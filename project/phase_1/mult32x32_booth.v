module mult32x32_booth (
    input  wire [31:0] A,        // multiplicand
    input  wire [31:0] B,        // multiplier
    output reg  [63:0] P         // product
);
    integer i;

    // Treat as signed for two's complement multiplication
    reg  signed [63:0] acc;
    reg  signed [63:0] mcand;        // sign-extended A
    reg  signed [63:0] pp;           // partial product (shifted)
    reg  [33:0]        extB;         // B with extra bits for Booth: {B[31], B, 0}

    reg  signed [63:0] m1;           // +A
    reg  signed [63:0] m2;           // +2A

    always @(*) begin
        // Sign extend A to 64-bit
        mcand = {{32{A[31]}}, A};
        m1    = mcand;
        m2    = mcand <<< 1;

        // Extend multiplier:
        // extB[0] = 0 (implicit q[-1])
        // extB[32:1] = B[31:0]
        // extB[33] = B[31] (extra sign bit for safe top group)
        extB  = {B[31], B, 1'b0};

        acc = 64'sd0;

        // 32-bit multiplier -> 16 radix-4 groups (2 bits per group)
        for (i = 0; i < 16; i = i + 1) begin
            // Booth code uses 3 bits: {q[2i+1], q[2i], q[2i-1]}
            case ({extB[2*i+2], extB[2*i+1], extB[2*i]})
                3'b000,
                3'b111: pp = 64'sd0;                 // 0
                3'b001,
                3'b010: pp =  m1;                    // +1 * A
                3'b011: pp =  m2;                    // +2 * A
                3'b100: pp = -m2;                    // -2 * A
                3'b101,
                3'b110: pp = -m1;                    // -1 * A
                default: pp = 64'sd0;
            endcase

            // Shift partial product by 2*i and accumulate
            acc = acc + (pp <<< (2*i));
        end

        P = acc[63:0];
    end

endmodule
