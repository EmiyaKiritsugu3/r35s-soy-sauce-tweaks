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

**Fix do LED — abordagem DTB (solução definitiva):**

O `fix_power_led` userspace **não funcionava** porque o kernel `simple-panel-dsi` usa
a GPIO descriptor API (`devm_gpiod_get_optional`) para ownar os GPIOs 0 e 5.
O `echo > /sys/class/gpio/export` falha silenciosamente — o kernel rejeita a exportação.

Evidência: o LED apaga durante standby (kernel deasserta via `panel_unprepare()`),
confirmando que o driver controla esses GPIOs ativamente.

**Solução:** remover `led-red-gpios` e `led-blue1-gpios` do nó `panel@0` no DTS,
recompilar e substituir o DTB na partição BOOT do SD card.

```
dtb/rk3326-r35s-linux.dts     ← modificado: led-*-gpios removidos
dtb/rk3326-r35s-linux-noleds.dtb ← DTB compilado (já flashado no SD)
```

**Aplicado no SD card (2026-05-01):**
- `/usr/local/bin/fix_power_led` → versão com GPIO 0/5 (redundante agora, mas não prejudica)
- `/usr/local/bin/batt_life_warning.py` → versão com LED_GPIOS = [77, 0, 5]
- `rk3326-r35s-linux.dtb` → novo DTB sem led-*-gpios (backup em `.dtb.bak`)

**Próximo passo:** testar no device — o LED frontal deve permanecer apagado durante uso normal.

---

## Arquitetura do ArkOS — o que já dissecamos

### Sequência de boot (systemd)

```
351mp.service  (oneshot)
  ├─ fix_power_led       → ativa GPIO 77 (LED padrão RG351) + desliga GPIOs 0/5 (R35S) ← NOSSO FIX
  ├─ checkbrightonboot   → restaura brilho salvo
  └─ fixvolume.sh        → restaura volume salvo

batt_led.service  (loop contínuo)
  └─ batt_life_warning.py → pisca GPIOs 77/0/5 se bateria ≤ 20% ← NOSSO FIX

emulationstation.service
  └─ /usr/bin/emulationstation/emulationstation.sh  (user: ark)

oga_events.service    → lê botões físicos / hotkeys
autosuspend.service   → suspend por inatividade
wifi_importer.service → importa configs WiFi
```

### Fix do LED — arquitetura real (descoberta na dissecação)

O ArkOS **já tem** sistema de LED (`fix_power_led` + `batt_life_warning.py`) mas
controla **GPIO 77** (GPIO2_B5), que é irrelevante para o R35S.

O LED que incomoda é acionado pelo driver `simple-panel-dsi` nos:
- **GPIO 0** (GPIO0_A0) — LED frontal azul
- **GPIO 5** (GPIO0_A5) — LED frontal vermelho

O `apply_led_fix.sh` integra os GPIOs 0 e 5 ao sistema existente, sem criar
services paralelos. `fix_power_led` e `batt_life_warning.py` são atualizados.

### Descoberta importante: audio-fix.sh

`/usr/local/bin/audio-fix.sh` (modificado Jan/2026, comentários em Mandarim):
O chip de áudio RK817-1A tem bug de inicialização — precisa de suspend/resume:
```bash
sleep 6
rtcwake -m mem -s 1   # suspend para RAM por 1s → reseta chip fisicamente
sleep 2
amixer sset 'Playback Path' 'SPK'
alsactl store
```
Serviço correspondente provavelmente habilitado — investigar na dissecação.

### Scripts principais em /usr/local/bin

| Script | Função |
|--------|--------|
| `fix_power_led` | Liga/desliga LEDs no boot |
| `batt_life_warning.py` | Monitor de bateria com alerta de LED |
| `retroarch` / `retroarch32` | Launchers do RetroArch |
| `es_systems.cfg` | Config de sistemas do EmulationStation |
| `ogage` / `ogage.r33s` / `ogage.r36s` | OGA events (3 variantes de hardware) |
| `auto_suspend.py` | Auto suspend por inatividade |
| `perfmax` / `perfnorm` | Scripts de performance (overclock) |
| `audio-fix.sh` | Fix de inicialização do áudio (RK817-1A) |

---

## Estado das tarefas

### Concluído
- [x] Hardware mapeado (GPIOs, display, boot chain, DTB decompilado)
- [x] Imagem OS montada em `images/r35s_arkos_os.img`
- [x] Arquitetura do ArkOS dissecada (boot sequence, services, scripts)
- [x] Fix do LED: `apply_led_fix.sh` criado e commitado
- [x] Documentação completa (docs/, dtb/, CLAUDE.md)

### Pendente
- [x] **LED fix CONFIRMADO** no device em 2026-05-01 — LED frontal apagado ✓
- [ ] **Continuar dissecação** — EmulationStation configs, RetroArch setup, audio-fix
- [ ] **f3probe** no SD card para verificar capacidade real de escrita
- [ ] **dArkOS port** — recriar darkos_boot.img e executar flash (ver docs/darkos-port.md)

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
