/**
 * RISC-V 64-bit Register File
 *
 * Description:
 *   Synthesizable register file with 32 x 64-bit registers.
 *   - x0 (zero) is hardwired to zero
 *   - 2 asynchronous read ports (combinational)
 *   - 1 synchronous write port (rising edge triggered)
 *
 * Ports:
 *   - clk: System clock
 *   - rst_n: Active-low asynchronous reset
 *   - rs1: Read port 1 address (5-bit, selects x0-x31)
 *   - rs1_data: Read port 1 data output (64-bit)
 *   - rs2: Read port 2 address (5-bit, selects x0-x31)
 *   - rs2_data: Read port 2 data output (64-bit)
 *   - wr_en: Write enable (active high)
 *   - wr_addr: Write address (5-bit, selects x0-x31)
 *   - wr_data: Write data input (64-bit)
 */

module regfile (
    input  logic        clk,
    input  logic        rst_n,
    
    // Read port 1 (combinational)
    input  logic [4:0]  rs1,
    output logic [63:0] rs1_data,
    
    // Read port 2 (combinational)
    input  logic [4:0]  rs2,
    output logic [63:0] rs2_data,
    
    // Write port (synchronous, rising edge)
    input  logic        wr_en,
    input  logic [4:0]  wr_addr,
    input  logic [63:0] wr_data
);

    // Storage: 32 registers, each 64 bits wide
    logic [63:0] registers [0:31];

    // =========================================================================
    // Write Logic (Synchronous)
    // =========================================================================
    // On rising clock edge, if wr_en is high, write wr_data to registers[wr_addr]
    // x0 (register 0) is never written to (implicit, as it's always zero)
    // =========================================================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to zero
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 64'h0;
            end
        end else if (wr_en && (wr_addr != 5'h0)) begin
            // Write to destination register (except x0)
            registers[wr_addr] <= wr_data;
        end
    end

    // =========================================================================
    // Read Logic (Combinational)
    // =========================================================================
    // Asynchronously read from registers[rs1] and registers[rs2]
    // If register address is x0, always return 64'h0 (hardwired zero)
    // =========================================================================
    
    // Read port 1: rs1 -> rs1_data
    assign rs1_data = (rs1 == 5'h0) ? 64'h0 : registers[rs1];
    
    // Read port 2: rs2 -> rs2_data
    assign rs2_data = (rs2 == 5'h0) ? 64'h0 : registers[rs2];

endmodule

