# R35S Soy Sauce Tweaks — Contexto do Projeto

## O que é este projeto

Engenharia reversa e customização do OS do **R35S** (handheld retro gaming).
O device é vendido como "R35S" mas o ArkOS o identifica como **"Clone R36S Soy Sauce"** (família Y3506).

- **SoC:** Rockchip RK3326, ARM64, 4× Cortex-A35
- **RAM:** 1 GB
- **Display:** Elida KD35T133, MIPI DSI, driver `simple-panel-dsi`, controlador HX8394F
- **OS base:** ArkOS (Linux 4.4, kernel ARM64)
- **SD Card:** 87,9 GB (vendido como 128 GB — **falsificado**)
- **GitHub:** https://github.com/EmiyaKiritsugu3/r35s-soy-sauce-tweaks

---

## Workspace local

```
~/Projetos_Antigravity/r35s-soy-sauce-tweaks/
├── images/r35s_arkos_os.img   ← imagem OS completa (8,8 GB) — sistema original intacto
├── mnt/rootfs/                ← ponto de montagem do sistema (vazio até montar)
├── mnt/boot/                  ← ponto de montagem da BOOT (vazio até montar)
├── mount.sh                   ← monta/desmonta a imagem
├── docs/hardware.md           ← mapa completo do hardware
├── docs/insights.md           ← 14 insights técnicos da jornada
└── fixes/led-off/             ← fix do LED frontal (service systemd)
```

### Montar para trabalho

```bash
sudo bash mount.sh           # monta mnt/rootfs/ e mnt/boot/
sudo bash mount.sh umount    # desmonta
```

### Offsets da imagem

| Partição | Setor início | Offset bytes | Tamanho |
|---|---|---|---|
| sdb1 BOOT (FAT32) | 32768 | 16 MB | 112 MB |
| sdb2 ROOT (ext4) | 262144 | 128 MB | 8,7 GB |
| sdb3 EASYROMS (exfat) | 18434245 | ~8,8 GB | 79,1 GB (não na imagem) |

---

## Estado atual

### Concluído
- [x] Hardware completamente mapeado (GPIOs, display, boot chain)
- [x] Imagem OS original montada e verificada (`images/r35s_arkos_os.img`)
- [x] Fix do LED frontal criado (`fixes/led-off/`) — pronto para aplicar
- [x] Documentação completa (`docs/hardware.md`, `docs/insights.md`)
- [x] Workspace de desenvolvimento configurado

### Pendente
- [ ] **Aplicar LED fix** ao `root_partition.img` (requer `sudo bash ~/aplicar_led_fix.sh`)
- [ ] **Dissecar o sistema** — montar e mapear scripts/configs do ArkOS
- [ ] **Gerar imagem com LED fix** — após aplicar o fix, rodar `montar_os_completo.sh` de novo
- [ ] **Restaurar o SD card** — `sudo bash ~/restaurar_r35s.sh`
- [ ] **f3probe** no SD card para verificar capacidade real de escrita
- [ ] **dArkOS port** — solução identificada mas não executada (ver abaixo)

---

## Fix do LED frontal

**Problema:** LED frontal fica aceso o tempo todo desde que o device foi comprado.

**Causa:** O driver `simple-panel-dsi` seta GPIO0_A0 (sysfs 0) e GPIO0_A5 (sysfs 5) como HIGH
ao inicializar o display. O nó `gpio_leds` está `disabled` no DTB → `/sys/class/leds/` vazio.

**Solução:** `fixes/led-off/led-off.service` — service systemd one-shot que roda após
`multi-user.target` e escreve 0 nos dois GPIOs via sysfs.

**Para aplicar na imagem:**
```bash
# Injeta no root_partition.img (no SSD)
sudo bash ~/aplicar_led_fix.sh

# Depois regenera a imagem OS com o fix incluído
sudo bash ~/montar_os_completo.sh
# → salva em /run/media/.../r35s_arkos_os.img (SSD)
# → copiar para images/ aqui
```

