import argparse
import os
import signal
import subprocess
import sys
from pathlib import Path
import tempfile
from typing import IO

ROOT_PATH = Path.cwd()


class TestRunner:
    def __init__(self) -> None:
        pass


class TestCase:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.circ_path = Path.joinpath(ROOT_PATH, "logisim", "RiskV.circ")
        pass

    def __repr__(self) -> str:
        return f"TestCase: {self}"

    def __str__(self) -> str:
        return Path.__str__(self.path).split("/")[-1]

    def results(self) -> list[str]:
        with open(Path.joinpath(self.path, "results.out"), "r") as fd:
            lines = fd.readlines()
        return [line.strip() for line in lines]

    def exec_test(self) -> list[str]:
        output = tempfile.TemporaryFile(mode="r+")
        try:
            stdinf = open("/dev/null")
        except Exception as e:
            print(
                "Could not open nul or /dev/null. Program will most likely error now."
            )
        # 1. Define the command arguments using the package name you installed
        cmd = [
            "logisim",
            "logisim/RiskV.circ",
            # "IMem=tests/test_align.hex",
            # "-tick",
            "-t",
            "table",
        ]

        try:
            proc = subprocess.Popen(
                cmd,
                cwd=ROOT_PATH,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,  # Automatically decodes bytes to strings (\n handled natively)
                bufsize=1,  # Line-buffered output
            )
            print(f"Process started with PID: {proc.pid}")
            if not proc.stdout:
                raise Exception("Unable to get stdout")

            return self.parse_output([line.strip() for line in proc.stdout])

        except Exception as e:
            print("Unable to start proc", e)
        finally:
            os.kill(proc.pid, signal.SIGTERM)

        return []

    def parse_output(self, output: list[str]) -> list[str]:
        parsed = []
        for line in output:
            binary = "".join(line.split(" "))
            number = int(binary, 2)
            hex = f"{number:08x}"
            parsed.append(hex)

        return parsed

    def run(self) -> list[str]:
        out = self.exec_test()
        print("Execution output:")
        print(out)
        return self.results()


def list_tests() -> dict[str, TestCase]:
    test_path = Path.joinpath(ROOT_PATH, "tests")

    test_filenames = os.listdir(test_path)
    tests: dict[str, TestCase] = {}

    for filename in test_filenames:
        file_path = Path.joinpath(test_path, filename)
        if Path.is_dir(file_path):
            test = TestCase(file_path)
            tests[filename] = test

    return tests


def main(args):
    test_arg = args.test[0]
    tests = list_tests()
    test = tests.get(test_arg)

    if not test:
        print("Invalid test case", test_arg)
        return

    print("Running test ... ", test)
    results = test.run()
    print("Test results: ", results)

    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Logisim tests")
    tests = list_tests()
    parser.add_argument(
        "test",
        choices=[f"{test}" for test in tests],
        help="Select test to run",
        nargs=1,
    )
    args = parser.parse_args()
    main(args)
