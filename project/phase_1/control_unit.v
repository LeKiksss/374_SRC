module control_unit (
    input  wire        Clock,
    input  wire        Reset,
    input  wire        Stop,
    input  wire [31:0] IR,
    input  wire        CON,

    output reg         Gra,
    output reg         Grb,
    output reg         Grc,
    output reg         Rin,
    output reg         Rout,
    output reg         BAout,
    output reg         PCin,
    output reg         IRin,
    output reg         Yin,
    output reg         MARin,
    output reg         HIin,
    output reg         LOin,
    output reg         Zin,
    output reg         MDRin,
    output reg         CONin,
    output reg         Out_Portin,
    output reg         R12in_force,
    output reg         IncPC,
    output reg         Read,
    output reg         Write,
    output reg         PCout,
    output reg         MDRout,
    output reg         HIout,
    output reg         LOout,
    output reg         Zhighout,
    output reg         Zlowout,
    output reg         In_Portout,
    output reg         Cout,
    output reg         AND,
    output reg         OR,
    output reg         NOT_op,
    output reg         NEG,
    output reg         SHR,
    output reg         SHRA,
    output reg         SHL,
    output reg         ROR,
    output reg         ROL,
    output reg         ADD,
    output reg         SUB,
    output reg         MUL,
    output reg         DIV,
    output reg         Run,
    output wire [4:0]  state_dbg
);

    localparam [4:0]
        OP_ADD   = 5'b00000,
        OP_SUB   = 5'b00001,
        OP_AND   = 5'b00010,
        OP_OR    = 5'b00011,
        OP_SHR   = 5'b00100,
        OP_SHRA  = 5'b00101,
        OP_SHL   = 5'b00110,
        OP_ROR   = 5'b00111,
        OP_ROL   = 5'b01000,
        OP_ADDI  = 5'b01001,
        OP_ANDI  = 5'b01010,
        OP_ORI   = 5'b01011,
        OP_DIV   = 5'b01100,
        OP_MUL   = 5'b01101,
        OP_NEG   = 5'b01110,
        OP_NOT   = 5'b01111,
        OP_LD    = 5'b10000,
        OP_LDI   = 5'b10001,
        OP_ST    = 5'b10010,
        OP_JAL   = 5'b10011,
        OP_JR    = 5'b10100,
        OP_BR    = 5'b10101,
        OP_IN    = 5'b10110,
        OP_OUT   = 5'b10111,
        OP_MFHI  = 5'b11000,
        OP_MFLO  = 5'b11001,
        OP_NOP   = 5'b11010,
        OP_HALT  = 5'b11011;

    localparam [4:0]
        STATE_T0   = 5'd0,
        STATE_T1   = 5'd1,
        STATE_T2   = 5'd2,
        STATE_T3   = 5'd3,
        STATE_T4   = 5'd4,
        STATE_T5   = 5'd5,
        STATE_T6   = 5'd6,
        STATE_T7   = 5'd7,
        STATE_HALT = 5'd31;

    reg [4:0] state_reg;
    reg [4:0] next_state;

    wire [4:0] opcode = IR[31:27];

    wire is_r_alu = (opcode == OP_ADD)  ||
                    (opcode == OP_SUB)  ||
                    (opcode == OP_AND)  ||
                    (opcode == OP_OR)   ||
                    (opcode == OP_SHR)  ||
                    (opcode == OP_SHRA) ||
                    (opcode == OP_SHL)  ||
                    (opcode == OP_ROR)  ||
                    (opcode == OP_ROL);

    wire is_imm_alu = (opcode == OP_ADDI) ||
                      (opcode == OP_ANDI) ||
                      (opcode == OP_ORI);

    wire is_unary = (opcode == OP_NEG) || (opcode == OP_NOT);
    wire is_load_store_addr = (opcode == OP_LD) || (opcode == OP_LDI) || (opcode == OP_ST);
    wire is_mul_div = (opcode == OP_MUL) || (opcode == OP_DIV);

    assign state_dbg = state_reg;

    always @(*) begin
        next_state = state_reg;

        case (state_reg)
            STATE_T0: next_state = STATE_T1;
            STATE_T1: next_state = STATE_T2;
            STATE_T2: next_state = STATE_T3;

            STATE_T3: begin
                if (is_r_alu || is_imm_alu || is_load_store_addr || is_mul_div ||
                    (opcode == OP_BR) || (opcode == OP_JAL)) begin
                    next_state = STATE_T4;
                end else begin
                    next_state = STATE_T0;
                end
            end

            STATE_T4: begin
                if (is_r_alu || is_imm_alu || (opcode == OP_LDI) || (opcode == OP_BR) ||
                    (opcode == OP_LD) || (opcode == OP_ST) || is_mul_div) begin
                    next_state = STATE_T5;
                end else begin
                    next_state = STATE_T0;
                end
            end

            STATE_T5: begin
                if (opcode == OP_LD || opcode == OP_ST) begin
                    next_state = STATE_T6;
                end else if (is_mul_div || (opcode == OP_BR)) begin
                    next_state = STATE_T6;
                end else begin
                    next_state = STATE_T0;
                end
            end

            STATE_T6: begin
                if (opcode == OP_LD || opcode == OP_ST) begin
                    next_state = STATE_T7;
                end else begin
                    next_state = STATE_T0;
                end
            end

            STATE_T7: next_state = STATE_T0;
            default:  next_state = STATE_HALT;
        endcase
    end

    always @(posedge Clock) begin
        if (Reset) begin
            state_reg <= STATE_T0;
            Run <= 1'b1;
        end else if (Stop) begin
            state_reg <= STATE_HALT;
            Run <= 1'b0;
        end else if (!Run) begin
            state_reg <= STATE_HALT;
            Run <= 1'b0;
        end else if ((state_reg == STATE_T3) && (opcode == OP_HALT)) begin
            state_reg <= STATE_HALT;
            Run <= 1'b0;
        end else begin
            state_reg <= next_state;
            Run <= 1'b1;
        end
    end

    always @(*) begin
        Gra = 1'b0;
        Grb = 1'b0;
        Grc = 1'b0;
        Rin = 1'b0;
        Rout = 1'b0;
        BAout = 1'b0;
        PCin = 1'b0;
        IRin = 1'b0;
        Yin = 1'b0;
        MARin = 1'b0;
        HIin = 1'b0;
        LOin = 1'b0;
        Zin = 1'b0;
        MDRin = 1'b0;
        CONin = 1'b0;
        Out_Portin = 1'b0;
        R12in_force = 1'b0;
        IncPC = 1'b0;
        Read = 1'b0;
        Write = 1'b0;
        PCout = 1'b0;
        MDRout = 1'b0;
        HIout = 1'b0;
        LOout = 1'b0;
        Zhighout = 1'b0;
        Zlowout = 1'b0;
        In_Portout = 1'b0;
        Cout = 1'b0;
        AND = 1'b0;
        OR = 1'b0;
        NOT_op = 1'b0;
        NEG = 1'b0;
        SHR = 1'b0;
        SHRA = 1'b0;
        SHL = 1'b0;
        ROR = 1'b0;
        ROL = 1'b0;
        ADD = 1'b0;
        SUB = 1'b0;
        MUL = 1'b0;
        DIV = 1'b0;

        if (Reset || Stop || !Run) begin
            // Hold all controls low while the processor is resetting or halted.
        end else begin
            case (state_reg)
                STATE_T0: begin
                    PCout = 1'b1;
                    MARin = 1'b1;
                    IncPC = 1'b1;
                    Zin = 1'b1;
                end

                STATE_T1: begin
                    Zlowout = 1'b1;
                    PCin = 1'b1;
                    Read = 1'b1;
                    MDRin = 1'b1;
                end

                STATE_T2: begin
                    MDRout = 1'b1;
                    IRin = 1'b1;
                end

                STATE_T3: begin
                    case (opcode)
                        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_SHR, OP_SHRA, OP_SHL, OP_ROR, OP_ROL,
                        OP_ADDI, OP_ANDI, OP_ORI: begin
                            Grb = 1'b1;
                            Rout = 1'b1;
                            Yin = 1'b1;
                        end

                        OP_NEG: begin
                            Grb = 1'b1;
                            Rout = 1'b1;
                            NEG = 1'b1;
                            Zin = 1'b1;
                        end

                        OP_NOT: begin
                            Grb = 1'b1;
                            Rout = 1'b1;
                            NOT_op = 1'b1;
                            Zin = 1'b1;
                        end

                        OP_LD, OP_LDI, OP_ST: begin
                            Grb = 1'b1;
                            BAout = 1'b1;
                            Yin = 1'b1;
                        end

                        OP_MUL, OP_DIV: begin
                            Gra = 1'b1;
                            Rout = 1'b1;
                            Yin = 1'b1;
                        end

                        OP_MFHI: begin
                            HIout = 1'b1;
                            Gra = 1'b1;
                            Rin = 1'b1;
                        end

                        OP_MFLO: begin
                            LOout = 1'b1;
                            Gra = 1'b1;
                            Rin = 1'b1;
                        end

                        OP_IN: begin
                            In_Portout = 1'b1;
                            Gra = 1'b1;
                            Rin = 1'b1;
                        end

                        OP_OUT: begin
                            Gra = 1'b1;
                            Rout = 1'b1;
                            Out_Portin = 1'b1;
                        end

                        OP_JR: begin
                            Gra = 1'b1;
                            Rout = 1'b1;
                            PCin = 1'b1;
                        end

                        OP_JAL: begin
                            PCout = 1'b1;
                            R12in_force = 1'b1;
                        end

                        OP_BR: begin
                            Gra = 1'b1;
                            Rout = 1'b1;
                            CONin = 1'b1;
                        end

                        default: begin
                        end
                    endcase
                end

                STATE_T4: begin
                    case (opcode)
                        OP_ADD: begin Grc = 1'b1; Rout = 1'b1; ADD = 1'b1; Zin = 1'b1; end
                        OP_SUB: begin Grc = 1'b1; Rout = 1'b1; SUB = 1'b1; Zin = 1'b1; end
                        OP_AND: begin Grc = 1'b1; Rout = 1'b1; AND = 1'b1; Zin = 1'b1; end
                        OP_OR:  begin Grc = 1'b1; Rout = 1'b1; OR  = 1'b1; Zin = 1'b1; end
                        OP_SHR: begin Grc = 1'b1; Rout = 1'b1; SHR = 1'b1; Zin = 1'b1; end
                        OP_SHRA: begin Grc = 1'b1; Rout = 1'b1; SHRA = 1'b1; Zin = 1'b1; end
                        OP_SHL: begin Grc = 1'b1; Rout = 1'b1; SHL = 1'b1; Zin = 1'b1; end
                        OP_ROR: begin Grc = 1'b1; Rout = 1'b1; ROR = 1'b1; Zin = 1'b1; end
                        OP_ROL: begin Grc = 1'b1; Rout = 1'b1; ROL = 1'b1; Zin = 1'b1; end

                        OP_ADDI: begin Cout = 1'b1; ADD = 1'b1; Zin = 1'b1; end
                        OP_ANDI: begin Cout = 1'b1; AND = 1'b1; Zin = 1'b1; end
                        OP_ORI:  begin Cout = 1'b1; OR  = 1'b1; Zin = 1'b1; end

                        OP_NEG, OP_NOT: begin
                            Zlowout = 1'b1;
                            Gra = 1'b1;
                            Rin = 1'b1;
                        end

                        OP_LD, OP_LDI, OP_ST: begin
                            Cout = 1'b1;
                            ADD = 1'b1;
                            Zin = 1'b1;
                        end

                        OP_MUL: begin
                            Grb = 1'b1;
                            Rout = 1'b1;
                            MUL = 1'b1;
                            Zin = 1'b1;
                        end

                        OP_DIV: begin
                            Grb = 1'b1;
                            Rout = 1'b1;
                            DIV = 1'b1;
                            Zin = 1'b1;
                        end

                        OP_JAL: begin
                            Gra = 1'b1;
                            Rout = 1'b1;
                            PCin = 1'b1;
                        end

                        OP_BR: begin
                            PCout = 1'b1;
                            Yin = 1'b1;
                        end

                        default: begin
                        end
                    endcase
                end

                STATE_T5: begin
                    case (opcode)
                        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_SHR, OP_SHRA, OP_SHL, OP_ROR, OP_ROL,
                        OP_ADDI, OP_ANDI, OP_ORI, OP_LDI: begin
                            Zlowout = 1'b1;
                            Gra = 1'b1;
                            Rin = 1'b1;
                        end

                        OP_LD, OP_ST: begin
                            Zlowout = 1'b1;
                            MARin = 1'b1;
                        end

                        OP_MUL, OP_DIV: begin
                            Zlowout = 1'b1;
                            LOin = 1'b1;
                        end

                        OP_BR: begin
                            Cout = 1'b1;
                            ADD = 1'b1;
                            Zin = 1'b1;
                        end

                        default: begin
                        end
                    endcase
                end

                STATE_T6: begin
                    case (opcode)
                        OP_LD: begin
                            Read = 1'b1;
                            MDRin = 1'b1;
                        end

                        OP_ST: begin
                            Gra = 1'b1;
                            Rout = 1'b1;
                            MDRin = 1'b1;
                        end

                        OP_MUL, OP_DIV: begin
                            Zhighout = 1'b1;
                            HIin = 1'b1;
                        end

                        OP_BR: begin
                            if (CON) begin
                                Zlowout = 1'b1;
                                PCin = 1'b1;
                            end
                        end

                        default: begin
                        end
                    endcase
                end

                STATE_T7: begin
                    case (opcode)
                        OP_LD: begin
                            MDRout = 1'b1;
                            Gra = 1'b1;
                            Rin = 1'b1;
                        end

                        OP_ST: begin
                            Write = 1'b1;
                        end

                        default: begin
                        end
                    endcase
                end

                default: begin
                end
            endcase
        end
    end

endmodule
