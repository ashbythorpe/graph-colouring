#pragma once
#include <cstddef>

class MemoryTracker {
  size_t current_usage{0};
public:
  size_t peak_usage{0};
  size_t total_usage{0};

  void add(size_t n);

  void remove(size_t n);

  void reset();

  void print_usage();
};

extern MemoryTracker memory_tracker;
