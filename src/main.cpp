#include "colouring.hpp"
#include "graph.hpp"
#include "greedy.hpp"
#include "memory_tracker.hpp"
#include "palette.hpp"
#include "partition.hpp"
#include "reader.hpp"
#include <algorithm>
#include <boost/concept/detail/has_constraints.hpp>
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
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <limits>
#include <ostream>
#include <string>
#include <string_view>
#include <sys/mman.h>
#include <sys/stat.h>
#include <vector>

size_t get_nodes(std::string file) {
  MMapReader reader{file};

  uint32_t nodes = 0;
  uint32_t n;

  while (reader.read_number(n)) {
    nodes = std::max(nodes, n + 1);
  }

  return size_t(nodes);
}

enum class Algorithm { Greedy, APS, PS, Partition };

class Parser {
  Algorithm algorithm;
  size_t max_colours;
  double c;
  double x;
  size_t m;
  bool two_pass;
  bool compress_palettes;
  size_t trials = 50;
  size_t palette_size;

public:
  Parser(const std::vector<std::string_view> &args) {
    const std::string_view &algorithm_str =
        *(std::find(args.begin(), args.end(), "--algorithm") + 1);

    if (algorithm_str == "greedy") {
      algorithm = Algorithm::Greedy;
    } else if (algorithm_str == "aps") {
      algorithm = Algorithm::APS;
    } else if (algorithm_str == "partition") {
      algorithm = Algorithm::Partition;
    } else if (algorithm_str == "ps") {
      algorithm = Algorithm::PS;
    } else {
      std::cerr << "Invalid algorithm";
    }

    two_pass = std::find(args.begin(), args.end(), "--two-pass") != args.end();
    compress_palettes = std::find(args.begin(), args.end(),
                                  "--compress-palettes") != args.end();

    auto trials_pos = std::find(args.begin(), args.end(), "--trials");
    if (trials_pos != args.end()) {
      const std::string_view &trials_str = *(trials_pos + 1);
      trials = std::stoul(std::string(trials_str));
    }

    if (algorithm == Algorithm::APS) {
      const std::string_view &max_colours_str =
          *(std::find(args.begin(), args.end(), "--max-colours") + 1);
      max_colours = std::stoul(std::string(max_colours_str));

      const std::string_view &c_str =
          *(std::find(args.begin(), args.end(), "--c") + 1);
      c = std::stod(std::string(c_str));

      const std::string_view &x_str =
          *(std::find(args.begin(), args.end(), "--x") + 1);
      x = std::stod(std::string(x_str));
    } else if (algorithm == Algorithm::Partition) {
      const std::string_view &m_str =
          *(std::find(args.begin(), args.end(), "--m") + 1);
      m = std::stoul(std::string(m_str));
    } else if (algorithm == Algorithm::PS) {
      const std::string_view &max_colours_str =
          *(std::find(args.begin(), args.end(), "--max-colours") + 1);
      max_colours = std::stoul(std::string(max_colours_str));

      const std::string_view &palette_size_str =
          *(std::find(args.begin(), args.end(), "--palette-size") + 1);
      palette_size = std::stoul(std::string(palette_size_str));
    }
  };

  void run(Reader &reader, size_t nodes) {
    if (algorithm == Algorithm::Greedy) {
      find_colouring_greedy(reader, two_pass, nodes);
    } else if (algorithm == Algorithm::APS) {
      find_colouring_palette(
          reader, nodes, max_colours, compress_palettes, two_pass,
          [&](uint32_t i) { return size_t(c * std::pow(nodes - i, x)); });
    } else if (algorithm == Algorithm::Partition) {
      find_colouring_partition(reader, m, two_pass, nodes);
    } else {
      find_colouring_palette(reader, nodes, max_colours, compress_palettes,
                             two_pass,
                             [&](uint32_t i) { return palette_size; });
    }
  }

  void test(Reader &reader, size_t nodes) {
    Colouring colouring;

    if (algorithm == Algorithm::Greedy) {
      colouring = find_colouring_greedy(reader, two_pass, nodes);
    } else if (algorithm == Algorithm::APS) {
      colouring =
          find_colouring_palette(
              reader, nodes, max_colours, compress_palettes, two_pass,
              [&](uint32_t i) { return size_t(c * std::pow(nodes - i, x)); })
              .colouring;
    } else if (algorithm == Algorithm::Partition) {
      colouring =
          find_colouring_partition(reader, m, two_pass, nodes).colouring;
    } else {
      colouring = find_colouring_palette(
                      reader, nodes, max_colours, compress_palettes, two_pass,
                      [&](uint32_t i) { return palette_size; })
                      .colouring;
    }

    Graph graph = Graph::parse_full(reader);
    graph.validate_colouring(colouring);
  }

