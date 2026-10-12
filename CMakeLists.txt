cmake_minimum_required(VERSION 3.15.3)

set(CMAKE_VERBOSE_MAKEFILE ON)
option(BUILD_GTEST "Build host unit tests (gtest) instead of the ARM firmware" OFF)

if(NOT BUILD_GTEST)
	set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/riscv64-unknown-elf-toolchain.cmake" CACHE FILEPATH "RISC-V toolchain file")
endif()

project(mpfs-blank-baremetal C ASM)

if(BUILD_GTEST)

	message(STATUS "BUILD_GTEST=ON -> building host gtest suite from src/tests/")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage -O0 -g")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -O0 -g")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
	enable_testing()
	add_subdirectory(src/tests)


else()
	# Keep source-level breakpoints available in every firmware library, not only main.c.
	add_compile_options(-O0 -g3)

    set(EXECUTABLE ${PROJECT_NAME}.elf)
    set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)
    set(BOARD_DIR ${SRC_DIR}/boards/icicle-kit-es)
    set(PLATFORM_CONFIG_DIR ${BOARD_DIR}/platform_config/lim-debug)
    set(LINKER_FILE ${PLATFORM_CONFIG_DIR}/linker/mpfs-lim.ld)

    set(PYTHON_EXECUTABLE
    "C:/Microchip/SoftConsole-v2022.2-RISC-V-747/python3/python.exe"
    CACHE FILEPATH "Python used by the hardware configuration generator")

    set(CMAKE_C_STANDARD 11)
    set(CMAKE_C_STANDARD_REQUIRED ON)
    set(CMAKE_C_EXTENSIONS ON)

    add_library(mpfs_build_options INTERFACE)
    target_compile_options(mpfs_build_options INTERFACE
        -march=rv64gc
        -mabi=lp64d
        -mcmodel=medany
        -msmall-data-limit=8
        -mstrict-align
        -mno-save-restore
        -O0
        -fmessage-length=0
        -fsigned-char
        -ffunction-sections
        -fdata-sections
        -g3
        --specs=nano.specs
        $<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes>
        $<$<COMPILE_LANGUAGE:C>:-Wbad-function-cast>
    )
    target_compile_definitions(mpfs_build_options INTERFACE
        $<$<COMPILE_LANGUAGE:C>:ICICLE_KIT_ES>)

    add_custom_target(generate_hardware_config
        COMMAND ${PYTHON_EXECUTABLE}
            ${SRC_DIR}/platform/soc_config_generator/mpfs_configuration_generator.py
            ${BOARD_DIR}/fpga_design/design_description/
            ${BOARD_DIR}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Generating MPFS hardware configuration headers")

    add_subdirectory(src)

    add_executable(${EXECUTABLE})
    target_link_libraries(${EXECUTABLE} PRIVATE
        mpfs_platform
        mpfs_application)

    target_link_options(${EXECUTABLE} PRIVATE
        -march=rv64gc
        -mabi=lp64d
        -mcmodel=medany
        -msmall-data-limit=8
        -mstrict-align
        -mno-save-restore
        -O0
        -fmessage-length=0
        -fsigned-char
        -ffunction-sections
        -fdata-sections
        -g3
        -T${LINKER_FILE}
        -nostartfiles
        -Wl,--gc-sections
        -Wl,-Map=${PROJECT_NAME}.map
        --specs=nano.specs
        --specs=nosys.specs)

    add_custom_command(TARGET ${EXECUTABLE} POST_BUILD
        COMMAND ${CMAKE_SIZE_UTIL} --format=sysv --totals --radix=16 ${EXECUTABLE}
        COMMAND ${CMAKE_OBJCOPY} -O srec --srec-len=64
            ${EXECUTABLE} ${PROJECT_NAME}.s19
        COMMAND ${CMAKE_OBJCOPY} -O ihex
            ${EXECUTABLE} ${PROJECT_NAME}.hex
        COMMAND ${CMAKE_OBJCOPY} -O binary
            ${EXECUTABLE} ${PROJECT_NAME}.bin
        COMMENT "Printing ELF size and generating firmware images")
endif()