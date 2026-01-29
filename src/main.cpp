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

static bool benchmark_memory;

class MemoryTracker {
  size_t current_usage{0};
  size_t peak_usage{0};
  size_t total_usage{0};

public:
  void add(size_t n) {
    current_usage += n;
    total_usage += n;
    if (current_usage > peak_usage) {
      peak_usage = current_usage;
    }
  }

  void remove(size_t n) { current_usage -= n; }

  void reset() {
    current_usage = 0;
    peak_usage = 0;
    total_usage = 0;
  }

  void print_usage() {
#ifdef BENCHMARK_MEMORY
    std::cout << "Peak memory usage: " << peak_usage / 1000000 << "MB"
              << std::endl;
    std::cout << "Total allocated memory: " << total_usage / 1000000 << "MB"
              << std::endl;
#endif // BENCHMARK_MEMORY
  }
};

static MemoryTracker memory_tracker;

#ifdef BENCHMARK_MEMORY
// https://en.cppreference.com/w/cpp/memory/new/operator_new
void *operator new(std::size_t sz) {
  if (sz == 0) {
    ++sz; // avoid std::malloc(0) which may return nullptr on success
  }

  if (void *ptr = std::malloc(sz)) {
    memory_tracker.add(sz);
    return ptr;
  }

  throw std::bad_alloc{}; // required by [new.delete.single]/3
}

// no inline, required by [replacement.functions]/3
void *operator new[](std::size_t sz) {
  if (sz == 0) {
    ++sz; // avoid std::malloc(0) which may return nullptr on success
  }

  if (void *ptr = std::malloc(sz)) {
    memory_tracker.add(sz);
    return ptr;
  }

  throw std::bad_alloc{}; // required by [new.delete.single]/3
}

void operator delete(void *ptr) noexcept {
  std::cerr << "delete without specified size" << std::endl;
  std::free(ptr);
}

void operator delete(void *ptr, std::size_t size) noexcept {
  memory_tracker.remove(size);
  std::free(ptr);
}

void operator delete[](void *ptr) noexcept {
  std::cerr << "delete[] without specified size" << std::endl;
  std::free(ptr);
}

void operator delete[](void *ptr, std::size_t size) noexcept {
  memory_tracker.remove(size);
  std::free(ptr);
}
#endif // BENCHMARK_MEMORY

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

bool isspace(char c) { return c == ' ' || c == '\n' || c == '\t' || c == '\r'; }

class Reader {
public:
  virtual ~Reader() = default;

  virtual void skip_header() = 0;
  virtual bool read_number(uint32_t &num) = 0;
  virtual void reset() = 0;
};

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

class BufReader : public Reader {
  std::ifstream file;
  char buffer[1024 * 1024];
  char *ptr = buffer;
  char *end = ptr;

public:
  BufReader(std::string file) : file(std::ifstream{file}) {}

  void skip_header() override {
    std::string line;
    while (file.peek() == '#') {
      std::getline(file, line);
    }
  }

