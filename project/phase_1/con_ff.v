module con_ff (
    input  wire        Clock,
    input  wire        Clear,
    input  wire        CONin,
    input  wire [31:0] IR,
    input  wire [31:0] BUS,
    output reg         CON
);

    wire [1:0] branch_condition = IR[20:19];
    reg        condition_met;

    always @(*) begin
        case (branch_condition)
            2'b00: condition_met = (BUS == 32'h0000_0000);
            2'b01: condition_met = (BUS != 32'h0000_0000);
            2'b10: condition_met = (BUS[31] == 1'b0) && (BUS != 32'h0000_0000);
            2'b11: condition_met = (BUS[31] == 1'b1);
            default: condition_met = 1'b0;
        endcase
    end

    always @(posedge Clock) begin
        if (Clear) begin
            CON <= 1'b0;
        end else if (CONin) begin
            CON <= condition_met;
        end
    end

endmodule
