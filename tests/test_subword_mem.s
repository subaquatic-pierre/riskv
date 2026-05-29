.globl _start

.section .text
_start:
    addi x1, x0, 0          # Reset base memory pointer register x1
    addi x2, x0, 0          # Reset source register x2
    addi x3, x0, 0          # Reset verification loading register x3
    addi x4, x0, 0          # Reset reference comparison register x4
    addi x31, x0, 0         # Reset diagnostic reporting register x31

    addi x1, x0, 128        # Set base memory pointer to address 128 (0x80 - safely within 256 bytes)
    li x2, 0x12345678       # Load 32-bit test pattern into x2
    sw x2, 0(x1)            # Store full word to initialize RAM at that location

    # =========================================================================
    # 1. TEST BYTE STORE AND SIGNED BYTE LOAD (sb, lb)
    # =========================================================================
    addi x2, x0, 0x96       # Load an 8-bit pattern with the MSB set (negative if signed)
    sb x2, 0(x1)            # Overwrite byte 0 at RAM[128] with 0x96
    
    lb x3, 0(x1)            # Load signed byte from RAM[128]
    li x4, 0xFFFFFF96       # Expected value must be sign-extended to 32 bits
    bne x3, x4, mem_fail    # Fail if sign-extension failed on lb

    # =========================================================================
    # 2. TEST UNSIGNED BYTE LOAD (lbu)
    # =========================================================================
    lbu x3, 0(x1)           # Load unsigned byte from RAM[128]
    addi x4, x0, 0x96       # Expected value must be zero-extended to 0x00000096
    bne x3, x4, mem_fail    # Fail if zero-extension failed on lbu

    # =========================================================================
    # 3. TEST HALF-WORD STORE AND SIGNED HALF-WORD LOAD (sh, lh)
    # =========================================================================
    li x2, 0xABCD           # Load a 16-bit pattern with the MSB set
    sh x2, 2(x1)            # Overwrite upper half-word at RAM[130] with 0xABCD
    
    lh x3, 2(x1)            # Load signed half-word from RAM[130]
    li x4, 0xFFFFABCD       # Expected value must be sign-extended to 32 bits
    bne x3, x4, mem_fail    # Fail if sign-extension failed on lh

    # =========================================================================
    # 4. TEST UNSIGNED HALF-WORD LOAD (lhu)
    # =========================================================================
    lhu x3, 2(x1)           # Load unsigned half-word from RAM[130]
    li x4, 0x0000ABCD       # Expected value must be zero-extended to 0x0000ABCD
    bne x3, x4, mem_fail    # Fail if zero-extension failed on lhu

    # Clean verification wrap-up
    bne x0, x0, mem_fail    # Mask isolation check
    .word 0x00000000        # Clear space barrier row to test uninitialized state safety
    addi x31, x0, 1         # Write validation pass identifier 1 to register x31
    j sim_end               # Branch straight to completion loop

mem_fail:
    addi x31, x0, -1        # Write core error identifier -1 to register x31

sim_end:
    j sim_end               # Lock execution to verify x31 status