# MainControlDecoder Architecture Overview

The **MainControlDecoder** reads raw instructions from memory and drives the control signals and buses required to steer data through the processor.

---

### Control Signal Canvas Mapping

```text
+-----------------------------------------------------------------------+
|                         MAIN CONTROL DECODER                          |
+-----------------------------------------------------------------------+
   |                                                                 |
   |-- [ID_Control]   --> ImmSel[2:0]                                |
   |                                                                 |
   |-- [EX_Control]   --> ASel, BSel, ALUSel[3:0], BrSel[4:0]        |
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

| Canvas Group     | Signal / Bus Name | Bit Width | Destination Block   | Functional Description                                                                                                              |
| :--------------- | :---------------- | :-------: | :------------------ | :---------------------------------------------------------------------------------------------------------------------------------- |
| **ID_Control**   | `ImmSel[2:0]`     |     3     | Immediate Generator | Selects immediate unpacking and formatting type based on instruction format.                                                        |
| **EX_Control**   | `ASel`            |     1     | Multiplexer A       | Selects ALU Input A: Register Port 1 (`0`) or Program Counter (`1`).                                                                |
|                  | `BSel`            |     1     | Multiplexer B       | Selects ALU Input B: Register Port 2 (`0`) or Immediate (`1`).                                                                      |
|                  | `ALUSel[3:0]`     |     4     | Execution ALU       | Combines `funct3` and `Instruction[30]` to command ALU operations. Gated to `0000` (`ADD`) for non-arithmetic instructions.         |
|                  | `BrSel[4:0]`      |     5     | Branch Controller   | Composite Bus: `[4:2]` maps `funct3`, `[1]` gates conditional branches (`Is_Branch`), `[0]` forces unconditional jumps (`Is_Jump`). |
| **MEM_Control**  | `MemRead`         |     1     | Data Memory (RAM)   | Read-enable switch; active only during Load instructions.                                                                           |
|                  | `MemWrite`        |     1     | Data Memory (RAM)   | Write-enable switch; active only during Store instructions.                                                                         |
| **WB_Control**   | `RegWEn`          |     1     | Register File       | Master register write enable. Active high for instructions writing to register `rd`.                                                |
|                  | `WBSel[1:0]`      |     2     | Writeback MUX       | Selects writeback source: Data Memory (`00`), ALU Result (`01`), or Sequential PC Address $PC + 4$ (`11`).                          |
| **Trap_Control** | `Is_Ecall`        |     1     | Exception Unit      | Asserts high on environment call (`ecall`) to invoke system trap.                                                                   |
|                  | `Is_Ebreak`       |     1     | Debug Unit          | Asserts high on breakpoint (`ebreak`) to halt for debugger.                                                                         |

---

### Master Instruction Definitions

| Instruction Type | Opcode (Binary) | Opcode (Hex) | Description / Example                         |
| :--------------- | :-------------- | :----------- | :-------------------------------------------- |
| **R_Type**       | `0110011`       | `0x33`       | Register-Register Math (`add`, `sub`, `slt`)  |
| **I_type**       | `0010011`       | `0x13`       | Register-Immediate Math (`addi`, `slti`)      |
| **Load**         | `0000011`       | `0x03`       | Load Data from RAM to Register (`lw`)         |
| **Store**        | `0100011`       | `0x23`       | Store Data from Register to RAM (`sw`)        |
| **Branch**       | `1100011`       | `0x63`       | Conditional PC Jump (`beq`, `bne`)            |
| **JAL**          | `1101111`       | `0x6F`       | Jump and Link Unconditional (`jal`)           |
| **JALR**         | `1100111`       | `0x67`       | Jump and Link Register Indirect (`jalr`)      |
| **AUIPC**        | `0010111`       | `0x17`       | Add Upper Immediate to PC (`auipc`)           |
| **LUI**          | `0110111`       | `0x37`       | Load Upper Immediate (`lui`)                  |
| **System**       | `1110011`       | `0x73`       | Environment Calls / Traps (`ecall`, `ebreak`) |

---

### Processor Execution Flow

1. **Fetch (IF):** PC outputs next instruction address to Instruction Memory.
2. **Decode (ID):** Opcode defines `ImmSel` format. Remaining control signals and bus layouts are resolved concurrently.
3. **Execute (EX):** `ASel` and `BSel` route inputs to the ALU; `ALUSel` defines operation. `BrSel` assesses branch/jump conditions.
4. **Memory (MEM):** `MemRead` or `MemWrite` triggers for Loads/Stores. Bypassed for standard arithmetic.
5. **Writeback (WB):** `WBSel` routes the chosen data block to the Register File, committed via `RegWEn`.

---

# ImmSel (Immediate Select) Logic Configuration

### ImmSel Multiplexer Routing Table

| ImmSel[2:0] Value | Selected Immediate Format | Target Instruction Types                            |
| :---------------: | :------------------------ | :-------------------------------------------------- |
|    **000 (0)**    | **IType**                 | Standard ALU Immediates, Memory Loads, JALR, System |
|    **001 (1)**    | **SType**                 | Memory Stores (`sw`, `sb`, `sh`)                    |
|    **010 (2)**    | **BType**                 | Conditional Branches (`beq`, `bne`, `blt`, `bge`)   |
|    **011 (3)**    | **UType**                 | Upper Immediates (`lui`, `auipc`)                   |
|    **100 (4)**    | **JType**                 | Unconditional Long Jumps (`jal`)                    |

### Driver Gate Formulas

```text
ImmSel[0] = Store OR LUI OR AUIPC
ImmSel[1] = Branch OR LUI OR AUIPC
ImmSel[2] = JAL
```

---

# ASel (ALU Input A Select) Logic Configuration

### ASel Multiplexer Routing Table

| ASel Pin Value | Selected ALU Input A Source    | Target Instruction Classes                   |
| :------------: | :----------------------------- | :------------------------------------------- |
|     **0**      | **Register File Port 1 (rs1)** | RType, IType, Load, Store, JALR, LUI, System |
|     **1**      | **Program Counter (PC)**       | AUIPC, Branch, JAL                           |

### Driver Gate Formula

```text
ASel = AUIPC OR Branch OR JAL
```

---

# BSel (ALU Input B Select) Logic Configuration

### BSel Multiplexer Routing Table

| BSel Pin Value | Selected ALU Input B Source          | Target Instruction Classes                        |
| :------------: | :----------------------------------- | :------------------------------------------------ |
|     **0**      | **Register File Port 2 (rs2)**       | RType, System                                     |
|     **1**      | **Immediate Generator Output (Imm)** | IType, Load, Store, AUIPC, LUI, JAL, JALR, Branch |

### Driver Gate Formula

```text
BSel = IType OR Load OR Store OR AUIPC OR LUI OR JAL OR JALR OR Branch
```

---

# ALUSel (ALU Operation Select) Logic Configuration

### ALUSel Bus Bit Mapping

The 4-bit `ALUSel[3:0]` bus handles ALU operation routing. It is derived from `funct3` and `Instruction[30]`. Non-arithmetic operations are masked to `0000` (`ADD`). Shift-right immediates (`srli`/`srai`) use an exception gate to preserve the `Instruction[30]` modifier bit from being treated as raw numerical data.

|     Bus Bit     | Gated Source Component Mapping                     | Functional Purpose / Behavior              |
| :-------------: | :------------------------------------------------- | :----------------------------------------- |
| **`ALUSel[3]`** | `Instruction[14]` AND (`R_Type` OR `I_Type`)       | High bit of operation code.                |
| **`ALUSel[2]`** | `Instruction[13]` AND (`R_Type` OR `I_Type`)       | Middle bit of operation code.              |
| **`ALUSel[1]`** | `Instruction[12]` AND (`R_Type` OR `I_Type`)       | Low bit of operation code.                 |
| **`ALUSel[0]`** | `Instruction[30]` AND (`R_Type` OR `IShift_Right`) | Modifier bit (`add`/`sub`, `srli`/`srai`). |

### Driver Gate Formulas

```text
Is_Arithmetic = R_Type OR I_Type
IShift_Right  = I_Type AND Instruction[14] AND NOT(Instruction[13]) AND Instruction[12]
ALUSel_Mod_Gate = R_Type OR IShift_Right

