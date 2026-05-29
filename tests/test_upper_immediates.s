.globl _start

.section .text
_start:
    addi x1, x0, 0          # Reset validation register x1
    addi x2, x0, 0          # Reset comparison register x2
    addi x3, x0, 0          # Reset verification register x3
    addi x31, x0, 0         # Reset diagnostic reporting register x31

    lui x1, 0x12345         # Load upper immediate 0x12345 into x1 (sets bits [31:12])
    li x2, 0x12345000       # Generate expected golden bit pattern in x2 for comparison
    bne x1, x2, immediate_fail # If LUI failed to shift or write back, branch to failure track

    # Testing AUIPC:
    # We will grab the current PC by using an AUIPC instruction with a 0 immediate.
    # This adds 0 to the current PC and stores the absolute address directly into x3.
current_pc_label:
    auipc x3, 0             # Read current PC into register x3
    
    # In Logisim, if your code begins execution at address 0x00000000:
    # _start is at 0x00
    # addi instructions take 4 bytes each (4 * 4 = 16 bytes -> 0x10)
    # lui is at 0x14, li expands to 2 instructions (0x18, 0x1C), bne is at 0x20
    # Therefore, current_pc_label should land exactly at address 0x00000024.
    li x2, 0x00000024       # Load the mathematically expected absolute PC address into x2
    bne x3, x2, immediate_fail # If AUIPC calculated the wrong PC offset, drop to failure

    # Testing AUIPC with a non-zero upper immediate offset:
offset_pc_label:
    auipc x1, 0x00002       # Calculate PC + 0x00002000 and store result into x1
    
    # offset_pc_label executes exactly at address 0x00000030.
    # The calculation is: 0x00000030 + 0x00002000 = 0x00002030.
    li x2, 0x00002030       # Load the expected combined calculation pattern into x2
    bne x1, x2, immediate_fail # If the upper immediate addition was offset incorrectly, fail

    bne x0, x0, immediate_fail # Ghost branch check to ensure BrSel[0] masking is still tight
    
    .word 0x00000000        # Clear space barrier to verify zero-word instructions are safe
    addi x31, x0, 1         # Write validation pass identifier 1 to register x31
    j simulation_end        # Jump directly to stable termination point

immediate_fail:
    addi x31, x0, -1        # Write core error identifier -1 to register x31

simulation_end:
    j simulation_end        # Freeze execution to confirm status marker in x31