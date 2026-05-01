# Diário Completo — Projeto dArkOS no R35S
**Data:** Abril–Maio 2026  
**Objetivo original:** Instalar dArkOS (imagem `dArkOSRE_R36_trixie_03082026.img`) no R35S  
**Resultado:** Não concluído — retorno ao ArkOS original pendente  

---

## 1. Hardware do Device

### Identificação
- **Device físico:** Vendido como "R35S" — mas ArkOS identifica internamente como **"Clone R36S Soy Sauce"**
- **SoC:** Rockchip RK3326 (= PX30) — 4× ARM Cortex-A35, ARM64
- **RAM:** 1GB (898MB visível ao SO, ~128MB reservado para GPU)
- **Armazenamento:** SD card 87.9GB (vendido como 128GB — **FALSO/CONTRAFEIT**)
- **Display:** Elida KD35T133 — controlador HX8394F via MIPI DSI
  - Driver Linux: `simple-panel-dsi` (genérico, não precisa driver específico)
  - GPIO enable: GPIO1 @ 0xff250000, pino 18, ativo-baixo
  - GPIO reset: GPIO3 @ 0xff270000, pino 16, ativo-baixo
  - Backlight: PWM via `pwm-backlight`
- **Resolução:** 640×480 @ 60Hz

### DTB em Uso pelo ArkOS Original
- Arquivo: `rk3326-r35s-linux.dtb`
- `compatible = "rockchip,rk3326-odroidgo3-linux", "rockchip,rk3326"`
- `model = "Rockchip RK3326"` → aparece em `/proc/cpuinfo Hardware:`
- Arquitetura: ARM64

### Layout do SD Card
```
Setor 0        → 32767    : U-Boot (16MB) — bootloader de 2º estágio
/dev/sdb1  112MB  FAT32   BOOT     : kernel, DTB, boot.ini, initrd
/dev/sdb2  8.7GB  ext4    root     : sistema operacional
/dev/sdb3  79.1GB exfat   EASYROMS : ROMs dos jogos
```

### Cadeia de Boot
```
Ligar → Boot ROM (embutida no SoC) → lê U-Boot do setor 64
→ U-Boot processa boot.ini no FAT32
→ carrega Image (kernel) + uInitrd (initrd) + DTB
→ kernel inicializa hardware (display, GPIO, etc.)
→ initrd monta ROOT (sdb2)
→ systemd → EmulationStation
```

### Sobre o "Clone R36S Soy Sauce"
O device é vendido como R35S mas usa hardware identificado pela ArkOS como 
"Clone R36S Soy Sauce" — uma família de placas clone do R36S fabricadas pela Y3506.
O dArkOS tem DTBs específicos para essa família (`dtb/soysauce/Y3506_*`).
Os GPIOs de display são **idênticos** entre o DTB do R35S e os DTBs Soy Sauce V03,
confirmado por comparação dos endereços MMIO (0xff250000 e 0xff270000).

---

## 2. Sobre o SD Card Falso

### O Problema
- Embalagem: 128GB
- Capacidade reportada pelo sistema: 87.9GB
- Tamanho padrão mais próximo: não existe (64GB = ~59GiB, 128GB = ~119GiB)
- **87.9GB não é tamanho padrão** → cartão falso confirmado

### Riscos
Cartões falsos têm flash real menor que o reportado. Ao escrever além da
capacidade real, dados anteriores são silenciosamente sobrescritos ou perdidos.
O `f3probe` (ainda pendente) determinará a capacidade real do flash.

### Observação Importante
O ROMs nunca corrompeu durante o uso normal. A partição ROMS (sdb3) começa
em ~8.9GB do início do disco e ocupa até ~87.9GB. Se a capacidade real for
menor que isso, parte dos ROMs poderia estar corrompida silenciosamente.

---

## 3. Backups Disponíveis

