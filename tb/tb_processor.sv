`timescale 1ns / 1ps

module tb_processor ();

    // =========================================================================
    // PARAMETERS
    // =========================================================================
    parameter CLK_PERIOD     = 10ns;
    parameter RESET_CYCLES   = 5;
    parameter SIM_TIMEOUT    = 100000;
    parameter INSTR_MEM_SIZE = 1024;
    parameter DATA_MEM_SIZE  = 4096;
    parameter DATA_BASE      = 64'h1000;
    parameter RESULTS_BASE   = 64'h1100;

    // =========================================================================
    // SIGNALS
    // =========================================================================
    logic clk;
    logic rst_n;

    logic [63:0] instr_mem_addr;
    logic [31:0] instr_mem_data;

    logic [63:0] data_mem_addr;
    logic [63:0] data_mem_wr_data;
    logic        data_mem_wr_en;
    logic [63:0] data_mem_rd_data;

    logic [63:0] cycle_count;
    logic        simulation_done;

    // =========================================================================
    // MEMORIES
    // =========================================================================
    reg [31:0] instr_mem [0:INSTR_MEM_SIZE-1];
    reg [63:0] data_mem  [0:DATA_MEM_SIZE-1];

    // =========================================================================
    // DUT
    // =========================================================================
    rv64_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .instr_mem_addr(instr_mem_addr),
        .instr_mem_data(instr_mem_data),
        .data_mem_addr(data_mem_addr),
        .data_mem_wr_data(data_mem_wr_data),
        .data_mem_wr_en(data_mem_wr_en),
        .data_mem_rd_data(data_mem_rd_data)
    );

    // =========================================================================
    // INSTRUCTION MEMORY
    // =========================================================================
    assign instr_mem_data = instr_mem[instr_mem_addr[63:2]];

    // =========================================================================
    // DATA MEMORY
    // =========================================================================
    wire [63:0] mem_dword_addr = data_mem_addr >> 3;

    always_comb begin
        if (mem_dword_addr < DATA_MEM_SIZE)
            data_mem_rd_data = data_mem[mem_dword_addr];
        else
            data_mem_rd_data = 64'h0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (rst_n && data_mem_wr_en) begin
            if (mem_dword_addr < DATA_MEM_SIZE)
                data_mem[mem_dword_addr] <= data_mem_wr_data;
        end
    end

    // =========================================================================
    // CLOCK / RESET
    // =========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst_n = 0;
        repeat (RESET_CYCLES) @(posedge clk);
        rst_n = 1;
        $display("[%0t] Reset released", $time);
    end

    // =========================================================================
    // COUNTERS
    // =========================================================================
    initial begin
        cycle_count     = 0;
        simulation_done = 0;
        forever @(posedge clk) cycle_count++;
    end

    // =========================================================================
    // INIT INSTR MEM
    // =========================================================================
    initial begin
        integer i;
        for (i = 0; i < INSTR_MEM_SIZE; i++)
            instr_mem[i] = 32'h0;

        $readmemh("instr_mem.hex", instr_mem);

        $display("[%0t] Instruction memory loaded", $time);
    end

    // =========================================================================
    // INIT DATA MEM
    // =========================================================================
    initial begin
        integer i;
        for (i = 0; i < DATA_MEM_SIZE; i++)
            data_mem[i] = 64'h0;
        $display("[%0t] Data memory cleared", $time);
    end

    // =========================================================================
    // MAIN CONTROL
    // =========================================================================
    initial begin
        @(posedge rst_n);

        uut.rf_inst.registers[2] = 64'h9000; // stack pointer

        fork
            begin
                repeat (SIM_TIMEOUT) @(posedge clk);
                $display("[ERROR] Simulation timeout");
                simulation_done = 1;
            end
            begin
                wait_for_results();
                simulation_done = 1;
            end
        join_any

        print_results();
        #100 $finish;
    end

    // =========================================================================
    // TASKS
    // =========================================================================
    task automatic wait_for_results();
        repeat (100000) @(posedge clk);
        $display("[%0t] Test program finished", $time);
    endtask

    task automatic print_results();
        integer i;
        logic [63:0] base;
        logic [63:0] test_a, test_b;
        logic [63:0] exp_sum, exp_diff, exp_and, exp_or, exp_xor;
        logic [63:0] exp_shl, exp_shr, exp_sh2add, exp_sh3add;

        base   = RESULTS_BASE / 8;
        test_a = data_mem[16'h1e0];  // Parameters now at 0x0F00/8 = 0x1E0
        test_b = data_mem[16'h1e1];  // Parameters now at 0x0F08/8 = 0x1E1

        exp_sum    = test_a + test_b;
        exp_diff   = test_a - test_b;
        exp_and    = test_a & test_b;
        exp_or     = test_a | test_b;
        exp_xor    = test_a ^ test_b;
        exp_shl    = test_a << 2;
        exp_shr    = test_a >> 2;
        exp_sh2add = test_a + (test_b << 2);
        exp_sh3add = test_a + (test_b << 3);

        check_result(base+0,  exp_sum,    "ADD");
        check_result(base+1,  exp_diff,   "SUB");
        check_result(base+2,  123,        "LOAD");
        check_result(base+3,  exp_and,    "AND");
        check_result(base+4,  exp_or,     "OR");
        check_result(base+5,  exp_xor,    "XOR");
        check_result(base+6,  exp_shl,    "SHL");
        check_result(base+7,  exp_shr,    "SHR");
        check_result(base+10, exp_sh2add, "SH2ADD");
        check_result(base+11, exp_sh3add, "SH3ADD");

        $display("Total cycles: %0d", cycle_count);
    endtask

    task automatic check_result(
        input int unsigned index,
        input logic [63:0] expected,
        input string desc
    );
        logic [63:0] actual;
        actual = data_mem[index];

        if (actual == expected)
            $display("PASS: %-20s exp=%016h act=%016h", desc, expected, actual);
        else
            $display("FAIL: %-20s exp=%016h act=%016h", desc, expected, actual);
    endtask

    // =========================================================================
    // WAVES
    // =========================================================================
    initial begin
        $dumpfile("tb_processor.vcd");
        $dumpvars(0, tb_processor);
    end

endmodule