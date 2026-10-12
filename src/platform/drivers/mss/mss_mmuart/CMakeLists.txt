cmake_minimum_required(VERSION 3.15)

add_library(mpfs_uart STATIC mss_uart.c)

target_include_directories(mpfs_uart PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_uart PUBLIC mpfs_build_options)
add_dependencies(mpfs_uart generate_hardware_config)
