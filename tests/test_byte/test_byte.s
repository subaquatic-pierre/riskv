# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (SUB-WORD MASKING & DATA HARNESS)
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
    addi  x5, x0, 64         # x5 = Aligned base address 64 (Avoid null pointer space)
    addi  x6, x0, 2047       # Pre-load raw positive half-word pattern boundary
    addi  x6, x6, 1          # x6 = 2048 (0x00000800)
    lui   x2, 0xDEADC        # Setup upper 20 bits for raw test word
    addi  x2, x2, -273       # x2 = 0xDEADBEEF (Byte 3=DE, Byte 2=AD, Byte 1=BE, Byte 0=EF)

    # --------------------------------------------------------------------------
    # STEP 1: BYTE STORE MASK & SIGN EXTENSION CHECKS
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # [MEM] Slot 0 = 0xDEADBEEF (Initial full word sync)
    sb    x6, 0(x5)          # [MEM] Addr 00 Store lower byte (0x00) into Byte 3
    lb    x10, 0(x5)         # [RAM] Addr 00 Read Byte 3 (0x00). Expected x10 = 0x00000000
    bne   x10, x0, fault     # Verify hard 0 entry read back matches exactly

    sb    x2, 1(x5)          # [MEM] Addr 01 Store lower byte (0xEF) into Byte 2
    lb    x11, 1(x5)         # [RAM] Addr 01 Read Byte 2 (0xEF). Expected x11 = 0xFFFFFFFF (or 0xFFFFFFEF per comment logic)
    addi  x30, x0, -17       # Match register for signed 0xFFFFFFEF (-17 dec)
    bne   x11, x30, fault

    lbu   x12, 1(x5)         # [RAM] Addr 01 Read Byte 2 Unsigned. Expected x12 = 0x000000EF
    addi  x30, x0, 239       # Match register for unsigned 0x000000EF (239 dec)
    bne   x12, x30, fault

    # --------------------------------------------------------------------------
    # STEP 2: HIGH HALF-WORD MASK & SIGN EXTENSION
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
    sh    x2, 0(x5)          # [MEM] Addr 00 Store lower 16 bits (0xBEEF) to Bytes 3 & 2
    lh    x13, 0(x5)         # [RAM] Addr 00 Read upper half-word. Expected x13 = 0xFFFFBEEF
    lui   x30, 0xFFFFC       # Build match register 0xFFFFB000
    addi  x30, x30, -0x111     # x30 = 0xFFFFBEEF
    bne   x13, x30, fault

    # --------------------------------------------------------------------------
    # STEP 3: LOW HALF-WORD MASK & SIGN/ZERO EXTENSION
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
    sh    x2, 2(x5)          # [MEM] Addr 10 Store lower 16 bits (0xBEEF) to Bytes 1 & 0
    lh    x14, 2(x5)         # [RAM] Addr 10 Read lower half-word. Expected x14 = 0xFFFFBEEF
    bne   x14, x30, fault

    lhu   x15, 2(x5)         # [RAM] Addr 10 Read lower half-word Unsigned. Expected x15 = 0x0000BEEF
    lui   x30, 0x0000C       # Build match register 0x0000B000
    addi  x30, x30, -0x111     # x30 = 0x0000BEEF
    bne   x15, x30, fault

    # --------------------------------------------------------------------------
    # STEP 4: ACTIVE MASK 0110 STRIDE EXECUTIONS
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
    sh    x2, 1(x5)          # [MEM] Addr 01 Active mask 0110 (Writes 0xBEEF to Bytes 2 & 1)
    lb    x16, 1(x5)         # [RAM] Addr 01 Read Byte 2 (0xBE). Expected x16 = 0xFFFFFFBE
    addi  x30, x0, -66       # Match register for signed 0xFFFFFFBE (-66 dec)
    bne   x16, x30, fault

    lb    x17, 2(x5)         # [RAM] Addr 10 Read Byte 1 (0xEF). Expected x17 = 0xFFFFFFEF
    addi  x30, x0, -17       # Match register for signed 0xFFFFFFEF (-17 dec)
    bne   x17, x30, fault

    lh    x18, 1(x5)         # [RAM] Addr 01 Read unaligned half-word. Expected x18 = 0xFFFFBEEF
    lui   x30, 0xFFFFC       # Build match register
    addi  x30, x30, -0x111     # x30 = 0xFFFFBEEF
    bne   x18, x30, fault

    # --------------------------------------------------------------------------
    # STEP 5: PIPELINE CORE AUDIT SINK
    # --------------------------------------------------------------------------
    sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
    lw    x20, 0(x5)         # [RAM] Read full word to audit results. Expected x20 = 0xDEADBEEF
    bne   x20, x2, fault

pass_route:
    addi  x31, x0, 1         # Write successful status flag 1 into register x31
    jal   x0, terminal       # Jump to final halt loop

fault:
    addi  x31, x0, -1        # Write execution fault flag -1 into register x31

terminal:
    jal   x0, terminal       # Infinite loop holding core simulation static