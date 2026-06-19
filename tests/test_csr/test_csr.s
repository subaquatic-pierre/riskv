.globl _start

_start:
  addi x1, x0, 0xff # set x1 0xff
  addi x2, x0, 0x00 # set x2 0x00
  addi x3, x0, 0x01 # set x3 0x01

  csrrw x3, 0x7C0, x1 
  bne x3, x0, fail # jump to fail if x3 not zero

  csrrs x2, 0x7C0, x1  # read previously updated value into x2
  bne x2, x1, fail # check x2 gets new value from CSR 0x00

  j pass

pass:
  csrrwi x0, 0x7C0, 1
  j halt

fail:
  csrrwi x0, 0x7C0, 2
  j halt

halt:
  j halt