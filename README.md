# Risk-V Implementation

# RV32I Arithmetic & Logic Core Components

## 1. Foundational Addition & Subtraction Blocks

- [ ] **1-Bit Full Adder Primitive (FA)**: Gate-level cell computing $\text{Sum}$ and $C_{\text{out}}$ from inputs $A$, $B$, and $C_{\text{in}}$.
- [ ] **32-Bit Ripple Carry Adder (RCA)**: A parallel cascade of 32 Full Adders used to calculate sequential address increments ($\text{PC} + 4$) and pointer offsets.
- [ ] **32-Bit Unified Adder/Subtractor**: An RCA modified with a bitwise inversion layer (XOR gates) and a conditional carry-in line to handle two's complement subtraction ($A - B$) natively within the same circuit.

## 2. Word-Level Comparison Matrix

- [ ] **32-Bit Magnitude Comparator**: A combinational logic array that checks equality and relative magnitude bit-by-bit from MSB to LSB.
- [ ] **Signed/Unsigned Arbitration Unit**: A gate layer that reads the magnitude comparator outputs along with operand sign bits ($A[31]$ and $B[31]$) to resolve signed vs. unsigned inequalities for branches and set-less-than instructions (`BLT`, `BLTU`, `SLT`, `SLTU`).

## 3. Evaluation & Condition Flag Detectors

- [ ] **Zero Flag Detector**: A 32-input reduction NOR tree tracking the output bus of the adder/subtractor to instantly assert high if the result is exactly `0`.
- [ ] **Sign Flag Detector**: A dedicated wire tap on bit 31 of the arithmetic output bus to track negative numbers.
- [ ] **Overflow Flag Detector**: A small combinational gate block checking for two's complement arithmetic overflow by comparing the sign bits of the inputs against the sign bit of the output.

## 4. Basic Bitwise Logic Blocks

- [ ] **32-Bit Bitwise AND Matrix**: A parallel array of 32 basic AND gates for logical masking instructions (`AND`, `ANDI`).
- [ ] **32-Bit Bitwise OR Matrix**: A parallel array of 32 basic OR gates for logical combining instructions (`OR`, `ORI`).
- [ ] **32-Bit Bitwise XOR Matrix**: A parallel array of 32 basic XOR gates for logical inversion instructions (`XOR`, `XORI`).
