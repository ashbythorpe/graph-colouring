#include <algorithm>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/detail/adjacency_list.hpp>
#include <boost/graph/graph_concepts.hpp>
#include <boost/graph/graph_selectors.hpp>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include <boost/property_map/property_map.hpp>
#include <fstream>
#include <iostream>
#include <istream>
#include <optional>
#include <ostream>
#include <string>
#include <string_view>
#include <vector>

template <typename T> class Node {
private:
  std::vector<size_t> neighbours;

public:
  T data;

  Node(T data) : data(data) {};

  void add_node(int to) { neighbours.push_back(to); }
};

typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::undirectedS>
    BoostGraph;

template <typename T> class Graph {
private:
  std::vector<Node<T>> nodes;

public:
  static Graph parse(std::istream &is, const T &value) {
    Graph graph{};

    size_t from, to;
    while (is >> from >> to) {
      size_t max_size = std::max(from, to);

      if (max_size >= graph.nodes.size()) {
        graph.nodes.resize(max_size + 1, Node<T>{value});
      }

      graph.nodes[from].add_node(to);
      graph.nodes[to].add_node(from);
    }

    return graph;
  }

  size_t vertices() {
    return nodes.size();
  }
};

BoostGraph parse_boost_graph(std::istream &is) {
  BoostGraph graph{};

  size_t from, to;
  while (is >> from >> to) {
    size_t max_size = std::max(from, to);

    while (boost::num_vertices(graph) <= max_size) {
      boost::add_vertex(graph);
    }

    boost::add_edge(from, to, graph);
  }

  return graph;
}

std::optional<std::ifstream> open_graph_file(std::string filename, bool print_comments) {
  std::ifstream is {filename};

  if (!is.is_open()) {
    return std::nullopt;
  }

  std::string line;
  while(is.peek() == '#') {
    std::getline(is, line);
    if (print_comments) {
      std::cout << line << std::endl;
    }
  }

  return is;
}

int main(int argc, char *argv[]) {
  std::vector<std::string_view> args { argv, argv + argc };

  if (std::find(args.begin(), args.end(), "-v") != args.end() ||
      std::find(args.begin(), args.end(), "--version") != args.end()) {
    std::cout << "0.0.1" << std::endl;
    return 0;
  }

  if (argc == 1 || std::find(args.begin(), args.end(), "-h") != args.end() ||
      std::find(args.begin(), args.end(), "--help") != args.end()) {
    std::cout << "Usage: graph-colouring [OPTIONS] INPUT" << std::endl;
    return 0;
  }

  std::string filename{argv[1]};

  // {
  //   std::optional<std::ifstream> is = open_graph_file(filename, true);
  //
  //   if (!is.has_value()) {
  //     std::cout << "Failed to open " << filename << std::endl;
  //     return 1;
  //   }
  //
  //   auto graph = Graph<std::optional<int>>::parse(*is, std::nullopt);
  //
  //   std::cout << graph.vertices() << std::endl;
  // }

  std::optional<std::ifstream> is = open_graph_file(filename, false);

  if (!is.has_value()) {
    std::cout << "Failed to open " << filename << std::endl;
    return 1;
  }
  BoostGraph boost_graph = parse_boost_graph(*is);

  std::cout << "Number of vertices: " << boost::num_vertices(boost_graph) << std::endl;

  std::vector<unsigned long> colors(boost::num_vertices(boost_graph));
  auto index_map = boost::get(boost::vertex_index, boost_graph);
  auto color_map = boost::make_safe_iterator_property_map(colors.begin(), colors.size(), index_map);

  auto num_colors = boost::sequential_vertex_coloring(boost_graph, color_map);

  std::cout << num_colors << " colours :)" << std::endl;
}
