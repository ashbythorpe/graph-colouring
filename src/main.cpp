#include <algorithm>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/detail/adjacency_list.hpp>
#include <boost/graph/graph_concepts.hpp>
#include <boost/graph/graph_selectors.hpp>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include <boost/graph/smallest_last_ordering.hpp>
#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <boost/property_map/property_map.hpp>
#include <boost/property_map/shared_array_property_map.hpp>
#include <boost/range/iterator_range_core.hpp>
#include <cctype>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <istream>
#include <iterator>
#include <limits>
#include <optional>
#include <ostream>
#include <string>
#include <string_view>
#include <sys/mman.h>
#include <sys/stat.h>
#include <system_error>
#include <vector>

class Header {
public:
  size_t nodes;
  size_t edges;
};

Header read_header(std::istream &is) {
  std::string buf;
  size_t nodes, edges;
  while (is.peek() == '#') {
    is.get();

    while (is >> buf) {
      if (buf == "Nodes:") {
        is >> nodes;
      } else if (buf == "Edges:") {
        is >> edges;
        break;
      } else {
        break;
      }
    }

    std::getline(is, buf);
  }

  return Header{nodes, edges};
}

class Node {
public:
  Node() {}

  Node(size_t degree) { neighbours.reserve(degree); }

  std::vector<uint32_t> neighbours;
  void add_node(uint32_t to) { neighbours.push_back(to); }

  size_t degree() const { return neighbours.size(); }
};

using BoostGraph =
    boost::adjacency_list<boost::vecS, boost::vecS, boost::undirectedS>;
using vertices_size_type = boost::graph_traits<BoostGraph>::vertices_size_type;
using vertex_descriptor = boost::graph_traits<BoostGraph>::vertex_descriptor;

class Colouring {
public:
  std::vector<uint32_t> colours;
  size_t num_colors;
};

class Reader {
  std::ifstream file;
  char buffer[1024 * 1024];
  char *ptr = buffer;
  char *end = ptr;

public:
  Reader(std::string file) : file(std::ifstream{file}) {}

  Header read_header() {
    std::string buf;
    size_t nodes, edges;
    while (file.peek() == '#') {
      file.get();

      while (file >> buf) {
        if (buf == "Nodes:") {
          file >> nodes;
        } else if (buf == "Edges:") {
          file >> edges;
          break;
        } else {
          break;
        }
      }

      std::getline(file, buf);
    }

    return Header{nodes, edges};
  }

  bool read_number(uint32_t &num) {
    if (ptr >= end || (end - ptr) < 32) {
      size_t leftover = end - ptr;
      if (leftover > 0 && ptr != buffer) {
        std::memmove(buffer, ptr, leftover);
      }

      file.read(buffer + leftover, (1024 * 1024) - leftover);
      size_t bytes_read = file.gcount();

      ptr = buffer;
      end = buffer + leftover + bytes_read;

      if (bytes_read == 0 && leftover == 0) {
        return false;
      }
    }

    while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
      ptr++;
    }

    auto [new_ptr, err] = std::from_chars(ptr, end, num);

    if (err == std::errc()) {
      ptr = const_cast<char *>(new_ptr);
      return true;
    } else {
      return false;
    }
  }
};

class MMapReader {
private:
  int fd;
  char *address;
  size_t length;
  const char *ptr;
  const char *end;

public:
  MMapReader(std::string file) {
    fd = open(file.c_str(), O_RDONLY);
    if (fd == -1) {
      std::cerr << "Error opening file";
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
      std::cerr << "Error getting file stats";
      close(fd);
    }
    length = sb.st_size;

    address =
        static_cast<char *>(mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0));
    if (address == MAP_FAILED) {
      std::cerr << "Error mapping file";
      close(fd);
    }

    ptr = address;
    end = address + length;
  }

  ~MMapReader() {
    munmap(address, length);
    close(fd);
  }

  void skip_header() {
    while (ptr < end && *ptr == '#') {
      while (ptr < end && *ptr != '\n')
        ptr++;
      if (ptr < end)
        ptr++;
    }
  }

  void reset() {
    ptr = address;
    end = address + length;
  }

  bool read_number(uint32_t &num) {
    while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
      ptr++;
    }

    if (ptr >= end) {
      return false;
    }

    auto [next_ptr, ec1] = std::from_chars(ptr, end, num);
    if (ec1 != std::errc{}) {
      std::cerr << "Error parsing number" << std::endl;
      return false;
    }
    ptr = next_ptr;

    return true;
  }
};

