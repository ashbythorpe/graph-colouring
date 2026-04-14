#pragma once

#include <cstdint>
#include <vector>

struct Colouring {
  std::vector<uint32_t> colours;
  size_t num_colours;
};

struct ColouringResult {
  size_t cg_edges;
  size_t sp_edges;
  Colouring colouring;
};
