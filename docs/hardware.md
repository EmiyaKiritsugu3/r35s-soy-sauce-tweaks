# Hardware Documentation — R35S (Clone R36S Soy Sauce)

## Identification

- **Device sold as:** R35S
- **ArkOS panel detection:** "Clone R36S Soy Sauce"
- **dArkOS family:** `soysauce` (Y3506)
- **`/proc/cpuinfo Hardware:`** `Rockchip RK3326` (when using R35S DTB)
- **SoC:** Rockchip RK3326 / PX30 — ARM64, 4× Cortex-A35 @ 1.3GHz
- **RAM:** 1GB (898MB visible, ~128MB reserved for GPU)

## Display

| Property | Value |
|----------|-------|
| Panel | Elida KD35T133 |
| Controller | HX8394F |
| Interface | MIPI DSI (4 lanes) |
| Linux driver | `simple-panel-dsi` (generic — no ST7701 or vendor-specific driver needed) |
| Backlight | `pwm-backlight` |
| Resolution | 640×480 |
| Refresh | 60Hz (also 50Hz and 75Hz timings in DTB) |

### Display GPIOs (from DTB)

| Signal | GPIO Bank | Pin | Active |
|--------|-----------|-----|--------|
| Panel enable | GPIO1 @ 0xff250000 | 18 | Low |
| Panel reset | GPIO3 @ 0xff270000 | 16 | Low |
| Blue LED | GPIO0 @ 0xff040000 | 0 | High |
| Red LED | GPIO0 @ 0xff040000 | 5 | High |

> **Note:** `led-blue1-gpios` (GPIO0_A0) and `led-red-gpios` (GPIO0_A5) are set HIGH by the panel driver at display init — this is what causes the always-on front LED.

### DTB Compatible Strings

```
R35S DTB:       compatible = "rockchip,rk3326-odroidgo3-linux", "rockchip,rk3326"
Soy Sauce V03:  compatible = "rockchip,rk3326-r36s-linux", "rockchip,rk3326"
```

Display GPIOs are **identical** between R35S and Soy Sauce V03 DTBs (confirmed by MMIO address comparison).

## Boot Chain

```
Power → Boot ROM (in SoC) → U-Boot (sector 64 of SD)
→ U-Boot reads boot.ini from FAT32 BOOT partition
→ Loads: Image (kernel) + uInitrd (initrd) + DTB
→ Kernel initializes hardware
→ initrd mounts ROOT partition
→ systemd → EmulationStation
```

### boot.ini Format

```
odroidgoa-uboot-config

setenv bootargs "root=LABEL=ROOTFS rootwait rw ..."
setenv loadaddr "0x02000000"
setenv initrd_loadaddr "0x01100000"
setenv dtb_loadaddr "0x01f00000"

load mmc 1:1 ${loadaddr} Image
load mmc 1:1 ${initrd_loadaddr} uInitrd
load mmc 1:1 ${dtb_loadaddr} rk3326-r35s-linux.dtb

booti ${loadaddr} ${initrd_loadaddr} ${dtb_loadaddr}
```

## SD Card Layout

```
Offset 0       → 16MB    : U-Boot (raw, sector 64)
/dev/mmcblk0p1   112MB   FAT32   BOOT      : kernel, DTB, initrd, boot.ini
/dev/mmcblk0p2   8.7GB   ext4    root      : OS root filesystem
/dev/mmcblk0p3   ~79GB   exfat   EASYROMS  : ROMs
```

> **Important:** `/dev/mmcblk0p3` starts at ~8.9GB from disk start. The dArkOS image (7.8GB) does **not** overwrite p3 when flashed with `dd`.

## GPIO Map (RK3326 / PX30)

| GPIO Bank | MMIO Address | Kernel GPIO base |
|-----------|-------------|-----------------|
| GPIO0 | 0xff040000 | 0 |
| GPIO1 | 0xff250000 | 32 |
| GPIO2 | 0xff260000 | 64 |
| GPIO3 | 0xff270000 | 96 |

## Kernel Info (ArkOS)

- Version: 4.4.189
- Compiler: GCC 7.3
- Architecture: ARM64
- Filesystems: ext4 (built-in), exfat (module) — **no btrfs**

## Kernel Info (dArkOS)

- Version: 4.4.189
- Architecture: ARM64
- Has: `simple-panel-dsi` ✓, `pwm-backlight` ✓
- **No btrfs** — ROOT must be ext4

## dArkOS Hardware Detection

dArkOS runs `/usr/local/bin/r36_config.sh` at boot which:
1. Reads `Hardware:` from `/proc/cpuinfo`
2. Looks up variant in `/boot/dtb/r36_devices.ini`
3. With R35S DTB: `Hardware = "Rockchip RK3326"` → not found → `variant = unknown`
4. Fallback: LED `Clone_PMIC_Controlled.py`, ALSA `SPK_HP`
5. Logs to `/boot/darkosre_device.log`
