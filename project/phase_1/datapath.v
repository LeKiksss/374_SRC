module Datapath (
    input  wire        Clock,
    input  wire        Clear,

    input  wire [15:0] Rin,
    input  wire        BAout,

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

    // Encoded select for the shared 32‑bit bus
    input  wire [4:0]  BusSel,

    // ALU operation selects
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


    // Increment PC by one when asserted
    input  wire        IncPC,

    input  wire        Read,
    input  wire        Write,
    input  wire [31:0] port_in,

    // Top‑level datapath visibility
    output wire [31:0] BusMuxOut,

    output wire [31:0] PC,
    output wire [31:0] IR,
    output wire [31:0] Y,
    output wire [31:0] MAR,
    output wire [31:0] MDR,
    output wire [31:0] HI,
    output wire [31:0] LO,
    output wire [63:0] Z,

    output wire [31:0] Zlow,
    output wire [31:0] Zhigh,
    output wire [31:0] In_Port,
    output wire [31:0] Out_Port,
    output wire [31:0] MemoryData,
    output wire        CON,

    // Edge‑case flags exported from ALU and incrementer
    output wire        addsub_overflow,
    output wire        neg_overflow,
    output wire        mul_overflow,
    output wire        div_by_zero,
    output wire        inc_overflow,   // PC+1 wrapped

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

    // General‑purpose register file R0–R15
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

    // Other 32‑bit architectural registers
    register PC_reg  (.clear(Clear), .clock(Clock), .enable(PCin),  .BusMuxOut(BusMuxOut), .BusMuxIn(PC));
    register IR_reg  (.clear(Clear), .clock(Clock), .enable(IRin),  .BusMuxOut(BusMuxOut), .BusMuxIn(IR));
    register Y_reg   (.clear(Clear), .clock(Clock), .enable(Yin),   .BusMuxOut(BusMuxOut), .BusMuxIn(Y));
    register MAR_reg (.clear(Clear), .clock(Clock), .enable(MARin), .BusMuxOut(BusMuxOut), .BusMuxIn(MAR));
    register HI_reg  (.clear(Clear), .clock(Clock), .enable(HIin),  .BusMuxOut(BusMuxOut), .BusMuxIn(HI));
    register LO_reg  (.clear(Clear), .clock(Clock), .enable(LOin),  .BusMuxOut(BusMuxOut), .BusMuxIn(LO));
    register OUT_reg (.clear(Clear), .clock(Clock), .enable(Out_Portin), .BusMuxOut(BusMuxOut), .BusMuxIn(Out_Port));

    // Input port is sampled each cycle so it can be gated onto the bus for the in instruction.
    reg [31:0] in_port_reg;
    always @(posedge Clock) begin
        if (Clear) begin
            in_port_reg <= 32'b0;
        end else begin
            in_port_reg <= port_in;
        end
    end
    assign In_Port = in_port_reg;

    // Memory subsystem: MAR drives the address; MDR interfaces with the shared memory data bus.
    wire [31:0] MDR_data;
    wire [31:0] memory_data_bus;

    assign memory_data_bus = Write ? MDR_data : 32'bz;

    ram512x32 U_RAM (
        .Clock(Clock),
        .Read(Read),
        .Write(Write),
        .address(MAR[8:0]),
        .data(memory_data_bus)
    );

    MDR MDR_reg (
        .Clock(Clock),
        .Clear(Clear),
        .MDRin(MDRin),
        .Read(Read),
        .BusMuxOut(BusMuxOut),
        .Mdatain(memory_data_bus),
        .MDRout(MDR_data)
    );
    assign MDR = MDR_data;
    assign MemoryData = memory_data_bus;

    // Core ALU wiring: Y and the bus feed the ALU, which then feeds Z
    wire [31:0] A = Y;         // ALU A input
    wire [31:0] B = BusMuxOut; // ALU B input

    wire [63:0] logic_out;
    wire        addsub_ovf_int;
    wire        neg_ovf_int;
    wire        mul_ovf_int;
    wire        div_zero_int;

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
        .out(logic_out),

        .addsub_overflow(addsub_ovf_int),
        .neg_overflow(neg_ovf_int),
        .mul_overflow(mul_ovf_int),
        .div_by_zero(div_zero_int)
    );

    // Z loads either PC+1 or the current ALU result
    wire [31:0] inc_out;
    inc32 U_INC (.in(BusMuxOut), .out(inc_out));

    // Detect wrap‑around when incrementing 0xFFFF_FFFF
    assign inc_overflow = IncPC && (BusMuxOut == 32'hFFFF_FFFF);

    wire [63:0] Z_in_internal = IncPC ? {32'b0, inc_out} : logic_out;

    // 64‑bit Z register holds ALU or PC+1 result
    register #(.DATA_WIDTH_IN(64), .DATA_WIDTH_OUT(64)) Z_reg (
        .clear(Clear),
        .clock(Clock),
        .enable(Zin),
        .BusMuxOut(Z_in_internal),
        .BusMuxIn(Z)
    );

    assign Zlow  = Z[31:0];
    assign Zhigh = Z[63:32];

    wire [31:0] C_sign_extended = {{14{IR[18]}}, IR[17:0]};

    con_ff U_CON (
        .Clock(Clock),
        .Clear(Clear),
        .CONin(CONin),
        .IR(IR),
        .BUS(BusMuxOut),
        .CON(CON)
    );

    // Drive ALU edge‑case flags to module outputs
    assign addsub_overflow = addsub_ovf_int;
    assign neg_overflow    = neg_ovf_int;
    assign mul_overflow    = mul_ovf_int;
    assign div_by_zero     = div_zero_int;

    // 32‑to‑1 bus multiplexer that chooses the current bus source
    wire [31:0] R0_bus = BAout ? 32'b0 : R[0];

    reg [31:0] bus_mux_out;

    always @(*) begin
        case (BusSel)
            5'd0:  bus_mux_out = R0_bus;
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
            5'd22: bus_mux_out = In_Port;
            5'd23: bus_mux_out = C_sign_extended;
            default: bus_mux_out = 32'b0;
        endcase
    end

    assign BusMuxOut = bus_mux_out;

endmodule
