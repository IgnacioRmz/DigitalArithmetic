module array_multiplier #(
    parameter   int SRC1_WIDTH      = 32,
    parameter   int SRC2_WIDTH      = SRC1_WIDTH,
    localparam  int RESULT_WIDTH    = (SRC1_WIDTH + SRC2_WIDTH)
) (
    input  logic [SRC1_WIDTH-1:0]   srca,
    input  logic [SRC2_WIDTH-1:0]   srcb,
    input  logic                    is_signed,
    output logic [RESULT_WIDTH-1:0] result
);

    logic [SRC1_WIDTH-1:0]  srca_pos;
    logic [SRC2_WIDTH-1:0]  srcb_pos;
    logic [RESULT_WIDTH-1:0] unsigned_result;
    logic [RESULT_WIDTH-1:0] final_result;

    logic srca_neg_masked;
    logic srcb_neg_masked;
    logic result_is_negative;

    logic [RESULT_WIDTH-1:0] partial_products [SRC2_WIDTH-1:0];
    logic [RESULT_WIDTH-1:0] acc_sum [SRC2_WIDTH:0];

    // Determine sign of each input when is signed
    assign srca_neg_masked = is_signed & srca[SRC1_WIDTH-1];
    assign srcb_neg_masked = is_signed & srcb[SRC2_WIDTH-1];
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

  
    always_comb begin
        for (int i = 0; i < SRC2_WIDTH; i++) begin
            partial_products[i] = (srca_pos & {SRC1_WIDTH{srcb_pos[i]}}) << i;
        end
    end

    assign acc_sum[0] = '0;

    generate
        genvar i;
        for (i = 0; i < SRC2_WIDTH; i++) begin : sum_gen
            ripple_carry_adder #(
                .WIDTH(RESULT_WIDTH)
            ) sum_inst (
                .srca(acc_sum[i]),
                .srcb(partial_products[i]),
                .cin(1'b0),
                .is_signed(1'b0),
                .result(acc_sum[i+1]),
                .cout(),
                .zero_f(),
                .ov_f()
            );
        end
    endgenerate

    // Negate result if signs of operands differed
    twos_complement #(.WIDTH(RESULT_WIDTH)) tc_result (
        .value(acc_sum[SRC2_WIDTH]),
        .convert(result_is_negative),
        .result(final_result)
    );

    assign result = final_result;

endmodule