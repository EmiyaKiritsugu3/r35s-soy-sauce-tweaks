#!/bin/bash
# Monta/desmonta as partições da imagem OS para trabalho local
# Uso:
#   sudo bash mount.sh         → monta rootfs e boot
#   sudo bash mount.sh umount  → desmonta tudo

PROJ="$(cd "$(dirname "$0")" && pwd)"
OS_IMG="$PROJ/images/r35s_arkos_os.img"

ROOTFS="$PROJ/mnt/rootfs"
BOOT="$PROJ/mnt/boot"

# Offsets das partições (setor × 512)
BOOT_OFFSET=$((32768 * 512))      # sdb1: setor 32768
ROOT_OFFSET=$((262144 * 512))     # sdb2: setor 262144

umount_all() {
    echo "Desmontando..."
    umount "$ROOTFS" 2>/dev/null && echo "  rootfs desmontado" || true
    umount "$BOOT"   2>/dev/null && echo "  boot desmontado"   || true
}

mount_all() {
    [ ! -f "$OS_IMG" ] && echo "ERRO: $OS_IMG não encontrado" && exit 1

    echo "Montando partições de: $OS_IMG"
    echo ""

    echo "→ ROOT  ($ROOTFS)"
    mount -o loop,offset=$ROOT_OFFSET,rw "$OS_IMG" "$ROOTFS"

    echo "→ BOOT  ($BOOT)"
    mount -o loop,offset=$BOOT_OFFSET,rw "$OS_IMG" "$BOOT"

    echo ""
    echo "Pronto. Explore:"
    echo "  $ROOTFS   ← sistema de arquivos completo"
    echo "  $BOOT     ← kernel, DTB, boot.ini"
    echo ""
    echo "Para desmontar: sudo bash mount.sh umount"
}

case "${1:-mount}" in
    umount|unmount|u) umount_all ;;
    mount|*)          mount_all  ;;
esac
