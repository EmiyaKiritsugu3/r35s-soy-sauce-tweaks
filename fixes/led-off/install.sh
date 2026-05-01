#!/bin/bash
# install.sh — install the led-off fix
#
# Usage (running on the device itself):
#   sudo bash install.sh
#
# Usage (inject into SD card ROOT image from a PC, no sudo needed on device):
#   bash install.sh --image /path/to/root_partition.img

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/led-off.service"
SHELL_SCRIPT="$SCRIPT_DIR/led-off.sh"

# ── on-device install ────────────────────────────────────────────────────────
install_on_device() {
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: run as root (sudo bash install.sh)" >&2
        exit 1
    fi

    install -m 755 "$SHELL_SCRIPT"  /usr/local/bin/led-off.sh
    install -m 644 "$SERVICE_FILE"  /etc/systemd/system/led-off.service

    systemctl daemon-reload
    systemctl enable led-off.service
    systemctl start  led-off.service

    echo "Done. LEDs will turn off on every boot."
}

# ── SD-image inject (via debugfs, no sudo required) ──────────────────────────
install_into_image() {
    local img="$1"

    if ! command -v debugfs &>/dev/null; then
        echo "ERROR: debugfs not found. Install e2fsprogs." >&2
        exit 1
    fi

    echo "[1/4] Writing led-off.sh -> /usr/local/bin/led-off.sh"
    debugfs -w "$img" -R "rm /usr/local/bin/led-off.sh"       2>/dev/null || true
    debugfs -w "$img" -R "write $SHELL_SCRIPT /usr/local/bin/led-off.sh"

    echo "[2/4] Writing led-off.service -> /etc/systemd/system/led-off.service"
    debugfs -w "$img" -R "rm /etc/systemd/system/led-off.service"    2>/dev/null || true
    debugfs -w "$img" -R "write $SERVICE_FILE /etc/systemd/system/led-off.service"

    echo "[3/4] Setting permissions on led-off.sh"
    debugfs -w "$img" -R "set_inode_field /usr/local/bin/led-off.sh i_mode 0100755"

    echo "[4/4] Enabling service (creating symlink in multi-user.target.wants)"
    debugfs -w "$img" -R "mkdir /etc/systemd/system/multi-user.target.wants" 2>/dev/null || true
    debugfs -w "$img" -R "ln /etc/systemd/system/led-off.service /etc/systemd/system/multi-user.target.wants/led-off.service" 2>/dev/null || \
    debugfs -w "$img" -R "symlink /etc/systemd/system/multi-user.target.wants/led-off.service /etc/systemd/system/led-off.service"

    echo "Done. Image updated: $img"
}

# ── dispatch ─────────────────────────────────────────────────────────────────
if [ "${1}" = "--image" ]; then
    [ -z "$2" ] && { echo "Usage: $0 --image <root.img>"; exit 1; }
    install_into_image "$2"
else
    install_on_device
fi
