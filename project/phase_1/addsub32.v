module addsub32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        Sub,   // 0: perform A + B, 1: perform A − B
    output wire [31:0] S,
    output wire        Cout
);
    wire [31:0] Bx;

    // When Sub is high, invert B so the adder computes A + (~B) + 1 = A − B
    assign Bx = B ^ {32{Sub}};

    adder32 U_ADD (
        .A(A),
        .B(Bx),
        .Cin(Sub),
        .S(S),
        .Cout(Cout)
    );
endmodule
