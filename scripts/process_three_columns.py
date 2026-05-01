from pathlib import Path
import sys


def process_line(line: str) -> str:
    f, to = (int(x) for x in line.split()[:2])
    return f"{f}\t{to}\n"


def main():
    input = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()

    with open(input) as input_file, open(output, "w") as output_file:
        output_file.writelines(process_line(line) for line in input_file.readlines())


if __name__ == "__main__":
    main()
