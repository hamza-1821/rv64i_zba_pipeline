/**
 * Hazard Detection Unit for 5-Stage RV64I Pipeline
 *
 * Description:
 *   Detects pipeline hazards and generates control signals to manage them.
 *   This unit specifically addresses load-use hazards, which cannot be fully
 *   resolved by the forwarding unit alone.
 *
 *   Load-Use Hazard:
 *   A load instruction in the MEM stage loads data that is needed by the
 *   current EX stage instruction. Because loads don't produce data until
 *   the MEM stage completes, the next instruction cannot use the loaded
 *   data immediately. This requires a one-cycle stall.
 *
 *   Stall Mechanism:
 *   - Freeze IF/ID and ID/EX pipeline registers
 *   - Freeze PC (prevent fetch of next instruction)
 *   - Insert NOP in EX stage (by disabling control signals)
 *   - Retry the dependent instruction in next cycle
 *
 * Ports:
 *   - mem_read_ex: Load instruction in EX stage (MemRead signal)
 *   - rd_ex: Destination register of EX stage load instruction (5-bit)
 *   - rs1_id: Source register 1 in ID stage (5-bit)
 *   - rs2_id: Source register 2 in ID stage (5-bit)
 *   - stall: Stall pipeline (freeze IF, ID, and ID/EX registers)
 *   - flush_if_id: Flush IF/ID register (for branch misprediction recovery)
 *
 * Stall Conditions:
 *   1. Load-Use Hazard:
 *      - mem_read_ex == 1 (load in EX stage)
 *      - (rd_ex == rs1_id OR rd_ex == rs2_id) (result needed by next instr)
 *      - rd_ex != 5'h0 (not x0, which is always zero)
 */

module hazard_unit (
    input  logic [4:0] rd_ex,
    input  logic       mem_read_ex,
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,
    
    output logic       stall,
    output logic       flush_if_id
);

    // =========================================================================
    // Load-Use Hazard Detection
    // =========================================================================
    // A load-use hazard occurs when:
    //   1. Current EX stage instruction is a load (mem_read_ex == 1)
    //   2. The load's destination register (rd_ex) is a source for the
    //      current ID stage instruction (rs1_id or rs2_id)
    //   3. The destination is not x0 (which doesn't need forwarding)
    //
    // When detected, we must stall the pipeline to allow the load to
    // complete and the forwarding unit to forward the result.
    // =========================================================================

    logic load_use_hazard;

    // Detect if load result is needed by next instruction
    assign load_use_hazard = (mem_read_ex == 1'b1) &&
                             (rd_ex != 5'h0) &&
                             ((rd_ex == rs1_id) || (rd_ex == rs2_id));

    // =========================================================================
    // Stall Signal
    // =========================================================================
    // Asserted when any hazard requiring a stall is detected.
    // Effects of stall:
    //   - PC is frozen (IF stage doesn't fetch next instruction)
    //   - IF/ID register is frozen (keeps same instruction)
    //   - ID/EX register is frozen (keeps same instruction)
    //   - Data path continues, but effectively inserts NOP
    // =========================================================================

    assign stall = load_use_hazard;

    // =========================================================================
    // Flush IF/ID Signal
    // =========================================================================
    // Normally NOT asserted in hazard unit (hazards are resolved via stall).
    // IF/ID flush is typically controlled by the branch unit when a branch
    // is mispredicted or resolved.
    //
    // However, we can optionally include branch flush logic here if desired.
    // For now, we leave it at 0 and let the branch/control unit handle it.
    // =========================================================================

    assign flush_if_id = 1'b0;

endmodule

