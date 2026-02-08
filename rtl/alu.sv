/**
 * RV64I + Zba ALU (Arithmetic Logic Unit)
 *
 * Description:
 *   Synthesizable combinational ALU supporting RV64I base integer operations
 *   plus Zba extension (address generation) instructions.
 *
 *   Supported Operations:
 *   - RV64I: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
 *   - Zba: SH1ADD, SH2ADD, SH3ADD, ADD.UW, SH1ADD.UW, SH2ADD.UW, SH3ADD.UW
 *
 * Ports:
 *   - operand_a: First operand (64-bit)
 *   - operand_b: Second operand (64-bit)
 *   - alu_op: Operation select (5-bit)
 *   - result: ALU result (64-bit)
 *   - zero: Zero flag (result == 0)
 *
 * ALU Operation Encoding:
 *   5'b00000: ADD       - 64-bit addition
 *   5'b00001: SUB       - 64-bit subtraction
 *   5'b00010: AND       - Bitwise AND
 *   5'b00011: OR        - Bitwise OR
 *   5'b00100: XOR       - Bitwise XOR
 *   5'b00101: SLL       - Shift left logical (shamt = operand_b[5:0])
 *   5'b00110: SRL       - Shift right logical (shamt = operand_b[5:0])
 *   5'b00111: SRA       - Shift right arithmetic (shamt = operand_b[5:0])
 *   5'b01000: SLT       - Set if less than (signed)
 *   5'b01001: SLTU      - Set if less than (unsigned)
 *
 *   Zba Instructions (Address Generation):
 *   5'b01010: SH1ADD    - operand_a + (operand_b << 1)
 *   5'b01011: SH2ADD    - operand_a + (operand_b << 2)
 *   5'b01100: SH3ADD    - operand_a + (operand_b << 3)
 *   5'b01101: ADD.UW    - Zero-extend 32-bit result of (operand_a + operand_b)
 *   5'b01110: SH1ADD.UW - Zero-extend 32-bit result of (operand_a + (operand_b << 1))
 *   5'b01111: SH2ADD.UW - Zero-extend 32-bit result of (operand_a + (operand_b << 2))
 *   5'b10000: SH3ADD.UW - Zero-extend 32-bit result of (operand_a + (operand_b << 3))
 */

