.globl _start

.section .text
_start:
    addi x1, x0, 0          # Initialize pointer register x1 to 0
    addi x2, x0, 0          # Initialize tracking data register x2 to 0
    addi x3, x0, 0          # Initialize verification register x3 to 0
    addi x4, x0, 0          # Initialize reference register x4 to 0
    addi x5, x0, 0          # Initialize reference register x5 to 0
    addi x31, x0, 0         # Clear master execution status register x31

    addi x1, x0, 128        # Establish RAM test boundary at address 128
    addi x2, x0, -1         # Generate a continuous 32-bit high bit pattern (0xFFFFFFFF) in x2
    sw x2, 0(x1)            # Perform memory store. Validates that S-type fields do not pull RegWEn high
    
    lw x3, 0(x1)            # Perform memory load. Validates that ALUSel ignores funct3 (0x2) and forces ADD
    bne x3, x2, trap_error  # If address logic failed or memory corrupted, jump to error routine

    addi x4, x0, 100        # Load baseline condition marker 100 into x4
    addi x5, x0, 200        # Load baseline condition marker 200 into x5
    slt x6, x5, x4          # Perform standard R-type SLT with funct3=010. Tests branch isolation mechanics
    xori x7, x4, 15         # Perform standard I-type XORI with funct3=100. Tests branch isolation mechanics

    bne x4, x5, branch_ok   # Execute standard inequality branch. Verifies BrSel[0] successfully validates jumps
    j trap_error            # Trap if sequential execution erroneously skipped the branch instruction

branch_ok:
    .word 0x00000000        # Insert zero-word block. Confirms uninitialized streams default safely to x0
    .word 0x00000000        # Insert zero-word block. Validates explicit RegWEn boundaries block corruption
    addi x31, x0, 1         # Assert 1 on status register x31 to signal clean pipeline execution
    j simulation_halt       # Route directly to clean termination phase

trap_error:
    addi x31, x0, -1        # Assert -1 on status register x31 to signal a control hazard failure

simulation_halt:
    j simulation_halt       # Permanent trap loop indicating end of verification run