import csv
import subprocess
from argparse import ArgumentParser
from pathlib import Path
from typing import Iterable

import numpy as np
import optuna
import pandas as pd
from optuna.samplers import TPESampler
from optuna.trial import FrozenTrial
from tqdm import tqdm


def parse(x: str) -> Iterable[float]:
    return (float(part) for part in x.split(","))


def count_nodes_edges(path: Path) -> tuple[int, int]:
    edges = 0
    nodes = 0
    with open(path) as file:
        filtered = (line for line in file if not line.startswith("#"))
        reader = csv.reader(filtered, delimiter="\t")
        for row in reader:
            if row[0] != row[1]:
                edges += 1
                nodes = max(nodes, int(row[0]) + 1, int(row[1]) + 1)

    return nodes, edges


def benchmark(file: Path, args: list[str], memory: bool, trials: int = 10):
    process = subprocess.run(
        [
            "./build/benchmark-memory/graph-colouring" if memory else "./build/release/graph-colouring",
            file,
            "benchmark-memory" if memory else "benchmark",
            "--trials",
            str(trials),
        ]
        + args,
        stdout=subprocess.PIPE,
        text=True,
    )

    return parse(process.stdout)


def objective(trial: optuna.Trial, file: Path, two_pass: bool, nodes: int, edges: int):
    max_colours = trial.suggest_int("max_colours", 1, 500)
    a = trial.suggest_float("A", 0, 50)
    x = trial.suggest_float("x", 0, 1)

    c = (a * nodes) / np.sum(np.arange(1, nodes + 1) ** (-x))

    process = subprocess.run(
        [
            "./build/release/graph-colouring",
            file,
            "experiment",
            "--algorithm",
            "aps",
            "--two-pass" if two_pass else "",
            "--max-colours",
            str(max_colours),
            "--c",
            str(c),
            "--x",
            str(x),
        ],
        stdout=subprocess.PIPE,
        text=True,
    )

    (
        min_k,
        max_k,
        avg_k,
        min_cg_edges,
        max_cg_edges,
        avg_cg_edges,
        min_sp_edges,
        max_sp_edges,
        avg_sp_edges,
    ) = parse(process.stdout)

    trial.set_user_attr(
        "data",
        {
            "min_k": min_k,
            "max_k": max_k,
            "avg_k": avg_k,
            "min_cg_edges": min_cg_edges,
            "max_cg_edges": max_cg_edges,
            "avg_cg_edges": avg_cg_edges,
            "min_sp_edges": min_sp_edges,
            "max_sp_edges": max_sp_edges,
            "avg_sp_edges": avg_sp_edges,
            "c": c,
        },
    )

    return avg_k, max(avg_cg_edges, avg_sp_edges)

def get_graph_data(input: Path, out_dir: Path):
    path = out_dir / "graph_data.csv"

    if not path.exists():
        nodes, edges = count_nodes_edges(input)

        with open(path, "w") as file:
            file.writelines(
                [
                    "nodes,edges\n",
                    f"{nodes},{edges}",
                ]
            )


def run_greedy(input: Path, out_dir: Path, two_pass: bool):
    file = out_dir / ("greedy_two_pass.csv" if two_pass else "greedy_single_pass.csv")

    if file.exists():
        return

    process = subprocess.run(
        [
            "./build/release/graph-colouring",
            input,
            "experiment",
            "--algorithm",
            "greedy",
            "--two-pass" if two_pass else "",
        ],
        stdout=subprocess.PIPE,
        text=True,
    )

    colours = float(process.stdout)

    min_time, max_time, avg_time = benchmark(
        input, ["--algorithm", "greedy"], memory=False
    )
    peak_memory, total_memory = benchmark(input, ["--algorithm", "greedy"], memory=True)

    with open(
        out_dir / ("greedy_two_pass.csv" if two_pass else "greedy_single_pass.csv"), "w"
    ) as file:
        file.writelines(
            [
                "colours,min_time,max_time,avg_time,peak_memory,total_memory\n",
                f"{colours},{min_time},{max_time},{avg_time},{peak_memory},{total_memory}\n",
            ]
        )


def run_partition_experiment(input: Path, m: int, two_pass: bool):
    args = [
        "--algorithm",
        "partition",
        "--two-pass" if two_pass else "",
        "--m",
        str(m),
    ]

    process = subprocess.run(
        [
            "./build/release/graph-colouring",
            str(input),
            "experiment",
        ]
        + args,
        stdout=subprocess.PIPE,
        text=True,
    )

    colours, cg_edges, sp_edges = parse(process.stdout)
    min_time, max_time, avg_time = benchmark(input, args, memory=False)
    peak_memory, total_memory = benchmark(input, args, memory=True)

    return (
        m,
        colours,
        cg_edges,
        sp_edges,
        min_time,
        max_time,
        avg_time,
        peak_memory,
        total_memory,
    )


