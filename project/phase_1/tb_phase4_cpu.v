`timescale 1ns/1ps

module tb_phase4_cpu;

    localparam LABEL_W = 8*64;

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

    localparam [31:0] INS_BRMI   = {OP_BR,  4'd5, 2'b00, BR_MI, 19'd3};
    localparam [31:0] INS_BRPL   = {OP_BR,  4'd1, 2'b00, BR_PL, 19'd2};
    localparam [31:0] INS_ST_A3  = {OP_ST,  4'd5, 4'd0, 19'h0A3};
    localparam [31:0] INS_ST_89  = {OP_ST,  4'd7, 4'd4, 19'h089};
    localparam [31:0] INS_MUL    = {OP_MUL, 4'd3, 4'd7, 19'd0};
    localparam [31:0] INS_DIV    = {OP_DIV, 4'd3, 4'd7, 19'd0};
    localparam [31:0] INS_JAL    = {OP_JAL, 4'd10, 23'd0};
    localparam [31:0] INS_JR_R12 = {OP_JR,  4'd12, 23'd0};
    localparam [31:0] INS_ST_77  = {OP_ST,  4'd6, 4'd0, 19'h077};
    localparam [31:0] INS_OUT_R6 = {OP_OUT, 4'd6, 23'd0};
    localparam [31:0] INS_DEC_R2 = {OP_LDI, 4'd2, 4'd2, 19'h7FFFF};
    localparam [31:0] INS_DEC_R7 = {OP_LDI, 4'd7, 4'd7, 19'h7FFFF};

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

    reg  [7:0] expected_outputs [0:40];

    integer failures;
    integer cycle_count;
    integer output_count;

    reg saw_brmi;
    reg saw_brmi_not_taken;
    reg saw_brpl;
    reg saw_brpl_taken;
    reg saw_store_a3;
    reg saw_store_89;
    reg saw_mul;
    reg saw_div;
    reg saw_jal;
    reg saw_jr_r12;
    reg saw_store_77;
    reg saw_dec_r2;
    reg saw_dec_r7;

    mini_src_cpu #(
        .RAM_INIT_FILE("phase4_memory_init.hex")
    ) DUT (
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

    task expect32;
        input [LABEL_W-1:0] label;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%08h actual=%08h", label, expected, actual);
            end
        end
    endtask

    task expect8;
        input [LABEL_W-1:0] label;
        input [7:0] actual;
        input [7:0] expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%02h actual=%02h", label, expected, actual);
            end
        end
    endtask

    task expect1;
        input [LABEL_W-1:0] label;
        input actual;
        input expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%0b actual=%0b", label, expected, actual);
            end
        end
    endtask

    task init_expected_outputs;
        integer rep;
        integer idx;
        begin
            idx = 0;
            for (rep = 0; rep < 5; rep = rep + 1) begin
                expected_outputs[idx] = 8'hE0; idx = idx + 1;
                expected_outputs[idx] = 8'h70; idx = idx + 1;
                expected_outputs[idx] = 8'h38; idx = idx + 1;
                expected_outputs[idx] = 8'h1C; idx = idx + 1;
                expected_outputs[idx] = 8'h0E; idx = idx + 1;
                expected_outputs[idx] = 8'h07; idx = idx + 1;
                expected_outputs[idx] = 8'h03; idx = idx + 1;
                expected_outputs[idx] = 8'h01; idx = idx + 1;
            end
            expected_outputs[idx] = 8'h63;
        end
    endtask

    task reset_flags;
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
            saw_jr_r12 = 1'b0;
            saw_store_77 = 1'b0;
            saw_dec_r2 = 1'b0;
            saw_dec_r7 = 1'b0;
        end
    endtask

    always @(posedge Clock) begin
        #1;

        if (!Reset) begin
            cycle_count = cycle_count + 1;

            if (state_dbg == STATE_T0) begin
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

                if (IR == INS_ST_89) begin
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

                if (IR == INS_JR_R12) begin
                    saw_jr_r12 = 1'b1;
                    expect32("jr R12 return target", PC, 32'h0000_0029);
                end

                if (IR == INS_ST_77) begin
                    saw_store_77 = 1'b1;
                    expect32("memory[0x77] after store", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h077], 32'h0000_00E0);
                end

                if (IR == INS_DEC_R2) begin
                    saw_dec_r2 = 1'b1;
                end

                if (IR == INS_DEC_R7) begin
                    saw_dec_r7 = 1'b1;
                end

                if (IR == INS_OUT_R6) begin
                    if (output_count < 41) begin
                        expect8("Out.Port lower byte", Out_Port[7:0], expected_outputs[output_count]);
                        $display("TRACE: OUT[%0d] = %02h", output_count, Out_Port[7:0]);
                    end else begin
                        failures = failures + 1;
                        $display("FAIL: saw unexpected extra output event value=%02h", Out_Port[7:0]);
                    end
                    output_count = output_count + 1;
                end
            end
        end
    end

    initial begin
        Clock = 1'b0;
        Reset = 1'b1;
        Stop = 1'b0;
        port_in = 32'h0000_00E0;
        failures = 0;
        cycle_count = 0;
        output_count = 0;

        init_expected_outputs();
        reset_flags();

        $display("==== Phase 4 Integrated CPU ====");

        repeat (2) @(posedge Clock);
        #1;

        expect1("Run after reset", Run, 1'b1);
        expect32("PC reset", PC, 32'h0000_0000);
        expect32("R0 reset", R0, 32'h0000_0000);
        expect32("R15 reset", R15, 32'h0000_0000);
        expect32("initial mem[0x77]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h077], 32'h0000_0000);
        expect32("initial mem[0x88]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h088], 32'h0000_FFFF);
        expect32("initial mem[0x89]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h089], 32'h0000_00A7);
        expect32("initial mem[0xA3]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h0A3], 32'h0000_0068);
        expect32("official ldi decrement at 0x2F", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h02F], INS_DEC_R2);
        expect32("official ldi decrement at 0x32", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h032], INS_DEC_R7);

        Reset = 1'b0;

        repeat (2) @(posedge Clock);
        #1;
        expect32("first fetch increments PC by 1", PC, 32'h0000_0001);

        begin : RUN_TO_HALT
            integer timeout_cycles;
            timeout_cycles = 0;
            while (Run && (timeout_cycles < 50000000)) begin
                @(posedge Clock);
                timeout_cycles = timeout_cycles + 1;
            end

            #1;
            if (Run) begin
                $display("FAIL: timeout waiting for halt");
                $fatal(1, "FAIL: timeout waiting for halt");
            end
        end

        expect1("halt drops Run", Run, 1'b0);
        expect32("final PC after halt fetch", PC, 32'h0000_003C);
        expect32("final R2", R2, 32'h0000_0000);
        expect32("final R3", R3, 32'h0000_002E);
        expect32("final R5", R5, 32'h0000_0001);
        expect32("final R6", R6, 32'h0000_0063);
        expect32("final R7", R7, 32'h0000_0000);
        expect32("final R12", R12, 32'h0000_0029);
        expect32("final Out.Port", Out_Port, 32'h0000_0063);
        expect32("final memory[0x77]", DUT.U_DP_TOP.U_DP.U_RAM.memory[9'h077], 32'h0000_00E0);
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
        expect1("observed jr R12", saw_jr_r12, 1'b1);
        expect1("observed store 77", saw_store_77, 1'b1);
        expect1("observed ldi decrement R2", saw_dec_r2, 1'b1);
        expect1("observed ldi decrement R7", saw_dec_r7, 1'b1);
        expect32("output event count", output_count, 32'd41);

        if (failures == 0) begin
            $display("PASS: Phase 4 integrated CPU completed with no failures");
            $finish;
        end else begin
            $display("FAIL: Phase 4 integrated CPU completed with %0d failure(s)", failures);
            $fatal(1, "FAIL: Phase 4 integrated CPU completed with %0d failure(s)", failures);
        end
    end

endmodule
