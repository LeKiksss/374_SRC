module Datapath_top #(
    parameter RAM_INIT_FILE = ""
) (
    input  wire        Clock,
    input  wire        Clear,

    // Select and Encode controls
    input  wire        Gra,
    input  wire        Grb,
    input  wire        Grc,
    input  wire        Rin,
    input  wire        Rout,
    input  wire        BAout,

    // Write enables for architectural registers
    input  wire        PCin,
    input  wire        IRin,
    input  wire        Yin,
    input  wire        MARin,
    input  wire        HIin,
    input  wire        LOin,
    input  wire        Zin,
    input  wire        MDRin,
    input  wire        CONin,
    input  wire        Out_Portin,
    input  wire        R12in_force,

    // Memory and PC increment controls
    input  wire        IncPC,
    input  wire        Read,
    input  wire        Write,

    // Shared bus source controls
    input  wire        PCout,
    input  wire        MDRout,
    input  wire        HIout,
    input  wire        LOout,
    input  wire        Zhighout,
    input  wire        Zlowout,
    input  wire        In_Portout,
    input  wire        Cout,

    // ALU operation control signals
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

    // External input port
    input  wire [31:0] port_in,

    // Datapath visibility for simulation and debugging
    output wire [31:0] BusMuxOut,
    output wire [31:0] PC,
    output wire [31:0] IR,
    output wire [31:0] Y,
    output wire [31:0] MAR,
    output wire [31:0] MDR,
    output wire [31:0] HI,
    output wire [31:0] LO,
    output wire [63:0] Z,
    output wire [31:0] Zhigh,
    output wire [31:0] Zlow,
    output wire [31:0] In_Port,
    output wire [31:0] Out_Port,
    output wire [31:0] MemoryData,
    output wire        CON,

    // Arithmetic status flags from the datapath
    output wire        addsub_overflow,
    output wire        neg_overflow,
    output wire        mul_overflow,
    output wire        div_by_zero,
    output wire        inc_overflow,

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

    localparam [4:0] BUS_R0      = 5'd0;
    localparam [4:0] BUS_R15     = 5'd15;
    localparam [4:0] BUS_HI      = 5'd16;
    localparam [4:0] BUS_LO      = 5'd17;
    localparam [4:0] BUS_ZHIGH   = 5'd18;
    localparam [4:0] BUS_ZLOW    = 5'd19;
    localparam [4:0] BUS_PC      = 5'd20;
    localparam [4:0] BUS_MDR     = 5'd21;
    localparam [4:0] BUS_IN_PORT = 5'd22;
    localparam [4:0] BUS_COUT    = 5'd23;

    wire [15:0] GPRin;
    wire [15:0] GPRout;
    reg  [4:0]  BusSel;

    select_encode U_SELECT_ENCODE (
        .IR(IR),
        .Gra(Gra),
        .Grb(Grb),
        .Grc(Grc),
        .Rin(Rin),
        .Rout(Rout),
        .BAout(BAout),
        .GPRin(GPRin),
        .GPRout(GPRout)
    );

    always @(*) begin
        BusSel = BUS_R0;

        if      (GPRout[0])  BusSel = 5'd0;
        else if (GPRout[1])  BusSel = 5'd1;
        else if (GPRout[2])  BusSel = 5'd2;
        else if (GPRout[3])  BusSel = 5'd3;
        else if (GPRout[4])  BusSel = 5'd4;
        else if (GPRout[5])  BusSel = 5'd5;
        else if (GPRout[6])  BusSel = 5'd6;
        else if (GPRout[7])  BusSel = 5'd7;
        else if (GPRout[8])  BusSel = 5'd8;
        else if (GPRout[9])  BusSel = 5'd9;
        else if (GPRout[10]) BusSel = 5'd10;
        else if (GPRout[11]) BusSel = 5'd11;
        else if (GPRout[12]) BusSel = 5'd12;
        else if (GPRout[13]) BusSel = 5'd13;
        else if (GPRout[14]) BusSel = 5'd14;
        else if (GPRout[15]) BusSel = BUS_R15;
        else if (HIout)      BusSel = BUS_HI;
        else if (LOout)      BusSel = BUS_LO;
        else if (Zhighout)   BusSel = BUS_ZHIGH;
        else if (Zlowout)    BusSel = BUS_ZLOW;
        else if (PCout)      BusSel = BUS_PC;
        else if (MDRout)     BusSel = BUS_MDR;
        else if (In_Portout) BusSel = BUS_IN_PORT;
        else if (Cout)       BusSel = BUS_COUT;
    end

    Datapath #(
        .RAM_INIT_FILE(RAM_INIT_FILE)
    ) U_DP (
        .Clock(Clock),
        .Clear(Clear),
        .Rin(GPRin),
        .BAout(BAout),
        .PCin(PCin),
        .IRin(IRin),
        .Yin(Yin),
        .MARin(MARin),
        .HIin(HIin),
        .LOin(LOin),
        .Zin(Zin),
        .MDRin(MDRin),
        .CONin(CONin),
        .Out_Portin(Out_Portin),
        .R12in_force(R12in_force),
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
        .IncPC(IncPC),
        .Read(Read),
        .Write(Write),
        .port_in(port_in),
        .BusMuxOut(BusMuxOut),
        .PC(PC),
        .IR(IR),
        .Y(Y),
        .MAR(MAR),
        .MDR(MDR),
        .HI(HI),
        .LO(LO),
        .Z(Z),
        .Zlow(Zlow),
        .Zhigh(Zhigh),
        .In_Port(In_Port),
        .Out_Port(Out_Port),
        .MemoryData(MemoryData),
        .CON(CON),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .R8(R8), .R9(R9), .R10(R10), .R11(R11),
        .R12(R12), .R13(R13), .R14(R14), .R15(R15),
        .addsub_overflow(addsub_overflow),
        .neg_overflow(neg_overflow),
        .mul_overflow(mul_overflow),
        .div_by_zero(div_by_zero),
        .inc_overflow(inc_overflow)
    );

endmodule
