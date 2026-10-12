cmake_minimum_required(VERSION 3.15)

add_library(mpfs_hal INTERFACE)

add_subdirectory(startup_gcc)
add_subdirectory(common)

target_sources(mpfs_hal INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/startup_gcc/mss_entry.S")

target_link_libraries(mpfs_hal INTERFACE
    mpfs_hal_startup
    mpfs_hal_nwc
    mpfs_hal_common)
