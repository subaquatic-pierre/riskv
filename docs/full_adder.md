# Full Adder Primitive Component

## Functional Overview

The **Full Adder (FA)** is a 1-bit combinational circuit designed to perform the arithmetic addition of three binary inputs: two operand bits and a carry-in bit cascaded from a lower-order significance column. It serves as the foundational core for word-level vector adders, allowing carry propagation across parallel execution stages.

---

## Architecture Selection Trade-Offs

While a Full Adder can be constructed structurally by chaining two existing `HalfAdder` modules back-to-back with an OR gate, this design implements a flat, optimized **Standard Gate-Level Layout (SOP-optimized)** instead.

### Why the Structural Two-Half-Adder Design Was Rejected

- **Propagation Delay Bottleneck:** In a multi-bit ripple carry chain, the critical path is dictated by the time it takes for the carry signal to propagate from the lowest bit to the highest bit. Chaining two half adders forces the carry-out signal to traverse multiple nested sub-circuit boundaries and sequential gating paths, increasing total gate propagation latency.
- **Optimized Carry Path:** The standard gate-level approach resolves the critical carry-out pathway ($C_{\text{out}}$) in parallel. By evaluating all input combinations across a single shallow layer of parallel 2-input AND gates feeding directly into a 3-input OR gate, the propagation delay is minimized, making it significantly faster when scaled to a full 32-bit width.

---

## Interface Specifications

### Input Signals

| Pin Name | Bit Width | Direction | Functional Description                                                     |
| :------- | :-------: | :-------: | :------------------------------------------------------------------------- |
| `A`      |     1     |   Input   | Augend bit (Operand A, bit position $i$)                                   |
| `B`      |     1     |   Input   | Addend bit (Operand B, bit position $i$)                                   |
| `Cin`    |     1     |   Input   | Carry-in bit cascading from the previous lower-significance column ($i-1$) |

### Output Signals

| Pin Name | Bit Width | Direction | Functional Description                                                                   |
| :------- | :-------: | :-------: | :--------------------------------------------------------------------------------------- |
| `Sum`    |     1     |  Output   | The localized binary sum of inputs `A`, `B`, and `Cin`                                   |
| `Cout`   |     1     |  Output   | The carry-out bit generated to overflow into the next higher-significance column ($i+1$) |

---

## Mathematical & Boolean Formulations

The Standard Gate-Level Layout optimizes execution paths by deriving outputs directly from the primary inputs using parallel Boolean expressions.

### The Sum Logic Path

The binary sum represents an odd parity check across the three input variables, resolved using cascaded 2-input Exclusive-OR (XOR) logic gates:
$$Sum = A \oplus B \oplus Cin$$

### The Carry-Out Logic Path

The carry-out is asserted if at least two of the three inputs are high. This is evaluated using a parallel Sum-of-Products (SOP) configuration:
$$Cout = (A \cdot B) + (B \cdot Cin) + (A \cdot Cin)$$

---

## Truth Table Matrix

| Input `A` | Input `B` | Input `Cin` | Output `Cout` | Output `Sum` | Equivalent Decimal Evaluation |
| :-------: | :-------: | :---------: | :-----------: | :----------: | :---------------------------- |
|    `0`    |    `0`    |     `0`     |      `0`      |     `0`      | $0 + 0 + 0 = 0$               |
|    `0`    |    `1`    |     `0`     |      `0`      |     `1`      | $0 + 1 + 0 = 1$               |
|    `1`    |    `0`    |     `0`     |      `0`      |     `1`      | $1 + 0 + 0 = 1$               |
|    `1`    |    `1`    |     `0`     |      `1`      |     `0`      | $1 + 1 + 0 = 2$               |
|    `0`    |    `0`    |     `1`     |      `0`      |     `1`      | $0 + 0 + 1 = 1$               |
|    `0`    |    `1`    |     `1`     |      `1`      |     `0`      | $0 + 1 + 1 = 2$               |
|    `1`    |    `0`    |     `1`     |      `1`      |     `0`      | $1 + 0 + 1 = 2$               |
|    `1`    |    `1`    |     `1`     |      `1`      |     `1`      | $1 + 1 + 1 = 3$               |
