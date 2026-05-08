cmake_minimum_required(VERSION 3.15)
project(personalized_tourism_system VERSION 1.0.0 LANGUAGES CXX)

# C++17 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0 -DDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")

# 输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# ============================================
# 依赖（使用 MSYS2 pacman 已安装的包，不从 GitHub 下载）
# ============================================

# nlohmann/json（当前服务端代码未直接使用；安装后可供后续模块链接）
find_package(nlohmann_json QUIET)
if(nlohmann_json_FOUND)
    message(STATUS "nlohmann_json found")
else()
    message(STATUS "nlohmann_json not found; building server without it")
endif()

# GoogleTest（未安装时跳过单元测试目标，避免阻塞服务端构建）
find_package(GTest QUIET)
if(GTest_FOUND)
    message(STATUS "GTest found; tests enabled")
else()
    message(STATUS "GTest not found; tests disabled")
endif()

# Crow 使用本地头文件（crow_all.h 已存在于 include/）
# ASIO 使用 standalone 版本
find_path(ASIO_INCLUDE_DIR asio.hpp)
if(NOT ASIO_INCLUDE_DIR)
    message(FATAL_ERROR "Standalone Asio was not found. Install asio/asio-devel or add the directory containing asio.hpp to CMAKE_PREFIX_PATH.")
endif()
message(STATUS "Asio found: ${ASIO_INCLUDE_DIR}")

# ============================================
# 头文件目录
# ============================================
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/include/graph
)

# ============================================
# 源文件
# ============================================
set(GRAPH_SOURCES
    src/graph/graph.cpp
    src/graph/dijkstra.cpp
)
set(MAIN_SOURCES
    src/main.cpp
)
set(ALL_SOURCES
    ${GRAPH_SOURCES}
    ${MAIN_SOURCES}
)

# ============================================
# 主可执行文件
# ============================================
add_executable(tourism_server ${ALL_SOURCES})

target_include_directories(tourism_server PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/include/graph
    ${ASIO_INCLUDE_DIR}
)

target_compile_definitions(tourism_server PRIVATE
    ASIO_STANDALONE
    _WIN32_WINNT=0x0601
)

if(nlohmann_json_FOUND)
    target_link_libraries(tourism_server PRIVATE nlohmann_json::nlohmann_json)
endif()

if(WIN32)
    target_link_libraries(tourism_server PRIVATE ws2_32 wsock32)
endif()

# ============================================
# 单元测试
# ============================================
if(GTest_FOUND)
    enable_testing()

    add_executable(test_graph tests/test_graph.cpp src/graph/graph.cpp)
    target_include_directories(test_graph PRIVATE
        ${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/include/graph)
    target_link_libraries(test_graph PRIVATE GTest::gtest_main)

    add_executable(test_dijkstra tests/test_dijkstra.cpp src/graph/graph.cpp src/graph/dijkstra.cpp)
    target_include_directories(test_dijkstra PRIVATE
        ${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/include/graph)
    target_link_libraries(test_dijkstra PRIVATE GTest::gtest_main)

    include(GoogleTest)
    gtest_discover_tests(test_graph)
    gtest_discover_tests(test_dijkstra)
endif()

message(STATUS "============================================")
message(STATUS "Personalized Tourism System Build Config")
message(STATUS "============================================")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Source Files:")
message(STATUS "  - Graph: ${GRAPH_SOURCES}")
message(STATUS "  - Main: ${MAIN_SOURCES}")
message(STATUS "============================================")
