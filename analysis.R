library(tidyverse)
library(scales)
library(ggsci)
library(patchwork)

folders <- list.files("./data")

file <- function(folder, name) paste0("./data/", folder, "/", name)

get_files <- function(name) {
  map(folders, \(folder) {
    read_csv(file(folder, name)) |> mutate(graph = folder)
  }) |>
    list_rbind()
}

graph_data <- get_files("graph_data.csv")
greedy_single_pass <- get_files("greedy_single_pass.csv")
greedy_two_pass <- get_files("greedy_two_pass.csv")
partition_single_pass <- get_files("partition_single_pass.csv")
partition_two_pass <- get_files("partition_two_pass.csv")
palette_single_pass_trials <- get_files("palette_single_pass_trials.csv")
palette_two_pass_trials <- get_files("palette_two_pass_trials.csv")
palette_single_pass_benchmarks <- get_files(
  "palette_single_pass_benchmarks.csv"
)
palette_two_pass_benchmarks <- get_files("palette_two_pass_benchmarks.csv")
palette_single_pass_compressed_benchmarks <- get_files(
  "palette_single_pass_compressed_benchmarks.csv"
)
palette_two_pass_compressed_benchmarks <- get_files(
  "palette_two_pass_compressed_benchmarks.csv"
)
palette_symmetric_trials <- get_files("palette_symmetric_trials.csv")
palette_single_pass_trials_k <- read_csv(
  "data/fpsol/palette_single_pass_trials_k.csv"
) |>
  mutate(graph = "fpsol")

graph_data
pareto_front <- function(data) {
  data |>
    group_by(graph) |>
    arrange(avg_k) |>
    mutate(max_edges = pmax(avg_cg_edges, avg_sp_edges)) |>
    mutate(cum_min_edges = cummin(max_edges)) |>
    distinct(cum_min_edges, .keep_all = TRUE) |>
    select(-cum_min_edges) |>
    mutate(colours = avg_k) |>
    ungroup()
}

filter_partition_two_pass <- function(data, min = FALSE) {
  if (min) {
    data |>
      group_by(graph) |>
      arrange(pmax(cg_edges, sp_edges)) |>
      filter(m <= m[1]) |>
      ungroup()
  } else {
    data |>
      group_by(graph) |>
      arrange(desc(colours)) |>
      filter(m <= m[1]) |>
      ungroup()
  }
}

bind_rows(
  filter_partition_two_pass(partition_two_pass) |>
    mutate(
      method = "Partition algorithm (two pass)",
      max_edges = pmax(cg_edges, sp_edges)
    ),
  pareto_front(palette_single_pass_trials) |>
    mutate(method = "APS algorithm", colours = avg_k),
  # pareto_front(palette_symmetric_trials) |>
  #   mutate(method = "APS (symmetric)", colours = avg_k),
  pareto_front(palette_two_pass_trials) |>
    mutate(method = "APS algorithm (two pass)", colours = avg_k),
  partition_single_pass |>
    mutate(
      method = "Partition algorithm",
      max_edges = pmax(cg_edges, sp_edges)
    ),
  greedy_single_pass |>
    left_join(graph_data) |>
    mutate(
      method = "Greedy algorithm",
      max_edges = edges,
    ),
  # pareto_front(palette_single_pass_trials_k) |>
  #   mutate(method = "APS algorithm (tuning k)", colours = avg_k),
) |>
  filter(graph != "migration") |>
  filter(
    colours < max(round(min(colours, na.rm = TRUE) / 50), 1) * 50 * 4,
    .by = graph
  ) |>
  ggplot(aes(x = colours, y = max_edges, colour = method)) +
  geom_point() +
  facet_wrap(vars(graph), scales = "free", ncol = 3) +
  scale_colour_aaas() +
  scale_y_continuous(label = label_comma()) +
  coord_cartesian(xlim = c(0, NA)) +
  theme_minimal(base_size = 9) +
  labs(
    x = "Colours used",
    y = "Stored edges",
    colour = NULL,
  ) +
  guides(colour = guide_legend(nrow = 2)) +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.background = element_rect(color = "black", linewidth = 0.3)
  )

ggsave(
  "dissertation/plots/pareto_fronts_both_passes.pdf",
  plot = last_plot(),
  width = 7.16,
  height = 4.5,
)

