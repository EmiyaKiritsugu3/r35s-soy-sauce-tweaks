#!/bin/bash
# Project Sentinel: Deep X-Ray Hardware Mapping (v2.1 - Ultra-Fast & Visual Feedback)
# Goal: Use LED to signal progress and avoid early shutdown.

DUMP_DIR="/boot/SENTINEL_DUMPS"
LOG_FILE="$DUMP_DIR/last_scan.log"
TTY="/dev/tty1"
RED_LED=5

# Function to turn Red LED on/off
set_led() {
    if [ ! -d /sys/class/gpio/gpio$RED_LED ]; then
        echo $RED_LED > /sys/class/gpio/export 2>/dev/null
    fi
    echo out > /sys/class/gpio/gpio$RED_LED/direction 2>/dev/null
    echo $1 > /sys/class/gpio/gpio$RED_LED/value 2>/dev/null
}

# START: Turn LED ON
set_led 1

mkdir -p $DUMP_DIR
echo "--- SENTINEL v2.1 START $(date) ---" > $LOG_FILE

sentinel_screen() { echo -e "$1" | tee -a $LOG_FILE > $TTY; }

clear > $TTY
sentinel_screen "=========================================================="
sentinel_screen "  SENTINEL v2.1: [RED LED ON = DO NOT POWER OFF]"
sentinel_screen "=========================================================="

# 1. Faster Hardware ID (No DTC, just grep)
sentinel_screen "[*] Probing Display DNA..."
find /proc/device-tree -name "compatible" | grep "panel" | xargs cat 2>/dev/null >> $LOG_FILE
echo "" >> $LOG_FILE

# 2. Kernel Errors (Vital for black screen diagnosis)
sentinel_screen "[*] Capturing Kernel Errors..."
dmesg | grep -iE "fail|error|panic|conflict|timeout|panel|dsi|drm" >> $LOG_FILE

# 3. Storage DNA
sentinel_screen "[*] Reading SD Card Identity..."
cat /sys/block/mmcblk0/device/cid 2>/dev/null >> $LOG_FILE

# 4. JSON Summary
cat <<EOF > "$DUMP_DIR/summary.json"
{
  "status": "success",
  "panel": "$(find /proc/device-tree -name "compatible" | grep "panel" | xargs cat 2>/dev/null)",
  "hostname": "$(hostname)"
}
EOF

sentinel_screen "=========================================================="
sentinel_screen "  COMPLETE! RED LED WILL TURN OFF NOW."
sentinel_screen "=========================================================="

# FINISH: Turn LED OFF
sync
set_led 0
sleep 1
