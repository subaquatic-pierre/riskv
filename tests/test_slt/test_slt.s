# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (I-TYPE & ENVIRONMENT CALLS)
# = Expected Success Outcome: x31 will contain 1, core will trap at 'ebreak_handler'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'fault'
# ==============================================================================

.global _start

.section .text
_start:
    # =========================================================================
    # 1. INITIALIZATION & STATE CLEANUP
    # =========================================================================
    addi x1, x0, 0          # Reset tracking register x1
    addi x2, x0, 0          # Reset tracking register x2
    addi x3, x0, 0          # Reset validation register x3
    addi x4, x0, 0          # Reset validation register x4
    lui  x31, 0x00000       # Clear master execution status register x31 to 0

    # =========================================================================
    # 2. STANDARD I-TYPE MATH & IMMED SELECT
    # =========================================================================
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 20      # x2 = 20

    # =========================================================================
    # 3. SLT OPERATION (TRUE CONDITION)
    # =========================================================================
    slt  x3, x1, x2      # x3 should become 0x00000001 (10 < 20 is True)
    addi x30, x0, 1      # Match register
    bne  x3, x30, fault  # Verify SLT true-state output execution

    # =========================================================================
    # 4. SLT OPERATION (FALSE CONDITION)
    # =========================================================================
    slt  x4, x2, x1      # x4 should become 0x00000000 (20 < 10 is False)
    bne  x4, x0, fault   # Verify SLT false-state output execution

    # =========================================================================
    # 5. EXCEPTION HANDLING PREPARATION & SYSTEM CALL
    # =========================================================================
    # Write success flag before the software breakpoint trap.
    # If the core handles ebreak correctly, x31 remains 1. 
    # If the interlock fails or executes rogue behavior, it may branch to fault.
    addi x31, x0, 1      
    jal x0, terminal     # Infinite loop holding core simulation static
    
fault:
    addi x31, x0, -1     # Write core error identifier -1 to register x31

terminal:
    jal x0, terminal     # Infinite loop holding core simulation static