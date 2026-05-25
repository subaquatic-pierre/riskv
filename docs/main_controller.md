# MainControlDecoder Architecture Overview

The **MainControlDecoder** serves as the central orchestration unit for the processor's datapath. It decodes the raw instructions fetched from memory and generates a structured set of control signals and buses. To maintain clear structural organization, these signals are conceptualized and grouped on the canvas according to the specific pipeline stages and architectural blocks they manage.

---

### Control Signal Canvas Mapping

```text
+-----------------------------------------------------------------------+
|                         MAIN CONTROL DECODER                          |
+-----------------------------------------------------------------------+
   |                                                                 |
   |-- [ID_Control]   --> ImmSel[2:0]                                |
   |                                                                 |
   |-- [EX_Control]   --> ASel, BSel, ALUSel[3:0], BRSel[2:0], PCSel |
   |                                                                 |
   |-- [MEM_Control]  --> MemRead, MemWrite                          |
   |                                                                 |
   |-- [WB_Control]   --> RegWEn, WBSel[1:0]                         |
   |                                                                 |
   |-- [Trap_Control] --> Is_Ecall, Is_Ebreak                        |
+-----------------------------------------------------------------------+
```

---

### Master Interface Signal Matrix

| Canvas Group     | Signal / Bus Name | Bit Width | Type | Destination Block    | Primary Functional Purpose                                                                                          |
| :--------------- | :---------------- | :-------: | :--: | :------------------- | :------------------------------------------------------------------------------------------------------------------ |
| **ID_Control**   | `ImmSel[2:0]`     |  3 bits   | Bus  | Immediate Generator  | Configures the sign-extension layout based on instruction type (I, S, B, U, J).                                     |
| **EX_Control**   | `ASel`            |   1 bit   | Pin  | Multiplexer A        | Selects Register Port 1 data (`0`) vs. current `PC` value (`1`) for ALU Input A.                                    |
|                  | `BSel`            |   1 bit   | Pin  | Multiplexer B        | Selects Register Port 2 data (`0`) vs. Extended Immediate (`1`) for ALU Input B.                                    |
|                  | `ALUSel[3:0]`     |  4 bits   | Bus  | Execution ALU        | Dictates the exact arithmetic or logical operation the main ALU must perform.                                       |
|                  | `BRSel[2:0]`      |  3 bits   | Bus  | Branch Controller    | Forwards condition selection criteria (`funct3`) to evaluate branch structural inequalities.                        |
|                  | `PCSel`           |   1 bit   | Pin  | Fetch MUX (Loopback) | Evaluated in EX: Forces a pipeline jump to a computed target (`1`) or maintains sequential $PC + 4$ (`0`).          |
| **MEM_Control**  | `MemRead`         |   1 bit   | Pin  | Data Memory (RAM)    | Active-high master read enable. Activates memory read lookups exclusively during Load operations.                   |
|                  | `MemWrite`        |   1 bit   | Pin  | Data Memory (RAM)    | Active-high master write enable. Commits data from Register Port 2 to memory during Store operations.               |
| **WB_Control**   | `RegWEn`          |   1 bit   | Pin  | Register File        | Master writeback gatekeeper. Asserts high (`1`) to permit writing execution results into destination register `rd`. |
|                  | `WBSel[1:0]`      |  2 bits   | Bus  | Writeback MUX        | Chooses the writeback source data: Data Memory (`00`), ALU Result (`01`), or Link Address $PC + 4$ (`10`).          |
| **Trap_Control** | `Is_Ecall`        |   1 bit   | Pin  | Exception / CSR Unit | Detects environment calls (`ecall`), initiating a structured transition to supervisor/machine mode.                 |
|                  | `Is_Ebreak`       |   1 bit   | Pin  | Debug / CSR Unit     | Detects environment breakpoints (`ebreak`), halting the pipeline or redirecting to a debugger monitor.              |

---

### Architectural Pipeline Flow