  bool read_number(uint32_t &num) override {
    if (ptr >= end || (end - ptr) < 32) {
      size_t leftover = end - ptr;
      if (leftover > 0) {
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

    while (ptr < end && isspace(*ptr)) {
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

  void reset() override {
    file.clear();
    file.seekg(0);
  }
};

class MMapReader : public Reader {
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
      return;
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
      std::cerr << "Error getting file stats";
      close(fd);
      return;
    }
    length = sb.st_size;

    address =
        static_cast<char *>(mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0));
    if (address == MAP_FAILED) {
      std::cerr << "Error mapping file";
      close(fd);
      return;
    }

    ptr = address;
    end = address + length;
  }

  ~MMapReader() override {
    munmap(address, length);
    close(fd);
  }

  void skip_header() override {
    while (ptr < end && *ptr == '#') {
      while (ptr < end && *ptr != '\n') {
        ptr++;
      }

      if (ptr < end) {
        ptr++;
      }
    }
  }

  void reset() override {
    ptr = address;
    end = address + length;
  }

  bool read_number(uint32_t &num) override {
    while (ptr < end && isspace(*ptr)) {
      ptr++;
    }

    if (ptr >= end) {
      return false;
    }

    auto [next_ptr, err] = std::from_chars(ptr, end, num);
    if (err != std::errc{}) {
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

  static std::vector<size_t> parse_degrees(Reader &reader) {
    reader.skip_header();

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

public:
  void add_edge(uint32_t from, uint32_t to) {
    uint32_t max_size = std::max(to, from) + 1;

    while (max_size > nodes.size()) {
      nodes.push_back(Node{});
    }

    nodes[from].add_node(to);
    nodes[to].add_node(from);
  }

  static Graph parse(Reader &reader) {
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

  static Graph two_part_parse(Reader &reader) {
    std::vector<size_t> degrees = parse_degrees(reader);

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

BoostGraph parse_boost_graph(Reader &reader) {
  BoostGraph graph{};

  reader.skip_header();

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

  std::cout << "Parsed graph" << std::endl;

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
    // assigned the node the colour `0`, so update `colours` accordingly.
    for (size_t node_index = colouring.colours.size();
         node_index * n + graph_index < nodes; node_index++) {
      colours[node_index * n + graph_index] = num_colors;
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

  const std::string file{argv[1]};

  // {
  //   auto start = std::chrono::high_resolution_clock::now();
  //
  //   MMapReader reader{file};
  //
  //   Colouring colouring = find_colouring_stream(reader, 10);
  //
  //   auto end = std::chrono::high_resolution_clock::now();
  //   std::chrono::duration<double> elapsed{end - start};
  //
  //   std::cout << "Found colouring using 10-partition streaming with " <<
  //   colouring.num_colors << " colours"
  //             << std::endl;
  //   std::cout << "Vertices: " << colouring.colours.size() << std::endl;
  //   std::cout << "Time taken: " << elapsed.count() << std::endl;
  // }

  // {
  //   g_tracker.reset();
  //   auto start = std::chrono::high_resolution_clock::now();
  //
  //   MMapReader reader{file};
  //
  //   auto graph = Graph::parse(reader);
  //
  //   std::cout << "Vertices: " << graph.num_vertices() << std::endl;
  //
  //   Colouring colouring = graph.find_colouring_greedy();
  //
  //   auto end = std::chrono::high_resolution_clock::now();
  //   std::chrono::duration<double> elapsed{end - start};
  //
  //   std::cout << "Found colouring using greedy with " << colouring.num_colors
  //             << " colours" << std::endl;
  //   std::cout << "Time taken: " << elapsed.count() << std::endl;
  //   g_tracker.print_usage();
  // }

  for (size_t n = 50; n > 1; n--) {
    memory_tracker.reset();
    auto start = std::chrono::high_resolution_clock::now();

    MMapReader reader{file};

    Colouring colouring = find_colouring_stream(reader, n);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed{end - start};

    std::cout << "Found colouring using " << n << "-partition streaming with "
              << colouring.num_colors << " colours" << std::endl;
    std::cout << "Vertices: " << colouring.colours.size() << std::endl;
    std::cout << "Time taken: " << elapsed.count() << std::endl;
    memory_tracker.print_usage();
  }

  return 0;

  {
    auto start = std::chrono::high_resolution_clock::now();

    MMapReader reader{file};

    auto graph = Graph::parse(reader);

    std::cout << "Vertices: " << graph.num_vertices() << std::endl;

    Colouring colouring = graph.find_colouring_greedy();

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed{end - start};

    std::cout << "Time taken using mmap: " << elapsed.count() << std::endl;

    std::cout << "Found colouring with " << colouring.num_colors << " colours"
              << std::endl;
  }

  {
    auto start = std::chrono::high_resolution_clock::now();

    BufReader reader{file};

    auto graph = Graph::two_part_parse(reader);

    std::cout << "Vertices: " << graph.num_vertices() << std::endl;

    Colouring colouring = graph.find_colouring_greedy();

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed{end - start};

    std::cout << "Time taken using two part parse: " << elapsed.count()
              << std::endl;

    std::cout << "Found colouring with " << colouring.num_colors << " colours"
              << std::endl;
  }

  {
    auto start = std::chrono::high_resolution_clock::now();

    MMapReader reader{file};

    auto graph = Graph::two_part_parse(reader);

    std::cout << "Vertices: " << graph.num_vertices() << std::endl;

    Colouring colouring = graph.find_colouring_greedy();

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed{end - start};

    std::cout << "Time taken using mmap + two part parse: " << elapsed.count()
              << std::endl;

    std::cout << "Found colouring with " << colouring.num_colors << " colours"
              << std::endl;
  }

  return 0;

  std::ifstream is{file};

  if (!is.is_open()) {
    std::cerr << "Failed to open " << file << std::endl;
    return 1;
  }

  read_header(is);

  auto parse_start = std::chrono::high_resolution_clock::now();

  BufReader reader{file};
  BoostGraph boost_graph = parse_boost_graph(reader);

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
