cmake_minimum_required(VERSION 3.15)
project(personalized_tourism_system VERSION 1.0.0 LANGUAGES CXX)

# C++17 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -O2")
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
find_package(PostgreSQL REQUIRED)
include_directories(${PostgreSQL_INCLUDE_DIRS})

# 查找或下载依赖（使用 FetchContent）
include(FetchContent)

# nlohmann/json
FetchContent_Declare(
    json
    URL https://github.com/nlohmann/json/releases/download/v3.11.2/json.tar.xz
)
FetchContent_MakeAvailable(json)

# Crow HTTP 服务器（轻量级）
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
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# GeographicLib（地理计算）
FetchContent_Declare(
    geographiclib
    URL https://sourceforge.net/projects/geographiclib/files/dists-cpp/GeographicLib-2.3.tar.gz/download
)
# GeographicLib 需要手动配置，这里简化处理

# ============================================
# 头文件目录
# ============================================

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/include/graph
    ${CMAKE_SOURCE_DIR}/include/recommendation
    ${CMAKE_SOURCE_DIR}/include/search
    ${CMAKE_SOURCE_DIR}/include/database
    ${CMAKE_SOURCE_DIR}/include/utils
)

# ============================================
# 源文件
# ============================================

# 图数据结构模块
set(GRAPH_SOURCES
    src/graph/graph.cpp
    src/graph/dijkstra.cpp
    src/graph/astar.cpp
    src/graph/floyd.cpp
)

# 推荐算法模块
set(RECOMMENDATION_SOURCES
    src/recommendation/topk.cpp
    src/recommendation/kdtree.cpp
    src/recommendation/scoring.cpp
)

# 检索与压缩模块
set(SEARCH_SOURCES
    src/search/inverted_index.cpp
    src/search/trie.cpp
    src/search/huffman.cpp
)

# 数据库访问模块
set(DATABASE_SOURCES
    src/database/db_connection.cpp
    src/database/queries.cpp
)

# 控制器模块
set(CONTROLLER_SOURCES
    src/controllers/scenic_controller.cpp
    src/controllers/route_controller.cpp
    src/controllers/diary_controller.cpp
    src/controllers/user_controller.cpp
)

# 工具类
set(UTILS_SOURCES
    src/utils/json_utils.cpp
    src/utils/geo_utils.cpp
)

# 主程序
set(MAIN_SOURCES
    src/main.cpp
)

# 所有源文件
set(ALL_SOURCES
    ${GRAPH_SOURCES}
    ${RECOMMENDATION_SOURCES}
    ${SEARCH_SOURCES}
    ${DATABASE_SOURCES}
    ${CONTROLLER_SOURCES}
    ${UTILS_SOURCES}
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
        ${PostgreSQL_LIBRARIES}
        pthread  # Linux/Unix
)

# Windows 特定配置
if(WIN32)
    target_link_libraries(tourism_server
        PRIVATE
            ws2_32  # Windows Socket
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

# Top-K 算法测试
add_executable(test_topk
    tests/test_topk.cpp
    src/recommendation/topk.cpp
)
target_link_libraries(test_topk
    PRIVATE
        GTest::gtest_main
)

# 倒排索引测试
add_executable(test_inverted_index
    tests/test_inverted_index.cpp
    src/search/inverted_index.cpp
    src/search/trie.cpp
)
target_link_libraries(test_inverted_index
    PRIVATE
        GTest::gtest_main
        nlohmann_json::nlohmann_json
)

# 包含测试
include(GoogleTest)
gtest_discover_tests(test_graph)
gtest_discover_tests(test_dijkstra)
gtest_discover_tests(test_topk)
gtest_discover_tests(test_inverted_index)

# ============================================
# 安装规则
# ============================================

install(TARGETS tourism_server
    RUNTIME DESTINATION bin
)

install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/
    DESTINATION include
)

# ============================================
# 自定义目标（生成测试数据等）
# ============================================

add_custom_target(generate_test_data
    COMMAND python3 ${CMAKE_SOURCE_DIR}/../scripts/generate_test_data.py
    COMMENT "Generating test data..."
    VERBATIM
)

# ============================================
# 打印配置信息
# ============================================

message(STATUS "============================================")
message(STATUS "Personalized Tourism System Build Config")
message(STATUS "============================================")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "PostgreSQL Include: ${PostgreSQL_INCLUDE_DIRS}")
message(STATUS "PostgreSQL Libraries: ${PostgreSQL_LIBRARIES}")
message(STATUS "Install Prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "============================================")
