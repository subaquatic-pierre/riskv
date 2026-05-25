# 32-Word Discrete Register File Module

## Functional Overview

The **Register File (`RegisterFile`)** serves as the central high-speed execution scratchpad for the processor core. Unlike consolidated memory blocks, this module is built out of 32 discrete, independent 32-bit registers (`x0` to `x31`) to expose raw structural routing.

To support standard RISC-V three-operand arithmetic (`add rd, rs1, rs2`), the module provides concurrent dual-asynchronous read capabilities alongside a single synchronous write capability. It enforces the foundational RISC-V architectural constraint that register `x0` remains hardwired to zero, discarding any incoming writes and consistently emitting zero data.

---

## Interface Specifications

### Input Signals

| Pin Name | Bit Width | Direction | Functional Description                                      |
| :------- | :-------: | :-------: | :---------------------------------------------------------- |
| `rs1`    |     5     |   Input   | Source Register 1 address line (Instruction bits [19:15])   |
| `rs2`    |     5     |   Input   | Source Register 2 address line (Instruction bits [24:20])   |
| `rd`     |     5     |   Input   | Destination Register address line (Instruction bits [11:7]) |
| `W_Data` |    32     |   Input   | 32-bit data bus containing the value to commit to storage   |
| `W_En`   |     1     |   Input   | Master write-enable control signal from the execution stage |
| `Clk`    |     1     |   Input   | Global system clock line (Synchronous write trigger)        |

### Output Signals

| Pin Name  | Bit Width | Direction | Functional Description                                       |
| :-------- | :-------: | :-------: | :----------------------------------------------------------- |
| `R_Data1` |    32     | Input/Out | Real-time, asynchronous 32-bit data read from register `rs1` |
| `R_Data2` |    32     | Input/Out | Real-time, asynchronous 32-bit data read from register `rs2` |

---

## Internal Hardware Architecture

The structural layout inside the component is divided into three distinct combinational and sequential layers:

### 1. Write Steering Layer (Demultiplexer)

A 1-to-32 Demultiplexer handles incoming write operations.

- The 1-bit master `W_En` line is tied to the data input of the demultiplexer.
- The 5-bit `rd` address bus acts as the selector input.
- **The `x0` Bypass:** Output line 0 of the demultiplexer (corresponding to `rd = 00000`) is left completely unconnected. The remaining 31 output lines are routed directly to the individual write-enable ports of registers `x1` through `x31`. This guarantees that a write transaction targeted at `x0` is safely dropped.

### 2. Storage Layer (Register Bank)

- **Register `x0`:** No physical register component is placed. The line representing `x0` is hardwired directly to a constant ground bus (`0x00000000`).
- **Registers `x1` to `x31`:** 31 individual 32-bit registers are arrayed in parallel. Their data inputs (`D`) are tied concurrently to the master `W_Data` bus, and their clock pins are linked directly to the master `Clk` line. Execution only triggers if an individual register's specific demultiplexer line goes high.

### 3. Read Steering Layer (Multiplexers)

Two independent 32-bit 32-to-1 Multiplexers drive the real-time output streams:

- **Port 1 (`R_Data1`):** Driven by a 32-to-1 MUX controlled by the 5-bit `rs1` address line. Input 0 of this MUX is tied to the constant ground block (`0`), while inputs 1 through 31 are connected to the outputs of registers `x1` to `x31`.
- **Port 2 (`R_Data2`):** Driven by an identical 32-to-1 MUX controlled by the 5-bit `rs2` address line, following the exact same input allocation schema.

---

## Core Operational Mechanics

1. **Asynchronous Read Operations:** Any modification to the `rs1` or `rs2` address lines instantly ripples through the 32-to-1 multiplexer trees. The requested data values stabilize on `R_Data1` and `R_Data2` within the same clock phase, requiring no clock edge to read.
2. **Synchronous Write Operations:** When `W_En` is active, the data value on `W_Data` sits at the inputs of all registers, but only the register highlighted by `rd` has its write-enable pin asserted. On the subsequent rising edge of the `Clk`, the selected register captures and saves the data value.
