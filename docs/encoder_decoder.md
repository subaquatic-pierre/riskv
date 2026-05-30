# Encoders & Decoders

## Priority Encoder

### Base Gate Logic (The 4-to-2 Primitive)

A base 4-to-2 Priority Encoder compresses 4 active-high input lines ($D_3$ down to $D_0$) into a 2-bit binary address ($A_1, A_0$) alongside a global Valid bit ($V$) that fires if any input is high. It grants strict precedence to the highest indexed active line:

- **Boolean Expressions:** - $A_1 = D_3 + D_2$
  - $A_0 = D_3 + \sim\!D_2 \cdot D_1$
  - $V = D_3 + D_2 + D_1 + D_0$
- **Gate Layout:** Built using a NOT gate, a 2-input AND gate, and multi-input OR gates. The priority masking logic explicitly blocks lower-order assertions when a higher-order input is high.

### Functional Purpose & System Usage

Priority encoders resolve competing, simultaneous hardware requests when only one event can be handled at a time.

- **Purpose:** In a standard binary encoder, multiple active input lines corrupt the output address. A priority encoder enforces a hardware hierarchy so that lower-priority requests are masked out until higher-priority requests are cleared.
- **Usage:** CPU Interrupt Controllers to determine peripheral precedence when multiple interrupts fire simultaneously, and floating-point units to calculate leading-zero counts for normalization.

### Tree Scaling Mechanism

Scaling from a $2^N$-to-$N$ block up to a $2^{N+1}$-to-$(N+1)$ block uses a **multiplexing convergence tree**. The circuit splits data lanes by priority level, using the higher-priority block's status to override the lower-priority path:

- **Input Bifurcation:** The $2^{N+1}$ inputs are split into a Low Bank (`0` to `2^N - 1`) and a High Bank (`2^N` to `2^{N+1} - 1`), feeding into parallel $2^N$-to-$N$ sub-encoders.
- **New MSB Generation:** The highest output bit ($Out_N$) is driven directly by the Valid status bit of the High Bank encoder ($V_{\text{high}}$). If any line in the upper half is active, $Out_N = 1$.
- **Lower Bit Address Steering:** The address outputs of both banks route through an array of $N$ 2-to-1 multiplexers. $V_{\text{high}}$ drives the select line of the MUX array, passing the High Bank address when active and defaulting to the Low Bank address when quiet.
- **Global Validity Calculation:** A 2-input OR gate combines both bank valid signals ($V = V_{\text{high}} + V_{\text{low}}$) to indicate if the entire composite component sees an active line.

---

## Binary Decoder

### Base Gate Logic (The 2-to-4 Primitive)

A baseline 2-to-4 Binary Decoder expands a 2-bit input address ($A_1, A_0$) into 4 unique destination lines ($Y_3$ down to $Y_0$). It features an active-high Enable pin ($E$) to gate the entire block.

- **Boolean Expressions:** - $Y_3 = A_1 \cdot A_0 \cdot E$
  - $Y_2 = A_1 \cdot \sim\!A_0 \cdot E$
  - $Y_1 = \sim\!A_1 \cdot A_0 \cdot E$
  - $Y_0 = \sim\!A_1 \cdot \sim\!A_0 \cdot E$
- **Gate Layout:** Built from a pair of address-line inverters feeding a parallel grid of 3-input AND gates. Each gate decodes one unique minterm combinatorially, and the line only fires if $E = 1$.

### Functional Purpose & System Usage

Decoders act as hardware routers that translate a compact, encoded binary number into a spatial physical location.

- **Purpose:** Minimizes wire clutter. Instead of running 32 separate control lines across a processor canvas to select a register, a 5-bit address bus routes to a decoder positioned at the target destination.
- **Usage:** Memory addressing schemes (RAM/ROM row selection), Register File index selection, and Central Control Units to translate raw 7-bit opcodes into dedicated, single-line instruction-activation paths.

### Tree Scaling Mechanism

Scaling from an $N$-to-$2^N$ module to an $(N+1)$-to-$2^{N+1}$ architecture follows an **activation wave routing pattern**, steering block-level enable signals rather than data buses:

- **Parallel Address Distribution:** The lower $N$ address lines ($In_{[N-1:0]}$) are bundled into a shared bus and wired directly to the address ports of both sub-decoders.
- **Master Bank Selection:** The single highest address bit ($In_N$) acts as the routing flag.
  - `In_N` routes directly to the Enable ($E$) pin of the High Bank sub-decoder.
  - `In_N` is inverted through a NOT gate and routed to the Enable ($E$) pin of the Low Bank sub-decoder.
- **Output Address Mapping:** The Low Bank sub-decoder drives lines `0` to `2^N - 1`, and the High Bank sub-decoder drives lines `2^N` to `2^{N+1} - 1`.

---

## Topographical Symmetry

| Attribute                  | Binary Decoders                                                                        | Priority Encoders                                                                        |
| :------------------------- | :------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------- |
| **Data Flow Pattern**      | Expansion ($N \longrightarrow 2^N$)                                                    | Compression ($2^N \longrightarrow N$)                                                    |
| **Scaling Tree Structure** | Gated Activation Wave                                                                  | Multiplexing Selection Tree                                                              |
| **Primary System Role**    | Address routing and sub-block activation.                                              | Interrupt prioritization and lead-bit identification.                                    |
| **Routing Control Hook**   | Input MSB dictates which sub-block is allowed to **wake up**.                          | Upper Valid bit ($V_{\text{high}}$) dictates which sub-block's data **survives**.        |
| **Inactive State Status**  | Unselected banks have their enable lines dropped, forcing all outputs to ground (`0`). | Unselected lower-priority lines are actively masked out inside the combinational matrix. |
