from pathlib import Path
import sys


def main():
    input = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()

    with open(input) as input_file, open(output, "w") as output_file:
        output_file.writelines(line.replace(" ", "\t") for line in input_file.readlines())


if __name__ == "__main__":
    main()
