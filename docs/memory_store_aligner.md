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
