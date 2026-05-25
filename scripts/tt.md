Instruction
Name
Description
Type Opcode
Funct3 Funct7
add
rd rs1 rs2
ADD
R[rd] = R[rs1] + R[rs2]
R 011 0011 000 000 0000
sub
rd rs1 rs2
SUBtract
R[rd] = R[rs1] - R[rs2]
R 011 0011 000 010 0000
and
rd rs1 rs2
bitwise AND
R[rd] = R[rs1] & R[rs2]
R 011 0011 111 000 0000
or
rd rs1 rs2
bitwise OR
R[rd] = R[rs1] | R[rs2]
R 011 0011 110 000 0000
xor
rd rs1 rs2
bitwise XOR
R[rd] = R[rs1] ^ R[rs2]
R 011 0011 100 000 0000
sll
rd rs1 rs2
Shift Left Logical
R[rd] = R[rs1] << R[rs2]
R 011 0011 001 000 0000
srl
rd rs1 rs2
Shift Right Logical
R[rd] = R[rs1] >> R[rs2]
R 011 0011 101 000 0000
(Zero-extend)
sra
rd rs1 rs2
Shift Right Arithmetic
R[rd] = R[rs1] >> R[rs2]
R 011 0011 101 010 0000
(Sign-extend)
slt
rd rs1 rs2
Set Less Than
if (R[rs1] < R[rs2]) {
R 011 0011 010 000 0000
(signed)
R[rd] = 1;
} else {
sltu
rd rs1 rs2
Set Less Than
R 011 0011 011 000 0000
R[rd] = 0;
c
i t (Unsigned)
}
em addi
rd rs1 imm
ADD Immediate
R[rd] = R[rs1] + imm
I
001 0011 000
ht A r i andi
rd rs1 imm
bitwise AND
R[rd] = R[rs1] & imm
I
001 0011 111
Immediate
ori
rd rs1 imm
bitwise OR Immediate R[rd] = R[rs1] | imm
I
001 0011 110
xori
rd rs1 imm
bitwise XOR
R[rd] = R[rs1] ^ imm
I
001 0011 100
Immediate
slli
rd rs1 imm
Shift Left Logical
R[rd] = R[rs1] << imm
I* 001 0011 001 000 0000
Immediate
srli
rd rs1 imm
Shift Right Logical
R[rd] = R[rs1] >> imm
I* 001 0011 101 000 0000
Immediate
(Zero-extend)
srai
rd rs1 imm
Shift Right Arithmetic
R[rd] = R[rs1] >> imm
I* 001 0011 101 010 0000
Immediate
(Sign-extend)
slti
rd rs1 imm
Set Less Than
if (R[rs1] < imm) {
I
001 0011 010
Immediate (signed)
R[rd] = 1;
} else {
sltiu rd rs1 imm
Set Less Than
I
001 0011 011
R[rd] = 0;
Immediate (Unsigned) }
lb
rd imm(rs1)
Load Byte
R[rd] = M[R[rs1] + imm][7:0]
I
000 0011 000
(Sign-extend)
lbu
rd imm(rs1)
Load Byte (Unsigned)
R[rd] = M[R[rs1] + imm][7:0]
I
000 0011 100
(Zero-extend)
lh
rd imm(rs1)
Load Half-word
R[rd] = M[R[rs1] + imm][15:0]
I
000 0011 001
(Sign-extend)
lhu
rd imm(rs1)
Load Half-word
R[rd] = M[R[rs1] + imm][15:0]
I
000 0011 101
(Unsigned)
(Zero-extend)
y
r o lw
rd imm(rs1)
Load Word
R[rd] = M[R[rs1] + imm][31:0]
I
000 0011 010
me M sb
rs2 imm(rs1) Store Byte
M[R[rs1] + imm][7:0] =
S 010 0011 000
R[rs2][7:0]
sh
rs2 imm(rs1) Store Half-word
M[R[rs1] + imm][15:0] =
S 010 0011 001
R[rs2][15:0]
sw
rs2 imm(rs1) Store Word
M[R[rs1] + imm][31:0] =
S 010 0011 010
R[rs2][31:0]
Instruction
Name
beq
rs1 rs2 label Branch if EQual
bne
rs1 rs2 label Branch if Not Equal
l
ortnoCblt
bltu
bge
bgeu
jal
rs1 rs2 labelrs1 rs2 labelrs1 rs2 labelrs1 rs2 labelrd label
Branch if Less Than (signed)
Branch if Less Than (Unsigned)
Branch if Greater or Equal (signed)
Branch if Greater or Equal (Unsigned)
Jump And Link
jalr
rd rs1 imm
auipc rd immu
lui
rd immu
r
eht O ebreak
ecall
t
x mul
rd rs1 rs2
EJump And Link Register
Add Upper Immediate to PC
Load Upper Immediate
Environment BREAK
Environment CALL
Multiply (part of mul ISA extension)
Description
if (R[rs1] == R[rs2])
PC = PC + offset
if (R[rs1] != R[rs2])
PC = PC + offset
if (R[rs1] < R[rs2])
PC = PC + offset
if (R[rs1] >= R[rs2])
PC = PC + offset
R[rd] = PC + 4
PC = PC + offset
R[rd] = PC + 4
PC = R[rs1] + imm
imm = immu << 12
R[rd] = PC + imm
imm = immu << 12
R[rd] = imm
Asks the debugger to do
something (imm = 0)
Asks the OS to do
something (imm = 1)
R[rd] = (R[rs1]) *
(R[rs2])
Type Opcode
Funct3
B 110 0011 000
B 110 0011 001
B 110 0011 100
B 110 0011 110
B 110 0011 101
B 110 0011 111
J 110 1111
I
110 0111 000
U 001 0111
U 011 0111
I
111 0011 000
I
111 0011 000
(omitted)
