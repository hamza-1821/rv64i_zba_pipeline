/**
 * ALU Control Module for RV64I + Zba
 *
 * Description:
 *   Decodes the ALUOp signal along with funct3 and funct7 fields to generate
 *   the final 5-bit ALU control signal that selects the specific operation.
 *   This module provides a second level of instruction decoding, allowing
 *   simpler control unit design and fine-grained ALU operation selection.
 *
 * Ports:
 *   - alu_op: 4-bit primary ALU operation class (from control unit)
 *   - funct3: 3-bit function select field (instruction[14:12])
 *   - funct7: 7-bit function select field (instruction[31:25])
 *   - alu_ctrl: 5-bit ALU control signal (to ALU)
 *
 * ALUOp Encoding (from Control Unit):
 *   4'b0000: Default operation (used for load/store addressing)
 *   4'b0001: Arithmetic operations (ADD, ADDI, SUB)
 *   4'b0010: Logical operations (AND, OR, XOR)
 *   4'b0011: Shift operations (SLL, SRL, SRA)
 *   4'b0100: Comparison operations (SLT, SLTU)
 *   4'b0101: Zba shift-add instructions (SH1ADD, SH2ADD, SH3ADD, variants)
 *
 * ALU Control Output (5-bit):
 *   5'b00000: ADD
 *   5'b00001: SUB
 *   5'b00010: AND
 *   5'b00011: OR
 *   5'b00100: XOR
 *   5'b00101: SLL
 *   5'b00110: SRL
 *   5'b00111: SRA
 *   5'b01000: SLT
 *   5'b01001: SLTU
 *   5'b01010: SH1ADD
 *   5'b01011: SH2ADD
 *   5'b01100: SH3ADD
 *   5'b01101: ADD.UW
 *   5'b01110: SH1ADD.UW
 *   5'b01111: SH2ADD.UW
 *   5'b10000: SH3ADD.UW
 */

module alu_control (
    input  logic [3:0] alu_op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [4:0] alu_ctrl
);

    // =========================================================================
    // ALU Control Logic
    // =========================================================================
    // Decode ALUOp and secondary fields (funct3/funct7) to generate final
    // ALU control signal
    // =========================================================================

    always_comb begin
        case (alu_op)

            // ================================================================
            // ALUOp = 4'b0000: Default Operation (ADD for addressing)
            // Used for loads/stores and memory address calculation
            // ================================================================
            4'b0000: begin
                alu_ctrl = 5'b00000;  // ADD
            end

            // ================================================================
            // ALUOp = 4'b0001: Arithmetic Operations
            // Determined by funct3 for I-type or funct7/funct3 for R-type
            // ================================================================
            4'b0001: begin
                case (funct3)
                    3'b000: begin
                        // ADD or SUB: check funct7[5]
                        if (funct7[5] == 1'b0)
                            alu_ctrl = 5'b00000;  // ADD (ADDI, ADD)
                        else
                            alu_ctrl = 5'b00001;  // SUB
                    end
                    default: begin
                        alu_ctrl = 5'b00000;  // Default to ADD
                    end
                endcase
            end

            // ================================================================
            // ALUOp = 4'b0010: Logical Operations
            // Determined by funct3 (ANDI, ORI, XORI for I-type;
            // AND, OR, XOR for R-type)
            // ================================================================
            4'b0010: begin
                case (funct3)
                    3'b111: alu_ctrl = 5'b00010;  // AND
                    3'b110: alu_ctrl = 5'b00011;  // OR
                    3'b100: alu_ctrl = 5'b00100;  // XOR
                    default: alu_ctrl = 5'b00010;  // Default to AND
                endcase
            end

            // ================================================================
            // ALUOp = 4'b0011: Shift Operations
            // Determined by funct3 (funct7[5] determines SRL vs SRA)
            // ================================================================
            4'b0011: begin
                case (funct3)
                    3'b001: begin
                        alu_ctrl = 5'b00101;  // SLL (SLLI, SLL)
                    end
                    3'b101: begin
                        // SRL or SRA: check funct7[5]
                        if (funct7[5] == 1'b0)
                            alu_ctrl = 5'b00110;  // SRL (SRLI, SRL)
                        else
                            alu_ctrl = 5'b00111;  // SRA (SRAI, SRA)
                    end
                    default: alu_ctrl = 5'b00101;  // Default to SLL
                endcase
            end

            // ================================================================
            // ALUOp = 4'b0100: Comparison Operations (SLT, SLTU)
            // Determined by funct3
            // ================================================================
            4'b0100: begin
                case (funct3)
                    3'b010: alu_ctrl = 5'b01000;  // SLT (SLTI, SLT)
                    3'b011: alu_ctrl = 5'b01001;  // SLTU (SLTIU, SLTU)
                    default: alu_ctrl = 5'b01000;  // Default to SLT
                endcase
            end

            // ================================================================
            // ALUOp = 4'b0101: Zba Shift-Add Instructions
            // Determined by funct7 and funct3 combination
            // ================================================================
            4'b0101: begin
                case ({funct7, funct3})
                    // Zba instructions: funct7 selects between regular and .UW variants
                    
                    // Standard Zba shift-add (funct7 = 0x20)
                    {7'b0100000, 3'b001}: alu_ctrl = 5'b01010;  // SH1ADD
                    {7'b0100000, 3'b010}: alu_ctrl = 5'b01011;  // SH2ADD
                    {7'b0100000, 3'b011}: alu_ctrl = 5'b01100;  // SH3ADD
                    
                    // Zba .UW variants (32-bit zero-extended)
                    {7'b0000100, 3'b000}: alu_ctrl = 5'b01101;  // ADD.UW
                    {7'b0010000, 3'b001}: alu_ctrl = 5'b01110;  // SH1ADD.UW
                    {7'b0010000, 3'b010}: alu_ctrl = 5'b01111;  // SH2ADD.UW
                    {7'b0010000, 3'b011}: alu_ctrl = 5'b10000;  // SH3ADD.UW
                    
                    default: alu_ctrl = 5'b00000;  // Default to ADD
                endcase
            end

            // ================================================================
            // Default: Undefined ALUOp
            // ================================================================
            default: begin
                alu_ctrl = 5'b00000;  // Default to ADD
            end

        endcase
    end

endmodule

