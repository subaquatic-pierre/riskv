# Data Memory

# Component: Store Mask Generator / Byte Enable Decoder

## Description

Generates a 4-bit write-mask/byte-enable signal (`Mask[3:0]`) to selectively activate the appropriate byte lanes within the 32-bit word-addressed RAM unit. This component supports aligned sub-word configurations and handles unaligned mid-word boundary writes while capping boundary-crossing operations to the final lane.

---

## 1. Inputs & Outputs

### Inputs

- **`Addr[1:0]`**: The 2 lowest bits of the effective target memory address.
- **`MemByteSel[2:0]`**: 3-bit control signal bus driven by the Main Control Decoder.
  - `MemByteSel[1]` = Half-word flag (`funct3[0]`)
  - `MemByteSel[2]` = Full-word flag (`funct3[1]`)

### Outputs

- **`Mask[3:0]`**: 4-bit byte-enable output bus routed directly to the RAM selection/mask pins.
  - `Mask[3]` $\rightarrow$ Controls RAM Byte Lane 3 (Bits `[31:24]`)
  - `Mask[2]` $\rightarrow$ Controls RAM Byte Lane 2 (Bits `[23:16]`)
  - `Mask[1]` $\rightarrow$ Controls RAM Byte Lane 1 (Bits `[15:8]`)
  - `Mask[0]` $\rightarrow$ Controls RAM Byte Lane 0 (Bits `[7:0]`)

---

## 2. Hardware Operational Truth Table

| Instruction Class    | MemByteSel[2] (Word) | MemByteSel[1] (Half) | Addr[1] | Addr[0] | Mask[3] (Byte 3) | Mask[2] (Byte 2) | Mask[1] (Byte 1) | Mask[0] (Byte 0) | Target Operation / Logic Behavior                 |
| :------------------- | :------------------: | :------------------: | :-----: | :-----: | :--------------: | :--------------: | :--------------: | :--------------: | :------------------------------------------------ |
| **Byte (`sb`)**      |          0           |          0           |    0    |    0    |      **1**       |        0         |        0         |        0         | Store Byte at Offset 00                           |
| **Byte (`sb`)**      |          0           |          0           |    0    |    1    |        0         |      **1**       |        0         |        0         | Store Byte at Offset 01                           |
| **Byte (`sb`)**      |          0           |          0           |    1    |    0    |        0         |        0         |      **1**       |        0         | Store Byte at Offset 10                           |
| **Byte (`sb`)**      |          0           |          0           |    1    |    1    |        0         |        0         |        0         |      **1**       | Store Byte at Offset 11                           |
| **Half-word (`sh`)** |          0           |          1           |    0    |    0    |      **1**       |      **1**       |        0         |        0         | Aligned Upper Half-word                           |
| **Half-word (`sh`)** |          0           |          1           |    0    |    1    |        0         |      **1**       |      **1**       |        0         | Unaligned Mid Half-word                           |
| **Half-word (`sh`)** |          0           |          1           |    1    |    0    |        0         |        0         |      **1**       |      **1**       | Aligned Lower Half-word                           |
| **Half-word (`sh`)** |          0           |          1           |    1    |    1    |        0         |        0         |        0         |      **1**       | Word Boundary Limit (Programmer Error: Drops LSB) |
| **Full Word (`sw`)** |          1           |          0           |    X    |    X    |      **1**       |      **1**       |      **1**       |      **1**       | Store Full Word (All Lanes)                       |

---

## 3. Gate Implementation Formulas

The resulting optimal combinational logic equations to implement this logic gate array:

```text
Signal Conditioning:
Is_Word = MemByteSel[2]
Is_Half = MemByteSel[1]
Is_Byte = NOT(MemByteSel[2]) AND NOT(MemByteSel[1])

Logic Equations:
Mask[3] = W OR (~A1 AND (~A0 AND B OR H))
Mask[2] = W OR (~A1 AND (A0 AND B OR ~A0 AND H))
Mask[1] = W OR (A1 AND ~A0 AND B) OR (H AND (A1 XOR A0))
Mask[0] = W OR (A1 AND (A0 AND B OR H))
```

### Factored Hardware Form (Best for Minimal Gate Count)

If you are wire-budgeting your canvas to use the absolute minimum number of logic gates, you can factor out common terms (like `~A1` and `A1`).

