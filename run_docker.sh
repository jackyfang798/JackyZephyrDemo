#!/usr/bin/env bash
# =============================================================================
# run_docker.sh – Launch the Zephyr build container interactively
#
# Mounts:
#   - Project directory     → /workspace
#   - zephyrproject/        → /zephyrproject  (Zephyr source + modules)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${ZEPHYR_DOCKER_IMAGE:-zephyr-build}"
IMAGE_TAG="${ZEPHYR_DOCKER_TAG:-latest}"
CONTAINER_NAME="${ZEPHYR_CONTAINER_NAME:-zephyr-dev}"
ZEPHYR_PROJECT_DIR="${SCRIPT_DIR}/zephyrproject"

# Verify that fetch_zephyr.sh has been run
if [[ ! -d "${ZEPHYR_PROJECT_DIR}/zephyr" ]]; then
    echo "ERROR: ${ZEPHYR_PROJECT_DIR}/zephyr not found."
    echo "       Run './fetch_zephyr.sh' first to download Zephyr and modules."
    exit 1
fi

echo "============================================="
echo "  Starting container: ${CONTAINER_NAME}"
echo "  Image : ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  Mount : ${SCRIPT_DIR}            -> /workspace"
echo "  Mount : ${ZEPHYR_PROJECT_DIR}    -> /zephyrproject"
echo "============================================="

docker run -it --rm \
    --name "${CONTAINER_NAME}" \
    -v "${SCRIPT_DIR}":/workspace \
    -v "${ZEPHYR_PROJECT_DIR}":/zephyrproject \
    -e ZEPHYR_BASE=/zephyrproject/zephyr \
    -e ZEPHYR_MODULES="/zephyrproject/modules/hal/stm32;/zephyrproject/modules/hal/cmsis;/zephyrproject/modules/lib/picolibc" \
    -w /workspace \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /bin/bash
