module board_clock_helper #(
    parameter USE_DEMO_CLOCK = 1,
    parameter integer DEMO_DIVIDE = 64
) (
    input  wire clock_in,
    output wire clock_out
);

    generate
        if (USE_DEMO_CLOCK) begin : G_DEMO_CLOCK
            localparam integer HALF_DIVIDE = (DEMO_DIVIDE < 2) ? 1 : (DEMO_DIVIDE / 2);

            reg [31:0] div_count;
            reg        demo_clock;

            initial begin
                div_count = 32'b0;
                demo_clock = 1'b0;
            end

            always @(posedge clock_in) begin
                if (div_count == (HALF_DIVIDE - 1)) begin
                    div_count <= 32'b0;
                    demo_clock <= ~demo_clock;
                end else begin
                    div_count <= div_count + 32'd1;
                end
            end

            assign clock_out = demo_clock;
        end else begin : G_RAW_CLOCK
            assign clock_out = clock_in;
        end
    endgenerate

endmodule