module alu (
    input  logic [63:0] operand_a,
    input  logic [63:0] operand_b,
    input  logic [4:0]  alu_op,
    output logic [63:0] result,
    output logic        zero
);

    // Internal signals for intermediate calculations
    logic [63:0] add_result;
    logic [63:0] sub_result;
    logic [63:0] shift_result;
    logic [63:0] shifted_operand_b;
    logic [5:0]  shamt;
    logic        signed_less;
    logic        unsigned_less;

    // =========================================================================
    // Arithmetic Operations
    // =========================================================================
    
    // Addition: used for ADD, ADD.UW, and Zba SH*ADD variants
    assign add_result = operand_a + operand_b;
    
    // Subtraction
    assign sub_result = operand_a - operand_b;
    
    // =========================================================================
    // Shift Operations
    // =========================================================================
    // Extract shift amount from operand_b[5:0] (6 bits for 64-bit shifts)
    assign shamt = operand_b[5:0];
    
    // Perform shift: logic will select between SLL, SRL, SRA
    always_comb begin
        case (alu_op[2:0])
            3'b000: shift_result = operand_a << shamt;  // SLL
            3'b001: shift_result = operand_a >> shamt;  // SRL
            3'b010: shift_result = $signed(operand_a) >>> shamt;  // SRA (arithmetic)
            default: shift_result = 64'h0;
        endcase
    end
    
    // =========================================================================
    // Comparison Operations (for SLT and SLTU)
    // =========================================================================
    
    // Signed comparison: operand_a < operand_b (2's complement)
    assign signed_less = $signed(operand_a) < $signed(operand_b);
    
    // Unsigned comparison: operand_a < operand_b
    assign unsigned_less = operand_a < operand_b;
    
    // =========================================================================
    // Zba Shift-Add Operations
    // =========================================================================
    // Zba instructions combine shift and add to optimize address generation
    //
    // SH1ADD:    result = operand_a + (operand_b << 1)
    // SH2ADD:    result = operand_a + (operand_b << 2)
    // SH3ADD:    result = operand_a + (operand_b << 3)
    //
    // These are computed once and selected in the main result mux
    // =========================================================================
    
    logic [63:0] sh1add_result;
    logic [63:0] sh2add_result;
    logic [63:0] sh3add_result;
    logic [63:0] add_uw_result;
    logic [63:0] sh1add_uw_result;
    logic [63:0] sh2add_uw_result;
    logic [63:0] sh3add_uw_result;
    
    // SH1ADD: operand_a + (operand_b << 1)
    assign sh1add_result = operand_a + (operand_b << 1);
    
    // SH2ADD: operand_a + (operand_b << 2)
    assign sh2add_result = operand_a + (operand_b << 2);
    
    // SH3ADD: operand_a + (operand_b << 3)
    assign sh3add_result = operand_a + (operand_b << 3);
    
    // =========================================================================
    // Zba .UW Variants (32-bit Zero-Extended)
    // =========================================================================
    // The .UW suffix indicates that the result of the addition is treated as
    // an unsigned 32-bit value, then zero-extended to 64 bits.
    // This is useful for index calculations in array addressing.
    //
    // Example: ADD.UW with operand_a = 0x100000000, operand_b = 0x1
    // Standard ADD would give 0x100000001
    // ADD.UW gives 0x0000000000000001 (only lower 32 bits, zero-extended)
    // =========================================================================
    
    // ADD.UW: Zero-extend lower 32 bits of (operand_a + operand_b)
    assign add_uw_result = { 32'h0, add_result[31:0] };
    
    // SH1ADD.UW: Zero-extend lower 32 bits of (operand_a + (operand_b << 1))
    assign sh1add_uw_result = { 32'h0, sh1add_result[31:0] };
    
    // SH2ADD.UW: Zero-extend lower 32 bits of (operand_a + (operand_b << 2))
    assign sh2add_uw_result = { 32'h0, sh2add_result[31:0] };
    
    // SH3ADD.UW: Zero-extend lower 32 bits of (operand_a + (operand_b << 3))
    assign sh3add_uw_result = { 32'h0, sh3add_result[31:0] };
    
    // =========================================================================
    // Main Result Multiplexer
    // =========================================================================
    // Select final result based on alu_op
    
    always_comb begin
        case (alu_op)
            5'b00000: result = add_result;         // ADD
            5'b00001: result = sub_result;         // SUB
            5'b00010: result = operand_a & operand_b;  // AND
            5'b00011: result = operand_a | operand_b;  // OR
            5'b00100: result = operand_a ^ operand_b;  // XOR
            5'b00101: result = shift_result;       // SLL (from shift block)
            5'b00110: result = shift_result;       // SRL (from shift block)
            5'b00111: result = shift_result;       // SRA (from shift block)
            5'b01000: result = { 63'h0, signed_less };   // SLT
            5'b01001: result = { 63'h0, unsigned_less }; // SLTU
            
            // Zba shift-add instructions (full 64-bit result)
            5'b01010: result = sh1add_result;      // SH1ADD
            5'b01011: result = sh2add_result;      // SH2ADD
            5'b01100: result = sh3add_result;      // SH3ADD
            
            // Zba .UW instructions (32-bit zero-extended)
            5'b01101: result = add_uw_result;      // ADD.UW
            5'b01110: result = sh1add_uw_result;   // SH1ADD.UW
            5'b01111: result = sh2add_uw_result;   // SH2ADD.UW
            5'b10000: result = sh3add_uw_result;   // SH3ADD.UW
            
            default: result = 64'h0;               // Undefined operation
        endcase
    end
    
    // =========================================================================
    // Zero Flag
    // =========================================================================
    // Asserted when result is all zeros (used for BEQ in branch execution)
    
    assign zero = (result == 64'h0);

endmodule

