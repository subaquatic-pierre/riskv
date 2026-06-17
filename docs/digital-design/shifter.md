# Integrated Barrel Shifter

## Functional Overview

The **Integrated Barrel Shifter** is a single-cycle execution unit that handles logical left/right shifts, arithmetic right shifts, and cyclic rotations. Masking, padding, and direction control logic are integrated directly into the core shifter multiplexers.

---

## Structural Composition (The RotN Cascade)

The physical core is implemented as a 5-stage log-scaled right-shifting cascade (`Rot1`, `Rot2`, `Rot4`, `Rot8`, and `Rot16`).

- **Stage Conditioning:** Each stage evaluates one bit of the 5-bit shift amount (`Shamt[i]`). If `Shamt[i] = 1`, the data lines shift right by $2^i$ positions; if `Shamt[i] = 0`, the data lines pass through unmodified.
- **Hardware Bias:** The internal wiring is optimized exclusively for rightward bit movement.

---

## Left-Shift Optimization via Arithmetic Inversion

To avoid duplicating the multiplexer cascade with left-handed wiring, a **Conditional Bitwise Inverter** on the control path maps left shifts into right rotations.

In a 32-bit architecture, a left shift by magnitude $K$ is equivalent to a right rotation by magnitude $32 - K$:

$$\text{Shift\_Left}(K) \equiv \text{Rotate\_Right}(32 - K)$$

When `Ctrl_Dir = 1` (Left Shift), the inverter flips the control lines driving the `RotN` stages (`~Shamt[4:0]`), computing the one's complement ($31 - K$). This allows left shifts to run natively through the right-handed datapath.

---

## The Universal Mask Generator (`MaskGenUni`)

The module embeds a unified combinational engine called `MaskGenUni` to isolate shifted windows and handle arithmetic sign extension. This sub-circuit mirrors the main shifter cascade and generates 32-bit masks via cyclic bit rotation of a uniform seed vector.

### Staged Seed Selection & Inversion Routing

1. **Dynamic Seed Vector Selection:** The sub-circuit initializes its input bus with a uniform seed vector via a multiplexer selecting between all ones (`32'hFFFF_FFFF`) or all zeros (`32'h0000_0000`).
   - For arithmetic right shifts (`SRA`), if the operand's sign bit ($DataIn[31]$) is high, an all-ones seed is used; if low, an all-zeros seed is used.
   - For logical shifts, the seed matches boundary padding requirements.
2. **Inverse Magnitude Controls:** The control bus driving the `MaskGenUni` rotator stages receives the bitwise inversion of the shift amount (`~Shamt[4:0]`).

Passing the uniform seed through the right-handed barrel rotator controlled by the inverted shift magnitude aligns the wrap-around lanes to form the mask boundary.

### Generated Output Masks

A single traversal of the `MaskGenUni` cascade generates two operational masks simultaneously:

- **The Isolation Mask:** A binary window used during logical shifts (`SLL`, `SRL`) to isolate valid shifted data and force out-of-bounds wrapped bits to `0`.
- **The Arithmetic Extension Mask:** A sign-extension vector used during arithmetic right shifts (`SRA`) to map the sampled $DataIn[31]$ sign bit pattern across the upper bits vacated by the shift.

---

## The Dual-Highway Isolation Matrix

The core output routes across two parallel paths before final bus selection:

- **Highway 0 (Pure Rotate Highway):** Connects the unconstrained cyclic output of the core directly to the final multiplexer stage for `ROL` and `ROR` results.
- **Highway 1 (Shift Highway):** Carries the results of the core running under active stage-conditioning limits (`SLL`, `SRL`, `SRA`), ensuring padded zeros or extended sign vectors are correctly aligned.

---

## Circuit Core Truth Table

| Shift_Ctl | Ctrl_Dir | Ctrl_Arith | Shamt | Output Bit Transformations ($Y[31:0]$)                                                  | Equivalent Instruction |
| :-------: | :------: | :--------: | :---: | :-------------------------------------------------------------------------------------- | :--------------------- |
|     1     |    0     |     0      |  $K$  | Bits are cyclically rotated right by $K$ slots. Upper bits wrap to bottom.              | `ror` / `rori`         |
|     0     |    1     |     0      |  $K$  | Control unit calculates $32 - K$; core shifts right. Lower $K$ slots are forced to `0`. | `sll` / `slli`         |
|     0     |    0     |     0      |  $K$  | Bits shift right by $K$ slots; upper $K$ slots are injected with `0`.                   | `srl` / `srli`         |
|     0     |    0     |     1      |  $K$  | Bits shift right by $K$ slots; upper $K$ slots replicate $DataIn[31]$.                  | `sra` / `srai`         |
|     0     |    X     |     X      |   0   | Control equation drops `MUX_Sel` to `0`. Core passes original data unmodified.          | Shift by 0 NOP         |
