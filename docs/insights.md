# Insights Técnicos — Jornada R35S

Compilação de tudo que foi descoberto, aprendido ou surpreendente durante o projeto.
Serve como guia mental para retomar ou expandir o trabalho no futuro.

---

## 1. Identidade do hardware

- O device é vendido como **R35S** mas o ArkOS o identifica internamente como
  **"Clone R36S Soy Sauce"** (família Y3506). Isso importa porque o dArkOS usa
  essa string de detecção para selecionar o DTB correto na inicialização.
- A string `Hardware:` em `/proc/cpuinfo` vem diretamente do campo `model` do DTB
  carregado — não do hardware físico. Trocar o DTB muda o que o sistema "acha" que é.
- O SoC é **RK3326** (idêntico ao PX30 do ponto de vista de kernel/GPIO).
  Toda documentação de GPIO/DTS do PX30 se aplica aqui.

---

## 2. GPIOs e fórmula de numeração

```
sysfs_num = bank * 32 + (grupo - 'A') * 8 + pino
```

Exemplos práticos:
| DTB name    | Banco | Grupo | Pino | sysfs |
|-------------|-------|-------|------|-------|
| GPIO0_A0    | 0     | A     | 0    | **0** |
| GPIO0_A5    | 0     | A     | 5    | **5** |
| GPIO1_A2    | 1     | A     | 2    | **34**|
| GPIO3_B0    | 3     | B     | 0    | **104**|

Esse padrão é universal em Rockchip (RK3326, RK3399, RK3588...).

---

## 3. Por que o LED frontal fica aceso

O DTB original declara os pinos do LED **dentro do nó do painel de display**:

```dts
panel@0 {
    led-blue1-gpios = <&gpio0 0 GPIO_ACTIVE_HIGH>;  /* GPIO0_A0 */
    led-red-gpios   = <&gpio0 5 GPIO_ACTIVE_HIGH>;  /* GPIO0_A5 */
};
```

O driver `simple-panel-dsi` afirma esses pinos HIGH ao inicializar o display e
**nunca os limpa**. O nó `gpio_leds` existe no DTB mas está `disabled`, então
`/sys/class/leds/` fica vazio — sem API de LED disponível em runtime.

A solução correta é um serviço systemd one-shot que roda após o boot e escreve 0
nos pinos via sysfs — não remover os GPIOs do DTB (isso os manteria apagados
durante o boot, perdendo o indicador visual de inicialização).

---

## 4. Cadeia de boot do RK3326

```
Boot ROM → U-Boot (setor 64 do disco) → lê boot.ini do FAT32 (sdb1)
        → carrega Image + uInitrd + DTB → kernel → initrd → systemd → EmulationStation
```

Pontos críticos:
- O U-Boot está gravado nos primeiros ~16 MB do disco bruto, **antes de qualquer partição**.
  Um `dd` da imagem inteira sobrescreve o U-Boot sem aviso.
- O **DTB é carregado pelo U-Boot separadamente do kernel** — isso permite trocar
  o DTB sem recompilar o kernel. É como o boot "injeta" a descrição do hardware.
- O `boot.ini` controla os endereços de carga. Se errar o endereço do DTB ou do
  initrd, o kernel trava silenciosamente (tela preta, sem mensagem).

---

## 5. Por que o dArkOS não bootou direto

| Tentativa | O que foi feito | Sintoma | Causa real |
|-----------|-----------------|---------|------------|
| 1 | Flash direto da imagem dArkOS | Tela preta total | ROOT usa **btrfs** — kernel ArkOS 4.4 não tem driver btrfs |
| 2 | Kernel ArkOS + ROOT dArkOS btrfs | LED acendeu, tela preta cintilante | Kernel não monta btrfs, pânico antes do journald |
| 3 | Kernel ArkOS + ROOT dArkOS **ext4** | Tela preta (sem cintilação) | Debian Trixie (userspace) é incompatível com kernel 4.4 |
| ✓ Solução | **Kernel dArkOS** + DTB R35S + ROOT ext4 | Não testado (sudo bloqueado) | — |

A lição: **kernel e userspace precisam ser do mesmo ecossistema**. Um Debian Trixie
com kernel 4.4 é uma combinação impossível — libc, systemd e módulos são muito novos.

---

## 6. firstboot.service — a armadilha silenciosa

O dArkOS ROOT vem com `firstboot.service` habilitado. Ele roda `expandtoexfat.sh`
que **formata sdb3 inteiro** (a partição de ROMs). Não há aviso, não há prompt.

Nunca flash um ROOT de sistema embarcado sem checar os serviços de firstboot antes.
Fix: `debugfs -w -R "rm /etc/systemd/system/multi-user.target.wants/firstboot.service" root.img`

---

## 7. debugfs — o canivete suíço para imagens ext4

