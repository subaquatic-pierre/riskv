# Unified Truth Table Reference Manual

## Multiplexers & Demultiplexers

### 2-to-1 Multiplexer (1-bit)

- **Core Logic:** Out = $(Input\_A \cdot \sim\!S) + (Input\_B \cdot S)$

| Select (S) | Input A | Input B | Output Y | Description                   |
| :--------: | :-----: | :-----: | :------: | :---------------------------- |
|     0      |    0    |    X    |    0     | Selects Input A and outputs 0 |
|     0      |    1    |    X    |    1     | Selects Input A and outputs 1 |
|     1      |    X    |    0    |    0     | Selects Input B and outputs 0 |
|     1      |    X    |    1    |    1     | Selects Input B and outputs 1 |

### 2-to-1 Multiplexer (32-bit)

- **Core Logic:** Parallel array of 32 1-bit MUX primitives driven by a common selection wire.

| Select (S) | Input A (32-bit) | Input B (32-bit) | Output Y | Description                           |
| :--------: | :--------------: | :--------------: | :------: | :------------------------------------ |
|     0      |     A[31:0]      |        X         | A[31:0]  | Selects the 32-bit value from Input A |
|     1      |        X         |     B[31:0]      | B[31:0]  | Selects the 32-bit value from Input B |

### 4-to-1 Multiplexer (32-bit)

- **Core Logic:** Cascaded binary convergence tree using two selection stages (`S1`, `S0`).

| Select (S1 S0) | Selected Input | Output Y | Description                           |
| :------------: | :------------: | :------: | :------------------------------------ |
|       00       |    Input A     | A[31:0]  | Selects the 32-bit value from Input A |
|       01       |    Input B     | B[31:0]  | Selects the 32-bit value from Input B |
|       10       |    Input C     | C[31:0]  | Selects the 32-bit value from Input C |
|       11       |    Input D     | D[31:0]  | Selects the 32-bit value from Input D |

### 1-to-2 Demultiplexer (32-bit)

- **Core Logic:** Gated output distribution. Inactive destination buses are grounded out (`32'b0`).

| Select (S) | Input D[31:0] | Output A[31:0] | Output B[31:0] | Description                         |
| :--------: | :-----------: | :------------: | :------------: | :---------------------------------- |
|     0      |    D[31:0]    |    D[31:0]     |       0        | Routes the 32-bit input to Output A |
|     1      |    D[31:0]    |       0        |    D[31:0]     | Routes the 32-bit input to Output B |

### 1-to-4 De-Multiplexer

- **Core Logic:** Diverging routing tree structure.

| Select (S1 S0) | Input D | Output A | Output B | Output C | Output D | Description                  |
| :------------: | :-----: | :------: | :------: | :------: | :------: | :--------------------------- |
|       00       |    1    |    1     |    0     |    0     |    0     | Routes the input to Output A |
|       01       |    1    |    0     |    1     |    0     |    0     | Routes the input to Output B |
|       10       |    1    |    0     |    0     |    1     |    0     | Routes the input to Output C |
|       11       |    1    |    0     |    0     |    0     |    1     | Routes the input to Output D |

---

## Encoders & Decoders

### 2-to-4 Decoder

- **Core Logic:** Generates distinct spatial minterms based on binary inputs.

| Input A1 A0 | Output Y0 | Output Y1 | Output Y2 | Output Y3 | Description         |
| :---------: | :-------: | :-------: | :-------: | :-------: | :------------------ |
|     00      |     1     |     0     |     0     |     0     | Activates Output Y0 |
|     01      |     0     |     1     |     0     |     0     | Activates Output Y1 |
|     10      |     0     |     0     |     1     |     0     | Activates Output Y2 |
|     11      |     0     |     0     |     0     |     1     | Activates Output Y3 |

### 3-to-8 Decoder

- **Core Logic:** Expanded activation wave matrix. Exactly one destination line is asserted.

| Input A2 A1 A0 | Y0  | Y1  | Y2  | Y3  | Y4  | Y5  | Y6  | Y7  | Description  |
| :------------: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :----------- |
|      000       |  1  |  0  |  0  |  0  |  0  |  0  |  0  |  0  | Activates Y0 |
|      001       |  0  |  1  |  0  |  0  |  0  |  0  |  0  |  0  | Activates Y1 |
|      010       |  0  |  0  |  1  |  0  |  0  |  0  |  0  |  0  | Activates Y2 |
|      011       |  0  |  0  |  0  |  1  |  0  |  0  |  0  |  0  | Activates Y3 |
|      100       |  0  |  0  |  0  |  0  |  1  |  0  |  0  |  0  | Activates Y4 |
|      101       |  0  |  0  |  0  |  0  |  0  |  1  |  0  |  0  | Activates Y5 |
|      110       |  0  |  0  |  0  |  0  |  0  |  0  |  1  |  0  | Activates Y6 |
|      111       |  0  |  0  |  0  |  0  |  0  |  0  |  0  |  1  | Activates Y7 |

### 4-to-2 Binary Encoder

- **Core Logic:** Compresses a single active line down to a binary index. Consumes non-overlapping inputs.

| Input D0 | Input D1 | Input D2 | Input D3 | Output Y1 Y0 | Description             |
| :------: | :------: | :------: | :------: | :----------: | :---------------------- |
|    1     |    0     |    0     |    0     |      00      | Encodes D0 active as 00 |
|    0     |    1     |    0     |    0     |      01      | Encodes D1 active as 01 |
|    0     |    0     |    1     |    0     |      10      | Encodes D2 active as 10 |
|    0     |    0     |    0     |    1     |      11      | Encodes D3 active as 11 |

