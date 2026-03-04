module MDR (
    input  wire        Clock,
    input  wire        Clear,
    input  wire        MDRin,
    input  wire        Read,
    input  wire [31:0] BusMuxOut,
    input  wire [31:0] Mdatain,
    output reg  [31:0] MDRout
);

    // Select either memory data (when Read=1) or the system bus
    wire [31:0] MDMuxOut;
    assign MDMuxOut = (Read) ? Mdatain : BusMuxOut;

    always @(posedge Clock) begin
        if (Clear) begin
            MDRout <= 32'b0;
        end else if (MDRin) begin
            MDRout <= MDMuxOut;
        end
    end

endmodule
