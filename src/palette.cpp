#include "palette.hpp"
#include "colouring.hpp"
#include "reader.hpp"
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <iterator>
#include <random>
#include <vector>

class Node {
public:
  Node(std::vector<uint32_t> palette) : palette(std::move(palette)) {}

  std::vector<uint32_t> neighbours;
  std::vector<uint32_t> palette;

  void add_node(uint32_t to);

  size_t degree() const;
};

class Graph {
public:
  std::vector<Node> nodes;

  void add_edge(uint32_t from, uint32_t to) {
    nodes[from].add_node(to);
    nodes[to].add_node(from);
  }

  void add_node(Node node) { nodes.push_back(node); }
};

std::pair<std::vector<uint32_t>, std::vector<uint32_t>>
compute_pi(GraphInfo &info, std::mt19937 &gen) {
  std::vector<uint32_t> pi(info.nodes);
  std::vector<uint32_t> pi_inv(info.nodes);

  for (uint32_t i = 0; i < info.nodes; i++) {
    pi[i] = i;
  }

  std::shuffle(pi.begin(), pi.end(), gen);

  for (uint32_t i = 0; i < info.nodes; i++) {
    pi_inv[pi[i]] = i;
  }

  return {pi, pi_inv};
}

std::vector<uint32_t> sample_palette(GraphInfo &info, std::mt19937 &gen,
                                     size_t list_size, size_t max_colours) {
  if (list_size > max_colours) {
    std::cerr << "list_size > max_colours" << std::endl;
  } else {
  }

  std::vector<uint32_t> palette;
  palette.reserve(list_size);
  std::uniform_int_distribution<uint32_t> dist(0, max_colours - 1);

  while (palette.size() < list_size) {
    uint32_t colour = dist(gen);
    auto it = std::lower_bound(palette.begin(), palette.end(), colour);

    if (it == palette.end() || *it != colour) {
      palette.insert(it, colour);
    } else {
    }
  }

  return palette;
}

Graph init_graph(GraphInfo &info, std::vector<uint32_t> &pi,
                 std::mt19937 &gen, size_t max_colours, size_t palette_size) {
  float nlogn = ((float)info.nodes) * std::log((float)info.nodes);

  Graph graph{};
  graph.nodes.reserve(info.nodes);

  for (uint32_t i = 0; i < info.nodes; i++) {
    // size_t list_size =
    //     std::max(std::min(max_colours,
    //                       (size_t)((1 * nlogn) / (float)(pi[i] + 1))),
    //              (size_t)1);
    std::vector<uint32_t> palette = sample_palette(info, gen, palette_size, max_colours);

    graph.add_node(Node{palette});
  }

  return graph;
}

bool palettes_overlap(std::vector<uint32_t> &x, std::vector<uint32_t> &y) {
  size_t i = 0, j = 0;
  while (i < x.size() && j < y.size()) {
    if (x[i] < y[j]) {
      i++;
    } else if (x[i] > y[j]) {
      j++;
    } else {
      return true;
    }
  }

  return false;
}

std::pair<size_t, Colouring> find_colouring_palette(Reader &reader, GraphInfo &info, size_t max_colours, size_t palette_size) {
  reader.skip_header();

  std::random_device random_device;
  std::mt19937 gen(random_device());

  auto [pi, pi_inv] = compute_pi(info, gen);

  Graph graph = init_graph(info, pi, gen, max_colours, palette_size);

  uint32_t from, to;
  uint32_t skipped = 0;
  uint32_t kept = 0;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    Node &from_node = graph.nodes[from];
    Node &to_node = graph.nodes[to];

    if (palettes_overlap(from_node.palette, to_node.palette)) {
      if (pi[from] < pi[to]) {
        from_node.add_node(to);
      } else {
        to_node.add_node(from);
      }
      kept++;
    } else {
      skipped++;
    }
  }

  std::vector<uint32_t> colours(info.nodes);

  std::vector<uint8_t> neighbour_colours(1);

  uint32_t spare_colour = max_colours;

  size_t num_colors = 0;

  for (auto it = pi_inv.rbegin(); it != pi_inv.rend(); ++it) {
    const Node &node = graph.nodes[*it];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colours[neighbour];

      neighbour_colours[colour] = 1;
    }

    uint32_t colour;
    bool found = false;
    for (uint32_t c : node.palette) {
      colour = c;

      if (colour >= neighbour_colours.size() || !neighbour_colours[colour]) {
        found = true;
        break;
      }
    }

    if (!found) {
      colour = spare_colour;
      spare_colour++;
    }
    num_colors = std::max(num_colors, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colors + 1);

    colours[*it] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colours[neighbour]] = 0;
    }
  }

  return {skipped, {colours, num_colors}};
}
