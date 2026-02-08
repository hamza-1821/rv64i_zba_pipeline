/**
 * RISC-V RV64I Control Unit
 *
 * Description:
 *   Combinational control unit that decodes the 7-bit opcode of a RISC-V
 *   instruction and generates control signals for the datapath.
 *
 * Ports:
 *   - opcode: 7-bit instruction opcode (instruction[6:0])
 *   - funct3: 3-bit funct3 field (instruction[14:12])
 *   - funct7: 7-bit funct7 field (instruction[31:25])
 *   - reg_write: Write result to register file
 *   - mem_read: Read from data memory
 *   - mem_write: Write to data memory
 *   - mem_to_reg: Multiplex memory data (1) or ALU result (0) for register write
 *   - alu_src: Multiplex ALU operand B: register (0) or immediate (1)
 *   - branch: Branch operation (BEQ=1, BNE=2, BLT=3, BGE=4, BLTU=5, BGEU=6)
 *   - jump: Jump operation (JAL=1, JALR=2)
 *   - alu_op: ALU operation select (5-bit, routed to ALU)
 *
 * Control Signal Truth Table:
 *   R-Type (ADD, SUB, SLL, SRL, SRA, AND, OR, XOR, Zba):
 *     RegWrite=1, MemRead=0, MemWrite=0, MemToReg=0, ALUSrc=0, Branch=0, Jump=0
 *
 *   I-Type Arithmetic (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI):
 *     RegWrite=1, MemRead=0, MemWrite=0, MemToReg=0, ALUSrc=1, Branch=0, Jump=0
 *
 *   Load Instructions (LB, LH, LW, LD, LBU, LHU, LWU):
 *     RegWrite=1, MemRead=1, MemWrite=0, MemToReg=1, ALUSrc=1, Branch=0, Jump=0
 *
 *   Store Instructions (SB, SH, SW, SD):
 *     RegWrite=0, MemRead=0, MemWrite=1, MemToReg=X, ALUSrc=1, Branch=0, Jump=0
 *
 *   Branch Instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU):
 *     RegWrite=0, MemRead=0, MemWrite=0, MemToReg=X, ALUSrc=0, Branch=type, Jump=0
 *
 *   JAL:
 *     RegWrite=1, MemRead=0, MemWrite=0, MemToReg=0, ALUSrc=1, Branch=0, Jump=1
 *
 *   JALR:
 *     RegWrite=1, MemRead=0, MemWrite=0, MemToReg=0, ALUSrc=1, Branch=0, Jump=2
 *
 *   LUI, AUIPC:
 *     RegWrite=1, MemRead=0, MemWrite=0, MemToReg=0, ALUSrc=1, Branch=0, Jump=0
 */

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic [2:0] branch,    // 0: none, 1-6: branch type
    output logic [1:0] jump,      // 0: none, 1: JAL, 2: JALR
    output logic [4:0] alu_op
);

    // Default control signal values
    always_comb begin
        // Default: no operation
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        alu_src = 1'b0;
        branch = 3'b0;
        jump = 2'b0;
        alu_op = 5'b0;

        // Decode opcode and generate control signals
        case (opcode)

            // ================================================================
            // R-Type: Arithmetic and Logical Instructions
            // Opcode: 0x33 (7'b0110011)
            // Format: funct7[5:0] rs2 rs1 funct3 rd opcode
            // Instructions: ADD, SUB, SLL, SRL, SRA, AND, OR, XOR, SLT, SLTU
            //               Zba: SH1ADD, SH2ADD, SH3ADD, ADD.UW, SH*ADD.UW
            // ================================================================
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src = 1'b0;      // Operand B from register
                
                // ALU operation determined by funct7 and funct3
                case ({funct7, funct3})
                    // RV64I base instructions
                    {7'b0000000, 3'b000}: alu_op = 5'b00000;  // ADD
                    {7'b0100000, 3'b000}: alu_op = 5'b00001;  // SUB
                    {7'b0000000, 3'b111}: alu_op = 5'b00010;  // AND
                    {7'b0000000, 3'b110}: alu_op = 5'b00011;  // OR
                    {7'b0000000, 3'b100}: alu_op = 5'b00100;  // XOR
                    {7'b0000000, 3'b001}: alu_op = 5'b00101;  // SLL
                    {7'b0000000, 3'b101}: alu_op = 5'b00110;  // SRL
                    {7'b0100000, 3'b101}: alu_op = 5'b00111;  // SRA
                    {7'b0000000, 3'b010}: alu_op = 5'b01000;  // SLT
                    {7'b0000000, 3'b011}: alu_op = 5'b01001;  // SLTU
                    
                    // Zba instructions (funct7 = 0x20)
                    {7'b0100000, 3'b001}: alu_op = 5'b01010;  // SH1ADD
                    {7'b0100000, 3'b010}: alu_op = 5'b01011;  // SH2ADD
                    {7'b0100000, 3'b011}: alu_op = 5'b01100;  // SH3ADD
                    {7'b0000100, 3'b000}: alu_op = 5'b01101;  // ADD.UW
                    {7'b0010000, 3'b001}: alu_op = 5'b01110;  // SH1ADD.UW
                    {7'b0010000, 3'b010}: alu_op = 5'b01111;  // SH2ADD.UW
                    {7'b0010000, 3'b011}: alu_op = 5'b10000;  // SH3ADD.UW
                    
                    default: alu_op = 5'b0;
                endcase
            end

            // ================================================================
            // I-Type Immediate Arithmetic and Logical
            // Opcode: 0x13 (7'b0010011)
            // Format: imm[11:0] rs1 funct3 rd opcode
            // Instructions: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI
            // ================================================================
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;      // Operand B from immediate
                
                // ALU operation determined by funct3 (and funct7 for shifts)
                case (funct3)
                    3'b000: alu_op = 5'b00000;  // ADDI
                    3'b111: alu_op = 5'b00010;  // ANDI
                    3'b110: alu_op = 5'b00011;  // ORI
                    3'b100: alu_op = 5'b00100;  // XORI
                    3'b001: alu_op = 5'b00101;  // SLLI
                    3'b101: begin
                        // SRLI or SRAI determined by funct7[5]
                        if (funct7[5] == 1'b0)
                            alu_op = 5'b00110;  // SRLI
                        else
                            alu_op = 5'b00111;  // SRAI
                    end
                    3'b010: alu_op = 5'b01000;  // SLTI
                    3'b011: alu_op = 5'b01001;  // SLTIU
                    default: alu_op = 5'b0;
                endcase
            end

            // ================================================================
            // Load Instructions (I-Type)
            // Opcode: 0x03 (7'b0000011)
            // Format: imm[11:0] rs1 funct3 rd opcode
            // Instructions: LB, LH, LW, LD, LBU, LHU, LWU
            // ================================================================
            7'b0000011: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;   // Select loaded data
                alu_src = 1'b1;      // Operand B from immediate (address calc)
                alu_op = 5'b00000;   // ADD (for address calculation)
            end

            // ================================================================
            // Store Instructions (S-Type)
            // Opcode: 0x23 (7'b0100011)
            // Format: imm[11:5] rs2 rs1 funct3 imm[4:0] opcode
            // Instructions: SB, SH, SW, SD
            // ================================================================
            7'b0100011: begin
                mem_write = 1'b1;
                alu_src = 1'b1;      // Operand B from immediate (address calc)
                alu_op = 5'b00000;   // ADD (for address calculation)
            end

            // ================================================================
            // Branch Instructions (B-Type)
            // Opcode: 0x63 (7'b1100011)
            // Format: imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode
            // Instructions: BEQ, BNE, BLT, BGE, BLTU, BGEU
            // ================================================================
            7'b1100011: begin
                alu_src = 1'b0;      // Both operands from registers
                
                // Branch type determined by funct3
                case (funct3)
                    3'b000: begin
                        branch = 3'b001;        // BEQ
                        alu_op = 5'b00001;      // SUB (for comparison)
                    end
                    3'b001: begin
                        branch = 3'b010;        // BNE
                        alu_op = 5'b00001;      // SUB (for comparison)
                    end
                    3'b100: begin
                        branch = 3'b011;        // BLT
                        alu_op = 5'b01000;      // SLT (for comparison)
                    end
                    3'b101: begin
                        branch = 3'b100;        // BGE
                        alu_op = 5'b01000;      // SLT (for comparison)
                    end
                    3'b110: begin
                        branch = 3'b101;        // BLTU
                        alu_op = 5'b01001;      // SLTU (for comparison)
                    end
                    3'b111: begin
                        branch = 3'b110;        // BGEU
                        alu_op = 5'b01001;      // SLTU (for comparison)
                    end
                    default: begin
                        branch = 3'b0;
                        alu_op = 5'b0;
                    end
                endcase
            end

            // ================================================================
            // Upper Immediate Instructions
            // LUI: Opcode 0x37 (7'b0110111)
            // AUIPC: Opcode 0x17 (7'b0010111)
            // Format: imm[31:12] rd opcode
            // ================================================================
            7'b0110111, 7'b0010111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;      // Operand B from immediate
                alu_op = 5'b00000;   // ADD (for LUI: adds 0 to shifted imm)
            end

            // ================================================================
            // Jump Instructions
            // JAL: Opcode 0x6F (7'b1101111)
            // ================================================================
            7'b1101111: begin
                reg_write = 1'b1;
                jump = 2'b01;        // JAL
                alu_src = 1'b1;      // Operand B from immediate (target calc)
                alu_op = 5'b00000;   // ADD (for target calculation: PC + offset)
            end

            // ================================================================
            // Jump Register Instruction
            // JALR: Opcode 0x67 (7'b1100111)
            // Format: imm[11:0] rs1 funct3 rd opcode
            // ================================================================
            7'b1100111: begin
                reg_write = 1'b1;
                jump = 2'b10;        // JALR
                alu_src = 1'b1;      // Operand B from immediate
                alu_op = 5'b00000;   // ADD (for target calculation: rs1 + offset)
            end

            // ================================================================
            // Default Case: Undefined Opcode
            // ================================================================
            default: begin
                reg_write = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 1'b0;
                alu_src = 1'b0;
                branch = 3'b0;
                jump = 2'b0;
                alu_op = 5'b0;
            end

        endcase
    end

endmodule

