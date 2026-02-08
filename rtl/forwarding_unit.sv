/**
 * Forwarding Unit for 5-Stage RV64I Pipeline
 *
 * Description:
 *   Detects data hazards and generates forwarding control signals to bypass
 *   results directly from later pipeline stages to the EX stage operands,
 *   reducing the number of stalls required.
 *
 *   This forwarding unit implements classic MIPS-style forwarding with two
 *   main forwarding paths:
 *   - EX/MEM → EX (ALU result from previous cycle)
 *   - MEM/WB → EX (Load data or ALU result from 2 cycles ago)
 *
 * Ports:
 *   - rs1_ex: Source register 1 address in EX stage (5-bit)
 *   - rs2_ex: Source register 2 address in EX stage (5-bit)
 *   - rd_mem: Destination register address in MEM stage (5-bit)
 *   - rd_wb: Destination register address in WB stage (5-bit)
 *   - reg_write_mem: Register write enable in MEM stage
 *   - reg_write_wb: Register write enable in WB stage
 *   - forward_a: Forwarding select for ALU operand A (2-bit)
 *   - forward_b: Forwarding select for ALU operand B (2-bit)
 *
 * Forwarding Select Encoding:
 *   2'b00: Use register file data (no hazard)
 *   2'b01: Forward from EX/MEM stage (ALU result from previous cycle)
 *   2'b10: Forward from MEM/WB stage (load data or ALU result from 2 cycles ago)
 *
 * Priority:
 *   EX/MEM forwarding has higher priority than MEM/WB when both conditions
 *   are true (rare case where same register is written by adjacent stages).
 *   x0 (register 0) is never forwarded (always reads as zero).
 */

module forwarding_unit (
    input  logic [4:0] rs1_ex,
    input  logic [4:0] rs2_ex,
    input  logic [4:0] rd_mem,
    input  logic [4:0] rd_wb,
    input  logic       reg_write_mem,
    input  logic       reg_write_wb,
    
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    // =========================================================================
    // Forwarding Logic for Operand A (rs1)
    // =========================================================================
    // Check if source register rs1 in EX stage matches destination register
    // in MEM or WB stages, and if write is enabled.
    // =========================================================================

    always_comb begin
        // Default: no forwarding (use register file data)
        forward_a = 2'b00;

        // Check EX/MEM forwarding path (higher priority)
        // Condition: rd_mem matches rs1_ex AND reg_write_mem is true
        //            AND rd_mem is not x0
        if (reg_write_mem && (rd_mem != 5'h0) && (rd_mem == rs1_ex)) begin
            forward_a = 2'b01;  // Forward from EX/MEM
        end
        // Check MEM/WB forwarding path (lower priority)
        // Condition: rd_wb matches rs1_ex AND reg_write_wb is true
        //            AND rd_wb is not x0
        // This is only checked if EX/MEM forwarding is not active
        else if (reg_write_wb && (rd_wb != 5'h0) && (rd_wb == rs1_ex)) begin
            forward_a = 2'b10;  // Forward from MEM/WB
        end
    end

    // =========================================================================
    // Forwarding Logic for Operand B (rs2)
    // =========================================================================
    // Check if source register rs2 in EX stage matches destination register
    // in MEM or WB stages, and if write is enabled.
    // =========================================================================

    always_comb begin
        // Default: no forwarding (use register file data)
        forward_b = 2'b00;

        // Check EX/MEM forwarding path (higher priority)
        // Condition: rd_mem matches rs2_ex AND reg_write_mem is true
        //            AND rd_mem is not x0
        if (reg_write_mem && (rd_mem != 5'h0) && (rd_mem == rs2_ex)) begin
            forward_b = 2'b01;  // Forward from EX/MEM
        end
        // Check MEM/WB forwarding path (lower priority)
        // Condition: rd_wb matches rs2_ex AND reg_write_wb is true
        //            AND rd_wb is not x0
        // This is only checked if EX/MEM forwarding is not active
        else if (reg_write_wb && (rd_wb != 5'h0) && (rd_wb == rs2_ex)) begin
            forward_b = 2'b10;  // Forward from MEM/WB
        end
    end

endmodule

