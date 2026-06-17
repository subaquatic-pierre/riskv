# Pipeline

---

## 5-Stage Instruction Isolation Mechanics

Pipelining maximizes execution throughput by overlapping the execution of multiple instructions. To achieve this synchronization without data collisions or signal degradation, the Risk-V datapath is explicitly partitioned into five execution stages. Each stage is strictly isolated by sequential, edge-triggered boundary registers that act as clock-cycle checkpoints.

Every pipeline register captures the output metrics and control flags of the preceding stage on the positive (rising) edge of the system clock (`SysClk`) and stabilizes them as static inputs for the downstream stage throughout the current clock cycle.

---

## Stage-by-Stage Hardware Breakdown

### 1. Instruction Fetch (IF)

The Instruction Fetch stage calculates the next instruction address and reads the raw machine code word from memory.

- **Active Hardware**: Program Counter (PC) 32-bit register, stable synchronous Instruction Memory (IMem), and a dedicated combinational $PC + 4$ Adder.
- **Operational Flow**: The 32-bit address inside the PC is driven directly onto the address bus of the Instruction Memory, yielding a 32-bit instruction machine code word. Concurrently, the adder calculates the sequential fallback tracking address ($PC + 4$).
- **Downstream Targeting**: Both the raw instruction word and the $PC + 4$ tracking index settle at the entry boundary of the `IF_ID` pipeline register.

### 2. Instruction Decode (ID)

The Instruction Decode stage untangles the instruction bitfields, checks for pipeline hazards, reads source operands, and builds sign-extended constants.

- **Active Hardware**: Main Control Unit decoder matrix, 32-word structural Register File, Immediate Generator, and the centralized Hazard Controller.
- **Operational Flow**:
  - The 32-bit instruction is sliced into explicit bit ranges: `opcode` (bits 6:0), `rd` (bits 11:7), `funct3` (bits 14:12), `rs1` (bits 19:15), `rs2` (bits 24:20), and `funct7` (bits 31:25).
  - The Main Control Unit combinationally decodes the `opcode` to establish initial control flags.
  - The Register File performs parallel asynchronous reads on ports `rs1` and `rs2`, outputting data onto buses `RDataA` and `RDataB`.
  - The Immediate Generator parses non-contiguous fragments to reconstruct a unified 32-bit sign-extended immediate field (`Imm`).
- **Downstream Targeting**: Decoded control flags, read operands, immediate scalars, and tracking indices are routed directly to the `ID_EX` register boundary.

### 3. Execution (EX)

The Execution stage completes arithmetic computations, evaluates branch conditions, and determines target addresses.

- **Active Hardware**: Core Arithmetic Logic Unit (ALU), source multiplexer arrays (`ASel` and `BSel`), Branch Control Unit, and the Forwarding Unit.
- **Operational Flow**:
  - The Forwarding Unit continuously evaluates active downstream register writes against current execution sources (`rs1`/`rs2`). If a data dependency is identified, forwarding multiplexers dynamically swap stale register data with live bypass values from the `EX_MEM` or `MEM_WB` registers.
  - Multiplexers `ASel` and `BSel` finalize the core ALU inputs (e.g., selecting between bypassed register data, the active PC tracking value, or the sign-extended immediate).
  - The ALU processes the inputs based on the 5-bit `ALUSel` opcode to generate `ALURes`.
  - The Branch Control Unit evaluates conditions (e.g., equality, signed comparison) to determine if a branch is taken (`Branch_Taken`).
- **Downstream Targeting**: The computed result (`ALURes`), forwarded store data (`MemWData`), target destination index (`rdi`), and remaining memory/writeback control flags land at the input of the `EX_MEM` register.

### 4. Memory Access (MEM)

The Memory Access stage coordinates reads and writes with physical volatile storage cells.

- **Active Hardware**: Data Memory (DMem) core, combinational Store Aligner, and Load Aligner.
- **Operational Flow**:
  - The incoming `ALURes` is mapped straight to the Data Memory address bus.
  - If `MemWrite` is asserted high, the Store Aligner formats the data payload (`MemWData`) into appropriate byte lanes based on the instruction width spec (`MemByteSel`) before triggering the RAM cells.
  - If `MemRead` is asserted high, a data word is retrieved from the RAM cells, and the Load Aligner sign-extends or zero-pads the output according to the targeted load size format (byte, halfword, or full word).
- **Downstream Targeting**: Sized read data (`MemRData`), bypassed ALU outcomes (`ALURes`), return links ($PC + 4$), and target writeback metrics settle at the `MEM_WB` register inputs.

