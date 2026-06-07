.globl _start

.section .text
_start:

  # ==========================================
  # SETUP REFERENCE REGISTERS (Expected Final State)
  # ==========================================
  # Pre-calculated and loaded into reference registers (x20-x30)
  # to match the correct mathematical outputs for a 32-bit hardware execution unit.

  addi x20, x0, -60         # x20: Expected final state of x4  (Test 1: mul)
  addi x21, x0, 1           # x21: Expected final state of x5  (Test 2: mulh)
  addi x22, x0, -2          # x22: Expected final state of x6  (Test 3: mulhu -> 0xFFFFFFFE)
  addi x23, x0, -1          # x23: Expected final state of x7  (Test 4: mulhsu)

  addi x24, x0, -6          # x24: Expected final state of x8  (Test 5: div)
  lui x25, 0x55555        # x25: Expected final state of x9 (Test 7: divu)
  addi x25, x25, 1358
  addi x26, x0, -2          # x26: Expected final state of x10 (Test 7: rem)
  addi x27, x0, 2           # x27: Expected final state of x11 (Test 8: remu)
  
  # Load 0x80000000 into x30 (Test 10: div overflow)
  lui  x30, 0x80000      

  # ==========================================
  # EXECUTE TESTS
  # ==========================================

  # TEST 1: mul (Lower 32 bits, Signed/Unsigned)
  # 12 * -5 = -60 (0xFFFFFFC4)
  addi x1, x0, 12       # rs1 = 12
  addi x2, x0, -5       # rs2 = -5
  mul  x4, x1, x2       # x4 = -60
  bne  x4, x20, failed 

  # TEST 2: mulh (Upper 32 bits, Signed x Signed)
  # -2147483648 * -2 = +4294967296 (64-bit hex: 0x00000001_00000000)
  # Upper 32 bits = 0x00000001
  lui  x1, 0x80000      # rs1 = 0x80000000 (-2147483648)
  addi x2, x0, -2       # rs2 = -2
  mulh x5, x1, x2       # x5 = 1
  bne  x5, x21, failed

  # TEST 3: mulhu (Upper 32 bits, Unsigned x Unsigned)
  # 4294967295 * 4294967295 = 18446744069414584321 (64-bit hex: 0xFFFFFFFE_00000001)
  # Upper 32 bits = 0xFFFFFFFE (-2)
  addi x1, x0, -1       # rs1 = 0xFFFFFFFF
  addi x2, x0, -1       # rs2 = 0xFFFFFFFF
  mulhu x6, x1, x2      # x6 = 0xFFFFFFFE
  bne  x6, x22, failed

  # TEST 4: mulhsu (Upper 32 bits, Signed x Unsigned)
  # -1 * 2 = -2 (64-bit hex: 0xFFFFFFFF_FFFFFFFE)
  # Upper 32 bits = 0xFFFFFFFF (-1)
  addi x1, x0, -1       # rs1 = -1 (Signed)
  addi x2, x0, 2        # rs2 = 2  (Unsigned)
  mulhsu x7, x1, x2     # x7 = 0xFFFFFFFF (-1)
  bne  x7, x23, failed

  # SET registers for Divide and Remainder signed and unsigned
  addi x1, x0, -20      # rs1 = -20
  addi x2, x0, 3        # rs2 = 3

  # TEST 5: div (Signed Division)
  div  x8, x1, x2       # x8 = -6
  bne  x8, x24, failed

  # TEST 6: divu (Unsigned Division)
  divu x9, x1, x2       # x9 = 1431655758
  bne  x9, x25, failed

  # TEST 7: rem (Signed Remainder)
  rem  x10, x1, x2      # x10 = -2
  bne  x10, x26, failed

  # TEST 8: remu (Unsigned Remainder)
  remu x11, x1, x2      # x11 = 2
  bne  x11, x27, failed

success:
  addi x31, x0, 1       # Signify pass
  j halt

failed:
  addi x31, x0, -1      # Signify fail
  j halt

halt:
  jal x0, halt