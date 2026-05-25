# Half Adder Primitive Component

## Functional Overview

The **Half Adder (HA)** is the foundational, single-bit combinational building block for arithmetic logic within the processor architecture. It handles the arithmetic addition of two single-bit binary inputs. Because it lacks an incoming carry input ($C_{\text{in}}$), it represents the localized starting point of binary addition before cascading logic is introduced.

---

## Interface Specifications

### Input Signals

| Pin Name | Bit Width | Direction | Functional Description                   |
| :------- | :-------: | :-------: | :--------------------------------------- |
| `A`      |     1     |   Input   | Augend bit (Operand A, bit position $i$) |
| `B`      |     1     |   Input   | Addend bit (Operand B, bit position $i$) |

### Output Signals

| Pin Name | Bit Width | Direction | Functional Description                                                        |
| :------- | :-------: | :-------: | :---------------------------------------------------------------------------- |
| `Sum`    |     1     |  Output   | The localized binary sum of inputs `A` and `B`                                |
| `Carry`  |     1     |  Output   | The overflow bit generated when both inputs are asserted ($2_{10}$ or $10_2$) |

---

## Mathematical & Boolean Formulations

The Half Adder resolves its outputs strictly using the current evaluation cycle's inputs.

### The Sum Column ($Sum$)

The sum output tracks whether the total number of asserted inputs is odd. It is mapped via a two-input Exclusive-OR (XOR) logic gate:
$$Sum = A \oplus B$$

### The Carry-Out Column ($Carry$)

The carry output acts as a logical mask that detects when both input bits are high, demanding an arithmetic carry to the next power-of-two significance column. It is mapped via a two-input AND logic gate:
$$Carry = A \cdot B$$

---

## Truth Table Matrix

| Input `A` | Input `B` | Output `Carry` | Output `Sum` | Binary Representation | Equivalent Decimal Evaluation |
| :-------: | :-------: | :------------: | :----------: | :-------------------: | :---------------------------- |
|    `0`    |    `0`    |      `0`       |     `0`      |         `00`          | $0 + 0 = 0$                   |
|    `0`    |    `1`    |      `0`       |     `1`      |         `01`          | $0 + 1 = 1$                   |
|    `1`    |    `0`    |      `0`       |     `1`      |         `01`          | $1 + 0 = 1$                   |
|    `1`    |    `1`    |      `1`       |     `0`      |         `10`          | $1 + 1 = 2$                   |
