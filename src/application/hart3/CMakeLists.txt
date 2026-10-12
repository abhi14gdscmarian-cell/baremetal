cmake_minimum_required(VERSION 3.15)

add_library(mpfs_hart3 STATIC u54_3.c)
target_include_directories(mpfs_hart3 PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/application
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_hart3 PUBLIC mpfs_build_options)
add_dependencies(mpfs_hart3 generate_hardware_config)
