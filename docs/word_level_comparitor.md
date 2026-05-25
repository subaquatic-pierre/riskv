# 32-Bit Word-Level Comparator Module

## Functional Overview

The **Word-Level Comparator (`WordLevelComparator`)** is a passive logic block that handles all value comparisons inside the processor. Instead of using its own heavy mathematical circuits to figure out if one number is larger, smaller, or equal to another, it cleanly reuses the work already done by the main 32-bit adder/subtractor unit.

By looking at the outputs of a subtraction operation ($A - B$), this module instantly calculates whether the two numbers are equal, smaller than each other as unsigned numbers (like memory addresses), or smaller than each other as signed numbers (positive and negative integers). It boxes up this logic in one clean component, preventing a mess of loose wires in the main ALU.

---

## Interface Specifications

### Input Signals

| Pin Name    | Bit Width | Direction | Functional Description                               |
| :---------- | :-------: | :-------: | :--------------------------------------------------- |
| `Result_In` |    32     |   Input   | The 32-bit output bus from the main adder/subtractor |
| `Cout_In`   |     1     |   Input   | The raw carry-out bit from the main adder/subtractor |
| `A_Sign`    |     1     |   Input   | Bit 31 (the sign bit) of input operand $A$           |
| `B_Sign`    |     1     |   Input   | Bit 31 (the sign bit) of input operand $B$           |

### Output Signals

| Pin Name | Bit Width | Direction | Functional Description                                                 |
| :------- | :-------: | :-------: | :--------------------------------------------------------------------- |
| `EQ`     |     1     |  Output   | **Equal:** Goes high (`1`) if $A$ is exactly equal to $B$              |
| `LTU`    |     1     |  Output   | **Less-Than Unsigned:** Goes high (`1`) if $A < B$ using unsigned math |
| `LTS`    |     1     |  Output   | **Less-Than Signed:** Goes high (`1`) if $A < B$ using signed math     |

---

## Internal Logic Mechanics

### 1. Equality (`EQ`)

If $A$ and $B$ are equal, subtracting them ($A - B$) results in exactly `0`.

- The module passes all 32 bits of `Result_In` through a wide NOR tree (a 32-input OR gate flipped by a NOT gate).
- If every single bit is `0`, the output settles high (`1`).

### 2. Unsigned Comparison (`LTU`)

In unsigned hardware subtraction, the carry-out pin acts as a "no borrow" flag. If $A$ is smaller than $B$, the subtraction underflows and drops `Cout_In` to `0`.

- The module routes `Cout_In` through a single NOT gate.
- A flipped `0` becomes a `1`, cleanly signaling that $A < B$.

### 3. Signed Comparison (`LTS`)

Signed numbers require sorting by positive and negative states. An XOR gate checks if the sign bits of $A$ and $B$ match:

- **Signs Match (XOR output = `0`):** There is no risk of signed overflow tricks. The multiplexer selects the raw unsigned underflow logic (`LTU`).
- **Signs Differ (XOR output = `1`):** A negative number is always smaller than a positive one. Because of this, the answer to "$A < B$" is identical to the sign bit of $A$. The multiplexer selects `A_Sign` directly.

---