1. **Decode & Preparation (ID Stage):** The incoming instruction instantly drives `ImmSel` to extract immediates. The rest of the control groups are bundled and prepared for travel.
2. **Execution & Flow Decision (EX Stage):** Operand paths are established via `ASel` and `BSel` to feed the ALU. Concurrently, register comparisons run through `BRSel` to generate the real-time feedback loop for `PCSel`, resolving flow hazards.
3. **Memory Access (MEM Stage):** Dedicated `MemRead` and `MemWrite` flags dictate RAM interactions, ensuring isolated standby states during non-memory operational lifecycles.
4. **State Commit (WB Stage):** The writeback multiplexer chooses the exact processing lineage via `WBSel`, and `RegWEn` safely commits the finalized token back into the architectural register arrays.

---

# ImmSel (Immediate Select) Logic Configuration

### ImmSel Multiplexer Routing Table

The Immediate Generator module uses a 3-bit selection bus (`ImmSel[2:0]`) to control its final output multiplexer, allowing it to correctly format and sign-extend different instruction variants:

| ImmSel[2:0] Value | Selected Immediate Format | Target Instruction Types                            |
| :---------------: | :------------------------ | :-------------------------------------------------- |
|    **000 (0)**    | **IType**                 | Standard ALU Immediates, Memory Loads, JALR, System |
|    **001 (1)**    | **SType**                 | Memory Stores (`sw`, `sb`, `sh`)                    |
|    **010 (2)**    | **BType**                 | Conditional Branches (`beq`, `bne`, `blt`, `bge`)   |
|    **011 (3)**    | **UType**                 | Upper Immediates (`lui`, `auipc`)                   |
|    **100 (4)**    | **JType**                 | Unconditional Long Jumps (`jal`)                    |

---

### Baseline State Logic (000)

Because your multiplexer routes the **IType** format to input port `0` (`000`), it acts as the baseline default state for the control unit.

When the processor decodes an IType arithmetic instruction, a memory load, a `jalr` jump, or a system call, no control lines need to be pulled high. The `ImmSel` lines naturally remain unasserted at `000`.

---

### Discrete Driver Gate Formulas

To shift the multiplexer to select ports 1 through 4, we use targeted OR gates to pull specific bits of the 3-bit bus high based on the active decoded opcode wire:

#### ImmSel[0] (Bit 0)

This bit must turn high for any format mapped to an odd port number: Port 1 (SType `001`) and Port 3 (UType `011`).

```text
ImmSel[0] = Store OR LUI OR AUIPC
```

#### ImmSel[1] (Bit 1)

This bit must turn high for any format mapped to ports requiring the middle binary position: Port 2 (BType `010`) and Port 3 (UType `011`).

```text
ImmSel[1] = Branch OR LUI OR AUIPC
```

#### ImmSel[2] (Bit 2)

This bit must turn high exclusively for the long jump format mapped to Port 4 (JType `100`).

```text
ImmSel[2] = JAL
```

---

# ASel (ALU Input A Select) Logic Configuration

### ASel Multiplexer Routing Table

| ASel Pin Value | Selected ALU Input A Source    |
| :------------: | :----------------------------- |
|     **0**      | **Register File Port 1 (rs1)** |
|     **1**      | **Program Counter (PC)**       |

### Instructions Setting ASel High (1)

The following instruction types require the current Program Counter (PC) address to be routed into ALU input A instead of a register value:

- **AUIPC:** Adds a U-type upper immediate to the current PC value ($PC + \text{Immediate}$).
- **Branch:** Uses the PC to calculate the relative branch target address ($PC + \text{Branch\_Offset}$) in case the condition is met.
- **JAL:** Uses the PC to calculate the relative long-range unconditional jump target address ($PC + \text{Jump\_Offset}$).

### Instructions Leaving ASel Low (0)

These instruction types default to `0` because they either perform arithmetic on a base register or bypass the ALU entirely:

- **RType:** Requires register source 1 (`rs1`) for standard register-to-register arithmetic.
- **IType:** Requires register source 1 (`rs1`) for standard register-immediate arithmetic (e.g., `addi`).
- **Load:** Uses register source 1 (`rs1`) as the base address for the memory offset calculation ($rs1 + \text{Offset}$).
- **Store:** Uses register source 1 (`rs1`) as the base address for the memory offset calculation ($rs1 + \text{Offset}$).
- **JALR:** Explicitly calculates its target relative to a base register value ($rs1 + \text{Offset}$), keeping ASel at `0`.
- **LUI:** Bypasses the ALU entirely, routing the upper immediate directly to the final writeback multiplexer.
- **System:** Operates on trap/exception flags directly without processing values via ALU input A.

