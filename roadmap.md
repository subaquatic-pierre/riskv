# CPU Development Roadmap: Phase 2

## Phase 1: CSR Registers & Instruction Support

Add support for Control and Status Registers (CSRs) to handle system states, performance counters, and basic exception tracking.

### Key Objectives

- Implement the core CSR address space and internal register file storage.
- Add execution support for the atomic CSR instruction set:
  - `csrrw` / `csrrwi` (Atomic Read/Write Register)
  - `csrrs` / `csrrsi` (Atomic Read & Set Bits)
  - `csrrc` / `csrrci` (Atomic Read & Clear Bits)
- Support system instructions: `ecall` (Environment Call) and `ebreak` (Breakpoint).

### Execution Strategy

- **Decode Modification:** Upgrade the decode unit to parse the 12-bit CSR address encoded in the immediate field ($[31:20]$).
- **Execution Integration:** Route the CSR read data back into the main multiplexer for write-back into the standard integer register file ($x0$-$x31$).

---

## Phase 2: M-Extension (Multiplier/Divider Unit)

Upgrade the execution pipeline from basic integer operations to hardware-accelerated math operations.

### Key Objectives

- Integrate a hardware Multiplier and Divider unit into the Execution stage.
- Support the standard RV32M instruction set:
  - `mul`, `mulh`, `mulhu`, `mulhsu` (32-bit multiplication returning lower or upper halves).
  - `div`, `divu`, `rem`, `remu` (Signed/Unsigned division and remainder).

### Execution Strategy

- **ALU Extension:** Place the Multiplier/Divider block parallel to the primary ALU.
- **Cycle Budgeting:** Determine whether to use an iterative multi-cycle design to preserve maximum clock frequency, or a large single-cycle combinational array.

---

## Phase 3: Two-Stage Pipelining

Break the processor into two overlapping stages: **Fetch (IF)** and **Execute (ID/EX/MEM/WB)**. The Program Counter fetches the next instruction while the current one is being processed.

```
Cycle 1: [ Fetch Inst 1 ]
Cycle 2: [ Fetch Inst 2 ] -> [ Execute Inst 1 ]
Cycle 3: [ Fetch Inst 3 ] -> [ Execute Inst 2 ]
```

### Hazard Mitigation

#### 1. Structural Hazards

- **The Hazard:** Simultaneous memory access. If your architecture uses a unified single-port memory structure for instructions and data, the Execute stage will block the Fetch stage during `lw` or `sw` operations.
- **Overcoming It:** Transition to a dual-port memory architecture or separate instruction and data networks (Harvard Architecture structure: `IMem` and `DMem`).

#### 2. Control Hazards (Branches/Jumps)

- **The Hazard:** When a conditional branch (`beq`, `bne`, etc.) or jump (`jal`, `jalr`) changes the Program Counter, the instruction currently being fetched right behind it is invalid.
- **Overcoming It:** * **Pipeline Flushing:** If a branch evaluates to *taken\* in the Execute stage, drop the incorrectly fetched instruction in the pipeline register by forcing it to a `NOP` (`0x00000013`).
  - **Hardware Stall:** Introduce a 1-cycle penalty bubble to let the PC resolve to the correct target address.

---

## Phase 4: Branch Prediction (Static Strategy)

Before jumping directly to heavy pipelining, introduce a dedicated architecture layer to predict branch behavior at the Fetch stage to reduce branch-induced stall cycles.

### Key Objectives

- Implement a **Static Branch Predictor** based on direction parameters (BTFNT: _Backward Taken, Forward Not Taken_).
  - **Backward Branches (Loops):** If the sign bit of the branch target offset is negative (pointing to a lower memory address), guess **Taken**.
  - **Forward Branches (If/Else):** If the sign bit of the branch target offset is positive (pointing to a higher memory address), guess **Not Taken**.
- Build a baseline branch evaluation pipeline to compare prediction bits against actual ALU outcomes.

### Execution Strategy

- **Pre-decode Block:** Add minimal combinational logic in the Fetch stage to intercept the raw instruction bytes, check if the opcode matches a branch, and extract the sign bit of the immediate offset.
- **Target Speculation:** If predicted taken, the PC latches `PC + immediate` immediately on the next edge instead of `PC + 4`.

---

## Phase 5: Five-Stage Pipelining

Deconstruct execution completely into the classic RISC paradigm: **Fetch (IF)** $\rightarrow$ **Decode (ID)** $\rightarrow$ **Execute (EX)** $\rightarrow$ **Memory (MEM)** $\rightarrow$ **Write-Back (WB)**.

### Hazard Mitigation

#### 1. Data Hazards (Read-After-Write)

- **The Hazard:** An instruction tries to read a register value before a previous instruction has finished writing its results back to the register file.
  ```assembly
  addi x5, x0, 10   # Writes to x5 in WB stage (Cycle 5)
  add  x6, x5, x5   # Reads x5 in ID stage (Cycle 3) -> Stale Value!
  ```
- **Overcoming It:**
  - **Register File Bypassing / Forwarding:** Build a **Forwarding Unit** that detects if the source registers in the execution stage match the destination registers currently moving through the `EX/MEM` or `MEM/WB` pipeline registers. Route the computing data lines back directly to the ALU inputs, skipping the register file write lag entirely.
  - **Load-Use Stalls:** If an instruction directly following a `lw` instruction depends on that loaded data, forwarding is physically impossible because the data hasn't been read from memory yet. Detect this condition in hardware and insert a 1-cycle **Pipeline Stall (Bubble)**, freezing the IF and ID stages for one clock tick.

#### 2. Control Hazards

- **The Hazard:** With a 5-stage deep pipeline, a branch decision made late in the pipeline means multiple instructions currently trailing behind it are invalid if the prediction fails.
- **Overcoming It:**
  - **Dynamic Misprediction Auditing:** Integrate the branch predictor from Phase 4. If the execution stage determines that the predictor guessed wrong (e.g., predicted Taken, but branch actually evaluated to Not Taken), trigger a recovery routine.
  - **Flushing Infrastructure:** Expand the flush logic to dynamically clear multiple pipeline staging registers (`IF/ID`, `ID/EX`) simultaneously, turning bad speculative instructions into safe `NOP`s while correcting the PC back to the proper execution stream.
  - **Early Branch Resolution:** Move branch target evaluation and comparison logic earlier into the Decode (ID) stage to minimize the misprediction penalty down from three cycles to a single cycle.
