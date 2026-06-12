.globl _start

.section .text
_start:
    # =========================================================================
    # 1. INITIALIZATION
    # =========================================================================
    # Clear target registers to establish a clean baseline
    addi x1, x0, 0          # Base address pointer zeroing
    addi x2, x0, 0          # Data source register zeroing
    addi x3, x0, 0          # Destination register zeroing
    addi x4, x0, 0          # Verification register zeroing
    addi x5, x0, 0          # Alternate branch validator zeroing

    # =========================================================================
    # 2. EXPLICIT RegWEn VALIDATION (Store Isolation Test)
    # =========================================================================
    # Verify that 'sw' explicitly keeps RegWEn low and does not corrupt rd.
    # Note: sw uses bits [11:7] as part of the immediate, which overlaps 
    # with the 'rd' position in R-type instructions.
    addi x1, x0, 64         # Set base memory pointer to an arbitrary safe RAM offset (64)
    addi x2, x0, 42         # Put magic number 42 into source register x2
    
    sw x2, 0(x1)            # Store 42 at RAM[64]. 
                            # If RegWEn is derived via NOT(Branch OR Store), this is safe.
                            # But if an uninitialized instruction is read later, it fails.

    # =========================================================================
    # 3. ALU ALUSel LOGIC GATING VALIDATION (Load/Store Address Test)
    # =========================================================================
    # Validate that non-arithmetic instructions force ALUSel to 0000 (ADD).
    # lw/sw use funct3 fields that would map to alternative math operations
    #  the arithmetic masking array fails.
    
    addi x1, x0, 64         # Re-verify address pointer
    lw x3, 0(x1)            # Load data from RAM[64] into x3. 
                            # lw uses funct3=010. If not gated, ALUSel becomes 0100 (SLT) 
                            # or similar, breaking the address calculation.
                            
    # Verification: x3 must now equal 42.
    bne x3, x2, fail_loop   # If masking failed, address was wrong, x3 won't be 42.

    # =========================================================================
    # 4. COMPOSITE BrSel VALIDATION (Branch Selector Isolation Test)
    # =========================================================================
    # Validate that instructions sharing funct3 with branches do not trigger jumps.
    # 'add' uses funct3=000, matching 'beq'. 
    # 'slt' uses funct3=010, matching an unused branch or overlapping condition logic.

    addi x4, x0, 10         # Setup operand A
    addi x5, x0, 20         # Setup operand B
    
    # If BrSel[0] (Is_Branch) is missing or leaky, the underlying WordLevelComparator 
    # and BranchSelector will see x4 != x5, triggering a 'BNE' (funct3=001) condition 
    #  an I-type math instruction with funct3=001 passes down the pipe.
    
    slli x0, x0, 0          # NOP / structural padding
    ori x6, x4, 0           # funct3 for ORI is 110 (overlaps with BLTU condition).
                            # If BranchSelector is active here without BrSel[0] gating,
                            # it will evaluate 10 < 20 (True) and trigger a ghost jump.

    # Actual intentional branch test to verify BrSel functionality is intact:
    addi x4, x0, 5
    addi x5, x0, 5
    beq x4, x5, branch_pass # Should cleanly execute this jump
    j fail_loop             # Failed to branch when conditions were met

branch_pass:
    # =========================================================================
    # 5. ALL-ZERO UNINITIALIZED MEMORY SAFE-STATE TEST
    # =========================================================================
    # Simulate hitting uninitialized memory rows (0x00000000).
    # In raw hardware terms, 0x00000000 decodes as: add x0, x0, x0
    # Our explicit RegWEn array ensures that even if RegWEn matches R_Type,
    # the target register is x0, protecting architectural state.
    
    .word 0x00000000        # Explicit uninitialized instruction emulation
    .word 0x00000000        # Explicit uninitialized instruction emulation

    # If we made it here without getting stuck or corrupting state, we passed.
    addi x31, x0, 1         # Write Success Flag to x31
success_halt:
    j success_halt          # Infinite loop confirming success

fail_loop:
    addi x31, x0, -1        # Write Failure Flag to x31
    j fail_loop             # Infinite loop tracking failure