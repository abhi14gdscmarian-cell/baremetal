cmake_minimum_required(VERSION 3.15)

add_library(mpfs_hal_startup STATIC
    mss_utils.S
    newlib_stubs.c
    system_startup.c)

target_include_directories(mpfs_hal_startup PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_hal_startup PUBLIC mpfs_build_options)
add_dependencies(mpfs_hal_startup generate_hardware_config)
