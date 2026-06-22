module fma_independent_modules #(
    parameter  int SRC1_WIDTH   = 64,
    parameter  int SRC2_WIDTH   = SRC1_WIDTH,
    parameter  int SRC3_WIDTH   = SRC1_WIDTH,
    parameter  int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH)
) (
    input  logic [SRC1_WIDTH-1:0]   srca,
    input  logic [SRC2_WIDTH-1:0]   srcb,
    input  logic [SRC3_WIDTH-1:0]   srcc,
    input  logic                    is_fma,
    input  logic                    is_signed,
    output logic [RESULT_WIDTH-1:0] result
);

    logic [RESULT_WIDTH-1:0] mul_result;
    logic [RESULT_WIDTH-1:0] srcc_ext;
    logic [RESULT_WIDTH-1:0] addend;

    assign srcc_ext = is_signed
        ? {{(RESULT_WIDTH-SRC3_WIDTH){srcc[SRC3_WIDTH-1]}}, srcc}
        : {{(RESULT_WIDTH-SRC3_WIDTH){1'b0}}, srcc};
    assign addend = is_fma ? srcc_ext : '0;

    booth_wallace_multiplier #(
        .SRC1_WIDTH(SRC1_WIDTH),
        .SRC2_WIDTH(SRC2_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH)
    ) multiplier (
        .srca(srca),
        .srcb(srcb),
        .is_signed(is_signed),
        .result(mul_result)
    );

    ripple_carry_adder #(
        .WIDTH(RESULT_WIDTH)
    ) final_add (
        .srca(mul_result),
        .srcb(addend),
        .cin(1'b0),
        .is_signed(is_signed),
        .result(result),
        .cout(),
        .zero_f(),
        .ov_f()
    );

endmodule