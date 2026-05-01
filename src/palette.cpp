#include "palette.hpp"
#include "colouring.hpp"
#include "graph.hpp"
#include "reader.hpp"
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <iostream>
#include <random>
#include <unordered_set>
#include <utility>
#include <vector>

class Palette {
  std::vector<uint32_t> palette;

public:
  // Palette(std::mt19937 &gen, size_t list_size, size_t max_colours) {
  //   if (list_size > max_colours) {
  //     std::cerr << "list_size > max_colours" << std::endl;
  //   }
  //
  //   palette.reserve(list_size);
  //
  //   if (list_size == max_colours) {
  //     for (size_t i = 0; i < list_size; i++) {
  //       palette.push_back(i);
  //     }
  //
  //     return;
  //   }
  //
  //   std::uniform_int_distribution<uint32_t> dist(0, max_colours - 1);
  //
  //   while (palette.size() < list_size) {
  //     uint32_t colour = dist(gen);
  //     auto it = std::lower_bound(palette.begin(), palette.end(), colour);
  //
  //     if (it == palette.end() || *it != colour) {
  //       palette.insert(it, colour);
  //     }
  //   }
  // }

  Palette(std::mt19937 &gen, size_t list_size, size_t max_colours) {
    if (list_size > max_colours) {
      std::cerr << "list_size > max_colours" << std::endl;
    }

    palette.reserve(list_size);

    for (int i = max_colours - list_size + 1; i <= max_colours; ++i) {
      std::uniform_int_distribution<int> dist(1, i);
      int r = dist(gen);

      bool found = false;
      for (int val : palette) {
        if (val == r) {
          found = true;
          break;
        }
      }

      if (found) {
        palette.push_back(i);
      } else {
        palette.push_back(r);
      }
    }

    std::sort(palette.begin(), palette.end());
  }

  bool overlaps(const Palette &other, size_t max_colours) const {
    if (palette.size() == 0 || other.palette.size() == 0) {
      return false;
    }

    if (palette.size() == max_colours || other.palette.size() == max_colours) {
      return true;
    }

    size_t i = 0, j = 0;
    while (i < palette.size() && j < other.palette.size()) {
      if (palette[i] < other.palette[j]) {
        i++;
      } else if (palette[i] > other.palette[j]) {
        j++;
      } else {
        return true;
      }
    }

    return false;
  }

  template <typename F> void for_each(F callback, size_t max_colours) const {
    for (uint32_t colour : palette) {
      if (callback(colour)) {
        break;
      }
    }
  }
};

class CompressedPalette {
  size_t size;
  uint32_t seed;

public:
  CompressedPalette(std::mt19937 &gen, size_t list_size, size_t max_colours)
      : size(list_size), seed(gen()) {}

  bool overlaps(const CompressedPalette &other, size_t max_colours) const {
    if (size == 0 || other.size == 0) {
      return false;
    }

    if (size == max_colours || other.size == max_colours) {
      return true;
    }

    const CompressedPalette *smaller =
        (this->size < other.size) ? this : &other;
    const CompressedPalette *larger = (this->size < other.size) ? &other : this;

    std::unordered_set<uint32_t> smaller_set;
    smaller_set.reserve(smaller->size);

    std::minstd_rand gen_small(smaller->seed);
    std::uniform_int_distribution<int> dist(1, max_colours);

    while (smaller_set.size() < smaller->size) {
      smaller_set.insert(dist(gen_small));
    }

    std::minstd_rand gen_large(larger->seed);

    std::unordered_set<int> larger_set;
    larger_set.reserve(larger->size);

    int generated_unique_colours = 0;

    while (larger_set.size() < larger->size) {
      uint32_t colour = dist(gen_large);

      auto [_, inserted] = larger_set.insert(colour);

      if (inserted) {
        if (smaller_set.find(colour) != smaller_set.end()) {
          return true;
        }
      }
    }

    return false;
  }