### Discrete Driver Gate Formula

```text
ASel = AUIPC OR Branch OR JAL
```

---

# BSel (ALU Input B Select) Logic Configuration

### BSel Multiplexer Routing Table

| BSel Pin Value | Selected ALU Input B Source          |
| :------------: | :----------------------------------- |
|     **0**      | **Register File Port 2 (rs2)**       |
|     **1**      | **Immediate Generator Output (Imm)** |

### Instructions Setting BSel High (1)

The following instruction types require an immediate value to be routed into ALU input B:

- **IType:** Standard register-immediate operations (e.g., `addi`).
- **Load:** Uses an immediate offset to calculate the target memory address ($rs1 + \text{Offset}$).
- **Store:** Uses an immediate offset to calculate the target memory address ($rs1 + \text{Offset}$).
- **AUIPC:** Adds a U-type upper immediate to the current PC value ($PC + \text{Immediate}$).
- **JAL:** Routes the J-type jump offset to the ALU to calculate the target address ($PC + \text{Offset}$).
- **JALR:** Routes the I-type jump offset to the ALU to calculate the target address ($rs1 + \text{Offset}$).

### Instructions Leaving BSel Low (0)

These instruction types default to `0` because they either operate on a second register or bypass the ALU entirely:

- **RType:** Requires register source 2 (`rs2`) for pure register-to-register calculations.
- **Branch:** Requires register source 2 (`rs2`) so the Branch Comparator can evaluate both registers simultaneously.
- **LUI:** Bypasses the ALU completely, routing the upper immediate directly to the final writeback multiplexer.
- **System:** Triggers hazard and exception logic directly without routing a value through the ALU data path.

### Discrete Driver Gate Formula

```text
BSel = IType OR Load OR Store OR AUIPC OR JAL OR JALR
```

---

# ALUSel (ALU Operation Select) Logic Configuration

### ALUSel Bus Bit Mapping

The `ALUSel[3:0]` bus is a 4-bit control signal forwarded down the pipeline to specify the exact arithmetic or logic operation the ALU must perform. Instead of using a complex combinatorial decoding matrix inside the Main Controller, your layout elegantly passes the instruction fields directly to the bus, using bits from `funct3` and `funct7`:

|     Bus Bit     | Source Component                | Purpose                                                         |
| :-------------: | :------------------------------ | :-------------------------------------------------------------- |
| **`ALUSel[3]`** | `Instruction[14]` (`funct3[2]`) | High bit of operation type.                                     |
| **`ALUSel[2]`** | `Instruction[13]` (`funct3[1]`) | Middle bit of operation type.                                   |
| **`ALUSel[1]`** | `Instruction[12]` (`funct3[0]`) | Low bit of operation type.                                      |
| **`ALUSel[0]`** | `Instruction[30]` (`funct7[5]`) | Modifier bit (e.g., toggles `add` vs `sub`, or `srl` vs `sra`). |

### Internal Control and Gating Mechanics

While the bits are wired directly from the instruction fields to the bus lines, the ALU should only evaluate these bits during instructions that actually perform ALU calculations.

For instructions that do not use the ALU for structural operations (such as memory loads, stores, or branches), the lower modifier bit (`ALUSel[0]`) must be explicitly managed or masked to prevent accidental execution of alternate functions (like forcing a subtraction when calculating a memory address offset).

#### 1. Tracking the Modifier Bit (`ALUSel[0]`)

In the RISC-V ISA, bit 30 of the instruction (`funct7[5]`) acts as an operation modifier for only two primary sets of instructions:

- **Subtraction vs Addition:** Differentiating `sub` from `add` (R-Type).
- **Arithmetic vs Logical Shifts:** Differentiating `sra`/`srai` from `srl`/`srli` (R-Type and I-Type).

For all other instruction types (like `Load`, `Store`, or `AUIPC`), the ALU must perform a standard addition. Therefore, the modifier bit must be forced to `0` for these types, even if bit 30 of the raw instruction happens to be a `1`.

