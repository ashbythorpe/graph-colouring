cmake_minimum_required(VERSION 3.10)
project(GraphColouring)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()

find_package(Boost REQUIRED)

option(BENCHMARK_MEMORY "" OFF)

add_executable(graph-colouring
  src/main.cpp
  src/boost.cpp
  src/colouring.hpp
  src/greedy.cpp
  src/graph.cpp
  src/memory_tracker.cpp
  src/palette.cpp
  src/partition.cpp
  src/reader.cpp
  src/utils.cpp
)

if(MSVC)
  add_compile_options(/W4)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

target_include_directories(
  graph-colouring
  PRIVATE
  ${Boost_INCLUDE_DIRS}
)

if(BENCHMARK_MEMORY)
  target_compile_definitions(graph-colouring PRIVATE BENCHMARK_MEMORY)
endif()
