// SHL instruction testbench: shl R7, R0, R4 (SHL in T4)
`timescale 1ns/10ps
module tb_shl;
    reg Clock, Clear;
    reg [15:0] Rin, Rout;
    reg PCout, Zlowout, Zhighout, MDRout, HIout, LOout;
    reg MARin, Zin, PCin, MDRin, IRin, Yin, HIin, LOin;
    reg IncPC, Read;
    reg AND, OR, NOT_op, NEG, SHR, SHRA, SHL, ROR, ROL, ADD, SUB, MUL, DIV;
    reg [31:0] Mdatain;

    parameter Default=4'b0000, Reg_load1a=4'b0001, Reg_load1b=4'b0010, Reg_load2a=4'b0011,
              Reg_load2b=4'b0100, T0=4'b0111, T1=4'b1000, T2=4'b1001, T3=4'b1010, T4=4'b1011, T5=4'b1100;
    reg [3:0] Present_state = Default;

    Datapath_top DUT (.Clock(Clock), .Clear(Clear), .Rin(Rin), .Rout(Rout), .PCin(PCin), .IRin(IRin),
        .Yin(Yin), .MARin(MARin), .HIin(HIin), .LOin(LOin), .Zin(Zin), .IncPC(IncPC), .MDRin(MDRin),
        .Read(Read), .Mdatain(Mdatain), .PCout(PCout), .MDRout(MDRout), .HIout(HIout), .LOout(LOout),
        .Zhighout(Zhighout), .Zlowout(Zlowout), .AND(AND), .OR(OR), .NOT_op(NOT_op), .NEG(NEG),
        .SHR(SHR), .SHRA(SHRA), .SHL(SHL), .ROR(ROR), .ROL(ROL), .ADD(ADD), .SUB(SUB), .MUL(MUL), .DIV(DIV),
        .BusMuxOut(), .PC(), .IR(), .Y(), .MAR(), .HI(), .LO(), .Z(), .Zhigh(), .Zlow(),
        .R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(), .R8(), .R9(), .R10(), .R11(), .R12(), .R13(), .R14(), .R15());

    initial begin Clock = 0; forever #10 Clock = ~Clock; end

    always @(posedge Clock) begin
        case (Present_state)
            Default: Present_state = Reg_load1a;
            Reg_load1a: Present_state = Reg_load1b;
            Reg_load1b: Present_state = Reg_load2a;
            Reg_load2a: Present_state = Reg_load2b;
            Reg_load2b: Present_state = T0;
            T0: Present_state = T1;
            T1: Present_state = T2;
            T2: Present_state = T3;
            T3: Present_state = T4;
            T4: Present_state = T5;
            T5: Present_state = T5;
        endcase
    end

    always @(Present_state) begin
        Rin=0; Rout=0; PCout=0; Zlowout=0; Zhighout=0; MDRout=0; HIout=0; LOout=0;
        MARin=0; Zin=0; PCin=0; MDRin=0; IRin=0; Yin=0; HIin=0; LOin=0; IncPC=0; Read=0;
        AND=0; OR=0; NOT_op=0; NEG=0; SHR=0; SHRA=0; SHL=0; ROR=0; ROL=0; ADD=0; SUB=0; MUL=0; DIV=0;
        Mdatain=0;
        case (Present_state)
            Reg_load1a: begin Mdatain=32'h0000_0008; Read=1; MDRin=1; end
            Reg_load1b: begin MDRout=1; Rin[0]=1; end
            Reg_load2a: begin Mdatain=32'd2; Read=1; MDRin=1; end
            Reg_load2b: begin MDRout=1; Rin[4]=1; end
            T0: begin PCout=1; MARin=1; IncPC=1; Zin=1; end
            T1: begin Zlowout=1; PCin=1; Read=1; MDRin=1; Mdatain=32'h11870000; end  // shl R7,R0,R4
            T2: begin MDRout=1; IRin=1; end
            T3: begin Rout[0]=1; Yin=1; end
            T4: begin Rout[4]=1; SHL=1; Zin=1; end
            T5: begin Zlowout=1; Rin[7]=1; end
        endcase
    end
endmodule