#### 2. Discrete Gating Logic for the Modifier Bit

To enforce a standard addition for memory operations and address calculations, `ALUSel[0]` is gated so it can only pass through to the ALU when an R-Type or I-Type ALU instruction is active:

```text
ALUSel[0] = Instruction[30] AND (RType OR IType)
```

### Complete ALUSel Bus Formulas

```text
ALUSel[3] = Instruction[14]
ALUSel[2] = Instruction[13]
ALUSel[1] = Instruction[12]
ALUSel[0] = Instruction[30] AND (RType OR IType)
```

---

# PCSel (Program Counter Select) Output Documentation

The **`PCSel`** output is a critical 1-bit control signal generated by the Main Control Decoder. It acts as the master routing switch for the processor's fetch stage, determining whether the Program Counter (PC) advances sequentially to the next instruction or transitions to a calculated target address (such as a jump destination or a taken branch).

---

### Functional Specification

The `PCSel` pin directly drives the selection input of the 2-to-1 multiplexer positioned immediately before the Program Counter register.

| PCSel Value | Selected PC Source                      | Core Execution Behavior                                                                                                                                                                 |
| :---------: | :-------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   **`0`**   | **Sequential PC ($PC + 4$)**            | The processor executes the next contiguous instruction in memory. This is the baseline state for all standard arithmetic, logical, load, store, and non-taken branch instructions.      |
|   **`1`**   | **Target Address (ALU / Target Adder)** | The processor alters its control flow and jumps to a new address space. This state is triggered during unconditional jumps or when a conditional branch successfully evaluates to true. |

### Internal Decoder Dependency Matrix

To generate the `PCSel` signal without exposing raw opcode lines externally, the Main Control Decoder internally evaluates its decoded instruction types against a single-bit feedback line (**`TakeBranch`**) received from the external Branch Control component.

#### Inputs Used for Calculation:

- **`Opcode_is_JAL` (Internal Flag):** Asserted high if the decoded bits match the unconditional Jump and Link instruction (`1101111`).
- **`Opcode_is_JALR` (Internal Flag):** Asserted high if the decoded bits match the unconditional Jump and Link Register instruction (`1100111`).
- **`Opcode_is_Branch` (Internal Flag):** Asserted high if the decoded bits match the conditional branch instruction class (`1100011`).
- **`TakeBranch` (External Input Pin):** A real-time evaluations flag from the Branch Control component indicating if the conditional statement (e.g., `BEQ`, `BNE`) is arithmetically satisfied.

### Mathematical Control Formula

The combinatorial logic within the Main Control Decoder drives the output high using a simple sum-of-products relationship:

$$\text{PCSel} = \text{Opcode\_is\_JAL} \lor \text{Opcode\_is\_JALR} \lor (\text{Opcode\_is\_Branch} \land \text{TakeBranch})$$

### Truth Table Verification

| Opcode_is_JAL | Opcode_is_JALR | Opcode_is_Branch | TakeBranch Input | PCSel Output | Resulting Hardware Action                                                   |
| :-----------: | :------------: | :--------------: | :--------------: | :----------: | :-------------------------------------------------------------------------- |
|       0       |       0        |        0         |        X         |    **0**     | **Fetch $PC + 4$:** Standard sequential execution path.                     |
|       0       |       0        |        1         |        0         |    **0**     | **Fetch $PC + 4$:** Branch instruction present, but condition failed.       |
|       0       |       0        |        1         |        1         |    **1**     | **Fetch Target:** Branch condition met; pipeline flushes to target address. |
|       1       |       0        |        0         |        X         |    **1**     | **Fetch Target:** Unconditional immediate jump (`jal`) forced.              |
|       0       |       1        |        0         |        X         |    **1**     | **Fetch Target:** Unconditional register jump (`jalr`) forced.              |

---

# Memory Control Logic Configuration (MemRead & MemWrite)

The Memory Control group contains the explicit command lines responsible for interfacing with the Data Memory (RAM) component. By utilizing two distinct, mutually exclusive control signals—**`MemRead`** and **`MemWrite`**—the architecture ensures that the memory subsystem remains completely passive during non-memory instructions, eliminating unintended bus activity and optimizing dynamic power consumption.

