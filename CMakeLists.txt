cmake_minimum_required(VERSION 3.10)
project(GraphColouring)

if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()

find_package(Boost REQUIRED)

option(BENCHMARK_MEMORY "" OFF)

add_executable(graph-colouring src/main.cpp)
target_include_directories(
  graph-colouring
  PRIVATE
  ${Boost_INCLUDE_DIRS}
)

if(BENCHMARK_MEMORY)
  target_compile_definitions(graph-colouring PRIVATE BENCHMARK_MEMORY)
endif()
