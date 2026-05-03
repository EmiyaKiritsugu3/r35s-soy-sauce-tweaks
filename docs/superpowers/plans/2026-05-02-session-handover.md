# Technical Handover: R35S Soy Sauce Elite Project

## Current Status
- **Device:** R35S (Clone R36S Soy Sauce V03).
- **Panel:** 01 (Elida KD35T133), confirmed timings: `hsync-len=120`.
- **Primary Goal:** Perform a clean install of dArkOS4Clone and restore selective functionality.
- **Critical Failure:** Latest boot attempts failed with a black screen and potential BTRFS corruption on the fake SD card.

## Assets Ready for Next Session
1. **The 'Golden' DTB:** `rk3326-r36s-sauce-panel1-wifi-linux.dtb` (located in root). This is the validated file that previously worked for display + WiFi.
2. **Sentinel v2.1:** Script injected in `images/darkos4clone_patched_base.img` and saved in `fixes/hardware-xray/sentinel_v2_1.sh`. It acende/apaga the Red LED to signal scan progress.
3. **Factory Truth:** Original factory DTS source and DTB binary saved in `dtb/factory/` and `docs/dissection/factory/`.
4. **Clean Image:** Source image located at `/home/emiyakiritsugu/Downloads/dArkOS4Clone-04302026.img.xz`.

## Blueprint for the New Session
1. **Flash Clean:** Use `xzcat` + `dd` to wipe the SD card with a fresh dArkOS4Clone image.
2. **Pre-emptive Strike:** BEFORE booting, mount the new BOOT partition and replace the DTB with the 'Golden' version (`panel1-wifi`).
3. **Sentinel Re-injection:** Ensure `sentinel_xray.sh` is present on the new ROOTFS to monitor the first boot.
4. **Graphify Mapping:** Once boot is confirmed, proceed with the full system mapping of the new clean install.

## Technical Reminders
- SD Card is **SDB** (but always check `lsblk` first).
- Use single quotes in Fish Shell for `rsync` filters: `--include='/*.zip'`.
- Never use generic `simple-panel` timings; always use the 120px factory standard.