| Arquivo | Tamanho | Conteúdo |
|---------|---------|----------|
| `r35s_backup_completo.img.gz` | 1.7GB (comprimido) | Disco completo do setor 0 até ~4.8GB (inclui U-Boot + BOOT + início do ROOT) |
| `R35S_Backup/boot_partition.img` | 112MB | Partição BOOT original completa |
| `R35S_Backup/root_partition.img` | 8.7GB | Partição ROOT original completa |
| `R35S_Backup/roms_partition.img` | 80GB | Partição ROMS completa |
| `R35S_Backup/lista_completa_jogos.txt` | 9.705 linhas | Lista de todos os ROMs |
| `R35S_Backup/Extracao_Vital/` | — | BIOS, save states, arquivos de boot originais |
| `dArkOSRE_R36_trixie_03082026.img` | 7.8GB | Imagem dArkOS para R36S (objeto do projeto) |
| `darkos_root.img` | 8.5GB | ROOT do dArkOS convertido de btrfs para ext4 |

**Nota sobre `r35s_backup_completo.img.gz`:** só cobre os primeiros ~4.8GB do disco.
O sdb2 (ROOT) tem 8.7GB, então o backup completo NÃO cobre o ROOT inteiro.
Para restaurar ROOT completamente, usar `root_partition.img`.

---

## 4. Tentativas de Instalação do dArkOS

### Tentativa 1 — Flash Direto da Imagem Oficial
**O que fizemos:** `dd if=dArkOSRE_R36_trixie_03082026.img of=/dev/sdb`  
**Resultado:** Device não iniciava — sem resposta ao ligar  
**Diagnóstico:**  
O dArkOS usa ROOT em **btrfs** com compressão zlib:1. O kernel original do ArkOS
(4.4.189, gcc 7.3, ARM64) não tem suporte a btrfs — confirmado com:
```
strings Image | grep -i btrfs  # retornou vazio
```
O kernel iniciava mas travava ao tentar montar o ROOT. Sem journald, sem log.

**Causa raiz:** Incompatibilidade de filesystem: kernel sem btrfs + ROOT btrfs.

---

### Tentativa 2 — Kernel Original + ROOT dArkOS (btrfs)
**O que fizemos:** Mantemos BOOT do ArkOS (kernel original) + ROOT do dArkOS
intacto (btrfs).  
**Resultado:** LED acendeu, tela preta cintilante, OS não carregou.  
**Diagnóstico:** Mesmo problema — kernel sem btrfs trava ao montar ROOT.
O "cintilante" era o backlight tentando inicializar antes do kernel travar.

---

### Tentativa 3 — Converter ROOT dArkOS de btrfs para ext4
**O que fizemos:** Montamos o ROOT dArkOS (btrfs, 4.4GB comprimido = ~7.1GB real)
e fizemos rsync para uma imagem ext4 de 8.5GB.
```bash
# Verificação do filesystem original
lsblk -f  # mostrou btrfs no ROOT dArkOS
strings darkos_kernel | grep btrfs  # vazio — sem suporte

# Conversão
dd if=/dev/zero of=darkos_root.img bs=1M count=8500
mkfs.ext4 -L ROOTFS darkos_root.img
mount -o loop darkos_root.img /mnt/new_root
rsync -aHAX /mnt/dark_root/ /mnt/new_root/
```
**Resultado:** 119.386 arquivos copiados, 7.4GB usados, label ROOTFS ✓  
**Por que ext4:** O kernel ArkOS original só suporta ext4 como filesystem principal.

---

### Tentativa 4 — Kernel Original + ROOT dArkOS (ext4)
**O que fizemos:** BOOT com kernel ArkOS original + sdb2 com `darkos_root.img`.  
**Resultado:** Tela preta, sem cintilação, sem resposta.  
**Diagnóstico:** Dois problemas identificados:

1. **Kernel ArkOS vs userspace Debian Trixie:** O kernel ArkOS (4.4.189, gcc 7.3)
   é antigo demais para o userspace Debian Trixie do dArkOS. Incompatibilidades
   de syscalls/interfaces podem causar falha silenciosa do init.

2. **DRM sem fbdev emulation:** O kernel ArkOS usa DRM/KMS mas sem emulação fbdev.
   `console=tty1` não produz saída visível pois não há `/dev/fb0`.
   O `console=/dev/ttyFIQ0` (padrão) envia output para UART, não para a tela.
   Resultado: sistema pode estar rodando mas não há forma de ver o que acontece.

