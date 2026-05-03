#!/bin/bash
# Project Sentinel: Deep X-Ray Hardware Mapping
# Output redirected to Console TTY1 for real-time visualization.

LOG="/boot/SENTINEL_HARDWARE_MAP.log"
TTY="/dev/tty1"

# Function to log to both file and screen
sentinel_log() {
    echo -e "$1" | tee -a $LOG > $TTY
}

# Clear screen and show header
clear > $TTY
echo "==========================================================" > $TTY
echo "  PROJECT SENTINEL: DEEP X-RAY HARDWARE MAP" | tee $LOG > $TTY
echo "  Target: R35S/Soy Sauce | Status: SCANNING..." > $TTY
echo "==========================================================" > $TTY

sentinel_log "\n[1. SYSTEM_IDENTITY]"
uname -a >> $LOG
sentinel_log "Hostname: $(hostname)"

sentinel_log "\n[2. CPU_DNA]"
grep "model name" /proc/cpuinfo | head -n 1 >> $LOG
sentinel_log "Cores Detected: $(grep -c ^processor /proc/cpuinfo)"

sentinel_log "\n[3. DEVICE_TREE_EXPLORER]"
[ -f /proc/device-tree/model ] && sentinel_log "Model: $(cat /proc/device-tree/model)"
if command -v dtc >/dev/null; then
    sentinel_log "Dumping full DTS to log file..."
    dtc -I fs -O dts /proc/device-tree 2>/dev/null >> $LOG
fi

sentinel_log "\n[4. STORAGE_DNA]"
for dev in /sys/block/mmcblk*; do
    if [ -d "$dev/device" ]; then
        name=$(cat $dev/device/name 2>/dev/null)
        sentinel_log "Found Storage: $dev ($name)"
        cat $dev/device/cid 2>/dev/null >> $LOG
    fi
done

sentinel_log "\n[5. USB_BUS_MAP]"
for dev in /sys/bus/usb/devices/*; do
    if [ -f "$dev/idVendor" ]; then
        vid=$(cat "$dev/idVendor")
        pid=$(cat "$dev/idProduct")
        sentinel_log "USB Device: $vid:$pid"
    fi
done

sentinel_log "\n[6. GPIO_MAP]"
mount -t debugfs none /sys/kernel/debug 2>/dev/null || true
if [ -f /sys/kernel/debug/gpio ]; then
    sentinel_log "Capturing GPIO Matrix..."
    cat /sys/kernel/debug/gpio >> $LOG
fi

sentinel_log "\n[7. DISPLAY DNA]"
panel=$(find /proc/device-tree -name "compatible" | grep "panel" | xargs cat 2>/dev/null)
sentinel_log "Panel DNA: $panel"

sentinel_log "\n=========================================================="
sentinel_log "  DEEP X-RAY COMPLETE! RESULTS IN /boot/"
sentinel_log "=========================================================="
sleep 3
sync
