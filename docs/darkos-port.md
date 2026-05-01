# Projeto dArkOS no R35S — Notas Técnicas

**Data:** Maio 2026  
**Device:** R35S (Clone R36S Soy Sauce)  
**SoC:** Rockchip RK3326 (ARM64, 4× Cortex-A35)  
**RAM:** 1GB (898MB disponível)  
**SD Card:** 87.9GB em /dev/sdb

---

## Hardware Identificado

- **SoC:** RK3326 / PX30 (ARM64)
- **Display:** Elida KD35T133, driver `simple-panel-dsi`, controlador HX8394F
  - DSI via `dsi@ff450000`
  - GPIO enable: GPIO1 (0xff250000), pin 18
  - GPIO reset: GPIO3 (0xff270000), pin 16
  - Backlight: PWM
- **DTB em uso pelo ArkOS:** `rk3326-r35s-linux.dtb`
  - `compatible = "rockchip,rk3326-odroidgo3-linux"`
  - `model = "Rockchip RK3326"` → string em `/proc/cpuinfo Hardware:`
- **ArkOS detecta painel como:** "Clone R36S Soy Sauce"
  - Mesma detecção que dispositivos Y3506 (Soy Sauce) do dArkOS
  - Os DTBs soysauce do dArkOS usam os **mesmos GPIOs** para display

---

## Por que dArkOS não bootou direto

### Tentativa 1 — Flash direto da imagem
- `dArkOSRE_R36_trixie_03082026.img` flashada com dd no SD inteiro
- Resultado: tela preta, device sem resposta
- **Causa:** dArkOS ROOT usa **btrfs** com compressão zlib; kernel original do ArkOS não tem suporte a btrfs

### Tentativa 2 — Kernel original + ROOT dArkOS
- Boot partition do ArkOS (kernel original) + ROOT do dArkOS
- Resultado: LED acendeu, tela preta cintilante
- **Causa:** kernel original (ArkOS) não conseguia montar ROOT btrfs; crashava antes do journald

### Tentativa 3 — ROOT dArkOS convertido para ext4
- Convertemos o ROOT dArkOS de btrfs→ext4 via rsync (8.5GB, 119386 arquivos)
- Kernel original + ROOT ext4
- Resultado: tela preta (sem cintilação)
- **Causa:** provável incompatibilidade de versão de userspace Debian Trixie vs kernel ArkOS 4.4

---

## Solução Encontrada (não executada por falta de sudo com TTY)

### Abordagem final planejada
**dArkOS kernel + DTB R35S + ROOT dArkOS ext4**

- **Kernel dArkOS** (`Image`, ARM64, 4.4.189) tem suporte a `simple-panel-dsi` + `pwm-backlight`
- **DTB R35S** (`rk3326-r35s-linux.dtb`) tem os GPIOs corretos para este hardware
- **ROOT ext4** (`darkos_root.img`, label ROOTFS, 8.5GB) convertido de btrfs
- **fstab** já corrigido: `ext4` para ROOT, `exfat + nofail` para EASYROMS
- **firstboot.service** desabilitado no ROOT para não formatar sdb3

### Arquivos preparados
| Arquivo | Localização | Descrição |
|---------|-------------|-----------|
| `darkos_root.img` | SSD raiz | ROOT dArkOS ext4 (8.5GB, label ROOTFS) |
| `/tmp/darkos_boot.img` | PC /tmp | Imagem BOOT 100MB com kernel dArkOS + DTB R35S |
| `/tmp/darkos_r35s_boot.ini` | PC /tmp | boot.ini configurado para R35S |

### Comandos para executar (requer terminal com sudo)
```bash
# BOOT
sudo dd if=/tmp/darkos_boot.img of=/dev/sdb1 bs=4M status=progress conv=fsync

# ROOT
sudo dd if=/run/media/emiyakiritsugu/726EC5436EC50139/darkos_root.img of=/dev/sdb2 bs=4M status=progress conv=fsync
```
U-Boot e sdb3 não precisam ser tocados.

---

## Conteúdo dos Backups

| Arquivo | Tamanho | Conteúdo |
|---------|---------|----------|
| `r35s_backup_completo.img.gz` | 1.7GB (comprimido) | Disco completo (inclui U-Boot, BOOT, início do ROOT) |
| `R35S_Backup/boot_partition.img` | 112MB | Partição BOOT original |
| `R35S_Backup/root_partition.img` | 8.7GB | Partição ROOT original completa |
| `R35S_Backup/roms_partition.img` | 80GB | Partição ROMS completa |
| `R35S_Backup/lista_completa_jogos.txt` | 9705 linhas | Lista de todos os ROMs |
| `R35S_Backup/Extracao_Vital/` | — | BIOS, save states, arquivos de boot originais |

### Script de restauração
```bash
sudo bash /home/emiyakiritsugu/restaurar_r35s.sh
```

---

## Layout do SD Card

```
/dev/sdb       87.9GB
├── sdb (0–32767 setores)  U-Boot (16MB)
├── sdb1  112MB   BOOT     FAT32  — kernel, DTB, boot.ini
├── sdb2  8.7GB   root     ext4   — sistema operacional
└── sdb3  79.1GB  EASYROMS exfat  — ROMs
```

## Boot Chain
```
Power → Boot ROM → U-Boot (setor 64) → lê boot.ini do FAT32 →
→ carrega Image (kernel) + uInitrd + DTB → kernel → initrd → monta ROOT → systemd → EmulationStation
```

---

## Notas para Retomar o Projeto dArkOS

1. O `/tmp/darkos_boot.img` e `/tmp/darkos_root.img` são perdidos ao reiniciar o PC — precisam ser recriados
2. A imagem dArkOS original está em: `SSD/dArkOSRE_R36_trixie_03082026.img` (7.8GB)
3. O device é identificado como **"Clone R36S Soy Sauce"** pelo ArkOS — não é um R35S puro
4. Os DTBs do dArkOS para Soy Sauce (pasta `dtb/soysauce/`) usam os mesmos GPIOs de display que o DTB R35S
5. O variant `Y3506_*` correto não foi determinado (precisaria do Hardware: string com DTB soysauce carregado)
6. Alternativa: tentar com o DTB soysauce V03 diretamente, pois dArkOS reconheceria o hardware corretamente
