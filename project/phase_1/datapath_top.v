module Datapath_top (
    input  wire        Clock,
    input  wire        Clear,

    // ----------------------------
    // WRITE enables (one-hot for GPRs)
    // ----------------------------
    input  wire [15:0] Rin,

    // Special register write enables
    input  wire        PCin,
    input  wire        IRin,
    input  wire        Yin,
    input  wire        MARin,
    input  wire        HIin,
    input  wire        LOin,
    input  wire        Zin,

    // MDR control
    input  wire        MDRin,
    input  wire        Read,
    input  wire [31:0] Mdatain,

    // ----------------------------
    // BUS "out" controls (one-hot sources driving the bus)
    // ----------------------------
    input  wire [15:0] Rout,      // R0out..R15out one-hot
    input  wire        PCout,
    input  wire        MDRout,
    input  wire        HIout,
    input  wire        LOout,
    input  wire        Zhighout,
    input  wire        Zlowout,
    // (later) input wire InPortout, Cout, etc.

    // ----------------------------
    // ALU controls
    // ----------------------------
    input  wire        AND,
    input  wire        OR,
    input  wire        NOT_op,
    input  wire        NEG,
    input  wire        SHR,
    input  wire        SHRA,
    input  wire        SHL,
    input  wire        ROR,
    input  wire        ROL,
    input  wire        ADD,
    input  wire        SUB,
    input  wire        MUL,
    input  wire        DIV,

    // ----------------------------
    // Outputs for waveform visibility
    // ----------------------------
    output wire [31:0] BusMuxOut,
    output wire [31:0] PC,
    output wire [31:0] IR,
    output wire [31:0] Y,
    output wire [31:0] MAR,
    output wire [31:0] HI,
    output wire [31:0] LO,
    output wire [63:0] Z,
    output wire [31:0] Zhigh,
    output wire [31:0] Zlow,

    output wire [31:0] R0,
    output wire [31:0] R1,
    output wire [31:0] R2,
    output wire [31:0] R3,
    output wire [31:0] R4,
    output wire [31:0] R5,
    output wire [31:0] R6,
    output wire [31:0] R7,
    output wire [31:0] R8,
    output wire [31:0] R9,
    output wire [31:0] R10,
    output wire [31:0] R11,
    output wire [31:0] R12,
    output wire [31:0] R13,
    output wire [31:0] R14,
    output wire [31:0] R15
);

    // -----------------------------------------
    // Encode "out" control signals into BusSel
    // -----------------------------------------
    reg [4:0] BusSel;

    always @(*) begin
        BusSel = 5'd0; // default (R0)

        // Priority encoder: expects ONE source asserted at a time.
        // GPR outs
        if      (Rout[0])  BusSel = 5'd0;
        else if (Rout[1])  BusSel = 5'd1;
        else if (Rout[2])  BusSel = 5'd2;
        else if (Rout[3])  BusSel = 5'd3;
        else if (Rout[4])  BusSel = 5'd4;
        else if (Rout[5])  BusSel = 5'd5;
        else if (Rout[6])  BusSel = 5'd6;
        else if (Rout[7])  BusSel = 5'd7;
        else if (Rout[8])  BusSel = 5'd8;
        else if (Rout[9])  BusSel = 5'd9;
        else if (Rout[10]) BusSel = 5'd10;
        else if (Rout[11]) BusSel = 5'd11;
        else if (Rout[12]) BusSel = 5'd12;
        else if (Rout[13]) BusSel = 5'd13;
        else if (Rout[14]) BusSel = 5'd14;
        else if (Rout[15]) BusSel = 5'd15;

        // Special outs
        else if (HIout)     BusSel = 5'd16;
        else if (LOout)     BusSel = 5'd17;
        else if (Zhighout)  BusSel = 5'd18;
        else if (Zlowout)   BusSel = 5'd19;
        else if (PCout)     BusSel = 5'd20;
        else if (MDRout)    BusSel = 5'd21;

        // else if (InPortout) BusSel = 5'd22; // later
        // else if (Cout)      BusSel = 5'd23; // later
    end

    // -----------------------------------------
    // Instantiate your existing Datapath core
    // -----------------------------------------
    Datapath U_DP (
        .Clock(Clock),
        .Clear(Clear),

        .Rin(Rin),

        .PCin(PCin),
        .IRin(IRin),
        .Yin(Yin),
        .MARin(MARin),
        .HIin(HIin),
        .LOin(LOin),
        .Zin(Zin),

        .BusSel(BusSel),

        .AND(AND),
        .OR(OR),
        .NOT_op(NOT_op),
        .NEG(NEG),
        .SHR(SHR),
        .SHRA(SHRA),
        .SHL(SHL),
        .ROR(ROR),
        .ROL(ROL),
        .ADD(ADD),
        .SUB(SUB),
        .MUL(MUL),
        .DIV(DIV),

        .MDRin(MDRin),
        .Read(Read),
        .Mdatain(Mdatain),

        .BusMuxOut(BusMuxOut),

        .PC(PC),
        .IR(IR),
        .Y(Y),
        .MAR(MAR),
        .HI(HI),
        .LO(LO),
        .Z(Z),
        .Zlow(Zlow),
        .Zhigh(Zhigh),

        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .R8(R8), .R9(R9), .R10(R10), .R11(R11),
        .R12(R12), .R13(R13), .R14(R14), .R15(R15)
    );

endmodule