### 5. Write Back (WB)

The terminal Write Back stage selects and routes the finalized data payload to commit updates back into the architectural register file.

- **Active Hardware**: Write Back Controller multiplexer steering matrix.
- **Operational Flow**: The Write Back Controller acts as a multi-channel selection tree. It evaluates the 2-bit `WBSel` tracking flag to steer a single 32-bit data path out of three available resource channels:
  - `00`: Direct ALU calculation bypass (`ALURes`).
  - `01`: Sanitized memory read output (`MemRData`).
  - `11`: Sequential link return address ($PC + 4$).
- **Loopback Targeting**: The selected data path loops back across the full horizontal layout of the processor schematic, terminating directly at the write port (`BusW`) of the Register File in the Decode stage, authorized on the clock edge by the latched register write enable flag (`RegWEn`).

---

## Global Structural Timing Diagram

The diagram below maps out how independent instructions move through the decoupled execution stages across five successive clock cycles under normal pipeline operation:

```text
          Cycle 1      Cycle 2      Cycle 3      Cycle 4      Cycle 5
Inst 0:   [  IF  ] --> [  ID  ] --> [  EX  ] --> [  MEM ] --> [  WB  ]
Inst 1:                [  IF  ] --> [  ID  ] --> [  EX  ] --> [  MEM ] --> [  WB  ]
Inst 2:                             [  IF  ] --> [  ID  ] --> [  EX  ] --> [  MEM ]
Inst 3:                                          [  IF  ] --> [  ID  ] --> [  EX  ]
Inst 4:                                                       [  IF  ] --> [  ID  ]
```

---

## Boundary Register Micro-Logic Specifications

The pipeline relies on four discrete boundary register blocks to maintain steady state isolation. Each block handles stall and flush signals uniquely using input-side multiplexing and label tunnels.

### 1. IF/ID Register (`components/pipeline/if-id.md`)

- **Inputs Captured**: `In_PC` (32 bits), `In_Inst` (32 bits)
- **Outputs Delivered**: `Out_PC` (32 bits), `Out_Inst` (32 bits)
- **Control Mechanics**:
  - Controlled by the active-high write-enable flag `IF_ID_Write` and active-high clear flag `IF_ID_Flush`.
  - If `IF_ID_Flush == 1` $\rightarrow$ Outputs instantly clear on the clock edge (`Out_PC = 0x00000000`, `Out_Inst = 0x00000013` [Hardware NOP]).
  - If `IF_ID_Flush == 0` and `IF_ID_Write == 0` $\rightarrow$ Clock updates are masked, locking the internal state to execute a pipeline stall.

### 2. ID/EX Register (`components/pipeline/id-ex.md`)

- **Inputs Captured**: Execution, Memory, and Writeback control bundles, source/destination tracking indices (`rs1`, `rs2`, `rdi`), read payloads (`RDataA`, `RDataB`), immediate scalar (`Imm`), and address track (`IF_ID_PC`).
- **Outputs Delivered**: Symmetrical pipeline-prefixed versions of all inputs (e.g., `ID_EX_ALUSel`, `ID_EX_RDataA`).
- **Control Mechanics**: Mapped directly to write-enable `ID_EX_WE` and flush vector `ID_EX_FLUSH`. Activating a flush isolates the execution stage by forcing all outgoing downstream control lines synchronously to `0`, transforming the instruction into a harmless pipeline bubble.

### 3. EX/MEM Register (`components/pipeline/ex-mem.md`)

- **Inputs Captured**: Memory and Writeback control lines, ALU outcome (`ALURes`), forwarded store data (`MemWData`), and destination index (`rdi`).
- **Outputs Delivered**: `EX_MEM_` prefixed tracking buses.
- **Control Mechanics**: Mapped to write enable `EX_MEM_WE` and synchronous clear `EX_MEM_FLUSH`. Wipes trailing memory read/write commands if late exceptions occur during execution.

### 4. MEM/WB Register (`components/pipeline/mem-wb.md`)

- **Inputs Captured**: Writeback control lines (`RegWEn`, `WBSel`), destination pointer (`rdi`), memory output (`MemRData`), arithmetic result (`ALURes`), and link path (`PC_4`).
- **Outputs Delivered**: Terminal `MEM_WB_` prefixed commit lines.
- **Control Mechanics**: Controlled by `MEM_WB_WE` and `MEM_WB_FLUSH`. This register stabilizes data returns and loops target write metrics (`MEM_WB_rdi`, `MEM_WB_RegWEn`) back to the forwarding and hazard modules to maintain hazard safety.

```

```
