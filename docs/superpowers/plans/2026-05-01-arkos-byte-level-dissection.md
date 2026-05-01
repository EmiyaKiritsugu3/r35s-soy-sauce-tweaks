# ArkOS Byte-Level Reverse Engineering & Dissection Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Perform a complete, byte-level dissection and reverse engineering of the ArkOS system image for the R35S (RK3326).

**Architecture:** We will systematically analyze the storage layout, bootloader (U-Boot), kernel and device tree, initramfs, and the root filesystem (systemd services, EmulationStation configs, and proprietary binaries). The goal is to produce a comprehensive map of how the system operates from power-on to the UI, identifying all custom patches, scripts, and configurations.

**Tech Stack:** `hexdump`, `strings`, `binwalk`, `dtc`, `debugfs`, `mtools`, `mount` (loop), systemd analysis, bash script analysis.

---

### Task 1: Storage Layout & Bootloader (U-Boot) Analysis

**Files:**
- Create: `docs/dissection/01-storage-and-uboot.md`
- Target Image: `images/r35s_arkos_os.img` (or physical SD card backup)

- [ ] **Step 1: Map the exact partition table**

Run `fdisk -l images/r35s_arkos_os.img` and `parted images/r35s_arkos_os.img print` to document the exact sector boundaries of all partitions (BOOT, ROOT, and the unallocated space for EASYROMS). Document this in `docs/dissection/01-storage-and-uboot.md`.

- [ ] **Step 2: Extract and analyze the U-Boot region**

The U-Boot bootloader is stored in the raw sectors before the first partition (typically sectors 64 to 32767).
Extract it:
```bash
dd if=images/r35s_arkos_os.img of=/tmp/uboot.bin bs=512 skip=64 count=32704
```

- [ ] **Step 3: Strings and binwalk analysis of U-Boot**

Run `strings /tmp/uboot.bin | grep -i "U-Boot"` and `binwalk /tmp/uboot.bin`. Document the U-Boot version, build date, and any hardcoded environment variables or boot scripts found within the binary. Add findings to `docs/dissection/01-storage-and-uboot.md`.

- [ ] **Step 4: Commit findings**

```bash
git add docs/dissection/01-storage-and-uboot.md
git commit -m "docs: add storage layout and U-Boot dissection"
```

### Task 2: BOOT Partition Analysis (Kernel, Initrd, DTB)

**Files:**
- Create: `docs/dissection/02-boot-partition.md`
- Target: `mnt/boot/`

- [ ] **Step 1: Mount BOOT and analyze boot.ini**

Read `mnt/boot/boot.ini`. Document the kernel command line (`bootargs`), memory load addresses, and the exact sequence of `load` and `booti` commands. Add this to `docs/dissection/02-boot-partition.md`.

- [ ] **Step 2: Analyze the Kernel (Image)**

Extract kernel version and compile info:
```bash
strings mnt/boot/Image | grep "Linux version"
```
Check for specific drivers compiled in (e.g., display, filesystem support):
```bash
strings mnt/boot/Image | grep -i "simple-panel\|drm\|btrfs\|ext4\|rk817"
```
Document the kernel capabilities.

- [ ] **Step 3: Extract and analyze initrd (uInitrd)**

The `uInitrd` is a U-Boot wrapped initramfs. Strip the header and extract:
```bash
dd if=mnt/boot/uInitrd of=/tmp/initrd.gz bs=64 skip=1
mkdir -p /tmp/initrd_extract
cd /tmp/initrd_extract
gunzip -c /tmp/initrd.gz | cpio -id
```
Analyze the `/init` script inside the extracted initramfs. Document how it mounts the ROOT partition, any fallback mechanisms, and how it switches root (`switch_root`). Document in `docs/dissection/02-boot-partition.md`.

- [ ] **Step 4: Commit findings**

```bash
git add docs/dissection/02-boot-partition.md
git commit -m "docs: add boot partition, kernel, and initramfs dissection"
```

### Task 3: Root Filesystem (systemd & Custom Services)

**Files:**
- Create: `docs/dissection/03-rootfs-services.md`
- Target: `mnt/rootfs/etc/systemd/system/`

