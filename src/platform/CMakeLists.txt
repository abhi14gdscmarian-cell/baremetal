cmake_minimum_required(VERSION 3.15)

add_library(mpfs_platform INTERFACE)

add_subdirectory(mpfs_hal)
add_subdirectory(hal)
add_subdirectory(drivers)

add_library(mpfs_platform_extras INTERFACE)
target_link_libraries(mpfs_platform_extras INTERFACE
    mpfs_platform_hal
    mpfs_uart)

target_link_libraries(mpfs_platform INTERFACE
    mpfs_hal
    mpfs_platform_extras)
