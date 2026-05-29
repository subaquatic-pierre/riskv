.global _start

_start:
    # Test 1: Standard I-Type Math & Immed Select
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 20      # x2 = 20

    # Test 2: SLT Operation (10 < 20 should be True)
    slt  x3, x1, x2      # x3 should become 0x00000001
    
    # Test 3: SLT Operation (20 < 10 should be False)
    slt  x4, x2, x1      # x4 should become 0x00000000

    # Test 4: Trigger your System Exception Control
    ebreak               # Stops execution, activates your interlock gates