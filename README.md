# R35S Soy Sauce Tweaks

Customizations, fixes and documentation for the **R35S handheld gaming device** (Clone R36S "Soy Sauce" variant) running **ArkOS**.

## Device

| Property | Value |
|----------|-------|
| Sold as | R35S |
| Internal ID | Clone R36S Soy Sauce (Y3506 family) |
| SoC | Rockchip RK3326 (4× ARM Cortex-A35, ARM64) |
| RAM | 1GB |
| Display | Elida KD35T133 — HX8394F controller, MIPI DSI |
| Resolution | 640×480 @ 60Hz |
| OS | dArkOS4Clone (Trixie build, btrfs) |
| DTB | `rk3326-r35s-linux.dtb` (patched Soy Sauce V03) |

> **Note:** The project recently migrated to **dArkOS4Clone** as the primary baseline for better hardware support and clone compatibility.

## Fixes

| Fix | Description | Status |
|-----|-------------|--------|
| [LED Off](fixes/led-off/) | Turn off the always-on front LED after boot (DTB patch) | ✅ Integrated |
| [Wi-Fi Fix](dtb/) | Enabled SDIO bus for internal/external Wi-Fi support | ✅ Integrated |
| [Anti-Expansion](docs/diario.md) | Prevented automatic expansion to protect fake SD cards | ✅ Integrated |
| [Baseline Image](images/) | Patched dArkOS4Clone baseline image created | ✅ Ready |

## Hardware Details

See [docs/hardware.md](docs/hardware.md) for full hardware documentation including boot chain, partition layout, GPIO map, and display driver info.

## SD Card Note

This device is commonly sold with a **counterfeit SD card** (labeled 128GB, real capacity ~88GB). Verify with:
```bash
sudo f3probe --destructive --time-ops /dev/sdX
```

## Contributing

PRs welcome. If you have a different Soy Sauce board revision (Y3506_V04, V05, etc.), hardware reports and DTB contributions are especially useful.
