#!/usr/bin/env bash
# =============================================================================
# build_docker.sh – Build the Zephyr development Docker image
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${ZEPHYR_DOCKER_IMAGE:-zephyr-build}"
IMAGE_TAG="${ZEPHYR_DOCKER_TAG:-latest}"

echo "============================================="
echo "  Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "============================================="

docker build \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f "${SCRIPT_DIR}/docker/Dockerfile" \
    "${SCRIPT_DIR}/docker"

echo ""
echo "Done.  Image '${IMAGE_NAME}:${IMAGE_TAG}' is ready."
echo "Run './run_docker.sh' to start a container."
