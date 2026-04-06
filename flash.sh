#!/usr/bin/env bash
# =============================================================================
# flash.sh – Flash built firmware to the STM32 Nucleo board
#
# Usage (run on the HOST, not inside Docker):
#   ./flash.sh                  # Auto-detect method, flash zephyr.bin
#   ./flash.sh openocd          # Force OpenOCD
#   ./flash.sh stlink           # Force st-flash
#   ./flash.sh dnd              # Drag-and-drop (copy to mass storage)
#
# Environment:
#   BUILD_DIR    Override build directory (default: ./build)
#   FIRMWARE     Override firmware file   (default: BUILD_DIR/zephyr/zephyr.bin)
#   FLASH_ADDR   Override flash address   (default: 0x08000000)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"
FIRMWARE="${FIRMWARE:-${BUILD_DIR}/zephyr/zephyr.bin}"
FLASH_ADDR="${FLASH_ADDR:-0x08000000}"
METHOD="${1:-auto}"

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
if [[ ! -f "${FIRMWARE}" ]]; then
    echo "ERROR: Firmware not found at: ${FIRMWARE}"
    echo "       Run './build.sh' first (inside the Docker container)."
    exit 1
fi

FIRMWARE_SIZE=$(stat -c%s "${FIRMWARE}" 2>/dev/null || stat -f%z "${FIRMWARE}")
echo "============================================="
echo "  Firmware : ${FIRMWARE}"
echo "  Size     : ${FIRMWARE_SIZE} bytes"
echo "  Address  : ${FLASH_ADDR}"
echo "  Method   : ${METHOD}"
echo "============================================="

# ---------------------------------------------------------------------------
# Flash functions
# ---------------------------------------------------------------------------
flash_stlink() {
    if ! command -v st-flash &>/dev/null; then
        echo "ERROR: st-flash not found."
        echo "       Install with: sudo apt-get install stlink-tools"
        return 1
    fi
    echo "[st-flash] Flashing ..."
    st-flash write "${FIRMWARE}" "${FLASH_ADDR}"
    echo "[st-flash] Done."
}

flash_openocd() {
    if ! command -v openocd &>/dev/null; then
        echo "ERROR: openocd not found."
        echo "       Install with: sudo apt-get install openocd"
        return 1
    fi
    local ELF="${BUILD_DIR}/zephyr/zephyr.elf"
    if [[ -f "${ELF}" ]]; then
        echo "[openocd] Flashing ELF (includes debug symbols) ..."
        openocd \
            -f interface/stlink.cfg \
            -f target/stm32l4x.cfg \
            -c "program ${ELF} verify reset exit"
    else
        echo "[openocd] Flashing BIN ..."
        openocd \
            -f interface/stlink.cfg \
            -f target/stm32l4x.cfg \
            -c "program ${FIRMWARE} ${FLASH_ADDR} verify reset exit"
    fi
    echo "[openocd] Done."
}

flash_dnd() {
    # Nucleo boards appear as a USB mass-storage device named NOD_xxxxx
    local MOUNT_POINT=""
    for dir in /media/${USER}/NOD_* /run/media/${USER}/NOD_* /media/NOD_*; do
        if [[ -d "${dir}" ]]; then
            MOUNT_POINT="${dir}"
            break
        fi
    done

    if [[ -z "${MOUNT_POINT}" ]]; then
        echo "ERROR: Nucleo mass-storage device not found."
        echo "       Make sure the board is connected via USB and mounted."
        echo "       Look for a volume named NOD_xxxxx."
        return 1
    fi

    echo "[dnd] Copying firmware to ${MOUNT_POINT} ..."
    cp "${FIRMWARE}" "${MOUNT_POINT}/"
    sync
    echo "[dnd] Done. The board should reset automatically."
}

# ---------------------------------------------------------------------------
# Auto-detect or use the specified method
# ---------------------------------------------------------------------------
case "${METHOD}" in
    stlink)
        flash_stlink
        ;;
    openocd)
        flash_openocd
        ;;
    dnd|drag-and-drop)
        flash_dnd
        ;;
    auto)
        if command -v st-flash &>/dev/null; then
            flash_stlink
        elif command -v openocd &>/dev/null; then
            flash_openocd
        else
            echo "No st-flash or openocd found, trying drag-and-drop ..."
            flash_dnd
        fi
        ;;
    *)
        echo "Unknown method: ${METHOD}"
        echo "Usage: $0 [auto|stlink|openocd|dnd]"
        exit 1
        ;;
esac

echo ""
echo "Flash complete. Connect to serial console with:"
echo "  screen /dev/ttyACM0 115200"
