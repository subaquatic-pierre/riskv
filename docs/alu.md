# Arithmetic Logic Unit (ALU) Component Documentation

The **Arithmetic Logic Unit (ALU)** is the primary operational core of the execution stage. It is a purely combinatorial module that accepts two 32-bit data operands and a 4-bit control configuration selection bus. It performs the designated arithmetic or logical operation and immediately exposes the calculated result on its output bus.

---

### Interface Specification

#### Input Signals

- **`dataA[31:0]` (32 bits):** First data operand, routed from the `ASel` multiplexer (representing either `rs1_data` or the current `PC` value).
- **`dataB[31:0]` (32 bits):** Second data operand, routed from the `BSel` multiplexer (representing either `rs2_data` or the sign-extended immediate value).
- **`ALUSel[3:0]` (4 bits):** Execution operation selection bus, wired directly from the `EX_Control` output group of the Main Control Decoder.

#### Output Signals

- **`ALUResult[31:0]` (32 bits):** The computed output word of the executed operation, routed directly to the Data Memory address port and the Writeback multiplexer.

---

### Selection Bus Bit Mapping

The 4-bit `ALUSel[3:0]` bus is constructed directly from the instruction payload fields inside the control decoder. To align with the layout of your hardware matrix, the instruction modifier bit is mapped directly to the Most Significant Bit (MSB):

- **`ALUSel[3]`:** Wired directly to **`Instruction[30]`** (the sign/modifier bit from the `funct7` field).
- **`ALUSel[2:0]`:** Wired directly to the instruction's **`funct3`** field (`Instruction[14:12]`).

---

### ALU Operation Mapping Matrix

The execution logic decodes `ALUSel[3:0]` to select the active hardware path. For operations involving shifts or unsigned comparisons, the operands are cast to their corresponding hardware types:

| ALUSel[3:0] | Target Instructions         | Internal Core Operation                             | Description                                                     |
| :---------: | :-------------------------- | :-------------------------------------------------- | :-------------------------------------------------------------- |
| **`0000`**  | `ADD`, `ADDI`, Loads/Stores | `ALUResult = dataA + dataB`                         | Standard 32-bit two's complement addition.                      |
| **`0001`**  | `SLL`, `SLLI`               | `ALUResult = dataA << dataB[4:0]`                   | Logical Shift Left (shifts in zeros). Uses bottom 5 bits of B.  |
| **`0010`**  | `SLT`, `SLTI`               | `ALUResult = (signed)dataA < (signed)dataB ? 1 : 0` | Set Less Than (Signed comparison).                              |
| **`0011`**  | `SLTU`, `SLTUI`             | `ALUResult = dataA < dataB ? 1 : 0`                 | Set Less Than Unsigned (Magnitude comparison).                  |
| **`0100`**  | `XOR`, `XORI`               | `ALUResult = dataA ^ dataB`                         | Bitwise bit-by-bit exclusive OR.                                |
| **`0101`**  | `SRL`, `SRLI`               | `ALUResult = dataA >> dataB[4:0]`                   | Logical Shift Right (shifts in zeros). Uses bottom 5 bits of B. |
| **`0110`**  | `OR`, `ORI`                 | `ALUResult = dataA \| dataB`                        | Bitwise bit-by-bit logical OR.                                  |
| **`0111`**  | `AND`, `ANDI`               | `ALUResult = dataA & dataB`                         | Bitwise bit-by-bit logical AND.                                 |
| **`1000`**  | `SUB`                       | `ALUResult = dataA - dataB`                         | Standard 32-bit two's complement subtraction.                   |
| **`1101`**  | `SRA`, `SRAI`               | `ALUResult = (signed)dataA >> dataB[4:0]`           | Arithmetic Shift Right (preserves the sign bit `dataA[31]`).    |

---

### Hardware Implementation Notes

### Hardware Implementation Notes

1. **Shift Magnitude Gating:** For all shift commands (`SLL`, `SRL`, `SRA`), the hardware layout ignores the upper 27 bits of `dataB`. The shift matrix hooks up exclusively to `dataB[4:0]` because shifting a 32-bit register by more than 31 bits is architecturally undefined in the base RV32I ISA.
2. **Logisim Adder Integration:** Addition and subtraction are handled natively by a standard Logisim sub-component. The subtraction modifier flag (`ALUSel[0]`) connects directly to the arithmetic block's internal operation control terminal to toggle between modes, eliminating the need for manual bit-inversion gates or discrete carry-in manipulation on the canvas.
3. **Comparison Set-Less-Than Bus Padding:** The Boolean comparators for `SLT` and `SLTU` generate a single-bit primitive output flag (`0` or `1`). To drive the full 32-bit execution result bus, this token must be routed into a bit-extension network on the canvas. The single-bit value is mapped directly to `ALUResult[0]`, while bits `ALUResult[31:1]` are explicitly padded with constant zero blocks to drive the unutilized lines low.
