#include "boost.hpp"
#include "colouring.hpp"
#include "reader.hpp"
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/detail/adjacency_list.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include <boost/graph/smallest_last_ordering.hpp>
#include <boost/property_map/shared_array_property_map.hpp>
#include <vector>

using BoostGraph =
    boost::adjacency_list<boost::vecS, boost::vecS, boost::undirectedS>;
using vertices_size_type = boost::graph_traits<BoostGraph>::vertices_size_type;
using vertex_descriptor = boost::graph_traits<BoostGraph>::vertex_descriptor;

BoostGraph parse_boost_graph(Reader &reader) {
  BoostGraph graph{};

  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    uint32_t max_size = std::max(from, to);

    while (boost::num_vertices(graph) <= max_size) {
      boost::add_vertex(graph);
    }

    boost::add_edge(from, to, graph);
  }

  return graph;
}

Colouring find_colouring_boost(Reader &reader) {
  BoostGraph graph = parse_boost_graph(reader);

  const auto index_map = boost::get(boost::vertex_index, graph);

  auto order =
      boost::copy_range<std::vector<vertex_descriptor>>(boost::vertices(graph));
  auto order_map = boost::make_safe_iterator_property_map(
      order.begin(), order.size(), index_map);

  boost::smallest_last_vertex_ordering(graph, order_map);

  vertices_size_type num_vertices = boost::num_vertices(graph);
  std::vector<uint32_t> colours(num_vertices);
  auto colour_map = boost::make_safe_iterator_property_map(
      colours.begin(), colours.size(), index_map);

  const auto num_colours =
      boost::sequential_vertex_coloring(graph, order_map, colour_map);

  return Colouring{colours, num_colours};
}
