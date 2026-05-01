# Hardware X-Ray Diagnostic Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and integrate an autonomous hardware diagnostic script that generates a "Hardware DNA" report on every boot.

**Architecture:** A modular shell script (`xray.sh`) will collect data from `/sys`, `/proc`, and `dmesg`. It will be triggered by the existing `351mp.service` via the `fix_power_led` hook and save its output to the `BOOT` partition for easy access.

**Tech Stack:** Bash, Linux virtual filesystems (`/sys`, `/proc`), `dmesg`, `systemd`.

---

### Task 1: Create the X-Ray Core Script

**Files:**
- Create: `workspace/xray.sh`

- [ ] **Step 1: Write the xray.sh script with collection modules**

```bash
cat > workspace/xray.sh << 'EOF'
#!/bin/bash
# Hardware X-Ray Diagnostic Tool for R35S/R36S
# Output: /boot/HARDWARE_XRAY.log

LOG_FILE="/boot/HARDWARE_XRAY.log"
TEMP_LOG="/tmp/xray.tmp"

echo "=== HARDWARE X-RAY REPORT START: $(date) ===" > $TEMP_LOG

# Module: SYSTEM
echo -e "\n[SYSTEM]" >> $TEMP_LOG
cat /proc/version >> $TEMP_LOG 2>&1
echo "Hardware: $(grep Hardware /proc/cpuinfo | awk -F': ' '{print $2}')" >> $TEMP_LOG

# Module: USB (Wi-Fi Detection)
echo -e "\n[USB_TOPOLOGY]" >> $TEMP_LOG
for dev in /sys/bus/usb/devices/*; do
    if [ -f "$dev/idVendor" ]; then
        vid=$(cat "$dev/idVendor")
        pid=$(cat "$dev/idProduct")
        prod=$(cat "$dev/product" 2>/dev/null || echo "Unknown")
        echo "Device: $prod | ID: $vid:$pid | Path: $(basename $dev)" >> $TEMP_LOG
    fi
done

# Module: DISPLAY
echo -e "\n[DISPLAY_DNA]" >> $TEMP_LOG
find /proc/device-tree -name "compatible" -exec echo -n "{}: " \; -exec cat {} \; -exec echo "" \; | grep -E "panel|display" >> $TEMP_LOG
if [ -d /proc/device-tree/display-subsystem/dsi@ff450000/panel@0 ]; then
    echo "Panel Init Sequence (Hex):" >> $TEMP_LOG
    hexdump -C /proc/device-tree/display-subsystem/dsi@ff450000/panel@0/panel-init-sequence 2>/dev/null >> $TEMP_LOG
fi

# Module: STORAGE (SD Card Identity)
echo -e "\n[STORAGE_CID]" >> $TEMP_LOG
if [ -d /sys/block/mmcblk0/device ]; then
    echo "Manufacturer: $(cat /sys/block/mmcblk0/device/manfid)" >> $TEMP_LOG
    echo "OEM ID: $(cat /sys/block/mmcblk0/device/oemid)" >> $TEMP_LOG
    echo "Product Name: $(cat /sys/block/mmcblk0/device/name)" >> $TEMP_LOG
    echo "CID: $(cat /sys/block/mmcblk0/device/cid)" >> $TEMP_LOG
    echo "HW Rev: $(cat /sys/block/mmcblk0/device/hwrev)" >> $TEMP_LOG
    echo "Manufacture Date: $(cat /sys/block/mmcblk0/device/date)" >> $TEMP_LOG
fi

# Module: GPIO STATE
echo -e "\n[GPIO_STATE]" >> $TEMP_LOG
mount -t debugfs none /sys/kernel/debug 2>/dev/null || true
cat /sys/kernel/debug/gpio 2>/dev/null >> $TEMP_LOG

# Module: DMESG (Full Log)
echo -e "\n[DMESG_DUMP]" >> $TEMP_LOG
dmesg >> $TEMP_LOG 2>&1

echo -e "\n=== HARDWARE X-RAY REPORT END ===" >> $TEMP_LOG

# Persistence with backup
if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.bak"
fi
cp $TEMP_LOG "$LOG_FILE"
sync
EOF
chmod +x workspace/xray.sh
```

- [ ] **Step 2: Verify script syntax**

Run: `bash -n workspace/xray.sh`
Expected: No output (success).

### Task 2: Inject Script and Hook into Boot Sequence

**Files:**
- Modify: `mnt/rootfs/usr/local/bin/fix_power_led`
- Create: `mnt/rootfs/usr/local/bin/xray.sh` (Injected)

- [ ] **Step 1: Ensure image is mounted**

Run: `mount | grep mnt/rootfs`
If not mounted, run `sudo losetup -P /dev/loop0 images/r35s_arkos_os.img && sudo mount /dev/loop0p2 mnt/rootfs && sudo mount /dev/loop0p1 mnt/boot`

- [ ] **Step 2: Inject xray.sh into the system**

Run: `sudo cp workspace/xray.sh mnt/rootfs/usr/local/bin/xray.sh && sudo chmod 755 mnt/rootfs/usr/local/bin/xray.sh`

- [ ] **Step 3: Modify fix_power_led to trigger X-Ray**

Use `sed` or `replace` to add the execution line.
```bash
sudo sed -i '2i\
# Trigger Hardware X-Ray (Background)\
nice -n 19 /usr/local/bin/xray.sh &\
' mnt/rootfs/usr/local/bin/fix_power_led
```

- [ ] **Step 4: Verify the modification**

Run: `cat mnt/rootfs/usr/local/bin/fix_power_led | head -n 10`
Expected: Should see the `nice -n 19 /usr/local/bin/xray.sh &` line after the shebang.

### Task 3: Final Verification & Unmount

**Files:**
- None

- [ ] **Step 1: Check for any orphaned temp files**

Run: `ls workspace/xray.sh`

- [ ] **Step 2: Unmount the image to persist changes**

Run: `sudo bash mount.sh umount`

- [ ] **Step 3: Commit implementation**

```bash
git add workspace/xray.sh
git commit -m "feat: implement hardware x-ray diagnostic tool and boot hook"
```
