#include "util.hpp"
#include "reader.hpp"
#include <algorithm>
#include <vector>

GraphInfo parse_info(Reader &reader) {
  reader.skip_header();

  std::vector<size_t> degrees;

  uint32_t from, to;
  size_t max_degree = 0;
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

    max_degree = std::max({max_degree, degrees[from], degrees[to]});
  }

  return GraphInfo{degrees.size(), max_degree};
}
