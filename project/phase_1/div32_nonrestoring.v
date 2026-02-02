module div32_nonrestoring (
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output reg  [63:0] result   // {remainder[31:0], quotient[31:0]}
);
    integer i;

    // We use a signed remainder so we can test "negative" during the algorithm.
    // 33 bits to avoid overflow when subtracting divisor.
    reg signed [32:0] rem;
    reg        [31:0] quot;

    // divisor extended to 33 bits (unsigned)
    reg signed [32:0] div_ext;

    always @(*) begin
        // Divide-by-zero handling (pick something consistent)
        if (divisor == 32'b0) begin
            // Common choices: quotient=all1s, remainder=dividend
            result = {dividend, 32'hFFFF_FFFF};
        end else begin
            rem     = 33'sd0;
            quot    = dividend;
            div_ext = {1'b0, divisor};

            // 32 iterations
            for (i = 0; i < 32; i = i + 1) begin
                // Shift left {rem,quot} by 1:
                // rem takes next MSB of quot, quot shifts left
                rem  = {rem[31:0], quot[31]};
                quot = {quot[30:0], 1'b0};

                // Non-restoring step:
                if (rem >= 0)
                    rem = rem - div_ext;
                else
                    rem = rem + div_ext;

                // Set new quotient bit based on sign of remainder
                if (rem >= 0)
                    quot[0] = 1'b1;
                else
                    quot[0] = 1'b0;
            end

            // Final restore if remainder is negative
            if (rem < 0)
                rem = rem + div_ext;

            result = {rem[31:0], quot};
        end
    end
endmodule
