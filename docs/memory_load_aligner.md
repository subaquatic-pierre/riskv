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
