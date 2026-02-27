#include "reader.hpp"
#include <cstddef>

struct GraphInfo {
  size_t nodes;
  size_t max_degree;
};

GraphInfo parse_info(Reader& reader);
