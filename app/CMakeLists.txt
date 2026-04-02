# =============================================================================
# CMakeLists.txt – Hello World for Zephyr (pure CMake, no west)
# Target board: STM32 Nucleo L010RB  (nucleo_l010rb)
# =============================================================================
cmake_minimum_required(VERSION 3.20.0)

# --------------------------------------------------------------------------
# ZEPHYR_BASE must point to the Zephyr source tree.
# Inside the Docker container it is /opt/zephyr.
# On a host system, set it via environment variable or pass -DZEPHYR_BASE=...
# --------------------------------------------------------------------------
if(NOT DEFINED ENV{ZEPHYR_BASE} AND NOT DEFINED ZEPHYR_BASE)
    message(FATAL_ERROR
        "ZEPHYR_BASE is not set. "
        "Export ZEPHYR_BASE to point to the Zephyr source tree, e.g.:\n"
        "  export ZEPHYR_BASE=/opt/zephyr"
    )
endif()

# Pull in the Zephyr build system (this replaces the west build step)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(hello_world LANGUAGES C)

target_sources(app PRIVATE src/main.c)
