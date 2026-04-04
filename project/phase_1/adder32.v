module adder32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        Cin,
    output wire [31:0] S,
    output wire        Cout
);
    wire [31:0] C; // internal carry chain

    // Least significant bit uses the external carry‑in
    assign S[0] = A[0] ^ B[0] ^ Cin;
    assign C[0] = (A[0] & B[0]) | (A[0] & Cin) | (B[0] & Cin);

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : FA
            assign S[i] = A[i] ^ B[i] ^ C[i-1];
            assign C[i] = (A[i] & B[i]) | (A[i] & C[i-1]) | (B[i] & C[i-1]);
        end
    endgenerate

    assign Cout = C[31];
endmodule
