# Branch Control Component Documentation

The **Branch Control** component is a self-contained combinatorial module designed to evaluate conditional branch execution flags independently of the main ALU. By processing source register values alongside the instruction's verification fields, it determines whether a conditional execution path should be taken (`TakeBranch = 1`) or if the pipeline should proceed sequentially (`TakeBranch = 0`).

---

### Interface Specification

#### Input Signals

- **`rs1_data[31:0]` (32 bits):** The data word read from Register File Port 1.
- **`rs2_data[31:0]` (32 bits):** The data word read from Register File Port 2.
- **`BrSel[2:0]` (3 bits):** The condition selection bus, wired directly from the instruction's `funct3` field (`Instruction[14:12]`).

#### Output Signals

- **`TakeBranch` (1 bit):** Status flag asserted high (`1`) if the input data satisfies the condition selected by `BrSel`. Otherwise defaults to low (`0`).

---

### Internal Architecture

The component isolates its evaluation logic into two stages: **Arithmetic Difference Generation** and **Condition Matching Selection**.

#### 1. Arithmetic Difference Generation

The module routes `rs1_data` and `rs2_data` into an internal 32-bit subtractor to evaluate structural inequality without modifying the main processor state:

$$\text{Diff} = \text{rs1\_data} - \text{rs2\_data}$$

From this operation, the block derives four hardware status flags:

- **Zero Flag ($Z$):** Asserted if every bit of $\text{Diff}$ is zero. Indicated mathematically as:
  $$Z = \neg(\text{Diff}[31] \lor \text{Diff}[30] \lor \dots \lor \text{Diff}[0])$$
- **Negative Flag ($N$):** Tracks the sign bit of the raw difference:
  $$N = \text{Diff}[31]$$
- **Overflow Flag ($V$):** Asserted if the subtraction of two signed numbers results in an arithmetic overflow:
  $$V = (\text{rs1\_data}[31] \land \neg\text{rs2\_data}[31] \land \neg\text{Diff}[31]) \lor (\neg\text{rs1\_data}[31] \land \text{rs2\_data}[31] \land \text{Diff}[31])$$
- **Unsigned Borrow Flag ($C$):** The raw carry-out/borrow bit generated directly by the unsigned execution of the subtractor.

#### 2. Evaluated Status Flags

Using the raw signals above, the block establishes signed and unsigned less-than markers:

- **`LessSigned`:** Derived by checking if the result is structurally negative without overflow anomalies:
  $$\text{LessSigned} = N \oplus V$$
- **`LessUnsigned`:** Equal to the raw borrow state ($C$) of the hardware subtraction block.

---

### Condition Selection Matrix

The internal selection logic uses a 3-bit multiplexer or sum-of-products gate array driven by `BrSel[2:0]` to select which status flag rules the final output line:

| BrSel[2:0] | Target Instruction          | Output Condition Formula         | Functional Description                                            |
| :--------: | :-------------------------- | :------------------------------- | :---------------------------------------------------------------- |
| **`000`**  | `BEQ` (Equal)               | `TakeBranch = Z`                 | Asserted if values are identical ($\text{Diff} = 0$).             |
| **`001`**  | `BNE` (Not Equal)           | `TakeBranch = NOT(Z)`            | Asserted if values differ ($\text{Diff} \neq 0$).                 |
| **`100`**  | `BLT` (Less Than)           | `TakeBranch = LessSigned`        | Asserted if $rs1 < rs2$ using two's complement interpretation.    |
| **`101`**  | `BGE` (Greater / Equal)     | `TakeBranch = NOT(LessSigned)`   | Asserted if $rs1 \geq rs2$ using two's complement interpretation. |
| **`110`**  | `BLTU` (Less Than Un)       | `TakeBranch = LessUnsigned`      | Asserted if $rs1 < rs2$ using raw magnitude interpretation.       |
| **`111`**  | `BGEU` (Greater / Equal Un) | `TakeBranch = NOT(LessUnsigned)` | Asserted if $rs1 \geq rs2$ using raw magnitude interpretation.    |

---

### Pipeline Integration

The output of this component is designed to interface directly with the stage control logic at the pipeline boundary. Because it only checks if a branch condition is met, its output must be qualified by the main decoder's `Branch` opcode wire to verify that a branch operation is actually being executed:

```text
PCSel = JAL OR JALR OR (Branch AND TakeBranch)
```
