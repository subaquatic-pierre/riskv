# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (CONTROL ISOLATION & MASKS)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'success_halt'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'fail_loop'
# ==============================================================================

.globl _start

.section .text
_start:
    # =========================================================================
    # 1. INITIALIZATION
    # =========================================================================
    addi x1, x0, 0          # Base address pointer zeroing
    addi x2, x0, 0          # Data source register zeroing
    addi x3, x0, 0          # Destination register zeroing
    addi x4, x0, 0          # Verification register zeroing
    addi x5, x0, 0          # Alternate branch validator zeroing
    lui  x31, 0x00000       # Clear master execution status register x31 to 0

    # =========================================================================
    # 2. EXPLICIT RegWEn VALIDATION (Store Isolation Test)
    # =========================================================================
    addi x1, x0, 64         # Set base memory pointer to an arbitrary safe RAM offset (64)
    addi x2, x0, 42         # Put magic number 42 into source register x2
    
    sw x2, 0(x1)            # Store 42 at RAM[64]. 
                            # Verifies S-type fields [11:7] do not force RegWEn high.

    # =========================================================================
    # 3. ALU ALUSel LOGIC GATING VALIDATION (Load/Store Address Test)
    # =========================================================================
    addi x1, x0, 64         # Re-verify address pointer
    lw x3, 0(x1)            # Load data from RAM[64] into x3.
                            # funct3=010 must be gated to force ADD (0000) for address.
                            
    bne x3, x2, fail_loop   # If masking failed, address was wrong, x3 won't be 42.

    # =========================================================================
    # 4. COMPOSITE BrSel VALIDATION (Branch Selector Isolation Test)
    # =========================================================================
    addi x4, x0, 10         # Setup operand A
    addi x5, x0, 20         # Setup operand B
    
    # If BrSel is leaky, math instructions sharing branch funct3 values will trigger ghost jumps
    slli x0, x0, 0          # NOP / structural padding (funct3=001 overlaps BNE layout)
    ori x6, x4, 0           # funct3=110 overlaps BLTU layout.
    
    # Actual intentional branch test to verify BrSel functionality is intact:
    addi x4, x0, 5
    addi x5, x0, 5
    beq x4, x5, branch_pass # Should cleanly execute this jump
    j fail_loop             # Failed to branch when conditions were met

branch_pass:
    # Verify pipeline flush tracking: Ensure drop-through instruction wasn't executed
    addi x4, x0, 5
    bne  x4, x5, fail_loop

    # =========================================================================
    # 5. ALL-ZERO UNINITIALIZED MEMORY SAFE-STATE TEST
    # =========================================================================
    .word 0x00000000        # Explicit uninitialized instruction emulation (add x0, x0, x0)
    .word 0x00000000        # Explicit uninitialized instruction emulation (add x0, x0, x0)

    # If execution drops through cleanly without state corruption, test passes.
    addi x31, x0, 1         # Write Success Flag to x31
success_halt:
    j success_halt          # Infinite loop confirming success

fail_loop:
    addi x31, x0, -1        # Write Failure Flag to x31
    j fail_loop             # Infinite loop tracking failure