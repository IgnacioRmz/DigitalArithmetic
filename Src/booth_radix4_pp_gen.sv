module booth_radix4_pp_gen #(
    parameter int SRC1_WIDTH    = 32,
    parameter int SRC2_WIDTH    = SRC1_WIDTH
) (
    input  logic [SRC1_WIDTH-1:0]   multiplicand,
    input  logic [SRC2_WIDTH-1:0]   multiplier,
    output logic [RESULT_WIDTH-1:0] partial_products [PP_COUNT-1:0]
);

    localparam int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH);
    localparam int PP_COUNT     = ((SRC2_WIDTH / 2) + 1);

    logic [RESULT_WIDTH:0] multiplicand_ext;
    logic [RESULT_WIDTH:0] a_pos;
    logic [RESULT_WIDTH:0] a_x2_pos;
    logic [RESULT_WIDTH:0] a_neg;
    logic [RESULT_WIDTH:0] a_x2_neg;
    logic [SRC2_WIDTH+2:0] multiplier_pad;
    logic [2:0]           booth_bits;
    logic [RESULT_WIDTH:0] row_value;

    twos_complement #(
        .WIDTH(RESULT_WIDTH+1)
    ) tc_a_neg (
        .value(a_pos),
        .convert(1'b1),
        .result(a_neg)
    );

    always_comb begin
        multiplier_pad   = {2'b00, multiplier, 1'b0};
        multiplicand_ext = {{(RESULT_WIDTH+1-SRC1_WIDTH){1'b0}}, multiplicand};
        a_pos            = multiplicand_ext;
        a_x2_pos         = multiplicand_ext << 1;
        a_x2_neg         = a_neg << 1;

        for (int i = 0; i < PP_COUNT; i++) begin
            logic [RESULT_WIDTH:0] shifted_row;

            booth_bits = multiplier_pad[(2*i)+2 -: 3];

            unique case (booth_bits)
                3'b000, 3'b111: row_value = '0;
                3'b001, 3'b010: row_value = a_pos;
                3'b011:         row_value = a_x2_pos;
                3'b100:         row_value = a_x2_neg;
                3'b101, 3'b110: row_value = a_neg;
                default:        row_value = '0;
            endcase

            shifted_row = row_value << (2*i);
            partial_products[i] = shifted_row[RESULT_WIDTH-1:0];
        end
    end

endmodule
