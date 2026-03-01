module Datapath (
    input  wire        Clock,
    input  wire        Clear,

    input  wire [15:0] Rin,

    input  wire        PCin,
    input  wire        IRin,
    input  wire        Yin,
    input  wire        MARin,
    input  wire        HIin,
    input  wire        LOin,
    input  wire        Zin,

    // 32:1 bus select
    input  wire [4:0]  BusSel,

    // ALU Control Signals (logic ops for now)
    input  wire        AND,
    input  wire        OR,
    input  wire        NOT_op,
    input  wire        NEG,
	 input  wire 		  SHR,
	 input  wire 		  SHRA,
	 input  wire 		  SHL,
	 input  wire 		  ROR,
	 input  wire 		  ROL,
	 input  wire 		  ADD,
	 input  wire		  SUB,
	 input  wire		  MUL,
	 input  wire		  DIV,


    // PC increment (T0: Z <- PC+1)
    input  wire        IncPC,

    // MDR
    input  wire        MDRin,
    input  wire        Read,
    input  wire [31:0] Mdatain,

    // outputs
    output wire [31:0] BusMuxOut,

    output wire [31:0] PC,
    output wire [31:0] IR,
    output wire [31:0] Y,
    output wire [31:0] MAR,
    output wire [31:0] HI,
    output wire [31:0] LO,
    output wire [63:0] Z,

    output wire [31:0] Zlow,
    output wire [31:0] Zhigh,

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

    // ----------------------------
    // 1) General Purpose Registers
    // ----------------------------
    wire [31:0] R [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GPR
            register #(.DATA_WIDTH_IN(32), .DATA_WIDTH_OUT(32)) Rn (
                .clear(Clear),
                .clock(Clock),
                .enable(Rin[i]),
                .BusMuxOut(BusMuxOut),
                .BusMuxIn(R[i])
            );
        end
    endgenerate

    assign R0  = R[0];
    assign R1  = R[1];
    assign R2  = R[2];
    assign R3  = R[3];
    assign R4  = R[4];
    assign R5  = R[5];
    assign R6  = R[6];
    assign R7  = R[7];
    assign R8  = R[8];
    assign R9  = R[9];
    assign R10 = R[10];
    assign R11 = R[11];
    assign R12 = R[12];
    assign R13 = R[13];
    assign R14 = R[14];
    assign R15 = R[15];

    // ----------------------------
    // 2) Special 32-bit Registers
    // ----------------------------
    register PC_reg  (.clear(Clear), .clock(Clock), .enable(PCin),  .BusMuxOut(BusMuxOut), .BusMuxIn(PC));
    register IR_reg  (.clear(Clear), .clock(Clock), .enable(IRin),  .BusMuxOut(BusMuxOut), .BusMuxIn(IR));
    register Y_reg   (.clear(Clear), .clock(Clock), .enable(Yin),   .BusMuxOut(BusMuxOut), .BusMuxIn(Y));
    register MAR_reg (.clear(Clear), .clock(Clock), .enable(MARin), .BusMuxOut(BusMuxOut), .BusMuxIn(MAR));
    register HI_reg  (.clear(Clear), .clock(Clock), .enable(HIin),  .BusMuxOut(BusMuxOut), .BusMuxIn(HI));
    register LO_reg  (.clear(Clear), .clock(Clock), .enable(LOin),  .BusMuxOut(BusMuxOut), .BusMuxIn(LO));

    // ----------------------------
    // 3) MDR (special register with 2 input sources)
    // ----------------------------
    wire [31:0] MDR_data;

    MDR MDR_reg (
        .Clock(Clock),
        .Clear(Clear),
        .MDRin(MDRin),
        .Read(Read),
        .BusMuxOut(BusMuxOut),
        .Mdatain(Mdatain),
        .MDRout(MDR_data)
    );

    // ----------------------------
    // 4) Core wiring: Y -> ALU (logic) -> Z
    // ----------------------------
    wire [31:0] A = Y;         // ALU A operand comes from Y
    wire [31:0] B = BusMuxOut; // ALU B operand comes from the bus

    wire [63:0] logic_out;

    alu_core U_LOGIC (
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
		  
        .A(A),
        .B(B),
        .out(logic_out)
    );

    // Z input: when IncPC, Z loads PC+1 (bus holds PC); else ALU output
    wire [31:0] inc_out;
    inc32 U_INC (.in(BusMuxOut), .out(inc_out));
    wire [63:0] Z_in_internal = IncPC ? {32'b0, inc_out} : logic_out;

    // ----------------------------
    // 5) Z Register (64-bit)
    // ----------------------------
    register #(.DATA_WIDTH_IN(64), .DATA_WIDTH_OUT(64)) Z_reg (
        .clear(Clear),
        .clock(Clock),
        .enable(Zin),
        .BusMuxOut(Z_in_internal),
        .BusMuxIn(Z)
    );

    assign Zlow  = Z[31:0];
    assign Zhigh = Z[63:32];

    // ----------------------------
    // 6) Bus Mux (sources -> BusMuxOut)
    // ----------------------------
    wire [31:0] InPort = 32'b0;
    wire [31:0] C_se   = 32'b0;

    reg [31:0] bus_mux_out;

    always @(*) begin
        case (BusSel)
            5'd0:  bus_mux_out = R[0];
            5'd1:  bus_mux_out = R[1];
            5'd2:  bus_mux_out = R[2];
            5'd3:  bus_mux_out = R[3];
            5'd4:  bus_mux_out = R[4];
            5'd5:  bus_mux_out = R[5];
            5'd6:  bus_mux_out = R[6];
            5'd7:  bus_mux_out = R[7];
            5'd8:  bus_mux_out = R[8];
            5'd9:  bus_mux_out = R[9];
            5'd10: bus_mux_out = R[10];
            5'd11: bus_mux_out = R[11];
            5'd12: bus_mux_out = R[12];
            5'd13: bus_mux_out = R[13];
            5'd14: bus_mux_out = R[14];
            5'd15: bus_mux_out = R[15];
            5'd16: bus_mux_out = HI;
            5'd17: bus_mux_out = LO;
            5'd18: bus_mux_out = Zhigh;
            5'd19: bus_mux_out = Zlow;
            5'd20: bus_mux_out = PC;
            5'd21: bus_mux_out = MDR_data;
            5'd22: bus_mux_out = InPort;
            5'd23: bus_mux_out = C_se;
            default: bus_mux_out = 32'b0;
        endcase
    end

    assign BusMuxOut = bus_mux_out;

endmodule
