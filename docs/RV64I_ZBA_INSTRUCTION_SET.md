# RV64I + Zba Instruction Set Reference

## RV64I Base Integer Instructions

### Arithmetic/Logical
- ADD, ADDI, SUB
- AND, ANDI, OR, ORI, XOR, XORI
- LUI, AUIPC

### Shifts
- SLL, SLLI, SRL, SRLI, SRA, SRAI

### Loads
- LB, LH, LW, LD, LBU, LHU, LWU

### Stores
- SB, SH, SW, SD

### Branches
- BEQ, BNE, BLT, BGE, BLTU, BGEU

### Jumps
- JAL, JALR

---

## Zba Extension: Address Generation Instructions

### Instructions

| Instruction | Format | Description |
|-------------|--------|-------------|
| ADD.UW | rd = (rs1 + rs2)[31:0] zero-extended | Add with zero-extend 32-bit result |
| SH1ADD | rd = rs1 + (rs2 << 1) | Add with 1-bit shift |
| SH2ADD | rd = rs1 + (rs2 << 2) | Add with 2-bit shift |
| SH3ADD | rd = rs1 + (rs2 << 3) | Add with 3-bit shift |
