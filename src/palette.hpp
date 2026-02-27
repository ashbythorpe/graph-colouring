#include "colouring.hpp"
#include "reader.hpp"
#include "util.hpp"

std::pair<size_t, Colouring> find_colouring_palette(Reader &reader, GraphInfo &info, size_t max_colours, size_t palette_size);
