`timescale 1ns/1ps

module tb_phase2_load;

    localparam LABEL_W = 8*48;
    localparam [4:0] OP_LD  = 5'h00;
    localparam [4:0] OP_LDI = 5'h01;

    localparam [5:0]
        S_CLEAR_1 = 6'd0,  S_T0_1 = 6'd1,  S_T1_1 = 6'd2,  S_T2_1 = 6'd3,
        S_T3_1    = 6'd4,  S_T4_1 = 6'd5,  S_T5_1 = 6'd6,  S_T6_1 = 6'd7,  S_T7_1 = 6'd8,
        S_CLEAR_2 = 6'd9,  S_T0_2 = 6'd10, S_T1_2 = 6'd11, S_T2_2 = 6'd12,
        S_T3_2    = 6'd13, S_T4_2 = 6'd14, S_T5_2 = 6'd15, S_T6_2 = 6'd16, S_T7_2 = 6'd17,
        S_CLEAR_3 = 6'd18, S_T0_3 = 6'd19, S_T1_3 = 6'd20, S_T2_3 = 6'd21,
        S_T3_3    = 6'd22, S_T4_3 = 6'd23, S_T5_3 = 6'd24,
        S_CLEAR_4 = 6'd25, S_T0_4 = 6'd26, S_T1_4 = 6'd27, S_T2_4 = 6'd28,
        S_T3_4    = 6'd29, S_T4_4 = 6'd30, S_T5_4 = 6'd31,
        S_DONE    = 6'd32;

    reg  [5:0]  Present_state;
    reg         Clock, Clear;
    reg         Gra, Grb, Rin, BAout;
    reg         PCin, IRin, Yin, MARin, Zin, MDRin;
    reg         IncPC, Read;
    reg         PCout, MDRout, Zlowout, Cout;
    reg         ADD;

    wire [31:0] BusMuxOut, PC, IR, Y, MAR, MDR, HI, LO, Zhigh, Zlow, In_Port, Out_Port, MemoryData;
    wire [63:0] Z;
    wire        CON;
    wire        addsub_overflow, neg_overflow, mul_overflow, div_by_zero, inc_overflow;
    wire [31:0] R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15;

    integer failures;

    Datapath_top DUT (
        .Clock(Clock), .Clear(Clear), .Gra(Gra), .Grb(Grb), .Grc(1'b0), .Rin(Rin), .Rout(1'b0), .BAout(BAout),
        .PCin(PCin), .IRin(IRin), .Yin(Yin), .MARin(MARin), .HIin(1'b0), .LOin(1'b0), .Zin(Zin), .MDRin(MDRin),
        .CONin(1'b0), .Out_Portin(1'b0), .IncPC(IncPC), .Read(Read), .Write(1'b0), .PCout(PCout),
        .MDRout(MDRout), .HIout(1'b0), .LOout(1'b0), .Zhighout(1'b0), .Zlowout(Zlowout),
        .In_Portout(1'b0), .Cout(Cout), .AND(1'b0), .OR(1'b0), .NOT_op(1'b0), .NEG(1'b0),
        .SHR(1'b0), .SHRA(1'b0), .SHL(1'b0), .ROR(1'b0), .ROL(1'b0), .ADD(ADD), .SUB(1'b0), .MUL(1'b0), .DIV(1'b0),
        .port_in(32'h0000_0000), .BusMuxOut(BusMuxOut), .PC(PC), .IR(IR), .Y(Y), .MAR(MAR), .MDR(MDR), .HI(HI), .LO(LO),
        .Z(Z), .Zhigh(Zhigh), .Zlow(Zlow), .In_Port(In_Port), .Out_Port(Out_Port), .MemoryData(MemoryData),
        .CON(CON), .addsub_overflow(addsub_overflow), .neg_overflow(neg_overflow), .mul_overflow(mul_overflow),
        .div_by_zero(div_by_zero), .inc_overflow(inc_overflow),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .R8(R8), .R9(R9), .R10(R10), .R11(R11), .R12(R12), .R13(R13), .R14(R14), .R15(R15)
    );

    always #5 Clock = ~Clock;

    function [31:0] encode_rrc;
        input [4:0] opcode;
        input [3:0] ra;
        input [3:0] rb;
        input [18:0] c;
        begin
            encode_rrc = {opcode, ra, rb, c};
        end
    endfunction

    task expect32;
        input [LABEL_W-1:0] label;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s expected=%h actual=%h", label, expected, actual);
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
        $display("==== Load Group ====");
    end

    always @(*) begin
        Clear = 0;
        Gra = 0; Grb = 0; Rin = 0; BAout = 0;
        PCin = 0; IRin = 0; Yin = 0; MARin = 0; Zin = 0; MDRin = 0;
        IncPC = 0; Read = 0;
        PCout = 0; MDRout = 0; Zlowout = 0; Cout = 0;
        ADD = 0;

        case (Present_state)
            S_CLEAR_1, S_CLEAR_2, S_CLEAR_3, S_CLEAR_4: Clear = 1;

            S_T0_1, S_T0_2, S_T0_3, S_T0_4: begin PCout = 1; MARin = 1; IncPC = 1; Zin = 1; end
            S_T1_1, S_T1_2, S_T1_3, S_T1_4: begin Zlowout = 1; PCin = 1; Read = 1; MDRin = 1; end
            S_T2_1, S_T2_2, S_T2_3, S_T2_4: begin MDRout = 1; IRin = 1; end
            S_T3_1, S_T3_2, S_T3_3, S_T3_4: begin Grb = 1; BAout = 1; Yin = 1; end
            S_T4_1, S_T4_2, S_T4_3, S_T4_4: begin Cout = 1; ADD = 1; Zin = 1; end

            S_T5_1, S_T5_2: begin Zlowout = 1; MARin = 1; end
            S_T6_1, S_T6_2: begin Read = 1; MDRin = 1; end
            S_T7_1, S_T7_2: begin MDRout = 1; Gra = 1; Rin = 1; end

            S_T5_3, S_T5_4: begin Zlowout = 1; Gra = 1; Rin = 1; end
        endcase
    end

    always @(posedge Clock) begin
        #1;
        case (Present_state)
            S_CLEAR_1: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_LD, 4'd7, 4'd0, 19'h065);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                Present_state = S_T0_1;
            end
            S_T0_1: Present_state = S_T1_1;
            S_T1_1: Present_state = S_T2_1;
            S_T2_1: Present_state = S_T3_1;
            S_T3_1: Present_state = S_T4_1;
            S_T4_1: Present_state = S_T5_1;
            S_T5_1: Present_state = S_T6_1;
            S_T6_1: Present_state = S_T7_1;
            S_T7_1: begin
                expect32("ld R7, 0x65", R7, 32'h0000_0084);
                Present_state = S_CLEAR_2;
            end

            S_CLEAR_2: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_LD, 4'd0, 4'd2, 19'h072);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.GPR[2].Rn.q = 32'h0000_0057;
                Present_state = S_T0_2;
            end
            S_T0_2: Present_state = S_T1_2;
            S_T1_2: Present_state = S_T2_2;
            S_T2_2: Present_state = S_T3_2;
            S_T3_2: begin
                expect32("BAout with R2 base", BusMuxOut, 32'h0000_0057);
                Present_state = S_T4_2;
            end
            S_T4_2: Present_state = S_T5_2;
            S_T5_2: Present_state = S_T6_2;
            S_T6_2: Present_state = S_T7_2;
            S_T7_2: begin
                expect32("ld R0, 0x72(R2)", R0, 32'h0000_002B);
                Present_state = S_CLEAR_3;
            end

            S_CLEAR_3: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_LDI, 4'd7, 4'd0, 19'h065);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                Present_state = S_T0_3;
            end
            S_T0_3: Present_state = S_T1_3;
            S_T1_3: Present_state = S_T2_3;
            S_T2_3: Present_state = S_T3_3;
            S_T3_3: Present_state = S_T4_3;
            S_T4_3: Present_state = S_T5_3;
            S_T5_3: begin
                expect32("ldi R7, 0x65", R7, 32'h0000_0065);
                Present_state = S_CLEAR_4;
            end

            S_CLEAR_4: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_LDI, 4'd0, 4'd2, 19'h072);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.GPR[2].Rn.q = 32'h0000_0057;
                Present_state = S_T0_4;
            end
            S_T0_4: Present_state = S_T1_4;
            S_T1_4: Present_state = S_T2_4;
            S_T2_4: Present_state = S_T3_4;
            S_T3_4: Present_state = S_T4_4;
            S_T4_4: Present_state = S_T5_4;
            S_T5_4: begin
                expect32("ldi R0, 0x72(R2)", R0, 32'h0000_00C9);
                if (failures == 0) begin
                    $display("PASS: GROUP 0 completed with no failures");
                end else begin
                    $display("FAIL: GROUP 0 completed with %0d failure(s)", failures);
                end
                Present_state = S_DONE;
            end

            S_DONE: begin
            end
        endcase
    end

endmodule
