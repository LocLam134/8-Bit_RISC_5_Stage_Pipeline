// =============================================================================
// File        : control_unit.v
// Module      : control_unit
// Description : Hard-wired combinational instruction decoder (Stage 2: ID).
//               Converts the 4-bit opcode into pipeline control signals.
// =============================================================================
`timescale 1ns / 1ps

module control_unit (
    input  wire [3:0] opcode,       // Instruction bits [15:12]
    output reg  [2:0] alu_op,       // ALU operation code
    output reg        alu_src_imm,  // 1: ALU input B comes from imm8
    output reg        ra_is_rd,     // 1: Read port A uses field rd (for ADDI)
    output reg        rb_is_rd,     // 1: Read port B uses field rd (for ST)
    output reg        uses_a,       // 1: Instruction reads register port A
    output reg        uses_b,       // 1: Instruction reads register port B
    output reg        reg_we,       // 1: Instruction writes to register rd in WB
    output reg        mem_to_reg,   // 1: Write-back data comes from data memory (LD)
    output reg        mem_we,       // 1: Write to data memory in MEM stage (ST)
    output reg        flag_we,      // 1: Update Z and C flags in EX stage
    output reg        jump,         // 1: Unconditional jump (JMP)
    output reg        br_z,         // 1: Branch if Zero flag is 1 (BZ)
    output reg        br_nz,        // 1: Branch if Zero flag is 0 (BNZ)
    output reg        halt          // 1: Halt processor execution (HLT)
);

    // 4-bit Opcode definitions
    localparam [3:0] OP_NOP  = 4'h0,
                     OP_ADD  = 4'h1,
                     OP_SUB  = 4'h2,
                     OP_AND  = 4'h3,
                     OP_OR   = 4'h4,
                     OP_XOR  = 4'h5,
                     OP_SHL  = 4'h6,
                     OP_SHR  = 4'h7,
                     OP_LDI  = 4'h8,
                     OP_ADDI = 4'h9,
                     OP_LD   = 4'hA,
                     OP_ST   = 4'hB,
                     OP_JMP  = 4'hC,
                     OP_BZ   = 4'hD,
                     OP_BNZ  = 4'hE,
                     OP_HLT  = 4'hF;

    always @(*) begin
        // Default all control signals to 0 (equivalent to a safe NOP)
        alu_op      = 3'd0;
        alu_src_imm = 1'b0;
        ra_is_rd    = 1'b0;
        rb_is_rd    = 1'b0;
        uses_a      = 1'b0;
        uses_b      = 1'b0;
        reg_we      = 1'b0;
        mem_to_reg  = 1'b0;
        mem_we      = 1'b0;
        flag_we     = 1'b0;
        jump        = 1'b0;
        br_z        = 1'b0;
        br_nz       = 1'b0;
        halt        = 1'b0;

        case (opcode)
            OP_NOP: begin
                // All signals remain 0
            end

            OP_ADD: begin
                alu_op  = 3'd0;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_SUB: begin
                alu_op  = 3'd1;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_AND: begin
                alu_op  = 3'd2;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_OR: begin
                alu_op  = 3'd3;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_XOR: begin
                alu_op  = 3'd4;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_SHL: begin
                alu_op  = 3'd5;
                uses_a  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_SHR: begin
                alu_op  = 3'd6;
                uses_a  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end

            OP_LDI: begin
                alu_op      = 3'd7; // Pass immediate B through ALU
                alu_src_imm = 1'b1;
                reg_we      = 1'b1;
            end

            OP_ADDI: begin
                alu_op      = 3'd0; // Add rd + imm8
                alu_src_imm = 1'b1;
                ra_is_rd    = 1'b1; // Port A reads destination register rd
                uses_a      = 1'b1;
                reg_we      = 1'b1;
                flag_we     = 1'b1;
            end

            OP_LD: begin
                uses_a     = 1'b1;  // Port A reads address register rs1
                reg_we     = 1'b1;
                mem_to_reg = 1'b1;
            end

            OP_ST: begin
                rb_is_rd = 1'b1;    // Port B reads data register rd to store
                uses_a   = 1'b1;    // Port A reads address register rs1
                uses_b   = 1'b1;
                mem_we   = 1'b1;
            end

            OP_JMP: begin
                jump = 1'b1;
            end

            OP_BZ: begin
                br_z = 1'b1;
            end

            OP_BNZ: begin
                br_nz = 1'b1;
            end

            OP_HLT: begin
                halt = 1'b1;
            end

            default: begin
                // Keep safe NOP defaults
            end
        endcase
    end

endmodule