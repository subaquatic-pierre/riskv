# Logisim Test Harness & Verification Documentation

This document outlines the architecture, setup procedure, and execution guidelines for writing and running assembly-level regression tests on the RiskV processor inside Logisim.

---

## 1. Test Directory Structure

Every test case must follow a strict naming convention and structure. The automated python test runner expects each test to live in its own subdirectory inside `tests/` and contain a `.s` source file, a compiled `.hex` memory image, and the `.circ` Logisim test wrapper.

```text
tests/
├── TestHarnessTemplate.circ         # Master template for creating new tests
├── test_case_name/                  # Example test directory
│   ├── test_case_name.s             # RISC-V assembly source code
│   ├── test_case_name.hex           # Compiled Logisim-compatible ROM hex file
│   └── test_case_name.circ          # Executable Logisim circuit for this test
```

---

## 2. Compiling Assembly to Logisim Hex

Logisim’s ROM components cannot read raw binary machine code directly; they require a specific text-based hexadecimal format prefixed with a structural header.

To compile your assembly file (`.s`) into a Logisim-compatible hex image (`.hex`), use the local compilation utility:

```bash
./compile-logisim tests/test_case_name/test_case_name.s
```

This utility handles the translation and automatically formats the output file header so Logisim's memory elements can parse it securely.

### Manually Generating Custom Hex Sequences

If you are writing a minimal micro-test or bypass sequence without using the toolchain compiler, you can write raw hex instructions directly into a text file. The file **must** start with the explicit Logisim v2.0 raw memory declaration descriptor:

```text
v2.0 raw
05500f13
0de79463
0002a803
```

---

## 3. Creating the Test Circuit (.circ)

Currently, the automation infrastructure is configured around the **CPU Test Harness**. This harness wraps the core CPU tracking structures and hooks them directly into the terminal verification pins.

### Step-by-Step Harness Configuration

1. Copy `tests/TestHarnessTemplate.circ` and rename it to match your target test folder (e.g., `tests/test_case_name/test_case_name.circ`).
2. Open your newly created circuit file in Logisim.
3. Right-click the **ROM / Instruction Memory (IMem)** component, select **Load Image...**, and choose your generated `test_case_name.hex` file.
4. **Configure the Pipeline Flush Boundary:** \* Locate the **Constant component** driving the PC termination comparator in the harness architecture.
   - Identify the byte address of the absolute last instruction in your compiled program.
   - **Add 8** to that target address (this extra 2-cycle buffer allows instructions to clear the `EX`, `MEM`, and `WB` pipeline phases cleanly).
   - Update the Constant component's value with this final calculated flush address.

---

## 4. Test Pass/Fail Semantics

The test runner detects the execution outcome by evaluating the final architecture register configuration state.

- Your assembly program **must** explicitly write its evaluation status into register **`x31`** before completion.
- **`1`** indicates a **PASS** state.
- **`-1`** (or `0xFFFFFFFF`) indicates a **FAIL** state.

### Structural Assembly Example (`test_example.s`)

```assembly
    # ... Core Processor Verification Logic ...
    lw    x16, 0(x5)
    lui   x30, 0xFF560
    addi  x30, x30, -171
    bne   x16, x30, bad_exit   # Jump to failure if states misaligned

good_exit:
    addi  x31, x0, 1           # Write PASS token (1) to x31
    beq   x0, x0, core_halt

bad_exit:
    addi  x31, x0, -1          # Write FAIL token (-1) to x31

core_halt:
    beq   x0, x0, core_halt    # Static loop trapped until harness asserts 'halt'
```

---

## 5. Running the Test Suite

The Python test runner interacts directly with Logisim's background CLI. It reads your `.circ` files, suppresses active graphics loops, and parses the output binary bus straight from your shell terminal.

### Execute a Specific Test Case

To verify a single distinct isolation component layout:

```bash
python test_runner.py test_align
```

### Execute the Complete Integration Suite

To run all discovered tests sequentially inside the `tests/` directory:

```bash
python test_runner.py all
```

### Expected Output Log Format

When a test executes successfully to its `halt` state boundary, the runner outputs the execution transitions directly to the terminal:

```text
--- Running Test: test_align ---
Execution Log Trace (Raw Integers): [0, 1]
Initial State State Value: 0
Final State Halt Value:    1
[test_align] PASS ✅
--------------------------------------------------
Suite Execution Finished: Passed 12/12 cases.
```
