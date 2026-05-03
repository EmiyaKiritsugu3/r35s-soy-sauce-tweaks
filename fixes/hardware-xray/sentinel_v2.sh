#!/bin/bash
# Project Sentinel: Deep X-Ray Hardware Mapping (v2.0 - Offline Telemetry)
# Author: Gemini Architecture Engine
# Goal: Structured data extraction for offline PC analysis.

DUMP_DIR="/boot/SENTINEL_DUMPS"
JSON_FILE="$DUMP_DIR/hardware_fingerprint.json"
TTY="/dev/tty1"

# Ensure dump directory exists
mkdir -p $DUMP_DIR

sentinel_screen() { echo -e "$1" > $TTY; }

# Clear screen and show header
clear > $TTY
sentinel_screen "=========================================================="
sentinel_screen "  SENTINEL v2.0: DEEP HARDWARE TELEMETRY"
sentinel_screen "  Status: GENERATING OFFLINE DUMP..."
sentinel_screen "=========================================================="

# --- 1. FULL LOG (LEGACY COMPATIBILITY) ---
LOG_FILE="$DUMP_DIR/full_scan_$(date +%Y%m%d_%H%M).log"
/usr/local/bin/sentinel_xray.sh > $LOG_FILE 2>&1 # Run old script to get the text log

# --- 2. CRITICAL ERROR FILTERING ---
sentinel_screen "[*] Filtering Kernel Errors..."
dmesg | grep -iE "fail|error|panic|conflict|timeout|deadlock" > "$DUMP_DIR/dmesg_errors.log"

# --- 3. LIVE DEVICE TREE DUMP (The Source of Truth) ---
sentinel_screen "[*] Extracting Live Device Tree..."
if command -v dtc >/dev/null; then
    dtc -I fs -O dts /proc/device-tree > "$DUMP_DIR/live_system.dts" 2>/dev/null
else
    # Fallback to direct copy if dtc is missing
    find /proc/device-tree -type f -exec echo -n "{}: " \; -exec cat {} \; -exec echo "" \; > "$DUMP_DIR/tree_walk.txt" 2>/dev/null
fi

# --- 4. SYSTEM INTEGRITY (Checksums) ---
sentinel_screen "[*] Calculating System Checksums..."
{
    echo "--- CHECKSUM REPORT ---"
    echo "Current DTB: $(sha256sum /boot/*.dtb 2>/dev/null)"
    echo "Kernel Image: $(sha256sum /boot/Image 2>/dev/null)"
    echo "U-Boot Script: $(sha256sum /boot/boot.ini 2>/dev/null)"
} > "$DUMP_DIR/integrity_checks.txt"

# --- 5. JSON FINGERPRINT (For PC Automation/Graphify) ---
sentinel_screen "[*] Generating JSON Fingerprint..."
cat <<EOF > $JSON_FILE
{
  "timestamp": "$(date -Is)",
  "system": {
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "model": "$(cat /proc/device-tree/model 2>/dev/null)",
    "compatible": "$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' ' ')"
  },
  "storage": {
    "mmcblk0_cid": "$(cat /sys/block/mmcblk0/device/cid 2>/dev/null)",
    "mmcblk0_name": "$(cat /sys/block/mmcblk0/device/name 2>/dev/null)"
  },
  "display": {
    "panel": "$(find /proc/device-tree -name "compatible" | grep "panel" | xargs cat 2>/dev/null)"
  }
}
EOF

sentinel_screen "\n=========================================================="
sentinel_screen "  DUMP COMPLETE! Analyze the folder 'SENTINEL_DUMPS'"
sentinel_screen "  in the BOOT partition on your PC."
sentinel_screen "=========================================================="
sleep 2
sync
