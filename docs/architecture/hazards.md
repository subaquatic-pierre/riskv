# Hazards

---

## Overview

In a pipelined processor, maximum throughput is achieved when a new instruction is fetched on every single clock cycle. However, conditions called **hazards** arise that prevent the next instruction in the instruction stream from executing in its designated clock cycle. If left unhandled, hazards cause the pipeline to execute stale data or incorrect instructions, leading to critical state corruption.

The Risk-V architecture features a centralized hardware **Hazard Controller** that dynamically monitors instructions across all pipeline stages, resolves dependencies, and maintains strict program correctness through two primary recovery mechanisms:

- **Pipeline Stalls (Interlocks)**: Freezing early pipeline stages while allowing later stages to advance, creating an execution gap.
- **Pipeline Flushes (Bubbles)**: Synchronously clearing speculative instructions out of boundary registers and replacing them with non-operational (`NOP`) tokens.

---

## Hazard Categorization

The Risk-V 5-stage pipeline detects and mitigates two main classes of architectural hazards: **Data Hazards** and **Control Hazards**.

### 1. Data Hazards

Data hazards occur when an instruction depends on the result of a previous instruction that is still moving through the pipeline and has not yet committed its final value to the Register File.

- **RAW (Read-After-Write) Hazards**: This is the primary data hazard present in the Risk-V pipeline. It happens when an instruction in the Decode (ID) stage needs to read a register (`rs1` or `rs2`) that a preceding instruction in the Execute (EX), Memory (MEM), or Writeback (WB) stage is scheduled to write back to (`rd`).
  - _ALU Dependency_: Resolved transparently with **zero-latency overhead** via the **Forwarding Unit**, which routes calculated results straight from the `EX_MEM` or `MEM_WB` registers back to the ALU inputs.
  - _Load-Use Dependency_: Occurs when an instruction immediately following a load instruction (`lw`, `lh`, `lb`) requires the loaded data. Because data memory reads finish late in the MEM stage, the operand cannot be bypassed back to the ALU in time for the execution edge. This requires a structural **1-cycle pipeline stall**.

```text
    Cycle 1      Cycle 2      Cycle 3      Cycle 4      Cycle 5      Cycle 6
lw  x5, 0(x10)   [IF] --------> [ID] --------> [EX] --------> [MEM] -------> [WB]
                                                                | (Data ready late)
                                                                v (Cannot bridge backward)
add x6, x5, x7                [IF] --------> [ID] (STALL) -> [EX] -------> [MEM] -------> [WB]
```

### 2. Control Hazards

Control hazards occur when the pipeline fetches subsequent instructions based on a speculative Program Counter path before a branch or jump instruction has completed its target address evaluation.

- **Branch Misprediction / Jump Redirection**: The Risk-V pipeline utilizes a baseline _Static Predict-Not-Taken_ approach, speculatively fetching sequential instructions ($PC + 4$).
- When a conditional branch evaluates as **taken** in the Execution stage, or when an unconditional jump (`jal`, `jalr`) resolves its target, the speculatively fetched instructions currently in the Fetch (IF) and Decode (ID) stages are invalidated.
- The Hazard Controller mitigates this by asserting flush vectors, converting the speculatively loaded slots into harmless `NOP` bubbles while updating the Program Counter to point to the correct branch destination address.

---

## Central Hazard Controller Interface

The Hazard Controller acts as an independent combinational supervisor operating adjacent to the main pipeline. It evaluates destination indices, source dependencies, and branch statuses to generate global gating signals.

### Controller Inputs

| Signal          | Width  | Source Stage | Description                                                                                                  |
| :-------------- | :----: | :----------: | :----------------------------------------------------------------------------------------------------------- |
| `ID_EX_MemRead` | 1 bit  |      EX      | Asserted high if the instruction currently in the Execute stage is a memory load.                            |
| `ID_EX_rd`      | 5 bits |      EX      | Destination register index of the instruction currently in the Execute stage.                                |
| `IF_ID_rs1`     | 5 bits |      ID      | Source register 1 index of the instruction currently in the Decode stage.                                    |
| `IF_ID_rs2`     | 5 bits |      ID      | Source register 2 index of the instruction currently in the Decode stage.                                    |
| `Branch_Taken`  | 1 bit  |      EX      | Evaluation flag from the Branch Control Unit; high if a branch condition evaluates as true or a jump occurs. |

### Controller Outputs

