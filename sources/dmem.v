// =============================================================================
// File        : dmem.v
// Module      : dmem
// Description : 256 x 8-bit Data Memory (RAM) for LD and ST instructions.
//               Supports synchronous write and asynchronous read (LUT-RAM).
// =============================================================================
`timescale 1ns / 1ps

module dmem (
    input  wire       clk,      // System clock
    input  wire       rst,      // Synchronous active-high reset
    input  wire       we,       // Memory write enable (active for ST in MEM stage)
    input  wire [7:0] addr,     // 8-bit byte address (from rs1)
    input  wire [7:0] wdata,    // 8-bit data to store (from rd)
    output wire [7:0] rdata     // 8-bit data read asynchronously (for LD)
);

    // 256-byte data memory array (maps to distributed LUT-RAM on Xilinx FPGAs)
    reg [7:0] ram [0:255];
    integer i;

    // Initialize memory to zero for clean simulation and synchronous reset/write
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            ram[i] = 8'h00;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) begin
                ram[i] <= 8'h00;
            end
        end else if (we) begin
            ram[addr] <= wdata;
        end
    end

    // Asynchronous read so loaded byte is ready before the MEM/WB clock edge
    assign rdata = ram[addr];

endmodule