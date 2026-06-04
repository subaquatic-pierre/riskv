# 32-Bit Word-Level Comparator Module

## Functional Overview

The **Word-Level Comparator (`WordLevelComparator`)** evaluates value comparisons by reusing the flags generated from a subtraction operation ($A - B$) performed by an external Two's Complement Adder.

By interpreting the subtraction result, carry-out, and original operand sign bits, this module evaluates equality (`EQ`), unsigned less-than (`LTU`), and signed less-than (`LTS`) conditions.

---

## Interface Specifications

### Input Signals

| Pin Name          | Bit Width | Direction | Functional Description                         |
| :---------------- | :-------: | :-------: | :--------------------------------------------- |
| `Result_In[31:0]` |    32     |   Input   | Output bus from the adder/subtractor block.    |
| `Cout_In`         |     1     |   Input   | Carry-out bit from the adder/subtractor block. |
| `A_Sign`          |     1     |   Input   | Sign bit (bit 31) of input operand $A$.        |
| `B_Sign`          |     1     |   Input   | Sign bit (bit 31) of input operand $B$.        |

### Output Signals

| Pin Name | Bit Width | Direction | Functional Description                                                |
| :------- | :-------: | :-------: | :-------------------------------------------------------------------- |
| `EQ`     |     1     |  Output   | **Equal:** Asserts high if $A == B$.                                  |
| `LTU`    |     1     |  Output   | **Less-Than Unsigned:** Asserts high if $A < B$ under unsigned rules. |
| `LTS`    |     1     |  Output   | **Less-Than Signed:** Asserts high if $A < B$ under signed rules.     |

---

## Internal Logic Mechanics

### 1. Equality (`EQ`)

When $A == B$, the subtraction result ($A - B$) equals zero.

- The 32-bit `Result_In` bus passes through a 32-input NOR tree.
- If all bits are `0`, `EQ` evaluates to `1`.

### 2. Unsigned Comparison (`LTU`)

In unsigned subtraction, the carry-out pin acts as an inverted borrow bit. If $A < B$, the subtraction underflows, driving `Cout_In` low.

- `Cout_In` is routed through an inverter.
- `LTU = NOT(Cout_In)`

### 3. Signed Comparison (`LTS`)

Signed evaluations depend on whether the operands share the same sign bit. An XOR gate determines the routing pathway:

- **Signs Match (`A_Sign XOR B_Sign = 0`):** Overflow is impossible. The calculation relies on the subtraction sign flag, which matches the unsigned underflow status (`LTU`).
- **Signs Differ (`A_Sign XOR B_Sign = 1`):** A negative number is always smaller than a positive number. Therefore, the result of $A < B$ matches `A_Sign` directly.

A multiplexer uses the `A_Sign XOR B_Sign` state as the selector to drive the final `LTS` output line.

---

### Driver Gate Formulas

```text
EQ  = NOT(Result_In[0] OR Result_In[1] OR ... OR Result_In[31])
LTU = NOT(Cout_In)
LTS = (A_Sign AND (A_Sign XOR B_Sign)) OR (LTU AND NOT(A_Sign XOR B_Sign))
```
