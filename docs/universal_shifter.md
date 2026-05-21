# Integrated Barrel Shifter

## Functional Overview

The Integrated Barrel Shifter is a high-performance, single-cycle execution unit capable of natively processing logical left/right shifts, arithmetic right shifts, and unconstrained cyclic rotations. Rather than relying on a separate, high-overhead post-execution mask generator to clean up bits, the circuit injects masking, padding, and direction control logic directly into the multiplexer stages of the shifter core.

## Structural Composition (The RotN Cascade)

The physical core is implemented as a 5-stage log-scaled shifter cascade (Rot1, Rot2, Rot4, Rot8, and Rot16).

- **Stage Conditioning:** Every stage evaluates a single bit of the 5-bit shift amount (`Shamt[i]`). If `Shamt[i]` is high, the data lines shift spatially by $2^i$ positions; if low, the data lines pass through unmodified.
- **Right-Rotating Hardware Bias:** The physical wire routing within the multiplexer grid is configured exclusively for rightward movement.

---

## Left-Shift Optimization via Arithmetic Inversion

To avoid duplicating the entire multi-stage multiplexer cascade with left-handed wiring, the hardware implements a **Two's Complement Arithmetic Inversion Unit** on the control path.

### The Underlying Mathematical Reasoning

In a fixed-width 32-bit register space, shifting a binary value left by a magnitude of $K$ is structurally and mathematically equivalent to rotating that same value right by a magnitude of $32 - K$.

$$\text{Shift\_Left}(K) \equiv \text{Rotate\_Right}(32 - K)$$

To calculate $32 - K$ efficiently in hardware without dropping a heavy subtraction unit into the control line, the circuit utilizes a conditional bitwise inverter:

- **Bitwise Inversion:** Inverting all 5 bits of the shift amount (`~Shamt[4:0]`) calculates the one's complement, which is equivalent to $(31 - \text{Shamt})$.
- **+1:** By treating the final bit inversion as an effective $32 - \text{Shamt}$ operation, the hardware maps left-shifts into a standard right-rotation coordinate space. When `Ctrl_Dir = 1` (Left Shift), the inversion unit flips the control lines driving the `RotN` stages.

---

## Mask Generation & Spatial Isolation

To cleanly enforce boundaries across different instruction modes, an internal combinational Mask Generator runs in parallel with the shifter cascade. This logic maps the 5-bit `Shamt` vector into 32-bit bitmasks to isolate or pad specific windows:

- **Isolation Mask Generation:** For logical operations, a masking vector is computed based on the shift magnitude. It isolates the valid shifted data window and structurally forces all out-of-bounds wrapped bits to logical low (`0`) within the MUX stages.
- **Arithmetic Extension Mask Generation:** For arithmetic operations (`Ctrl_Arith = 1`), an extension mask is generated to intercept vacated upper bit positions. Instead of wrapping or grounding, this mask forces those specific lanes to mirror the operand's **Sign Bit** ($DataIn[31]$), preserving two's complement numerical validity.

---

## The Universal Mask Generator (`MaskGenUni`)

To cleanly isolate shifted windows and handle arithmetic sign extension without expensive decoder/thermometer-code matrices, the execution block embeds a unified combinational engine called the `MaskGenUni` sub-circuit. This component contains a standard, parallel **staged barrel rotator** architecture that structurally mirrors the main shifter cascade, generating precise 32-bit hardware masks natively via cyclic bit rotation.

### Staged Seed Selection & Inversion Routing

Instead of rotating data, the `MaskGenUni` cascade processes a fixed block-level initialization vector (Seed) and leverages the complement of the shift magnitude to establish mask boundaries:

1. **Dynamic Seed Vector Selection:**
   - The sub-circuit initializes its input bus with a uniform background seed vector. This vector is driven entirely by a selection multiplexer choosing between all ones (`32'hFFFF_FFFF`) or all zeros (`32'h0000_0000`).
   - **Arithmetic Sign Integration:** The choice of seed is conditioned by the instruction type and the incoming operand's **Sign Bit** ($DataIn[31]$). For arithmetic right shifts (`SRA`), if the sign bit is high, an all-ones seed is committed; if low, an all-zeros seed is committed. For logical shifts, the seed matches the boundary padding requirements.
2. **Inverse Magnitude Controls:**
   - The control bus driving the `MaskGenUni` rotator stages receives the bitwise inversion of the shift amount (`~Shamt[4:0]`).
   - By feeding the inverted shift magnitude into a right-handed barrel rotator initialized with a uniform seed, the out-of-bounds wrap-around lanes naturally align to form a perfectly scaled, continuous mask boundary.

### Concurrently Generated Output Masks

Because the internal multiplexer stages combine the uniform seed vectors with inverted routing vectors, a single traversal of the `MaskGenUni` rotator cascade generates two distinct operational masks simultaneously:

- **The Isolation Mask:** A clean binary window used during logical adjustments (`SLL`, `SRL`) to isolate valid shifted data slots and structurally drop all out-of-bounds wrapped bits to logical low (`0`).
- **The Arithmetic Extension Mask:** A dedicated sign-extension vector used during arithmetic adjustments (`SRA`). It maps the sampled $DataIn[31]$ bit pattern across the exact upper bit slots vacated by the shift, preserving two's complement arithmetic integrity.

---

## The Dual-Highway Isolation Matrix

To cleanly separate pure cyclic modifications from restricted shifts without bloating the critical path, the architecture routes the rotator core's signals across two parallel paths before the final output bus selection:

- **Highway 0 (Pure Rotate Highway):** Connects the unconstrained cyclic output of the core directly to the final multiplexer stage to instantly expose `ROL` and `ROR` results.
- **Highway 1 (Shift Highway):** Carries the results of the core when it is running under active stage-conditioning limits (`SLL`, `SRL`, `SRA`), ensuring padded zeros or extended sign vectors are correctly aligned.

---

## Circuit Core Truth Table

| Shift_Ctl | Ctrl_Dir | Ctrl_Arith | Shamt | Output Bit Transformations ($Y[31:0]$)                                                  | Equivalent Instruction |
| :-------: | :------: | :--------: | :---: | :-------------------------------------------------------------------------------------- | :--------------------- |
|     1     |    0     |     0      |  $K$  | Bits are cyclically rotated right by $K$ slots. Upper bits wrap to bottom.              | `ror` / `rori`         |
|     0     |    1     |     0      |  $K$  | Control unit calculates $32 - K$; core shifts right. Lower $K$ slots are forced to `0`. | `sll` / `slli`         |
|     0     |    0     |     0      |  $K$  | Bits shift right by $K$ slots; upper $K$ slots are injected with `0`.                   | `srl` / `srli`         |
|     0     |    0     |     1      |  $K$  | Bits shift right by $K$ slots; upper $K$ slots replicate $DataIn[31]$.                  | `sra` / `srai`         |
|     0     |    X     |     X      |   0   | Control equation drops `MUX_Sel` to `0`. Core passes original data unmodified.          | Shift by 0 NOP         |
