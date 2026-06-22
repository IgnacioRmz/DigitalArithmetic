module booth_wallace_multiplier #(
    parameter   int SRC1_WIDTH      = 32,
    parameter   int SRC2_WIDTH      = SRC1_WIDTH,
    parameter   int RESULT_WIDTH    = (SRC1_WIDTH + SRC2_WIDTH),
    parameter   int PP_COUNT        = ((SRC2_WIDTH / 2) + 1)
) (
    input  logic [SRC1_WIDTH-1:0]   srca,
    input  logic [SRC2_WIDTH-1:0]   srcb,
    input  logic                    is_signed,
    output logic [RESULT_WIDTH-1:0] result
);

    logic [RESULT_WIDTH-1:0] partial_products [PP_COUNT-1:0];
    logic [RESULT_WIDTH-1:0] wallace_sum;
    logic [RESULT_WIDTH-1:0] wallace_carry;

    booth_radix4_pp_gen #(
        .SRC1_WIDTH(SRC1_WIDTH),
        .SRC2_WIDTH(SRC2_WIDTH)
    ) booth_pp_gen (
        .multiplicand(srca),
        .multiplier(srcb),
        .is_signed(is_signed),
        .partial_products(partial_products)
    );

    wallace_reducer #(
        .RESULT_WIDTH(RESULT_WIDTH),
        .PP_COUNT(PP_COUNT)
    ) wallace_reduce (
        .partial_products(partial_products),
        .sum_result(wallace_sum),
        .carry_result(wallace_carry)
    );

    ripple_carry_adder #(
        .WIDTH(RESULT_WIDTH)
    ) final_add (
        .srca(wallace_sum),
        .srcb(wallace_carry),
        .cin(1'b0),
        .is_signed(1'b0),
        .result(result),
        .cout(),
        .zero_f(),
        .ov_f()
    );

endmodule