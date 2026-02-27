#include "graph.hpp"
#include "colouring.hpp"
#include "reader.hpp"
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <limits>
#include <vector>

Node::Node() {}

Node::Node(size_t degree) { neighbours.reserve(degree); }

void Node::add_node(uint32_t to) { neighbours.push_back(to); }

size_t Node::degree() const { return neighbours.size(); }

std::vector<size_t> Graph::parse_degrees(Reader &reader) {
  reader.skip_header();

  std::vector<size_t> degrees{};

  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    uint32_t max_size = std::max(to, from) + 1;

    while (max_size > degrees.size()) {
      degrees.push_back(0);
    }

    degrees[from]++;
    degrees[to]++;
  }

  return degrees;
}

void Graph::add_edge(uint32_t from, uint32_t to) {
  uint32_t max_size = std::max(to, from) + 1;

  while (max_size > nodes.size()) {
    nodes.push_back(Node{});
  }

  nodes[from].add_node(to);
  nodes[to].add_node(from);
}

Graph Graph::parse(Reader &reader) {
  reader.skip_header();

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

    graph._max_degree = std::max({
        graph._max_degree,
        graph.nodes[from].degree(),
        graph.nodes[to].degree(),
    });
  }

  return graph;
}

Graph Graph::two_part_parse(Reader &reader) {
  std::vector<size_t> degrees = parse_degrees(reader);

  reader.reset();
  reader.skip_header();

  Graph graph{};

  graph.nodes.reserve(degrees.size());

  std::transform(degrees.begin(), degrees.end(),
                 std::back_inserter(graph.nodes),
                 [](size_t degree) { return Node{degree}; });

  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    graph.nodes[from].add_node(to);
    graph.nodes[to].add_node(from);

    graph._max_degree = std::max({
        graph._max_degree,
        graph.nodes[from].degree(),
        graph.nodes[to].degree(),
    });
  }

  return graph;
}

size_t Graph::num_vertices() const { return nodes.size(); }

size_t Graph::max_degree() const { return _max_degree; }

Colouring Graph::find_colouring_greedy() const {
  const uint32_t UNCOLOURED = std::numeric_limits<uint32_t>::max();

  std::vector<uint32_t> colouring(nodes.size(), UNCOLOURED);

  std::vector<uint8_t> neighbour_colours(1);

  size_t num_colors = 1;
  for (size_t i = 0; i < nodes.size(); i++) {
    const Node &node = nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colouring[neighbour];

      if (colour != UNCOLOURED) {
        neighbour_colours[colour] = 1;
      }
    }

    uint32_t colour = 0;
    while (colour < neighbour_colours.size() && neighbour_colours[colour]) {
      colour++;
    }

    num_colors = std::max(num_colors, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colors + 1);

    colouring[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      if (colouring[neighbour] != UNCOLOURED) {
        neighbour_colours[colouring[neighbour]] = 0;
      }
    }
  }

  return {colouring, num_colors};
}

bool Graph::validate_colouring(const Colouring &colouring) {
  for (size_t i = 0; i < nodes.size(); i++) {
    Node node = nodes[i];
    uint32_t colour = colouring.colours[i];

    if (colour >= colouring.num_colors) {
      std::cerr << "Node " << i << " has colour " << colour
                << " but `num_colors` is " << colouring.num_colors << std::endl;
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
