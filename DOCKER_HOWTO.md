# Docker Build Environment for Zephyr RTOS

This document explains how to build and use the Docker image that provides a
self-contained build environment for the **Zephyr RTOS** project targeting the
**STM32 Nucleo L010RB** board.

---

## Prerequisites

| Tool    | Minimum Version |
|---------|-----------------|
| Docker  | 20.10+          |
| Bash    | 4.0+            |

Make sure the Docker daemon is running:

```bash
docker info
```

---

## Directory Layout

```
sample1/
├── docker/
│   └── Dockerfile          # Build environment image definition
├── app/
│   ├── CMakeLists.txt      # CMake project (no west required)
│   ├── prj.conf            # Zephyr Kconfig options
│   └── src/
│       └── main.c          # Hello World application
├── build_docker.sh         # Builds the Docker image
├── run_docker.sh           # Starts an interactive container
├── build.sh                # Builds the firmware inside the container
├── DOCKER_HOWTO.md         # ← You are here
└── ZEPHYR_PROJECT_SETUP.md # Guide for creating new Zephyr projects
```

---

## Step 1 – Build the Docker Image

```bash
chmod +x build_docker.sh
./build_docker.sh
```

This creates a Docker image called **`zephyr-build:latest`** that contains:

- Ubuntu 22.04 base
- CMake 3.28
- Ninja build system
- Zephyr SDK 0.16.8 (ARM toolchain)
- Zephyr RTOS v3.7.0 source tree at `/opt/zephyr`
- All required STM32 HAL / CMSIS submodules
- Python dependencies for Zephyr's build system

> **Tip:** Override the image name/tag with environment variables:
> ```bash
> ZEPHYR_DOCKER_IMAGE=my-zephyr ZEPHYR_DOCKER_TAG=v1 ./build_docker.sh
> ```

---

## Step 2 – Start the Container

```bash
chmod +x run_docker.sh
./run_docker.sh
```

This starts an **interactive bash shell** inside the container.  
Your project directory is mounted at `/workspace`.

---

## Step 3 – Build the Firmware (inside the container)

Once inside the container shell:

```bash
chmod +x build.sh
./build.sh
```

Or do a clean rebuild:

```bash
./build.sh clean
```

### Build Output

After a successful build the firmware files are located under `build/zephyr/`:

| File            | Description                    |
|-----------------|--------------------------------|
| `zephyr.bin`    | Raw binary for flashing        |
| `zephyr.elf`    | ELF with debug symbols         |
| `zephyr.hex`    | Intel HEX for ST-Link flashing |

---

## Step 4 – Flash the Board

### Option A – Using ST-Link (on the host, outside Docker)

```bash
# Install st-flash if not present
sudo apt-get install stlink-tools

# Flash
st-flash write build/zephyr/zephyr.bin 0x08000000
```

### Option B – Using OpenOCD (on the host)

```bash
openocd -f interface/stlink.cfg \
        -f target/stm32l0.cfg \
        -c "program build/zephyr/zephyr.elf verify reset exit"
```

### Option C – Drag-and-drop

The Nucleo board appears as a USB mass-storage device. Simply copy
`build/zephyr/zephyr.bin` to the mounted drive.

---

## Step 5 – Connect to Serial Console

The Nucleo L010RB exposes a virtual COM port through the ST-Link USB connector.

```bash
# Find the device (usually /dev/ttyACM0)
ls /dev/ttyACM*

# Connect (default Zephyr UART: 115200 8N1)
screen /dev/ttyACM0 115200
# or
minicom -D /dev/ttyACM0 -b 115200
```

You should see:

```
Hello World! Running on nucleo_l010rb
Blinking LED ...
```

---

## Environment Variables

| Variable                | Default         | Description                   |
|-------------------------|-----------------|-------------------------------|
| `ZEPHYR_DOCKER_IMAGE`  | `zephyr-build`  | Docker image name             |
| `ZEPHYR_DOCKER_TAG`    | `latest`        | Docker image tag              |
| `ZEPHYR_CONTAINER_NAME`| `zephyr-dev`    | Container name for run_docker |
| `BOARD`                | `nucleo_l010rb` | Target board for build.sh     |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `ZEPHYR_BASE is not set` | You are running `build.sh` outside the container. Use `run_docker.sh` first. |
| Docker build fails downloading SDK | Check internet connectivity; retry with `--no-cache`. |
| `Permission denied` on scripts | Run `chmod +x *.sh` |
| LED not blinking after flash | Ensure you selected the correct board and that the binary was fully written. |
