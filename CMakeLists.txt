cmake_minimum_required(VERSION 3.10)
project(GraphColouring)

if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()

find_package(Boost REQUIRED COMPONENTS graph)

add_executable(graph-colouring src/main.cpp)
target_link_libraries(
  graph-colouring
  PRIVATE
  Boost::graph
)