class Graph {
  std::vector<Node> nodes;
  size_t _max_degree;

  static std::vector<size_t> parse_degrees(std::string filename) {
    Reader reader{filename};

    reader.read_header();

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

  static std::vector<size_t> parse_degrees_mmap(MMapReader &reader) {
    std::vector<size_t> degrees{};

    reader.skip_header();

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

public:
  void add_edge(uint32_t from, uint32_t to) {
    uint32_t max_size = std::max(to, from) + 1;

    while (max_size > nodes.size()) {
      nodes.push_back(Node{});
    }

    nodes[from].add_node(to);
    nodes[to].add_node(from);
  }

  static Graph parse_mmap(const std::string &path) {
    MMapReader reader{path};

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

  static Graph two_part_parse_mmap(const std::string &path) {
    MMapReader reader{path};

    std::vector<size_t> degrees = parse_degrees_mmap(reader);

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

  static Graph parse(std::string file) {
    Reader reader{file};

    reader.read_header();

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

  static Graph two_part_parse_buf(std::string filename) {
    std::vector<size_t> degrees = parse_degrees(filename);

    Reader reader{filename};

    reader.read_header();

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

  size_t num_vertices() const { return nodes.size(); }

  size_t max_degree() const { return _max_degree; }

  Colouring find_colouring_greedy() const {
    const uint32_t UNCOLOURED = std::numeric_limits<uint32_t>::max();

    std::vector<uint32_t> colouring(nodes.size(), UNCOLOURED);

    std::vector<char> neighbour_colours(1);

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

    Colouring result{colouring, num_colors};

    return result;
  }

  bool validate_colouring(const Colouring &colouring) {
    for (size_t i = 0; i < nodes.size(); i++) {
      Node node = nodes[i];
      uint32_t colour = colouring.colours[i];
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

std::optional<std::ifstream> open_graph_file(std::string filename,
                                             bool print_comments) {
  std::ifstream is{filename};

  if (!is.is_open()) {
    return std::nullopt;
  }

  std::string line;
  while (is.peek() == '#') {
    std::getline(is, line);
    if (print_comments) {
      std::cout << line << std::endl;
    }
  }

  return is;
}

Colouring find_colouring_stream(std::string filename) {
  Reader reader{filename};

  reader.read_header();

  Graph conflict_graphs[10];

  uint32_t nodes = 0;
  uint32_t from, to;
  while (reader.read_number(from) && reader.read_number(to)) {
    if (from == to) {
      continue;
    }

    if (from % 10 == to % 10) {
      conflict_graphs[from % 10].add_edge(from / 10, to / 10);
    }

    nodes = std::max({from + 1, to + 1, nodes});
  }

  std::cout << "Parsed graph" << std::endl;

  std::vector<uint32_t> colours(nodes);
  size_t num_colors = 0;
  for (size_t graph_index = 0; graph_index < 10; graph_index++) {
    Graph &conflict_graph = conflict_graphs[graph_index];

    Colouring colouring = conflict_graph.find_colouring_greedy();

    for (size_t node_index = 0; node_index < colouring.colours.size();
         node_index++) {
      colours[node_index * 10 + graph_index] =
          num_colors + colouring.colours[node_index];
    }

    num_colors += colouring.num_colors;
  }

  return Colouring{colours, num_colors};
}

int main(int argc, char *argv[]) {
  const std::vector<std::string_view> args{argv, argv + argc};

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

  const std::string filename{argv[1]};

  {
    std::ifstream is{filename};

    if (!is.is_open()) {
      std::cerr << "Failed to open " << filename << std::endl;
      return 1;
    }

    // {
    //   auto start = std::chrono::high_resolution_clock::now();
    //
    //   auto graph = Graph::parse(is);
    //
    //   auto end = std::chrono::high_resolution_clock::now();
    //   std::chrono::duration<double> elapsed{end - start};
    //
    //   std::cout << "Time taken: " << elapsed.count() << std::endl;
    // }

    {
      auto start = std::chrono::high_resolution_clock::now();

      Colouring colouring = find_colouring_stream(filename);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed{end - start};

      std::cout << "Found colouring with " << colouring.num_colors << " colours"
                << std::endl;
      std::cout << "Vertices: " << colouring.colours.size() << std::endl;
      std::cout << "Time taken: " << elapsed.count() << std::endl;

      // Graph graph = Graph::parse_buf(filename);
      //
      // if (!graph.validate_colouring(colouring)) {
      //   std::cerr << "Colouring is invalid" << std::endl;
      // }
    }

    // return 0;

    {
      auto start = std::chrono::high_resolution_clock::now();

      auto graph = Graph::parse(filename);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed{end - start};

      std::cout << "Vertices: " << graph.num_vertices() << std::endl;

      std::cout << "Time taken using buffer: " << elapsed.count() << std::endl;

      Colouring colouring = graph.find_colouring_greedy();

      std::cout << "Found colouring with " << colouring.num_colors << " colours"
                << std::endl;
    }

    {
      auto start = std::chrono::high_resolution_clock::now();

      auto graph = Graph::two_part_parse_buf(filename);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed{end - start};

      std::cout << "Vertices: " << graph.num_vertices() << std::endl;

      std::cout << "Time taken using buffer + two part parse: "
                << elapsed.count() << std::endl;
    }

    {
      auto start = std::chrono::high_resolution_clock::now();

      Graph graph = Graph::parse_mmap(filename);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed = end - start;

      std::cout << "Vertices: " << graph.num_vertices() << std::endl;

      std::cout << "Time taken for parse (using mmap): " << elapsed.count()
                << std::endl;

      auto start2 = std::chrono::high_resolution_clock::now();

      Colouring colouring = graph.find_colouring_greedy();

      auto end2 = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed2 = end2 - start2;

      std::cout << "Found colouring with " << colouring.num_colors << " colours"
                << std::endl;

      std::cout << "Time taken to find colouring: " << elapsed2.count()
                << std::endl;
    }

    return 0;

    {
      auto start = std::chrono::high_resolution_clock::now();

      Graph graph = Graph::two_part_parse_mmap(filename);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed = end - start;

      std::cout << "Vertices: " << graph.num_vertices() << std::endl;

      std::cout << "Time taken for parse (using mmap + 2 part parsing): "
                << elapsed.count() << std::endl;
    }
  }

  return 0;

  std::ifstream is{filename};

  if (!is.is_open()) {
    std::cerr << "Failed to open " << filename << std::endl;
    return 1;
  }

  read_header(is);

  auto parse_start = std::chrono::high_resolution_clock::now();

  BoostGraph boost_graph = parse_boost_graph(is);

  auto parse_end = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double> parse_elapsed{parse_end - parse_start};

  std::cout << "Number of vertices: " << boost::num_vertices(boost_graph)
            << std::endl;

  std::cout << "Time taken to parse boost graph: " << parse_elapsed.count()
            << std::endl;

  {
    auto start = std::chrono::high_resolution_clock::now();

    const auto index_map = boost::get(boost::vertex_index, boost_graph);

    std::vector<vertices_size_type> colors(boost::num_vertices(boost_graph));
    auto color_map = boost::make_safe_iterator_property_map(
        colors.begin(), colors.size(), index_map);

    const auto num_colors =
        boost::sequential_vertex_coloring(boost_graph, color_map);

    auto end = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double> elapsed{end - start};

    std::cout << num_colors << " colours :)" << std::endl;

    std::cout << "Time taken to compute colouring: " << elapsed.count()
              << std::endl;
  }

  {
    auto start = std::chrono::high_resolution_clock::now();

    const auto index_map = boost::get(boost::vertex_index, boost_graph);

    auto order = boost::copy_range<std::vector<vertex_descriptor>>(
        boost::vertices(boost_graph));
    auto order_map = boost::make_safe_iterator_property_map(
        order.begin(), order.size(), index_map);

    boost::smallest_last_vertex_ordering(boost_graph, order_map);

    auto order_end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> order_elapsed{order_end - start};

    std::cout << "Finished ordering vertices" << std::endl;

    std::cout << "Time taken to order vertices: " << order_elapsed.count()
              << std::endl;

    std::vector<vertices_size_type> colors(boost::num_vertices(boost_graph));
    auto color_map = boost::make_safe_iterator_property_map(
        colors.begin(), colors.size(), index_map);

    const auto num_colors =
        boost::sequential_vertex_coloring(boost_graph, order_map, color_map);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> color_elapsed{end - order_end};
    std::chrono::duration<double> total_elapsed{end - start};

    std::cout << num_colors << " colours :)" << std::endl;
    std::cout << "Time taken to find colouring: " << color_elapsed.count()
              << std::endl;
    std::cout << "Total time: " << total_elapsed.count() << std::endl;
  }

  return 0;
}
