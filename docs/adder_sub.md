# 32-Bit Unified Adder/Subtractor Module

## Functional Overview

The **32-Bit Unified Adder/Subtractor (`AdderSub32`)** handles signed and unsigned addition and subtraction within the execution path. The module unifies both operations into a single 32-bit adder network rather than duplicating hardware structures.

To perform subtraction, the circuit converts the subtrahend into its two's complement form using a parallel bitwise one's complement inversion layer and a decoupled carry-in control path. This architecture processes subtraction natively and maintains modularity for cascading multi-word operations.

---

## Architectural Mechanics & Exterior Two's Complement Execution

To evaluate subtraction ($A - B$), the arithmetic path implements the standard two's complement identity:

$$A - B = A + \overline{B} + 1$$

The hardware separates the bitwise logical negation phase from the final mathematical carry increment step:

- **The Programmable Inverter Array:** A single 32-bit wide XOR gate array serves as a conditional bitwise inverter on the $B$ operand path.
  - When `Sub = 0`, the XOR gates act as transparent buffers, passing the operand unmodified ($B \oplus 0 = B$) to execute standard addition.
  - When `Sub = 1`, the XOR gates dynamically invert the bits ($B \oplus 1 = \overline{B}$), fulfilling the one's complement inversion required for subtraction.
- **Decoupled Carry-In Path:** The carry-in ($C_{\text{in}}$) pin of the internal 32-bit ripple chain passes directly to the baseline bit stage ($Bit_0$) without modification or logical masking.

### Operational Mapping (Caller Responsibilities)

Because the internal carry path is transparent, the external calling control logic coordinates standalone and multi-word cascaded executions:

- **Standalone Addition:** The control unit drives `Sub = 0` and `Cin = 0`.
- **Standalone Subtraction:** The control unit drives `Sub = 1` and routes the same control signal into `Cin = 1`, satisfying the $+1$ requirement for two's complement mathematical validity.
- **Multi-Word Cascading (64-Bit Precision):** The upper-significant 32-bit module sets its `Sub` line to match the global operation type, while its `Cin` line directly captures the raw, unmodified `Cout` cascading from the lower-significant 32-bit module.

| Intended Operation         | `Sub` Line |      Ext `Cin`      |      XOR Array ($B$)      |   Internal $C_0$    | True Arithmetic Expression             |
| :------------------------- | :--------: | :-----------------: | :-----------------------: | :-----------------: | :------------------------------------- |
| **ADD** (Standalone)       |    `0`     |         `0`         |      Unchanged ($B$)      |         `0`         | $A + B + 0$                            |
| **ADC** (64-bit Add Chain) |    `0`     |         `1`         |      Unchanged ($B$)      |         `1`         | $A + B + 1$                            |
| **SUB** (Standalone)       |    `1`     |         `1`         | Inverted ($\overline{B}$) |         `1`         | $A + \overline{B} + 1$                 |
| **SBB** (64-bit Sub Chain) |    `1`     | $Cout_{\text{low}}$ | Inverted ($\overline{B}$) | $Cout_{\text{low}}$ | $A + \overline{B} + Cout_{\text{low}}$ |

---

## Interface Specifications

### Input Signals

| Pin Name  | Bit Width | Direction | Functional Description                                                     |
| :-------- | :-------: | :-------: | :------------------------------------------------------------------------- |
| `A[31:0]` |    32     |   Input   | Word-level Augend/Minuend vector.                                          |
| `B[31:0]` |    32     |   Input   | Word-level Addend/Subtrahend vector.                                       |
| `Sub`     |     1     |   Input   | Operational control signal (`0` = Pass $B$ raw, `1` = Invert $B$ bitwise). |
| `Cin`     |     1     |   Input   | Carry-in stream routed straight to the baseline bit layer ($Bit_0$).       |

### Output Signals

| Pin Name       | Bit Width | Direction | Functional Description                                            |
| :------------- | :-------: | :-------: | :---------------------------------------------------------------- |
| `Result[31:0]` |    32     |  Output   | Word-level arithmetic transformation output vector.               |
| `Cout`         |     1     |  Output   | Final carry-out trailing from the highest bit layer ($Bit_{31}$). |

