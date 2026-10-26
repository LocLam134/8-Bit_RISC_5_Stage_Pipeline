// =============================================================================
// File        : tb_risc8_5stage.v
// Module      : tb_risc8_5stage
// Author      : Lam Duy Loc - Student ID: SE190907
// Description : Self-checking testbench for the 8-bit 5-stage RISC processor.
//               Logs cycle-by-cycle activity and verifies 9 architectural checks.
// =============================================================================
`timescale 1ns / 1ps

module tb_risc8_5stage;

    // Testbench clock and reset signals
    reg        clk;
    reg        rst;

    // DUT observation outputs
    wire       halted;
    wire [7:0] pc_out;
    wire [1:0] flags_out;
    wire       instr_done;

    // Instantiate the Device Under Test (DUT)
    risc8_5stage_core dut (
        .clk        (clk),
        .rst        (rst),
        .halted     (halted),
        .pc_out     (pc_out),
        .flags_out  (flags_out),
        .instr_done (instr_done)
    );

    // 100 MHz clock generation (10 ns period: 5 ns high, 5 ns low)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Performance counters and verification status
    integer cycle_count;
    integer instr_count;
    integer stall_count;
    integer branch_count;
    integer fwd_count;
    integer fail_count;

    initial begin
        // Initialize counters and assert reset for 2 clock cycles (20 ns)
        rst          = 1'b1;
        cycle_count  = 0;
        instr_count  = 0;
        stall_count  = 0;
        branch_count = 0;
        fwd_count    = 0;
        fail_count   = 0;

        #20;
        rst = 1'b0;
        $display("==========================================================================");
        $display(" Starting 8-bit 5-Stage RISC Processor Behavioral Simulation (100 MHz)");
        $display(" Student Name : Lam Duy Loc");
        $display(" Student ID   : SE190907");
        $display("==========================================================================");
    end

    // Monitor pipeline execution on every rising clock edge after reset
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;

            if (instr_done)
                instr_count = instr_count + 1;
            if (dut.stall)
                stall_count = stall_count + 1;
            if (dut.take_branch)
                branch_count = branch_count + 1;
            if (dut.idex_valid && (dut.fwd_a_sel != 2'b00))
                fwd_count = fwd_count + 1;
            if (dut.idex_valid && (dut.fwd_b_sel != 2'b00))
                fwd_count = fwd_count + 1;

            $display("Cycle %2d | PC=0x%02h | IF/ID=%b(0x%04h) | ID/EX=%b | EX/MEM=%b | WB=%b | stall=%b br=%b fwdA=%b fwdB=%b",
                     cycle_count, pc_out,
                     dut.ifid_valid, dut.ifid_instr,
                     dut.idex_valid, dut.exmem_valid, dut.memwb_valid,
                     dut.stall, dut.take_branch, dut.fwd_a_sel, dut.fwd_b_sel);

            // When HLT reaches WB stage, wait half a cycle for final WB write and check results
            if (halted) begin
                #15;
                $display("==========================================================================");

                // Check 1..4: Registers R1, R2, R3, R4
                if (dut.u_regfile.regs[1] !== 8'h00) begin $display("FAIL: R1 = 0x%02h (expected 0x00)", dut.u_regfile.regs[1]); fail_count = fail_count + 1; end
                else $display("PASS: R1 = 0x%02h", dut.u_regfile.regs[1]);

                if (dut.u_regfile.regs[2] !== 8'h0F) begin $display("FAIL: R2 = 0x%02h (expected 0x0F)", dut.u_regfile.regs[2]); fail_count = fail_count + 1; end
                else $display("PASS: R2 = 0x%02h", dut.u_regfile.regs[2]);

                if (dut.u_regfile.regs[3] !== 8'h01) begin $display("FAIL: R3 = 0x%02h (expected 0x01)", dut.u_regfile.regs[3]); fail_count = fail_count + 1; end
                else $display("PASS: R3 = 0x%02h", dut.u_regfile.regs[3]);

                if (dut.u_regfile.regs[4] !== 8'h20) begin $display("FAIL: R4 = 0x%02h (expected 0x20)", dut.u_regfile.regs[4]); fail_count = fail_count + 1; end
                else $display("PASS: R4 = 0x%02h", dut.u_regfile.regs[4]);

                // Check 5..7: Registers R5, R6, R7
                if (dut.u_regfile.regs[5] !== 8'h00) begin $display("FAIL: R5 = 0x%02h (expected 0x00)", dut.u_regfile.regs[5]); fail_count = fail_count + 1; end
                else $display("PASS: R5 = 0x%02h", dut.u_regfile.regs[5]);

                if (dut.u_regfile.regs[6] !== 8'h66) begin $display("FAIL: R6 = 0x%02h (expected 0x66)", dut.u_regfile.regs[6]); fail_count = fail_count + 1; end
                else $display("PASS: R6 = 0x%02h", dut.u_regfile.regs[6]);

                if (dut.u_regfile.regs[7] !== 8'h00) begin $display("FAIL: R7 = 0x%02h (expected 0x00)", dut.u_regfile.regs[7]); fail_count = fail_count + 1; end
                else $display("PASS: R7 = 0x%02h", dut.u_regfile.regs[7]);

                // Check 8: Data Memory[0x20]
                if (dut.u_dmem.ram[8'h20] !== 8'h0F) begin $display("FAIL: Mem[0x20] = 0x%02h (expected 0x0F)", dut.u_dmem.ram[8'h20]); fail_count = fail_count + 1; end
                else $display("PASS: Memory[0x20] = 0x%02h", dut.u_dmem.ram[8'h20]);

                // Check 9: Architectural Flags Z and C
                if (flags_out !== 2'b11) begin $display("FAIL: Flags {Z,C} = %b (expected 11)", flags_out); fail_count = fail_count + 1; end
                else $display("PASS: Flags Z=%b, C=%b", flags_out[1], flags_out[0]);

                $display("--------------------------------------------------------------------------");
                $display(" Summary: Cycles=%0d | Instructions=%0d | Stalls=%0d | Branches=%0d | Forwards=%0d",
                         cycle_count, instr_count, stall_count, branch_count, fwd_count);
                $display("==========================================================================");

                if (fail_count == 0)
                    $display("*** ALL TESTS PASSED ***");
                else
                    $display("*** TEST FAILED (%0d errors) ***", fail_count);

                $finish;
            end
        end
    end

endmodule