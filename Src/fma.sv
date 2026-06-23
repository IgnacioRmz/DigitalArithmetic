module fma #(
    parameter  int SRC1_WIDTH   = 64,
    parameter  int SRC2_WIDTH   = SRC1_WIDTH,
    parameter  int SRC3_WIDTH   = SRC1_WIDTH,
    parameter int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH)
) (
    input  logic [SRC1_WIDTH-1:0]   srca,
    input  logic [SRC2_WIDTH-1:0]   srcb,
    input  logic [SRC3_WIDTH-1:0]   srcc,
    input  logic                    is_fma,
    input  logic                    is_signed,
    output logic [RESULT_WIDTH-1:0] result
);

    localparam int PP_COUNT = (SRC2_WIDTH / 2) + 1;

    logic [RESULT_WIDTH-1:0] partial_products [PP_COUNT-1:0];
    logic [RESULT_WIDTH-1:0] all_pps          [PP_COUNT:0];
    logic [RESULT_WIDTH-1:0] srcc_ext;
    logic [RESULT_WIDTH-1:0] wallace_sum;
    logic [RESULT_WIDTH-1:0] wallace_carry;

    assign srcc_ext = is_signed
        ? {{(RESULT_WIDTH-SRC3_WIDTH){srcc[SRC3_WIDTH-1]}}, srcc}
        : {{(RESULT_WIDTH-SRC3_WIDTH){1'b0}}, srcc};

    booth_radix4_pp_gen #(
        .SRC1_WIDTH(SRC1_WIDTH),
        .SRC2_WIDTH(SRC2_WIDTH)
    ) booth_pp_gen (
        .multiplicand(srca),
        .multiplier(srcb),
        .is_signed(is_signed),
        .partial_products(partial_products)
    );

    // Build PP array: Booth partial products + srcc as final entry (gated by is_fma)
    always_comb begin
        for (int i = 0; i < PP_COUNT; i++) all_pps[i] = partial_products[i];
        all_pps[PP_COUNT] = is_fma ? srcc_ext : '0;
    end

    wallace_reducer #(
        .RESULT_WIDTH(RESULT_WIDTH),
        .PP_COUNT(PP_COUNT + 1)
    ) wallace_reduce (
        .partial_products(all_pps),
        .sum_result(wallace_sum),
        .carry_result(wallace_carry)
    );

    ripple_carry_adder #(
        .WIDTH(RESULT_WIDTH)
    ) final_add (
        .srca(wallace_sum),
        .srcb(wallace_carry),
        .cin(1'b0),
        .is_signed(is_signed),
        .result(result),
        .cout(),
        .zero_f(),
        .ov_f()
    );

endmodule