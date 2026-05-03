# Current State - R35S Soy Sauce Tweaks
**Date:** 2026-05-03
**Target Device:** R35S (Clone R36S Soy Sauce V03)
**Panel:** Elida KD35T133 (Panel 01)
**Status:** SUCCESS - Stabilized & Optimized

## System Overview
- **OS:** dArkOSRE (Debian Trixie based)
- **Kernel:** 4.4.189 (dArkOS official)
- **DTB:** Smart Hybrid DTB (Factory timings + RTL8188FU identity hack + Regulator-driven power management).

## Hardware Truth (Validated)
- **Display Stability:** The "White Screen" was a Race Condition. Fixed by removing `regulator-always-on` from `vcc_lcd` and adding a 50ms ramp delay, forcing the kernel to wait for stable voltage before panel init.
- **WiFi Chip:** Identified as **Realtek 8188FU**. 
- **The HSync Secret:** This specific Panel 1 requires `hsync-len = <0xda>`.

## Safeguards & Tools
- **Sentinel X-Ray:** Built-in systemd service that captures hardware diagnostics to `/boot/SENTINEL_DIAGNOSTIC.log` on every boot.
- **doneit:** Flag active to prevent automated script expansion.
- **Safepoints:** 
  1. `images/dArkOSRE_R35S_V03_Safepoint_20260503.img` (11GB - OS only).
  2. ROMs successfully migrated (GB, GBA, GBC, SNES + BIOS).

## Next Goals
1. Verification of WiFi connectivity with the new identity hack.
2. Fine-tuning of RetroArch core assignments for the Trixie environment.
