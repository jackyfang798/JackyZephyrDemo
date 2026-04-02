#!/usr/bin/env bash
# =============================================================================
# build.sh – Build the Hello World application with CMake (no west)
#
# Usage:
#   ./build.sh              # Build (default: nucleo_l010rb)
#   ./build.sh clean        # Remove build directory and rebuild
#   BOARD=other_board ./build.sh   # Override target board
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/app"
BUILD_DIR="${SCRIPT_DIR}/build"
BOARD="${BOARD:-nucleo_l010rb}"

# Ensure ZEPHYR_BASE is set (should already be set inside the Docker container)
if [[ -z "${ZEPHYR_BASE:-}" ]]; then
    echo "ERROR: ZEPHYR_BASE is not set."
    echo "       Inside the Docker container it should be /opt/zephyr."
    echo "       Export it before running this script:"
    echo "         export ZEPHYR_BASE=/opt/zephyr"
    exit 1
fi

# Handle 'clean' argument
if [[ "${1:-}" == "clean" ]]; then
    echo "Cleaning build directory ..."
    rm -rf "${BUILD_DIR}"
fi

echo "============================================="
echo "  Board      : ${BOARD}"
echo "  ZEPHYR_BASE: ${ZEPHYR_BASE}"
echo "  App dir    : ${APP_DIR}"
echo "  Build dir  : ${BUILD_DIR}"
echo "============================================="

# Configure
cmake -B "${BUILD_DIR}" -S "${APP_DIR}" \
    -GNinja \
    -DBOARD="${BOARD}" \
    -DZEPHYR_BASE="${ZEPHYR_BASE}"

# Build
cmake --build "${BUILD_DIR}" -- -j "$(nproc)"

echo ""
echo "Build complete."
echo "Firmware binary : ${BUILD_DIR}/zephyr/zephyr.bin"
echo "Firmware ELF    : ${BUILD_DIR}/zephyr/zephyr.elf"
echo "Firmware HEX    : ${BUILD_DIR}/zephyr/zephyr.hex"
