#include "graph.hpp"
#include "colouring.hpp"
#include "reader.hpp"
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <vector>

Node::Node() {}

Node::Node(size_t degree) { neighbours.reserve(degree); }

void Node::add_node(uint32_t to) { neighbours.push_back(to); }

size_t Node::degree() const { return neighbours.size(); }

void Graph::add_edge(uint32_t from, uint32_t to) {
  uint32_t max_size = std::max(to, from) + 1;

  while (max_size > nodes.size()) {
    nodes.push_back(Node{});
  }

  if (from > to) {
    nodes[from].add_node(to);
  } else {
    nodes[to].add_node(from);
  }
}

bool Graph::maybe_add_edge(uint32_t from, uint32_t to) {
  uint32_t max_size = std::max(to, from) + 1;

  while (max_size > nodes.size()) {
    nodes.push_back(Node{});
  }

  if (from > to) {
    if (std::find(nodes[from].neighbours.begin(), nodes[from].neighbours.end(),
                  to) == nodes[from].neighbours.end()) {
      nodes[from].add_node(to);
      return true;
    }
  } else {
    if (std::find(nodes[to].neighbours.begin(), nodes[to].neighbours.end(),
                  from) == nodes[to].neighbours.end()) {
      nodes[to].add_node(from);
      return true;
    }
  }

  return false;
}

Graph Graph::parse_full(Reader &reader) {
  Graph graph{};

  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    uint32_t max_size = std::max(to, from) + 1;

    while (max_size > graph.nodes.size()) {
      graph.nodes.push_back(Node{});
    }

    graph.nodes[from].add_node(to);
    graph.nodes[to].add_node(from);
  }

  return graph;
}

size_t Graph::num_vertices() const { return nodes.size(); }

size_t Graph::max_degree() const { return _max_degree; }

Colouring Graph::find_colouring_greedy() const {
  std::vector<uint32_t> colouring(nodes.size(), 0);

  std::vector<uint8_t> neighbour_colours(1);

  size_t num_colours = 1;
  for (size_t i = 0; i < nodes.size(); i++) {
    const Node &node = nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colouring[neighbour];

      neighbour_colours[colour] = 1;
    }

    uint32_t colour = 0;
    while (colour < neighbour_colours.size() && neighbour_colours[colour]) {
      colour++;
    }

    num_colours = std::max(num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colours + 1);

    colouring[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colouring[neighbour]] = 0;
    }
  }

  return {std::move(colouring), num_colours};
}

bool Graph::validate_colouring(const Colouring &colouring) {
  for (size_t i = 0; i < nodes.size(); i++) {
    Node node = nodes[i];
    uint32_t colour = colouring.colours[i];

    if (colour >= colouring.num_colours) {
      std::cerr << "Node " << i << " has colour " << colour
                << " but `num_colours` is " << colouring.num_colours << std::endl;
    }

    for (uint32_t neighbour : node.neighbours) {
      if (colouring.colours[neighbour] == colour) {
        std::cerr << "Node " << i << "and node " << neighbour
                  << " intersect (with colour " << colour << ")" << std::endl;
        return false;
      }
    }
  }

  return true;
}
