#include "boost.hpp"
#include "colouring.hpp"
#include "graph.hpp"
#include "memory_tracker.hpp"
#include "palette.hpp"
#include "partition.hpp"
#include "reader.hpp"
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
#include <chrono>
#include <cstddef>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <ostream>
#include <string>
#include <string_view>
#include <sys/mman.h>
#include <sys/stat.h>
#include <vector>

GraphInfo get_info(std::string file) {
  MMapReader reader{file};
  return parse_info(reader);
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
  //   memory_tracker.reset();
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
  //   memory_tracker.print_usage();
  // }
  //
  // {
  //   memory_tracker.reset();
  //   auto start = std::chrono::high_resolution_clock::now();
  //
  //   MMapReader reader{file};
  //
  //   Colouring colouring = find_colouring_stream(reader, 10);
  //
  //   auto end = std::chrono::high_resolution_clock::now();
  //   std::chrono::duration<double> elapsed{end - start};
  //
  //   std::cout << "Found colouring using " << 10 << "-partition streaming with "
  //             << colouring.num_colors << " colours" << std::endl;
  //   std::cout << "Vertices: " << colouring.colours.size() << std::endl;
  //   std::cout << "Time taken: " << elapsed.count() << std::endl;
  //   memory_tracker.print_usage();
  // }


  GraphInfo info = get_info(file);

  std::cout << "palette_size,colours,skipped,time" << std::endl;

  size_t max_colours = 450;
  for (size_t palette_size = 1; palette_size <= max_colours; palette_size++) {
    memory_tracker.reset();
    auto start = std::chrono::high_resolution_clock::now();

    MMapReader reader{file};

    auto [skipped, colouring] = find_colouring_palette(reader, info, max_colours, palette_size);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed{end - start};

    std::cout << palette_size << "," << colouring.num_colors << "," << skipped << "," << elapsed.count() << std::endl;
  }

  return 0;

  for (size_t n = 1; n < 50; n++) {
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

  return 0;

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

  auto parse_start = std::chrono::high_resolution_clock::now();

  BufReader reader{file};
  Colouring colouring = find_colouring_boost(reader);

  std::cout << colouring.num_colors << " colours" << std::endl;

  return 0;
}
