library(tidyverse)
library(scales)

folders <- list.files("./data")

file <- function(folder, name) paste0("./data/", folder, "/", name)

get_files <- function(name) {
  map(folders, \(folder) read_csv(file(folder, name)) |> mutate(graph = folder)) |>
    list_rbind()
}

graph_data <- get_files("graph_data.csv")
greedy_single_pass <- get_files("greedy_single_pass.csv")
greedy_two_pass <- get_files("greedy_two_pass.csv")
partition_single_pass <- get_files("partition_single_pass.csv")
partition_two_pass <- get_files("partition_two_pass.csv")
palette_single_pass_trials <- get_files("palette_single_pass_trials.csv")
palette_two_pass_trials <- get_files("palette_two_pass_trials.csv")
palette_single_pass_benchmarks <- get_files("palette_single_pass_benchmarks.csv")
palette_two_pass_benchmarks <- get_files("palette_two_pass_benchmarks.csv")
palette_single_pass_compressed_benchmarks <- get_files("palette_single_pass_compressed_benchmarks.csv")
palette_two_pass_compressed_benchmarks <- get_files("palette_two_pass_compressed_benchmarks.csv")

pareto_front <- function(data) {
  data |>
    arrange(avg_k) |>
    mutate(max_edges = pmax(avg_cg_edges, avg_sp_edges)) |>
    mutate(cum_min_edges = cummin(max_edges)) |>
    distinct(cum_min_edges, .keep_all = TRUE) |>
    select(-cum_min_edges) |>
    mutate(colours = avg_k)
}

partition_two_pass |>
  mutate(max_edges = pmax(cg_edges, sp_edges)) |>
  ggplot(aes(x = colours, y = max_edges, colour = m)) +
  geom_point()

partition_two_pass |>
  pivot_longer(c(cg_edges, sp_edges), names_to = "pass", values_to = "edges") |>
  ggplot(aes(x = m, y = colours)) +
  geom_point()

# Remove the runs of the two-pass algorithm where colours start to decrease
max_m <- partition_two_pass |>
  arrange(desc(colours)) |>
  slice_head() |>
  _$m

bind_rows(
  partition_two_pass |> mutate(method = "Partition algorithm (two pass)", max_edges = pmax(cg_edges, sp_edges)) |> filter(m <= max_m),
  pareto_front(palette_single_pass_trials) |> mutate(method = "APS algorithm", colours = avg_k),
  pareto_front(palette_two_pass_trials) |> mutate(method = "APS algorithm (two pass)", colours = avg_k),
  partition_single_pass |> mutate(method = "Partition algorithm", max_edges = pmax(cg_edges, sp_edges)),
) |>
  ggplot(aes(x = colours, y = max_edges, colour = method)) +
  geom_point() +
  coord_cartesian(xlim = c(0, 200)) +
  scale_color_brewer(palette = "Set1") +
  scale_y_continuous(label = label_comma())

pareto_front(palette_single_pass_trials) |>
  filter(colours <= 200) |>
  left_join(graph_data) |>
  filter(max_edges < edges) |>
  rowwise() |>
  mutate(a = (c / nodes) * sum(1:nodes ^ (-params_x))) |>
  ungroup() |>
  ggplot(aes(x = colours, y = max_edges, colour = a)) +
  geom_point()

pareto_front(palette_single_pass_trials) |>
  filter(colours > min(colours, na.rm = TRUE), colours < 200) |>
  left_join(graph_data) |>
  rowwise() |>
  mutate(a = (c / nodes) * sum(1:nodes ^ (-params_x))) |>
  ungroup() |>
  ggplot(aes(x = colours, y = a, colour = params_max_colours)) +
  geom_point()

pareto_front(palette_single_pass_trials) |>
  left_join(graph_data) |>
  rowwise() |>
  mutate(max_edges = pmax(avg_cg_edges, avg_sp_edges), colours = avg_k, a = (c / nodes) * sum(1:nodes ^ (-params_x))) |>
  ungroup() |>
  filter(max_edges < edges, colours < 500) |>
  ggplot(aes(x = a, y = params_max_colours)) +
  geom_point(aes(colour = colours)) +
  geom_smooth()

x <- pareto_front(palette_single_pass_trials) |>
  left_join(graph_data) |>
  rowwise() |>
  mutate(max_edges = pmax(avg_cg_edges, avg_sp_edges), colours = avg_k, a = (c / nodes) * sum(1:nodes ^ (-params_x))) |>
  ungroup() |>
  filter(max_edges < edges, colours < 500)

skipped_proportion <- function(c, x, max_colours, nodes) {
  ell <- c * ((1:nodes) ^ -x)
  
  sum(map_dbl(1:nodes, \(i) sum(1 - dhyper(0, ell[i], max_colours - ell[i], ell[-i]))))
}

nodes <- graph_data$nodes
dhyper(0, 1:nodes, max_colours- 1:nodes, 1:nodes)

row <- pareto_front(palette_single_pass_trials) |>
  slice_sample()
skipped_proportion(row$c, row$params_x, row$params_max_colours, graph_data$nodes)

palette_single_pass_trials |>
  left_join(graph_data) |>
  mutate(max_edges = pmax(avg_cg_edges, avg_sp_edges), colours = avg_k, edges_group = cut(max_edges, 10)) |>
  rowwise() |>
  mutate(a = (c / nodes) * sum(1:nodes ^ (-params_x))) |>
  ungroup() |>
  filter(max_edges < edges, colours < 500) |>
  ggplot(aes(x = colours, y = max_edges, colour = params_max_colours)) +
  geom_point()

graph_data$edges

greedy_single_pass$peak_memory

palette_single_pass_benchmarks |>
  ggplot(aes(x = colours, y = peak_memory, colour = x)) +
  geom_point() +
  scale_y_continuous(labels = label_comma())

palette_two_pass_benchmarks |>
  left_join(palette_two_pass_trials, by = join_by(max_colours == params_max_colours, x == params_x, c)) |>
  ggplot(aes(x = colours, y = peak_memory, colour = avg_cg_edges)) +
  geom_point() +
  scale_y_continuous(labels = label_comma()) +
  coord_cartesian(ylim = c(0, NA), xlim = c(0, 200))

palette_single_pass_compressed_benchmarks |>
  slice_sample()

cat