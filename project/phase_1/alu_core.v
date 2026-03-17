module alu_core (
    input  wire        AND,
    input  wire        OR,
    input  wire        NOT_op,
    input  wire        NEG,

    // Shift and rotate operations
    input  wire        SHR,
    input  wire        SHRA,
    input  wire        SHL,
    input  wire        ROR,
    input  wire        ROL,

    // Add and subtract operations
    input  wire        ADD,
    input  wire        SUB,
	 
	 // Multiply and divide operations
	 input wire			  MUL,
	 input wire			  DIV,

    // ALU operands
    input  wire [31:0] A,   // usually comes from Y
    input  wire [31:0] B,   // usually comes from the bus (also carries shift amount)

    // 64-bit result that feeds the Z register
    output wire [63:0] out,

    // Status flags for arithmetic edge cases
    output wire        addsub_overflow,
    output wire        neg_overflow,
    output wire        mul_overflow,
    output wire        div_by_zero
);

    wire [4:0] shamt = B[4:0];

    wire [31:0] not_b = ~B;

    // NEG is implemented as (~B) + 1 using the incrementer
    wire [31:0] neg_b;
    inc32 u_inc32 (
        .in(not_b),
        .out(neg_b)
    );

    // Rotation is done by concatenating A with itself and then slicing
    wire [63:0] AA = {A, A};
    wire [63:0] AA_shl = AA << shamt;
    wire [63:0] AA_shr = AA >> shamt;
    wire [31:0] rol_a = AA_shl[63:32];
    wire [31:0] ror_a = AA_shr[31:0];

    // Manual arithmetic shift right with explicit sign extension
    wire [31:0] shr_a  = A >> shamt;
    wire [31:0] shra_fill = A[31] ? ~({32{1'b1}} >> shamt) : 32'h0000_0000;
    wire [31:0] shra_a = shr_a | shra_fill;

    // 32‑bit ripple-carry adder shared by ADD and SUB (SUB uses two's‑complement of B)
		wire [31:0] addsub_s;
		wire        addsub_cout;

		addsub32 U_ADDSUB32 (
			 .A(A),
			 .B(B),
			 .Sub(SUB),
			 .S(addsub_s),
			 .Cout(addsub_cout)
		);

    // Signed overflow detection for ADD/SUB (two's‑complement rules)
    wire add_overflow_int = ( ADD && (A[31] == B[31]) && (addsub_s[31] != A[31]) );
    wire sub_overflow_int = ( SUB && (A[31] != B[31]) && (addsub_s[31] != A[31]) );
    assign addsub_overflow = add_overflow_int | sub_overflow_int;
    reg [63:0] result;
	 
	 // 32‑bit by 32‑bit signed multiply
	 wire [63:0] mul_out;

		mult32x32_booth U_MUL (
			.A(A),
			.B(B),
			.P(mul_out)
		);
		
	 // Signed divide with quotient and remainder packed into 64 bits
	 wire [63:0] div_out;

	div32_nonrestoring U_DIV (
		.dividend(A),   // Typically: Y holds dividend
		.divisor(B),    // Bus holds divisor
		.result(div_out)
	);

    // NEG overflows only for the most negative 32‑bit value
    assign neg_overflow = NEG && (B == 32'h8000_0000);

    // MUL overflow when the 64‑bit product does not fit in a sign‑extended 32‑bit value
    wire mul_sign_bit = mul_out[31];
    wire [31:0] mul_hi_expected = {32{mul_sign_bit}};
    assign mul_overflow = MUL && (mul_out[63:32] != mul_hi_expected);

    assign div_by_zero = DIV && (B == 32'b0);

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
            result = {32'b0, shra_a};
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
