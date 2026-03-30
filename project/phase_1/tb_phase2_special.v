`timescale 1ns/1ps

module tb_phase2_special;

    localparam LABEL_W = 8*48;
    localparam [4:0] OP_MFHI = 5'h09;
    localparam [4:0] OP_MFLO = 5'h0A;

    localparam [3:0]
        S_CLEAR_1 = 4'd0, S_T0_1 = 4'd1, S_T1_1 = 4'd2, S_T2_1 = 4'd3, S_T3_1 = 4'd4,
        S_CLEAR_2 = 4'd5, S_T0_2 = 4'd6, S_T1_2 = 4'd7, S_T2_2 = 4'd8, S_T3_2 = 4'd9,
        S_DONE    = 4'd10;

    reg  [3:0]  Present_state;
    reg         Clock, Clear;
    reg         Gra, Rin;
    reg         PCin, IRin, MARin, Zin, MDRin;
    reg         IncPC, Read;
    reg         PCout, MDRout, HIout, LOout, Zlowout;

    wire [31:0] BusMuxOut, PC, IR, Y, MAR, MDR, HI, LO, Zhigh, Zlow, In_Port, Out_Port, MemoryData;
    wire [63:0] Z;
    wire        CON;
    wire        addsub_overflow, neg_overflow, mul_overflow, div_by_zero, inc_overflow;
    wire [31:0] R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15;

    integer failures;

    Datapath_top DUT (
        .Clock(Clock), .Clear(Clear), .Gra(Gra), .Grb(1'b0), .Grc(1'b0), .Rin(Rin), .Rout(1'b0), .BAout(1'b0),
        .PCin(PCin), .IRin(IRin), .Yin(1'b0), .MARin(MARin), .HIin(1'b0), .LOin(1'b0), .Zin(Zin), .MDRin(MDRin),
        .CONin(1'b0), .Out_Portin(1'b0), .R12in_force(1'b0), .IncPC(IncPC), .Read(Read), .Write(1'b0), .PCout(PCout),
        .MDRout(MDRout), .HIout(HIout), .LOout(LOout), .Zhighout(1'b0), .Zlowout(Zlowout),
        .In_Portout(1'b0), .Cout(1'b0), .AND(1'b0), .OR(1'b0), .NOT_op(1'b0), .NEG(1'b0), .SHR(1'b0),
        .SHRA(1'b0), .SHL(1'b0), .ROR(1'b0), .ROL(1'b0), .ADD(1'b0), .SUB(1'b0), .MUL(1'b0), .DIV(1'b0),
        .port_in(32'h0000_0000), .BusMuxOut(BusMuxOut), .PC(PC), .IR(IR), .Y(Y), .MAR(MAR), .MDR(MDR), .HI(HI), .LO(LO),
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
        $display("==== Special Group ====");
    end

    initial begin
        wait (Present_state == S_DONE);
        #1;
        $finish;
    end

    always @(*) begin
        Clear = 0;
        Gra = 0; Rin = 0;
        PCin = 0; IRin = 0; MARin = 0; Zin = 0; MDRin = 0;
        IncPC = 0; Read = 0;
        PCout = 0; MDRout = 0; HIout = 0; LOout = 0; Zlowout = 0;

        case (Present_state)
            S_CLEAR_1, S_CLEAR_2: Clear = 1;
            S_T0_1, S_T0_2: begin PCout = 1; MARin = 1; IncPC = 1; Zin = 1; end
            S_T1_1, S_T1_2: begin Zlowout = 1; PCin = 1; Read = 1; MDRin = 1; end
            S_T2_1, S_T2_2: begin MDRout = 1; IRin = 1; end
            S_T3_1: begin HIout = 1; Gra = 1; Rin = 1; end
            S_T3_2: begin LOout = 1; Gra = 1; Rin = 1; end
        endcase
    end

    always @(posedge Clock) begin
        #1;
        case (Present_state)
            S_CLEAR_1: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_ra(OP_MFHI, 4'd5);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.HI_reg.q = 32'h1234_5678;
                print_memory_contents("mfhi R5 setup", 9'h000);
                Present_state = S_T0_1;
            end
            S_T0_1: Present_state = S_T1_1;
            S_T1_1: Present_state = S_T2_1;
            S_T2_1: Present_state = S_T3_1;
            S_T3_1: begin
                expect32("mfhi R5", R5, 32'h1234_5678);
                Present_state = S_CLEAR_2;
            end

            S_CLEAR_2: begin
                init_memory_defaults();
                DUT.U_DP.U_RAM.memory[9'h000] = encode_ra(OP_MFLO, 4'd1);
                DUT.U_DP.PC_reg.q = 32'h0000_0000;
                DUT.U_DP.LO_reg.q = 32'h89AB_CDEF;
                print_memory_contents("mflo R1 setup", 9'h000);
                Present_state = S_T0_2;
            end
            S_T0_2: Present_state = S_T1_2;
            S_T1_2: Present_state = S_T2_2;
            S_T2_2: Present_state = S_T3_2;
            S_T3_2: begin
                expect32("mflo R1", R1, 32'h89AB_CDEF);
                if (failures == 0) begin
                    $display("PASS: GROUP 5 completed with no failures");
                end else begin
                    $display("FAIL: GROUP 5 completed with %0d failure(s)", failures);
                end
                Present_state = S_DONE;
            end

            S_DONE: begin
            end
        endcase
    end

endmodule
