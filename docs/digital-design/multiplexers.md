# Multiplexers & Demultiplexers

## Multiplexer (MUX)

### Base Gate Logic (The 2-to-1 Primitive)

A 1-bit 2-to-1 Multiplexer routes one of two inputs ($I_0$ or $I_1$) to a single output based on a select bit ($S$).

- **Boolean Expression:** $\text{Out} = (I_0 \cdot \sim\!S) + (I_1 \cdot S)$
- **Gate Layout:** The select line is inverted and ANDed with $I_0$. The raw select line is ANDed with $I_1$. The outputs of both AND gates pass through a final OR gate.

### Tree Scaling Mechanism

Scaling from a $2^N$-to-1 architecture up to a $2^{N+1}$-to-1 structure follows a **converging tree pattern**. The selection bus is split into lower addressing bits and a single master routing bit (MSB).

- **Sub-Bank Splitting:** The data input space is halved into a Low Bank (`0` to `2^N - 1`) and a High Bank (`2^N` to `2^{N+1} - 1`), each routed to a $2^N$-to-1 sub-MUX.
- **Parallel Addressing:** The lower $N$ selection bits (`Sel[N-1:0]`) drive both sub-MUX blocks in parallel, narrowing the inputs down to two candidate streams.
- **Final Stage Decision:** A base 2-to-1 MUX arbitrates between the outputs of the two banks. The highest selection bit (`Sel[N]`) drives this final stage, passing the Low Bank stream when `0` and the High Bank stream when `1`.

---

## De-multiplexer (DEMUX)

### Base Gate Logic (The 1-to-2 Primitive)

A 1-bit 1-to-2 De-multiplexer steers a single input ($I$) to one of two output lines ($Y_0$ or $Y_1$) using a select bit ($S$).

- **Boolean Expressions:** - $Y_0 = I \cdot \sim\!S$
  - $Y_1 = I \cdot S$
- **Gate Layout:** The input wire splits to drive one input of two parallel AND gates. The select line is inverted before entering the $Y_0$ AND gate and sent directly to the $Y_1$ AND gate. Unselected channels default to `0`.

### Tree Scaling Mechanism

Scaling a 1-to-$2^N$ structure up to a 1-to-$2^{N+1}$ structure follows a **diverging tree pattern**, splitting the data stream at the front of the architecture.

- **Stage 1 Early Routing:** A baseline 1-to-2 DEMUX primitive is positioned at the master input. Driven by the highest selection bit (`Sel[N]`), it routes the incoming data stream down either the Low Bank or High Bank branch.
- **Stage 2 Sub-Bank Distribution:** Two distinct 1-to-$2^N$ sub-DEMUX blocks handle terminal distribution:
  - The Low Bank sub-DEMUX maps to outputs `0` to `2^N - 1`.
  - The High Bank sub-DEMUX maps to outputs `2^N` to `2^{N+1} - 1`.
- **Parallel Lower Addressing:** The lower $N$ bits of the selection bus (`Sel[N-1:0]`) drive both Stage 2 sub-DEMUX blocks simultaneously, completing the pathway to the destination pin.

---

## Topographical Symmetry

| Attribute             | Multiplexers (MUX)                                             | De-multiplexers (DEMUX)                                                  |
| :-------------------- | :------------------------------------------------------------- | :----------------------------------------------------------------------- |
| **Data Flow Pattern** | Convergence ($2^N \longrightarrow 1$)                          | Divergence ($1 \longrightarrow 2^N$)                                     |
| **Topological Shape** | Converging Fan-In Tree                                         | Diverging Fan-Out Tree                                                   |
| **Control Priority**  | Select MSB acts at the **end** to choose the surviving stream. | Select MSB acts at the **beginning** to commit data to a primary branch. |
| **Inactive Status**   | Unselected input paths are isolated and ignored.               | Unselected output lines are driven to ground (`0`).                      |
