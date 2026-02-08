# 5-Stage RV64I Pipeline Architecture

## Pipeline Stages

IF → ID → EX → MEM → WB

### IF (Instruction Fetch)
- Read instruction from memory at PC
- PC_next_seq = PC + 4
- Output: instruction, pc, pc_next_seq

**IF/ID Register**: instr, pc, pc_next_seq

### ID (Instruction Decode)
- Decode instruction and extract fields
- Read register file (rs1, rs2)
- Generate control signals
- Sign/zero-extend immediates

**ID/EX Register**: alu_op, rs1_data, rs2_data, imm, rd, pc, pc_next_seq, mem_we, mem_type, rf_we, is_branch

### EX (Execute)
- ALU operations (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, Zba instructions)
- Branch/jump target computation
- Data forwarding resolution
- Branch comparison

**EX/MEM Register**: alu_result, mem_addr, mem_data, rd, pc_next_seq, mem_we, mem_type, rf_we

### MEM (Memory)
- Load/store operations
- Result multiplexing (ALU result or load data)

**MEM/WB Register**: result_data, rd, pc_next_seq, rf_we

### WB (Write-Back)
- Write result to register file
- Forward data for bypassing

---

## Hazards

**Data Hazards**: Resolved by forwarding unit and stalls
- Forwarding from EX/MEM (2-stage) - priority 1
- Forwarding from MEM/WB (3-stage) - priority 2

**Control Hazards**: Branches resolved in EX stage

**Structural Hazards**: Register file dual-read (ID), single-write (WB)
