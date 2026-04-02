# Setting Up a New Zephyr Project (CMake, no west)

This guide walks through creating a **new** Zephyr application from scratch
using **pure CMake** – no `west` meta-tool required. It uses the Docker build
environment provided in this repository.

---

## Overview

```
┌─────────────────────────────────────────────────┐
│  Your application code  (app/)                  │
│    CMakeLists.txt  ←  finds Zephyr via CMake    │
│    prj.conf        ←  Kconfig settings          │
│    src/main.c      ←  application entry point   │
├─────────────────────────────────────────────────┤
│  Zephyr source tree  (/opt/zephyr in Docker)    │
│    kernel, drivers, devicetree, HALs …          │
├─────────────────────────────────────────────────┤
│  Zephyr SDK  (/opt/zephyr-sdk-* in Docker)      │
│    arm-zephyr-eabi toolchain                     │
└─────────────────────────────────────────────────┘
```

---

## Step 1 – Create the Project Directory

```bash
mkdir my_zephyr_app
cd my_zephyr_app
mkdir -p app/src
```

---

## Step 2 – Write `CMakeLists.txt`

Create `app/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.20.0)

# Locate Zephyr – ZEPHYR_BASE must be set in the environment
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(my_app LANGUAGES C)

target_sources(app PRIVATE src/main.c)
```

### Key points

- `find_package(Zephyr)` pulls in the entire Zephyr build system.
- After this call a CMake target called **`app`** is available; add your
  sources to it with `target_sources()`.
- There is **no need for `west build`** – a plain `cmake` + `ninja` workflow
  works.

---

## Step 3 – Write the Kconfig file (`prj.conf`)

Create `app/prj.conf` to enable the kernel features your application needs:

```kconfig
# Enable GPIO driver (for LEDs, buttons, etc.)
CONFIG_GPIO=y

# Enable serial / UART console
CONFIG_SERIAL=y
CONFIG_CONSOLE=y
CONFIG_UART_CONSOLE=y
CONFIG_PRINTK=y
```

> Full list of Kconfig symbols:  
> <https://docs.zephyrproject.org/latest/kconfig.html>

---

## Step 4 – Write the Application Code

Create `app/src/main.c`:

```c
#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

int main(void)
{
    printk("Hello from %s!\n", CONFIG_BOARD);

    while (1) {
        k_msleep(1000);
    }
    return 0;
}
```

---

## Step 5 – Identify Your Target Board

Zephyr has built-in board definitions under `$ZEPHYR_BASE/boards/`.  
For STM32 Nucleo boards the naming convention is:

| Physical Board      | Zephyr Board Name  |
|---------------------|--------------------|
| Nucleo-L010RB       | `nucleo_l010rb`    |
| Nucleo-F401RE       | `nucleo_f401re`    |
| Nucleo-L476RG       | `nucleo_l476rg`    |

You can search for all boards:

```bash
find $ZEPHYR_BASE/boards -name "*.yaml" | grep nucleo
```

---

## Step 6 – Identify Required Zephyr Submodules

When **not** using `west`, you must manually initialise the Git submodules that
your target board requires. For any STM32 target you need at least:

| Submodule path                 | What it provides            |
|--------------------------------|-----------------------------|
| `modules/hal/stm32`           | STM32 HAL drivers           |
| `modules/hal/cmsis`           | ARM CMSIS headers           |
| `modules/lib/picolibc`        | C library used by Zephyr    |

Inside the Zephyr source tree:

```bash
cd $ZEPHYR_BASE
git submodule init  modules/hal/stm32 modules/hal/cmsis modules/lib/picolibc
git submodule update --depth 1 modules/hal/stm32 modules/hal/cmsis modules/lib/picolibc
```

> **Note:** The Docker image already includes these submodules.

For other MCU families, substitute the appropriate HAL module, e.g.:
- Nordic nRF → `modules/hal/nordic`
- NXP → `modules/hal/nxp`
- Espressif → `modules/hal/espressif`

---

## Step 7 – Build with CMake

```bash
export ZEPHYR_BASE=/opt/zephyr          # Already set in Docker
export BOARD=nucleo_l010rb

cmake -B build -S app -GNinja -DBOARD=$BOARD
cmake --build build -- -j$(nproc)
```

### What happens under the hood

1. **CMake configure** – `find_package(Zephyr)` loads Zephyr's CMake
   modules which:
   - Parse the board's **devicetree** (`.dts`) to discover peripherals.
   - Process **Kconfig** (`prj.conf` + board defaults) to generate
     `autoconf.h`.
   - Set up cross-compilation with the Zephyr SDK toolchain.
2. **Build** – Ninja compiles the kernel, selected drivers, and your
   application, then links everything into a single firmware image.

### Build artefacts

```
build/zephyr/
├── zephyr.bin          # Raw binary
├── zephyr.elf          # ELF (includes debug info)
├── zephyr.hex          # Intel HEX
├── .config             # Final merged Kconfig
└── zephyr.dts          # Compiled devicetree
```

---

## Step 8 – Flash and Run

See the [DOCKER_HOWTO.md](DOCKER_HOWTO.md#step-4--flash-the-board) for
detailed flashing instructions (ST-Link, OpenOCD, drag-and-drop).

---

## Adding More Features

### Using Devicetree Overlays

To customise pin assignments or add peripherals, create an overlay file
`app/boards/nucleo_l010rb.overlay`:

```dts
/* Example: remap USART2 pins */
&usart2 {
    status = "okay";
    current-speed = <115200>;
};
```

Zephyr picks this up automatically when the file name matches the board.

### Adding Extra Source Files

```cmake
target_sources(app PRIVATE
    src/main.c
    src/sensors.c
    src/display.c
)
```

### Adding Libraries / Modules

Enable modules via Kconfig:

```kconfig
CONFIG_I2C=y
CONFIG_SENSOR=y
CONFIG_LOG=y
CONFIG_LOG_DEFAULT_LEVEL=3
```

---

## Quick-Reference: CMake Variables

| Variable               | Purpose                                    |
|------------------------|--------------------------------------------|
| `BOARD`               | Target board (e.g. `nucleo_l010rb`)         |
| `ZEPHYR_BASE`         | Path to Zephyr source tree                  |
| `CONF_FILE`           | Override prj.conf path                      |
| `DTC_OVERLAY_FILE`    | Extra devicetree overlay                    |
| `EXTRA_CONF_FILE`     | Additional Kconfig fragment                 |
| `CMAKE_BUILD_TYPE`    | `Debug` (default) or `Release`              |

Example with overrides:

```bash
cmake -B build -S app -GNinja \
    -DBOARD=nucleo_l010rb \
    -DCONF_FILE="prj.conf;extra.conf" \
    -DDTC_OVERLAY_FILE=app/boards/nucleo_l010rb.overlay
```

---

## Summary Cheatsheet

```bash
# 1. Build Docker image (one-time)
./build_docker.sh

# 2. Enter the container
./run_docker.sh

# 3. Build firmware
./build.sh            # or: ./build.sh clean

# 4. Exit container, flash on host
st-flash write build/zephyr/zephyr.bin 0x08000000

# 5. Open serial monitor
screen /dev/ttyACM0 115200
```
