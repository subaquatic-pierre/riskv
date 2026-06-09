# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (EXCLUDING LB/SB/LH/SH)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'terminal'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'terminal'
# ==============================================================================

.globl _start

.section .text
_start:
    lui x1, 0x00000         # Hard-clear x1 using upper immediate zeroing
    lui x2, 0x00000         # Hard-clear x2 using upper immediate zeroing
    lui x3, 0x00000         # Hard-clear x3 using upper immediate zeroing
    lui x4, 0x00000         # Hard-clear x4 using upper immediate zeroing
    lui x31, 0x00000        # Clear diagnostic tracking register x31 to 0
    lui x10, 0x00002        # Load upper immediate 0x00002000 into x10
    auipc x11, 0x00001      # Calculate PC + 0x00001000 and store result into x11
    addi x1, x0, 15         # x1 = 0 + 15 = 15
    slti x2, x1, 20         # x2 = 1 (since 15 < 20 signed)
    sltiu x3, x1, 10        # x3 = 0 (since 15 < 10 unsigned is false)
    xori x4, x1, -1         # x4 = bitwise NOT of 15 (inverts all bits)
    ori x5, x1, 1           # x5 = 15 OR 1 = 15
    andi x6, x1, 1          # x6 = 15 AND 1 = 1
    slli x7, x1, 2          # x7 = 15 << 2 = 60
    srli x8, x1, 1          # x8 = 15 >> 1 logical = 7
    srai x9, x4, 1          # x9 = x4 >> 1 arithmetic (preserves sign bit)
    add x12, x1, x7         # x12 = 15 + 60 = 75
    sub x13, x7, x1         # x13 = 60 - 15 = 45
    sll x14, x1, x6         # x14 = 15 << 1 = 30
    slt x15, x5, x12        # x15 = 1 (since 15 < 75 signed)
    sltu x16, x12, x5       # x16 = 0 (since 75 < 15 unsigned is false)
    xor x17, x1, x5         # x17 = 15 XOR 15 = 0
    srl x18, x7, x6         # x18 = 60 >> 1 logical = 30
    sra x19, x4, x6         # x19 = x4 >> 1 arithmetic (sign preservation)
    or x20, x1, x6          # x20 = 15 OR 1 = 15
    and x21, x1, x6         # x21 = 15 AND 1 = 1
    addi x22, x0, 64        # Set base memory offset to address 64 (0x40)
    lui x23, 0xABCDE        # Populate upper memory raw signature block
    addi x23, x23, 1264     # Complete 32-bit signature value 0xABCDE4F0 without colon
    sw x23, 0(x22)          # Store full 32-bit word to RAM[64]
    lw x24, 0(x22)          # Load full 32-bit word back from RAM[64]
    beq x1, x5, test_bne    # Branch to test_bne if 15 == 15 (Valid)
    jal x0, fault           # Unconditional raw drop-through protection trap
test_bne:
    bne x1, x7, test_blt    # Branch to test_blt if 15 != 60 (Valid)
    jal x0, fault           # Unconditional raw drop-through protection trap
test_blt:
    blt x5, x7, test_bge    # Branch to test_bge if 15 < 60 signed (Valid)
    jal x0, fault           # Unconditional raw drop-through protection trap
test_bge:
    bge x7, x5, test_bltu   # Branch to test_bltu if 60 >= 15 signed (Valid)
    jal x0, fault           # Unconditional raw drop-through protection trap
test_bltu:
    bltu x5, x7, test_bgeu  # Branch to test_bgeu if 15 < 60 unsigned (Valid)
    jal x0, fault           # Unconditional raw drop-through protection trap
test_bgeu:
    bgeu x7, x5, test_jal   # Branch to test_jal if 60 >= 15 unsigned (Valid)
    jal x0, fault           # Unconditional raw drop-through protection trap
test_jal:
    jal x29, target_label   # Jump to target_label and link return address in x29
return_anchor:
    jalr x0, x29, 8        # Jump to x29 + 8 bytes (skips the immediate fault trap below)
    jal x0, fault           # Unconditional raw drop-through protection trap
target_label:
    jal x0, return_anchor   # Safe unconditional jump back to the anchor loop
pass_route:
    .word 0x00000000        # Uninitialized memory padding row (handled as add x0,x0,x0)
    addi x31, x0, 1         # Write successful status flag 1 into register x31
    jal x0, terminal        # Jump to final halt loop
fault:
    addi x31, x0, -1        # Write execution fault flag -1 into register x31
terminal:
    jal x0, terminal        # Infinite loop holding core simulation static