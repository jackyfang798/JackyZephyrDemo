#!/usr/bin/env bash
# =============================================================================
# run_docker.sh – Launch the Zephyr build container interactively
#
# The current directory (project root) is mounted at /workspace inside the
# container so you can edit files on the host and build inside Docker.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${ZEPHYR_DOCKER_IMAGE:-zephyr-build}"
IMAGE_TAG="${ZEPHYR_DOCKER_TAG:-latest}"
CONTAINER_NAME="${ZEPHYR_CONTAINER_NAME:-zephyr-dev}"

echo "============================================="
echo "  Starting container: ${CONTAINER_NAME}"
echo "  Image : ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  Mount : ${SCRIPT_DIR} -> /workspace"
echo "============================================="

docker run -it --rm \
    --name "${CONTAINER_NAME}" \
    -v "${SCRIPT_DIR}":/workspace \
    -w /workspace \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /bin/bash
