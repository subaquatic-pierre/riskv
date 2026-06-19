.globl _start

_start:
  # Initialize baseline registers
  addi x1, x0, 0xff       # Test pattern 1 (255)
  addi x2, x0, 0x0f       # Test pattern 2 (15)
  addi x3, x0, 0x00       # Clear register for target tracking
  addi x4, x0, 0x01       # Constant 1 for tracking increments

  # =========================================================================
  # TEST 1: Initial Write & Read-Clear (csrrc)
  # =========================================================================
  # Target: htest0 (0x7C0)
  # Initial state is 0x00. Write 0xFF via csrrw.
  csrrw x3, 0x7C0, x1     # x3 = old htest0 (0), htest0 = x1 (0xFF)
  bne x3, x0, fail        # Ensure old value read was 0

  # Bitwise Clear: Clear the lower 4 bits using x2 (0x0F)
  # Expected outcome: htest0 should become 0xF0. x3 should get old value (0xFF).
  csrrc x3, 0x7C0, x2     # x3 = old htest0 (0xFF), htest0 = 0xFF & ~0x0F = 0xF0
  bne x3, x1, fail        # Verify old value read back was 0xFF

  # Verify the modification stuck
  csrrs x3, 0x7C0, x0     # Read htest0 without modifying it (rs1 = x0)
  addi x5, x0, 0xF0       # Load expected value
  bne x3, x5, fail        # Verify htest0 is exactly 0xF0

  # =========================================================================
  # TEST 2: Immediate Variants (csrrwi, csrrsi, csrrci)
  # =========================================================================
  # Target: htest1 (0x7C1)
  # Write an immediate value of 5
  csrrwi x3, 0x7C1, 5     # x3 = old htest1 (0), htest1 = 5
  bne x3, x0, fail

  # Set bit 4 (value 16) using an immediate mask
  # Expected outcome: htest1 = 5 | 16 = 21 (0x15). x3 should get old value (5).
  csrrsi x3, 0x7C1, 16    # x3 = old htest1 (5), htest1 = 5 | 16 = 21
  addi x5, x0, 5
  bne x3, x5, fail

  # Clear bit 0 (value 1) using an immediate mask
  # Expected outcome: htest1 = 21 & ~1 = 20 (0x14). x3 should get old value (21).
  csrrci x3, 0x7C1, 1     # x3 = old htest1 (21), htest1 = 21 & ~1 = 20
  addi x5, x0, 21
  bne x3, x5, fail

  # Verify immediate modifications stuck
  csrrs x3, 0x7C1, x0     # Read htest1
  addi x5, x0, 20
  bne x3, x5, fail

  # =========================================================================
  # TEST 3: Hardware Performance Counters (cycle)
  # =========================================================================
  # Target: cycle (0xC00)
  # Cycles must increment continually across execution instructions.
  csrrs x1, 0xC00, x0     # Snapshot cycle count at point A
  nop                     # Consume processing steps
  nop
  nop
  csrrs x2, 0xC00, x0     # Snapshot cycle count at point B
  slt x3, x1, x2          # If x1 < x2, x3 = 1
  bne x3, x4, fail        # If cycle didn't advance, crash test

  # =========================================================================
  # TEST 4: Instructions-Retired Counter Validation (instret)
  # =========================================================================
  # Target: instret (0xC02)
  # Every non-bubbled instruction reaching writeback ticks this up.
  csrrs x1, 0xC02, x0     # Snapshot retired instructions count at point A
  addi x5, x0, 1          # 1 instruction
  addi x5, x0, 2          # 2 instructions
  csrrs x2, 0xC02, x0     # Snapshot retired instructions count at point B
  
  # Between point A and B, exactly 2 instructions retired:
  # 1. addi x5, x0, 1
  # 2. addi x5, x0, 2
  sub x3, x2, x1          # Delta = x2 - x1
  addi x5, x0, 2          # Expected delta
  bne x3, x5, fail        # Verify exact structural retirement matches tracking

  # =========================================================================
  # TEST 5: Suppression via Register x0 / Immediate 0
  # =========================================================================
  # Target: htest0 (Current state: 0xF0)
  # If rs1 is x0 during a CSRRS or CSRRC instruction, the write enable (WE)
  # must be suppressed to avoid mutating structural properties inadvertently.
  
  # Attempt to set bits using x0 as source pointer
  csrrs x3, 0x7C0, x0     # Should execute as a pure structural read
  addi x5, x0, 0xF0
  bne x3, x5, fail        # Read must match baseline state

  # Attempt to clear bits using immediate 0 mask
  csrrci x3, 0x7C0, 0     # Should execute as a pure structural read
  bne x3, x5, fail        # Read must match baseline state

  # Final stability test to verify no mutations bypass suppression logic
  csrrs x3, 0x7C0, x0
  bne x3, x5, fail

  j pass

pass:
  csrrwi x0, 0x7C0, 1     # Hardware check matrix code 1: Pass
  j halt

fail:
  csrrwi x0, 0x7C0, 2     # Hardware check matrix code 2: Fail
  j halt

halt:
  j halt