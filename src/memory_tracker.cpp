#include "memory_tracker.hpp"
#include <cstddef>
#include <iostream>

void MemoryTracker::add(size_t n) {
  current_usage += n;
  total_usage += n;
  if (current_usage > peak_usage) {
    peak_usage = current_usage;
  }
}

void MemoryTracker::remove(size_t n) { current_usage -= n; }

void MemoryTracker::reset() {
  current_usage = 0;
  peak_usage = 0;
  total_usage = 0;
}

void MemoryTracker::print_usage() {
#ifdef BENCHMARK_MEMORY
  std::cout << "Peak memory usage: " << peak_usage / 1000000 << "MB"
            << std::endl;
  std::cout << "Total allocated memory: " << total_usage / 1000000 << "MB"
            << std::endl;
#endif // BENCHMARK_MEMORY
}

MemoryTracker memory_tracker;

#ifdef BENCHMARK_MEMORY
// https://en.cppreference.com/w/cpp/memory/new/operator_new
void *operator new(std::size_t sz) {
  if (sz == 0) {
    ++sz; // avoid std::malloc(0) which may return nullptr on success
  }

  if (void *ptr = std::malloc(sz)) {
    memory_tracker.add(sz);
    return ptr;
  }

  throw std::bad_alloc{}; // required by [new.delete.single]/3
}

// no inline, required by [replacement.functions]/3
void *operator new[](std::size_t sz) {
  if (sz == 0) {
    ++sz; // avoid std::malloc(0) which may return nullptr on success
  }

  if (void *ptr = std::malloc(sz)) {
    memory_tracker.add(sz);
    return ptr;
  }

  throw std::bad_alloc{}; // required by [new.delete.single]/3
}

void operator delete(void *ptr) noexcept {
  std::cerr << "delete without specified size" << std::endl;
  std::free(ptr);
}

void operator delete(void *ptr, std::size_t size) noexcept {
  memory_tracker.remove(size);
  std::free(ptr);
}

void operator delete[](void *ptr) noexcept {
  std::cerr << "delete[] without specified size" << std::endl;
  std::free(ptr);
}

void operator delete[](void *ptr, std::size_t size) noexcept {
  memory_tracker.remove(size);
  std::free(ptr);
}
#endif // BENCHMARK_MEMORY