3. **fstab incorreto (descoberto depois):** O `/etc/fstab` no ROOT dArkOS dizia
   `btrfs` para o ROOT — se não corrigido, o systemd tentaria remontar como btrfs
   e falharia. (Corrigido para ext4 antes do próximo teste.)

---

### Tentativa 5 — Análise do Kernel dArkOS
**O que descobrimos:**  
Extraímos e analisamos o kernel do dArkOS com `strings Image | grep`:
```
simple-panel-dsi   ← suporte ao display do R35S ✓
pwm-backlight      ← suporte ao backlight ✓
# strings Image | grep -i btrfs  → vazio — sem btrfs (não necessário com ext4)
```
O kernel do dArkOS (4.4.189, ARM64) tem os drivers necessários para o display do R35S.

**Comparação de DTBs:**  
Comparamos `rk3326-r35s-linux.dtb` (ArkOS) com `rk3326-r36s-linux.dtb` (dArkOS):
- Ambos usam `"elida,kd35t133", "simple-panel-dsi"` — mesmo driver
- Ambos mapeiam GPIO enable → `0xff250000` (GPIO1) pin 18
- Ambos mapeiam GPIO reset → `0xff270000` (GPIO3) pin 16
- **GPIOs de display são idênticos entre R35S e Soy Sauce V03**
- Diferença: sequência de inicialização do panel (calibração de cores diferente)

**Conclusão:** O kernel dArkOS PODE dirigir o display do R35S usando o DTB original.

---

### Solução Identificada (Não Executada)
**Abordagem:** dArkOS kernel + DTB do R35S + ROOT dArkOS ext4  

**Por que deve funcionar:**
- Kernel dArkOS tem `simple-panel-dsi` + `pwm-backlight` ✓
- DTB R35S tem GPIOs corretos para este hardware específico ✓
- ROOT ext4 com fstab corrigido ✓
- Initrd dArkOS é Debian Trixie padrão, monta ext4 normalmente ✓

**Por que não foi executada:** Comando `sudo dd` requer terminal com TTY para
autenticação da senha. O ambiente Claude Code não tem TTY, então todos os
`sudo` falharam com "a terminal is required to read the password".

**Arquivos preparados (em /tmp — perdidos ao reiniciar PC):**
- `/tmp/darkos_boot.img` — imagem FAT32 100MB com:
  - `Image` (kernel dArkOS)
  - `uInitrd` (initrd Debian Trixie)
  - `rk3326-r35s-linux.dtb` (DTB R35S com GPIOs corretos)
  - `boot.ini` com `root=LABEL=ROOTFS console=tty1`
  - `dtb/r36_devices.ini` (detecção de hardware do dArkOS)

**Modificações no ROOT ext4 (`darkos_root.img`):**
- `/etc/fstab` corrigido: `btrfs` → `ext4`, EASYROMS: `vfat` → `exfat,nofail`
- `firstboot.service` desabilitado (evitaria formatar sdb3 com os ROMs)

**Comandos para retomar:**
```bash
# BOOT (recriar /tmp/darkos_boot.img primeiro — ver seção 6)
sudo dd if=/tmp/darkos_boot.img of=/dev/sdb1 bs=4M status=progress conv=fsync

# ROOT
sudo dd if=/run/media/emiyakiritsugu/726EC5436EC50139/darkos_root.img of=/dev/sdb2 bs=4M status=progress conv=fsync
```

---

## 5. Descobertas Importantes

### O SD Card Nunca Foi Completamente Apagado
A imagem dArkOS tem 7.8GB. Ao fazer `dd if=imagem.img of=/dev/sdb`, o dd
**para de escrever quando a imagem acaba** — não apaga o restante do disco.

```
0        7.8GB     8.9GB (início sdb3)         87.9GB
├─────────────────┤─────────────────────────────────┤
  imagem dArkOS    sdb3: NUNCA SOBRESCRITO
  (sobrescreveu)
```

sdb3 (EASYROMS com ROMs) nunca foi tocada em nenhuma operação.

