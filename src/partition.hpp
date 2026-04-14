#pragma once

#include "colouring.hpp"
#include "reader.hpp"

ColouringResult find_colouring_partition(Reader &reader, size_t m, bool two_pass);
