cmake_minimum_required(VERSION 3.15)

add_library(mpfs_uart_mapping STATIC uart_mapping.c)
target_include_directories(mpfs_uart_mapping PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/application
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_uart_mapping PUBLIC mpfs_build_options)
add_dependencies(mpfs_uart_mapping generate_hardware_config)
