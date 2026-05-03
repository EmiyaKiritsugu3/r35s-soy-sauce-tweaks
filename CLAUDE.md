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

## ⚡ ESTADO ATUAL (2026-05-02)

### O que foi feito nesta sessão

**1. Sucesso do Sentinel: Deep X-Ray:**
Mesmo com o bug temporário de tela preta, o script Sentinel rodou com sucesso no background, gerando o arquivo `SENTINEL_HARDWARE_MAP.log`. 
- **Confirmado:** Kernel dArkOS suporta BTRFS.
- **Confirmado:** SD Card CID extraído para monitoramento de saúde do chip falso.
- **Hostname:** Identificado como `g350`.

**2. Diagnóstico e Rollback do Display:**
Identificamos que o dArkOS4Clone é sensível a mudanças no DTB nativo. O uso do DTB do ArkOS antigo causou "cegueira" no sistema. 
- **Ação:** O DTB original funcional foi restaurado a partir da imagem de backup.
- **Status:** O sistema está pronto para boot com imagem e LED corrigido (herdado do backup).

**3. Documentação de Elite:**
Os achados do "Ground Truth" do Sentinel foram integrados em `docs/hardware.md`.

---

## 🎯 Estratégia de Elite: Arch-style Workflow


## 🏗 Arquitetura do dArkOS4Clone — Novo Baseline

Diferente do ArkOS original, o dArkOS4Clone utiliza **btrfs** na ROOTFS por padrão e possui uma estrutura de boot mais flexível.

### Scripts e Localizações Importantes (Pós-Migração)

| Caminho | Função |
|--------|--------|
| `mnt/boot/boot.ini` | Configurações de boot e DTB (Removido `quiet splash`) |
| `/usr/local/bin/sentinel_xray.sh` | **Sentinel: Deep X-Ray** (Saída visual no TTY1) |
| `/usr/local/bin/fix_power_led` | Gestão de LED frontal |

---

## 🎯 Estratégia de Elite: Arch-style Workflow

Para evitar o ciclo de "reinstalar tudo" e proteger o SD Card falso, adotamos o modelo de **Particionamento Desacoplado**:

### 1. Separação de Preocupações
- **Sistema (BOOT/ROOTFS):** Tratado como imutável/descartável. Atualizado via flash seletivo de partições.
- **Dados (EASYROMS):** O "/home" do console. Contém ROMs, BIOS, Saves e Configurações de usuário. **Nunca deve ser formatado.**

### 2. Persistência de Configurações (Binding)
- Implementar `mount --bind` para pastas críticas:
    - `/home/ark/.config/retroarch` → `/roms/bios/.system_configs/retroarch`
    - `/home/ark/.emulationstation` → `/roms/bios/.system_configs/es_configs`
- **Benefício:** Saves e configurações sobrevivem a trocas de OS.

### 3. Sentinel: Deep X-Ray Protocol
- O scanner de hardware agora é parte integrante do baseline.
- **Trigger:** Rodado automaticamente no boot via systemd.
- **Output:** `/boot/SENTINEL_HARDWARE_MAP.log` (completo) e TTY1 (progresso visual).

---

## Estado das tarefas

### Concluído
- [x] Hardware mapeado (GPIOs, display, boot chain, DTB decompilado)
- [x] Baseline migrado para dArkOS4Clone
- [x] Imagem base gerada e injetada com **Sentinel X-Ray (Visual)**
- [x] Display Fix (Elida Panel) aplicado no DTB oficial do dArkOS
- [x] Estratégia "Arch-style" documentada

### Pendente
- [ ] **Flash Seletivo** — Gravar apenas sdb1 e sdb2 da imagem para o SD físico.
- [ ] **Mapeamento Graphify** — Rodar na ROOTFS extraída para gerar o blueprint.
- [ ] **Configuração do fstab** — Automatizar o bind de saves/configs para a partição ROMs.
- [ ] **Análise btrfs** — Avaliar resiliência vs ext4 no chip falso.

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
