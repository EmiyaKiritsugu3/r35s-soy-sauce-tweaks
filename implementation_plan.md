# Implementation Plan: [PID-SENTINEL] Restoration Baseline (dArkOS)
**Date:** 2026-05-02
**FPA Estimate:** 11 (Critical Path: Hardware/Flashing)
**Status:** Awaiting Council Ratification

## 1. Goal
Restore the R35S Soy Sauce V03 to a clean functional state using dArkOS (Official Image) and verified hardware configurations.

## 2. Prerequisites
- [x] Golden DTB available: `rk3326-r36s-sauce-panel1-wifi-linux.dtb`
- [x] Clean image available: `images/dArkOSRE_R36_trixie_03082026.img`
- [x] SD Card identified as `/dev/sdb`

## 3. Steps

### Phase 1: Environment Preparation
1. [ ] Unmount any active partitions on `/dev/sdb`.
2. [ ] Verify `lsblk` output to ensure no mounts remain.

### Phase 2: Flashing Operation
1. [ ] Execute `dd if=images/dArkOSRE_R36_trixie_03082026.img of=/dev/sdb bs=4M status=progress conv=fsync`.
2. [ ] Run `partprobe /dev/sdb` to refresh partition table.

### Phase 3: Pre-boot Configuration (The Pre-emptive Strike)
1. [ ] Mount `/dev/sdb1` (BOOT) to `mnt/boot`.
2. [ ] Backup default DTB to `mnt/boot/rk3326-r35s-linux.dtb.bak`.
3. [ ] Copy Golden DTB: `cp rk3326-r36s-sauce-panel1-wifi-linux.dtb mnt/boot/rk3326-r35s-linux.dtb`.
4. [ ] Unmount `mnt/boot`.

### Phase 4: Sentinel Injection
1. [ ] Mount `/dev/sdb2` (ROOTFS) to `mnt/rootfs`.
2. [ ] Copy `fixes/hardware-xray/sentinel_v2_1.sh` to `mnt/rootfs/usr/local/bin/sentinel_xray.sh`.
3. [ ] Ensure execution permissions.
4. [ ] Unmount `mnt/rootfs`.

## 4. Verification
1. [ ] `lsblk` confirms the new partition structure.
2. [ ] `md5sum` check on the written DTB against the Golden version.
3. [ ] Final unmount confirms filesystem consistency.

## 5. Council Ratification
- **Warden (Security/Integrity):** "Flash operation confirmed on verified device /dev/sdb using dArkOS official image. Integrity of Golden DTB is preserved."
- **Auditor (Verification):** "Plan updated to reflect user's directive. Path to image is correct."
- **Approval:** RATIFIED.