def run_partition(input: Path, out_dir: Path):
    columns = [
        "m",
        "colours",
        "cg_edges",
        "sp_edges",
        "min_time",
        "max_time",
        "avg_time",
        "peak_memory",
        "total_memory",
    ]

    sp_file = out_dir / "partition_single_pass.csv"
    if not sp_file.exists():
        df = pd.DataFrame(
            (
                list(run_partition_experiment(input, m, False))
                for m in tqdm(range(2, 501))
            ),
            columns=columns,
        )
        df.to_csv(sp_file, index=False)

    tp_file = out_dir / "partition_two_pass.csv"
    if not tp_file.exists():
        df = pd.DataFrame(
            (run_partition_experiment(input, m, True) for m in tqdm(range(2, 501))),
            columns=columns,
        )
        df.to_csv(tp_file, index=False)


def benchmark_aps(
    input: Path, trial: FrozenTrial, two_pass: bool, compress_palettes: bool
):
    max_colours = trial.params["max_colours"]
    x = trial.params["x"]
    data = trial.user_attrs["data"]
    c = data["c"]
    colours = trial.values[0]

    args = [
        "--algorithm",
        "aps",
        "--two-pass" if two_pass else "",
        "--max-colours",
        str(max_colours),
        "--c",
        str(c),
        "--x",
        str(x),
        "--compress-palettes" if compress_palettes else "",
    ]

    min_time, max_time, avg_time = benchmark(input, args, memory=False)
    peak_memory, total_memory = benchmark(input, args, memory=True)

    return max_colours, x, c, colours, min_time, max_time, avg_time, peak_memory, total_memory


def run_optuna(input: Path, out_dir: Path, two_pass: bool):
    storage = "sqlite:///optuna.db"

    nodes, edges = count_nodes_edges(input)

    study = optuna.create_study(
        study_name=f"APS Two Pass ({input.name})"
        if two_pass
        else f"APS ({input.name})",
        directions=["minimize", "minimize"],
        sampler=TPESampler(multivariate=True),
        storage=storage,
        load_if_exists=True,
    )

    study.set_metric_names(["Average colours", "Average edges"])

    if len(study.trials) < 2500:
        study.optimize(
            lambda trial: objective(
                trial, input, two_pass=two_pass, nodes=nodes, edges=edges
            ),
            n_trials=2500 - study.trials,
            n_jobs=-1,
        )

    df: pd.DataFrame = study.trials_dataframe()
    df = df.drop(columns=("user_attrs_data")).join(
        pd.json_normalize(df["user_attrs_data"])
    )
    df.to_csv(
        out_dir
        / (
            "palette_two_pass_trials.csv"
            if two_pass
            else "palette_single_pass_trials.csv"
        ),
        index=False,
    )

    columns = [
        "max_colours",
        "x",
        "c",
        "colours",
        "min_time",
        "max_time",
        "avg_time",
        "peak_memory",
        "total_memory",
    ]

    file = out_dir / (
        "palette_two_pass_benchmarks.csv"
        if two_pass
        else "palette_single_pass_benchmarks.csv"
    )

    if not file.exists():
        df = pd.DataFrame(
            (
                benchmark_aps(input, trial, two_pass, compress_palettes=False)
                for trial in tqdm(study.best_trials) if trial.values[1] < edges
            ),
            columns=columns,
        )

        df.to_csv(file, index=False)

    file = out_dir / (
        "palette_two_pass_compressed_benchmarks.csv"
        if two_pass
        else "palette_single_pass_compressed_benchmarks.csv"
    )

    if not file.exists():
        df = pd.DataFrame(
            (
                benchmark_aps(input, trial, two_pass, compress_palettes=True)
                for trial in tqdm(study.best_trials) if trial.values[1] < edges
            ),
            columns=columns,
        )

        df.to_csv(file, index=False)


def run_experiments(input: Path, out_dir: Path):
    get_graph_data(input, out_dir)

    run_greedy(input, out_dir, two_pass=False)
    run_greedy(input, out_dir, two_pass=True)

    run_partition(input, out_dir)

    run_optuna(input, out_dir, two_pass=False)
    run_optuna(input, out_dir, two_pass=True)


def main():
    parser = ArgumentParser("sample_data")
    parser.add_argument("input")
    parser.add_argument("output")

    args = parser.parse_args()

    input = Path(args.input).resolve()
    out_dir = Path(args.output).resolve()

    run_experiments(input, out_dir)


if __name__ == "__main__":
    main()
