# Risk-V Implementation

# RV32I Arithmetic & Logic Core Components

Phase 5: The Control Units (The Brain)
Before you drop everything onto one canvas, you need the circuits that read the instruction bits and orchestrate the control lines (like RegWrite, W_En, ImmSel, and your ALU operations).

1. Main Control Decoder Circuit
   What it does: Takes the 7-bit opcode (bits [6:0] of the instruction) and outputs primary execution flags.

Outputs to generate: RegWrite (enable register writes), ALUSrc (choose between Register Port 2 or the Immediate Generator output), MemRead/MemWrite (data memory signals), and Branch (tells the system an evaluation is happening).

2. ALU Control Decoder Circuit
   What it does: A secondary decoding block that combines the ALUOp signals from the main controller with the instruction's funct3 (bits [14:12]) and funct7 (bit 30).

Why it matters: It keeps the main decoder lean. This sub-circuit handles routing the precise 3-bit operations to your AdderSub32, UniversalShifter, and BitwiseLogicUnit.

Phase 6: Top-Level Datapath Integration
This is where you stop creating new components and begin your master wiring assembly on the main canvas (main circuit).

3. Integrated Arithmetic Logic Unit (ALU Shell)
   What it does: You will create a single unified ALU shell. Inside, you place your AdderSub32, UniversalShifter, and BitwiseLogicUnit in parallel.

The Routing Layer: You add a large 32-bit output multiplexer controlled by your ALU Control Decoder to select which mathematical unit's result gets passed out of the ALU.

4. Memory-Interface Alignment Logic
   What it does: A small combinational block sitting between your CPU registers and the data memory.

Why it matters: RISC-V requires byte and half-word operations (lb, lh, sb, sh). This block handles shifting and sign-extending data when reading or writing fractions of a 32-bit word from memory.

Phase 7: The Final System Shell 5. The Unified Core Canvas (Core)
The final assembly circuit. You stitch the complete circular loop together:

Connect the Program Counter output to the Instruction Memory address line.

Split the returning 32-bit instruction bus and route the address bits to the Register File, the format bits to the Immediate Generator, and the operational bits to your Control Decoders.

Feed the outputs of the Register File and Immediate Generator directly into your ALU Shell.

Loop the final calculation or memory output back around into the Register File's W_Data port.

Once Phase 5 is laid down, your processor will officially transition from a collection of parts into a self-directed, executing machine.

Are you ready to design the Main Control Decoder logic matrix next?
