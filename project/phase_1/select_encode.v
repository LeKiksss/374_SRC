module select_encode (
    input  wire [31:0] IR,
    input  wire        Gra,
    input  wire        Grb,
    input  wire        Grc,
    input  wire        Rin,
    input  wire        Rout,
    input  wire        BAout,
    output wire [15:0] GPRin,
    output wire [15:0] GPRout
);

    localparam RA_MSB = 26;
    localparam RA_LSB = 23;
    localparam RB_MSB = 22;
    localparam RB_LSB = 19;
    localparam RC_MSB = 18;
    localparam RC_LSB = 15;

    wire [3:0] selected_register =
        ({4{Gra}} & IR[RA_MSB:RA_LSB]) |
        ({4{Grb}} & IR[RB_MSB:RB_LSB]) |
        ({4{Grc}} & IR[RC_MSB:RC_LSB]);

    wire       register_selected = Gra | Grb | Grc;
    wire [15:0] decoded_register = register_selected ? (16'h0001 << selected_register) : 16'h0000;

    assign GPRin  = Rin ? decoded_register : 16'h0000;
    assign GPRout = (Rout | BAout) ? decoded_register : 16'h0000;

endmodule