| Signal        | Width |  Target Module   | Structural Action on Assertion (`1`)                                                                        |
| :------------ | :---: | :--------------: | :---------------------------------------------------------------------------------------------------------- |
| `PC_Write`    | 1 bit | Program Counter  | **Active-Low Enable (`EN`)**: Deasserting this to `0` freezes the PC value, preventing new fetches.         |
| `IF_ID_Write` | 1 bit | `IF_ID` Register | **Active-High Write Enable**: Deasserting this to `0` freezes the Fetch/Decode boundary register state.     |
| `IF_ID_Flush` | 1 bit | `IF_ID` Register | **Active-High Synchronous Clear**: Overwrites the latched instruction with `0x00000000` (Zero Address/NOP). |
| `ID_EX_Flush` | 1 bit | `ID_EX` Register | **Active-High Synchronous Clear**: Wipes control flags and injects a pipeline bubble into execution.        |

---

## Hazard Mitigation Logic (Core Rules)

The Hazard Controller evaluates its outputs combinationally based on two independent priority rules.

### Rule 1: Load-Use Hazard Interlock Evaluation

A load-use dependency is detected if an instruction in the Execute stage is a load (`ID_EX_MemRead == 1`) and its destination register (`ID_EX_rd`) matches either of the source registers currently being compiled in the Decode stage (`IF_ID_rs1` or `IF_ID_rs2`). Register `x0` is excluded from tracking as it is hardwired to zero.

$$\text{LoadUseHazard} = \text{ID\_EX\_MemRead} \ \land \ (\text{ID\_EX\_rd} \neq 0) \ \land \ ((\text{ID\_EX\_rd} == \text{IF\_ID\_rs1}) \ \lor \ (\text{ID\_EX\_rd} == \text{IF\_ID\_rs2}))$$

When `LoadUseHazard == 1`:

- `PC_Write = 0` $\rightarrow$ Structural freeze of the active Program Counter address.
- `IF_ID_Write = 0` $\rightarrow$ Structural freeze of the fetched instruction inside the Fetch/Decode boundary.
- `ID_EX_Flush = 1` $\rightarrow$ Wipes the downstream control lines moving into the execution register, inserting an execution bubble.

### Rule 2: Control Hazard Branch Flush Evaluation

When a conditional branch condition resolves as true or an unconditional jump executes, the instructions speculatively loaded into the pipeline behind it are invalid and must be expunged.

When `Branch_Taken == 1`:

- `IF_ID_Flush = 1` $\rightarrow$ Flushes the instruction currently in the Fetch stage.
- `ID_EX_Flush = 1` $\rightarrow$ Flushes the instruction currently in the Decode stage.
- The Program Counter multiplexer switches to route the calculated target address directly into the PC register on the next clock edge, overriding the standard sequential sequence.

---

## Step-by-Step Operational Traces

### Example 1: Handling a Load-Use Stall Sequence

Consider the following execution block:

```asm
lw  x2, 12(x10)  # Load memory data into register x2
sub x4, x2, x3   # Subtract uses x2 immediately - Load-Use Hazard!
```

1.  **Cycle N (Instruction Fetch/Decode)**:
    - The `lw` instruction moves into the EX stage; control logic asserts `ID_EX_MemRead = 1` and registers `ID_EX_rd = 0x02`.
    - The `sub` instruction is fetched out of instruction memory and settles inside the `IF_ID` register, exposing `IF_ID_rs1 = 0x02` and `IF_ID_rs2 = 0x03` to the decode bus.
2.  **Hazard Detection**:
    - The Hazard Controller detects that `ID_EX_MemRead == 1`, `ID_EX_rd != 0`, and `ID_EX_rd == IF_ID_rs1` ($0x02 == 0x02$).
    - The controller instantly pulls `PC_Write = 0`, `IF_ID_Write = 0`, and `ID_EX_Flush = 1`.
3.  **Clock Edge Transition (End of Cycle N)**:
    - The Program Counter holds its current address, ensuring `sub`'s successor is not fetched yet.
    - The `IF_ID` register ignores the clock edge, holding the raw `sub` machine code static on the decode tracks.
    - The `ID_EX` register processes the synchronous flush, locking all downstream control lines (`RegWEn`, `MemWrite`, etc.) to `0`.
4.  **Cycle N+1 (Stall Execution)**:
    - A harmless `NOP` bubble propagates through the Execution stage.
    - The original `lw` instruction reaches the MEM stage, retrieving the data word from RAM.
    - The load dependency is now resolved, allowing the Forwarding Unit to bypass the fresh data word directly from the `MEM_WB` boundary straight to the ALU for the `sub` instruction in the next cycle.

---

## Circuit Implementation Principles (Logisim)

- **Purely Combinational**: The Hazard Controller contains no internal registers or sequential memory clocks. It is implemented using native Logisim comparison matrices (`Bit Comparators`) and basic logic gates (`AND`, `OR`, `NOT`) to maintain zero-latency tracking updates within the current cycle.
- **Glitch Containment**: Hazard evaluation lines are distributed to the boundary registers via clean label tunnels. This ensures that control updates settle fully before the active positive clock edge arrives, eliminating race conditions or setup-time violations across the pipeline stages.

```

```
