#include "utils.hpp"
#include <algorithm>
#include <chrono>
#include <iostream>
#include <limits>
#include <tuple>

std::tuple<double, double, double> benchmark(std::function<void()> f) {
  // Warmup
  for (int i = 0; i < 5; i++) {
    f();
  }

  double min = std::numeric_limits<double>::max(), max = 0, total = 0;

  for (int i = 0; i < 50; i++) {
    auto start = std::chrono::high_resolution_clock::now();

    f();

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed{end - start};

    min = std::min(min, elapsed.count());
    max = std::max(max, elapsed.count());
    total += elapsed.count();
  }

  return {min, max, total / 50.0};
}

void report_benchmark(std::tuple<double, double, double> result) {
  auto [min, max, avg] = result;

  std::cout << "Min: " << min << "s\n"
    << "Max: " << max << "s\n"
    << "Average: " << avg << "s\n";
}