### Detecção de Hardware do dArkOS
O script `/usr/local/bin/r36_config.sh` roda a cada boot e:
1. Lê `Hardware:` de `/proc/cpuinfo`
2. Busca em `/boot/dtb/r36_devices.ini` (mapeado de hardware → variante)
3. Se não encontrar: usa `variant=unknown` com fallback gracioso
4. Configura LED, volume ALSA, gamma
5. Loga em `/boot/darkosre_device.log` — útil para diagnóstico

Com DTB R35S: Hardware = "Rockchip RK3326" → não encontrado no ini → `unknown`
→ LED usa `Clone_PMIC_Controlled.py`, ALSA usa `SPK_HP` (fallback correto)

### firstboot.service — Perigo
O serviço `firstboot.service` habilitado no ROOT do dArkOS roda `expandtoexfat.sh`
que **formata sdb3 como exfat**, destruindo ROMs existentes.
Foi desabilitado removendo o symlink em `multi-user.target.wants/`.

### Duplicatas nos ROMs
262 arquivos com nome duplicado na lista de jogos. Duplicatas reais:
- **59 jogos** em `genesis/` E `megadrive/` (mesmo console, nomes diferentes)
- **3 jogos** em `sfc/` E `snes/` (mesmo console, nomes diferentes)
O restante são portes legítimos do mesmo jogo para consoles diferentes.

---

## 6. Como Retomar o Projeto dArkOS

### Pré-requisitos
1. Ter `darkos_root.img` disponível (8.5GB, ext4, label ROOTFS, fstab corrigido)
   - Se não existir: recriar conforme seção abaixo
2. SD card em /dev/sdb, partições desmontadas
3. Terminal com sudo funcional

### Recriar /tmp/darkos_boot.img (se PC foi reiniciado)
```bash
DARKOS_IMG="/run/media/emiyakiritsugu/726EC5436EC50139/dArkOSRE_R36_trixie_03082026.img"
OFFSET=$((32768*512))

# Extrair arquivos do dArkOS
MTOOLS_SKIP_CHECK=1 mcopy -i "${DARKOS_IMG}@@${OFFSET}" ::/Image /tmp/darkos_Image
MTOOLS_SKIP_CHECK=1 mcopy -i "${DARKOS_IMG}@@${OFFSET}" ::/uInitrd /tmp/darkos_uInitrd
MTOOLS_SKIP_CHECK=1 mcopy -i "${DARKOS_IMG}@@${OFFSET}" ::/dtb/r36_devices.ini /tmp/r36_devices.ini

# Criar imagem BOOT
dd if=/dev/zero of=/tmp/darkos_boot.img bs=1M count=100
mkfs.fat -F32 -n BOOT /tmp/darkos_boot.img

# Popular a imagem
MTOOLS_SKIP_CHECK=1 mcopy -i /tmp/darkos_boot.img /tmp/darkos_Image ::/Image
MTOOLS_SKIP_CHECK=1 mcopy -i /tmp/darkos_boot.img /tmp/darkos_uInitrd ::/uInitrd
MTOOLS_SKIP_CHECK=1 mcopy -i /tmp/darkos_boot.img \
  /run/media/emiyakiritsugu/726EC5436EC50139/R35S_Backup/BOOT/rk3326-r35s-linux.dtb \
  ::/rk3326-r35s-linux.dtb
MTOOLS_SKIP_CHECK=1 mmd -i /tmp/darkos_boot.img ::dtb
MTOOLS_SKIP_CHECK=1 mcopy -i /tmp/darkos_boot.img /tmp/r36_devices.ini ::/dtb/r36_devices.ini
```

Criar `/tmp/darkos_r35s_boot.ini`:
```
odroidgoa-uboot-config

setenv bootargs "root=LABEL=ROOTFS rootwait rw fsck.repair=yes net.ifnames=0 fbcon=rotate:0 console=tty1 consoleblank=0 vt.global_cursor_default=0"

setenv loadaddr "0x02000000"
setenv initrd_loadaddr "0x01100000"
setenv dtb_loadaddr "0x01f00000"

load mmc 1:1 ${loadaddr} Image
load mmc 1:1 ${initrd_loadaddr} uInitrd
load mmc 1:1 ${dtb_loadaddr} rk3326-r35s-linux.dtb

booti ${loadaddr} ${initrd_loadaddr} ${dtb_loadaddr}
```

