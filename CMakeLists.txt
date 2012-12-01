
# :mode=cmake:noTabs=true:tabSize=4:

cmake_minimum_required(VERSION 2.8)

project(MINETEST_IRC C)

set(MINETEST_IRC_VERSION 0.1.0)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/lua)

add_subdirectory(src)
