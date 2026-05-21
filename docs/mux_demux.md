# Multiplexers & Demultiplexers

## Multiplexer (MUX)

### Base Gate Logic (The 2-to-1 Primitive)

At the lowest level, a 1-bit 2-to-1 Multiplexer is built entirely out of basic combinational gates. It uses an inverter, two AND gates, and an OR gate to pass one of two inputs ($I_0$ or $I_1$) based on a single select bit ($S$).

- **Boolean Expression:** $\text{Out} = (I_0 \cdot \sim\!S) + (I_1 \cdot S)$
- **Gate Blueprint:** The select line is inverted and fed into the first AND gate alongside $I_0$. The raw select line is fed into the second AND gate alongside $I_1$. The outputs of both AND gates converge into a final OR gate.

### Tree Scaling Mechanism

Scaling from a baseline $2^N$-to-1 architecture up to a $2^{N+1}$-to-1 structure follows a **converging tree pattern**. The hardware relies on breaking down the selection bus into lower addressing bits and a single master routing switch (MSB).

- **Sub-Bank Splitting:** The data input space is halved into a Low Bank (`[0` to `2^N - 1]`) and a High Bank (`[2^N` to `2^{N+1} - 1]`), each managed by a baseline $2^N$-to-1 sub-MUX.
- **Parallel Addressing:** The lower $N$ selection bits (`Sel[N-1:0]`) drive the selection pins of both sub-MUX blocks in parallel, narrowing the field down to two candidate streams.
- **The Final Stage Decision:** A single base 2-to-1 MUX arbitrates between the outputs of the two banks. The highest selection bit (`Sel[N]`) drives this final stage, passing the Low Bank stream when `0` and the High Bank stream when `1`.

---

## De-multiplexer (DEMUX)

### Base Gate Logic (The 1-to-2 Primitive)

A 1-bit 1-to-2 De-multiplexer steers a single input ($I$) to one of two output lines ($Y_0$ or $Y_1$) using a single select bit ($S$). It is built using an inverter and two AND gates.

- **Boolean Expressions:** \* $Y_0 = I \cdot \sim\!S$
  - $Y_1 = I \cdot S$
- **Gate Blueprint:** The input wire splits to drive one input of both AND gates. The select line is inverted before entering the first AND gate (driving $Y_0$) and sent directly to the second AND gate (driving $Y_1$). Unselected channels drop to absolute quiet (`0`).

### Tree Scaling Mechanism

Scaling a 1-to-$2^N$ structure up to a 1-to-$2^{N+1}$ structure follows a **diverging tree pattern**. Instead of resolving the selection at the end of the line, the calculation splits the data stream at the very front of the architecture.

- **Stage 1 Early Routing:** A baseline 1-to-2 sub-DEMUX primitive is positioned at the master input. Driven by the highest selection bit (`Sel[N]`), it routes the incoming data stream down either the Low Bank or High Bank branch.
- **Stage 2 Sub-Bank Distribution:** Two distinct 1-to-$2^N$ sub-DEMUX blocks handle the terminal distribution.
  - The Low Bank sub-DEMUX maps to outputs `[0` to `2^N - 1]`.
  - The High Bank sub-DEMUX maps to outputs `[2^N` to `2^{N+1} - 1]`.
- **Parallel Lower Addressing:** The lower $N$ bits of the selection bus (`Sel[N-1:0]`) drive both Stage 2 sub-DEMUX blocks simultaneously, completing the pathway to the final destination pin.

---

## 3. Topographical Symmetry

| Attribute                 | Multiplexers (MUX)                                                                | De-multiplexers (DEMUX)                                                           |
| :------------------------ | :-------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------- |
| **Data Flow Pattern**     | Convergence ($2^N \longrightarrow 1$)                                             | Divergence ($1 \longrightarrow 2^N$)                                              |
| **Topological Shape**     | Converging Fan-In Tree                                                            | Diverging Fan-Out Tree                                                            |
| **Control Priority**      | The Select MSB acts at the **very end** to choose the surviving candidate stream. | The Select MSB acts at the **very beginning** to commit data to a primary branch. |
| **Inactive State Status** | Unselected input paths are completely blocked and ignored.                        | Unselected output lines are driven to quiet grounding states (`0`).               |