  void experiment(Reader &reader, size_t nodes) {
    if (algorithm == Algorithm::Greedy) {
      std::cout << find_colouring_greedy(reader, two_pass, nodes).num_colours
                << std::endl;
    } else if (algorithm == Algorithm::APS || algorithm == Algorithm::PS) {
      size_t min_k = std::numeric_limits<uint32_t>::max(), tot_k = 0, max_k = 0;
      size_t min_cg_edges = std::numeric_limits<uint32_t>::max(),
             tot_cg_edges = 0, max_cg_edges = 0;
      size_t min_sp_edges = std::numeric_limits<uint32_t>::max(),
             tot_sp_edges = 0, max_sp_edges = 0;

      for (int i = 0; i < trials; i++) {
        reader.reset();

        ColouringResult result;
        if (algorithm == Algorithm::APS) {
          result = find_colouring_palette(
              reader, nodes, max_colours, compress_palettes, two_pass,
              [&](uint32_t i) { return size_t(c * std::pow(nodes - i, x)); });
        } else {
          result = find_colouring_palette(
              reader, nodes, max_colours, compress_palettes, two_pass,
              [&](uint32_t i) { return palette_size; });
        }

        min_k = std::min(min_k, result.colouring.num_colours);
        max_k = std::max(max_k, result.colouring.num_colours);
        tot_k += result.colouring.num_colours;

        min_cg_edges = std::min(min_cg_edges, result.cg_edges);
        max_cg_edges = std::max(max_cg_edges, result.cg_edges);
        tot_cg_edges += result.cg_edges;

        min_sp_edges = std::min(min_sp_edges, result.sp_edges);
        max_sp_edges = std::max(max_sp_edges, result.sp_edges);
        tot_sp_edges += result.sp_edges;
      }

      std::cout << min_k << "," << max_k << "," << double(tot_k) / trials << ","
                << min_cg_edges << "," << max_cg_edges << ","
                << double(tot_cg_edges) / trials << "," << min_sp_edges << ","
                << max_sp_edges << "," << double(tot_sp_edges) / trials
                << std::endl;
    } else {
      ColouringResult result =
          find_colouring_partition(reader, m, two_pass, nodes);

      std::cout << result.colouring.num_colours << "," << result.cg_edges << ","
                << result.sp_edges << std::endl;
    }
  }

  void benchmark(const std::string &file, size_t nodes) {
    // Warmup
    for (int i = 0; i < std::max(std::min(trials / 10, 5UL), 2UL); i++) {
      MMapReader reader{file};
      run(reader, nodes);
    }

    double min = std::numeric_limits<double>::max(), max = 0, total = 0;

    for (int i = 0; i < trials; i++) {
      auto start = std::chrono::high_resolution_clock::now();

      MMapReader reader{file};
      run(reader, nodes);

      auto end = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> elapsed{end - start};

      min = std::min(min, elapsed.count());
      max = std::max(max, elapsed.count());
      total += elapsed.count();
    }

    std::cout << min << "," << max << "," << total / trials << std::endl;
  }

  void benchmark_memory(const std::string &file, size_t nodes) {
    memory_tracker.reset();

    MMapReader reader{file};
    run(reader, nodes);

    std::cout << memory_tracker.peak_usage << "," << memory_tracker.total_usage
              << std::endl;
  }
};

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

  size_t nodes = get_nodes(file);

  Parser parser{args};

  if (std::find(args.begin(), args.end(), "experiment") != args.end()) {
    MockReader reader{file};
    parser.experiment(reader, nodes);
  } else if (std::find(args.begin(), args.end(), "test") != args.end()) {
    MMapReader reader{file};
    parser.test(reader, nodes);
  } else if (std::find(args.begin(), args.end(), "benchmark") != args.end()) {
    parser.benchmark(file, nodes);
  } else if (std::find(args.begin(), args.end(), "benchmark-memory") !=
             args.end()) {
    parser.benchmark_memory(file, nodes);
  } else if (std::find(args.begin(), args.end(), "run") != args.end()) {
    MMapReader reader{file};
    parser.run(reader, nodes);
  }
}
