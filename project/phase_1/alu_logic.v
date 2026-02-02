module alu_logic (
    input  wire        AND,
    input  wire        OR,
    input  wire        NOT_op,
    input  wire        NEG,

    input  wire [31:0] A,   // from Y
    input  wire [31:0] B,   // from bus

    output wire [63:0] out  // to Z input (low 32 bits used)
);

    // NOT and NEG typically apply to B (bus operand) in this datapath style
    wire [31:0] not_b = ~B;

    // NEG = two's complement of B = (~B) + 1, using inc32 (no '+')
    wire [31:0] neg_b;
    inc32 u_inc32 (
        .in(not_b),
        .out(neg_b)
    );

    reg [63:0] result;

    always @(*) begin
        result = 64'b0;

        if (AND) begin
            result = {32'b0, (A & B)};
        end else if (OR) begin
            result = {32'b0, (A | B)};
        end else if (NOT_op) begin
            result = {32'b0, not_b};
        end else if (NEG) begin
            result = {32'b0, neg_b};
        end
    end

    assign out = result;

endmodule