- [ ] **Step 1: Map all enabled services**

List all enabled services:
```bash
ls -l mnt/rootfs/etc/systemd/system/multi-user.target.wants/
```
Document the critical services in `docs/dissection/03-rootfs-services.md`.

- [ ] **Step 2: Dissect 351mp.service and batt_led.service**

Read `mnt/rootfs/etc/systemd/system/351mp.service` and `mnt/rootfs/etc/systemd/system/batt_led.service`. Trace the execution to the scripts they call (e.g., `/usr/local/bin/fix_power_led`, `/usr/local/bin/batt_life_warning.py`). Document their exact behavior.

- [ ] **Step 3: Dissect oga_events.service**

Read `mnt/rootfs/etc/systemd/system/oga_events.service`. Trace it to the binary it executes (likely `/usr/local/bin/ogage` or similar). This binary handles the hardware buttons and hotkeys.

- [ ] **Step 4: Dissect emulationstation.service**

Read `mnt/rootfs/etc/systemd/system/emulationstation.service`. Note the user it runs as (usually `ark`), environment variables set, and the path to the main script (`/usr/bin/emulationstation/emulationstation.sh`).

- [ ] **Step 5: Commit findings**

```bash
git add docs/dissection/03-rootfs-services.md
git commit -m "docs: add systemd and custom services dissection"
```

### Task 4: EmulationStation & RetroArch Configuration

**Files:**
- Create: `docs/dissection/04-ui-and-emulators.md`
- Target: `mnt/rootfs/etc/emulationstation/`, `mnt/rootfs/home/ark/.config/`

- [ ] **Step 1: Analyze EmulationStation es_systems.cfg**

Read `mnt/rootfs/etc/emulationstation/es_systems.cfg`. Document how it maps system names to the `EASYROMS` partition and the exact launch commands (usually calling a wrapper script like `perfmax` followed by `retroarch` or a standalone emulator). Add to `docs/dissection/04-ui-and-emulators.md`.

- [ ] **Step 2: Analyze RetroArch wrapper scripts**

Read `/usr/local/bin/retroarch` and `/usr/local/bin/retroarch32` in the mounted rootfs. Document any environment variables (like `SDL_AUDIODRIVER`, `LD_LIBRARY_PATH`) or CPU scaling commands executed before launching the emulator.

- [ ] **Step 3: Analyze RetroArch global config**

Read `mnt/rootfs/home/ark/.config/retroarch/retroarch.cfg`. Extract key configurations: default video driver (gl, glcore, vulkan), audio driver, input mapping paths, and hotkey binds.

- [ ] **Step 4: Commit findings**

```bash
git add docs/dissection/04-ui-and-emulators.md
git commit -m "docs: add EmulationStation and RetroArch config dissection"
```

### Task 5: Hardware-Specific Fixes & Binaries

**Files:**
- Create: `docs/dissection/05-hardware-fixes.md`
- Target: `mnt/rootfs/usr/local/bin/`

- [ ] **Step 1: Dissect audio-fix.sh**

Read `mnt/rootfs/usr/local/bin/audio-fix.sh`. Document the RTC wake (`rtcwake`) workaround for the RK817-1A audio chip bug. Add to `docs/dissection/05-hardware-fixes.md`.

- [ ] **Step 2: Analyze perfmax and perfnorm**

Read `mnt/rootfs/usr/local/bin/perfmax` and `mnt/rootfs/usr/local/bin/perfnorm`. Document the CPU governor changes (e.g., `performance` vs `ondemand`) and frequencies set.

- [ ] **Step 3: Reverse Engineer ogage binary (Optional/Surface Level)**

Run `strings mnt/rootfs/usr/local/bin/ogage` (or `ogage.r36s`). Look for hardcoded input event paths (`/dev/input/event*`), hotkey combinations (e.g., `KEY_POWER`, `KEY_VOLUMEUP`), and system commands executed (like `killall retroarch` or triggering suspend). Document findings.

- [ ] **Step 4: Commit findings**

```bash
git add docs/dissection/05-hardware-fixes.md
git commit -m "docs: add hardware-specific fixes and binary analysis"
```
