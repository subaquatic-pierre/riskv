# ==============================================================================
# = RISC-V COMPLETE PIPELINE VERIFICATION TEST SUITE (EXCLUDING LB/SB/LH/SH)
# = Expected Success Outcome: x31 will contain 1, core will loop at 'terminal'
# = Expected Failure Outcome: x31 will contain -1, core will loop at 'terminal'
# ==============================================================================

.globl _start

.section .text
_start:
    lui x1, 0x00000         # Hard-clear x1 using upper immediate zeroing
    lui x2, 0x00000         # Hard-clear x2 using upper immediate zeroing
    lui x3, 0x00000         # Hard-clear x3 using upper immediate zeroing
    lui x4, 0x00000         # Hard-clear x4 using upper immediate zeroing
    lui x31, 0x00000        # Clear diagnostic tracking register x31 to 0
    
    # --------------------------------------------------------------------------
    # TEST 1: RAW EX-TO-EX FORWARDING & COMPUTE
    # --------------------------------------------------------------------------
    addi x1, x0, 15         # x1 = 15
    add x2, x1, x1          # x2 = 15 + 15 = 30 (EX-to-EX hazard on x1)
    addi x3, x2, -10        # x3 = 30 - 10 = 20 (EX-to-EX hazard on x2)
    addi x4, x0, 20         # x4 = 20
    beq x3, x4, test_mem_fwd # Verify math via branch evaluation
    jal x0, fault           # Catch architecture failure

    # --------------------------------------------------------------------------
    # TEST 2: MEM-TO-EX FORWARDING (2-CYCLE DISTANCE)
    # --------------------------------------------------------------------------
test_mem_fwd:
    addi x5, x0, 100        # x5 = 100
    addi x6, x0, 0          # Bubble padding
    add x7, x5, x5          # x7 = 100 + 100 = 200 (MEM-to-EX hazard on x5)
    addi x8, x0, 200        # x8 = 200
    beq x7, x8, test_load_use # Verify branch
    jal x0, fault

    # --------------------------------------------------------------------------
    # TEST 3: LOAD-USE HAZARD (1-CYCLE MANDATORY STALL)
    # --------------------------------------------------------------------------
test_load_use:
    addi x9, x0, 64         # x9 = Base memory pointer 64
    addi x10, x0, 42        # x10 = Data value 42
    sw x10, 0(x9)           # RAM[64] = 42
    
    lw x11, 0(x9)           # x11 = 42 (Load instruction enters pipeline)
    addi x12, x11, 8        # x12 = 42 + 8 = 50 (Immediate Load-Use Hazard)
    
    addi x13, x0, 50        # x13 = 50
    beq x12, x13, test_store_fwd # Verify load-stall hardware output
    jal x0, fault

    # --------------------------------------------------------------------------
    # TEST 4: STORE DATA PATH FORWARDING (MUX B OVERRIDE)
    # --------------------------------------------------------------------------
test_store_fwd:
    addi x14, x0, 128       # x14 = Base memory pointer 128
    addi x15, x0, 99        # x15 = 99
    
    addi x16, x15, 1        # x16 = 99 + 1 = 100 (EX-to-EX hazard for store data)
    sw x16, 0(x14)          # RAM[128] = x16 (Verifies Forwarding Mux B updates StoreData path)
    
    lw x17, 0(x14)          # Load back to check alignment
    addi x18, x0, 100       # x18 = 100
    beq x17, x18, test_branch_fwd # Verify data integrity
    jal x0, fault

    # --------------------------------------------------------------------------
    # TEST 5: BRANCH SELECTOR HAZARD & FORWARDING
    # --------------------------------------------------------------------------
test_branch_fwd:
    addi x19, x0, 500       # x19 = 500
    addi x20, x0, 400       # x20 = 400
    addi x21, x20, 100      # x21 = 400 + 100 = 500 (EX-to-EX hazard evaluated by Branch Controller)
    
    beq x19, x21, test_jalr_target # Branch Controller must capture forwarded data
    jal x0, fault

    # --------------------------------------------------------------------------
    # TEST 6: JALR TARGET COMPUTATION & LINK
    # --------------------------------------------------------------------------
test_jalr_target:
    auipc x22, 0x00000      # Get current PC into x22
    addi x22, x22, 16       # Calculate absolute address of pass_route
    jalr x23, x22, 0        # Jump to pass_route, store link return in x23
    jal x0, fault           # Trap on sequential drop-through failure

pass_route:
    addi x31, x0, 1         # Write successful status flag 1 into register x31
    jal x0, terminal        # Jump to final halt loop

fault:
    addi x31, x0, -1        # Write execution fault flag -1 into register x31

terminal:
    jal x0, terminal        # Infinite loop holding core simulation static