---

## Mathematical & Structural Formulation

The internal core maps a linear structural progression. For any bit index $i$ in the 32-bit vector array, the localized equations match the hardware constraints of the instantiated Full Adder cell:

$$\text{Sum}_i = A_i \oplus B'_i \oplus C_i$$
$$C_{i+1} = (A_i \cdot B'_i) + (B'_i \cdot C_i) + (A_i \cdot C_i)$$

Where:

- $B'_i = B_i \oplus \text{Sub}$
- $C_0 = \text{Cin}$
- $C_{32} = \text{Cout}$

---

## Hardware Optimization Analysis (XOR vs. MUX)

An alternative design pattern utilizes a static NOT gate array coupled with a 32-bit 2-to-1 Multiplexer layer to choose between the raw $B$ bus and the inverted $\overline{B}$ bus. The conditional XOR matrix implementation was selected due to specific layout and performance advantages:

- **Gate Count Minimization:** A standard multiplexer implementation demands two AND gates, one NOT gate, and an OR gate per bit slice, on top of the discrete negation array. Conversely, an XOR gate operates as an atomic cell, restricting total transistor scaling and routing density across the wide 32-bit processing bus.
- **Shallow Propagation Depth:** The XOR matrix achieves both data propagation and conditional logical inversion in a single gate layer, bypassing the sequential delays introduced by separate negation arrays and selection multiplexers.

---

## Architectural Comparison & Design Trade-offs

To evaluate this baseline execution path against alternative designs, the matrix below details the performance, hardware area, and layout complexity profiles of different 32-bit adder topologies.

| Adder Topology                                | Propagation Delay (Time Complexity) | Hardware Footprint (Area Complexity) |             Logisim Layout / Wiring Complexity              | Trade-off Analysis & Architectural Notes                                                                                                                                                                                                                                               |
| :-------------------------------------------- | :---------------------------------: | :----------------------------------: | :---------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ripple Carry (RCA)** <br>_(Current Design)_ |    $O(N)$ <br>_(32 Gate Delays)_    |        $O(N)$ <br>_(Minimal)_        | **Very Low** <br>_(Highly uniform, linear cascading chain)_ | **Selected Baseline:** Smallest silicon area and cleanest routing profile. Linear delay ($O(N)$) creates a critical path bottleneck for high-frequency execution since the highest bits must stall until the lower carry signals stabilize.                                            |
| **Carry Look-Ahead (CLA)**                    |             $O(\log N)$             |            $O(N \log N)$             |      **High** <br>_(Complex parallel logic networks)_       | Evaluates all carries simultaneously using parallel generate ($G$) and propagate ($P$) equations. Drastically accelerates computation speed, but flat 32-bit implementation is constrained by high gate fan-in requirements, necessitating multi-level 4-bit grouped block schemes.    |
| **Carry Select (CSelA)**                      |            $O(\sqrt{N})$            |               $O(2N)$                | **Medium-High** <br>_(Duplicated cells + wide MUX arrays)_  | Computes dual 32-bit addition variations simultaneously (one array assuming `0` carry-in, another assuming `1`). When the true carry-in stabilizes, high-speed multiplexers select the correct answer. Cuts delay at the cost of doubling hardware area.                               |
| **Kogge-Stone (Parallel Prefix)**             |             $O(\log N)$             |            $O(N \log N)$             |     **Extreme** <br>_(Massive, overlapping wire trees)_     | A highly optimized parallel prefix tree implementation that represents the industry standard for industrial, high-frequency ALUs. Achieves the lowest absolute latency profile but introduces a complex web of overlapping signal nets that makes manual schematic layout impractical. |
| **Carry Skip / Bypass**                       |            $O(\sqrt{N})$            |                $O(N)$                |  **Medium** <br>_(Standard RCA cells + bypass AND MUXing)_  | Identifies blocks of bits where a carry is guaranteed to propagate through completely, allowing the carry bit to skip entire multi-bit stages through a bypass multiplexer lane. Modest performance boost over RCA with minimal extra gating area.                                     |

---
