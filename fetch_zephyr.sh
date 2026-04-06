#!/usr/bin/env bash
# =============================================================================
# fetch_zephyr.sh – Clone Zephyr RTOS and required HAL modules
#
# This script creates a "zephyrproject/" directory alongside the project with
# the Zephyr kernel and the modules needed for STM32 targets.
#
# Layout after running:
#
#   zephyrproject/
#   ├── zephyr/                  ← Zephyr kernel (ZEPHYR_BASE)
#   └── modules/
#       ├── hal/stm32/           ← STM32 HAL drivers
#       ├── hal/cmsis/           ← ARM CMSIS headers
#       └── lib/picolibc/        ← C library used by Zephyr
#
# Usage:
#   ./fetch_zephyr.sh                     # default version (v3.7.0)
#   ZEPHYR_VERSION=v3.6.0 ./fetch_zephyr.sh  # override version
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZEPHYR_VERSION="${ZEPHYR_VERSION:-v3.7.0}"
ZEPHYR_PROJECT_DIR="${SCRIPT_DIR}/zephyrproject"

echo "============================================="
echo "  Zephyr version : ${ZEPHYR_VERSION}"
echo "  Target dir     : ${ZEPHYR_PROJECT_DIR}"
echo "============================================="

# ── 1. Clone Zephyr kernel ──────────────────────────────────────────────────
if [[ -d "${ZEPHYR_PROJECT_DIR}/zephyr" ]]; then
    echo "[skip] zephyr/ already exists"
else
    echo "[clone] zephyr kernel ..."
    mkdir -p "${ZEPHYR_PROJECT_DIR}"
    git clone --branch "${ZEPHYR_VERSION}" --depth 1 \
        https://github.com/zephyrproject-rtos/zephyr.git \
        "${ZEPHYR_PROJECT_DIR}/zephyr"
fi

# ── 2. Clone required modules ───────────────────────────────────────────────
# Each entry: <repo-name>  <local-path>
MODULES=(
    "hal_stm32    modules/hal/stm32"
    "cmsis        modules/hal/cmsis"
    "picolibc     modules/lib/picolibc"
)

for entry in "${MODULES[@]}"; do
    read -r repo_name local_path <<< "${entry}"
    dest="${ZEPHYR_PROJECT_DIR}/${local_path}"

    if [[ -d "${dest}" ]]; then
        echo "[skip] ${local_path} already exists"
    else
        echo "[clone] ${local_path} ..."
        mkdir -p "$(dirname "${dest}")"
        git clone --depth 1 \
            "https://github.com/zephyrproject-rtos/${repo_name}.git" \
            "${dest}"
    fi
done

# ── 3. Done ─────────────────────────────────────────────────────────────────
echo ""
echo "============================================="
echo "  Done!  Zephyr workspace ready at:"
echo "    ${ZEPHYR_PROJECT_DIR}"
echo ""
echo "  ZEPHYR_BASE = ${ZEPHYR_PROJECT_DIR}/zephyr"
echo ""
echo "  Remember to install Python dependencies inside"
echo "  your Dockerfile (see fetch_zephyr.sh for details)."
echo "============================================="
