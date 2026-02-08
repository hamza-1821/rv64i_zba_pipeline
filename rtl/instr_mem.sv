/**
 * RISC-V Instruction Memory
 *
 * Description:
 *   Read-only instruction memory for a RISC-V processor. Memory is word-aligned
 *   (32-bit wide) and accessed by Program Counter (PC). Memory contents are
 *   initialized from a hexadecimal file using $readmemh.
 *
 *   This is a behavioral model suitable for simulation and synthesis.
 *   Memory depth and initialization file can be configured.
 *
 * Ports:
 *   - addr: Read address (PC value in bytes)
 *   - rd_data: Read data output (32-bit instruction)
 *
 * Parameters:
 *   - DEPTH: Number of 32-bit words (default: 1024)
 *   - INIT_FILE: Path to hex initialization file
 *
 * Addressing:
 *   - PC is byte-addressed but word-aligned
 *   - addr[63:2] selects the 32-bit word
 *   - addr[1:0] should always be 2'b00 (word-aligned)
 *   - In this implementation, we use addr >> 2 to select the word index
 *
 * Hex File Format:
 *   Each line contains a 32-bit hexadecimal value (8 hex digits).
 *   Example:
 *     93000513  // ADDI x10, x0, 80 (rd=x10, rs1=x0, imm=80)
 *     33051033  // ADD x0, x0, x0
 *     ef000b1f  // JAL x1, -1024
 *
 * Note:
 *   - Memory is zero-initialized by default
 *   - For synthesis, the $readmemh call should be conditional or
 *     wrapped in simulation-only pragmas
 */

module instr_mem #(
    parameter int DEPTH = 1024,
    parameter string INIT_FILE = ""
) (
    input  logic [63:0] addr,
    output logic [31:0] rd_data
);

    // =========================================================================
    // Instruction Memory Storage
    // =========================================================================
    // Array of 32-bit words
    // Depth = number of 32-bit instructions
    // =========================================================================
    
    logic [31:0] mem [0:DEPTH-1];

    // =========================================================================
    // Memory Initialization
    // =========================================================================
    // Initialize memory from hex file if provided
    // $readmemh reads hex values and fills the memory array
    // =========================================================================

    initial begin
        // Zero-initialize entire memory
        for (int i = 0; i < DEPTH; i++) begin
            mem[i] = 32'h0;
        end
        
        // Load from hex file if INIT_FILE is provided
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // =========================================================================
    // Read Logic (Combinational)
    // =========================================================================
    // Extract the word index from the byte-aligned address
    // Convert PC[63:2] to memory array index
    // Return 32-bit instruction
    // =========================================================================

    logic [63:0] word_addr;

    // Convert byte address to word address (divide by 4)
    assign word_addr = addr >> 2;

    // Read instruction from memory
    // If address is out of bounds, return 0 (NOP)
    assign rd_data = (word_addr < DEPTH) ? mem[word_addr] : 32'h0;

endmodule

