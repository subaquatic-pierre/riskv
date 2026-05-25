# 32-Bit Unified Adder/Subtractor Module

## Functional Overview

The **32-Bit Unified Adder/Subtractor (`AdderSub32`)** is the hardware component responsible for performing math inside the processor. Instead of using two separate circuits for adding and subtracting, it uses a single 32-bit adder to do both jobs.

To subtract a number, the circuit converts it into a negative number using Two's Complement math (flipping all the bits and adding 1). This module handles the bit-flipping internally when the subtraction control signal (`Sub`) is turned on. However, it leaves the task of adding the extra `1` to the external system driving it. This clean, open design ensures that multiple modules can be linked together in the future to easily handle larger 64-bit numbers.

---

## Architectural Mechanics & Exterior Two's Complement Execution

To evaluate subtraction ($A - B$), the arithmetic path relies on the classic Two's Complement derivation:

$$A - B = A + \overline{B} + 1$$

Rather than handling the arithmetic adjustment internally, this module isolates the bitwise inversion from the carry step:

- **The Programmable Inverter Array:** A single 32-bit wide XOR gate functions as a conditional bitwise inverter. When `Sub = 0`, the operand passes through unmodified ($B \oplus 0 = B$). When `Sub = 1`, a parallel bit-flip is executed ($B \oplus 1 = \overline{B}$), fulfilling the One's Complement portion of the formula.
- **Decoupled Carry-In Path:** The baseline carry-in ($C_{\text{in}}$) pin of the internal 32-bit ripple chain passes directly to the first bit stage ($Bit_0$) without modification or logical masking.

### Operational Mapping (Caller Responsibilities)

Because the internal carry path is completely transparent, the external calling environment drives the terminal operations:

- **Standalone Addition:** The caller drives `Sub = 0` and `Cin = 0`.
- **Standalone Subtraction:** The caller drives `Sub = 1` and ties the same activation signal straight into `Cin = 1`, completing the $+1$ requirement for Two's Complement math.
- **Multi-Word Cascading (64-Bit Precision):** The upper-significant 32-bit module sets its `Sub` line to match the global operation, while its `Cin` line directly captures the raw, unmodified `Cout` cascading from the lower-significant 32-bit module.

| Intended Operation         | `Sub` Line |      Ext `Cin`      |      XOR Array ($B$)      |   Internal $C_0$    | True Arithmetic Expression             |
| :------------------------- | :--------: | :-----------------: | :-----------------------: | :-----------------: | :------------------------------------- |
| **ADD** (Standalone)       |    `0`     |         `0`         |      Unchanged ($B$)      |         `0`         | $A + B + 0$                            |
| **ADC** (64-bit Add Chain) |    `0`     |         `1`         |      Unchanged ($B$)      |         `1`         | $A + B + 1$                            |
| **SUB** (Standalone)       |    `1`     |         `1`         | Inverted ($\overline{B}$) |         `1`         | $A + \overline{B} + 1$                 |
| **SBB** (64-bit Sub Chain) |    `1`     | `Cout_{\text{low}}` | Inverted ($\overline{B}$) | `Cout_{\text{low}}` | $A + \overline{B} + Cout_{\text{low}}$ |

---

## Interface Specifications

### Input Signals

| Pin Name | Bit Width | Direction | Functional Description                                                                |
| :------- | :-------: | :-------: | :------------------------------------------------------------------------------------ |
| `A`      |    32     |   Input   | Word-level Augend/Minuend vector [31:0]                                               |
| `B`      |    32     |   Input   | Word-level Addend/Subtrahend vector [31:0]                                            |
| `Sub`    |     1     |   Input   | Active-high operational control signal (`0` = Pass $B$ raw, `1` = Invert $B$ bitwise) |
| `Cin`    |     1     |   Input   | Unmodified carry-in stream routed straight to the baseline bit layer ($Bit_0$)        |

### Output Signals

| Pin Name | Bit Width | Direction | Functional Description                                               |
| :------- | :-------: | :-------: | :------------------------------------------------------------------- |
| `Result` |    32     |  Output   | Word-level arithmetic transformation output vector [31:0]            |
| `Cout`   |     1     |  Output   | Final raw carry-out trailing from the highest bit layer ($Bit_{31}$) |

---

## Mathematical & Structural Formulation

The internal core maps a purely linear structural progression. For any bit index $i$ in the 32-bit vector array, the localized equations match the hardware constraints of the instantiated Full Adder cell:

$$\text{Sum}_i = A_i \oplus B'_i \oplus C_i$$
$$C_{i+1} = (A_i \cdot B'_i) + (B'_i \cdot C_i) + (A_i \cdot C_i)$$

Where:

- $B'_i = B_i \oplus \text{Sub}$
- $C_0 = \text{Cin}$
- $C_{32} = \text{Cout}$

---

## Hardware Optimization Analysis (XOR vs. MUX)

