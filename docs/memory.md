# Sequential Memory Elements

## Foundational Bistable Primitives

### The NOR-Based S-R Latch

The absolute foundational element of sequential state tracking is the Set-Reset (S-R) Latch, constructed from cross-coupled bistable gates.

- **Boolean Expressions:** \* $Q = \sim\!(S + Q_{n})$
  - $Q_{n} = \sim\!(R + Q)$
- **Functional Behavior:** When both inputs are low ($S=0, R=0$), the cross-coupled loops sustain their current voltage values, serving as a 1-bit static memory cell. Driving $S=1$ forces $Q$ high, while driving $R=1$ forces $Q$ low. Setting both inputs high simultaneously ($S=1, R=1$) is an invalid hardware state that breaks complementarity, forcing both output ports to $0$.

### The Gated D-Latch (Level-Triggered)

To prevent invalid input states and manage timing, an enable gate layer is added to the S-R primitive to create a Gated D-Latch.

- **Gate Blueprint:** A single Data input ($D$) splits into complementary lines via a NOT gate ($S = D, R = \sim\!D$), completely eliminating the invalid $S=1, R=1$ configuration. These lines pass through a pair of steering AND gates controlled by a master Enable ($EN$) line.
- **Functional Behavior:** The component is **transparent**. While $EN = 1$, the internal S-R latch is open, and any change on the $D$ input pin flows directly to the $Q$ output instantly. When $EN$ drops to $0$, the steering AND gates lock up, freezing the last observed state inside the cross-coupled loop.

### The D-Flip-Flop with Clock Enable (Edge-Triggered Primitive)

Because level-triggered transparency causes uncontrollable data race conditions down a long combinational pipeline, the architecture uses a Master-Slave D-Flip-Flop layout to achieve crisp, edge-triggered isolation.

- **Structural Composition:** Two Gated D-Latches are placed in a series cascade (Master bank feeding Slave bank). The external Clock line ($CLK$) drives the Master's enable pin through an inverter, and wires directly to the Slave's enable pin.
- **Clock Enable ($WE$) Integration:** A Write Enable ($WE$) or Clock Enable ($CE$) control loop is integrated at the frontend. A 2-to-1 MUX feeds the master input lane: input `0` routes the current output ($Q$) back into the latch, while input `1` routes the new incoming data line ($D$). The $WE$ wire drives the selection line of this loop.
- **Functional Behavior:** The component is strictly **edge-triggered**. On the rising edge of the clock ($CLK: 0 \rightarrow 1$), the Master bank locks its feedback loop, while the Slave bank opens up to release that exact captured value to the external $Q$ pin. Data moves by exactly one stage per clock cycle.

---

## Word Register

### Functional Purpose & System Usage

Registers supply immediate, single-cycle temporary storage directly inside the processor canvas.

- **Why it is used:** Combinational circuits lack memory; their outputs change immediately when inputs change. Registers capture and freeze data outputs at precise clock boundaries, preventing race conditions and isolating different execution phases.
- **Where it is used:** Program Counters ($PC$), Pipeline Registers (IF/ID, ID/EX, etc.), Status Flags, and Control State Registers.

### Array Scaling Mechanism

Scaling a 1-bit cell up to an $N$-bit data register (such as a 32-bit RISC-V register) follows a **parallel array pattern**, fanning out control signals and splitting data lines.

- **Data Bus Widening:** A structural splitter divides an incoming $N$-bit write data bus into $N$ individual wires. Each wire $D_i$ hooks into the input port of its respective 1-bit flip-flop stage ($DFF_i$).
- **Unified Control Broadcast:** The timing and write-strobe controls do not use decode logic. The master clock line ($CLK$) and the master write-enable line ($WE$) are broadcasted in parallel to the clock and enable pins of **all $N$ flip-flops** simultaneously.
- **Output Bus Assembly:** The $N$ individual output pins ($Q_i$) converge at a bus combiner, reassembling the state into a single, cohesive $N$-bit output bus.

---

## Multi-Port Register File (RAM Bank)

### Base Matrix Logic (The 32-Word Register Array)

A Register File wraps an array of $2^A$ parallel word registers into a shared addressing matrix. For the standard RV32I base, this equates to a 32-word ($A=5$ address bits) register bank, where each register is 32 bits wide ($N=32$).

### Functional Purpose & System Usage

The Register File acts as the primary, ultra-high-speed workspace for the processor core's operational instructions.

- **Why it is used:** To execute instructions like `add rd, rs1, rs2`, the execution core must be able to read two completely distinct source operands and write one destination operand simultaneously within a single clock cycle. Stacking registers into a multi-port file allows this concurrent access without memory bus bottlenecks.
- **Where it is used:** The core CPU register bank ($x0$ down to $x31$). In RISC-V compliance, register $x0$ is hardwired to an absolute ground vector ($32'b0$) and discards all incoming writes.

### Matrix Routing Pattern

Constructing a Multi-Port Register File requires surrounding the register array with the decoding and multiplexing routing blocks built previously:

- **The Write Path (Exclusive Gated Activation):**
  - The $A$-bit write address bus (`waddr`) feeds into an $A$-to-$2^A$ binary decoder.
  - The central processor's master write-enable line (`we`) connects to the main **Enable ($E$)** pin of this decoder.
  - The $2^A$ output wires from the decoder map directly to the individual Write Enable ($WE$) inputs of the registers. This ensures only the single target register wakes up on a clock edge.
  - The $N$-bit master write data bus (`wdata`) is multi-cast to the inputs of **all registers** in parallel; only the decoded register captures it.
- **The Read Path (Parallel Multiplexing Selection):**
  - For every independent read port required (RISC-V requires $R=2$ ports for `rs1` and `rs2`), a $2^A$-to-1 $N$-bit wide multiplexer is placed on the canvas.
  - The $N$-bit output data buses from all $2^A$ registers are multi-cast to the input slots `[0` to `2^A-1]` of **both** port multiplexers in parallel.
  - Port 1's read address bus (`raddr1`) drives the `Sel` port of the first MUX, and Port 2's read address bus (`raddr2`) drives the second MUX, instantly exposing the contents of the selected registers to the ALU buses combinatorially.

---

## Topographical Symmetry

| Attribute                   | Word Registers                                                               | Multi-Port Register Files                                                                       |
| :-------------------------- | :--------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- |
| **Data Flow Pattern**       | Bit-width Scaling ($1 \longrightarrow N$)                                    | Address-space Scaling ($N \longrightarrow N \times 2^A$)                                        |
| **Scaling Architecture**    | Parallel Array Pattern                                                       | Decoder-MUX Matrix Pattern                                                                      |
| **Primary System Role**     | Pipeline staging, address tracking ($PC$).                                   | Core architectural state storage ($x0$–$x31$).                                                  |
| **Control Signal Behavior** | Timing controls ($CLK$, $WE$) are broadcast uniformly across all bit slices. | Address buses are translated into exclusive write gates (one-hot) and parallel read selections. |
| **RISC-V Concrete Metric**  | 32 separate DFF elements driven by a single unified clock/enable pair.       | 32 registers (32-bit wide), one 5-to-32 write decoder, and two 32-to-1 32-bit read MUXes.       |
