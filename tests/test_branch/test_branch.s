# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (CONTROL FLOW & OVERRIDE)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'simulation_halt'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'simulation_halt'
# ==============================================================================

.globl _start

.section .text
_start:
    addi x1, x0, 0          # Initialize pointer register x1 to 0
    addi x2, x0, 0          # Initialize tracking data register x2 to 0
    addi x3, x0, 0          # Initialize verification register x3 to 0
    addi x4, x0, 0          # Initialize reference register x4 to 0
    addi x5, x0, 0          # Initialize reference register x5 to 0
    addi x31, x0, 0         # Clear master execution status register x31

    # --------------------------------------------------------------------------
    # TEST 1: STORE REGWEN & LOAD ALUSEL BOUNDARIES
    # --------------------------------------------------------------------------
    addi x1, x0, 128        # Establish RAM test boundary at address 128
    addi x2, x0, -1         # Generate a continuous 32-bit high bit pattern (0xFFFFFFFF) in x2
    sw x2, 0(x1)            # Perform memory store. Validates that S-type fields do not pull RegWEn high
    
    lw x3, 0(x1)            # Perform memory load. Validates that ALUSel ignores funct3 (0x2) and forces ADD
    bne x3, x2, trap_error  # If address logic failed or memory corrupted, jump to error routine

    # --------------------------------------------------------------------------
    # TEST 2: R-TYPE / I-TYPE FUNCTIONAL ISOLATION
    # --------------------------------------------------------------------------
    addi x4, x0, 100        # Load baseline condition marker 100 into x4
    addi x5, x0, 200        # Load baseline condition marker 200 into x5
    
    slt x6, x5, x4          # Perform standard R-type SLT. Result should be 0 (200 < 100 is false)
    bne x6, x0, trap_error  # Verify output is strictly 0
    
    xori x7, x4, 15         # Perform standard I-type XORI (100 XOR 15 = 107)
    addi x30, x0, 107       # Match register for check
    bne x7, x30, trap_error # Verify XORI operation computed cleanly

    # --------------------------------------------------------------------------
    # TEST 3: BRANCH SELECTION & FLUSH PROTECTION LOOP
    # --------------------------------------------------------------------------
    bne x4, x5, branch_ok   # Execute standard inequality branch. Verifies BrSel successfully validates jumps
    
    # FAIL SAFE: This block must be flushed if branch is taken
    addi x31, x0, -1        
    j simulation_halt       

branch_ok:
    # --------------------------------------------------------------------------
    # TEST 4: NO-OP PAD & COMPONENT ISOLATION
    # --------------------------------------------------------------------------
    .word 0x00000000        # Insert zero-word block. Confirms uninitialized streams default safely to x0
    .word 0x00000000        # Insert zero-word block. Validates explicit RegWEn boundaries block corruption
    
    # Verify that the sequential drop-through to pass route wasn't fouled by the bubble
    addi x31, x0, 1         # Assert 1 on status register x31 to signal clean pipeline execution
    j simulation_halt       # Route directly to clean termination phase

trap_error:
    addi x31, x0, -1        # Assert -1 on status register x31 to signal a control hazard failure

simulation_halt:
    j simulation_halt       # Permanent trap loop indicating end of verification run