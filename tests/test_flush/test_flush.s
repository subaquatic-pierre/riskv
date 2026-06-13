# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (PSEUDO-OP & FLUSH CONTROL)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'core_halt'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'core_halt'
# ==============================================================================

.globl _start

.section .text
_start:
    # =========================================================================
    # 1. INITIALIZATION & CLEAN SLATE
    # =========================================================================
    addi x1, x0, 0          # Reset pointer address register x1
    addi x2, x0, 0          # Reset source data modifier register x2
    addi x3, x0, 0          # Reset verification loading register x3
    addi x4, x0, 0          # Reset test validation operand x4
    addi x5, x0, 0          # Reset test validation operand x5
    lui  x31, 0x00000       # Clear diagnostic reporting register x31 to 0

    # =========================================================================
    # 2. S-TYPE REGWEN & PSEUDO-OP EXPANSION HARNESS
    # =========================================================================
    addi x1, x0, 512        # Set high bounds memory location to address 512
    
    # Replace pseudo-op 'li x2, 8192' with pipeline-safe basic immediate math
    lui  x2, 0x00002        # Load upper immediate 0x00002000 (8192 dec)
    
    sw x2, 0(x1)            # Execute store. Verifies S-type structure restricts RegWEn to low
    
    lw x3, 0(x1)            # Execute load. Verifies ALUSel masks the bus back to ADD (0000)
    bne x3, x2, system_fail # Deflect execution to error loop if signature verification fails

    # =========================================================================
    # 3. GATING ISOLATION VERIFICATION (FUNCT3 SHADOW PREVENTION)
    # =========================================================================
    addi x4, x0, 15         # Assign data sample value 15 to x4
    addi x5, x0, -15        # Assign data sample value -15 to x5
    
    and x6, x4, x5          # funct3=111 matches BGEU. If BrSel isn't gated, triggers a ghost branch.
    sub x7, x4, x5          # funct3=000 matches BEQ. If BrSel isn't gated, triggers a ghost branch.

    # =========================================================================
    # 4. CONDITIONAL BRANCH EXECUTION & FLUSH PROTECTION
    # =========================================================================
    bge x4, x5, route_pass  # Execute signed inequality branch (15 >= -15 is True)
    
    # FAIL SAFE: Pipeline must flush this block on a taken branch
    addi x31, x0, -1        
    j core_halt             

route_pass:
    # Verify pipeline flush tracking: Ensure drop-through instruction wasn't executed
    addi x30, x0, -1
    beq  x31, x30, core_halt

    # =========================================================================
    # 5. ALL-ZERO UNINITIALIZED MEMORY SAFE-STATE TEST
    # =========================================================================
    .word 0x00000000        # Insert uninitialized memory boundary to check fallback x0 mapping
    .word 0x00000000        # Insert uninitialized memory boundary to verify RegWEn gating restrictions
    
    addi x31, x0, 1         # Write validation pass identifier 1 to register x31
    j core_halt             # Proceed directly to stable simulation termination loop

system_fail:
    addi x31, x0, -1        # Write core error identifier -1 to register x31

core_halt:
    j core_halt             # Freeze execution within permanent loop to read terminal status register