`debugfs` permite ler e **escrever** dentro de imagens `.img` sem montar, sem sudo
(quando o arquivo pertence ao usuário), sem loopback device:

```bash
# Ler arquivo dentro da imagem
debugfs img.img -R "cat /etc/fstab"

# Escrever arquivo
debugfs -w img.img -R "write /tmp/arquivo_local /caminho/dentro/da/imagem"

# Apagar arquivo
debugfs -w img.img -R "rm /caminho/dentro"

# Criar symlink (atenção: ordem é linkname, target — oposta ao ln!)
debugfs -w img.img -R "symlink /etc/systemd/system/multi-user.target.wants/svc.service /etc/systemd/system/svc.service"

# Alterar permissões
debugfs -w img.img -R "set_inode_field /caminho i_mode 0100755"
```

O `write` falha se o arquivo já existir — precisa de `rm` antes.

---

## 8. mtools — FAT32 sem sudo

Para partições FAT32 (BOOT), `mtools` com `MTOOLS_SKIP_CHECK=1` faz tudo sem
montar e sem sudo:

```bash
export MTOOLS_SKIP_CHECK=1
mdir  -i /dev/sdb1 ::/          # lista arquivos
mcopy -i boot.img ::/Image .    # extrai arquivo
mcopy -i boot.img arquivo ::/ . # injeta arquivo
```

Essencial quando não se tem TTY para sudo.

---

## 9. Conversão btrfs → ext4

A única forma confiável de converter é via **rsync** (não existe ferramenta de
conversão in-place estável):

```bash
# Criar imagem ext4 vazia do tamanho certo
dd if=/dev/zero of=novo.img bs=1M count=9000
mkfs.ext4 -L ROOTFS novo.img

# Montar ambos e copiar
mount -o loop btrfs.img /mnt/src
mount -o loop novo.img  /mnt/dst
rsync -aHAXx /mnt/src/ /mnt/dst/
```

Após a cópia, o fstab dentro do novo ROOT ainda diz `btrfs` — precisa ser corrigido
manualmente (via debugfs ou dentro do mount).

---

## 10. SD Card falsificado

O card foi vendido como 128 GB mas reporta 87,9 GB — tamanho não-padrão, indicador
de falsificação. Um teste `dd` de leitura sequencial (94 GB lidos, 36 MB/s, zero
erros) **não prova a capacidade real de escrita**.

Ferramenta correta para verificação real: `f3probe --destructive`:
```bash
sudo f3probe --destructive --time-ops /dev/sdb
```
Isso escreve padrões em todo o disco e verifica o retorno — detecta remapeamento
de setores em cards falsos.

---

## 11. Duplicatas de ROMs — nomes regionais

Das 9.705 ROMs listadas, 262 apareciam duplicadas. A maioria (200+) eram nomes
regionais do mesmo console:
- `genesis/` e `megadrive/` → mesmo console (Sega, EUA vs. mundo)
- `sfc/` e `snes/` → mesmo console (Nintendo, Japão vs. mundo)

O emulador provavelmente aceita ambas as pastas, então os mesmos jogos aparecem
na lista duas vezes. Não são arquivos duplicados — são aliases de pasta.

---

## 12. Fish shell e heredoc

Fish não suporta `<<` heredoc (sintaxe bash). Ao usar Claude Code com Fish como
shell padrão, escrever arquivos multi-linha precisa ser feito via:
- Ferramenta `Write` do Claude (cria direto no caminho)
- `printf '...' > /tmp/arquivo` com escaping manual
- Script auxiliar em bash chamado via `bash -c`

---

## 13. systemd one-shot para GPIO

Para controlar GPIO no boot via systemd:

```ini
[Unit]
After=multi-user.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes   # mantém o serviço "ativo" — evita que o kernel recicle os pinos
ExecStart=/usr/local/bin/script.sh
```

O `RemainAfterExit=yes` é importante: sem ele o serviço termina e o kernel pode
revogar o controle dos pinos exportados.

O sysfs GPIO precisa de um breve `sleep 0.05` após o `export` antes de definir
`direction` — o kernel leva um ciclo para criar os arquivos de controle.

---

## 14. DTB — a "placa de identidade" do hardware

O Device Tree Binary (DTB) é o único contrato entre o kernel e o hardware físico.
Num sistema embarcado ARM:
- O U-Boot passa o DTB para o kernel no boot
- O kernel não "descobre" hardware — ele lê o DTB
- Trocar o DTB pode habilitar/desabilitar periféricos inteiros sem recompilar
- `dtc -I dtb -O dts arquivo.dtb` descompila para texto editável

Para este device, o DTB correto é `rk3326-r35s-linux.dtb` com
`compatible = "rockchip,rk3326-odroidgo3-linux"`.

---

*Documento gerado em Maio 2026 — projeto R35S (Clone R36S Soy Sauce, RK3326)*
