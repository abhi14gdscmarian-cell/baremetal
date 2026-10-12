cmake_minimum_required(VERSION 3.15)

add_library(mpfs_hal_common STATIC
    mss_axiswitch.c
    mss_beu.c
    mss_clint.c
    mss_h2f.c
    mss_irq_handler_stubs.c
    mss_l2_cache.c
    mss_mpu.c
    mss_mtrap.c
    mss_peripherals.c
    mss_plic.c
    mss_pmp.c
    mss_util.c)

target_include_directories(mpfs_hal_common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_hal_common PUBLIC mpfs_build_options)
add_dependencies(mpfs_hal_common generate_hardware_config)

add_subdirectory(nwc)
