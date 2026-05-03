# Recovery Guide: R35S Soy Sauce Restoration
**Version:** 1.0 (2026-05-03)
**Target:** SD Card Failure / Data Corruption

## ⚠️ The "Fake Card" Situation
Your SD card is identified as a **fake capacity chip** (Reports 128GB, actual ~87GB).
- **Rule #1:** Never write more than 40GB of total data to be safe.
- **Rule #2:** If the OS stops booting or games disappear, assume sector corruption.

## 📥 Restoration Steps (Fast Track)

### 1. Burn the Safepoint Image
If you need to start over, use the golden image created on 2026-05-03:
```bash
sudo dd if=images/dArkOSRE_R35S_V03_Safepoint_20260503.img of=/dev/sdb bs=4M status=progress conv=fsync
```

### 2. Verify/Re-apply the DTB
If the screen is scrambled or white, ensure the correct DTB is in the root of the BOOT partition:
1. Connect SD to PC.
2. The file MUST be named `rk3326-r36s-linux.dtb`.
3. Use the factory DTB from `r35s_backup_completo.img` or the patched version from this project.

### 3. Fixing the "White Screen" on Boot
If the screen stays white after a fresh flash:
1. Don't panic. Press **Power** once to sleep, then once to wake.
2. If you want a permanent fix, apply the **Smart Patch** (Regulator-driven energy management) described in `ARCHITECTURAL-DECISIONS.md`.

### 4. Mounting ROMs manually
To add more games from the backup image:
```bash
# Mount the backup image
sudo mkdir -p mnt/roms_backup
sudo mount -o loop images/roms_partition.img mnt/roms_backup

# Mount the SD card EASYROMS partition
sudo mkdir -p mnt/easyroms
sudo mount /dev/sdb3 mnt/easyroms

# Copy (example: GBA)
sudo rsync -av --progress mnt/roms_backup/gba/ mnt/easyroms/gba/
```

## 🛠️ Essential Tools
- `mtools`: Used to edit the BOOT partition without mounting.
- `dtc`: Device Tree Compiler, used to decompile/compile `.dtb` files.
- `dd`: Binary writing tool.
