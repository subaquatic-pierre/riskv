# 32-Bit Branch Selector Module

## Functional Overview

The **Branch Selector (`BranchSelector`)** is the decision-making block that determines whether a conditional branch instruction should jump to a target address or continue executing code sequentially.

While the companion `WordLevelComparator` module calculates raw value truths (equal, less than, etc.), it does not know which instruction the CPU is processing. The Branch Selector solves this by acting as a filter. It reads the 3-bit sub-code (`funct3`) directly from the current instruction and uses it to select the exact comparison flag needed. It outputs a single true/false signal (`TakeBranch`) to control the processor's routing hardware.

---

## Interface Specifications

### Input Signals

| Pin Name    | Bit Width | Direction | Functional Description                                     |
| :---------- | :-------: | :-------: | :--------------------------------------------------------- |
| `EQ`        |     1     |   Input   | Raw Equality flag from the Word-Level Comparator           |
| `LTU`       |     1     |   Input   | Raw Unsigned Less-Than flag from the Word-Level Comparator |
| `LTS`       |     1     |   Input   | Raw Signed Less-Than flag from the Word-Level Comparator   |
| `Branch_Op` |     3     |   Input   | Bits [14:12] (`funct3`) parsed from the instruction bus    |

### Output Signals

| Pin Name     | Bit Width | Direction | Functional Description                                                  |
| :----------- | :-------: | :-------: | :---------------------------------------------------------------------- |
| `TakeBranch` |     1     |  Output   | Target jump control line (`1` = execute jump, `0` = sequential execute) |

---

## Internal Logic Matrix

The internal routing maps the 3-bit instruction filter to an 8-to-1 Multiplexer (MUX). The binary encoding matches the official RISC-V hardware specification:

| `Branch_Op` (Binary) | Matching Instruction                   | Evaluated Condition   | Internal Hardware Path                                    |
| :------------------: | :------------------------------------- | :-------------------- | :-------------------------------------------------------- |
|        `000`         | `BEQ` (Branch if Equal)                | $A == B$              | MUX Input 0 $\rightarrow$ Passes `EQ` directly            |
|        `001`         | `BNE` (Branch if Not Equal)            | $A \neq B$            | MUX Input 1 $\rightarrow$ Passes `EQ` through a NOT gate  |
|        `010`         | _Unused_                               | N/A                   | MUX Input 2 $\rightarrow$ Hardwired to Ground (`0`)       |
|        `011`         | _Unused_                               | N/A                   | MUX Input 3 $\rightarrow$ Hardwired to Ground (`0`)       |
|        `100`         | `BLT` (Branch Less Than Signed)        | $A < B$ (Signed)      | MUX Input 4 $\rightarrow$ Passes `LTS` directly           |
|        `101`         | `BGE` (Branch Greater/Equal Signed)    | $A \geq B$ (Signed)   | MUX Input 5 $\rightarrow$ Passes `LTS` through a NOT gate |
|        `110`         | `BLTU` (Branch Less Than Unsigned)     | $A < B$ (Unsigned)    | MUX Input 6 $\rightarrow$ Passes `LTU` directly           |
|        `111`         | `BGEU` (Branch Greater/Equal Unsigned) | $A \geq B$ (Unsigned) | MUX Input 7 $\rightarrow$ Passes `LTU` through a NOT gate |

---