By grouping the sub-word variables, the final hardware gate configurations simplify to:

- `Mask[3] = W OR (~A1 AND (~A0 AND B OR H))`
- `Mask[2] = W OR (~A1 AND (A0 AND B OR ~A0 AND H))`
- `Mask[1] = W OR (A1 AND ~A0 AND B) OR (H AND (A1 XOR A0))`
- `Mask[0] = W OR (A1 AND (A0 AND B OR H))`

### Logisim Implementation Tips

- **Use a 3-input OR gate** at the final output stage of each mask bit, tying the full-word command line (`W`) directly to the top pin of each gate.

# Component: Byte / Word Selector

## Description

Pre-processes 32-bit raw word data read from a word-addressed RAM unit. It handles sub-word alignment by shifting the target byte or half-word into the least significant bit (LSB) positions based on the lower two bits of the calculated ALU address, then performs parallel extension.

### Data Bus to Byte Offset Mapping

Because the word architecture maps address offsets in descending order relative to the 32-bit data bus lanes:

- **Addr[1:0] = 00** $\rightarrow$ Targets Byte 3 (Bits `[31:24]`) $\rightarrow$ Requires 24-bit R-Shift
- **Addr[1:0] = 01** $\rightarrow$ Targets Byte 2 (Bits `[23:16]`) $\rightarrow$ Requires 16-bit R-Shift
- **Addr[1:0] = 10** $\rightarrow$ Targets Byte 1 (Bits `[15:8]`) $\rightarrow$ Requires 8-bit R-Shift
- **Addr[1:0] = 11** $\rightarrow$ Targets Byte 0 (Bits `[7:0]`) $\rightarrow$ Requires 0-bit R-Shift

---

## 1. Inputs & Outputs

### Inputs

- **`dataIn[31:0]`**: Raw 32-bit word directly from Logisim RAM output.
- **`Addr[1:0]`**: The 2 lowest bits of the calculated effective memory address.
- **`sel[2:0]`**: 3-bit control signal mapped directly from the main controller decoder.
  - `sel[0]` = `funct3[2]` (Unsigned flag)
  - `sel[1]` = `funct3[0]` (Half-word flag)
  - `sel[2]` = `funct3[1]` (Full-word flag)

### Outputs

- **`dataOut[31:0]`**: Fully aligned and sign/zero-extended 32-bit output.

---

## 2. Internal Schematic & Routing Logic

### Stage 1: Shift Amount Calculation

- **Logic**: Inverts `Addr[1:0]` to swap the layout dependency, then shifts the value left by 3 bits (by appending three trailing zeros) to scale the byte offset into a bit-shift offset.
- **Mapping**:
  - `00` $\rightarrow$ `5'b11000` (24 bits)
  - `01` $\rightarrow$ `5'b10000` (16 bits)
  - `10` $\rightarrow$ `5'b01000` (8 bits)
  - `11` $\rightarrow$ `5'b00000` (0 bits)

### Stage 2: Pre-Alignment Shift

- **Logic**: A 32-bit logical right shifter uses the calculated 5-bit shift amount to dynamically slide the target segment down to the `[7:0]` (byte) or `[15:0]` (half-word) boundaries.

### Stage 3: Parallel Splitting and Extension

- **Logic**: The aligned data bus forks simultaneously into narrow splitters and extension logic blocks:
  - Bits `[7:0]` run to a sign extender and a zero extender.
  - Bits `[15:0]` run to a sign extender and a zero extender.

### Stage 4: Final Selection (8-to-1 Multiplexer)

- **Logic**: An 8-to-1 multiplexer selects the final output configuration. The 3-bit `sel[2:0]` control bus wires directly to the multiplexer selection port, mapping the hardware paths cleanly to the corresponding operations:
  - `000` $\rightarrow$ Signed Byte (`funct3` = `000`)
  - `001` $\rightarrow$ Unsigned Byte (`funct3` = `100`)
  - `010` $\rightarrow$ Signed Half-Word (`funct3` = `001`)
  - `011` $\rightarrow$ Unsigned Half-Word (`funct3` = `101`)
  - `100` $\rightarrow$ Raw Full Word (`funct3` = `010`, Bypasses Stage 2 entirely)

# Component: Store Aligner

## Description

