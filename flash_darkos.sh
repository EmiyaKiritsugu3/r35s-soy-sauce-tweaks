#!/bin/bash
# Flash script for [PID-SENTINEL] Restoration Baseline (dArkOS)
set -e

IMAGE="images/dArkOSRE_R36_trixie_03082026.img"
DEVICE="/dev/sdb"

echo "Checking image: $IMAGE"
if [ ! -f "$IMAGE" ]; then
    echo "Error: Image not found."
    exit 1
fi

echo "Unmounting partitions on $DEVICE..."
sudo umount ${DEVICE}* 2>/dev/null || true

echo "Flashing image to $DEVICE (this will take a while)..."
sudo dd if="$IMAGE" of="$DEVICE" bs=4M status=progress conv=fsync

echo "Refreshing partition table..."
sudo partprobe "$DEVICE"

echo "Done. Please return to the session."
