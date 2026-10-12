cmake_minimum_required(VERSION 3.15)

add_library(mpfs_hal_nwc STATIC
    mss_cfm.c
    mss_ddr.c
    mss_ddr_debug.c
    mss_ddr_test_pattern.c
    mss_io.c
    mss_nwc_init.c
    mss_pll.c
    mss_sgmii.c)

target_include_directories(mpfs_hal_nwc PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_hal_nwc PUBLIC mpfs_build_options)
add_dependencies(mpfs_hal_nwc generate_hardware_config)
