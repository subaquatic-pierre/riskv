.global _start

_start:
    addi x1, x0, 42       # x1 = 42 (Data to store)
    addi x2, x0, 32       # x2 = 32 (Base memory address pointer)

    sw x1, 0(x2) # Write 42 into RAM [32 + 0], MemWrite = 1, MemRead = 0, RegWEn = 0          

    lw x3, 0(x2) # Read RAM [32 + 0] into x3, MemRead = 1, MemWrite = 0, RegWEn = 1, WBSel = 00         

    ebreak # If successful, x3 will hold the value 42 (0x2A).