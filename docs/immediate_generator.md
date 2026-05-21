# Immediate Generator (ImmGen)

## Functional Overview

The Immediate Generator (`ImmGen`) extracts, reorganizes, and sign-extends immediate values from raw 32-bit RISC-V instructions (`Inst[31:0]`). It operates entirely via combinatorial wire splicing, preparing signed constants for the execution core based on the instruction type.

## Core Splicing Matrix

Instead of literal shifting hardware, fields are reassembled using parallel bit splitters/combiners. All formats (except U-type) utilize the instruction's MSB (`Inst[31]`) as a sign-extension vector to pad the upper bits up to bit 31.

- **I-Type (Sign-Extended 12-bit Constant):**
  - `Imm[11:0]` = `Inst[31:20]`
  - `Imm[31:12]` = `Inst[31]` (20-bit replication)
- **S-Type (Sign-Extended 12-bit Constant, Split Fields):**
  - `Imm[4:0]` = `Inst[11:7]`
  - `Imm[11:5]` = `Inst[31:25]`
  - `Imm[31:12]` = `Inst[31]` (20-bit replication)
- **B-Type (Sign-Extended 13-bit Byte Offset, LSB Grounded):**
  - `Imm[0]` = `1'b0` (Implicit zero for half-word alignment)
  - `Imm[4:1]` = `Inst[11:8]`
  - `Imm[10:5]` = `Inst[30:25]`
  - `Imm[11]` = `Inst[7]`
  - `Imm[31:12]` = `Inst[31]` (20-bit replication)
- **U-Type (Upper 20-bit Immediate, Lower 12 Bits Grounded):**
  - `Imm[11:0]` = `12'b0`
  - `Imm[31:12]` = `Inst[31:12]`
- **J-Type (Sign-Extended 21-bit Byte Offset, LSB Grounded):**
  - `Imm[0]` = `1'b0` (Implicit zero for half-word alignment)
  - `Imm[4:1]` = `Inst[24:21]`
  - `Imm[10:5]` = `Inst[30:25]`
  - `Imm[11]` = `Inst[20]`
  - `Imm[31:20]` = `Inst[31]` (12-bit replication)

## Bus Selection Control

The five parallel structural pathways route directly to a 32-bit multiplexer. Selection is driven by a 3-bit decoding signal (`ImmSel`) derived from the opcode processor.

```text
       Instruction Bus [31:0]
                 │
   ┌─────────────┼─────────────┬─────────────┬─────────────┐
   ▼             ▼             ▼             ▼             ▼
[I-Splicer]   [S-Splicer]   [B-Splicer]   [U-Splicer]   [J-Splicer]
   │             │             │             │             │
 32-bit        32-bit        32-bit        32-bit        32-bit
   │             │             │             │             │
 ──┴──────┬──────┴──────┬──────┴──────┬──────┴──────┬──────┴──
          ▼             ▼             ▼             ▼
       Input 0       Input 1       Input 2       Input 3       Input 4

      ┌─────────────────────────────────────────────────────────┐
      │               32-Bit 5-to-1 Multiplexer                 │◄─── ImmSel[2:0]
      └───────────────────────────┬─────────────────────────────┘
                                  ▼
                        Immediate Output [31:0]
```
