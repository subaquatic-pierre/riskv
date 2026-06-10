# HazardControl Subsystem Architecture Documentation

The **HazardControl** unit acts as the centralized control layer for the pipelined processor core. It evaluates execution states across multiple stages simultaneously to resolve control flow discrepancies and structural/data pipeline conflicts.

In the current 2-stage ($\text{IF} \rightarrow \text{ID/EX/MEM/WB}$) configuration, the unit isolates dependencies, passes synchronization hooks forward, and executes synchronous pipeline flushing to handle control hazards cleanly without logic feedback loops.

---

### Canvas Mapping Layout

```text
+-----------------------------------------------------------------------+
|                           HAZARD CONTROL UNIT                         |
+-----------------------------------------------------------------------+
   |                                                                 |
   |-- [Pipeline Inputs]  --> PCSel                                  |
   |                                                                 |
   |-- [Pipeline Outputs] --> IF_ID_Flush, PC_WriteEnable,           |
   |                          IF_ID_WriteEnable                      |
+-----------------------------------------------------------------------+
```

---

### Signal Interface Matrix

| Signal / Bus Name       | Bit Width | Direction  | Source / Destination               | Functional Description                                                                                                                            |
| :---------------------- | :-------: | :--------: | :--------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`PCSel`**             |     1     | **Input**  | Branch Controller (EX)             | Active-high signal indicating a resolved conditional branch is taken or an unconditional jump (`JAL`/`JALR`) is executing.                        |
| **`IF_ID_Flush`**       |     1     | **Output** | Flush MUX ($\text{IF}$)            | Drives the selection line of the 32-bit instruction multiplexer directly before the $\text{IF/ID}$ register. High injects a `NOP` (`0x00000013`). |
| **`PC_WriteEnable`**    |     1     | **Output** | Program Counter (`en`)             | Synchronous master update enable for the PC register. Driven low to freeze the PC in place during stalls.                                         |
| **`IF_ID_WriteEnable`** |     1     | **Output** | $\text{IF/ID}$ Pipeline Reg (`en`) | Synchronous master update enable for the stage register. Driven low to freeze the fetched instruction in place.                                   |

---

### Subsystem Operational Logic

### A. Control Hazard Resolution (Flushing)

When `PCSel` goes high, an instruction from an incorrect speculative path has already been staged in the instruction fetch phase. To remove this invalid instruction before it can access registers or memory resources, the `HazardControl` unit triggers an active-high flush.

Instead of manipulating the decoder dynamically mid-cycle (which causes a combinational race condition), this signal is routed to a multiplexer upstream of the pipeline boundary. On the next rising clock edge, a hardware `NOP` (`addi x0, x0, 0`) is safely latched into the execution stage while the PC updates to the true target address.

### B. Synchronous Stalling Configuration

To prevent simulation instability and clock skew caused by asynchronous logic gating on the clock wire, pipeline stalls are driven exclusively via the active-high register enable (`en`) flags.

- An enable of `1` permits standard state updates on the rising clock edge.
- An enable of `0` commands the register to ignore the incoming clock edge and safely hold its state.

---

### Core Driver Logic Formulas

Since data hazards do not physically exist inside a 2-stage execution split, the stall lines remain perpetually unasserted (enabled) during this phase. The internal combinational logic inside the sub-circuit is mapped as follows:

```text
// Control Hazard Mapping
IF_ID_Flush = PCSel

// Synchronous Write Enables (Active-High)
PC_WriteEnable    = 1
IF_ID_WriteEnable = 1
```

---

### Future Forwarding & Stalling Interface Hooks

When scaling this subsystem to a full 5-stage pipeline ($\text{IF} \rightarrow \text{ID} \rightarrow \text{EX} \rightarrow \text{MEM} \rightarrow \text{WB}$), the top-level ports and internal structures are already physically mapped to handle the expansion.

The layout can be scaled by extending the `HazardControl` sub-circuit with the following architectural connections:

#### 1. Input Extensions (Data Hazard Verification)

- `ID_rs1[4:0]`, `ID_rs2[4:0]` : Sourced from the instruction currently in the decode stage.
- `EX_rd[4:0]`, `MEM_rd[4:0]`, `WB_rd[4:0]` : Sourced from destination registers in subsequent phases.
- `EX_RegWEn`, `MEM_RegWEn`, `WB_RegWEn` : Master writeback status flags from later stages.
- `EX_MemRead` : Identifies an in-flight memory load instruction to track Load-Use stalls.

#### 2. Output Extensions (Forwarding Bus Integration)

- `ForwardA[1:0]`, `ForwardB[1:0]` : Multi-bit control selection buses routed to the ALU inputs. These select between raw register output (`00`), the MEM stage bypass (`01`), or the WB stage bypass (`10`).

#### 3. 5-Stage Logical Expansion Blueprint

```text
// Internal Load-Use Hazard Detection
Load_Use_Stall = EX_MemRead AND ((EX_rd == ID_rs1) OR (EX_rd == ID_rs2)) AND (EX_rd != 0)

// Expanded Active-High Write Enable Logic
PC_WriteEnable    = NOT(Load_Use_Stall)
IF_ID_WriteEnable = NOT(Load_Use_Stall)
```
