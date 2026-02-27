#pragma once

#include "colouring.hpp"
#include "reader.hpp"
#include <cstddef>
#include <cstdint>
#include <vector>

class Node {
public:
  Node();

  Node(size_t degree);

  std::vector<uint32_t> neighbours;
  void add_node(uint32_t to);

  size_t degree() const;
};

class Graph {
  std::vector<Node> nodes;
  size_t _max_degree;

  static std::vector<size_t> parse_degrees(Reader &reader);

public:
  void add_edge(uint32_t from, uint32_t to);

  static Graph parse(Reader &reader);

  static Graph two_part_parse(Reader &reader);

  size_t num_vertices() const;

  size_t max_degree() const;

  Colouring find_colouring_greedy() const;

  bool validate_colouring(const Colouring &colouring);
};
