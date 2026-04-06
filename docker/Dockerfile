# =============================================================================
# Dockerfile for Zephyr RTOS Build Environment
# Target: STM32 Nucleo L010RB (nucleo_l010rb)
#
# This image contains ONLY the build toolchain (SDK, CMake, Ninja, Python).
# Zephyr source and HAL modules live on the host and are mounted at runtime.
# =============================================================================
FROM ubuntu:22.04

ARG ZEPHYR_SDK_VERSION=0.16.8
ARG CMAKE_VERSION=3.28.1
ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer="zephyr-dev"
LABEL description="Zephyr RTOS build toolchain for STM32 Nucleo L010RB"

# ---------------------------------------------------------------------------
# 1. Install system dependencies
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ninja-build \
    gperf \
    ccache \
    dfu-util \
    device-tree-compiler \
    wget \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-tk \
    python3-wheel \
    python3-venv \
    xz-utils \
    file \
    make \
    gcc \
    gcc-multilib \
    g++-multilib \
    libsdl2-dev \
    libmagic1 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Install a recent CMake (system package is often too old)
# ---------------------------------------------------------------------------
RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    -O /tmp/cmake-install.sh \
    && chmod +x /tmp/cmake-install.sh \
    && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/cmake-install.sh

# ---------------------------------------------------------------------------
# 3. Install Zephyr SDK (contains ARM cross-compiler toolchain)
# ---------------------------------------------------------------------------
WORKDIR /opt
RUN wget -q https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && tar xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && cd zephyr-sdk-${ZEPHYR_SDK_VERSION} \
    && ./setup.sh -t arm-zephyr-eabi -c

ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${ZEPHYR_SDK_VERSION}
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# ---------------------------------------------------------------------------
# 3.5. Install Python dependencies needed by Zephyr
# ---------------------------------------------------------------------------
RUN pip3 install --no-cache-dir \
    west \
    pyelftools \
    pyyaml \
    pykwalify \
    canopen \
    packaging \
    progress \
    psutil \
    pylink-square \
    anytree \
    intelhex \
    cryptography \
    gcovr \
    pillow \
    grpcio-tools \
    lpc-checksum \
    pylint \
    colorama \
    natsort \
    prettytable \
    tabulate

# ---------------------------------------------------------------------------
# 4. Set up workspace directory
# ---------------------------------------------------------------------------
RUN mkdir -p /workspace /zephyrproject
WORKDIR /workspace

CMD ["/bin/bash"]
