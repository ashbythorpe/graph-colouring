#include "colouring.hpp"
#include "reader.hpp"
#include <cstddef>

Colouring find_colouring_greedy(Reader &reader, bool two_pass, size_t nodes);

void benchmark_neighbour_methods(const std::string &file, size_t nodes);
