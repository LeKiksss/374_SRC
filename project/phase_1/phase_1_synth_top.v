// DE0-CV top-level wrapper for the integrated Mini SRC CPU.
// Keep the legacy entity name so the Quartus project does not need to change.
module phase_1_synth_top (
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    input  wire [7:0]  SW,
    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5
);

    // Checked-in default: use a clearly visible hardware demo clock.
    // Set USE_DEMO_CLOCK to 0 for raw CLOCK_50 max-frequency experiments.
    localparam USE_DEMO_CLOCK = 1;
    localparam integer DEMO_DIVIDE = 64;

    wire        cpu_clock;
    wire        cpu_run;
    wire [31:0] out_port;

    board_clock_helper #(
        .USE_DEMO_CLOCK(USE_DEMO_CLOCK),
        .DEMO_DIVIDE(DEMO_DIVIDE)
    ) U_CLOCK (
        .clock_in(CLOCK_50),
        .clock_out(cpu_clock)
    );

    mini_src_cpu #(
        .RAM_INIT_FILE("phase4_memory_init.hex")
    ) U_CPU (
        .Clock(cpu_clock),
        .Reset(~KEY[0]),
        .Stop(~KEY[1]),
        .port_in({24'b0, SW}),
        .Run(cpu_run),
        .state_dbg(),
        .BusMuxOut(),
        .PC(),
        .IR(),
        .Y(),
        .MAR(),
        .MDR(),
        .HI(),
        .LO(),
        .Z(),
        .Zhigh(),
        .Zlow(),
        .In_Port(),
        .Out_Port(out_port),
        .MemoryData(),
        .CON(),
        .addsub_overflow(),
        .neg_overflow(),
        .mul_overflow(),
        .div_by_zero(),
        .inc_overflow(),
        .R0(),
        .R1(),
        .R2(),
        .R3(),
        .R4(),
        .R5(),
        .R6(),
        .R7(),
        .R8(),
        .R9(),
        .R10(),
        .R11(),
        .R12(),
        .R13(),
        .R14(),
        .R15()
    );

    hex7seg_active_low U_HEX0 (
        .nibble(out_port[3:0]),
        .segments(HEX0)
    );

    hex7seg_active_low U_HEX1 (
        .nibble(out_port[7:4]),
        .segments(HEX1)
    );

    assign LEDR = {4'b0000, cpu_run, 5'b00000};

    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;

endmodule
