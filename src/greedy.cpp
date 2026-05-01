#include "colouring.hpp"
#include "graph.hpp"
#include "reader.hpp"
#include "utils.hpp"
#include <algorithm>
#include <boost/concept/detail/has_constraints.hpp>
#include <boost/unordered/detail/fca.hpp>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <vector>

Graph parse_graph(Reader &reader, size_t nodes) {
  Graph graph{};

  graph.nodes.reserve(nodes);

  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    uint32_t max_size = std::max(to, from) + 1;

    while (max_size > graph.nodes.size()) {
      graph.nodes.push_back(Node{});
    }

    if (from > to) {
      graph.nodes[from].add_node(to);
    } else {
      graph.nodes[to].add_node(from);
    }
  }

  return graph;
}

Colouring find_colouring_from_graph(Graph& graph, size_t nodes) {
  std::vector<uint32_t> colours(graph.nodes.size(), 0);

  std::vector<uint8_t> neighbour_colours(1);

  size_t num_colours = 1;
  for (size_t i = 0; i < graph.nodes.size(); i++) {
    const Node &node = graph.nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colours[neighbour];

      neighbour_colours[colour] = 1;
    }

    uint32_t colour = 0;
    while (colour < neighbour_colours.size() && neighbour_colours[colour]) {
      colour++;
    }

    num_colours = std::max(num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colours + 1);

    colours[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colours[neighbour]] = 0;
    }
  }

  return {std::move(colours), num_colours};
}

Colouring find_colouring_greedy_single_pass(Reader &reader, size_t nodes) {
  Graph graph = parse_graph(reader, nodes);

  return find_colouring_from_graph(graph, nodes);
}

Colouring find_colouring_from_graph_bitset(Graph& graph, size_t nodes) {
  std::vector<uint32_t> colours(graph.nodes.size(), 0);

  std::vector<uint64_t> neighbour_colours(1, 0UL);

  size_t num_colours = 1;
  for (size_t i = 0; i < graph.nodes.size(); i++) {
    const Node &node = graph.nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colours[neighbour];

      neighbour_colours[colour / 64] |= 1ULL << colour % 64;
    }

    uint32_t colour = 0;
    for (size_t j = 0; j < colours.size(); j++) {
      uint64_t colours_slice = neighbour_colours[j];

      if (~colours_slice != 0ULL) {
        colour = j * 64 + __builtin_ctzll(~colours_slice);
        break;
      }
    }

    num_colours = std::max(num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colours / 64 + 1, 0ULL);

    colours[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colours[neighbour] / 64] = 0ULL;
    }
  }

  return {std::move(colours), num_colours};
}

Colouring find_colouring_greedy_two_pass(Reader &reader, size_t nodes) {
  std::vector<size_t> indices;
  indices.reserve(nodes);
  size_t total = 0;
  {
    std::vector<size_t> degrees(nodes, 0);

    uint32_t from, to;
    while (reader.read_number(from) && reader.read_number(to)) {
      if (from == to) {
        continue;
      }

      if (from > to) {
        degrees[from]++;
      } else {
        degrees[to]++;
      }
    }

    for (size_t i = 0; i < nodes; i++) {
      indices.push_back(total);
      total += degrees[i];
    }
  }

  std::vector<uint32_t> graph(total);

  {
    std::vector<size_t> offsets(nodes, 0);
    reader.reset();

    uint32_t from, to;
    while (reader.read_number(from) && reader.read_number(to)) {
      if (from == to) {
        continue;
      }

      if (from > to) {
        graph[indices[from] + offsets[from]] = to;
        offsets[from]++;
      } else {
        graph[indices[to] + offsets[to]] = from;
        offsets[to]++;
      }
    }
  }

  std::vector<uint32_t> colours(nodes);

  std::vector<uint8_t> neighbour_colours(1);

  size_t num_colours = 1;
  for (size_t i = 0; i < indices.size(); i++) {
    size_t start = indices[i];
    size_t end = i == indices.size() - 1 ? graph.size() : indices[i + 1];

    for (size_t j = start; j < end; j++) {
      size_t colour = colours[graph[j]];

      neighbour_colours[colour] = 1;
    }

    uint32_t colour = 0;
    while (colour < neighbour_colours.size() && neighbour_colours[colour]) {
      colour++;
    }

    num_colours = std::max(num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colours + 1);

    colours[i] = colour;

    for (size_t i = start; i < end; i++) {
      neighbour_colours[colours[graph[i]]] = 0;
    }
  }

  return {std::move(colours), num_colours};
}

void benchmark_neighbour_methods(const std::string &file, size_t nodes) {
  MMapReader reader{file};
  Graph graph = parse_graph(reader, nodes);

  {
    auto result = benchmark([&] {
      find_colouring_from_graph(graph, nodes);
    });

    std::cout << "Array\n";
    report_benchmark(result);
  }

  {
    auto result = benchmark([&] {
      find_colouring_from_graph_bitset(graph, nodes);
    });

    std::cout << "\nBitset\n";
    report_benchmark(result);
  }
}

Colouring find_colouring_greedy(Reader &reader, bool two_pass, size_t nodes) {
  if (two_pass) {
    return find_colouring_greedy_two_pass(reader, nodes);
  } else {
    return find_colouring_greedy_single_pass(reader, nodes);
  }
}