pareto_front(palette_single_pass_trials) |>
  filter(
    colours <=
      quantile(colours, 0.75, na.rm = TRUE) + 1.5 * IQR(colours, na.rm = TRUE),
    # colours >=
    #   quantile(colours, 0.25, na.rm = TRUE) - 1.5 * IQR(colours, na.rm = TRUE),
    .by = graph
  ) |>
  ggplot(aes(x = params_max_colours, y = colours)) +
  geom_point() +
  facet_wrap(~graph, scales = "free") +
  coord_cartesian(xlim = c(0, NA), ylim = c(0, NA)) +
  theme_minimal(base_size = 9) +
  labs(
    x = "max_colours",
    y = "Number of colours",
  )

ggsave(
  "dissertation/plots/max_colours_relationship.pdf",
  plot = last_plot(),
  width = 7.16,
  height = 4.5,
)

plot_benchmark_var <- function(data, x_var, y_var) {
  scale_colour <- if (length(unique(data$method)) <= 2) {
    methods <- unique(data$method)
    method_name <- methods[methods != "Greedy algorithm"]
    colour_values <- c("Greedy algorithm" = "red")
    colour_values[as.character(method_name)] = "black"
    scale_color_manual(values = colour_values)
  } else {
    scale_color_aaas()
  }

  data |>
    ggplot(aes(x = {{ x_var }}, y = {{ y_var }}, colour = method)) +
    geom_point() +
    scale_colour +
    coord_cartesian(ylim = c(0, NA))
}

plot_benchmark_data <- function(data, x_var, graph) {
  data <- bind_rows(
    data,
    greedy_single_pass |> mutate(method = "Greedy algorithm", {{ x_var }} := 0)
  ) |>
    filter(graph == .env$graph) |>
    mutate(method = fct_inorder(factor(method)))

  (plot_benchmark_var(data, {{ x_var }}, colours) +
    ylab("Colours") +
    plot_benchmark_var(data, {{ x_var }}, avg_time) +
    scale_y_continuous(name = "Time", label = label_timespan())) /
    (plot_benchmark_var(data, {{ x_var }}, peak_memory) +
      scale_y_continuous(name = "Peak memory", label = label_bytes()) +
      plot_benchmark_var(data, {{ x_var }}, total_memory) +
      scale_y_continuous(name = "Total memory", label = label_bytes())) +
    plot_layout(axes = "collect_x", guides = "collect") &
    labs(colour = NULL) &
    theme_minimal(base_size = 9) &
    theme(
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.background = element_rect(color = "black", linewidth = 0.3)
    )
}

plot_partition_benchmarks <- function(graph, two_pass = FALSE) {
  data <- if (two_pass) partition_two_pass else partition_single_pass

  plot_benchmark_data(
    data |> mutate(method = "Partitioning algorithm"),
    m,
    graph
  )
}

plot_palette_benchmarks <- function(
  graph,
  two_pass = FALSE,
  compressed = FALSE
) {
  data <- if (two_pass && compressed) {
    palette_two_pass_compressed_benchmarks
  } else if (two_pass) {
    palette_two_pass_benchmarks
  } else if (compressed) {
    palette_single_pass_compressed_benchmarks
  } else {
    palette_single_pass_benchmarks
  }

  data |>
    filter(graph == .env$graph) |>
    arrange(colours) |>
    mutate(i = row_number(), method = "APS Algorithm") |>
    plot_benchmark_data(i, graph)
}

plot_palette_compressed_comparison <- function(
  graph,
  two_pass = FALSE
) {
  data <- if (two_pass) {
    bind_rows(
      palette_two_pass_benchmarks |> mutate(method = "APS algorithm"),
      palette_two_pass_compressed_benchmarks |>
        mutate(method = "APS algorithm (with compressed palettes)")
    )
  } else {
    bind_rows(
      palette_single_pass_benchmarks |> mutate(method = "APS algorithm"),
      palette_single_pass_compressed_benchmarks |>
        mutate(method = "APS algorithm (with compressed palettes)")
    )
  }

  data |>
    filter(graph == .env$graph) |>
    group_by(method) |>
    arrange(colours) |>
    mutate(i = row_number()) |>
    ungroup() |>
    plot_benchmark_data(i, graph)
}

plot_palette_pass_comparison <- function(graph) {
  data <-
    bind_rows(
      palette_single_pass_compressed_benchmarks |>
        mutate(method = "APS algorithm (single pass)"),
      palette_two_pass_compressed_benchmarks |>
        mutate(method = "APS algorithm (two pass)")
    )

  data |>
    filter(graph == .env$graph) |>
    group_by(method) |>
    arrange(colours, .by_group = TRUE) |>
    mutate(i = row_number()) |>
    ungroup() |>
    plot_benchmark_data(i, graph)
}

