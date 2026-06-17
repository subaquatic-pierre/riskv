# 32-Bit Program Counter (PC) Module

## Functional Overview

The **Program Counter (`ProgramCounter`)** is the central state element driving the instruction fetch path. It holds the 32-bit memory address of the instruction currently being executed by the CPU.

Every clock cycle, the module updates the address pointer via one of two paths:

1. **Sequential Execution ($PC + 4$):** Increments the pointer by 4 bytes to load the next consecutive instruction.
2. **Control Flow Alteration (Branch/Jump):** Routes to a computed target address when a conditional branch is met or an unconditional jump is executed.

---

## Interface Specifications

### Input Signals

| Pin Name            | Bit Width | Direction | Functional Description                                                  |
| :------------------ | :-------: | :-------: | :---------------------------------------------------------------------- |
| `Target_Addr[31:0]` |    32     |   Input   | Calculated branch or jump destination address from the execution stage. |
| `TakeBranch`        |     1     |   Input   | Active-high routing control line from the Branch Controller.            |
| `Clk`               |     1     |   Input   | Master clock line (Updates on rising-edge trigger).                     |
| `Reset`             |     1     |   Input   | Active-high asynchronous reset line forcing the PC to `0x00000000`.     |

### Output Signals

| Pin Name       | Bit Width | Direction | Functional Description                                               |
| :------------- | :-------: | :-------: | :------------------------------------------------------------------- |
| `PC_Out[31:0]` |    32     |  Output   | Current instruction address exported directly to Instruction Memory. |

---

## Internal Architectural Design

The component utilizes a feedback loop consisting of a 32-bit state register, a hardwired adder, and an input-steering multiplexer:

- **State Storage:** A standard 32-bit register with asynchronous clear capability.
- **Incrementer Block:** A 32-bit dedicated adder with one port tied to the register output and the other tied to a constant value of `4`.
- **Routing Matrix:** A 32-bit 2-to-1 Multiplexer feeding the register's input (`D`) channel:
  - **Channel 0 (`TakeBranch = 0`):** Connects the sequential $PC + 4$ value.
  - **Channel 1 (`TakeBranch = 1`):** Connects the incoming `Target_Addr` value.

---

## Core Timing & Execution Phases

- **Setup Phase (Steady State):** The current address remains fixed on `PC_Out`. The adder computes $PC + 4$ while the execution stage computes `Target_Addr`. The `TakeBranch` control line settles, routing the selected target to the register input.
- **Commit Phase (Clock Rising Edge):** The register captures the value at its input. `PC_Out` transitions to the new instruction address, updating the execution path.

---

### Driver Logic Equations

```text
Next_PC = TakeBranch ? Target_Addr : (PC_Out + 4)

On Rising_Edge(Clk):
    if Reset == 1:
        PC_Out <= 32'h0000_0000
    else:
        PC_Out <= Next_PC
```