Processes 32-bit data payloads from the register file and configuration signals from the controller before memory writes. It aligns sub-word data (`sb`, `sh`) to the correct byte lanes of a 32-bit wide memory bus based on a 2-bit address offset.

It also contains the **Store Mask Generator**. While the aligner shifts the data bits into the correct slots on the 32-bit bus, the mask generator drives the RAM's write enable lines (`WriteMask[3:0]`) so only the targeted byte lanes update in memory.

### Data Bus to Byte Offset Mapping

Because this 32-bit Big-Endian architecture maps address offsets in descending order relative to the data bus lanes, the right-aligned register data must shift upward to its destination segment:

- **AddrOffset[1:0] = 00** $\rightarrow$ Targets Byte 3 (Bits `[31:24]`) $\rightarrow$ Requires 24-bit L-Shift
- **AddrOffset[1:0] = 01** $\rightarrow$ Targets Byte 2 (Bits `[23:16]`) $\rightarrow$ Requires 16-bit L-Shift
- **AddrOffset[1:0] = 10** $\rightarrow$ Targets Byte 1 (Bits `[15:8]`) $\rightarrow$ Requires 8-bit L-Shift
- **AddrOffset[1:0] = 11** $\rightarrow$ Targets Byte 0 (Bits `[7:0]`) $\rightarrow$ Requires 0-bit L-Shift

---

## 1. Inputs & Outputs

### Inputs

- **`DataFromRegisterFile[31:0]`**: Raw 32-bit data from register file source (`rs2`).
- **`AddrOffset[1:0]`**: The 2 lowest bits of the calculated effective memory address.
- **`ByteSel`**: Control lines from the main controller decoder:
  - `ByteSel[0]` (`indicates unsigned loads, used in LoadAligner`)
  - `ByteSel[1]` (High for `sh`)
  - `ByteSel[2]` (High for `sw`)

### Outputs

- **`AlignedDataToMemory[31:0]`**: Shifted data connected to the RAM module data input.
- **`WriteMask[3:0]`**: 4-bit byte write-enable mask connected to the RAM lane enable inputs.

---

## 2. Internal Schematic & Routing Logic

### Stage 1: Exception Detection (Misalignment Flag)

- **Logic**: Detects an unaligned half-word operation spanning internal boundaries. This flag goes high only when the offset is `01` during a half-word store instruction while a full word write is low.
- **Equation**:
  $$\text{mis\_align} = \text{AddrOffset}[0] \ \text{AND} \ \sim\text{AddrOffset}[1] \ \text{AND} \ \text{Half} \ \text{AND} \ \sim\text{Word}$$

### Stage 2: Shift Amount Calculation (`shamt[4:0]`)

- **Logic**: Maps the address and control signals into a 5-bit shift distance vector using pure gate logic instead of multiplexers. When the misalignment flag is high, it forces an 8-bit shift, overriding the standard calculation.
- **Equations**:
  - `shamt[4]` = $(\sim\text{AddrOffset}[1] \ \text{AND} \ \sim\text{Word}) \ \text{AND} \ \sim\text{mis\_align}$
  - `shamt[3]` = $(\sim\text{AddrOffset}[0] \ \text{AND} \ \text{Byte} \ \text{AND} \ \sim\text{Word}) \ \text{OR} \ \text{mis\_align}$
  - `shamt[2:0]` = $3'\text{b000}$ (Permanently grounded; shifts are always multiples of 8 bits)

### Stage 3: Spatial Left-Shifting

- **Logic**: A 32-bit logical left barrel shifter takes the raw data from the register file and shifts it up using the calculated 5-bit `shamt[4:0]` vector. Full word operations set the shift amount to zero, passing the register data through unchanged.

### Stage 4: Write Mask Generation

- **Logic**: Runs the integrated `StoreMaskGenerator` logic in parallel with the data shifter. It maps `AddrOffset[1:0]` and the instruction width signals to drive individual RAM write authorization pins (`WriteMask[3:0]`). This prevents data overwrites in non-targeted byte fields.
- **Mapping**:
  - `sw` $\rightarrow$ `4'b1111`
  - `sb` at `00`/`01`/`10`/`11` $\rightarrow$ `4'b1000` / `4'b0100` / `4'b0010` / `4'b0001`
  - `sh` at `00`/`01`/`10` $\rightarrow$ `4'b1100` / `4'b0110` / `4'b0011`

```

```