plot_partition_comparison <- function(graph) {
  data <- bind_rows(
    partition_single_pass |>
      mutate(method = "Partitioning algorithm (single pass)"),
    partition_two_pass |> mutate(method = "Partitioning algorithm (two pass)")
  )

  plot_benchmark_data(data, m, graph)
}

plot_partition_comparison("epinions")
plot_palette_compressed_comparison("fpsol")
plot_palette_pass_comparison("epinions")

map(set_names(folders[folders != "migration"]), \(graph) {
  list(
    partition = plot_partition_benchmarks(graph),
    partition_two_pass = plot_partition_benchmarks(graph, two_pass = TRUE),
    partition_two_pass_comparison = plot_partition_comparison(graph),
    palette = plot_palette_benchmarks(graph),
    palette_compressed = plot_palette_benchmarks(graph, compressed = TRUE),
    palette_two_pass = plot_palette_benchmarks(graph, two_pass = TRUE),
    palette_two_pass_compressed = plot_palette_benchmarks(
      graph,
      compressed = TRUE,
      two_pass = TRUE
    ),
    palette_compressed_comparison = plot_palette_compressed_comparison(graph),
    palette_pass_comparison = plot_palette_pass_comparison(graph)
  )
}) |>
  iwalk(\(graphs, graph_name) {
    iwalk(graphs, \(graph, name) {
      ggsave(
        glue::glue("dissertation/plots/{graph_name}_{name}.pdf"),
        plot = graph,
        width = 7.16,
        height = 4.5,
        device = cairo_pdf
      )
    })
  })

plot_partition_benchmarks("gnutella", two_pass = TRUE)
plot_partition_benchmarks("epinions")
plot_palette_benchmarks("epinions", compressed = TRUE, two_pass = TRUE)
plot_palette_benchmarks("road-pa", compressed = FALSE)
greedy_single_pass

greedy_data <- bind_rows(
  greedy_single_pass |>
    mutate(n_passes = 1),
  greedy_two_pass |>
    mutate(n_passes = 2)
)

greedy_data |>
  ggplot(aes(x = graph, y = peak_memory, fill = factor(n_passes))) +
  geom_col(position = "dodge") +
  scale_y_continuous(label = label_bytes()) +
  scale_fill_aaas() +
  theme_minimal(base_size = 9) +
  labs(
    x = "Graph",
    y = "Memory used",
    fill = "Number of passes",
  ) +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.background = element_rect(color = "black", linewidth = 0.3)
  ) +
  greedy_data |>
    ggplot(aes(x = graph, y = avg_time, fill = factor(n_passes))) +
  geom_col(position = "dodge") +
  scale_y_continuous(label = label_timespan()) +
  scale_fill_aaas() +
  theme_minimal(base_size = 9) +
  labs(
    x = "Graph",
    y = "Time taken",
    fill = "Number of passes",
  ) +
  plot_layout(axes = "collect_x", guides = "collect") &
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.background = element_rect(color = "black", linewidth = 0.3)
  )

ggsave(
  "dissertation/plots/greedy_passes.pdf",
  width = 7.16,
  height = 4.5,
)

pareto_front(palette_single_pass_trials) |>
  filter(colours <= 200) |>
  left_join(graph_data) |>
  filter(max_edges < edges) |>
  rowwise() |>
  mutate(a = (c / nodes) * sum(1:nodes^(-params_x))) |>
  ungroup() |>
  ggplot(aes(x = colours, y = max_edges, colour = a)) +
  geom_point()

pareto_front(palette_single_pass_trials) |>
  filter(colours > min(colours, na.rm = TRUE), colours < 200) |>
  left_join(graph_data) |>
  rowwise() |>
  mutate(a = (c / nodes) * sum(1:nodes^(-params_x))) |>
  ungroup() |>
  ggplot(aes(x = colours, y = a, colour = params_max_colours)) +
  geom_point()

pareto_front(palette_single_pass_trials) |>
  left_join(graph_data) |>
  rowwise() |>
  mutate(
    max_edges = pmax(avg_cg_edges, avg_sp_edges),
    colours = avg_k,
    a = (c / nodes) * sum(1:nodes^(-params_x))
  ) |>
  ungroup() |>
  filter(max_edges < edges, colours < 500) |>
  ggplot(aes(x = a, y = params_max_colours)) +
  geom_point(aes(colour = colours)) +
  geom_smooth()

