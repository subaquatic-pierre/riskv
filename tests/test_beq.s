.global _start

_start:
    # Setup matching values
    addi x1, x0, 5        # x1 = 5
    addi x2, x0, 5        # x2 = 5

    # Test Taken Branch: x1 == x2 (5 == 5)
    # PCSel must go high (1) and jump to 'target'
    beq x1, x2, target
    
    # FAIL SAFE: This must be skipped. If hit, branch tracking failed.
    addi x3, x0, 99       

target:
    # Test Non-Taken Branch: x1 == x3 (5 == 0, since x3 was skipped)
    # PCSel must stay low (0) and fall through
    beq x1, x3, fail_trap

    # SUCCESS: Execution falls here cleanly. Trigger your success trap.
    ebreak               

fail_trap:
    # If your non-taken branch accidentally jumped, you land here.
    ecall