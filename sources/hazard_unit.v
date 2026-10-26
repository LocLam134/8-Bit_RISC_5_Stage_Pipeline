// =============================================================================
// File        : hazard_unit.v
// Module      : hazard_unit
// Description : Combinational Data Hazard Unit.
//               Controls EX operand forwarding muxes and detects load-use stalls.
// =============================================================================
`timescale 1ns / 1ps

module hazard_unit (
    // Signals from ID stage (for load-use hazard detection)
    input  wire       ifid_valid,
    input  wire [2:0] id_ra,
    input  wire [2:0] id_rb,
    input  wire       id_uses_a,
    input  wire       id_uses_b,

    // Signals from EX stage (current consumer instruction & load-in-EX check)
    input  wire       idex_valid,
    input  wire [2:0] idex_rd,
    input  wire [2:0] idex_ra,
    input  wire [2:0] idex_rb,
    input  wire       idex_uses_a,
    input  wire       idex_uses_b,
    input  wire       idex_mem_to_reg, // 1 when instruction in EX is LD

    // Signals from MEM stage (distance-1 producer instruction)
    input  wire       exmem_valid,
    input  wire       exmem_reg_we,
    input  wire       exmem_mem_to_reg,
    input  wire [2:0] exmem_rd,

    // Signals from WB stage (distance-2 producer instruction)
    input  wire       memwb_valid,
    input  wire       memwb_reg_we,
    input  wire [2:0] memwb_rd,

    // Outputs to datapath
    output reg  [1:0] fwd_a_sel,       // 00: ID/EX, 01: EX/MEM, 10: MEM/WB
    output reg  [1:0] fwd_b_sel,       // 00: ID/EX, 01: EX/MEM, 10: MEM/WB
    output wire       stall            // 1: Hold PC and IF/ID, insert bubble in ID/EX
);

    // -------------------------------------------------------------------------
    // 1. Forwarding logic for ALU Operand A (EX stage)
    // Priority: EX/MEM (newest result) > MEM/WB (older result) > ID/EX register
    // -------------------------------------------------------------------------
    always @(*) begin
        fwd_a_sel = 2'b00;
        if (idex_valid && idex_uses_a) begin
            if (exmem_valid && exmem_reg_we && !exmem_mem_to_reg && (exmem_rd == idex_ra)) begin
                fwd_a_sel = 2'b01; // Forward ALU result from EX/MEM
            end else if (memwb_valid && memwb_reg_we && (memwb_rd == idex_ra)) begin
                fwd_a_sel = 2'b10; // Forward write-back result from MEM/WB
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2. Forwarding logic for Operand B (EX stage)
    // -------------------------------------------------------------------------
    always @(*) begin
        fwd_b_sel = 2'b00;
        if (idex_valid && idex_uses_b) begin
            if (exmem_valid && exmem_reg_we && !exmem_mem_to_reg && (exmem_rd == idex_rb)) begin
                fwd_b_sel = 2'b01; // Forward ALU result from EX/MEM
            end else if (memwb_valid && memwb_reg_we && (memwb_rd == idex_rb)) begin
                fwd_b_sel = 2'b10; // Forward write-back result from MEM/WB
            end
        end
    end

    // -------------------------------------------------------------------------
    // 3. Load-Use Hazard Detection (between EX load producer and ID consumer)
    // If EX holds a valid LD instruction and ID reads the same destination rd,
    // stall the pipeline for 1 cycle until LD reaches MEM/WB.
    // -------------------------------------------------------------------------
    wire match_a = id_uses_a && (id_ra == idex_rd);
    wire match_b = id_uses_b && (id_rb == idex_rd);

    assign stall = ifid_valid && idex_valid && idex_mem_to_reg && (match_a || match_b);

endmodule