.global _start

_start:
    # Setup a test value
    addi x1, x0, 42       # x1 = 42

    # The test is over, enter an infinite loop to hold the state
trap_loop:
    jal x0, trap_loop     # Jump right back to 'trap_loop' forever