# RISC-V 32-Bit Processor Core

UPDATE HERe

A 32-bit RISC-V processor implementation modeled after the UC Berkeley CS61C computer architecture curriculum. The execution engine is constructed using Logisim-Evolution to map custom hardware modules, control paths, and arithmetic execution units into a unified processing canvas.

---

## Architecture Blueprint

The microarchitecture uses a single-cycle datapath layout where every committed instruction processes entirely within one clock cycle.

- **Datapath Model:** Single-cycle execution loop.
- **Instruction Set Architecture:** RV32I Base Integer Instruction Set.
- **Current Support Matrix:** Includes all fundamental computational, control-flow, and word-level storage operations. Sub-word byte and half-word memory operations are bypass-routed for future expansion.

---

## Core Component Modules

The microarchitecture is split into specialized structural components located across functional circuit domains:

- **Program Counter (`ProgramCounter`):** Dedicated 32-bit execution pointer tracking synchronous sequence increments ($PC + 4$) and handling asynchronous clear lines and runtime branch/jump target interruptions.
- **Immediate Generator (`ImmGen`):** Combinational wire-splicing matrix that extracts, rearranges, and sign-extends immediate constants from I, S, B, U, and J instruction formats without generating explicit shift gate delay.
- **Unified Adder/Subtractor (`AdderSub32`):** Linear ripple-carry core using a conditional XOR inverter layer to combine addition, two's complement subtraction, and cascaded multi-word carry processing into one block.
- **Integrated Barrel Shifter (`UniShifter`):** 5-stage log-scaled right-shifting multiplexer cascade featuring complement-inversion logic to run left shifts natively through right-handed hardware lanes.
- **Word-Level Comparator (`WordLevelComparator`):** Flag-processing array that samples output buses and overflow bits directly from the subtraction channel to evaluate `EQ`, `LTU`, and `LTS` metrics without extra arithmetic structures.
- **Multi-Port Register File (`RegisterFile`):** Parallel storage cell matrix supporting two independent combinational read ports and one exclusive, decoder-gated write port simultaneously.

---

## Assembly Toolchain & ROM Target Creation

To execute tests on the hardware canvas, the environment includes compilation scripts to convert bare-metal RISC-V assembly source code into compatible hex images for Logisim ROM/RAM components.

### Compilation Toolchain Prerequisites

Running assembly files requires the RISC-V GNU Compiler Collection (`riscv-gnu-toolchain`) target configured for 32-bit bare-metal execution.

Install the necessary cross-compilers via your platform packages:

```bash
# Ubuntu/Debian Target Architecture Tools
sudo apt-get install gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf

# macOS Target Architecture Tools (via Homebrew)
brew tap riscv-software-src/riscv
brew install riscv-gnu-toolchain
```

### Automation Scripts

The toolchain automation framework provides direct compilation and verification routines:

- **`compile_logisim.sh`:** Automated shell script that compiles raw assembly strings (`.s`), processes object files, extracts text sections, and outputs standard Logisim-compatible hexadecimal vectors (`.hex`) ready for direct memory image streaming.

---

## Execution Verification Strategy

Hardware functionality is maintained using low-level boundary vectors located inside the verification suite. Test routines target explicit code execution paths:

- **Arithmetic & Logic:** Tests verifying standard integer calculation, signed register operations, shifts, and immediate boundaries.
- **Control Paths:** Validates branching parameters (`beq`, `bne`, etc.), jumps, trap boundaries, and upper-immediate alignment vectors (`lui`, `auipc`).
- **Memory Routing:** Confirms full-word data store and load configurations passing across the standard data bus layout.

---

## Roadmap & Core Expansion

Future engineering iterations target deeper performance scaling, structural decoupling, and production-grade validation environments:

- [ ] **Sub-Word Memory Integration:** Implement structural masking logic inside the memory access stage to introduce byte and half-word operations (`lb`, `lh`, `sb`, `sh`).
- [ ] **Pipelined Execution Core:** Transition from a single-cycle implementation to a high-frequency 5-stage pipeline architecture (Fetch, Decode, Execute, Memory, Writeback) complete with hazard resolution and forwarding networks.
- [ ] **HDL Migration:** Port validated Logisim schematics into fully descriptive digital logic frameworks using Digital or hardware description languages to evaluate synthesis targets.
