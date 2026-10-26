// =============================================================================
// File        : risc8_5stage_core.v
// Module      : risc8_5stage_core
// Description : Top-level 8-bit RISC Processor Core with a 5-stage pipeline
//               (IF, ID, EX, MEM, WB), full hazard handling, and debug outputs.
// =============================================================================
`timescale 1ns / 1ps

module risc8_5stage_core (
    input  wire       clk,         // System clock (100 MHz target)
    input  wire       rst,         // Synchronous active-high reset
    output wire       halted,      // Asserted when HLT reaches WB stage
    output wire [7:0] pc_out,      // Current Program Counter value for observation
    output wire [1:0] flags_out,   // Current architectural flags {Z, C}
    output wire       instr_done   // Pulses high each cycle an instruction retires
);

    // =========================================================================
    // 1. Stage 1 (IF) Signals & PC Register
    // =========================================================================
    reg  [7:0]  pc;
    wire [15:0] if_instr;

    imem u_imem (
        .addr  (pc),
        .instr (if_instr)
    );

    // =========================================================================
    // 2. IF/ID Pipeline Register (17 bits: 16-bit instruction + 1 valid bit)
    // =========================================================================
    reg  [15:0] ifid_instr;
    reg         ifid_valid;

    // =========================================================================
    // 3. Stage 2 (ID) Instruction Fields, Control Unit & Register File
    // =========================================================================
    wire [3:0] id_opcode = ifid_instr[15:12];
    wire [2:0] id_rd     = ifid_instr[11:9];
    wire [2:0] id_rs1    = ifid_instr[8:6];
    wire [2:0] id_rs2    = ifid_instr[5:3];
    wire [7:0] id_imm8   = ifid_instr[7:0];

    wire [2:0] id_alu_op;
    wire       id_alu_src_imm;
    wire       id_ra_is_rd;
    wire       id_rb_is_rd;
    wire       id_uses_a;
    wire       id_uses_b;
    wire       id_reg_we;
    wire       id_mem_to_reg;
    wire       id_mem_we;
    wire       id_flag_we;
    wire       id_jump;
    wire       id_br_z;
    wire       id_br_nz;
    wire       id_halt;

    control_unit u_ctrl (
        .opcode      (id_opcode),
        .alu_op      (id_alu_op),
        .alu_src_imm (id_alu_src_imm),
        .ra_is_rd    (id_ra_is_rd),
        .rb_is_rd    (id_rb_is_rd),
        .uses_a      (id_uses_a),
        .uses_b      (id_uses_b),
        .reg_we      (id_reg_we),
        .mem_to_reg  (id_mem_to_reg),
        .mem_we      (id_mem_we),
        .flag_we     (id_flag_we),
        .jump        (id_jump),
        .br_z        (id_br_z),
        .br_nz       (id_br_nz),
        .halt        (id_halt)
    );

    // Select read register indices (special cases: ADDI reads rd on A, ST reads rd on B)
    wire [2:0] id_ra = id_ra_is_rd ? id_rd : id_rs1;
    wire [2:0] id_rb = id_rb_is_rd ? id_rd : id_rs2;

    wire [7:0] id_rdata_a;
    wire [7:0] id_rdata_b;

    // Forward declarations for WB stage signals driving the Register File write port
    reg        memwb_valid;
    reg        memwb_reg_we;
    reg        memwb_halt;
    reg  [2:0] memwb_rd;
    reg  [7:0] memwb_result;

    wire wb_we = memwb_valid && memwb_reg_we && !halted;

    regfile u_regfile (
        .clk     (clk),
        .rst     (rst),
        .we      (wb_we),
        .waddr   (memwb_rd),
        .wdata   (memwb_result),
        .raddr_a (id_ra),
        .raddr_b (id_rb),
        .rdata_a (id_rdata_a),
        .rdata_b (id_rdata_b)
    );

    // =========================================================================
    // 4. ID/EX Pipeline Register (48 bits total)
    // =========================================================================
    reg        idex_valid;
    reg  [2:0] idex_alu_op;
    reg        idex_alu_src_imm;
    reg        idex_uses_a;
    reg        idex_uses_b;
    reg        idex_reg_we;
    reg        idex_mem_to_reg;
    reg        idex_mem_we;
    reg        idex_flag_we;
    reg        idex_jump;
    reg        idex_br_z;
    reg        idex_br_nz;
    reg        idex_halt;
    reg  [2:0] idex_rd;
    reg  [2:0] idex_ra;
    reg  [2:0] idex_rb;
    reg  [7:0] idex_rdata_a;
    reg  [7:0] idex_rdata_b;
    reg  [7:0] idex_imm8;

    // =========================================================================
    // 5. EX/MEM Pipeline Register Declarations (32 bits total)
    // =========================================================================
    reg        exmem_valid;
    reg        exmem_reg_we;
    reg        exmem_mem_to_reg;
    reg        exmem_mem_we;
    reg        exmem_halt;
    reg  [2:0] exmem_rd;
    reg  [7:0] exmem_alu_result;
    reg  [7:0] exmem_addr;
    reg  [7:0] exmem_st_data;

    // =========================================================================
    // 6. Hazard Unit & Stage 3 (EX) Datapath
    // =========================================================================
    wire [1:0] fwd_a_sel;
    wire [1:0] fwd_b_sel;
    wire       stall;

    hazard_unit u_hazard (
        .ifid_valid       (ifid_valid),
        .id_ra            (id_ra),
        .id_rb            (id_rb),
        .id_uses_a        (id_uses_a),
        .id_uses_b        (id_uses_b),
        .idex_valid       (idex_valid),
        .idex_rd          (idex_rd),
        .idex_ra          (idex_ra),
        .idex_rb          (idex_rb),
        .idex_uses_a      (idex_uses_a),
        .idex_uses_b      (idex_uses_b),
        .idex_mem_to_reg  (idex_mem_to_reg),
        .exmem_valid      (exmem_valid),
        .exmem_reg_we     (exmem_reg_we),
        .exmem_mem_to_reg (exmem_mem_to_reg),
        .exmem_rd         (exmem_rd),
        .memwb_valid      (memwb_valid),
        .memwb_reg_we     (memwb_reg_we),
        .memwb_rd         (memwb_rd),
        .fwd_a_sel        (fwd_a_sel),
        .fwd_b_sel        (fwd_b_sel),
        .stall            (stall)
    );

    // Forwarding multiplexers for Operand A and Operand B in EX stage
    wire [7:0] ex_op_a = (fwd_a_sel == 2'b01) ? exmem_alu_result :
                         (fwd_a_sel == 2'b10) ? memwb_result     :
                                                idex_rdata_a;

    wire [7:0] ex_op_b = (fwd_b_sel == 2'b01) ? exmem_alu_result :
                         (fwd_b_sel == 2'b10) ? memwb_result     :
                                                idex_rdata_b;

    // Second mux selects between forwarded register B and 8-bit immediate
    wire [7:0] alu_in_b = idex_alu_src_imm ? idex_imm8 : ex_op_b;

    wire [7:0] ex_alu_result;
    wire       ex_z_flag;
    wire       ex_c_flag;

    alu u_alu (
        .a      (ex_op_a),
        .b      (alu_in_b),
        .alu_op (idex_alu_op),
        .result (ex_alu_result),
        .z_flag (ex_z_flag),
        .c_flag (ex_c_flag)
    );

    // Architectural status flags (Z and C) updated in EX stage
    reg flag_z;
    reg flag_c;

    // Effective Z flag for branch decision (uses current EX result if flag_we is active,
    // otherwise uses registered flag_z; in our ISA, branches have flag_we = 0)
    wire take_branch = idex_valid && (
                       idex_jump ||
                       (idex_br_z  && flag_z) ||
                       (idex_br_nz && !flag_z)
                   );

    // Halt detection in EX, MEM, or WB stops new instructions from entering
    wire halt_in_pipe = (idex_valid  && idex_halt)  ||
                        (exmem_valid && exmem_halt) ||
                        (memwb_valid && memwb_halt);

    // =========================================================================
    // 7. Stage 4 (MEM) Data Memory Access
    // =========================================================================
    wire [7:0] mem_rdata;
    wire       dmem_we = exmem_valid && exmem_mem_we && !halted;

    dmem u_dmem (
        .clk   (clk),
        .rst   (rst),
        .we    (dmem_we),
        .addr  (exmem_addr),
        .wdata (exmem_st_data),
        .rdata (mem_rdata)
    );

    // Select between loaded memory byte (for LD) and ALU result (for all others)
    wire [7:0] mem_result = exmem_mem_to_reg ? mem_rdata : exmem_alu_result;

    // =========================================================================
    // 8. Sequential Pipeline Register Updates & Priority Control
    // Priority: Reset > Halted freeze > Branch Flush > Halt squash > Stall > Normal
    // =========================================================================
    reg halted_reg;

    always @(posedge clk) begin
        if (rst) begin
            pc               <= 8'h00;
            flag_z           <= 1'b0;
            flag_c           <= 1'b0;
            halted_reg       <= 1'b0;

            // Flush IF/ID
            ifid_instr       <= 16'h0000;
            ifid_valid       <= 1'b0;

            // Flush ID/EX
            idex_valid       <= 1'b0;
            idex_alu_op      <= 3'd0;
            idex_alu_src_imm <= 1'b0;
            idex_uses_a      <= 1'b0;
            idex_uses_b      <= 1'b0;
            idex_reg_we      <= 1'b0;
            idex_mem_to_reg  <= 1'b0;
            idex_mem_we      <= 1'b0;
            idex_flag_we     <= 1'b0;
            idex_jump        <= 1'b0;
            idex_br_z        <= 1'b0;
            idex_br_nz       <= 1'b0;
            idex_halt        <= 1'b0;
            idex_rd          <= 3'd0;
            idex_ra          <= 3'd0;
            idex_rb          <= 3'd0;
            idex_rdata_a     <= 8'h00;
            idex_rdata_b     <= 8'h00;
            idex_imm8        <= 8'h00;

            // Flush EX/MEM
            exmem_valid      <= 1'b0;
            exmem_reg_we     <= 1'b0;
            exmem_mem_to_reg <= 1'b0;
            exmem_mem_we     <= 1'b0;
            exmem_halt       <= 1'b0;
            exmem_rd         <= 3'd0;
            exmem_alu_result <= 8'h00;
            exmem_addr       <= 8'h00;
            exmem_st_data    <= 8'h00;

            // Flush MEM/WB
            memwb_valid      <= 1'b0;
            memwb_reg_we     <= 1'b0;
            memwb_halt       <= 1'b0;
            memwb_rd         <= 3'd0;
            memwb_result     <= 8'h00;

        end else if (!halted) begin
            // -----------------------------------------------------------------
            // PC and IF/ID Stage Update (Priority: Branch > Halt > Stall > Normal)
            // -----------------------------------------------------------------
            if (take_branch) begin
                pc         <= idex_imm8;  // Jump/branch target address
                ifid_instr <= 16'h0000;
                ifid_valid <= 1'b0;       // Flush wrong-path instruction in IF
            end else if (halt_in_pipe) begin
                pc         <= pc;         // Stop fetching once HLT reaches EX
                ifid_instr <= 16'h0000;
                ifid_valid <= 1'b0;       // Squash younger fetched instruction
            end else if (stall) begin
                pc         <= pc;         // Hold PC during 1-cycle load-use stall
                ifid_instr <= ifid_instr; // Hold instruction waiting in IF/ID
                ifid_valid <= ifid_valid;
            end else begin
                pc         <= pc + 8'd1;  // Normal sequential fetch
                ifid_instr <= if_instr;
                ifid_valid <= 1'b1;
            end

            // -----------------------------------------------------------------
            // ID/EX Stage Update (Insert bubble on Branch, Halt in EX, or Stall)
            // -----------------------------------------------------------------
            if (take_branch || halt_in_pipe || stall || !ifid_valid) begin
                idex_valid       <= 1'b0;
                idex_alu_op      <= 3'd0;
                idex_alu_src_imm <= 1'b0;
                idex_uses_a      <= 1'b0;
                idex_uses_b      <= 1'b0;
                idex_reg_we      <= 1'b0;
                idex_mem_to_reg  <= 1'b0;
                idex_mem_we      <= 1'b0;
                idex_flag_we     <= 1'b0;
                idex_jump        <= 1'b0;
                idex_br_z        <= 1'b0;
                idex_br_nz       <= 1'b0;
                idex_halt        <= 1'b0;
                idex_rd          <= 3'd0;
                idex_ra          <= 3'd0;
                idex_rb          <= 3'd0;
                idex_rdata_a     <= 8'h00;
                idex_rdata_b     <= 8'h00;
                idex_imm8        <= 8'h00;
            end else begin
                idex_valid       <= 1'b1;
                idex_alu_op      <= id_alu_op;
                idex_alu_src_imm <= id_alu_src_imm;
                idex_uses_a      <= id_uses_a;
                idex_uses_b      <= id_uses_b;
                idex_reg_we      <= id_reg_we;
                idex_mem_to_reg  <= id_mem_to_reg;
                idex_mem_we      <= id_mem_we;
                idex_flag_we     <= id_flag_we;
                idex_jump        <= id_jump;
                idex_br_z        <= id_br_z;
                idex_br_nz       <= id_br_nz;
                idex_halt        <= id_halt;
                idex_rd          <= id_rd;
                idex_ra          <= id_ra;
                idex_rb          <= id_rb;
                idex_rdata_a     <= id_rdata_a;
                idex_rdata_b     <= id_rdata_b;
                idex_imm8        <= id_imm8;
            end

            // -----------------------------------------------------------------
            // Architectural Flags Update in EX Stage
            // -----------------------------------------------------------------
            if (idex_valid && idex_flag_we) begin
                flag_z <= ex_z_flag;
                flag_c <= ex_c_flag;
            end

            // -----------------------------------------------------------------
            // EX/MEM Stage Update
            // -----------------------------------------------------------------
            exmem_valid      <= idex_valid;
            exmem_reg_we     <= idex_valid ? idex_reg_we     : 1'b0;
            exmem_mem_to_reg <= idex_valid ? idex_mem_to_reg : 1'b0;
            exmem_mem_we     <= idex_valid ? idex_mem_we     : 1'b0;
            exmem_halt       <= idex_valid ? idex_halt       : 1'b0;
            exmem_rd         <= idex_rd;
            exmem_alu_result <= ex_alu_result;
            exmem_addr       <= ex_op_a;  // Memory address is always rs1 (Port A)
            exmem_st_data    <= ex_op_b;  // Store data is always rd (Port B)

            // -----------------------------------------------------------------
            // MEM/WB Stage Update
            // -----------------------------------------------------------------
            memwb_valid      <= exmem_valid;
            memwb_reg_we     <= exmem_valid ? exmem_reg_we : 1'b0;
            memwb_halt       <= exmem_valid ? exmem_halt   : 1'b0;
            memwb_rd         <= exmem_rd;
            memwb_result     <= mem_result;

            if (exmem_valid && exmem_halt) begin
                halted_reg   <= 1'b1;
            end
        end
    end

    // =========================================================================
    // 9. Top-Level Observation Outputs
    // =========================================================================
    assign halted     = (memwb_valid && memwb_halt) || halted_reg;
    assign pc_out     = pc;
    assign flags_out  = {flag_z, flag_c};
    assign instr_done = memwb_valid;

endmodule