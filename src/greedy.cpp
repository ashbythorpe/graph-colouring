#include "colouring.hpp"
#include "graph.hpp"
#include "reader.hpp"
#include "utils.hpp"
#include <algorithm>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <vector>

Graph parse_graph(Reader &reader) {
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

    if (from > to) {
      graph.nodes[from].add_node(to);
    } else {
      graph.nodes[to].add_node(from);
    }
  }

  return graph;
}

Colouring find_colouring_greedy_single_pass(Reader &reader) {
  Graph graph = parse_graph(reader);

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

  return {colours, num_colours};
}

Colouring find_colouring_greedy_single_pass_bitset(Reader &reader) {
  Graph graph = parse_graph(reader);

  std::vector<uint32_t> colours(graph.nodes.size(), 0);

  std::vector<uint64_t> neighbour_colours(1, 0UL);

  size_t num_colours = 1;
  for (size_t i = 0; i < graph.nodes.size(); i++) {
    const Node &node = graph.nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colours[neighbour];

      neighbour_colours[colour / 64] |= 1 << colour % 64;
    }

    uint32_t colour = 0;
    for (uint64_t colours : neighbour_colours) {
      if (~colours != 0UL) {
        colour = __builtin_ctzl(~colours);
        break;
      }
    }

    num_colours = std::max(num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colours + 1, 0UL);

    colours[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colours[neighbour] / 64] = 0;
    }
  }

  return {colours, num_colours};
}

Colouring find_colouring_greedy_two_pass(Reader &reader) {
  std::vector<size_t> indices;
  size_t total = 0;
  {
    std::vector<size_t> degrees;

    uint32_t from, to;
    while (reader.read_number(from) && reader.read_number(to)) {
      if (from == to) {
        continue;
      }

      if (from >= degrees.size() || to >= degrees.size()) {
        degrees.resize(std::max(from + 1, to + 1), 0);
      }

      if (from > to) {
        degrees[from]++;
      } else {
        degrees[to]++;
      }
    }

    indices.reserve(degrees.size());

    for (size_t i = 0; i < degrees.size(); i++) {
      indices.push_back(total);
      total += degrees[i];
    }
  }

  std::vector<uint32_t> graph(total);

  {
    std::vector<size_t> offsets(indices.size(), 0);
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

  std::vector<uint32_t> colours(indices.size());

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

  return {colours, num_colours};
}

void benchmark_neighbour_methods(std::string& file) {
  {
    auto result = benchmark([&] {
      MMapReader reader{file};

      find_colouring_greedy_single_pass(reader);
    });

    std::cout << "Array\n";
    report_benchmark(result);
  }

  {
    auto result = benchmark([&] {
      MMapReader reader{file};

      find_colouring_greedy_single_pass_bitset(reader);
    });

    std::cout << "\nBuffered reader\n";
    report_benchmark(result);
  }
}


Colouring find_colouring_greedy(Reader &reader, bool two_pass) {
  if (two_pass) {
    return find_colouring_greedy_two_pass(reader);
  } else {
    return find_colouring_greedy_single_pass(reader);
  }
}
