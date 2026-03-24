`timescale 1ns/1ps

module tb_phase2_io;

    localparam LABEL_W = 8*48;
    localparam [4:0] OP_OUT = 5'h0B;
    localparam [4:0] OP_IN  = 5'h0C;

    localparam [3:0]
        S_CLEAR_1 = 4'd0, S_T0_1 = 4'd1, S_T1_1 = 4'd2, S_T2_1 = 4'd3, S_T3_1 = 4'd4,
        S_CLEAR_2 = 4'd5, S_T0_2 = 4'd6, S_T1_2 = 4'd7, S_T2_2 = 4'd8, S_T3_2 = 4'd9,
        S_DONE    = 4'd10;

    reg  [3:0]  Present_state;
    reg         Clock, Clear;
    reg         Gra, Grb, Grc, Rin, Rout, BAout;
    reg         PCin, IRin, Yin, MARin, HIin, LOin, Zin, MDRin, CONin, Out_Portin;
    reg         IncPC, Read, Write;
    reg         PCout, MDRout, HIout, LOout, Zhighout, Zlowout, In_Portout, Cout;
    reg         AND, OR, NOT_op, NEG, SHR, SHRA, SHL, ROR, ROL, ADD, SUB, MUL, DIV;
    reg [31:0]  port_in;

    wire [31:0] BusMuxOut, PC, IR, Y, MAR, MDR, HI, LO, Zhigh, Zlow, In_Port, Out_Port, MemoryData;
    wire [63:0] Z;
    wire        CON;
    wire        addsub_overflow, neg_overflow, mul_overflow, div_by_zero, inc_overflow;
    wire [31:0] R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15;

    integer failures;

    Datapath_top DUT (
        .Clock(Clock), .Clear(Clear), .Gra(Gra), .Grb(Grb), .Grc(Grc), .Rin(Rin), .Rout(Rout), .BAout(BAout),
        .PCin(PCin), .IRin(IRin), .Yin(Yin), .MARin(MARin), .HIin(HIin), .LOin(LOin), .Zin(Zin), .MDRin(MDRin),
        .CONin(CONin), .Out_Portin(Out_Portin), .IncPC(IncPC), .Read(Read), .Write(Write), .PCout(PCout),
        .MDRout(MDRout), .HIout(HIout), .LOout(LOout), .Zhighout(Zhighout), .Zlowout(Zlowout),
        .In_Portout(In_Portout), .Cout(Cout), .AND(AND), .OR(OR), .NOT_op(NOT_op), .NEG(NEG), .SHR(SHR),
        .SHRA(SHRA), .SHL(SHL), .ROR(ROR), .ROL(ROL), .ADD(ADD), .SUB(SUB), .MUL(MUL), .DIV(DIV),
        .port_in(port_in), .BusMuxOut(BusMuxOut), .PC(PC), .IR(IR), .Y(Y), .MAR(MAR), .MDR(MDR), .HI(HI), .LO(LO),
        .Z(Z), .Zhigh(Zhigh), .Zlow(Zlow), .In_Port(In_Port), .Out_Port(Out_Port), .MemoryData(MemoryData),
        .CON(CON), .addsub_overflow(addsub_overflow), .neg_overflow(neg_overflow), .mul_overflow(mul_overflow),
        .div_by_zero(div_by_zero), .inc_overflow(inc_overflow), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4),
        .R5(R5), .R6(R6), .R7(R7), .R8(R8), .R9(R9), .R10(R10), .R11(R11), .R12(R12), .R13(R13), .R14(R14), .R15(R15)
    );

    always #5 Clock = ~Clock;

    function [31:0] encode_ra;
        input [4:0] opcode;
        input [3:0] ra;
        begin
            encode_ra = {opcode, ra, 23'b0};
        end
    endfunction

    task show_state;
        input [LABEL_W-1:0] label;
        begin
            $display("[%0t] %s BUS=%h PC=%h IR=%h R5=%h R7=%h OUT=%h IN=%h",
                $time, label, BusMuxOut, PC, IR, R5, R7, Out_Port, In_Port);
        end
    endtask

    task expect32;
        input [LABEL_W-1:0] label;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%h actual=%h", label, expected, actual);
            end else begin
                $display("PASS: %s = %h", label, actual);
            end
        end
    endtask

    task init_memory_defaults;
        begin
            DUT.U_DP.U_RAM.memory[9'h065] = 32'h0000_0084;
            DUT.U_DP.U_RAM.memory[9'h0C9] = 32'h0000_002B;
            DUT.U_DP.U_RAM.memory[9'h01F] = 32'h0000_00D4;
            DUT.U_DP.U_RAM.memory[9'h082] = 32'h0000_00A7;
        end
    endtask

    initial begin
        Clock = 1'b0;
        failures = 0;
        Present_state = S_CLEAR_1;
        $display("==== IO Group ====");
    end

    always @(*) begin
        Clear = 0;
        Gra = 0; Grb = 0; Grc = 0; Rin = 0; Rout = 0; BAout = 0;
        PCin = 0; IRin = 0; Yin = 0; MARin = 0; HIin = 0; LOin = 0; Zin = 0; MDRin = 0; CONin = 0; Out_Portin = 0;
        IncPC = 0; Read = 0; Write = 0;
        PCout = 0; MDRout = 0; HIout = 0; LOout = 0; Zhighout = 0; Zlowout = 0; In_Portout = 0; Cout = 0;
        AND = 0; OR = 0; NOT_op = 0; NEG = 0; SHR = 0; SHRA = 0; SHL = 0; ROR = 0; ROL = 0; ADD = 0; SUB = 0; MUL = 0; DIV = 0;
        port_in = 32'h0000_0000;

        case (Present_state)
            S_CLEAR_1, S_CLEAR_2: Clear = 1;
            S_T0_1, S_T0_2: begin PCout = 1; MARin = 1; IncPC = 1; Zin = 1; end
            S_T1_1, S_T1_2: begin Zlowout = 1; PCin = 1; Read = 1; MDRin = 1; end
            S_T2_1, S_T2_2: begin MDRout = 1; IRin = 1; end
            S_T3_1: begin Gra = 1; Rout = 1; Out_Portin = 1; end
            S_T3_2: begin In_Portout = 1; Gra = 1; Rin = 1; end
        endcase

        case (Present_state)
            S_T0_2, S_T1_2, S_T2_2, S_T3_2, S_DONE: port_in = 32'h1357_9BDF;
        endcase
    end

    always @(posedge Clock) begin
        #1;
        case (Present_state)
            S_CLEAR_1: begin
                show_state("CLEAR");
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_ra(OP_OUT, 4'd7);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.GPR[7].Rn.q = 32'h4D2A_91F0;
                Present_state = S_T0_1;
            end
            S_T0_1: begin show_state("T0"); Present_state = S_T1_1; end
            S_T1_1: begin show_state("T1"); Present_state = S_T2_1; end
            S_T2_1: begin show_state("T2"); Present_state = S_T3_1; end
            S_T3_1: begin
                show_state("T3");
                expect32("out R7", Out_Port, 32'h4D2A_91F0);
                Present_state = S_CLEAR_2;
            end

            S_CLEAR_2: begin
                show_state("CLEAR");
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_ra(OP_IN, 4'd5);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                Present_state = S_T0_2;
            end
            S_T0_2: begin show_state("T0"); Present_state = S_T1_2; end
            S_T1_2: begin show_state("T1"); Present_state = S_T2_2; end
            S_T2_2: begin show_state("T2"); Present_state = S_T3_2; end
            S_T3_2: begin
                show_state("T3");
                expect32("in R5", R5, 32'h1357_9BDF);
                if (failures == 0) begin
                    $display("PASS: GROUP 6 completed with no failures");
                end else begin
                    $display("FAIL: GROUP 6 completed with %0d failure(s)", failures);
                end
                $display("INFO: FSM-style testbench is holding final state for waveform inspection.");
                Present_state = S_DONE;
            end

            S_DONE: begin
            end
        endcase
    end

endmodule
