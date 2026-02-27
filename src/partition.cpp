#include "partition.hpp"
#include "colouring.hpp"
#include "reader.hpp"
#include "graph.hpp"
#include <algorithm>

Colouring find_colouring_stream(Reader &reader, size_t n) {
  reader.skip_header();

  Graph conflict_graphs[n];

  uint32_t nodes = 0;
  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    if (from % n == to % n) {
      conflict_graphs[from % n].add_edge(from / n, to / n);
    }

    nodes = std::max({from + 1, to + 1, nodes});
  }

  std::vector<uint32_t> colours(nodes);
  size_t num_colors = 0;
  for (size_t graph_index = 0; graph_index < n; graph_index++) {
    Graph &conflict_graph = conflict_graphs[graph_index];

    Colouring colouring = conflict_graph.find_colouring_greedy();

    for (size_t node_index = 0; node_index < colouring.colours.size();
         node_index++) {
      colours[node_index * n + graph_index] =
          num_colors + colouring.colours[node_index];
    }

    // `conflict_graph` may not actually contain all the nodes (e.g. if a node
    // has no neighbours). In this case `find_colouring_greedy()` would have
    // assigned the node (if it has existed) the colour `0`, so update `colours`
    // accordingly.
    for (size_t node_index = colouring.colours.size();
         node_index * n + graph_index < nodes; node_index++) {
      colours[node_index * n + graph_index] = num_colors;
    }

    num_colors += colouring.num_colors;
  }

  return Colouring{colours, num_colors};
}