An alternative design pattern utilizes a 32-bit 2-to-1 Multiplexer coupled with a 32-bit NOT gate array to handle operand selection. The XOR matrix implementation was selected due to specific physical and layout advantages:

- **Gate Count Minimization:** A standard gate-level Multiplexer implementation demands two AND gates, one NOT gate, and an OR gate per single data line. Conversely, an XOR gate behaves as a highly efficient atomic cell, drastically limiting total transistor scaling and routing density across a wide 32-bit processing bus.
- **Shallow Propagation Depth:** The XOR matrix achieves both data propagation and conditional logical inversion in a single gate layer, bypassing the sequential delays introduced by separate negation arrays and selection multiplexers.

---

## Architectural Comparison & Design Trade-offs

To evaluate this baseline execution path against production alternative designs, the matrix below details the performance, hardware area, and layout complexity profiles of different 32-bit adder topologies.

| Adder Topology                                | Propagation Delay (Time Complexity) | Hardware Footprint (Area Complexity) |                 Logisim Layout / Wiring Complexity                 | Trade-off Analysis & Architectural Notes                                                                                                                                                                                                                                               |
| :-------------------------------------------- | :---------------------------------: | :----------------------------------: | :----------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ripple Carry (RCA)** <br>_(Current Design)_ |    $O(N)$ <br>_(32 Gate Delays)_    |        $O(N)$ <br>_(Minimal)_        |    **Very Low** <br>_(Highly uniform, linear cascading chain)_     | **Selected Baseline:** Offers the absolute smallest silicon area and cleanest routing profile. However, its linear delay ($O(N)$) creates a critical path bottleneck for high-frequency execution since the highest bits must stall until the lower carry signals stabilize.           |
| **Carry Look-Ahead (CLA)**                    |             $O(\log N)$             |            $O(N \log N)$             |          **High** <br>_(Complex parallel logic networks)_          | Evaluates all carries simultaneously using parallel generate ($G$) and propagate ($P$) equations. Drastically accelerates computation speed, but flat 32-bit implementation is constrained by extreme gate fan-in requirements, necessitating multi-level 4-bit grouped block schemes. |
| **Carry Select (CSelA)**                      |            $O(\sqrt{N})$            |               $O(2N)$                | **Medium-High** <br>_(Duplicated cells + wide multiplexer arrays)_ | Speculatively computes dual 32-bit addition variations simultaneously (one array assuming a `0` carry-in, another assuming a `1`). When the true carry-in stabilizes, high-speed multiplexers select the correct answer. Drastically cuts delay at the cost of doubling hardware area. |
| **Kogge-Stone (Parallel Prefix)**             |             $O(\log N)$             |            $O(N \log N)$             |        **Extreme** <br>_(Massive, overlapping wire trees)_         | A highly optimized parallel prefix tree implementation that represents the industry standard for industrial, high-frequency ALUs. Achieves the lowest absolute latency profile but introduces a complex web of overlapping signal nets that makes manual schematic layout impractical. |
| **Carry Skip / Bypass**                       |            $O(\sqrt{N})$            |                $O(N)$                |  **Medium** <br>_(Standard RCA cells + bypass AND multiplexing)_   | Identifies blocks of bits where a carry is guaranteed to propagate through completely, allowing the carry bit to skip entire multi-bit stages through a bypass multiplexer lane. Modest performance boost over RCA with minimal extra gating area.                                     |

---

## Verification & Test Vectors

Functional validation within `logisim/AdderSub32.circ` is verified using the following boundary scenarios:

- **Standard Accumulation (`Sub = 0`, `Cin = 0`):** `0x00000005` + `0x00000002` $\rightarrow$ `Result` = `0x00000007`, `Cout` = 0
- **Cascaded Carry Injection (`Sub = 0`, `Cin = 1`):** `0x00000005` + `0x00000002` + `1` $\rightarrow$ `Result` = `0x00000008`, `Cout` = 0
- **Bit-31 Carry Ripple Overflow (`Sub = 0`, `Cin = 0`):** `0xFFFFFFFF` + `0x00000001` $\rightarrow$ `Result` = `0x00000000`, `Cout` = 1
- **Standard Subtraction (`Sub = 1`, `Cin = 1`):** `0x00000005` - `0x00000002` (via $\overline{B} + 1$) $\rightarrow$ `Result` = `0x00000003`, `Cout` = 1
- **Cascaded Borrow Subtraction (`Sub = 1`, `Cin = 0`):** `0x00000005` - `0x00000002` with active borrow-in condition $\rightarrow$ `Result` = `0x00000002`, `Cout` = 1
- **Negative Two's Complement Evaluation (`Sub = 1`, `Cin = 1`):** `0x00000002` - `0x00000005` $\rightarrow$ `Result` = `0xFFFFFFFD` (Evaluates natively to signed value $-3$), `Cout` = 0