### Interface Specification

| Pin Name       | Bit Width | Direction | Destination Component | Functional Purpose                                                                                                                                                                  |
| :------------- | :-------: | :-------: | :-------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`MemRead`**  |   1 bit   |  Output   | Data Memory           | Master read-enable switch. When asserted (`1`), it commands the memory unit to look up the data word at the calculated address and drive it onto the memory output bus.             |
| **`MemWrite`** |   1 bit   |  Output   | Data Memory           | Master write-enable switch. When asserted (`1`), it commands the memory unit to store the data present on the `rs2` data bus into the target address on the next rising clock edge. |

### Operational Truth Table

Because an instruction cannot simultaneously load from and store to memory within the same pipeline stage, these two lines are structurally mutually exclusive:

| Instruction Type    |       Example       | MemRead | MemWrite | Data Memory Action                                                                                            |
| :------------------ | :-----------------: | :-----: | :------: | :------------------------------------------------------------------------------------------------------------ |
| **Load**            |  `lw`, `lb`, `lh`   |  **1**  |  **0**   | **Read Enabled:** Memory reads address from ALU and outputs data word to the Writeback stage.                 |
| **Store**           |  `sw`, `sb`, `sh`   |  **0**  |  **1**   | **Write Enabled:** Memory captures data from `rs2` register and writes it to the address computed by the ALU. |
| **All Other Types** | `add`, `beq`, `jal` |  **0**  |  **0**   | **Disabled / Standby:** Internal memory arrays are isolated; output bus is ignored or tri-stated.             |

### Discrete Driver Gate Formulas

Within the Main Control Decoder, these lines require no complex combinatorial mixing. They are driven directly by the dedicated opcode wire decoders:

```text
MemRead  = Opcode_is_Load
MemWrite = Opcode_is_Store
```

# Writeback Control Logic Configuration (RegWEn & WBSel)

The Writeback Control group regulates how data is committed back into the Register File at the final stage of the instruction lifecycle. Together, **`RegWEn`** and **`WBSel`** ensure that the correct execution result—whether it originates from Data Memory, the ALU, or the program counter logic—is safely routed and saved to the destination register (`rd`) without corrupting architectural state during passive instructions.

### Interface Specification

| Pin / Bus Name   | Bit Width | Destination Component | Functional Purpose                                                                                                                                                                                                   |
| :--------------- | :-------: | :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`RegWEn`**     |   1 bit   | Register File         | **Register Write Enable:** Master gatekeeper pin. When asserted (`1`), the data present on the write-data bus is clocked into the destination register (`rd`). When low (`0`), the register file ignores all inputs. |
| **`WBSel[1:0]`** |  2 bits   | Writeback Multiplexer | **Writeback Source Select:** A 2-bit control bus driving the 3-way multiplexer that selects which execution source connects to the register file's write-data input port.                                            |

### Writeback Multiplexer Routing Table

The selection bus configures the 3-way multiplexer legs based on the data source required by the instruction class:

| WBSel[1:0] Value | Selected Writeback Source            | Target Instruction Classes               |
| :--------------: | :----------------------------------- | :--------------------------------------- |
|   **`00` (0)**   | **Data Memory Output (`Mem`)**       | Memory Loads (`lw`, `lb`, `lh`)          |
|   **`01` (1)**   | **ALU Result (`ALU`)**               | R-Type math, I-Type math, `LUI`, `AUIPC` |
|   **`10` (2)**   | **Sequential PC Address ($PC + 4$)** | Unconditional Jumps (`JAL`, `JALR`)      |
|   **`11` (3)**   | _Reserved / Unused_                  | N/A                                      |

### Decoder Execution Profile

Because `RegWEn` acts as an absolute gatekeeper, instructions that do not write to registers (Stores and Branches) are assigned a "Don't Care" (`XX`) state for `WBSel`, which defaults to `01` to minimize internal decoder gate complexity:

