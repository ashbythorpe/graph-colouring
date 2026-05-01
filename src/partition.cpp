#include "partition.hpp"
#include "colouring.hpp"
#include "reader.hpp"
#include "graph.hpp"
#include <boost/concept/detail/has_constraints.hpp>
#include <cstdint>
#include <vector>

ColouringResult find_colouring_partition_single_pass(Reader &reader, size_t m, size_t nodes) {
  std::vector<Graph> conflict_graphs(m);

  for (auto& graph: conflict_graphs) {
    graph.nodes.reserve(nodes / m + 1);
  }

  uint32_t from, to;
  uint32_t cg_edges = 0;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    if (from % m == to % m) {
      conflict_graphs[from % m].add_edge(from / m, to / m);
      cg_edges++;
    }
  }

  std::vector<uint32_t> colours(nodes);
  size_t num_colours = 0;
  for (size_t graph_index = 0; graph_index < m; graph_index++) {
    Graph &conflict_graph = conflict_graphs[graph_index];

    Colouring colouring = conflict_graph.find_colouring_greedy();

    for (size_t node_index = 0; node_index < colouring.colours.size();
         node_index++) {
      colours[node_index * m + graph_index] =
          num_colours + colouring.colours[node_index];
    }

    // `conflict_graph` may not actually contain all the nodes (e.g. if a node
    // has no neighbours). In this case `find_colouring_greedy()` would have
    // assigned the node (if it has existed) the colour `0`, so update `colours`
    // accordingly.
    for (size_t node_index = colouring.colours.size();
         node_index * m + graph_index < nodes; node_index++) {
      colours[node_index * m + graph_index] = num_colours;
    }

    num_colours += colouring.num_colours;
  }

  // C++ is a silly language
  return {cg_edges, 0, {std::move(colours), num_colours}};
}

ColouringResult find_colouring_partition_two_pass(Reader &reader, size_t m, size_t nodes) {
  auto [cg_edges, _, colouring] = find_colouring_partition_single_pass(reader, m, nodes);

  Graph colour_graph{};
  colour_graph.nodes.reserve(colouring.num_colours);

  reader.reset();

  uint32_t from, to;
  size_t sp_edges = 0;

  while (reader.read_number(from) && reader.read_number(to)) {
    if (from != to) {
      if (colour_graph.maybe_add_edge(colouring.colours[from], colouring.colours[to])) {
        sp_edges++;
      };
    }
  }

  Colouring psi = colour_graph.find_colouring_greedy();

  for (size_t i = 0; i < colouring.colours.size(); i++) {
    size_t colour = colouring.colours[i];

    if (colour < psi.colours.size()) {
      colouring.colours[i] = psi.colours[colour];
    } else {
      colouring.colours[i] = 0;
    }
  }

  colouring.num_colours = psi.num_colours;

  return {cg_edges, sp_edges, std::move(colouring)};
}

ColouringResult find_colouring_partition(Reader &reader, size_t m, bool two_pass, size_t nodes) {
  if (two_pass) {
    return find_colouring_partition_two_pass(reader, m, nodes);
  } else {
    return find_colouring_partition_single_pass(reader, m, nodes);
  }
}
