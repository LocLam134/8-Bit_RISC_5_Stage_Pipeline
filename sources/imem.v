// =============================================================================
// File        : imem.v
// Module      : imem
// Description : 256 x 16-bit Instruction Memory (ROM) with asynchronous read.
//               Pre-loaded with the self-checking verification program.
// =============================================================================
`timescale 1ns / 1ps

module imem (
    input  wire [7:0]  addr,    // Program Counter (PC) address from IF stage
    output wire [15:0] instr    // 16-bit instruction fetched in the same cycle
);

    reg [15:0] rom [0:255];
    integer i;

    initial begin
        // Default all unused ROM locations to NOP (0x0000)
        for (i = 0; i < 256; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // ---------------------------------------------------------------------
        // Verification Program: Tests all instruction formats, forwarding at
        // distances 1/2/3, shift ops, taken/not-taken branches, a 5..1 summation
        // loop, store/load, load-use stall, 8-bit carry overflow, jump, and halt.
        // ---------------------------------------------------------------------
        rom[8'h00] = 16'h823C; // 00: LDI  R1, 0x3C      -> R1 = 0x3C
        rom[8'h01] = 16'h840F; // 01: LDI  R2, 0x0F      -> R2 = 0x0F
        rom[8'h02] = 16'h3650; // 02: AND  R3, R1, R2    -> R3 = 0x0C (fwd R1, R2)
        rom[8'h03] = 16'h4850; // 03: OR   R4, R1, R2    -> R4 = 0x3F (bypass R1, fwd R2)
        rom[8'h04] = 16'h5A50; // 04: XOR  R5, R1, R2    -> R5 = 0x33
        rom[8'h05] = 16'h6D40; // 05: SHL  R6, R5        -> R6 = 0x66, C = 0 (fwd R5)
        rom[8'h06] = 16'h7F80; // 06: SHR  R7, R6        -> R7 = 0x33, C = 0 (fwd R6)
        rom[8'h07] = 16'h2FE8; // 07: SUB  R7, R7, R5    -> R7 = 0x00, Z = 1 (fwd R7)
        rom[8'h08] = 16'hD00A; // 08: BZ   0x0A          -> Taken branch #1 to 0x0A
        rom[8'h09] = 16'h8EFF; // 09: LDI  R7, 0xFF      -> Wrong-path (flushed!)

        // Loop initialization: compute sum 5 + 4 + 3 + 2 + 1 = 15 (0x0F) in R2
        rom[8'h0A] = 16'h8205; // 0A: LDI  R1, 5         -> R1 = loop counter (5)
        rom[8'h0B] = 16'h8400; // 0B: LDI  R2, 0         -> R2 = accumulator (0)
        rom[8'h0C] = 16'h8601; // 0C: LDI  R3, 1         -> R3 = step decrement (1)

        // Loop body (executes 5 times; BNZ taken 4 times, not-taken on 5th)
        rom[8'h0D] = 16'h1488; // 0D: ADD  R2, R2, R1    -> R2 = R2 + R1
        rom[8'h0E] = 16'h2258; // 0E: SUB  R1, R1, R3    -> R1 = R1 - 1
        rom[8'h0F] = 16'hE00D; // 0F: BNZ  0x0D          -> Taken branches #2..#5

        // Memory access, load-use hazard test, and carry/zero flag test
        rom[8'h10] = 16'h8820; // 10: LDI  R4, 0x20      -> R4 = memory address 0x20
        rom[8'h11] = 16'hB500; // 11: ST   R2, [R4]      -> Mem[0x20] = 0x0F (fwd R4)
        rom[8'h12] = 16'hAB00; // 12: LD   R5, [R4]      -> R5 = 0x0F (fwd R4)
        rom[8'h13] = 16'h9AF0; // 13: ADDI R5, 0xF0      -> R5 = 0xFF (1-cycle stall + fwd)
        rom[8'h14] = 16'h9A01; // 14: ADDI R5, 0x01      -> R5 = 0x00, Z = 1, C = 1 (fwd R5)

        // Unconditional jump and processor halt
        rom[8'h15] = 16'hC017; // 15: JMP  0x17          -> Taken branch #6 to 0x17
        rom[8'h16] = 16'h8EFF; // 16: LDI  R7, 0xFF      -> Wrong-path (flushed!)
        rom[8'h17] = 16'hF000; // 17: HLT                -> Stop processor execution
    end

    // Asynchronous read: instruction is available in the same clock cycle
    assign instr = rom[addr];

endmodule