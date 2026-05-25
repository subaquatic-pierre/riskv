# 32-Bit Unified Bitwise Logic Unit

## Functional Overview

The **Bitwise Logic Unit (`BitwiseLogicUnit`)** encapsulates all bit-level logical operations required by the RISC-V ISA. Instead of exposing individual gates or custom control lines to the top-level ALU canvas, this module implements a unified 3-bit interface that accepts the raw `funct3` instruction field directly.

Internally, the module utilizes Logisim's native 32-bit wide gates. These gates perform operations strictly **bitwise**, processing each column from Bit 0 to Bit 31 in complete isolation with zero carry propagation or cross-talk. An internal routing matrix masks and maps the incoming execution code to select the correct logical result.

---

## Interface Specifications

### Input Signals

| Pin Name | Bit Width | Direction | Functional Description                                       |
| :------- | :-------: | :-------: | :----------------------------------------------------------- |
| `A`      |    32     |   Input   | 32-bit data operand bus A                                    |
| `B`      |    32     |   Input   | 32-bit data operand bus B                                    |
| `Funct3` |     3     |   Input   | Bits [14:12] (`funct3`) parsed directly from the instruction |

### Output Signals

| Pin Name       | Bit Width | Direction | Functional Description                     |
| :------------- | :-------: | :-------: | :----------------------------------------- |
| `Logic_Result` |    32     |  Output   | The final computed 32-bit bitwise data bus |

---

## Internal Logic & Multiplexer Mapping

The module passes inputs `A` and `B` through parallel, 32-bit bitwise AND, OR, and XOR arrays simultaneously. To select the correct output, a splitter isolates the lower two bits (`Funct3[1:0]`) to drive an internal 32-bit 4-to-1 Multiplexer:

| `Funct3` (Raw) | `Funct3[1:0]` (MUX Sel) | Instruction    | Chosen Operation | Internal Hardware Connection                                 |
| :------------: | :---------------------: | :------------- | :--------------- | :----------------------------------------------------------- |
|     `100`      |          `00`           | `XOR` / `XORI` | Bitwise XOR      | MUX Input 0 $\rightarrow$ 32-bit XOR Gate Output             |
|     `101`      |          `01`           | _Reserved_     | None             | MUX Input 1 $\rightarrow$ Hardwired to Ground (`0x00000000`) |
|     `110`      |          `10`           | `OR` / `ORI`   | Bitwise OR       | MUX Input 2 $\rightarrow$ 32-bit OR Gate Output              |
|     `111`      |          `11`           | `AND` / `ANDI` | Bitwise AND      | MUX Input 3 $\rightarrow$ 32-bit AND Gate Output             |

---
