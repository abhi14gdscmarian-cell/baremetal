cmake_minimum_required(VERSION 3.15)

if(BUILD_GTEST)
    add_subdirectory(hart0)
    add_subdirectory(hart1)
    return()
endif()

add_library(mpfs_application INTERFACE)

add_subdirectory(inc)
add_subdirectory(hart4)
add_subdirectory(hart3)
add_subdirectory(hart2)
add_subdirectory(hart1)
add_subdirectory(hart0)

target_link_libraries(mpfs_application INTERFACE
    mpfs_uart_mapping
    mpfs_hart4
    mpfs_hart3
    mpfs_hart2
    mpfs_hart1
    mpfs_hart0)
