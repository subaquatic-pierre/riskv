# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (OPCODE MASKING & ISOLATION)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'terminal'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'terminal'
# ==============================================================================

.globl _start

.section .text
_start:
    # =========================================================================
    # 1. INITIALIZATION & RE-ZEROING
    # =========================================================================
    addi x1, x0, 0          # Reset base reference register x1
    addi x2, x0, 0          # Reset test value register x2
    addi x3, x0, 0          # Reset validation target register x3
    addi x4, x0, 0          # Reset execution check register x4
    addi x5, x0, 0          # Reset execution check register x5
    lui  x31, 0x00000       # Clear diagnostic result register x31 to 0

    # =========================================================================
    # 2. S-TYPE REGWEN & I-TYPE ALUSEL ADDRESS CHECK
    # =========================================================================
    addi x1, x0, 252        # Set boundary memory reference address to 252
    addi x2, x0, 1024       # Load unique identifier pattern 1024 into x2
    sw x2, 0(x1)            # Execute store. Verifies S-type opcode isolates RegWEn
    
    lw x3, 0(x1)            # Execute load. Verifies ALUSel overrides funct3=010 to run ADD
    bne x3, x2, fault       # Divert to failure track if loaded value does not match 1024

    # =========================================================================
    # 3. GATING ISOLATION VERIFICATION (FUNCT3 OVERLAP PREVENTION)
    # =========================================================================
    addi x4, x0, 0          # Clear comparison operand x4 to zero
    addi x5, x0, 1          # Set comparison operand x5 to one
    
    srl x6, x5, x5          # funct3=101 matches BGE. If BrSel isn't gated, triggers a ghost branch.
    slti x7, x4, 0          # funct3=010 matches BLT. If BrSel isn't gated, triggers a ghost branch.

    # =========================================================================
    # 4. CONDITIONAL BRANCH EXECUTION & FLUSH PROTECTION
    # =========================================================================
    blt x4, x5, pass_route  # Execute conditional branch. Verifies BrSel[0] allows genuine jumps
    
    # FAIL SAFE: Pipeline must flush this block on a taken branch
    addi x31, x0, -1        
    j terminal              

pass_route:
    # Verify pipeline flush tracking: Ensure drop-through instruction wasn't executed
    addi x30, x0, -1
    beq  x31, x30, terminal

    # =========================================================================
    # 5. ALL-ZERO UNINITIALIZED MEMORY SAFE-STATE TEST
    # =========================================================================
    .word 0x00000000        # Pad stream with uninitialized space to check R-type fallback handling
    .word 0x00000000        # Pad stream with uninitialized space to confirm explicit RegWEn masking
    
    addi x31, x0, 1         # Write confirmation status code 1 to register x31
    j terminal              # Branch to clean end of execution routing

fault:
    addi x31, x0, -1        # Write error status code -1 to register x31

terminal:
    j terminal              # Spin in hardware simulation trap loop to conclude execution run