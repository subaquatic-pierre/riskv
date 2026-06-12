# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (BRANCH CONTROL & FLUSH)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'halt'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'halt'
# ==============================================================================

.global _start

.section .text
_start:
    lui   x31, 0x00000       # Clear diagnostic tracking register x31 to 0
    addi  x3, x0, 0          # Hard-initialize x3 to 0

    # Setup matching values
    addi x1, x0, 5        # x1 = 5
    addi x2, x0, 5        # x2 = 5

    # Test Taken Branch: x1 == x2 (5 == 5)
    # PCSel must go high (1), jump to 'target', and flush the pipeline bubble (addi x3, x0, 99)
    beq x1, x2, target
    
    # FAIL SAFE / FLUSH TRACKING TRAP
    # This instruction must be flushed out of the pipeline. 
    # If the hardware fails to flush on a taken branch, x3 will become 99.
    addi x3, x0, 99       

target:
    # Verify the flush occurred: if addi was executed, x3 == 99, causing an immediate failure loop
    addi x4, x0, 99
    beq  x3, x4, fail_trap

    # Test Non-Taken Branch: x1 == x3 (5 == 0, since x3 was successfully skipped/flushed)
    # PCSel must stay low (0) and fall through cleanly
    beq x1, x3, fail_trap

    # SUCCESS: Execution falls here cleanly. Trigger your success trap.
    addi x31, x0, 1
    jal x0, halt               

fail_trap:
    # Landed here either because:
    # 1. The branch flush mechanism failed, executing 'addi x3, x0, 99'
    # 2. The non-taken branch mispredicted and jumped when it shouldn't
    addi x31, x0, -1

halt:
    jal x0, halt