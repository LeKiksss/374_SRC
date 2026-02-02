module alu_logic (
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
    // Use {A,A} and shift, then take the correct 32-bit slice
    wire [63:0] AA = {A, A};
    wire [31:0] rol_a = (AA << shamt)[63:32];
    wire [31:0] ror_a = (AA >> shamt)[31:0];

    reg [63:0] result;

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
        end
    end

    assign out = result;

endmodule