| Instruction Class | Example | RegWEn | WBSel[1:0] | Core Behavioral Action                            |
| :---------------- | :-----: | :----: | :--------: | :------------------------------------------------ |
| **Loads**         |  `lw`   | **1**  |  **`00`**  | Routes Data Memory lookup to `rd`.                |
| **ALU Ops**       | `addi`  | **1**  |  **`01`**  | Routes computed ALU result to `rd`.               |
| **Jumps**         |  `jal`  | **1**  |  **`10`**  | Routes return link address ($PC + 4$) to `rd`.    |
| **Stores**        |  `sw`   | **0**  |  **`01`**  | Register write disabled; memory captures data.    |
| **Branches**      |  `bne`  | **0**  |  **`01`**  | Register write disabled; PC control handles flow. |

### Internal Driver Gate Formulas

Within the Main Control Decoder, these lines are generated cleanly using basic boolean logic paths derived from the opcode validation lines:

#### 1. RegWEn Logic

```text
RegWEn = NOT(Branch OR Store)
```

#### 2. WBSel[1:0] Bus Logic

- **`WBSel[1]` (High Bit):**
  ```text
  WBSel[1] = JAL OR JALR
  ```
- **`WBSel[0]` (Low Bit):**
  ```text
  WBSel[0] = NOT(Load)
  ```

---

# System Instruction Control Logic (Is_Ecall & Is_Ebreak)

The System Instruction Control group handles the detection of architectural environment calls and breakpoints. These signals do not route data through the standard ALU or Memory pipelines; instead, they interface directly with the Control and Status Register (CSR) logic or the processor's exception/trapping interface to transfer control to an operating system kernel, environment monitor, or debugger.

### Interface Specification

| Pin Name        | Bit Width | Direction | Destination Component | Functional Purpose                                                                                                                                                                          |
| :-------------- | :-------: | :-------: | :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`Is_Ecall`**  |   1 bit   |  Output   | CSR / Exception Unit  | **Environment Call Flag:** Asserted high (`1`) when a system call instruction is decoded. Initiates a software interrupt to transition execution from user mode to supervisor/machine mode. |
| **`Is_Ebreak`** |   1 bit   |  Output   | CSR / Debug Unit      | **Environment Breakpoint Flag:** Asserted high (`1`) when a breakpoint instruction is decoded. Halts the processor pipeline or redirects control flow to a debugging monitor.               |

---

### Structural Decoding Context

Both `ecall` and `ebreak` share the standard **SYSTEM** opcode space (`1110011`). To distinguish them from each other—and from standard CSR read/write instructions—the decoder must qualify the opcode by inspecting the extended immediate fields located in bits 31 down to 20 of the raw instruction register.

| Instruction                 |   Opcode[6:0]    |    funct3    | Instruction[31:20] (Hex) | Is_Ecall | Is_Ebreak |
| :-------------------------- | :--------------: | :----------: | :----------------------: | :------: | :-------: |
| **`ecall`**                 |    `1110011`     |    `000`     |         `0x000`          |  **1**   |   **0**   |
| **`ebreak`**                |    `1110011`     |    `000`     |         `0x001`          |  **0**   |   **1**   |
| **CSR Ops** (`csrrw`, etc.) |    `1110011`     | $\neq$ `000` |       CSR Address        |  **0**   |   **0**   |
| **All Other Opcodes**       | $\neq$ `1110011` |      X       |            X             |  **0**   |   **0**   |

### Internal Driver Gate Formulas

To isolate these individual signals inside the Main Control Decoder without running massive 32-bit comparison blocks, the combinational paths first confirm the `SYSTEM` opcode and a blank `funct3` field, then split using bit 20 of the instruction register:

```text
System_Op_Valid = Opcode_is_System AND (funct3 == 000)

Is_Ecall  = System_Op_Valid AND NOT(Instruction[20])
Is_Ebreak = System_Op_Valid AND Instruction[20]
```

### Pipeline State Impact

When either `Is_Ecall` or `Is_Ebreak` is asserted high, the Main Control Decoder overrides the standard back-end pipeline enables:

- **`RegWEn`** is forced to `0` (system traps do not write to the register file).
- **`MemWrite`** and **`MemRead`** are forced to `0` (memory subsystems remain isolated).
- **Pipeline Flush:** The control block uses these signals to freeze or flush instructions currently in flight behind the system call to ensure exception tracking precision.
