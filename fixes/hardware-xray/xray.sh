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
