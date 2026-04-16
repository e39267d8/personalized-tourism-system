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
# 依赖查找
# ============================================

# 查找 PostgreSQL (libpqxx)
find_package(PostgreSQL QUIET)
if(PostgreSQL_FOUND)
    include_directories(${PostgreSQL_INCLUDE_DIRS})
    message(STATUS "PostgreSQL found: ${PostgreSQL_INCLUDE_DIRS}")
else()
    message(WARNING "PostgreSQL not found, some features will be disabled")
endif()

# 下载依赖（使用 FetchContent）
include(FetchContent)

# nlohmann/json
FetchContent_Declare(
    json
    URL https://github.com/nlohmann/json/releases/download/v3.11.2/json.tar.xz
)
FetchContent_MakeAvailable(json)

# Crow HTTP 服务器
FetchContent_Declare(
    crow
    GIT_REPOSITORY https://github.com/CrowCpp/Crow.git
    GIT_TAG v1.0+5
)
FetchContent_MakeAvailable(crow)

# GoogleTest（测试框架）
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# ============================================
# 头文件目录
# ============================================

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/include/graph
)

# ============================================
# 源文件（只包含实际存在的文件）
# ============================================

# 图数据结构模块
set(GRAPH_SOURCES
    src/graph/graph.cpp
    src/graph/dijkstra.cpp
)

# 主程序
set(MAIN_SOURCES
    src/main.cpp
)

# 所有源文件
set(ALL_SOURCES
    ${GRAPH_SOURCES}
    ${MAIN_SOURCES}
)

# ============================================
# 主可执行文件
# ============================================

add_executable(tourism_server
    ${ALL_SOURCES}
)

# 链接库
target_link_libraries(tourism_server
    PRIVATE
        nlohmann_json::nlohmann_json
        Crow::Crow
)

if(PostgreSQL_FOUND)
    target_link_libraries(tourism_server
        PRIVATE
            ${PostgreSQL_LIBRARIES}
    )
endif()

# Windows 特定配置
if(WIN32)
    target_link_libraries(tourism_server
        PRIVATE
            ws2_32
            wsock32
    )
endif()

# 编译定义
target_compile_definitions(tourism_server
    PRIVATE
        CROW_ENABLE_DEBUG
        CROW_LOG_LEVEL=0
)

# ============================================
# 测试可执行文件
# ============================================

enable_testing()

# 图算法测试
add_executable(test_graph
    tests/test_graph.cpp
    src/graph/graph.cpp
)
target_link_libraries(test_graph
    PRIVATE
        GTest::gtest_main
        nlohmann_json::nlohmann_json
)

# Dijkstra 算法测试
add_executable(test_dijkstra
    tests/test_dijkstra.cpp
    src/graph/graph.cpp
    src/graph/dijkstra.cpp
)
target_link_libraries(test_dijkstra
    PRIVATE
        GTest::gtest_main
        nlohmann_json::nlohmann_json
)

# 包含测试
include(GoogleTest)
gtest_discover_tests(test_graph)
gtest_discover_tests(test_dijkstra)

# ============================================
# 打印配置信息
# ============================================

message(STATUS "============================================")
message(STATUS "Personalized Tourism System Build Config")
message(STATUS "============================================")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Source Files:")
message(STATUS "  - Graph: ${GRAPH_SOURCES}")
message(STATUS "  - Main: ${MAIN_SOURCES}")
message(STATUS "============================================")
