module ram512x32 #(parameter INIT_FILE = "phase2_memory_init.hex") (
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

        $readmemh(INIT_FILE, memory);

        // Re-assert the required preload locations even if the init file is edited.
        memory[9'h065] = 32'h0000_0084;
        memory[9'h0C9] = 32'h0000_002B;
        memory[9'h01F] = 32'h0000_00D4;
        memory[9'h082] = 32'h0000_00A7;
    end

    assign data = (Read && !Write) ? memory[address] : 32'bz;

    always @(posedge Clock) begin
        if (Write) begin
            memory[address] <= data;
        end
    end

endmodule
