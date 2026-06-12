module multiplier#(
    parameter int SRC1_WIDTH    = 32,
    parameter int SRC2_WIDTH    = SRC1_WIDTH,
    localparam int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH)
) (
    input  logic [SRC1_WIDTH-1:0]   srca,
    input  logic [SRC2_WIDTH-1:0]   srcb,
    input  logic                    is_signed,
    output logic [RESULT_WIDTH-1:0] result
);

    localparam  int PP_COUNT        = ((SRC2_WIDTH / 2) + 1);

    logic [SRC1_WIDTH-1:0]   srca_pos;
    logic [SRC2_WIDTH-1:0]   srcb_pos;
    logic                    srca_neg_masked;
    logic                    srcb_neg_masked;
    logic                    result_is_negative;
    logic [RESULT_WIDTH-1:0] unsigned_result;

    logic [RESULT_WIDTH-1:0] partial_products [PP_COUNT-1:0];

    assign srca_neg_masked    = is_signed & srca[SRC1_WIDTH-1];
    assign srcb_neg_masked    = is_signed & srcb[SRC2_WIDTH-1];
    assign result_is_negative = srca_neg_masked ^ srcb_neg_masked;

    twos_complement #(.WIDTH(SRC1_WIDTH)) tc_srca (
        .value(srca),
        .convert(srca_neg_masked),
        .result(srca_pos)
    );

    twos_complement #(.WIDTH(SRC2_WIDTH)) tc_srcb (
        .value(srcb),
        .convert(srcb_neg_masked),
        .result(srcb_pos)
    );

    booth_radix4_pp_gen #(
        .SRC1_WIDTH(SRC1_WIDTH),
        .SRC2_WIDTH(SRC2_WIDTH)
    ) booth_pp_gen (
        .multiplicand(srca_pos),
        .multiplier(srcb_pos),
        .partial_products(partial_products)
    );

    wallace_reducer #(
        .RESULT_WIDTH(RESULT_WIDTH),
        .PP_COUNT(PP_COUNT)
    ) wallace_reduce (
        .partial_products(partial_products),
        .result(unsigned_result)
    );

    twos_complement #(.WIDTH(RESULT_WIDTH)) tc_result (
        .value(unsigned_result),
        .convert(result_is_negative),
        .result(result)
    );

endmodule