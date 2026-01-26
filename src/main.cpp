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
  std::vector<size_t> colours;
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
    while (true) {
      if (ptr >= end) {
        file.read(ptr, 1024 * 1024 - (ptr - buffer));

        if (file.gcount() == 0) {
          return false;
        } else {
          end = ptr + file.gcount();
        }
      }

      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr >= end) {
        std::memmove(buffer, ptr, end - ptr);
        ptr = buffer + (end - ptr);
        end = ptr;
        continue;
      }

      auto [new_ptr, err] = std::from_chars(ptr, end, num);

      if (err != std::errc()) {
        return false;
      } else if (new_ptr >= end) {
        std::memmove(buffer, ptr, end - ptr);
        ptr = buffer + (end - ptr);
        end = ptr;
      } else {
        ptr = const_cast<char *>(new_ptr);
        return true;
      }
    }
  }
};

class Graph {
  std::vector<Node> nodes;
  size_t _max_degree;

  static std::vector<size_t> parse_degrees(std::istream &is) {
    read_header(is);

    std::vector<size_t> degrees{};

    std::string line;
    uint32_t from, to;
    while (std::getline(is, line)) {
      const char *end = &line.front() + line.size();
      auto [ptr, err] = std::from_chars(&line.front(), end, from);

      if (err != std::errc{}) {
        std::cerr << "Error parsing graph" << std::endl;
        std::cerr << line << std::endl;
        break;
      }

      while (ptr != end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr == end) {
        break;
      }

      auto [_, err2] = std::from_chars(ptr, end, to);

      if (err2 != std::errc{}) {
        std::cerr << "Error parsing graph (2)" << std::endl;
        break;
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

  static std::vector<size_t> parse_degrees_buf(std::string filename) {
    Reader reader {filename};

    reader.read_header();

    std::vector<size_t> degrees{};

    uint32_t from, to;
    while (reader.read_number(from) && reader.read_number(to)) {
      uint32_t max_size = std::max(to, from) + 1;

      while (max_size > degrees.size()) {
        degrees.push_back(0);
      }

      degrees[from]++;
      degrees[to]++;
    }

    return degrees;
  }

  static std::vector<size_t> parse_degrees_mmap(const char *ptr,
                                                const char *end) {
    std::vector<size_t> degrees{};

    uint32_t from, to;
    while (ptr < end) {
      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr >= end) {
        break;
      }

      auto [next_ptr, ec1] = std::from_chars(ptr, end, from);
      if (ec1 != std::errc{}) {
        std::cerr << "Error parsing graph" << std::endl;
        break;
      }
      ptr = next_ptr;

      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      auto [next_ptr2, err2] = std::from_chars(ptr, end, to);

      if (err2 != std::errc{}) {
        std::cerr << "Error parsing graph (2)" << std::endl;
        break;
      }

      ptr = next_ptr2;

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
  // Graph(std::vector<Node> nodes, size_t _max_degree)
  //     : nodes(nodes), _max_degree(_max_degree) {}
  static Graph two_part_parse(std::istream &is) {
    std::vector<size_t> degrees = parse_degrees(is);
    is.clear();
    is.seekg(0);

    read_header(is);

    Graph graph{};

    graph.nodes.reserve(degrees.size());

    std::transform(degrees.begin(), degrees.end(),
                   std::back_inserter(graph.nodes),
                   [](size_t degree) { return Node{degree}; });

    std::string line;
    uint32_t from, to;
    while (std::getline(is, line)) {
      const char *end = &line.front() + line.size();
      auto [ptr, err] = std::from_chars(&line.front(), end, from);

      if (err != std::errc{}) {
        std::cerr << "Error parsing graph" << std::endl;
        std::cerr << line << std::endl;
        break;
      }

      while (ptr != end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr == end) {
        break;
      }

      auto [_, err2] = std::from_chars(ptr, end, to);

      if (err2 != std::errc{}) {
        std::cerr << "Error parsing graph (2)" << std::endl;
        break;
      }

      uint32_t max_size = std::max(to, from) + 1;

      if (max_size > graph.nodes.size()) {
        std::cerr << "Error" << std::endl;
        break;
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

  static Graph parse_mmap(const std::string &path) {
    int fd = open(path.c_str(), O_RDONLY);
    if (fd == -1) {
      std::cerr << "Error opening file";
      return {};
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
      std::cerr << "Error getting file stats";
      close(fd);
      return {};
    }
    size_t length = sb.st_size;

    char *address =
        static_cast<char *>(mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0));
    if (address == MAP_FAILED) {
      std::cerr << "Error mapping file";
      close(fd);
      return {};
    }

    const char *ptr = address;
    const char *end = address + length;

    while (ptr < end && *ptr == '#') {
      while (ptr < end && *ptr != '\n')
        ptr++;
      if (ptr < end)
        ptr++;
    }

    Graph graph{};

    uint32_t from, to;
    while (ptr < end) {
      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr >= end) {
        break;
      }

      auto [next_ptr, ec1] = std::from_chars(ptr, end, from);
      if (ec1 != std::errc{}) {
        std::cerr << "Error parsing graph" << std::endl;
        break;
      }
      ptr = next_ptr;

      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      auto [next_ptr2, err2] = std::from_chars(ptr, end, to);

      if (err2 != std::errc{}) {
        std::cerr << "Error parsing graph (2)" << std::endl;
        break;
      }

      ptr = next_ptr2;

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

    munmap(address, length);
    close(fd);

    return graph;
  }

  static Graph two_part_parse_mmap(const std::string &path) {
    int fd = open(path.c_str(), O_RDONLY);
    if (fd == -1) {
      std::cerr << "Error opening file";
      return {};
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
      std::cerr << "Error getting file stats";
      close(fd);
      return {};
    }
    size_t length = sb.st_size;

    char *address =
        static_cast<char *>(mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0));
    if (address == MAP_FAILED) {
      std::cerr << "Error mapping file";
      close(fd);
      return {};
    }

    const char *ptr = address;
    const char *end = address + length;

    while (ptr < end && *ptr == '#') {
      while (ptr < end && *ptr != '\n')
        ptr++;
      if (ptr < end)
        ptr++;
    }

    std::vector<size_t> degrees = parse_degrees_mmap(ptr, end);

    Graph graph{};

    graph.nodes.reserve(degrees.size());

    std::transform(degrees.begin(), degrees.end(),
                   std::back_inserter(graph.nodes),
                   [](size_t degree) { return Node{degree}; });

    uint32_t from, to;
    while (ptr < end) {
      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr >= end) {
        break;
      }

      auto [next_ptr, ec1] = std::from_chars(ptr, end, from);
      if (ec1 != std::errc{}) {
        std::cerr << "Error parsing graph" << std::endl;
        break;
      }
      ptr = next_ptr;

      while (ptr < end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      auto [next_ptr2, err2] = std::from_chars(ptr, end, to);

      if (err2 != std::errc{}) {
        std::cerr << "Error parsing graph (2)" << std::endl;
        break;
      }

      ptr = next_ptr2;

      uint32_t max_size = std::max(to, from) + 1;

      graph.nodes[from].add_node(to);
      graph.nodes[to].add_node(from);

      graph._max_degree = std::max({
          graph._max_degree,
          graph.nodes[from].degree(),
          graph.nodes[to].degree(),
      });
    }

    munmap(address, length);
    close(fd);

    return graph;
  }

  static Graph parse_buf(std::string file) {
    Reader reader{file};

    reader.read_header();

    Graph graph{};

    std::string line;
    uint32_t from, to;
    while (reader.read_number(from) && reader.read_number(to)) {
      // std::cout << "Read numbers: " << from << ", " << to << std::endl;
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
    std::vector<size_t> degrees = parse_degrees_buf(filename);

    Reader reader {filename};

    reader.read_header();

    Graph graph{};

    graph.nodes.reserve(degrees.size());

    std::transform(degrees.begin(), degrees.end(),
                   std::back_inserter(graph.nodes),
                   [](size_t degree) { return Node{degree}; });

    uint32_t from, to;
    while (reader.read_number(from) && reader.read_number(to)) {
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

  static Graph parse(std::istream &is) {
    read_header(is);

    Graph graph{};

    std::string line;
    uint32_t from, to;
    while (std::getline(is, line)) {
      const char *end = &line.front() + line.size();
      auto [ptr, err] = std::from_chars(&line.front(), end, from);

      if (err != std::errc{}) {
        std::cerr << "Error parsing graph" << std::endl;
        std::cerr << line << std::endl;
        break;
      }

      while (ptr != end && std::isspace(static_cast<unsigned char>(*ptr))) {
        ptr++;
      }

      if (ptr == end) {
        break;
      }

      auto [_, err2] = std::from_chars(ptr, end, to);

      if (err2 != std::errc{}) {
        std::cerr << "Error parsing graph (2)" << std::endl;
        break;
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

  size_t num_vertices() const { return nodes.size(); }

  size_t max_degree() const { return _max_degree; }

  Colouring find_colouring_greedy() const {
    const size_t UNCOLOURED = std::numeric_limits<size_t>::max();

    std::vector<size_t> colouring(nodes.size(), UNCOLOURED);
    const size_t colours = _max_degree + 1;

    std::vector<char> neighbour_colours(colours);

    size_t num_colors = 1;
    for (size_t i = 0; i < nodes.size(); i++) {
      const Node &node = nodes[i];

      for (size_t neighbour : node.neighbours) {
        size_t colour = colouring[neighbour];

        if (colour != UNCOLOURED) {
          neighbour_colours[colour] = 1;
        }
      }

      size_t colour = 0;
      while (colour < neighbour_colours.size() && neighbour_colours[colour]) {
        colour++;
      }

      num_colors = std::max(num_colors, colour + 1);

      colouring[i] = colour;

      for (size_t neighbour : node.neighbours) {
        if (colouring[neighbour] != UNCOLOURED) {
          neighbour_colours[colouring[neighbour]] = 0;
        }
      }
    }

    Colouring result{colouring, num_colors};

    return result;
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

      auto graph = Graph::parse_buf(filename);

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

      std::cout << "Time taken using buffer + two part parse: " << elapsed.count() << std::endl;
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

    {
      auto start = std::chrono::high_resolution_clock::now();

      Graph graph = Graph::two_part_parse_mmap(filename);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed = end - start;

      std::cout << "Vertices: " << graph.num_vertices() << std::endl;

      std::cout << "Time taken for parse (using mmap + 2 part parsing): "
                << elapsed.count() << std::endl;
    }

    is.clear();
    is.seekg(0);

    {
      auto start = std::chrono::high_resolution_clock::now();

      Graph graph = Graph::two_part_parse(is);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed = end - start;

      std::cout << "Time taken for two part parse: " << elapsed.count()
                << std::endl;
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
