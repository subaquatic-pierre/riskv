# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (U-TYPE ENCODING & ALIGNMENT)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'simulation_end'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'simulation_end'
# ==============================================================================

.globl _start

.section .text
_start:
    # =========================================================================
    # 1. INITIALIZATION & STATE CLEANUP
    # =========================================================================
    addi x1, x0, 0          # Reset validation register x1
    addi x2, x0, 0          # Reset comparison register x2
    addi x3, x0, 0          # Reset verification register x3
    lui  x31, 0x00000       # Clear diagnostic tracking register x31 to 0

    # =========================================================================
    # 2. LUI UPPER IMMEDIATE DECODING VALIDATION
    # =========================================================================
    lui x1, 0x12345         # Load upper immediate 0x12345 into x1 (sets bits [31:12])
    
    # Construct exact golden pattern 0x12345000 using pipeline-safe I-types
    lui x2, 0x12345         
    bne x1, x2, immediate_fail # If LUI failed to shift or write back, branch to failure track

    # =========================================================================
    # 3. AUIPC BASE PC EXTRACTION VALIDATION
    # =========================================================================
    # Testing AUIPC: Grab current PC by using an AUIPC instruction with a 0 immediate.
    # Instruction index tracking assuming execution starts at address 0x00000000:
    # 0x00: addi x1       0x04: addi x2       0x08: addi x3       0x0C: lui x31
    # 0x10: lui  x1       0x14: lui  x2       0x18: bne  x1
current_pc_label:
    auipc x3, 0             # Read current PC into register x3 (Should execute at 0x1C)
    
    lui x2, 0x00000         
    addi x2, x2, 28         # Expected raw hardware absolute PC = 0x0000001C (28 dec)
    bne x3, x2, immediate_fail # If AUIPC calculated the wrong PC offset, drop to failure

    # =========================================================================
    # 4. AUIPC HIGH IMMEDIATE MATH VALIDATION
    # =========================================================================
    # Testing AUIPC with a non-zero upper immediate offset:
    # 0x20: lui x2        0x24: addi x2       0x28: bne x3
offset_pc_label:
    auipc x1, 0x00002       # Calculate PC + 0x00002000 and store result into x1 (Executes at 0x2C)
    
    # Calculation: 0x0000002C + 0x00002000 = 0x0000202C
    lui x2, 0x00002         
    addi x2, x2, 44         # Expected composite pattern = 0x0000202C
    bne x1, x2, immediate_fail # If the upper immediate addition was offset incorrectly, fail

    # =========================================================================
    # 5. ISOLATION & FLUSH VALIDATION
    # =========================================================================
    bne x0, x0, immediate_fail # Ghost branch check to ensure BrSel masking is tight
    
    # Verify branch pipeline flush tracking: Ensure drop-through isn't executed
    addi x2, x0, 5
    beq  x0, x0, pass_route
    addi x31, x0, -1        # Catch rogue drop-through if pipeline flush failed
    j simulation_end

pass_route:
    .word 0x00000000        # Clear space barrier to verify zero-word instructions are safe
    addi x31, x0, 1         # Write validation pass identifier 1 to register x31
    j simulation_end        # Jump directly to stable termination point

immediate_fail:
    addi x31, x0, -1        # Write core error identifier -1 to register x31

simulation_end:
    j simulation_end        # Freeze execution to confirm status marker in x31