#include <functional>

std::tuple<double, double, double> benchmark(std::function<void()> f);

void report_benchmark(std::tuple<double, double, double> result);
