/**
 * RISC-V Immediate Generator
 *
 * Description:
 *   Combinational module that extracts and sign-extends immediates from RISC-V
 *   instructions. Supports all five immediate types defined in the RV64I ISA:
 *   I-type, S-type, B-type, U-type, and J-type.
 *
 * Ports:
 *   - instr: 32-bit instruction
 *   - imm: 64-bit sign-extended immediate output
 *
 * Immediate Type Encoding in Instructions:
 *   I-type: [31:20]        (12-bit immediate)
 *   S-type: [31:25, 11:7]  (12-bit immediate)
 *   B-type: [31, 7, 30:25, 11:8]  (12-bit immediate, encodes offset)
 *   U-type: [31:12]        (20-bit immediate)
 *   J-type: [31, 19:12, 20, 30:21]  (20-bit immediate, encodes offset)
 *
 * All immediates are sign-extended to 64 bits using the MSB of the
 * extracted immediate value.
 */

module imm_gen (
    input  logic [31:0] instr,
    output logic [63:0] imm
);

    // Extract opcode to determine instruction type
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    // Extracted immediates (before sign extension)
    logic [11:0] imm_i_type;
    logic [11:0] imm_s_type;
    logic [12:0] imm_b_type;
    logic [19:0] imm_u_type;
    logic [20:0] imm_j_type;

    // =========================================================================
    // I-Type Immediate Extraction
    // =========================================================================
    // Format: IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII ssssssss
    //         [31:20] = 12-bit immediate
    //         Opcode: 0x13 (ADDI, ANDI, ORI, XORI, etc.)
    //         Opcode: 0x03 (LB, LH, LW, LD, LBU, LHU, LWU)
    //         Opcode: 0x67 (JALR)
    // =========================================================================
    assign imm_i_type = instr[31:20];

    // =========================================================================
    // S-Type Immediate Extraction
    // =========================================================================
    // Format: IIIIIIII IIIIIIII [31:25] [11:7] IIIIIII
    //         [31:25] = upper 7 bits of 12-bit immediate
    //         [11:7]  = lower 5 bits of 12-bit immediate
    //         Opcode: 0x23 (SB, SH, SW, SD)
    // Reconstruction: { instr[31:25], instr[11:7] }
    // =========================================================================
    assign imm_s_type = { instr[31:25], instr[11:7] };

    // =========================================================================
    // B-Type Immediate Extraction
    // =========================================================================
    // Format: I I [30:25] [11:8] IIII
    //         [31]    = bit 12 (MSB)
    //         [30:25] = bits 10:5
    //         [11:8]  = bits 4:1
    //         [7]     = bit 11
    //         Opcode: 0x63 (BEQ, BNE, BLT, BGE, BLTU, BGEU)
    // Reconstruction: { instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 }
    // Note: B-type immediates are always even (bit 0 = 0), so we add implicit 0
    // Result is 13 bits (with implicit 0 at LSB): 12:1 stored in instruction
    // =========================================================================
    assign imm_b_type = { instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };

    // =========================================================================
    // U-Type Immediate Extraction
    // =========================================================================
    // Format: IIIIIIIIIIIIIIIIIIIIIIII 00000000
    //         [31:12] = 20-bit immediate (placed in upper bits of result)
    //         Opcode: 0x37 (LUI)
    //         Opcode: 0x17 (AUIPC)
    // The immediate is left-shifted by 12 (filled with 12 zeros at LSB)
    // =========================================================================
    assign imm_u_type = instr[31:12];

    // =========================================================================
    // J-Type Immediate Extraction
    // =========================================================================
    // Format: I [19:12] I [30:21] I
    //         [31]     = bit 20 (MSB)
    //         [19:12]  = bits 19:12
    //         [20]     = bit 11
    //         [30:21]  = bits 10:1
    //         Opcode: 0x6F (JAL)
    // Reconstruction: { instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 }
    // Note: J-type immediates are always even (bit 0 = 0), so we add implicit 0
    // Result is 21 bits (with implicit 0 at LSB): 20:1 stored in instruction
    // =========================================================================
    assign imm_j_type = { instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };

    // =========================================================================
    // Main Multiplexer: Select immediate type based on opcode
    // =========================================================================
    logic [20:0] selected_imm;  // Widest immediate type (J-type, 21 bits)
    logic        sign_bit;      // MSB for sign extension

    always_comb begin
        case (opcode)
            // I-Type: ADDI, ANDI, ORI, XORI, LB, LH, LW, LD, LBU, LHU, LWU, JALR
            7'b0010011,  // I-type arithmetic/logical (ADDI, ANDI, ORI, XORI)
            7'b0000011,  // I-type loads (LB, LH, LW, LD, LBU, LHU, LWU)
            7'b1100111:  // JALR
            begin
                selected_imm = { {9{imm_i_type[11]}}, imm_i_type };  // Sign extend 12->21
                sign_bit = imm_i_type[11];
            end

            // S-Type: SB, SH, SW, SD
            7'b0100011: begin
                selected_imm = { {9{imm_s_type[11]}}, imm_s_type };  // Sign extend 12->21
                sign_bit = imm_s_type[11];
            end

            // B-Type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                selected_imm = { {8{imm_b_type[12]}}, imm_b_type };  // Sign extend 13->21
                sign_bit = imm_b_type[12];
            end

            // U-Type: LUI, AUIPC
            7'b0110111,  // LUI
            7'b0010111:  // AUIPC
            begin
                selected_imm = { imm_u_type, 1'b0 };  // 20-bit left-shifted by 12
                sign_bit = imm_u_type[19];
            end

            // J-Type: JAL
            7'b1101111: begin
                selected_imm = imm_j_type;  // 21-bit immediate
                sign_bit = imm_j_type[20];
            end

            // Default: return zero
            default: begin
                selected_imm = 21'h0;
                sign_bit = 1'b0;
            end
        endcase
    end

    // =========================================================================
    // Sign Extension to 64 Bits
    // =========================================================================
    // Extend the selected 21-bit immediate to 64 bits using the sign bit
    // (MSB of the extracted immediate)
    // SPECIAL CASE: U-type immediates (LUI, AUIPC) need to be shifted left by 12
    // =========================================================================
    
    logic [63:0] sign_extended;
    assign sign_extended = { {43{sign_bit}}, selected_imm };
    
    // For U-type instructions, the immediate is in bits [63:12]
    // For all other instructions, the immediate is in bits [63:0]
    assign imm = (opcode == 7'b0110111 || opcode == 7'b0010111) 
        ? {imm_u_type, 12'h0}  // U-type: place in upper 20 bits, zero-fill lower 12
        : sign_extended;        // All others: sign-extended

endmodule

