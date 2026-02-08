/**
 * RISC-V Data Memory (Simplified)
 *
 * Description:
 *   Simple byte-addressable read/write data memory for a RISC-V processor.
 *   No type encoding; all reads/writes are 8-byte (64-bit) full doublewords.
 *
 *   - Synchronous write (on rising clock edge)
 *   - Combinational read (asynchronous)
 *
 * Ports:
 *   - clk: System clock
 *   - rst_n: Active-low asynchronous reset
 *   - addr: Read/write address (64-bit, byte-addressed)
 *   - wr_data: Write data (64-bit)
 *   - wr_en: Write enable (active high)
 *   - rd_data: Read data output (64-bit)
 *
 * Parameters:
 *   - DEPTH: Number of bytes (default: 2048)
 *   - INIT_FILE: Path to hex initialization file (optional)
 */

module data_mem #(
    parameter int DEPTH = 2048,
    parameter string INIT_FILE = ""
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [63:0] addr,
    input  logic [63:0] wr_data,
    input  logic        wr_en,
    output logic [63:0] rd_data
);

    // =========================================================================
    // Memory Storage
    // =========================================================================
    // Byte-addressable memory array
    // =========================================================================

    logic [7:0] mem [0:DEPTH-1];

    // =========================================================================
    // Memory Initialization
    // =========================================================================

    initial begin
        // Zero-initialize entire memory
        for (int i = 0; i < DEPTH; i++) begin
            mem[i] = 8'h0;
        end
        
        // Load from hex file if provided
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // =========================================================================
    // Write Logic (Synchronous)
    // =========================================================================
    // On rising clock edge, write wr_data to memory at address addr
    // =========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // No explicit reset needed (memory state preserved)
            // Async reset only affects control signals if any
        end else if (wr_en) begin
            // Write 8-byte doubleword to memory
            for (int i = 0; i < 8; i++) begin
                if ((addr + i) < DEPTH) begin
                    mem[addr + i] <= wr_data[i*8 +: 8]; //Progress 8 bits after every iter
                end
            end
        end
    end

    // =========================================================================
    // Read Logic (Combinational)
    // =========================================================================
    // Read 8-byte doubleword from memory at address addr
    // Returns full 64-bit word without any extension
    // =========================================================================

    always_comb begin
        // Read full 64-bit doubleword
        for (int i = 0; i < 8; i++) begin
            if ((addr + i) < DEPTH)
                rd_data[i*8 +: 8] = mem[addr + i];
            else
                rd_data[i*8 +: 8] = 8'h0;
        end
    end

endmodule