ALUSel[3] = Instruction[14] AND Is_Arithmetic
ALUSel[2] = Instruction[13] AND Is_Arithmetic
ALUSel[1] = Instruction[12] AND Is_Arithmetic
ALUSel[0] = Instruction[30] AND ALUSel_Mod_Gate
```

---

# BrSel (Branch Operation Select) Logic Configuration

## BrSel Bus Bit Mapping

The 5-bit `BrSel[4:0]` bus governs program counter updates by managing conditional branch verification and unconditional jump overrides.

|    Bus Bit     | Source Component Mapping         | Functional Purpose / Behavior                                             |
| :------------: | :------------------------------- | :------------------------------------------------------------------------ |
| **`BrSel[4]`** | `funct3[2]`                      | High condition select bit (signed/unsigned and equality bounds).          |
| **`BrSel[3]`** | `funct3[1]`                      | Middle condition select bit.                                              |
| **`BrSel[2]`** | `funct3[0]`                      | Low condition select bit.                                                 |
| **`BrSel[1]`** | `MainController (Branch Signal)` | Validation gate. Asserted high (`1`) exclusively for B-Type opcodes.      |
| **`BrSel[0]`** | `MainController (Jump Signal)`   | Unconditional jump override. Asserted high (`1`) for JAL or JALR opcodes. |

### Driver Gate Formulas

```text
BrSel[4] = funct3[2]
BrSel[3] =funct3[1]
BrSel[2] = funct3[0]
BrSel[1] = Branch
BrSel[0] = JAL OR JALR
```

---

# Memory Control Logic Configuration (MemRead & MemWrite)

### Interface Specification

| Pin Name       | Bit Width | Destination Component | Functional Description                                |
| :------------- | :-------: | :-------------------- | :---------------------------------------------------- |
| **`MemRead`**  |     1     | Data Memory           | Master read enable. Asserted for Load instructions.   |
| **`MemWrite`** |     1     | Data Memory           | Master write enable. Asserted for Store instructions. |

### Operational Truth Table

| Instruction Type    | MemRead | MemWrite | Subsystem Action                                           |
| :------------------ | :-----: | :------: | :--------------------------------------------------------- |
| **Load**            |  **1**  |  **0**   | Reads from address generated by ALU to writeback stage.    |
| **Store**           |  **0**  |  **1**   | Writes data from `rs2` to target address generated by ALU. |
| **All Other Types** |  **0**  |  **0**   | Memory array isolated; output bus ignored.                 |

### Driver Gate Formulas

```text
MemRead  = Load
MemWrite = Store
```

---

# Writeback Control Logic Configuration (RegWEn & WBSel)

### Interface Specification

| Pin / Bus Name   | Bit Width | Destination Component | Functional Description                                   |
| :--------------- | :-------: | :-------------------- | :------------------------------------------------------- |
| **`RegWEn`**     |     1     | Register File         | Master write enable. High commits data to register `rd`. |
| **`WBSel[1:0]`** |     2     | Writeback MUX         | Routes selected data source back to the register file.   |

### Writeback Multiplexer Routing Table

| WBSel[1:0] Value | Selected Writeback Source            | Target Instruction Classes                                |
| :--------------: | :----------------------------------- | :-------------------------------------------------------- |
|   **`00` (0)**   | **Data Memory Output (`Mem`)**       | Memory Loads (`lw`, `lb`, `lh`)                           |
|   **`01` (1)**   | **ALU Result (`ALU`)**               | R-Type, I-Type, `LUI`, `AUIPC`, Non-writing ops (default) |
|   **`11` (3)**   | **Sequential PC Address ($PC + 4$)** | Unconditional Function Jumps (`JAL`, `JALR`)              |

### Driver Gate Formulas

```text
RegWEn   = R_Type OR I_Type OR Load OR JAL OR JALR OR AUIPC OR LUI
WBSel[1] = JAL OR JALR
WBSel[0] = NOT(Load)
```

---

# System Instruction Control Logic (Is_Ecall & Is_Ebreak)

### Operational Matrix

Both instructions share the `SYSTEM` opcode (`1110011`) and a zeroed `funct3` field. They are differentiated by checking instruction bit 20.

| Instruction   | Opcode[6:0] |    funct3    | Instruction[31:20] | Is_Ecall | Is_Ebreak |
| :------------ | :---------: | :----------: | :----------------: | :------: | :-------: |
| **`ecall`**   |  `1110011`  |    `000`     |      `0x000`       |  **1**   |   **0**   |
| **`ebreak`**  |  `1110011`  |    `000`     |      `0x001`       |  **0**   |   **1**   |
| **CSR/Other** |  `1110011`  | $\neq$ `000` |    CSR Address     |  **0**   |   **0**   |

### Driver Gate Formulas

```text
System_Op_Valid = System AND (funct3 == 000)

Is_Ecall  = System_Op_Valid AND NOT(Instruction[20])
Is_Ebreak = System_Op_Valid AND Instruction[20]
```

### Pipeline Safeguards

When either exception flag goes high, `RegWEn`, `MemRead`, and `MemWrite` are driven to `0` to isolate memory structures and halt illegal state modification before a pipeline flush executes.
