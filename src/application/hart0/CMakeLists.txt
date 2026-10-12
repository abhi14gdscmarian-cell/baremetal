cmake_minimum_required(VERSION 3.15)

if (BUILD_GTEST)
    add_subdirectory(test)
    return()
endif()

add_library(mpfs_hart0 STATIC e51.c)

target_include_directories(mpfs_hart0 PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/application
    ${CMAKE_SOURCE_DIR}/src/platform
    ${BOARD_DIR}
    ${PLATFORM_CONFIG_DIR})
target_link_libraries(mpfs_hart0 PUBLIC mpfs_build_options)
add_dependencies(mpfs_hart0 generate_hardware_config)