  template <typename Func>
  void for_each(Func callback, size_t max_colours) const {
    std::minstd_rand gen{seed};

    std::uniform_int_distribution<int> dist(1, max_colours);

    std::unordered_set<uint32_t> colours(size);

    while (colours.size() < size) {
      uint32_t colour = dist(gen);

      auto [_, inserted] = colours.insert(colour);

      if (inserted) {
        if (callback(colour)) {
          break;
        }
      }
    }
  }
};

// class Node {
// public:
//   Node(std::vector<uint32_t> palette) : palette(std::move(palette)) {}
//
//   std::vector<uint32_t> neighbours;
//   std::vector<uint32_t> palette;
//
//   void add_node(uint32_t to);
//
//   size_t degree() const;
// };
//
// class Graph {
// public:
//   std::vector<Node> nodes;
//
//   void add_edge(uint32_t from, uint32_t to) {
//     nodes[from].add_node(to);
//     nodes[to].add_node(from);
//   }
//
//   void add_node(Node node) { nodes.push_back(node); }
// };

std::vector<uint32_t> sample_palette(std::mt19937 &gen, size_t list_size,
                                     size_t max_colours) {
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

template <typename Palette>
std::vector<Palette>
sample_palettes(size_t nodes, std::mt19937 &gen, size_t max_colours,
                std::function<size_t(uint32_t)> list_size_fun) {
  std::vector<Palette> palettes{};
  palettes.reserve(nodes);

  for (uint32_t i = 0; i < nodes; i++) {
    size_t list_size =
        std::max(std::min(list_size_fun(i), max_colours), size_t(1));

    palettes.push_back(Palette{gen, list_size, max_colours});
  }

  return palettes;
}

// Graph init_graph(size_t nodes, std::mt19937 &gen, size_t max_colours,
//                  size_t palette_size) {
//   Graph graph{};
//   graph.nodes.reserve(nodes);
//
//   for (uint32_t i = 0; i < nodes; i++) {
//     // size_t list_size =
//     //     std::max(std::min(max_colours,
//     //                       (size_t)((1 * nlogn) / (float)(pi[i] + 1))),
//     //              (size_t)1);
//     std::vector<uint32_t> palette =
//         sample_palette(gen, palette_size, max_colours);
//
//     graph.add_node(Node{palette});
//   }
//
//   return graph;
// }

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

template <typename Palette, typename G>
std::pair<size_t, Colouring>
find_colouring_first_pass(Reader &reader, size_t nodes, size_t max_colours,
                          std::function<size_t(uint32_t)> list_size_fun,
                          G on_uncoloured) {
  std::random_device random_device;
  std::mt19937 gen(random_device());

  std::vector<Palette> palettes =
      sample_palettes<Palette>(nodes, gen, max_colours, list_size_fun);
  Graph graph{};

  graph.nodes.resize(nodes);

  uint32_t from, to;
  uint32_t cg_edges = 0;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    Node &from_node = graph.nodes[from];
    Node &to_node = graph.nodes[to];

    if (palettes[from].overlaps(palettes[to], max_colours)) {
      if (from > to) {
        from_node.add_node(to);
      } else {
        to_node.add_node(from);
      }
      cg_edges++;
    }
  }

  std::vector<uint32_t> colours(nodes);

  std::vector<uint8_t> neighbour_colours(1);

  size_t num_colours = 0;

  for (size_t i = 0; i < graph.nodes.size(); i++) {
    const Node &node = graph.nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colours[neighbour];

      neighbour_colours[colour] = 1;
    }

    uint32_t colour;
    bool found = false;

    palettes[i].for_each(
        [&](uint32_t c) {
          colour = c;

          if (colour >= neighbour_colours.size() ||
              !neighbour_colours[colour]) {
            found = true;
            return true;
          }

          return false;
        },
        max_colours);

    if (!found) {
      colour = on_uncoloured(i);
    }
    num_colours = std::max(num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(num_colours + 1);

    colours[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colours[neighbour]] = 0;
    }
  }

  return {cg_edges, {std::move(colours), num_colours}};
}