```bash
MTOOLS_SKIP_CHECK=1 mcopy -i /tmp/darkos_boot.img /tmp/darkos_r35s_boot.ini ::/boot.ini
```

### Alternativa: Usar DTB Soy Sauce
Se a abordagem com DTB R35S não funcionar, tentar com DTB Soy Sauce V03.
O dArkOS reconheceria o hardware corretamente (variant=soysauce).
```bash
MTOOLS_SKIP_CHECK=1 mcopy -i "${DARKOS_IMG}@@${OFFSET}" \
  "::dtb/soysauce/Y3506_V03_20241104/rk3326-r36s-linux.dtb" \
  /tmp/soysauce_v03.dtb
# Substituir no boot.ini: rk3326-r35s-linux.dtb → rk3326-r36s-linux.dtb
# E copiar soysauce_v03.dtb para a imagem BOOT como rk3326-r36s-linux.dtb
```

---

## 7. Estado Atual do SD Card

O SD card encontra-se em estado **ArkOS GOGOCAT (original restaurado)**.
Todos os `sudo dd` desta sessão falharam por falta de TTY — nada foi gravado.

Para confirmar: o device liga normalmente com ArkOS GOGOCAT se inserido.

---

## 8. Pendências

- [ ] **f3probe** — verificar capacidade real do SD card (suspeito de falso/128GB→87.9GB)
- [ ] **Restauração limpa** — `sudo bash /home/emiyakiritsugu/restaurar_r35s.sh`
- [ ] **Testar dArkOS** (opcional, futuro) — recriar boot.img e tentar abordagem identificada
- [ ] **Remover duplicatas** — 62 jogos duplicados (genesis+megadrive, sfc+snes)

---

## 9. Comandos Úteis de Referência

```bash
# Verificar partições do SD
lsblk -o NAME,SIZE,LABEL,FSTYPE,MOUNTPOINT /dev/sdb

# Ler arquivo de uma imagem ext4 sem montar
debugfs -R "cat /etc/fstab" /path/to/image.img

# Ler/escrever arquivos em partição FAT sem montar (sem sudo)
MTOOLS_SKIP_CHECK=1 mdir -i /dev/sdb1 ::
MTOOLS_SKIP_CHECK=1 mcopy -i /dev/sdb1 ::/boot.ini /tmp/boot.ini

# Decompile DTB para ver hardware
dtc -I dtb -O dts arquivo.dtb | grep -A10 "panel\|display\|backlight"

# Verificar drivers em kernel ARM64
strings Image | grep -i "simple-panel\|pwm-backlight\|btrfs\|ext4"

# f3probe (verifica capacidade real do SD)
sudo f3probe --destructive --time-ops /dev/sdb

# Restauração completa
sudo bash /home/emiyakiritsugu/restaurar_r35s.sh
```

---

## 5. Instalação Bem-Sucedida do dArkOS4Clone (01/05/2026)

**Objetivo:** Instalar o dArkOS4Clone (ArkOS para clones) em um R36S (Panel 1) com SD Card falso.

### O que foi feito:
1. **Flash da Imagem:** Gravada a imagem `dArkOS4Clone` no `/dev/sdb`.
2. **Injeção de Hardware (Panel 1):**
   - Injetado `rk3326-r36s-sauce-panel1-linux.dtb`.
   - Injetado `boot.ini` configurado para o hardware Sauce.
   - Injetado kernel `Image` compatível.
3. **Trava de Segurança (Anti-Expansion):**
   - Criado arquivo `doneit` na raiz do boot para pular o script de primeiro boot.
   - Renomeado `expandtoexfat.sh` para `.bak` para impedir corrupção do SD falso por expansão automática.

### Resultado:
- Boot funcional de primeira.
- Hardware reconhecido corretamente (sem tela preta).
- Partição `EASYROMS` preservada e pronta para restauração seletiva de backup.

### Pendências:
- Restauração seletiva de ROMs do backup (`roms_partition.img`).
- Limitar uso a < 20GB para segurança física do chip falso.
