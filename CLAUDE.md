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
├── images/r35s_arkos_os.img   ← imagem OS (8,8 GB) — sistema com LED fix integrado
├── mnt/rootfs/                ← ponto de montagem do sistema
├── mnt/boot/                  ← ponto de montagem da BOOT
├── mount.sh                   ← sudo bash mount.sh / sudo bash mount.sh umount
├── apply_led_fix.sh           ← ⚠ PRÓXIMA AÇÃO: sudo bash apply_led_fix.sh
├── docs/                      ← hardware.md, insights.md, diario.md, darkos-port.md
├── dtb/                       ← rk3326-r35s-linux.dts (original decompilado)
└── fixes/led-off/             ← service systemd legado (substituído por apply_led_fix.sh)
```

### Montar/desmontar

```bash
sudo bash mount.sh           # monta mnt/rootfs/ e mnt/boot/
sudo bash mount.sh umount    # desmonta (salva mudanças na imagem)
```

---

## ⚡ ESTADO ATUAL (2026-05-01)

### O que foi feito nesta sessão

**1. Migração para dArkOS4Clone:**
O sistema base foi migrado de ArkOS (GOGOCAT) para **dArkOS4Clone** (Trixie build), que oferece melhor compatibilidade com clones e suporte a hardware moderno.

**2. Criação da Nova Imagem Base:**
Foi gerada uma imagem de backup do estado funcional atual do SD card:
- **Arquivo:** `images/darkos4clone_patched_base.img` (9,9 GB)
- **Conteúdo:** MBR + BOOT (vfat) + ROOTFS (btrfs).
- **Status:** Contém patches de hardware (Wi-Fi fix, Anti-Expansion fix).

**3. Fix do LED e Hardware (Herdados):**
- O fix do LED (abordagem DTB) foi validado e está integrado na nova imagem.
- Barramento SDIO (Wi-Fi) habilitado via DTB.
- Script `expandtoexfat.sh` desativado para proteger o SD card falsificado.

---

## 🏗 Arquitetura do dArkOS4Clone — Novo Baseline

Diferente do ArkOS original, o dArkOS4Clone utiliza **btrfs** na ROOTFS por padrão (embora possamos converter para ext4 se necessário) e possui uma estrutura de boot mais flexível.

### Scripts e Localizações Importantes (Pós-Migração)

| Caminho | Função |
|--------|--------|
| `mnt/boot/boot.ini` | Configurações de boot e DTB |
| `/usr/local/bin/xray.sh` | Ferramenta de diagnóstico (injetada) |
| `/usr/local/bin/fix_power_led` | Gestão de LED frontal |

---

## Estado das tarefas

### Concluído
- [x] Hardware mapeado (GPIOs, display, boot chain, DTB decompilado)
- [x] Baseline migrado para dArkOS4Clone
- [x] Imagem base gerada em `images/darkos4clone_patched_base.img`
- [x] Dissecação do ArkOS original concluída (docs/dissection/)

### Pendente
- [ ] **Validar dArkOS em campo** — testar estabilidade de Wi-Fi e performance de cores
- [ ] **f3probe** no SD card para verificar capacidade real de escrita
- [ ] **Restauração de ROMs** — popular a partição EASYROMS seletivamente do backup
- [ ] **Análise btrfs** — avaliar se vale manter btrfs ou converter para ext4 para resiliência

---

## Arquivos de backup (SSD externo)

SSD: `/run/media/emiyakiritsugu/726EC5436EC50139/`

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `R35S_Backup/boot_partition.img` | 112 MB | BOOT original — **não modificar** |
| `R35S_Backup/root_partition.img` | 8,7 GB | ROOT original — **não modificar** |
| `R35S_Backup/roms_partition.img` | 80 GB | ROMs completas — **não modificar** |
| `r35s_backup_completo.img` | 4,5 GB | U-Boot + BOOT + metade ROOT |
| `darkos_root.img` | 8,4 GB | ROOT dArkOS btrfs→ext4 |
| `dArkOSRE_R36_trixie_03082026.img` | 7,8 GB | Imagem dArkOS original |

**Scripts utilitários em ~/:**
```
~/restaurar_r35s.sh      — restaura SD card a partir dos backups do SSD
~/montar_os_completo.sh  — monta imagem OS flashável a partir das partes
```

---

## Hardware — referência rápida

### GPIO (RK3326) — fórmula: `sysfs = bank × 32 + (grupo − 'A') × 8 + pino`

| GPIO | sysfs | Função |
|---|---|---|
| GPIO0_A0 | 0 | LED frontal azul (panel driver) ← nosso fix |
| GPIO0_A5 | 5 | LED frontal vermelho (panel driver) ← nosso fix |
| GPIO2_B5 | 77 | LED padrão ODROID/RG351 (fix_power_led original) |
| GPIO1_B2 | 42 | Display enable |
| GPIO3_B0 | 104 | Display reset |

### Boot chain
```
Power → Boot ROM → U-Boot (setor 64) → boot.ini (FAT32) →
Image + uInitrd + rk3326-r35s-linux.dtb → kernel → systemd → EmulationStation
```

### Offsets da imagem

| Partição | Setor | Offset | Tamanho |
|---|---|---|---|
| sdb1 BOOT (FAT32) | 32768 | 16 MB | 112 MB |
| sdb2 ROOT (ext4) | 262144 | 128 MB | 8,7 GB |
| sdb3 EASYROMS | 18434245 | ~8,8 GB | não incluída |

---

## Notas importantes

- Fish shell não suporta heredoc `<<` — usar arquivos em /tmp ou Write tool
- `debugfs write` falha se arquivo já existe — fazer `rm` antes
- `debugfs symlink` tem ordem oposta ao `ln`: `(linkname, target)`
- O SD card é **falsificado** — nunca confiar na capacidade sem f3probe
- `firstboot.service` do dArkOS formata sdb3 — **sempre desabilitar antes de flashar ROOT dArkOS**
- `conv=notrunc` é obrigatório ao escrever partição dentro de imagem com `dd`
- Arquivos no sistema montado pertencem ao root → edições precisam de `sudo tee` ou script com sudo
