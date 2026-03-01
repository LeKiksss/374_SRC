module alu_core (
    input  wire        AND,
    input  wire        OR,
    input  wire        NOT_op,
    input  wire        NEG,

    // Shift / rotate controls
    input  wire        SHR,
    input  wire        SHRA,
    input  wire        SHL,
    input  wire        ROR,
    input  wire        ROL,

    // Add / sub controls
    input  wire        ADD,
    input  wire        SUB,
	 
	 // Multiply / Divide controls
	 input wire			  MUL,
	 input wire			  DIV,

    input  wire [31:0] A,   // from Y
    input  wire [31:0] B,   // from bus (also holds shift amount)

    output wire [63:0] out  // to Z input (low 32 bits used)
);

    // Shift amount (0..31)
    wire [4:0] shamt = B[4:0];

    // NOT and NEG apply to B in this style
    wire [31:0] not_b = ~B;

    // NEG = two's complement of B = (~B) + 1 using inc32 (no '+')
    wire [31:0] neg_b;
    inc32 u_inc32 (
        .in(not_b),
        .out(neg_b)
    );

    // Rotate trick (avoids "32 - shamt"):
    // Use {A,A} and shift, then take the correct 32-bit slice (no part-select on expr in older Verilog)
    wire [63:0] AA = {A, A};
    wire [63:0] AA_shl = AA << shamt;
    wire [63:0] AA_shr = AA >> shamt;
    wire [31:0] rol_a = AA_shl[63:32];
    wire [31:0] ror_a = AA_shr[31:0];

    // ---------------------------------------------------------
    // ADD/SUB support (NO + or -): ripple-carry adder approach
    // A - B = A + (~B) + 1
    // ---------------------------------------------------------
		wire [31:0] addsub_s;
		wire        addsub_cout;

		addsub32 U_ADDSUB32 (
			 .A(A),
			 .B(B),
			 .Sub(SUB),
			 .S(addsub_s),
			 .Cout(addsub_cout)
		);
    reg [63:0] result;
	 
	 // Multiply support 
	 wire [63:0] mul_out;

		mult32x32_booth U_MUL (
			.A(A),
			.B(B),
			.P(mul_out)
		);
		
	 // Divide support
	 wire [63:0] div_out;

	div32_nonrestoring U_DIV (
		.dividend(A),   // Typically: Y holds dividend
		.divisor(B),    // Bus holds divisor
		.result(div_out)
	);



    always @(*) begin
        result = 64'b0;

        // Logic ops
        if (AND) begin
            result = {32'b0, (A & B)};
        end else if (OR) begin
            result = {32'b0, (A | B)};
        end else if (NOT_op) begin
            result = {32'b0, not_b};
        end else if (NEG) begin
            result = {32'b0, neg_b};

        // Shift / rotate ops (operate on A = Y)
        end else if (SHL) begin
            result = {32'b0, (A << shamt)};
        end else if (SHR) begin
            result = {32'b0, (A >> shamt)};
        end else if (SHRA) begin
            result = {32'b0, ($signed(A) >>> shamt)};
        end else if (ROL) begin
            result = {32'b0, rol_a};
        end else if (ROR) begin
            result = {32'b0, ror_a};

        // ADD / SUB (share same adder result; mode controlled by SUB)
        end else if (ADD) begin
            result = {32'b0, addsub_s};
        end else if (SUB) begin
            result = {32'b0, addsub_s};
        end else if (MUL) begin
				result = mul_out;			// full 64-bit product goes into Z
		  end else if (DIV) begin
				result = div_out; 		// {remainder, quotient}
		  end
	 end

    assign out = result;

endmodule