> **Note:** If more than one input line is asserted simultaneously, output patterns corrupt into invalid junk values. For safe prioritization, use the Priority Encoders below.

### 4-to-2 Priority Encoder

- **Core Logic:** Enforces physical input precedence via internally nested look-ahead masking. Priority Hierarchy: $D_3 > D_2 > D_1 > D_0$.

| D3  | D2  | D1  | D0  | Output Y1 Y0 | Valid | Description                     |
| :-: | :-: | :-: | :-: | :----------: | :---: | :------------------------------ |
|  0  |  0  |  0  |  0  |      XX      |   0   | No input active                 |
|  0  |  0  |  0  |  1  |      00      |   1   | D0 active                       |
|  0  |  0  |  1  |  X  |      01      |   1   | D1 active (D1 overrides D0)     |
|  0  |  1  |  X  |  X  |      10      |   1   | D2 active (D2 overrides D1, D0) |
|  1  |  X  |  X  |  X  |      11      |   1   | D3 active (Highest Priority)    |

### 8-to-3 Priority Encoder

- **Core Logic:** Scaled prioritization matrix. High-order status flags instantly override lower address paths. Priority Hierarchy: $D_7$ (Highest) down to $D_0$ (Lowest).

| D7  | D6  | D5  | D4  | D3  | D2  | D1  | D0  | Output Y2 Y1 Y0 | Valid | Description                  |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-------------: | :---: | :--------------------------- |
|  0  |  0  |  0  |  0  |  0  |  0  |  0  |  0  |       XXX       |   0   | No inputs active             |
|  0  |  0  |  0  |  0  |  0  |  0  |  0  |  1  |       000       |   1   | D0 active                    |
|  0  |  0  |  0  |  0  |  0  |  0  |  1  |  X  |       001       |   1   | D1 active (overrides D0)     |
|  0  |  0  |  0  |  0  |  0  |  1  |  X  |  X  |       010       |   1   | D2 active                    |
|  0  |  0  |  0  |  0  |  1  |  X  |  X  |  X  |       011       |   1   | D3 active                    |
|  0  |  0  |  0  |  1  |  X  |  X  |  X  |  X  |       100       |   1   | D4 active                    |
|  0  |  0  |  1  |  X  |  X  |  X  |  X  |  X  |       101       |   1   | D5 active                    |
|  0  |  1  |  X  |  X  |  X  |  X  |  X  |  X  |       110       |   1   | D6 active                    |
|  1  |  X  |  X  |  X  |  X  |  X  |  X  |  X  |       111       |   1   | D7 active (Highest Priority) |

---

## Registers & Memory

### S-R Latch

- **Core Logic:** Cross-coupled bistable loop ($Q = \sim\!(S + Q_n)$).

| Input S | Input R |     Output Q      | Description                                            |
| :-----: | :-----: | :---------------: | :----------------------------------------------------- |
|    0    |    0    | $Q_{\text{prev}}$ | Stable Hold; loop maintains current bit state          |
|    0    |    1    |         0         | Reset state; forces $Q$ output to low                  |
|    1    |    0    |         1         | Set state; forces $Q$ output to high                   |
|    1    |    1    |    0 (Invalid)    | Race hazard; overrides feedback loop, outputs unstable |

### Gated D-Latch (Level-Triggered)

- **Core Logic:** Input isolation layer prevents invalid S-R conditions. Transparent when enable is high.

| Enable (E) | Data (D) |     Output Q      | Description                                        |
| :--------: | :------: | :---------------: | :------------------------------------------------- |
|     0      |    X     | $Q_{\text{prev}}$ | Latched mode; locked input channel preserves state |
|     1      |    0     |         0         | Transparent mode; output follows input immediately |
|     1      |    1     |         1         | Transparent mode; output follows input immediately |

### D Flip-Flop (DFF)

- **Core Logic:** Master-Slave series isolation cascade eliminates transparency race hazards.

| Clock Edge | Data (D) |     Output Q      | Description                                          |
| :--------: | :------: | :---------------: | :--------------------------------------------------- |
|  ↑ Rising  |    0     |         0         | Edge-triggered flash; samples input $D$ into storage |
|  ↑ Rising  |    1     |         1         | Edge-triggered flash; samples input $D$ into storage |
|  No Edge   |    X     | $Q_{\text{prev}}$ | Steady-state; ignores combinational input shifts     |

### 1-Bit Register (With Clock Enable / Write Enable)

- **Core Logic:** Frontend multiplexing feedback loop combined with an edge-triggered storage core.

| Clock Edge | Write Enable (WE) | Data (D) |  Stored Output Q  | Description                                         |
| :--------: | :---------------: | :------: | :---------------: | :-------------------------------------------------- |
|  ↑ Rising  |         1         |    0     |         0         | Strobe Active; captures new low bit                 |
|  ↑ Rising  |         1         |    1     |         1         | Strobe Active; captures new high bit                |
|  ↑ Rising  |         0         |    X     | $Q_{\text{prev}}$ | Strobe Quiet; drops to local loop preservation      |
|  No Edge   |         X         |    X     | $Q_{\text{prev}}$ | Steady-state; storage cell holds state indefinitely |
