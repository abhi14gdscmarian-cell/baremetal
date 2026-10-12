cmake_minimum_required(VERSION 3.15)

add_library(mpfs_platform_hal STATIC
    hal_irq.c
    hw_reg_access.S)

target_include_directories(mpfs_platform_hal PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_platform_hal PUBLIC mpfs_build_options)
add_dependencies(mpfs_platform_hal generate_hardware_config)
