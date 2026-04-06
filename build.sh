#!/usr/bin/env bash
# =============================================================================
# build.sh – Build the Hello World application with CMake (no west)
#
# Usage (run inside the Docker container):
#   ./build.sh              # Build (default: nucleo_l010rb)
#   ./build.sh clean        # Remove build directory and rebuild
#   BOARD=other_board ./build.sh   # Override target board
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/app"
BUILD_DIR="${SCRIPT_DIR}/build"
#BOARD="${BOARD:-nucleo_l010rb}"
#F103RB
BOARD="${BOARD:-nucleo_l476rg}"

# ── Resolve ZEPHYR_BASE ────────────────────────────────────────────────────
# Inside Docker it is /zephyrproject/zephyr (set by run_docker.sh).
# On the host it defaults to ./zephyrproject/zephyr.
if [[ -z "${ZEPHYR_BASE:-}" ]]; then
    if [[ -d "/zephyrproject/zephyr" ]]; then
        export ZEPHYR_BASE=/zephyrproject/zephyr
    elif [[ -d "${SCRIPT_DIR}/zephyrproject/zephyr" ]]; then
        export ZEPHYR_BASE="${SCRIPT_DIR}/zephyrproject/zephyr"
    else
        echo "ERROR: ZEPHYR_BASE is not set and zephyrproject/ was not found."
        echo "       Run './fetch_zephyr.sh' first, then use './run_docker.sh'."
        exit 1
    fi
fi

# ── Resolve ZEPHYR_MODULES ─────────────────────────────────────────────────
if [[ -z "${ZEPHYR_MODULES:-}" ]]; then
    if [[ -d "/zephyrproject/modules" ]]; then
        MOD_ROOT="/zephyrproject/modules"
    elif [[ -d "${SCRIPT_DIR}/zephyrproject/modules" ]]; then
        MOD_ROOT="${SCRIPT_DIR}/zephyrproject/modules"
    else
        echo "ERROR: Cannot find modules directory."
        echo "       Run './fetch_zephyr.sh' first."
        exit 1
    fi
    export ZEPHYR_MODULES="${MOD_ROOT}/hal/stm32;${MOD_ROOT}/hal/cmsis;${MOD_ROOT}/lib/picolibc"
fi

# Handle 'clean' argument
if [[ "${1:-}" == "clean" ]]; then
    echo "Cleaning build directory ..."
    rm -rf "${BUILD_DIR}"
fi

echo "============================================="
echo "  Board          : ${BOARD}"
echo "  ZEPHYR_BASE    : ${ZEPHYR_BASE}"
echo "  ZEPHYR_MODULES : ${ZEPHYR_MODULES}"
echo "  App dir        : ${APP_DIR}"
echo "  Build dir      : ${BUILD_DIR}"
echo "============================================="

# Configure
cmake -B "${BUILD_DIR}" -S "${APP_DIR}" \
    -GNinja \
    -DBOARD="${BOARD}" \
    -DZEPHYR_MODULES="${ZEPHYR_MODULES}"

# Build
cmake --build "${BUILD_DIR}" -- -j "$(nproc)"

echo ""
echo "Build complete."
echo "Firmware binary : ${BUILD_DIR}/zephyr/zephyr.bin"
echo "Firmware ELF    : ${BUILD_DIR}/zephyr/zephyr.elf"
echo "Firmware HEX    : ${BUILD_DIR}/zephyr/zephyr.hex"