---

## Porta dArkOS (pendente, menor prioridade)

**Solução identificada:** dArkOS kernel + DTB R35S + ROOT ext4 (já convertido)

| Arquivo | Localização | Status |
|---|---|---|
| `dArkOSRE_R36_trixie_03082026.img` | SSD raiz (7,8 GB) | Original dArkOS |
| `darkos_root.img` | SSD raiz (8,4 GB) | ROOT convertido btrfs→ext4 |
| `/tmp/darkos_boot.img` | **PERDIDO** ao reiniciar PC | Precisa recriar |

**Para recriar o boot dArkOS:**
1. Montar `dArkOSRE_R36_trixie_03082026.img` com offset correto
2. Extrair `Image` (kernel), `uInitrd`, criar `boot.ini` com DTB R35S
3. Flash: `sudo dd if=darkos_boot.img of=/dev/sdb1 bs=4M` + `sudo dd if=darkos_root.img of=/dev/sdb2 bs=4M`

**Por que não bootou antes (3 tentativas):**
1. ROOT btrfs — kernel ArkOS 4.4 não tem btrfs
2. Kernel ArkOS + ROOT ext4 — Debian Trixie incompatível com kernel 4.4
3. Solução correta nunca foi executada (sudo bloqueado por TTY)

---

## Arquivos de backup (SSD externo)

SSD: `/run/media/emiyakiritsugu/726EC5436EC50139/`

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `R35S_Backup/boot_partition.img` | 112 MB | BOOT original |
| `R35S_Backup/root_partition.img` | 8,7 GB | ROOT original (ext4, **intacto**) |
| `R35S_Backup/roms_partition.img` | 80 GB | ROMs completas |
| `r35s_backup_completo.img` | 4,5 GB | Primeiros 4,5 GB do disco (U-Boot + BOOT + metade ROOT) |
| `r35s_arkos_os.img` | 8,8 GB | Imagem OS montada (U-Boot + BOOT + ROOT completo) |
| `darkos_root.img` | 8,4 GB | ROOT dArkOS convertido para ext4 |

**Scripts no home:**
```
~/restaurar_r35s.sh       — restaura SD card completo (sdb)
~/aplicar_led_fix.sh      — injeta led-off service no root_partition.img
~/montar_os_completo.sh   — monta imagem OS flashável a partir das partes
```

---

## Hardware — referência rápida

### GPIO (RK3326)
Fórmula: `sysfs = bank * 32 + (grupo - 'A') * 8 + pino`

| GPIO | sysfs | Função |
|---|---|---|
| GPIO0_A0 | 0 | LED frontal azul (panel driver) |
| GPIO0_A5 | 5 | LED frontal vermelho (panel driver) |
| GPIO1_B2 | 42 | Display enable |
| GPIO3_B0 | 104 | Display reset |

### Boot chain
```
Power → Boot ROM → U-Boot (setor 64) → boot.ini (FAT32) →
→ Image + uInitrd + rk3326-r35s-linux.dtb → kernel → systemd → EmulationStation
```

### DTB
- Em uso: `rk3326-r35s-linux.dtb`
- compatible: `"rockchip,rk3326-odroidgo3-linux"`
- Descompilar: `dtc -I dtb -O dts rk3326-r35s-linux.dtb > original.dts`

---

## Notas importantes

- Fish shell não suporta heredoc `<<` — usar Write tool ou arquivos em /tmp
- `debugfs write` falha se arquivo já existe — fazer `rm` antes
- `debugfs symlink` tem ordem oposta ao `ln`: `(linkname, target)`
- O SD card é **falsificado** — nunca confiar na capacidade reportada sem f3probe
- `firstboot.service` do dArkOS formata sdb3 — **sempre desabilitar antes de flashar ROOT dArkOS**
- `conv=notrunc` é obrigatório ao escrever partição dentro de imagem com `dd`
