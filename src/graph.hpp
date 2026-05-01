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
  size_t _max_degree;

public:
  std::vector<Node> nodes;

  void add_edge(uint32_t from, uint32_t to);

  bool maybe_add_edge(uint32_t from, uint32_t to);

  static Graph parse_full(Reader &reader);

  size_t num_vertices() const;

  size_t max_degree() const;

  Colouring find_colouring_greedy() const;

  bool validate_colouring(const Colouring &colouring);
};
