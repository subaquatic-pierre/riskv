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
