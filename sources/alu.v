// =============================================================================
// File        : alu.v
// Module      : alu
// Description : 8-bit Arithmetic Logic Unit (combinational) for the EX stage.
//               Supports 8 operations and generates Zero (Z) and Carry (C) flags.
// =============================================================================
`timescale 1ns / 1ps

module alu (
    input  wire [7:0] a,        // First 8-bit operand (from port A / forwarding)
    input  wire [7:0] b,        // Second 8-bit operand (from port B / immediate)
    input  wire [2:0] alu_op,   // 3-bit operation selector from control unit
    output reg  [7:0] result,   // 8-bit computation output
    output wire       z_flag,   // Zero flag: asserted when result == 0
    output reg        c_flag    // Carry / borrow / shift-out flag
);

    // Operation encoding matching the Control Unit specification
    localparam [2:0] ALU_ADD   = 3'd0,
                     ALU_SUB   = 3'd1,
                     ALU_AND   = 3'd2,
                     ALU_OR    = 3'd3,
                     ALU_XOR   = 3'd4,
                     ALU_SHL   = 3'd5,
                     ALU_SHR   = 3'd6,
                     ALU_PASSB = 3'd7;

    // 9-bit temporary wire to capture overflow carry during addition
    wire [8:0] add_full = {1'b0, a} + {1'b0, b};

    always @(*) begin
        // Default assignments to prevent accidental latch inference in synthesis
        result = 8'h00;
        c_flag = 1'b0;

        case (alu_op)
            ALU_ADD: begin
                result = add_full[7:0];
                c_flag = add_full[8];     // Carry is 1 if unsigned sum > 255
            end

            ALU_SUB: begin
                result = a - b;
                c_flag = (a < b);         // Borrow flag is 1 when a < b
            end

            ALU_AND: begin
                result = a & b;           // Bitwise AND; carry cleared to 0
                c_flag = 1'b0;
            end

            ALU_OR: begin
                result = a | b;           // Bitwise OR; carry cleared to 0
                c_flag = 1'b0;
            end

            ALU_XOR: begin
                result = a ^ b;           // Bitwise XOR; carry cleared to 0
                c_flag = 1'b0;
            end

            ALU_SHL: begin
                c_flag = a[7];            // Carry captures old MSB (bit 7)
                result = {a[6:0], 1'b0};  // Logical shift left by 1 bit
            end

            ALU_SHR: begin
                c_flag = a[0];            // Carry captures old LSB (bit 0)
                result = {1'b0, a[7:1]};  // Logical shift right by 1 bit
            end

            ALU_PASSB: begin
                result = b;               // Pass input B directly (used by LDI)
                c_flag = 1'b0;
            end

            default: begin
                result = 8'h00;
                c_flag = 1'b0;
            end
        endcase
    end

    // Zero flag is combinational: high whenever the 8-bit output equals zero
    assign z_flag = (result == 8'h00);

endmodule