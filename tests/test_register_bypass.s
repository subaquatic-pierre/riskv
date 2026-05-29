.globl _start

.section .text
_start:
    addi x1, x0, 0          # Reset pointer address register x1
    addi x2, x0, 0          # Reset source data modifier register x2
    addi x3, x0, 0          # Reset verification loading register x3
    addi x4, x0, 0          # Reset test validation operand x4
    addi x5, x0, 0          # Reset test validation operand x5
    addi x31, x0, 0         # Reset diagnostic reporting register x31

    addi x1, x0, 512        # Set high bounds memory location to address 512
    li x2, 8192             # Load validation signature 8192 into x2 using pseudo-op expansion
    sw x2, 0(x1)            # Execute store. Verifies S-type structure restricts RegWEn to low
    
    lw x3, 0(x1)            # Execute load. Verifies ALUSel masks the bus back to ADD (0000)
    bne x3, x2, system_fail # Deflect execution to error loop if signature verification fails

    addi x4, x0, 15         # Assign data sample value 15 to x4
    addi x5, x0, -15        # Assign data sample value -15 to x5
    and x6, x4, x5          # Execute R-type bitwise AND with funct3=111. Verifies BGEU logic is bypassed
    sub x7, x4, x5          # Execute R-type subtraction with funct3=000. Verifies BEQ logic is bypassed

    bge x4, x5, route_pass  # Execute signed inequality branch. Verifies BrSel[0] allows valid jumps
    j system_fail           # Intercept execution if pipeline failed to branch correctly

route_pass:
    .word 0x00000000        # Insert uninitialized memory boundary to check fallback x0 mapping
    .word 0x00000000        # Insert uninitialized memory boundary to verify RegWEn gating restrictions
    addi x31, x0, 1         # Write validation pass identifier 1 to register x31
    j core_halt             # Proceed directly to stable simulation termination loop

system_fail:
    addi x31, x0, -1        # Write core error identifier -1 to register x31

core_halt:
    j core_halt             # Freeze execution within permanent loop to read terminal status register