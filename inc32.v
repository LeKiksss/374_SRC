module inc32 (
    input  wire [31:0] in,
    output wire [31:0] out
);
    wire [31:0] carry;

    // Add 1: out = in + 1
    assign out[0]  = ~in[0];
    assign carry[0] = in[0];

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : INC
            assign out[i]  = in[i] ^ carry[i-1];
            assign carry[i] = in[i] & carry[i-1];
        end
    endgenerate
endmodule
