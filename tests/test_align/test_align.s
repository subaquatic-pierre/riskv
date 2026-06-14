# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (SUB-WORD & UNALIGNED)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'terminal'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'terminal'
# ==============================================================================

.globl _start

.section .text
_start:
    lui   x31, 0x00000       # Clear diagnostic tracking register x31 to 0

    # --------------------------------------------------------------------------
    # PATTERN & INITIAL REGISTER SETUP
    # --------------------------------------------------------------------------
    lui   x2, 0xDEADC        # Setup test word pattern
    addi  x2, x2, -273       # x2  = 0xDEADBEEF
    addi  x3, x0, 255        # x3  = 0x000000FF (Byte boundary check)
    lui   x4, 0x55555        # Setup alternative pattern
    addi  x4, x4, 1365       # x4  = 0x55555555
    addi  x5, x0, 64         # x5  = Aligned base address 64 (Avoid null pointer space)
    addi  x6, x5, 1          # x6  = Unaligned address (Offset 01)
    addi  x7, x5, 2          # x7  = Unaligned address (Offset 10)
    addi  x8, x5, 3          # x8  = Unaligned address (Offset 11)
    addi  x9, x0, 128        # x9  = 0x00000080 (MSB of byte is 1)
    addi  x25, x0, 127       # x25 = 0x0000007F (MSB of byte is 0)

    # --------------------------------------------------------------------------
    # STEP 1: WORD BASELINE & FIRST BYTE MANIPULATION
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # [MEM] Slot 0 = 0xDEADBEEF
    lw    x10, 0(x5)         # x10 = 0xDEADBEEF
    bne   x10, x2, fault     # Verify initial full word write/read pipeline flow

    sb    x3, 0(x5)          # [MEM] Overwrites DE with FF -> 0xFFADBEEF (Assuming Big-Endian mapping per comments)
    lb    x11, 0(x5)         # x11 = 0xFFFFFFFF (Signed read of 0xFF)
    addi  x30, x0, -1        # Expected 0xFFFFFFFF
    bne   x11, x30, fault

    lbu   x12, 0(x5)         # x12 = 0x000000FF (Unsigned read of 0xFF)
    bne   x12, x3, fault

    # --------------------------------------------------------------------------
    # STEP 2: UNALIGNED BYTE STORES & BOUNDARY SIGN EXTENSION
    # --------------------------------------------------------------------------
    sb    x4, 0(x6)          # [MEM] Overwrites AD with 55 -> 0xFF55BEEF
    lb    x13, 0(x6)         # x13 = 0x00000055 (Signed read of 0x55 at offset 01)
    addi  x30, x0, 85        # Expected 0x00000055 (85 dec)
    bne   x13, x30, fault

    sb    x3, 0(x7)          # [MEM] Overwrites BE with FF -> 0xFF55FFEF
    lb    x14, 0(x7)         # x14 = 0xFFFFFFFF (Signed read of 0xFF at offset 10)
    addi  x30, x0, -1        # Expected 0xFFFFFFFF
    bne   x14, x30, fault

    sb    x4, 0(x8)          # [MEM] Overwrites EF with 55 -> 0xFF55FF55
    lbu   x15, 0(x8)         # x15 = 0x00000055 (Unsigned read of 0x55 at offset 11)
    addi  x30, x0, 85        # Expected 0x00000055
    bne   x15, x30, fault

    lw    x16, 0(x5)         # x16 = 0xFF55FF55 (Verify complete altered word structure)
    lui   x30, 0xFF560       # Build match register
    addi  x30, x30, -0xAB     # x30 = 0xFF55FF55
    bne   x16, x30, fault

    # --------------------------------------------------------------------------
    # STEP 3: HALF-WORD MANIPULATION & ALIGNMENT STRIDEs
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Reset memory to 0xDEADBEEF
    sh    x4, 0(x5)          # [MEM] Overwrites DEAD with 5555 -> 0x5555BEEF
    lh    x17, 0(x5)         # x17 = 0x00005555 (Signed read)
    lui   x30, 0x00005       # Build match register
    addi  x30, x30, 0x555     # x30 = 0x00005555
    bne   x17, x30, fault

    sh    x2, 0(x7)          # [MEM] Overwrites BEEF with BEEF (no change) -> 0x5555BEEF
    lh    x18, 0(x7)         # x18 = 0xFFFFBEEF (Signed read at offset 10)
    lui   x30, 0xFFFFC       # Build match register
    addi  x30, x30, -0x111     # x30 = 0xFFFFBEEF
    bne   x18, x30, fault

    lhu   x19, 0(x7)         # x19 = 0x0000BEEF (Unsigned read at offset 10)
    lui   x30, 0x0000C       # Build match register
    addi  x30, x30, -0x111     # x30 = 0x0000BEEF
    bne   x19, x30, fault

    # --------------------------------------------------------------------------
    # STEP 4: ACTIVE MASK 0110 UNALIGNED INTERACTION
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Reset memory to 0xDEADBEEF
    sh    x4, 0(x6)          # [MEM] Active mask 0110. Overwrites AD and BE with 5555 -> 0xDE5555EF
    lb    x21, 0(x6)         # x21 = 0x00000055 (Read Byte 2 via x6)
    addi  x30, x0, 85        # Expected 0x55
    bne   x21, x30, fault

    lb    x22, 0(x7)         # x22 = 0x00000055 (Read Byte 1 via x7)
    bne   x22, x30, fault

    lh    x23, 0(x6)         # x23 = 0x00005555 (Read unaligned half-word via x6)
    lui   x30, 0x00005
    addi  x30, x30, 0x555     # x30 = 0x00005555
    bne   x23, x30, fault

    lw    x24, 0(x5)         # x24 = 0xDE5555EF (Verify final layout structure via aligned x5)
    lui   x30, 0xDE555       # Build match register
    addi  x30, x30, 1519     # x30 = 0xDE5555EF
    bne   x24, x30, fault

    # --------------------------------------------------------------------------
    # STEP 5: MSB EXTENSION TRAPS
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Reset memory to 0xDEADBEEF
    sb    x9, 1(x6)          # [MEM] Store 0x80 into Byte 1 via address x6+1 (offset 10) -> 0xDEAD80EF
    lb    x26, 0(x7)         # x26 = 0xFFFFFF80 (Signed read verifies negative byte sign extension)
    addi  x30, x0, -128      # Expected 0xFFFFFF80 (-128 dec)
    bne   x26, x30, fault

    sb    x25, 1(x6)         # [MEM] Store 0x7F into Byte 1 via address x6+1 (offset 10) -> 0xDEAD7FEF
    lb    x27, 0(x7)         # x27 = 0x0000007F (Signed read verifies positive byte zero extension)
    bne   x27, x25, fault

    # --------------------------------------------------------------------------
    # STEP 6: BYPASS OVERRIDE CHECK
    # --------------------------------------------------------------------------
    sw    x4, 0(x6)          # Execute full sw using unaligned address register x6
    lw    x28, 0(x5)         # x28 = 0x55555555 (Verifies Word signal overrides mis_align block completely)
    bne   x28, x4, fault

pass_route:
    addi  x31, x0, 1         # Write successful status flag 1 into register x31
    jal   x0, terminal       # Jump to final halt loop

fault:
    addi  x31, x0, -1        # Write execution fault flag -1 into register x31

terminal:
    jal   x0, terminal       # Infinite loop holding core simulation static