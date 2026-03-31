module ram512x32 #(parameter INIT_FILE = "") (
    input  wire        Clock,
    input  wire        Read,
    input  wire        Write,
    input  wire [8:0]  address,
    inout  wire [31:0] data
);

    reg [31:0] memory [0:511];
    integer i;

    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            memory[i] = 32'h0000_0000;
        end

        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    assign data = (Read && !Write) ? memory[address] : 32'bz;

    always @(posedge Clock) begin
        if (Write) begin
            memory[address] <= data;
        end
    end

endmodule
