module addsub32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        Sub,   // 0 = add, 1 = sub
    output wire [31:0] S,
    output wire        Cout
);
    wire [31:0] Bx;

    // If Sub=1 -> Bx = ~B, else Bx = B
    assign Bx = B ^ {32{Sub}};

    adder32 U_ADD (
        .A(A),
        .B(Bx),
        .Cin(Sub),
        .S(S),
        .Cout(Cout)
    );
endmodule
