// Signed 32‑bit by 32‑bit multiplier using radix‑4 Booth encoding.
module mult32x32_booth (
    input  wire [31:0] A,        // multiplicand
    input  wire [31:0] B,        // multiplier
    output reg  [63:0] P         // full 64‑bit product
);
    integer i;

    // Accumulate a signed 64‑bit result
    reg  signed [63:0] acc;
    reg  signed [63:0] mcand;        // sign‑extended A
    reg  signed [63:0] pp;           // current partial product
    reg  [33:0]        extB;         // B with guard bits for Booth: {B[31], B, 0}

    reg  signed [63:0] m1;           // +A
    reg  signed [63:0] m2;           // +2A

    always @(*) begin
        // Sign‑extend A to 64 bits and precompute +A and +2A
        mcand = {{32{A[31]}}, A};
        m1    = mcand;
        m2    = mcand <<< 1;

        // Extend B with one trailing and one leading bit for Booth coding
        extB  = {B[31], B, 1'b0};

        acc = 64'sd0;

        // 32‑bit multiplier is processed as 16 radix‑4 groups (2 bits each)
        for (i = 0; i < 16; i = i + 1) begin
            // Booth code uses three bits: {q[2i+1], q[2i], q[2i-1]}
            case ({extB[2*i+2], extB[2*i+1], extB[2*i]})
                3'b000,
                3'b111: pp = 64'sd0; //  0 * A
                3'b001,
                3'b010: pp =  m1;    // +1 * A
                3'b011: pp =  m2;    // +2 * A
                3'b100: pp = -m2;    // -2 * A
                3'b101,
                3'b110: pp = -m1;    // -1 * A
                default: pp = 64'sd0;
            endcase

            // Shift partial product by 2*i and accumulate
            acc = acc + (pp <<< (2*i));
        end

        P = acc[63:0];
    end

endmodule
