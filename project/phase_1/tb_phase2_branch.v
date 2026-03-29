`timescale 1ns/1ps

module tb_phase2_branch;

    localparam LABEL_W = 8*48;
    localparam [4:0] OP_BR = 5'h06;

    localparam [6:0]
        S_CLEAR_1 = 7'd0,  S_T0_1 = 7'd1,  S_T1_1 = 7'd2,  S_T2_1 = 7'd3,  S_T3_1 = 7'd4,  S_T4_1 = 7'd5,  S_T5_1 = 7'd6,  S_T6_1 = 7'd7,
        S_CLEAR_2 = 7'd8,  S_T0_2 = 7'd9,  S_T1_2 = 7'd10, S_T2_2 = 7'd11, S_T3_2 = 7'd12, S_T4_2 = 7'd13, S_T5_2 = 7'd14, S_T6_2 = 7'd15,
        S_CLEAR_3 = 7'd16, S_T0_3 = 7'd17, S_T1_3 = 7'd18, S_T2_3 = 7'd19, S_T3_3 = 7'd20, S_T4_3 = 7'd21, S_T5_3 = 7'd22, S_T6_3 = 7'd23,
        S_CLEAR_4 = 7'd24, S_T0_4 = 7'd25, S_T1_4 = 7'd26, S_T2_4 = 7'd27, S_T3_4 = 7'd28, S_T4_4 = 7'd29, S_T5_4 = 7'd30, S_T6_4 = 7'd31,
        S_CLEAR_5 = 7'd32, S_T0_5 = 7'd33, S_T1_5 = 7'd34, S_T2_5 = 7'd35, S_T3_5 = 7'd36, S_T4_5 = 7'd37, S_T5_5 = 7'd38, S_T6_5 = 7'd39,
        S_CLEAR_6 = 7'd40, S_T0_6 = 7'd41, S_T1_6 = 7'd42, S_T2_6 = 7'd43, S_T3_6 = 7'd44, S_T4_6 = 7'd45, S_T5_6 = 7'd46, S_T6_6 = 7'd47,
        S_CLEAR_7 = 7'd48, S_T0_7 = 7'd49, S_T1_7 = 7'd50, S_T2_7 = 7'd51, S_T3_7 = 7'd52, S_T4_7 = 7'd53, S_T5_7 = 7'd54, S_T6_7 = 7'd55,
        S_CLEAR_8 = 7'd56, S_T0_8 = 7'd57, S_T1_8 = 7'd58, S_T2_8 = 7'd59, S_T3_8 = 7'd60, S_T4_8 = 7'd61, S_T5_8 = 7'd62, S_T6_8 = 7'd63,
        S_DONE    = 7'd64;

    reg  [6:0]  Present_state;
    reg         Clock, Clear;
    reg         Gra, Rout;
    reg         PCin, IRin, Yin, MARin, Zin, MDRin, CONin;
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
        .Clock(Clock), .Clear(Clear), .Gra(Gra), .Grb(1'b0), .Grc(1'b0), .Rin(1'b0), .Rout(Rout), .BAout(1'b0),
        .PCin(PCin), .IRin(IRin), .Yin(Yin), .MARin(MARin), .HIin(1'b0), .LOin(1'b0), .Zin(Zin), .MDRin(MDRin),
        .CONin(CONin), .Out_Portin(1'b0), .IncPC(IncPC), .Read(Read), .Write(1'b0), .PCout(PCout),
        .MDRout(MDRout), .HIout(1'b0), .LOout(1'b0), .Zhighout(1'b0), .Zlowout(Zlowout),
        .In_Portout(1'b0), .Cout(Cout), .AND(1'b0), .OR(1'b0), .NOT_op(1'b0), .NEG(1'b0), .SHR(1'b0),
        .SHRA(1'b0), .SHL(1'b0), .ROR(1'b0), .ROL(1'b0), .ADD(ADD), .SUB(1'b0), .MUL(1'b0), .DIV(1'b0),
        .port_in(32'h0000_0000), .BusMuxOut(BusMuxOut), .PC(PC), .IR(IR), .Y(Y), .MAR(MAR), .MDR(MDR), .HI(HI), .LO(LO),
        .Z(Z), .Zhigh(Zhigh), .Zlow(Zlow), .In_Port(In_Port), .Out_Port(Out_Port), .MemoryData(MemoryData),
        .CON(CON), .addsub_overflow(addsub_overflow), .neg_overflow(neg_overflow), .mul_overflow(mul_overflow),
        .div_by_zero(div_by_zero), .inc_overflow(inc_overflow), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4),
        .R5(R5), .R6(R6), .R7(R7), .R8(R8), .R9(R9), .R10(R10), .R11(R11), .R12(R12), .R13(R13), .R14(R14), .R15(R15)
    );

    always #5 Clock = ~Clock;

    function [31:0] encode_branch;
        input [4:0] opcode;
        input [3:0] ra;
        input [1:0] cond;
        input [18:0] c;
        begin
            encode_branch = {opcode, ra, 2'b00, cond, c};
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

    task expect_con;
        input [LABEL_W-1:0] label;
        input expected;
        begin
            if (CON !== expected) begin
                failures = failures + 1;
                $display("FAIL: %s CON expected=%b actual=%b", label, expected, CON);
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

    task print_memory_contents;
        input [LABEL_W-1:0] label;
        input [8:0] instruction_addr;
        begin
            $display("Memory contents (%s):", label);
            $display("  mem[%03h] = %08h", instruction_addr, DUT.U_DP.U_RAM.memory[instruction_addr]);
            $display("  mem[065] = %08h", DUT.U_DP.U_RAM.memory[9'h065]);
            $display("  mem[0C9] = %08h", DUT.U_DP.U_RAM.memory[9'h0C9]);
            $display("  mem[01F] = %08h", DUT.U_DP.U_RAM.memory[9'h01F]);
            $display("  mem[082] = %08h", DUT.U_DP.U_RAM.memory[9'h082]);
        end
    endtask

    initial begin
        Clock = 1'b0;
        failures = 0;
        Present_state = S_CLEAR_1;
        $display("==== Branch Group ====");
    end

    always @(*) begin
        Clear = 0;
        Gra = 0; Rout = 0;
        PCin = 0; IRin = 0; Yin = 0; MARin = 0; Zin = 0; MDRin = 0; CONin = 0;
        IncPC = 0; Read = 0;
        PCout = 0; MDRout = 0; Zlowout = 0; Cout = 0;
        ADD = 0;

        case (Present_state)
            S_CLEAR_1, S_CLEAR_2, S_CLEAR_3, S_CLEAR_4, S_CLEAR_5, S_CLEAR_6, S_CLEAR_7, S_CLEAR_8: Clear = 1;

            S_T0_1, S_T0_2, S_T0_3, S_T0_4, S_T0_5, S_T0_6, S_T0_7, S_T0_8: begin PCout = 1; MARin = 1; IncPC = 1; Zin = 1; end
            S_T1_1, S_T1_2, S_T1_3, S_T1_4, S_T1_5, S_T1_6, S_T1_7, S_T1_8: begin Zlowout = 1; PCin = 1; Read = 1; MDRin = 1; end
            S_T2_1, S_T2_2, S_T2_3, S_T2_4, S_T2_5, S_T2_6, S_T2_7, S_T2_8: begin MDRout = 1; IRin = 1; end
            S_T3_1, S_T3_2, S_T3_3, S_T3_4, S_T3_5, S_T3_6, S_T3_7, S_T3_8: begin Gra = 1; Rout = 1; CONin = 1; end
            S_T4_1, S_T4_2, S_T4_3, S_T4_4, S_T4_5, S_T4_6, S_T4_7, S_T4_8: begin PCout = 1; Yin = 1; end
            S_T5_1, S_T5_2, S_T5_3, S_T5_4, S_T5_5, S_T5_6, S_T5_7, S_T5_8: begin Cout = 1; ADD = 1; Zin = 1; end
            S_T6_1, S_T6_2, S_T6_3, S_T6_4, S_T6_5, S_T6_6, S_T6_7, S_T6_8: begin Zlowout = 1; PCin = CON; end
        endcase
    end

    always @(posedge Clock) begin
        #1;
        case (Present_state)
            S_CLEAR_1: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b00, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'h0000_0000; print_memory_contents("brzr taken setup", 9'h010); Present_state = S_T0_1; end
            S_T0_1: Present_state = S_T1_1;
            S_T1_1: Present_state = S_T2_1;
            S_T2_1: Present_state = S_T3_1;
            S_T3_1: begin expect_con("brzr taken", 1'b1); Present_state = S_T4_1; end
            S_T4_1: Present_state = S_T5_1;
            S_T5_1: Present_state = S_T6_1;
            S_T6_1: begin expect32("brzr taken", PC, 32'h0000_0041); Present_state = S_CLEAR_2; end

            S_CLEAR_2: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b00, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'h0000_0005; print_memory_contents("brzr not taken setup", 9'h010); Present_state = S_T0_2; end
            S_T0_2: Present_state = S_T1_2;
            S_T1_2: Present_state = S_T2_2;
            S_T2_2: Present_state = S_T3_2;
            S_T3_2: begin expect_con("brzr not taken", 1'b0); Present_state = S_T4_2; end
            S_T4_2: Present_state = S_T5_2;
            S_T5_2: Present_state = S_T6_2;
            S_T6_2: begin expect32("brzr not taken", PC, 32'h0000_0011); Present_state = S_CLEAR_3; end

            S_CLEAR_3: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b01, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'h0000_0005; print_memory_contents("brnz taken setup", 9'h010); Present_state = S_T0_3; end
            S_T0_3: Present_state = S_T1_3;
            S_T1_3: Present_state = S_T2_3;
            S_T2_3: Present_state = S_T3_3;
            S_T3_3: begin expect_con("brnz taken", 1'b1); Present_state = S_T4_3; end
            S_T4_3: Present_state = S_T5_3;
            S_T5_3: Present_state = S_T6_3;
            S_T6_3: begin expect32("brnz taken", PC, 32'h0000_0041); Present_state = S_CLEAR_4; end

            S_CLEAR_4: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b01, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'h0000_0000; print_memory_contents("brnz not taken setup", 9'h010); Present_state = S_T0_4; end
            S_T0_4: Present_state = S_T1_4;
            S_T1_4: Present_state = S_T2_4;
            S_T2_4: Present_state = S_T3_4;
            S_T3_4: begin expect_con("brnz not taken", 1'b0); Present_state = S_T4_4; end
            S_T4_4: Present_state = S_T5_4;
            S_T5_4: Present_state = S_T6_4;
            S_T6_4: begin expect32("brnz not taken", PC, 32'h0000_0011); Present_state = S_CLEAR_5; end

            S_CLEAR_5: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b10, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'h0000_0007; print_memory_contents("brpl taken setup", 9'h010); Present_state = S_T0_5; end
            S_T0_5: Present_state = S_T1_5;
            S_T1_5: Present_state = S_T2_5;
            S_T2_5: Present_state = S_T3_5;
            S_T3_5: begin expect_con("brpl taken", 1'b1); Present_state = S_T4_5; end
            S_T4_5: Present_state = S_T5_5;
            S_T5_5: Present_state = S_T6_5;
            S_T6_5: begin expect32("brpl taken", PC, 32'h0000_0041); Present_state = S_CLEAR_6; end

            S_CLEAR_6: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b10, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'hFFFF_FFF0; print_memory_contents("brpl not taken setup", 9'h010); Present_state = S_T0_6; end
            S_T0_6: Present_state = S_T1_6;
            S_T1_6: Present_state = S_T2_6;
            S_T2_6: Present_state = S_T3_6;
            S_T3_6: begin expect_con("brpl not taken", 1'b0); Present_state = S_T4_6; end
            S_T4_6: Present_state = S_T5_6;
            S_T5_6: Present_state = S_T6_6;
            S_T6_6: begin expect32("brpl not taken", PC, 32'h0000_0011); Present_state = S_CLEAR_7; end

            S_CLEAR_7: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b11, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'hFFFF_FFF0; print_memory_contents("brmi taken setup", 9'h010); Present_state = S_T0_7; end
            S_T0_7: Present_state = S_T1_7;
            S_T1_7: Present_state = S_T2_7;
            S_T2_7: Present_state = S_T3_7;
            S_T3_7: begin expect_con("brmi taken", 1'b1); Present_state = S_T4_7; end
            S_T4_7: Present_state = S_T5_7;
            S_T5_7: Present_state = S_T6_7;
            S_T6_7: begin expect32("brmi taken", PC, 32'h0000_0041); Present_state = S_CLEAR_8; end

            S_CLEAR_8: begin init_memory_defaults(); DUT.U_DP.U_RAM.memory[9'h010] = encode_branch(OP_BR, 4'd3, 2'b11, 19'd48); DUT.U_DP.PC_reg.q = 32'h0000_0010; DUT.U_DP.GPR[3].Rn.q = 32'h0000_0000; print_memory_contents("brmi not taken setup", 9'h010); Present_state = S_T0_8; end
            S_T0_8: Present_state = S_T1_8;
            S_T1_8: Present_state = S_T2_8;
            S_T2_8: Present_state = S_T3_8;
            S_T3_8: begin expect_con("brmi not taken", 1'b0); Present_state = S_T4_8; end
            S_T4_8: Present_state = S_T5_8;
            S_T5_8: Present_state = S_T6_8;
            S_T6_8: begin
                expect32("brmi not taken", PC, 32'h0000_0011);
                if (failures == 0) begin
                    $display("PASS: GROUP 3 completed with no failures");
                end else begin
                    $display("FAIL: GROUP 3 completed with %0d failure(s)", failures);
                end
                Present_state = S_DONE;
            end

            S_DONE: begin
            end
        endcase
    end

endmodule
