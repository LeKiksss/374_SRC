module Datapath (
    input  wire        Clock,
    input  wire        Clear,

    // General purpose register write enables (one-hot)
    input  wire [15:0]  Rin,

    // Special register write enables
    input  wire         PCin,
    input  wire         IRin,
    input  wire         Yin,
    input  wire         MARin,
    input  wire         HIin,
    input  wire         LOin,
    input  wire         Zin,

    // Bus input to registers (from BusMux)
    input  wire [31:0]  BusMuxOut,

    // 64-bit input to Z register (from ALU/mul/div result)
    input  wire [63:0]  Z_in,

    // Outputs you may want to observe / connect to bus mux later
    output wire [31:0]  PC,
    output wire [31:0]  IR,
    output wire [31:0]  Y,
    output wire [31:0]  MAR,
    output wire [31:0]  HI,
    output wire [31:0]  LO,
    output wire [63:0]  Z,

    output wire [31:0]  Zlow,
    output wire [31:0]  Zhigh,

    output wire [31:0]  R0,
    output wire [31:0]  R1,
    output wire [31:0]  R2,
    output wire [31:0]  R3,
    output wire [31:0]  R4,
    output wire [31:0]  R5,
    output wire [31:0]  R6,
    output wire [31:0]  R7,
    output wire [31:0]  R8,
    output wire [31:0]  R9,
    output wire [31:0]  R10,
    output wire [31:0]  R11,
    output wire [31:0]  R12,
    output wire [31:0]  R13,
    output wire [31:0]  R14,
    output wire [31:0]  R15
);

    // ----------------------------
    // 1) General Purpose Registers
    // ----------------------------
    wire [31:0] R [0:15];  // internal array

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

    // Optional: expose as named outputs (nice for waveform + bus mux wiring)
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
    register PC_reg (
        .clear(Clear), .clock(Clock), .enable(PCin),
        .BusMuxOut(BusMuxOut),
        .BusMuxIn(PC)
    );

    register IR_reg (
        .clear(Clear), .clock(Clock), .enable(IRin),
        .BusMuxOut(BusMuxOut),
        .BusMuxIn(IR)
    );

    register Y_reg (
        .clear(Clear), .clock(Clock), .enable(Yin),
        .BusMuxOut(BusMuxOut),
        .BusMuxIn(Y)
    );

    register MAR_reg (
        .clear(Clear), .clock(Clock), .enable(MARin),
        .BusMuxOut(BusMuxOut),
        .BusMuxIn(MAR)
    );

    register HI_reg (
        .clear(Clear), .clock(Clock), .enable(HIin),
        .BusMuxOut(BusMuxOut),
        .BusMuxIn(HI)
    );

    register LO_reg (
        .clear(Clear), .clock(Clock), .enable(LOin),
        .BusMuxOut(BusMuxOut),
        .BusMuxIn(LO)
    );

    // ----------------------------
    // 3) Z Register (64-bit)
    // ----------------------------
    register #(.DATA_WIDTH_IN(64), .DATA_WIDTH_OUT(64)) Z_reg (
        .clear(Clear),
        .clock(Clock),
        .enable(Zin),
        .BusMuxOut(Z_in),      // NOTE: here BusMuxOut is 64-bit input for Z
        .BusMuxIn(Z)
    );

    assign Zlow  = Z[31:0];
    assign Zhigh = Z[63:32];

endmodule
