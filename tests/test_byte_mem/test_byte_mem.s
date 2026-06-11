.globl _start

.section .text
_start:
  addi  x5, x0, 0          # x5 = Base address 0
  addi  x6, x0, 2047       # Pre-load raw positive half-word pattern boundary
  addi  x6, x6, 1          # x6 = 2048 (0x00000800)
  lui   x2, 0xDEADC        # Setup upper 20 bits for raw test word
  addi  x2, x2, -273       # x2 = 0xDEADBEEF (Byte 3=DE, Byte 2=AD, Byte 1=BE, Byte 0=EF)
  sw    x2, 0(x5)          # [MEM] Slot 0 = 0xDEADBEEF (Initial full word sync)
  sb    x6, 0(x5)          # [MEM] Addr 00 Store lower byte (0x00) into Byte 3
  lb    x10, 0(x5)         # [RAM] Addr 00 Read Byte 3 (0x00). Expected x10 = 0x00000000
  sb    x2, 1(x5)          # [MEM] Addr 01 Store lower byte (0xEF) into Byte 2
  lb    x11, 1(x5)         # [RAM] Addr 01 Read Byte 2 (0xEF). Expected x11 = 0xFFFFFFEF
  lbu   x12, 1(x5)         # [RAM] Addr 01 Read Byte 2 Unsigned. Expected x12 = 0x000000EF
  sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
  sh    x2, 0(x5)          # [MEM] Addr 00 Store lower 16 bits (0xBEEF) to Bytes 3 & 2
  lh    x13, 0(x5)         # [RAM] Addr 00 Read upper half-word. Expected x13 = 0xFFFFBEEF
  sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
  sh    x2, 2(x5)          # [MEM] Addr 10 Store lower 16 bits (0xBEEF) to Bytes 1 & 0
  lh    x14, 2(x5)         # [RAM] Addr 10 Read lower half-word. Expected x14 = 0xFFFFBEEF
  lhu   x15, 2(x5)         # [RAM] Addr 10 Read lower half-word Unsigned. Expected x15 = 0x0000BEEF
  sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
  sh    x2, 1(x5)          # [MEM] Addr 01 Active mask 0110 (Writes 0xBEEF to Bytes 2 & 1)
  lb    x16, 1(x5)         # [RAM] Addr 01 Read Byte 2 (0xBE). Expected x16 = 0xFFFFFFBE
  lb    x17, 2(x5)         # [RAM] Addr 10 Read Byte 1 (0xEF). Expected x17 = 0xFFFFFFEF
  lh    x18, 1(x5)         # [RAM] Addr 01 Read unaligned half-word. Expected x18 = 0xFFFFBEEF
  sw    x2, 0(x5)          # Restore memory slot 0 to standard baseline 0xDEADBEEF
  lw    x20, 0(x5)         # [RAM] Read full word to audit results. Expected x20 = 0xDEADBEEF

loop:
  jal x0, loop





