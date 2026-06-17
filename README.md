# Risk-V: 5-Stage Pipelined RISC-V Processor

A structurally verified, cycle-accurate 5-stage pipelined RISC-V (RV32I) processor core implemented entirely from fundamental digital logic primitives in Logisim-evolution.

This repository contains the complete modular datapath layout, hazard detection networks, dynamic forwarding bypass matrices, automated verification test benches, and a comprehensive documentation suite built via MkDocs.

---

## Core Architectural Features

- **Classic 5-Stage Pipeline**: Decoupled execution model divided into **Instruction Fetch (IF)**, **Instruction Decode (ID)**, **Execution (EX)**, **Memory Access (MEM)**, and **Write Back (WB)** structural zones.
- **Structural Hazard Mitigation**: A centralized, combinational **Hazard Controller** that dynamically monitors data dependencies to manage **1-cycle pipeline stalls (interlocks)** for load-use conditions and asserts synchronous **flushes (bubbles)** for branch mispredictions.
- **Dynamic Operand Forwarding**: An independent **Forwarding Unit** that continuously evaluates downstream write commitments (`EX/MEM` and `MEM/WB`) against active execution sources (`rs1` and `rs2`) to provide **zero-latency data bypassing** directly into the ALU inputs.
- **Boundary Register Checkpoints**: Fully isolated stage boundaries (`IF_ID`, `ID_EX`, `EX_MEM`, `MEM_WB`) engineered using custom input-side intercept multiplexing and structured label tunnels to prevent signal race hazards.

---

## Repository Structure

```text
├── logisim/
│   ├── design/                     # Digital design practice and foundational components
│   ├── RiskVCPU.circ               # Integrated top-level 5-stage core datapath
│   ├── RiskVControl.circ           # Central main controller, branch, and immediate matrices
│   ├── RiskVMemory.circ            # Structural 32-word Register File & Data Memory blocks
│   └── RiskVPipelineRegs.circ      # Component library for isolation boundary registers
├── docs/                           # MkDocs comprehensive architectural documentation source
├── tests/                          # Hex machine-code execution validation test suites
├── scripts/                        # Automated testing infrastructure and simulation runners
├── Makefile                        # Automation shortcuts for documentation, builds, and tests
├── mkdocs.yaml                     # MkDocs configuration and sidebar navigation layout
├── requirements.txt                # Python environment specifications for testing
└── component_template.md           # Structural standard template for modular design
```

---

## Quick Start & Environment Setup

### 1. Prerequisites

Ensure you have the following packages installed on your local environment (optimized for Debian/Ubuntu systems):

```bash
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv openjdk-17-jre make -y
```

### 2. Python Virtual Environment Setup

Initialize and activate a localized virtual environment to install the dependencies required by the automated verification test runners:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Automation Shortcuts (`Makefile`)

The project includes a streamlined `Makefile` to handle common management commands across testing, simulation, and documentation hosting.

### Testing and Verification

Run the integrated Python test runner suite to validate instructions against individual test cases:

```bash
make test
```

_Executes all `.hex` execution payloads found in the `tests/` directory against the top-level Logisim circuit using CLI simulation matrices._

### Documentation Suite

To compile and serve the comprehensive structural documentation project locally:

```bash
make docs-serve
```

_Spins up a local server at `http://127.0.0.1:8000/` using the Material theme, featuring interactive component definitions and pipeline traces._

To build a production-ready static site inside the `site/` folder:

```bash
make docs-build
```

---

## Automated Test Harness Architecture

Verification uses a automated Python-to-Logisim CLI test harness. Each test block inside the `tests/` directory contains:

1. A raw RISC-V assembly source file (`.s`) compiling down to a standard Logisim-compatible hex text block (`.hex`).
2. A customized validation harness based on `TestHarnessTemplate.circ` that injects the `.hex` stream into memory.
3. A python verification script that steps the simulation clock line-by-line, monitoring the terminal Register File states (`BusW`) and verifying execution correctness against architectural baseline models.

---

## Design Principles

This hardware processor adheres to a strict technical philosophy of **Simple > Complex** and **Explicit > Implicit**:

- No multi-cycle hidden abstractions; all pipeline behaviors are visually traced out via physical bus-planes in the schematic.
- Strictly edge-triggered sequential logic components driven by a centralized, non-skewed global clock lines (`SysClk`).
- Zero undocumented logic blocks. Every component layout follows the standardized criteria specified inside `component_template.md`.

```

```
