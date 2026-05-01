# Spec: Hardware X-Ray Diagnostic Tool for R35S/R36S

**Date:** 2026-05-01
**Topic:** Hardware identification and byte-level dissection automation.
**Status:** Draft

---

## 1. Objective
Create an autonomous diagnostic tool (`xray.sh`) that runs during the boot sequence of an R35S/R36S device to generate a comprehensive "Hardware DNA" report. This report will be used to identify internal components (Wi-Fi, LCD, Storage, Audio) with surgical precision, facilitating software optimization and driver porting (e.g., dArkOS integration).

## 2. Architecture

### 2.1 Trigger Mechanism
The script will be integrated into the existing ArkOS boot sequence:
- **Location:** `/usr/local/bin/xray.sh`
- **Execution Hook:** Called by `/usr/local/bin/fix_power_led` (which is triggered by `351mp.service` at `multi-user.target`).
- **Privileges:** Runs as `root`.

### 2.2 Collection Modules
The script will perform a "pull" operation from the Linux virtual filesystems:

| Module | Target | Data Points |
| :--- | :--- | :--- |
| **SYSTEM** | `/proc/version`, `/proc/cpuinfo` | Kernel version, compiler info, hardware string. |
| **USB** | `/sys/bus/usb/devices/` | VendorID, ProductID, Revision (Crucial for Wi-Fi). |
| **DISPLAY** | `/proc/device-tree/` | Panel compatibility string, initialization sequence hex dump. |
| **STORAGE** | `/sys/block/mmcblk0/device/` | CID (Card Identification), CSD, manufacturer code, manufacture date. |
| **AUDIO** | `amixer`, `dmesg` | RK817 revision, active playback paths. |
| **GPIO** | `/sys/kernel/debug/gpio` | Current state and ownership of all GPIO pins. |
| **LOGS** | `dmesg` | Full kernel ring buffer. |

## 3. Data Flow
1. **Init:** `351mp.service` starts.
2. **Hook:** `fix_power_led` executes `nice -n 19 /usr/local/bin/xray.sh &`.
3. **Scan:** `xray.sh` iterates through modules, buffering output in `/tmp/xray.tmp`.
4. **Persist:** Output is moved to `/boot/HARDWARE_XRAY.log` (FAT32 partition).
5. **Backup:** If a log exists, it's renamed to `HARDWARE_XRAY.log.bak`.

## 6. Implementation Plan Preview
1. Create `xray.sh` with modular extraction logic.
2. Modify `mnt/rootfs/usr/local/bin/fix_power_led` to call `xray.sh`.
3. Test locally by simulating `/sys` structures (if possible) or verifying script syntax.

---
## Self-Review
- **Scope:** Focused strictly on data collection.
- **Ambiguity:** Defined exact paths for all critical data points.
- **Safety:** Used `nice` and backgrounding to prevent boot delays.
- **Placeholders:** None.
