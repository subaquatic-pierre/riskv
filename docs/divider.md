# Division and Remainder Unit Documentation

## Overview

This hardware module implements the division and remainder operations for the RISC-V **M-Extension** (`div`, `divu`, `rem`, `remu`).

To minimize silicon area, the architecture shares a **single 32-bit unsigned division core** that expects strictly non-negative magnitudes. Signed operations are supported by wrapping the core with low-overhead, conditional pre-processing and post-processing mathematical negation blocks.

---

## Signal Interfaces

### Input Ports

- `dataA` (32-bit): Dividend input bus.
- `dataB` (32-bit): Divisor input bus.
- `sel` (3-bit): Control bus mapped directly from the instruction's `funct3` fields.

### Output Ports

- `out` (32-bit): The final calculated result, routed to the CPU register file.

---

## Control Mapping (`sel` / `funct3`)

The module uses the 3-bit `sel` bus to decode the exact operation and coordinate both the pre/post-processing stages and the final output selection multiplexer.

| `sel` (`funct3`) | Instruction | Operation Type     | Pre/Post-Correction | Output Mux Source   |
| :--------------- | :---------- | :----------------- | :------------------ | :------------------ |
| `3'b100`         | `div`       | Signed Division    | Enabled             | Corrected Quotient  |
| `3'b101`         | `divu`      | Unsigned Division  | Bypassed            | Raw Core Quotient   |
| `3'b110`         | `rem`       | Signed Remainder   | Enabled             | Corrected Remainder |
| `3'b111`         | `remu`      | Unsigned Remainder | Bypassed            | Raw Core Remainder  |

---

## Architectural Pipeline

Because integer division is non-linear, the two's complement representation of negative numbers cannot be easily corrected after a raw unsigned division. The division pipeline uses a three-stage topology:

### 1. Pre-Processing Stage (Sign Stripping)

Before entering the unsigned division core, negative signed inputs must be converted into absolute positive magnitudes. This is achieved using a conditional two's complement negation block for each input.

The architecture implements negation by performing a bitwise Exclusive-OR (XOR) with a sign-extended mask and adding the sign bit via the adder's carry-in:

$$\text{Core Input} = 0 + (\text{Data} \oplus \text{signExt}) + \text{sign}$$

- **Dividend Pre-Correction (`dataA`):**
  - `signA` = `dataA[31]`
  - `signAExt` = Replicated `signA` across a 32-bit bus.
  - Vector fed to core: `dataA_pos = 32'h0 + (dataA ^ signAExt) + signA`
- **Divisor Pre-Correction (`dataB`):**
  - `signB` = `dataB[31]`
  - `signBExt` = Replicated `signB` across a 32-bit bus.
  - Vector fed to core: `dataB_pos = 32'h0 + (dataB ^ signBExt) + signB`

_Note: For `divu` and `remu`, the control logic forces `signAExt` and `signBExt` to zero and drops the carry-in, passing the raw inputs directly to the core._

### 2. Unsigned Division Core

The shared core takes `dataA_pos` and `dataB_pos` and processes the division over its fixed or variable execution cycles. It drops out two positive 32-bit results simultaneously:

- `unsigned_quotient`
- `unsigned_remainder`

### 3. Post-Processing Stage (Sign Restoration)

Once the core finishes execution, the output values pass through a final layer of conditional negation adders to apply the signed representation attributes required by the RISC-V ISA specification.

#### Quotient Correction (`div`)

The quotient must be negative if, and only if, the signs of the two original inputs differ.

- **Control Signal (`signQ`):** Evaluated via a bitwise XOR of the input sign bits:
  $$\text{signQ} = \text{signA} \oplus \text{signB}$$
- **Correction Matrix:** `signQExt` is generated from `signQ`. The final signed quotient is calculated as:
  $$\text{Final Quotient} = 32'h0 + (\text{unsigned\_quotient} \oplus \text{signQExt}) + \text{signQ}$$

#### Remainder Correction (`rem`)

Per the RISC-V standard, the remainder must always inherit the sign of the original dividend (`dataA`), completely independent of the divisor's sign.

- **Control Signal (`signR`):** Inherited directly from the dividend sign:
  $$\text{signR} = \text{signA}$$
- **Correction Matrix:** `signRExt` (which is identical to `signAExt`) is used to mask the remainder. The final signed remainder is calculated as:
  $$\text{Final Remainder} = 32'h0 + (\text{unsigned\_remainder} \oplus \text{signRExt}) + \text{signR}$$

---

## Output Interconnection & Multiplexing

The results of the post-processing stages and raw unsigned outputs feed into the final execution mux layer. Based on the 3-bit `sel` signal, the correct 32-bit slice is driven onto the shared execution unit output bus, ensuring a uniform timing loop across both the multiplication and division routines.
