enable_language(CXX)

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)

FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
)

if(WIN32)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
endif()

set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

file(GLOB_RECURSE GTEST_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*_test.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/*_tests.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_*.cpp"
)

add_executable(unit_tests
    "${CMAKE_CURRENT_SOURCE_DIR}/gtest_main.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/mocks/e51_mock.cpp"
    ${GTEST_SOURCES}
)
target_compile_features(unit_tests PRIVATE cxx_std_17)
target_include_directories(unit_tests PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/mocks"
)
target_link_libraries(unit_tests PRIVATE GTest::gtest)

add_subdirectory(
    "${CMAKE_SOURCE_DIR}/src/application"
    "${CMAKE_CURRENT_BINARY_DIR}/application"
)

include(GoogleTest)
gtest_discover_tests(unit_tests)
