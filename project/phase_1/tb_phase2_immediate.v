`timescale 1ns/1ps

module tb_phase2_immediate;

    localparam LABEL_W = 8*48;
    localparam [4:0] OP_ADDI = 5'h03;
    localparam [4:0] OP_ANDI = 5'h04;
    localparam [4:0] OP_ORI  = 5'h05;

    localparam [4:0]
        S_CLEAR_1 = 5'd0,  S_T0_1 = 5'd1,  S_T1_1 = 5'd2,  S_T2_1 = 5'd3,  S_T3_1 = 5'd4,  S_T4_1 = 5'd5,  S_T5_1 = 5'd6,
        S_CLEAR_2 = 5'd7,  S_T0_2 = 5'd8,  S_T1_2 = 5'd9,  S_T2_2 = 5'd10, S_T3_2 = 5'd11, S_T4_2 = 5'd12, S_T5_2 = 5'd13,
        S_CLEAR_3 = 5'd14, S_T0_3 = 5'd15, S_T1_3 = 5'd16, S_T2_3 = 5'd17, S_T3_3 = 5'd18, S_T4_3 = 5'd19, S_T5_3 = 5'd20,
        S_DONE    = 5'd21;

    reg  [4:0]  Present_state;
    reg         Clock, Clear;
    reg         Gra, Grb, Rin, Rout;
    reg         PCin, IRin, Yin, MARin, Zin, MDRin;
    reg         IncPC, Read;
    reg         PCout, MDRout, Zlowout, Cout;
    reg         AND, OR, ADD;

    wire [31:0] BusMuxOut, PC, IR, Y, MAR, MDR, HI, LO, Zhigh, Zlow, In_Port, Out_Port, MemoryData;
    wire [63:0] Z;
    wire        CON;
    wire        addsub_overflow, neg_overflow, mul_overflow, div_by_zero, inc_overflow;
    wire [31:0] R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15;

    integer failures;

    Datapath_top DUT (
        .Clock(Clock), .Clear(Clear), .Gra(Gra), .Grb(Grb), .Grc(1'b0), .Rin(Rin), .Rout(Rout), .BAout(1'b0),
        .PCin(PCin), .IRin(IRin), .Yin(Yin), .MARin(MARin), .HIin(1'b0), .LOin(1'b0), .Zin(Zin), .MDRin(MDRin),
        .CONin(1'b0), .Out_Portin(1'b0), .R12in_force(1'b0), .IncPC(IncPC), .Read(Read), .Write(1'b0), .PCout(PCout),
        .MDRout(MDRout), .HIout(1'b0), .LOout(1'b0), .Zhighout(1'b0), .Zlowout(Zlowout),
        .In_Portout(1'b0), .Cout(Cout), .AND(AND), .OR(OR), .NOT_op(1'b0), .NEG(1'b0), .SHR(1'b0),
        .SHRA(1'b0), .SHL(1'b0), .ROR(1'b0), .ROL(1'b0), .ADD(ADD), .SUB(1'b0), .MUL(1'b0), .DIV(1'b0),
        .port_in(32'h0000_0000), .BusMuxOut(BusMuxOut), .PC(PC), .IR(IR), .Y(Y), .MAR(MAR), .MDR(MDR), .HI(HI), .LO(LO),
        .Z(Z), .Zhigh(Zhigh), .Zlow(Zlow), .In_Port(In_Port), .Out_Port(Out_Port), .MemoryData(MemoryData),
        .CON(CON), .addsub_overflow(addsub_overflow), .neg_overflow(neg_overflow), .mul_overflow(mul_overflow),
        .div_by_zero(div_by_zero), .inc_overflow(inc_overflow), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4),
        .R5(R5), .R6(R6), .R7(R7), .R8(R8), .R9(R9), .R10(R10), .R11(R11), .R12(R12), .R13(R13), .R14(R14), .R15(R15)
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
        $display("==== Immediate ALU Group ====");
    end

    initial begin
        wait (Present_state == S_DONE);
        #1;
        $finish;
    end

    always @(*) begin
        Clear = 0;
        Gra = 0; Grb = 0; Rin = 0; Rout = 0;
        PCin = 0; IRin = 0; Yin = 0; MARin = 0; Zin = 0; MDRin = 0;
        IncPC = 0; Read = 0;
        PCout = 0; MDRout = 0; Zlowout = 0; Cout = 0;
        AND = 0; OR = 0; ADD = 0;

        case (Present_state)
            S_CLEAR_1, S_CLEAR_2, S_CLEAR_3: Clear = 1;

            S_T0_1, S_T0_2, S_T0_3: begin PCout = 1; MARin = 1; IncPC = 1; Zin = 1; end
            S_T1_1, S_T1_2, S_T1_3: begin Zlowout = 1; PCin = 1; Read = 1; MDRin = 1; end
            S_T2_1, S_T2_2, S_T2_3: begin MDRout = 1; IRin = 1; end
            S_T3_1, S_T3_2, S_T3_3: begin Grb = 1; Rout = 1; Yin = 1; end
            S_T4_1, S_T4_2, S_T4_3: begin Cout = 1; Zin = 1; end
            S_T5_1, S_T5_2, S_T5_3: begin Zlowout = 1; Gra = 1; Rin = 1; end
        endcase

        case (Present_state)
            S_T4_1: ADD = 1;
            S_T4_2: AND = 1;
            S_T4_3: OR  = 1;
        endcase
    end

    always @(posedge Clock) begin
        #1;
        case (Present_state)
            S_CLEAR_1: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_ADDI, 4'd7, 4'd4, 19'h7FFF7);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.GPR[4].Rn.q = 32'h0000_0034;
                print_memory_contents("addi R7, R4, -9 setup", 9'h000);
                Present_state = S_T0_1;
            end
            S_T0_1: Present_state = S_T1_1;
            S_T1_1: Present_state = S_T2_1;
            S_T2_1: Present_state = S_T3_1;
            S_T3_1: Present_state = S_T4_1;
            S_T4_1: begin
                expect32("addi sign-extended constant", BusMuxOut, 32'hFFFF_FFF7);
                Present_state = S_T5_1;
            end
            S_T5_1: begin
                expect32("addi R7, R4, -9", R7, 32'h0000_002B);
                Present_state = S_CLEAR_2;
            end

            S_CLEAR_2: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_ANDI, 4'd7, 4'd4, 19'h071);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.GPR[4].Rn.q = 32'h0000_00F3;
                print_memory_contents("andi R7, R4, 0x71 setup", 9'h000);
                Present_state = S_T0_2;
            end
            S_T0_2: Present_state = S_T1_2;
            S_T1_2: Present_state = S_T2_2;
            S_T2_2: Present_state = S_T3_2;
            S_T3_2: Present_state = S_T4_2;
            S_T4_2: Present_state = S_T5_2;
            S_T5_2: begin
                expect32("andi R7, R4, 0x71", R7, 32'h0000_0071);
                Present_state = S_CLEAR_3;
            end

            S_CLEAR_3: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_rrc(OP_ORI, 4'd7, 4'd4, 19'h071);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.GPR[4].Rn.q = 32'h0000_0004;
                print_memory_contents("ori R7, R4, 0x71 setup", 9'h000);
                Present_state = S_T0_3;
            end
            S_T0_3: Present_state = S_T1_3;
            S_T1_3: Present_state = S_T2_3;
            S_T2_3: Present_state = S_T3_3;
            S_T3_3: Present_state = S_T4_3;
            S_T4_3: Present_state = S_T5_3;
            S_T5_3: begin
                expect32("ori R7, R4, 0x71", R7, 32'h0000_0075);
                if (failures == 0) begin
                    $display("PASS: GROUP 2 completed with no failures");
                end else begin
                    $display("FAIL: GROUP 2 completed with %0d failure(s)", failures);
                end
                Present_state = S_DONE;
            end

            S_DONE: begin
            end
        endcase
    end

endmodule
