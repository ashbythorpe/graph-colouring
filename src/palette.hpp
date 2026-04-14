#include "colouring.hpp"
#include "reader.hpp"
#include <cstddef>
#include <cstdint>
#include <functional>

ColouringResult
find_colouring_palette(Reader &reader, size_t nodes, size_t max_colours,
                       bool compress_palettes, bool two_pass, std::function<size_t(uint32_t)> list_size_fun);
