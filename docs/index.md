# Overview

---

## Welcome to Risk-V

Risk-V is a comprehensive reference platform dedicated to the structural verification, architectural design, and digital layout of a fully pipelined, 5-stage RISC-V (RV32I) processor implemented natively within Logisim-evolution.

This technical documentation outlines the exact specifications, interface standards, internal combinational/sequential logic blocks, and pipeline interactions that govern the execution datapath. Every module documented here has been built structurally using standard primitives to maintain clean architectural mapping and strict adherence to the RISC-V ISA spec.

---

## Architectural Highlights

The processor core is modeled around a classic 5-stage decoupled execution model designed to execute a subset of the standard RV32I base integer instruction set:

1. **Instruction Fetch (IF)**: Interfaces with Instruction Memory via a 32-bit Program Counter (PC) path with support for hardware stalls and dynamic branch/jump flushes.
2. **Instruction Decode (ID)**: Decompresses raw machine code, coordinates register index allocation via a dual-read structural Register File, extracts sign-extended immediates, and evaluates early branch indicators.
3. **Execution (EX)**: Utilizes a dedicated arithmetic logic unit (ALU) alongside localized operand forwarding networks to execute mathematical, logical, and shift operations at high speed.
4. **Memory Access (MEM)**: Manages clean data transport boundaries to Data Memory (DMem) supporting byte-, halfword-, and word-aligned reads and writes.
5. **Write Back (WB)**: Selects, routes, and commits terminal execution or memory results back into the Register File matrix to permanently update state contexts.

---

## Technical Features

- **Structural Hazard Mitigation**: Features a centralized Hazard Controller to handle data hazards (such as load-use interlocks) via structural pipeline stalls and control hazards via synchronous branch flushes.
- **Dynamic Forwarding Unit**: Minimizes pipeline stalls by dynamically bypassing ALU outputs and memory read fields back to the Execution stage operand networks.
- **Isolated Boundary Interfaces**: Utilizes discrete pipeline stage registers (`IF_ID`, `ID_EX`, `EX_MEM`, `MEM_WB`) mapped out with dedicated input-side multiplexing and label tunnel routing to avoid wire pollution and race hazards.

---

## Structural Documentation Strategy

This documentation follows an implementation-focused, code-and-circuit structural schema designed to expose exactly how logic functions inside the simulated processor:

- **Interface Specifications**: Direct pin-for-pin mapping tables detailing widths, directions, and behavioral triggers.
- **Core Output Logic**: Explicit rule-based definitions tracking exactly how logic flags and metrics derive output transitions.
- **Internal Structural Design**: Detailed explanations of combinational vs. sequential divisions, subcircuits deployed, and routing topologies.
- **Real Trace Mapping**: Minimal, concrete instruction trace examples mapping step-by-step transformations across specific data segments.

---

## Repository Path Index

The source code, simulation assets, and modular circuit templates are organized within the project according to the following layout:

```text
├── logisim/
│   ├── design/                     # Digital design practice and foundational theory components
│   ├── RiskVCPU.circ               # Integrated top-level 5-stage core
│   ├── RiskVControl.circ           # Central main controller matrices
│   ├── RiskVMemory.circ            # Structural Register File and Memory interfaces
│   ├── RiskVPipelineRegs.circ      # Component library for isolation registers
│   └── RiskVALU.circ               # Full Arithmetic Logic Unit macro block
```
