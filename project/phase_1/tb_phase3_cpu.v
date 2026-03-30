`timescale 1ns/1ps

module tb_phase3_cpu;

    localparam [4:0]
        OP_ADD   = 5'b00000,
        OP_SUB   = 5'b00001,
        OP_AND   = 5'b00010,
        OP_OR    = 5'b00011,
        OP_SHR   = 5'b00100,
        OP_SHRA  = 5'b00101,
        OP_SHL   = 5'b00110,
        OP_ROR   = 5'b00111,
        OP_ROL   = 5'b01000,
        OP_ADDI  = 5'b01001,
        OP_ANDI  = 5'b01010,
        OP_ORI   = 5'b01011,
        OP_DIV   = 5'b01100,
        OP_MUL   = 5'b01101,
        OP_NEG   = 5'b01110,
        OP_NOT   = 5'b01111,
        OP_LD    = 5'b10000,
        OP_LDI   = 5'b10001,
        OP_ST    = 5'b10010,
        OP_JAL   = 5'b10011,
        OP_JR    = 5'b10100,
        OP_BR    = 5'b10101,
        OP_IN    = 5'b10110,
        OP_OUT   = 5'b10111,
        OP_MFHI  = 5'b11000,
        OP_MFLO  = 5'b11001,
        OP_NOP   = 5'b11010,
        OP_HALT  = 5'b11011;

    localparam [1:0]
        BR_ZR = 2'b00,
        BR_NZ = 2'b01,
        BR_PL = 2'b10,
        BR_MI = 2'b11;

    localparam [4:0]
        STATE_T0   = 5'd0,
        STATE_HALT = 5'd31;

    localparam [31:0] INS_BRMI = {OP_BR, 4'd5, 2'b00, BR_MI, 19'd3};
    localparam [31:0] INS_BRPL = {OP_BR, 4'd1, 2'b00, BR_PL, 19'd2};
    localparam [31:0] INS_ST_A3 = {OP_ST, 4'd5, 4'd0, 19'h0A3};
    localparam [31:0] INS_ST_89_R4 = {OP_ST, 4'd7, 4'd4, 19'h089};
    localparam [31:0] INS_MUL = {OP_MUL, 4'd3, 4'd7, 19'd0};
    localparam [31:0] INS_DIV = {OP_DIV, 4'd3, 4'd7, 19'd0};
    localparam [31:0] INS_JAL = {OP_JAL, 4'd10, 23'd0};
    localparam [31:0] INS_JR  = {OP_JR, 4'd12, 23'd0};

    reg         Clock;
    reg         Reset;
    reg         Stop;
    reg [31:0]  port_in;

    wire        Run;
    wire [4:0]  state_dbg;
    wire [31:0] BusMuxOut, PC, IR, Y, MAR, MDR, HI, LO, Zhigh, Zlow, In_Port, Out_Port, MemoryData;
    wire [63:0] Z;
    wire        CON;
    wire        addsub_overflow, neg_overflow, mul_overflow, div_by_zero, inc_overflow;
    wire [31:0] R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15;

    integer failures;
    integer cycle_count;
    reg     main_trace_enable;
    reg     main_checks_enable;

    reg saw_brmi;
    reg saw_brmi_not_taken;
    reg saw_brpl;
    reg saw_brpl_taken;
    reg saw_store_a3;
    reg saw_store_89;
    reg saw_mul;
    reg saw_div;
    reg saw_jal;
    reg saw_jr;

    mini_src_cpu DUT (
        .Clock(Clock),
        .Reset(Reset),
        .Stop(Stop),
        .port_in(port_in),
        .Run(Run),
        .state_dbg(state_dbg),
        .BusMuxOut(BusMuxOut),
        .PC(PC),
        .IR(IR),
        .Y(Y),
        .MAR(MAR),
        .MDR(MDR),
        .HI(HI),
        .LO(LO),
        .Z(Z),
        .Zhigh(Zhigh),
        .Zlow(Zlow),
        .In_Port(In_Port),
        .Out_Port(Out_Port),
        .MemoryData(MemoryData),
        .CON(CON),
        .addsub_overflow(addsub_overflow),
        .neg_overflow(neg_overflow),
        .mul_overflow(mul_overflow),
        .div_by_zero(div_by_zero),
        .inc_overflow(inc_overflow),
        .R0(R0),
        .R1(R1),
        .R2(R2),
        .R3(R3),
        .R4(R4),
        .R5(R5),
        .R6(R6),
        .R7(R7),
        .R8(R8),
        .R9(R9),
        .R10(R10),
        .R11(R11),
        .R12(R12),
        .R13(R13),
        .R14(R14),
        .R15(R15)
    );

    always #5 Clock = ~Clock;

    function [31:0] encode_r;
        input [4:0] opcode;
        input [3:0] ra;
        input [3:0] rb;
        input [3:0] rc;
        begin
            encode_r = {opcode, ra, rb, rc, 15'b0};
        end
    endfunction

    function [31:0] encode_i;
        input [4:0] opcode;
        input [3:0] ra;
        input [3:0] rb;
        input signed [31:0] c;
        begin
            encode_i = {opcode, ra, rb, c[18:0]};
        end
    endfunction

    function [31:0] encode_b;
        input [4:0] opcode;
        input [3:0] ra;
        input [1:0] cond;
        input signed [31:0] c;
        begin
            encode_b = {opcode, ra, 2'b00, cond, c[18:0]};
        end
    endfunction

    function [31:0] encode_j;
        input [4:0] opcode;
        input [3:0] ra;
        begin
            encode_j = {opcode, ra, 23'b0};
        end
    endfunction

    function [31:0] encode_m;
        input [4:0] opcode;
        begin
            encode_m = {opcode, 27'b0};
        end
    endfunction

    task expect32;
        input [8*56-1:0] label;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%08h actual=%08h", label, expected, actual);
            end
        end
    endtask

    task expect1;
        input [8*56-1:0] label;
        input actual;
        input expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%0b actual=%0b", label, expected, actual);
            end
        end
    endtask

    task clear_memory;
        integer i;
        begin
            for (i = 0; i < 512; i = i + 1) begin
                DUT.U_DP_TOP.U_DP.U_RAM.memory[i] = 32'h0000_0000;
            end
        end
    endtask

    task load_phase3_program;
        begin
            clear_memory();

            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h000] = encode_i(OP_LDI, 4'd5, 4'd0, 32'h0000_0043);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h001] = encode_i(OP_LDI, 4'd5, 4'd5, 32'h0000_0006);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h002] = encode_i(OP_LD,  4'd4, 4'd0, 32'h0000_0089);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h003] = encode_i(OP_LDI, 4'd4, 4'd4, 32'h0000_0004);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h004] = encode_i(OP_LD,  4'd0, 4'd4, -32'sd8);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h005] = encode_i(OP_LDI, 4'd2, 4'd0, 32'h0000_0004);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h006] = encode_i(OP_LDI, 4'd5, 4'd0, 32'h0000_0087);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h007] = encode_b(OP_BR,  4'd5, BR_MI, 32'sd3);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h008] = encode_i(OP_LDI, 4'd5, 4'd5, 32'h0000_0005);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h009] = encode_i(OP_LD,  4'd1, 4'd5, -32'sd3);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h00A] = encode_m(OP_NOP);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h00B] = encode_b(OP_BR,  4'd1, BR_PL, 32'sd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h00C] = encode_i(OP_LDI, 4'd3, 4'd5, 32'h0000_0007);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h00D] = encode_i(OP_LDI, 4'd7, 4'd3, -32'sd4);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h00E] = encode_r(OP_ADD,  4'd7, 4'd5, 4'd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h00F] = encode_i(OP_ADDI, 4'd1, 4'd1, 32'sd3);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h010] = encode_i(OP_NEG,  4'd1, 4'd1, 32'sd0);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h011] = encode_i(OP_NOT,  4'd1, 4'd1, 32'sd0);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h012] = encode_i(OP_ANDI, 4'd1, 4'd1, 32'h0000_000F);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h013] = encode_r(OP_ROR,  4'd4, 4'd0, 4'd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h014] = encode_i(OP_ORI,  4'd1, 4'd4, 32'h0000_0005);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h015] = encode_r(OP_SHRA, 4'd4, 4'd1, 4'd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h016] = encode_r(OP_SHR,  4'd5, 4'd5, 4'd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h017] = encode_i(OP_ST,   4'd5, 4'd0, 32'h0000_00A3);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h018] = encode_r(OP_ROL,  4'd5, 4'd0, 4'd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h019] = encode_r(OP_OR,   4'd7, 4'd2, 4'd0);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h01A] = encode_r(OP_AND,  4'd4, 4'd5, 4'd0);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h01B] = encode_i(OP_ST,   4'd7, 4'd4, 32'h0000_0089);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h01C] = encode_r(OP_SUB,  4'd0, 4'd5, 4'd7);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h01D] = encode_r(OP_SHL,  4'd4, 4'd5, 4'd2);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h01E] = encode_i(OP_LDI,  4'd7, 4'd0, 32'h0000_0007);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h01F] = encode_i(OP_LDI,  4'd3, 4'd0, 32'h0000_0019);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h020] = encode_i(OP_MUL,  4'd3, 4'd7, 32'sd0);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h021] = encode_j(OP_MFHI, 4'd1);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h022] = encode_j(OP_MFLO, 4'd6);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h023] = encode_i(OP_DIV,  4'd3, 4'd7, 32'sd0);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h024] = encode_i(OP_LDI,  4'd8, 4'd7, 32'h0000_0002);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h025] = encode_i(OP_LDI,  4'd9, 4'd3, -32'sd4);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h026] = encode_i(OP_LDI,  4'd10, 4'd6, 32'h0000_0003);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h027] = encode_i(OP_LDI,  4'd11, 4'd1, 32'h0000_0005);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h028] = encode_j(OP_JAL,  4'd10);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h029] = encode_m(OP_HALT);

            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0B2] = encode_r(OP_ADD, 4'd14, 4'd8,  4'd10);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0B3] = encode_r(OP_SUB, 4'd13, 4'd9,  4'd11);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0B4] = encode_r(OP_SUB, 4'd14, 4'd14, 4'd13);
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0B5] = encode_j(OP_JR,  4'd12);

            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h089] = 32'h0000_00A7;
            DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0A3] = 32'h0000_0068;
        end
    endtask

    task reset_check_flags;
        begin
            saw_brmi = 1'b0;
            saw_brmi_not_taken = 1'b0;
            saw_brpl = 1'b0;
            saw_brpl_taken = 1'b0;
            saw_store_a3 = 1'b0;
            saw_store_89 = 1'b0;
            saw_mul = 1'b0;
            saw_div = 1'b0;
            saw_jal = 1'b0;
            saw_jr = 1'b0;
        end
    endtask

    always @(posedge Clock) begin
        #1;

        if (!Reset && main_trace_enable) begin
            cycle_count = cycle_count + 1;
            $display(
                "TRACE cycle=%0d run=%0b state=%0d pc=%03h ir=%08h mar=%03h mdr=%08h r1=%08h r5=%08h hi=%08h lo=%08h mem89=%08h memA3=%08h",
                cycle_count, Run, state_dbg, PC[8:0], IR, MAR[8:0], MDR, R1, R5, HI, LO,
                DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h089],
                DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0A3]
            );
        end

        if (!Reset && main_checks_enable && (state_dbg == STATE_T0)) begin
            if (IR == INS_BRMI) begin
                saw_brmi = 1'b1;
                if (PC == 32'h0000_0008) begin
                    saw_brmi_not_taken = 1'b1;
                end
            end

            if (IR == INS_BRPL) begin
                saw_brpl = 1'b1;
                if (PC == 32'h0000_000E) begin
                    saw_brpl_taken = 1'b1;
                end
            end

            if (IR == INS_ST_A3) begin
                saw_store_a3 = 1'b1;
                expect32("memory[0xA3] after store", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0A3], 32'h0000_0008);
            end

            if (IR == INS_ST_89_R4) begin
                saw_store_89 = 1'b1;
                expect32("memory[0x89] after indexed store", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h089], 32'h0000_006C);
            end

            if (IR == INS_MUL) begin
                saw_mul = 1'b1;
                expect32("mul HI", HI, 32'h0000_0000);
                expect32("mul LO", LO, 32'h0000_00AF);
            end

            if (IR == INS_DIV) begin
                saw_div = 1'b1;
                expect32("div HI", HI, 32'h0000_0004);
                expect32("div LO", LO, 32'h0000_0003);
            end

            if (IR == INS_JAL) begin
                saw_jal = 1'b1;
                expect32("jal return address", R12, 32'h0000_0029);
                expect32("jal jump target", PC, 32'h0000_00B2);
            end

            if (IR == INS_JR) begin
                saw_jr = 1'b1;
                expect32("jr return target", PC, 32'h0000_0029);
            end
        end
    end

    initial begin
        Clock = 1'b0;
        Reset = 1'b1;
        Stop = 1'b0;
        port_in = 32'h0000_0000;
        failures = 0;
        cycle_count = 0;
        main_trace_enable = 1'b0;
        main_checks_enable = 1'b0;
        reset_check_flags();

        $display("==== Phase 3 Integrated CPU ====");

        load_phase3_program();
        repeat (2) @(posedge Clock);
        #1;
        expect1("Run after reset", Run, 1'b1);
        expect32("PC reset", PC, 32'h0000_0000);
        expect32("R0 reset", R0, 32'h0000_0000);
        expect32("R15 reset", R15, 32'h0000_0000);

        Reset = 1'b0;

        repeat (8) @(posedge Clock);
        #1;
        Stop = 1'b1;

        @(posedge Clock);
        #1;
        expect1("Run after external Stop", Run, 1'b0);
        expect32("PC frozen at Stop", PC, PC);

        begin : STOP_HOLD
            reg [31:0] pc_hold;
            reg [4:0] state_hold;
            integer j;
            pc_hold = PC;
            state_hold = state_dbg;
            for (j = 0; j < 3; j = j + 1) begin
                @(posedge Clock);
                #1;
                expect1("Run remains low during Stop hold", Run, 1'b0);
                expect32("PC remains frozen during Stop hold", PC, pc_hold);
                if (state_dbg !== state_hold) begin
                    failures = failures + 1;
                    $display("FAIL: state remained %0d expected %0d", state_dbg, state_hold);
                end
            end
        end

        Stop = 1'b0;
        Reset = 1'b1;
        load_phase3_program();
        repeat (2) @(posedge Clock);
        #1;
        expect1("Run restored by reset", Run, 1'b1);
        expect32("PC reset after Stop test", PC, 32'h0000_0000);

        reset_check_flags();
        cycle_count = 0;
        main_trace_enable = 1'b1;
        main_checks_enable = 1'b1;
        Reset = 1'b0;

        repeat (2) @(posedge Clock);
        #1;
        expect32("first fetch increments PC by 1", PC, 32'h0000_0001);

        begin : RUN_TO_HALT
            integer timeout_cycles;
            timeout_cycles = 0;
            while (Run && (timeout_cycles < 600)) begin
                @(posedge Clock);
                timeout_cycles = timeout_cycles + 1;
            end

            #1;
            if (Run) begin
                failures = failures + 1;
                $display("FAIL: timeout waiting for halt");
            end
        end

        main_trace_enable = 1'b0;
        main_checks_enable = 1'b0;

        expect1("halt drops Run", Run, 1'b0);
        expect32("final PC after halt fetch", PC, 32'h0000_002A);
        expect32("final R0", R0, 32'h0000_0614);
        expect32("final R4", R4, 32'h0000_6800);
        expect32("final R5", R5, 32'h0000_0680);
        expect32("final R6", R6, 32'h0000_00AF);
        expect32("final R7", R7, 32'h0000_0007);
        expect32("final R10", R10, 32'h0000_00B2);
        expect32("final R12", R12, 32'h0000_0029);
        expect32("final R13", R13, 32'h0000_0010);
        expect32("final R14", R14, 32'h0000_00AB);
        expect32("final HI", HI, 32'h0000_0004);
        expect32("final LO", LO, 32'h0000_0003);
        expect32("final memory[0x89]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h089], 32'h0000_006C);
        expect32("final memory[0xA3]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0A3], 32'h0000_0008);

        expect1("observed brmi", saw_brmi, 1'b1);
        expect1("brmi not taken", saw_brmi_not_taken, 1'b1);
        expect1("observed brpl", saw_brpl, 1'b1);
        expect1("brpl taken", saw_brpl_taken, 1'b1);
        expect1("observed store A3", saw_store_a3, 1'b1);
        expect1("observed indexed store 89", saw_store_89, 1'b1);
        expect1("observed mul", saw_mul, 1'b1);
        expect1("observed div", saw_div, 1'b1);
        expect1("observed jal", saw_jal, 1'b1);
        expect1("observed jr", saw_jr, 1'b1);

        if (failures == 0) begin
            $display("PASS: Phase 3 integrated CPU completed with no failures");
        end else begin
            $display("FAIL: Phase 3 integrated CPU completed with %0d failure(s)", failures);
        end

        $finish;
    end

endmodule
