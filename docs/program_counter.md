# 32-Bit Program Counter (PC) Module

## Functional Overview

The **Program Counter (`ProgramCounter`)** is the central state element that drives the execution stage of the processor. It serves as a 32-bit instruction pointer, holding the memory address of the instruction currently being executed by the CPU.

Every clock cycle, the module prepares the next address by executing one of two path operations:

1. **Sequential Execution ($PC + 4$):** Automatically incrementing the pointer by 4 bytes to load the next adjacent instruction in memory.
2. **Control Flow Alteration (Branch/Jump):** Multiplexing to a calculated target address when a conditional branch is verified or an unconditional jump is decoded.

---

## Interface Specifications

### Input Signals

| Pin Name      | Bit Width | Direction | Functional Description                                                 |
| :------------ | :-------: | :-------: | :--------------------------------------------------------------------- |
| `Target_Addr` |    32     |   Input   | Calculated branch or jump destination address from the execution stage |
| `TakeBranch`  |     1     |   Input   | Active-high routing control line from the Branch Selector              |
| `Clk`         |     1     |   Input   | System master clock line (Updates on rising-edge trigger)              |
| `Reset`       |     1     |   Input   | Active-high asynchronous clear line to force the PC to `0x00000000`    |

### Output Signals

| Pin Name | Bit Width | Direction | Functional Description                                                      |
| :------- | :-------: | :-------: | :-------------------------------------------------------------------------- |
| `PC_Out` |    32     |  Output   | Current instruction pointer address exported directly to Instruction Memory |

---

## Internal Architectural Design

The component utilizes a feedback loop layout containing a 32-bit standard state register, a hardwired adder, and an input-steering multiplexer:

- **State Storage:** A standard 32-bit register containing synchronous data input (`D`) and real-time output (`Q`).
- **Incrementer Block:** A 32-bit adder with port `X` tied to the register output and port `Y` tied to a 32-bit constant of value `4`.
- **Routing Matrix:** A 32-bit 2-to-1 Multiplexer positioned directly ahead of the register's `D` input channel:
  - **Channel 0 (`TakeBranch = 0`):** Feeds the sequential $PC + 4$ value.
  - **Channel 1 (`TakeBranch = 1`):** Feeds the incoming `Target_Addr` value.

---

## Core Timing & Execution Phases

Because the internal register is an edge-triggered element, data evaluation is split cleanly across clock phases:

1. **Setup Phase (Clock Level Low/High Steady):** \* The current address remains fixed on `PC_Out`.
   - The incrementer and execution stages calculate both potential future addresses.
   - The `TakeBranch` control signal stabilizes, forcing the chosen next address to sit waiting directly at the input register door (`D`).
2. **Commit Phase (Clock Rising Edge):**
   - The register captures the value waiting at its input door.
   - `PC_Out` instantly transitions to the new instruction address, and the cycle repeats.
