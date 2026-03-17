// Signed 32‑bit divider. Result packs remainder in the high word and
// quotient in the low word: {remainder[31:0], quotient[31:0]}.
module div32_nonrestoring (
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output reg  [63:0] result
);
    integer i;

    // Unsigned remainder and quotient used while working with magnitudes
    reg [32:0] rem;
    reg [31:0] quot;
    reg [32:0] div_ext;

    // Signed versions used when restoring the correct signs at the end
    reg signed [31:0] quot_signed;
    reg signed [31:0] rem_signed;

    // Signed views of the original inputs
    wire signed [31:0] dividend_s = dividend;
    wire signed [31:0] divisor_s  = divisor;

    // Sign bits for inputs and for the final quotient
    wire sign_dividend = dividend_s[31];
    wire sign_divisor  = divisor_s[31];
    wire sign_quotient = sign_dividend ^ sign_divisor;

    // Absolute values of inputs in 32‑bit two's‑complement
    wire [31:0] dividend_abs = sign_dividend ? (~dividend + 32'd1) : dividend;
    wire [31:0] divisor_abs  = sign_divisor  ? (~divisor  + 32'd1) : divisor;

    always @(*) begin
        if (divisor == 32'b0) begin
            // Use all ones as a sentinel quotient and return the original
            // dividend as the remainder.
            result = {dividend, 32'hFFFF_FFFF};
        end else begin
            rem     = 33'd0;
            quot    = dividend_abs;
            div_ext = {1'b0, divisor_abs};

            for (i = 0; i < 32; i = i + 1) begin
                {rem, quot} = {rem, quot} << 1;

                if (rem >= div_ext) begin
                    rem      = rem - div_ext;
                    quot[0]  = 1'b1;
                end else begin
                    // rem unchanged, quotient bit already 0
                end
            end

            // Apply signs: the quotient sign follows sign_dividend XOR sign_divisor
            // and the remainder keeps the sign of the dividend (truncate‑toward‑zero).
            if (sign_quotient)
                quot_signed = -$signed(quot);
            else
                quot_signed = $signed(quot);

            if (sign_dividend)
                rem_signed = -$signed(rem[31:0]);
            else
                rem_signed = $signed(rem[31:0]);

            result = {rem_signed[31:0], quot_signed[31:0]};
        end
    end
endmodule
