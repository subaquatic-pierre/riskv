# Hazard and Forwarding Controller Specification

The **HazardController** is a centralized, combinational control unit responsible for maintaining data and control integrity within the 5-stage pipelined RISC-V processor. It dynamically resolves **Data Hazards** (ALU-to-ALU dependencies, Load-Use dependencies) and **Control Hazards** (taken branches/jumps) by managing pipeline register states and routing bypass data.

---

## Block Diagram & Interface

```text
                      +-------------------+
   IF_ID_rs1 -------->|                   |----> PC_WE
   IF_ID_rs2 -------->|                   |----> IF_ID_WE
   ID_EX_rs1 -------->|                   |----> IF_ID_Flush
   ID_EX_rs2 -------->|  HazardController |----> ID_EX_Flush
   ID_EX_rdi -------->|                   |----> FWD_A[1:0]
   EX_MEM_rdi ------->|                   |----> FWD_B[1:0]
   MEM_WB_rdi ------->|                   |
   ID_EX_MemRead ---->|                   |
   EX_MEM_RegWEn ---->|                   |
   MEM_WB_RegWEn ---->|                   |
   PCSel ------------>|                   |
                      +-------------------+
```

### Pin Definitions

| Signal Name         | Direction | Width | Description                                                                                     |
| :------------------ | :-------: | :---: | :---------------------------------------------------------------------------------------------- |
| `IF_ID_rs1` / `rs2` |   Input   |   5   | Source registers of the instruction currently in the Decode stage.                              |
| `ID_EX_rs1` / `rs2` |   Input   |   5   | Source registers of the instruction currently in the Execute stage.                             |
| `ID_EX_rdi`         |   Input   |   5   | Destination register of the instruction 1 cycle ahead (EX).                                     |
| `EX_MEM_rdi`        |   Input   |   5   | Destination register of the instruction 2 cycles ahead (MEM).                                   |
| `MEM_WB_rdi`        |   Input   |   5   | Destination register of the instruction 3 cycles ahead (WB).                                    |
| `ID_EX_MemRead`     |   Input   |   1   | Asserted if the instruction in the EX stage is a Load instruction.                              |
| `EX_MEM_RegWEn`     |   Input   |   1   | Asserted if the instruction in the MEM stage writes to the Register File.                       |
| `MEM_WB_RegWEn`     |   Input   |   1   | Asserted if the instruction in the WB stage writes to the Register File.                        |
| `PCSel`             |   Input   |   1   | Asserted if a branch is taken or a jump occurs in the EX stage.                                 |
| `PC_WE`             |  Output   |   1   | Write Enable for the Program Counter register ($1 = \text{normal}$, $0 = \text{freeze}$).       |
| `IF_ID_WE`          |  Output   |   1   | Write Enable for the Fetch/Decode pipeline register ($1 = \text{normal}$, $0 = \text{freeze}$). |
| `IF_ID_Flush`       |  Output   |   1   | Synchronous clear for the Fetch/Decode pipeline register (inserts NOP).                         |
| `ID_EX_Flush`       |  Output   |   1   | Synchronous clear for the Decode/Execute pipeline register (inserts NOP).                       |
| `FWD_A` / `FWD_B`   |  Output   |   2   | Selection lines for the 3-way ALU input multiplexers in the EX stage.                           |

---

## Theory of Operation

The module executes two parallel architectural routines every clock cycle: **Pipeline Interlock Logic** (Stalls/Flushes) and **Data Bypassing Logic** (Forwarding).

### 1. Data Bypassing (Forwarding)

To avoid stalling on ALU-to-ALU instructions, data is intercepted from downstream stages before it is formally committed back to the structural Register File.

The selection priority is hard-wired to prefer the **EX/MEM** stage over the **MEM/WB** stage. This structural constraint guarantees that if back-to-back instructions write to the same destination register, the ALU always receives the newest chronological value.

#### Mux Encoding

- **`2'b00`**: No hazard. Selects the standard operands out of the `ID_EX` pipeline register.
- **`2'b01`**: Forward from `EX_MEM`. Intercepts the ALU output from 1 cycle ahead. Structural pipeline rules guarantee that if an instruction reaches the MEM stage with `RegWEn` active without triggering a stall or a flush, it is natively an ALU operation.
- **`2'b10`**: Forward from `MEM_WB`. Intercepts the final output of the write-back multiplexer from 2 cycles ahead, handling resolved ALU results, loads, and jumps.

### 2. Pipeline Interlocks (Stalls & Flushes)

- **Load-Use Hazard:** Data requested from an external memory load (`lw`) is not physically valid until the instruction exits the MEM stage. If an instruction in Decode depends on an active load in Execute, the controller drops write enables to freeze the PC and ID stages while flushing the EX stage to insert a 1-cycle bubble.
- **Control Hazard:** If a branch is evaluated as taken or a jump instruction executes (`PCSel = 1`), instructions fetched in the shadow of that jump are invalid. The controller asserts both flushes to clean out the pipeline.

---

## Behavioral Logic Implementation

```text
// ==========================================
// 1. FORWARDING LOGIC (INPUT A)
// ==========================================
EX_MEM_Hazard_A = EX_MEM_RegWEn AND (EX_MEM_rdi != 0) AND (EX_MEM_rdi == ID_EX_rs1);
MEM_WB_Hazard_A = MEM_WB_RegWEn AND (MEM_WB_rdi != 0) AND (MEM_WB_rdi == ID_EX_rs1);

FWD_A[0] = EX_MEM_Hazard_A;
FWD_A[1] = MEM_WB_Hazard_A AND (NOT EX_MEM_Hazard_A); // EX_MEM takes priority

// ==========================================
// 2. FORWARDING LOGIC (INPUT B)
// ==========================================
EX_MEM_Hazard_B = EX_MEM_RegWEn AND (EX_MEM_rdi != 0) AND (EX_MEM_rdi == ID_EX_rs2);
MEM_WB_Hazard_B = MEM_WB_RegWEn AND (MEM_WB_rdi != 0) AND (MEM_WB_rdi == ID_EX_rs2);

FWD_B[0] = EX_MEM_Hazard_B;
FWD_B[1] = MEM_WB_Hazard_B AND (NOT EX_MEM_Hazard_B); // EX_MEM takes priority

// ==========================================
// 3. STALL & FLUSH LOGIC
// ==========================================
Load_Use_Stall = ID_EX_MemRead AND (ID_EX_rdi != 0) AND ((ID_EX_rdi == IF_ID_rs1) OR (ID_EX_rdi == IF_ID_rs2));

if (Load_Use_Stall) {
    PC_WE       = 0;  // Freeze Program Counter
    IF_ID_WE    = 0;  // Freeze Decode Stage
    IF_ID_Flush = 0;
    ID_EX_Flush = 1;  // Inject NOP into Execute Stage
}
else if (PCSel) {
    PC_WE       = 1;
    IF_ID_WE    = 1;
    IF_ID_Flush = 1;  // Flush instruction currently decoding
    ID_EX_Flush = 1;  // Flush instruction currently executing
}
else {
    PC_WE       = 1;  // Normal execution flow
    IF_ID_WE    = 1;
    IF_ID_Flush = 0;
    ID_EX_Flush = 0;
}
```
