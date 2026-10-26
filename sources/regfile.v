// =============================================================================
// File        : regfile.v
// Module      : regfile
// Description : 8 x 8-bit Register File (R0..R7) with two asynchronous read
//               ports, one synchronous write port, and write-through bypass.
// =============================================================================
`timescale 1ns / 1ps

module regfile (
    input  wire       clk,      // System clock (writes occur on rising edge)
    input  wire       rst,      // Synchronous active-high reset
    input  wire       we,       // Write enable from WB stage
    input  wire [2:0] waddr,    // Write destination register index (rd)
    input  wire [7:0] wdata,    // Data to write back into register rd
    input  wire [2:0] raddr_a,  // Read port A register index (ID stage)
    input  wire [2:0] raddr_b,  // Read port B register index (ID stage)
    output wire [7:0] rdata_a,  // Read port A output (with internal bypass)
    output wire [7:0] rdata_b   // Read port B output (with internal bypass)
);

    // Array of eight 8-bit general-purpose registers (R0 is a normal register)
    reg [7:0] regs [0:7];
    integer i;

    // Synchronous reset and register write on rising clock edge
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 8'h00;
            end
        end else if (we) begin
            regs[waddr] <= wdata;
        end
    end

    // Asynchronous read ports with write-through bypass for distance-3 hazards:
    // If WB writes to the same register currently read in ID, forward wdata.
    assign rdata_a = (we && (waddr == raddr_a)) ? wdata : regs[raddr_a];
    assign rdata_b = (we && (waddr == raddr_b)) ? wdata : regs[raddr_b];

endmodule