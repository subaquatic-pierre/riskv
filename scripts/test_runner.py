import argparse
import os
import subprocess
from pathlib import Path
import csv
import sys
from typing import Sequence

ROOT_PATH = Path.cwd()


class TestCase:
    def __init__(self, name: str, base_path: Path) -> None:
        self.name = name
        self.path = base_path
        # Dynamic circuit target based on folder schema: tests/test_CASE/test_CASE.circ
        self.circ_path = self.path / f"{self.name}.circ"

    def __repr__(self) -> str:
        return f"TestCase({self.name})"

    def __str__(self) -> str:
        return self.name

    def exec_test(self) -> list[list[int]]:
        """Runs Logisim CLI.
        Returns parsed integer list representing the Result bus trace milestones.
        """
        # Command syntax targeting the explicit test case circuit wrapper
        cmd = [
            "logisim",
            str(self.circ_path.relative_to(ROOT_PATH)),
            "-tty",
            "table",
        ]

        try:
            proc = subprocess.Popen(
                cmd,
                cwd=ROOT_PATH,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )

            if not proc.stdout:
                raise Exception("Unable to capture stdout stream")

            # Extract output lines
            raw_lines = [line.strip() for line in proc.stdout if line.strip()]
            proc.wait()  # Let process exit naturally upon hitting the 'halt' trigger

            return self.parse_output(raw_lines)

        except Exception as e:
            print(f"[{self.name}] Target execution failure: {e}")
            return []

    def parse_output(self, output: list[str]) -> list[list[int]]:
        """Parses the space-delimited raw binary output tokens into base-10 integers."""
        parsed_lines = []
        for line in output:
            parsed_values = []
            # Drop column delimiter spacing to form a clean binary chunk
            binary_str_vals = line.split("\t")
            for binary_str in binary_str_vals:
                try:
                    val = int(binary_str.replace(" ", ""), 2)
                    parsed_values.append(val)
                except ValueError:
                    continue
            parsed_lines.append(parsed_values)
        return parsed_lines

    def read_expected_output(self) -> list[list]:
        path = Path.joinpath(self.path, "results.csv")
        lines = []
        with open(path, "r") as f:
            reader = csv.DictReader(f)
            for line in reader:
                out_line = []
                for val in line.values():
                    try:
                        out_line.append(int(val))
                    except:
                        out_line.append(val)

                lines.append(out_line)

        return lines

    def run(self) -> bool:
        print(f"--- Running Test: {self.name} ---")
        out = self.exec_test()

        if not out:
            print(f"[{self.name}] FAIL: No valid execution metrics returned.")
            return False

        expected = self.read_expected_output()

        print(f"Execution Log Trace (Raw): {out}")
        print(f"Expected results (Raw): {expected}")

        valid = True

        for i_row, row in enumerate(expected):
            for i_col, val in enumerate(row):
                if val == "X":
                    continue

                try:
                    if out[i_row][i_col] != val:
                        valid = False
                        print(
                            f"[{self.name}] Expected value = {out[i_row]}, Got: {row})"
                        )
                except Exception as e:
                    valid = False
                    print(f"[{self.name}] Exception raised {e}")

        if valid:
            print(f"[{self.name}] PASS ✅")
        else:
            print(f"[{self.name}] FAIL ❌ (Expected output {expected}, Got: {out})")

        return valid


def list_tests() -> dict[str, TestCase]:
    test_path = ROOT_PATH / "tests"
    tests: dict[str, TestCase] = {}

    if not test_path.exists():
        print(f"Error: Base directory path '{test_path}' does not exist.")
        return tests

    for filename in os.listdir(test_path):
        file_path = test_path / filename
        # Ensure we only track actual subdirectories matching target execution boundaries
        if file_path.is_dir() and filename.startswith("test_"):
            tests[filename] = TestCase(filename, file_path)

    return tests


def main():
    tests = list_tests()

    parser = argparse.ArgumentParser(
        description="Automated Logisim Integration Test Suite Runner"
    )
    parser.add_argument(
        "test",
        choices=list(tests.keys()) + ["all"],
        help="Select a specific test run profile or execute 'all' configurations sequentially.",
        nargs="?",
        default="all",
    )

    args = parser.parse_args()

    if args.test == "all":
        print(f"Discovered {len(tests)} test instances. Launching batch operations...")
        passed = 0
        for name, test in tests.items():
            if test.run():
                passed += 1
            print("-" * 50)
        print(f"\nSuite Execution Finished: Passed {passed}/{len(tests)} cases.")
        if passed != len(tests):
            sys.exit(1)
    else:
        test = tests.get(args.test)
        if test:
            success = test.run()
            sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