x <- pareto_front(palette_single_pass_trials) |>
  left_join(graph_data) |>
  rowwise() |>
  mutate(
    max_edges = pmax(avg_cg_edges, avg_sp_edges),
    colours = avg_k,
    a = (c / nodes) * sum(1:nodes^(-params_x))
  ) |>
  ungroup() |>
  filter(max_edges < edges, colours < 500)

skipped_proportion <- function(c, x, max_colours, nodes) {
  ell <- c * ((1:nodes)^-x)

  sum(map_dbl(1:nodes, \(i) {
    sum(1 - dhyper(0, ell[i], max_colours - ell[i], ell[-i]))
  }))
}

nodes <- graph_data$nodes
dhyper(0, 1:nodes, max_colours - 1:nodes, 1:nodes)

row <- pareto_front(palette_single_pass_trials) |>
  slice_sample()
skipped_proportion(
  row$c,
  row$params_x,
  row$params_max_colours,
  graph_data$nodes
)

palette_single_pass_trials |>
  left_join(graph_data) |>
  mutate(
    max_edges = pmax(avg_cg_edges, avg_sp_edges),
    colours = avg_k,
    edges_group = cut(max_edges, 10)
  ) |>
  rowwise() |>
  mutate(a = (c / nodes) * sum(1:nodes^(-params_x))) |>
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
  filter(graph == "migration") |>
  left_join(
    palette_two_pass_trials,
    by = join_by(max_colours == params_max_colours, x == params_x, c)
  ) |>
  ggplot(aes(x = colours, y = peak_memory, colour = avg_cg_edges)) +
  geom_point() +
  scale_y_continuous(labels = label_comma()) +
  coord_cartesian(ylim = c(0, NA))

palette_single_pass_compressed_benchmarks |>
  slice_sample()

cat

partition_two_pass |>
  pivot_longer(c(cg_edges, sp_edges), names_to = "pass", values_to = "edges") |>
  filter(graph != "migration") |>
  ggplot(aes(x = m, y = edges, colour = pass)) +
  geom_point() +
  facet_wrap(vars(graph), scales = "free", ncol = 3) +
  scale_colour_aaas(labels = c("First pass", "Second pass")) +
  scale_y_continuous(label = label_comma()) +
  coord_cartesian(xlim = c(0, NA)) +
  theme_minimal(base_size = 9) +
  labs(
    x = "m",
    y = "Stored edges",
    colour = NULL,
  ) +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.background = element_rect(color = "black", linewidth = 0.3)
  )

ggsave(
  "dissertation/plots/partition_two_pass_edges.pdf",
  width = 7.16,
  height = 4.5,
)

avg_palette_size <- function(c, x, max_colours, n) {
  pmap_dbl(list(c, x, max_colours), \(c, x, max_colours) {
    mean(pmax(pmin(c * (1:n^(-x)), max_colours), 1), na.rm = TRUE)
  })
}

bind_rows(
  pareto_front(palette_single_pass_trials) |>
    left_join(graph_data) |>
    filter(max_edges < edges) |>
    mutate(
      method = "APS algorithm",
      colours = avg_k,
    ) |>
    mutate(
      avg_palette_size = avg_palette_size(
        c,
        params_x,
        params_max_colours,
        nodes[1]
      ),
      .by = graph
    ),
  partition_single_pass |>
    left_join(graph_data) |>
    mutate(
      method = "Partition algorithm",
      max_edges = pmax(cg_edges, sp_edges),
      avg_palette_size = colours / m,
    ),
) |>
  filter(graph != "migration") |>
  ggplot(aes(x = avg_palette_size, y = max_edges, colour = method)) +
  geom_point() +
  facet_wrap(vars(graph), scales = "free", ncol = 3) +
  scale_colour_aaas() +
  scale_y_continuous(label = label_comma()) +
  coord_cartesian(xlim = c(0, NA)) +
  theme_minimal(base_size = 9) +
  labs(
    x = "Average palette size",
    y = "Stored edges",
    colour = NULL,
  ) +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.background = element_rect(color = "black", linewidth = 0.3)
  )

ggsave(
  "dissertation/plots/average_palette_sizes.pdf",
  width = 7.16,
  height = 4.5,
)
