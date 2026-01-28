module MDR (
    input  wire        Clock,
    input  wire        Clear,
    input  wire        MDRin,
    input  wire        Read,
    input  wire [31:0] BusMuxOut,
    input  wire [31:0] Mdatain,
    output reg  [31:0] MDRout
);

    wire [31:0] MDMuxOut;

    // Select input source:
    // Read=1  -> take Mdatain (memory data)
    // Read=0  -> take BusMuxOut (bus data)
    assign MDMuxOut = (Read) ? Mdatain : BusMuxOut;

    always @(posedge Clock) begin
        if (Clear) begin
            MDRout <= 32'b0;
        end else if (MDRin) begin
            MDRout <= MDMuxOut;
        end
    end

endmodule
