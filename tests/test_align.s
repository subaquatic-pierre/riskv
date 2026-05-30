.globl _start

.section .text
_start:
  lui   x2, 0xDEADC        # Setup test word pattern
  addi  x2, x2, -273       # x2  = 0xDEADBEEF
  addi  x3, x0, 255        # x3  = 0x000000FF (Byte boundary check)
  lui   x4, 0x55555        # Setup alternative pattern
  addi  x4, x4, 1365       # x4  = 0x55555555
  addi  x5, x0, 0          # x5  = Aligned address (Offset 00) -> 0x00000000
  addi  x6, x0, 1          # x6  = Unaligned address (Offset 01) -> 0x00000001
  addi  x7, x0, 2          # x7  = Unaligned address (Offset 10) -> 0x00000002
  addi  x8, x0, 3          # x8  = Unaligned address (Offset 11) -> 0x00000003
  addi  x9, x0, 128        # x9  = 0x00000080 (MSB of byte is 1)
  addi  x25, x0, 127       # x25 = 0x0000007F (MSB of byte is 0)
  sw    x2, 0(x5)          # [MEM] Slot 0 = 0xDEADBEEF
  lw    x10, 0(x5)         # x10 = 0xDEADBEEF
  sb    x3, 0(x5)          # [MEM] Overwrites DE with FF -> 0xFFADBEEF
  lb    x11, 0(x5)         # x11 = 0xFFFFFFFF (Signed read of 0xFF)
  lbu   x12, 0(x5)         # x12 = 0x000000FF (Unsigned read of 0xFF)
  sb    x4, 0(x6)          # [MEM] Overwrites AD with 55 -> 0xFF55BEEF
  lb    x13, 0(x6)         # x13 = 0x00000055 (Signed read of 0x55 at offset 01)
  sb    x3, 0(x7)          # [MEM] Overwrites BE with FF -> 0xFF55FFEF
  lb    x14, 0(x7)         # x14 = 0xFFFFFFFF (Signed read of 0xFF at offset 10)
  sb    x4, 0(x8)          # [MEM] Overwrites EF with 55 -> 0xFF55FF55
  lbu   x15, 0(x8)         # x15 = 0x00000055 (Unsigned read of 0x55 at offset 11)
  lw    x16, 0(x5)         # x16 = 0xFF55FF55 (Verify complete altered word via aligned register)
  sw    x2, 0(x5)          # Reset memory to 0xDEADBEEF
  sh    x4, 0(x5)          # [MEM] Overwrites DEAD with 5555 -> 0x5555BEEF
  lh    x17, 0(x5)         # x17 = 0x00005555 (Signed read)
  sh    x2, 0(x7)          # [MEM] Overwrites BEEF with BEEF (no change) -> 0x5555BEEF
  lh    x18, 0(x7)         # x18 = 0xFFFFBEEF (Signed read at offset 10)
  lhu   x19, 0(x7)         # x19 = 0x0000BEEF (Unsigned read at offset 10)
  sw    x2, 0(x5)          # Reset memory to 0xDEADBEEF
  sh    x4, 0(x6)          # [MEM] Active mask 0110. Overwrites AD and BE with 5555 -> 0xDE5555EF
  lb    x21, 0(x6)         # x21 = 0x00000055 (Read Byte 2 via x6)
  lb    x22, 0(x7)         # x22 = 0x00000055 (Read Byte 1 via x7)
  lh    x23, 0(x6)         # x23 = 0x00005555 (Read unaligned half-word via x6)
  lw    x24, 0(x5)         # x24 = 0xDE5555EF (Verify final layout structure via aligned x5)
  sw    x2, 0(x5)          # Reset memory to 0xDEADBEEF
  sb    x9, 1(x6)          # [MEM] Store 0x80 into Byte 1 via address x6+1 (offset 10) -> 0xDEAD80EF
  lb    x26, 0(x7)         # x26 = 0xFFFFFF80 (Signed read verifies negative byte sign extension)
  sb    x25, 1(x6)         # [MEM] Store 0x7F into Byte 1 via address x6+1 (offset 10) -> 0xDEAD7FEF
  lb    x27, 0(x7)         # x27 = 0x0000007F (Signed read verifies positive byte zero extension)
  sw    x4, 0(x6)          # Execute full sw using unaligned address register x6
  lw    x28, 0(x5)         # x28 = 0x55555555 (Verifies Word signal overrides mis_align block completely)