template <typename Palette>
ColouringResult
find_colouring_single_pass(Reader &reader, size_t nodes, size_t max_colours,
                           std::function<size_t(uint32_t)> list_size_fun) {
  uint32_t spare_colour = max_colours;

  auto [cg_edges, colouring] = find_colouring_first_pass<Palette>(
      reader, nodes, max_colours, list_size_fun,
      [&](size_t _) { return spare_colour++; });

  return {cg_edges, 0, std::move(colouring)};
}

template <typename Palette>
ColouringResult
find_colouring_two_pass(Reader &reader, size_t nodes, size_t max_colours,
                        std::function<size_t(uint32_t)> list_size_fun) {
  std::unordered_set<size_t> uncoloured_nodes{};

  auto [cg_edges, colouring] = find_colouring_first_pass<Palette>(
      reader, nodes, max_colours, list_size_fun, [&](size_t i) {
        uncoloured_nodes.insert(i);
        return 0;
      });

  reader.reset();

  Graph graph{};

  graph.nodes.resize(nodes);

  uint32_t from, to;
  uint32_t sp_edges = 0;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    Node &from_node = graph.nodes[from];
    Node &to_node = graph.nodes[to];

    bool from_uncoloured =
        uncoloured_nodes.find(from) != uncoloured_nodes.end();
    bool to_uncoloured = uncoloured_nodes.find(to) != uncoloured_nodes.end();

    if (from_uncoloured && to_uncoloured) {
      if (from > to) {
        from_node.add_node(to);
      } else {
        to_node.add_node(from);
      }
      sp_edges++;
    } else if (from_uncoloured) {
      from_node.add_node(to);
      sp_edges++;
    } else if (to_uncoloured) {
      to_node.add_node(from);
      sp_edges++;
    }
  }

  std::vector<size_t> sorted_uncoloured{uncoloured_nodes.begin(),
                                        uncoloured_nodes.end()};
  std::sort(sorted_uncoloured.begin(), sorted_uncoloured.end());

  std::vector<uint8_t> neighbour_colours(colouring.num_colours);

  for (size_t i : sorted_uncoloured) {
    const Node &node = graph.nodes[i];

    for (size_t neighbour : node.neighbours) {
      size_t colour = colouring.colours[neighbour];

      neighbour_colours[colour] = 1;
    }

    uint32_t colour = 0;

    while (colour < neighbour_colours.size() && neighbour_colours[colour]) {
      colour++;
    }

    colouring.num_colours =
        std::max(colouring.num_colours, static_cast<size_t>(colour + 1));

    neighbour_colours.resize(colouring.num_colours + 1);

    colouring.colours[i] = colour;

    for (uint32_t neighbour : node.neighbours) {
      neighbour_colours[colouring.colours[neighbour]] = 0;
    }
  }

  return {cg_edges, sp_edges, std::move(colouring)};
}

ColouringResult
find_colouring_palette(Reader &reader, size_t nodes, size_t max_colours,
                       bool compress_palettes, bool two_pass,
                       std::function<size_t(uint32_t)> list_size_fun) {
  if (two_pass) {
    if (compress_palettes) {
      return find_colouring_two_pass<CompressedPalette>(
          reader, nodes, max_colours, list_size_fun);
    } else {
      return find_colouring_two_pass<Palette>(reader, nodes, max_colours,
                                              list_size_fun);
    }
  } else {
    if (compress_palettes) {
      return find_colouring_single_pass<CompressedPalette>(
          reader, nodes, max_colours, list_size_fun);
    } else {
      return find_colouring_single_pass<Palette>(reader, nodes, max_colours,
                                                 list_size_fun);
    }
  }
}
