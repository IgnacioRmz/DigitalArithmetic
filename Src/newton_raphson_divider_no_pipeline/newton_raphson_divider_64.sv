module divider#(
  parameter int WIDTH = 64
) (
    input  logic [63:0] srca,
    input  logic [63:0] srcb,
    input  logic        is_signed,
    output logic [63:0] result,
    output logic [63:0] rem,
    output logic        div_zero_f
);

    logic [63:0] abs_srca;
    logic [63:0] abs_srcb;
    logic [6:0]  lzc_out;
    logic [5:0]  shift_amount;
    logic [63:0] shifted_abs_srcb;

    logic [4:0]  x0_lut;
    logic [63:0] x0_seed;
    logic [63:0] x1_out;
    logic [63:0] x2_out;
    logic [63:0] x3_out;
    logic [63:0] x4_out;
    logic [63:0] one_over_b;
    logic [127:0] one_over_b_wide;
    logic [6:0]  denorm_shift_amount;

    logic [127:0] res_mult;
    logic [63:0]  q_est;
    logic [63:0]  q_abs;
    logic [63:0]  q_abs_corr;
    logic [63:0]  rem_abs;
    logic [63:0]  rem_abs_corr;

    logic [127:0] q_est_times_b;
    logic [127:0] q_abs_times_b;
    logic [127:0] abs_srca_ext;

    logic         srca_neg;
    logic         srcb_neg;
    logic         quotient_neg;
    logic [63:0]  result_signed;
    logic [63:0]  rem_signed;

    assign shift_amount = lzc_out[5:0];
    assign x0_seed = {x0_lut, 59'd0};

    assign srca_neg = is_signed & srca[63];
    assign srcb_neg = is_signed & srcb[63];
    assign quotient_neg = srca_neg ^ srcb_neg;

    assign abs_srca_ext = {64'd0, abs_srca};

    absolute #(
        .WIDTH(64)
    ) absolute_srca_inst (
        .in(srca),
        .out(abs_srca)
    );

    absolute #(
        .WIDTH(64)
    ) absolute_srcb_inst (
        .in(srcb),
        .out(abs_srcb)
    );

    lzc #(
        .WIDTH(64)
    ) lzc_abs_srcb (
        .in(abs_srcb),
        .out(lzc_out)
    );

    shifter #(
        .WIDTH(64)
    ) shifter_norm_divisor (
        .in(abs_srcb),
        .shift_amount(shift_amount),
        .direction(1'b0),
        .out(shifted_abs_srcb)
    );

    nr_lut nr_lut_inst (
        .in_val(shifted_abs_srcb[63:60]),
        .x0_out(x0_lut)
    );

    newton_raphson_module newton_raphson_iter1 (
        .Xo(x0_seed),
        .D(shifted_abs_srcb),
        .Xn(x1_out)
    );

    newton_raphson_module newton_raphson_iter2 (
        .Xo(x1_out),
        .D(shifted_abs_srcb),
        .Xn(x2_out)
    );

    newton_raphson_module newton_raphson_iter3 (
        .Xo(x2_out),
        .D(shifted_abs_srcb),
        .Xn(x3_out)
    );

    newton_raphson_module newton_raphson_iter4 (
        .Xo(x3_out),
        .D(shifted_abs_srcb),
        .Xn(x4_out)
    );

    booth_wallace_multiplier #(
        .SRC1_WIDTH(64),
        .SRC2_WIDTH(64)
    ) mult_quotient (
        .srca(abs_srca),
        .srcb(x4_out),
        .is_signed(1'b0),
        .result(res_mult)
    );

    assign denorm_shift_amount = 7'd126 - {1'b0, shift_amount};

    shifter #(
        .WIDTH(128)
    ) shifter_denorm_recip (
        .in(res_mult),
        .shift_amount(denorm_shift_amount),
        .direction(1'b1),
        .out(one_over_b_wide)
    );

    assign one_over_b = one_over_b_wide[63:0];

    assign q_abs = one_over_b;
    assign rem_abs = abs_srca - (q_abs * abs_srcb);


    always_comb begin
        q_abs_corr = q_abs;
        rem_abs_corr = rem_abs;

        // Final correction: if the remainder is still at least one divisor,
        // increment quotient and reduce remainder once.
        if ((abs_srcb != 64'd0) && (rem_abs >= abs_srcb) && (q_abs != 64'hFFFF_FFFF_FFFF_FFFF)) begin
            q_abs_corr = q_abs + 64'd1;
            rem_abs_corr = rem_abs - abs_srcb;
        end
    end

    assign result_signed = quotient_neg ? (~q_abs_corr + 64'd1) : q_abs_corr;
    assign rem_signed = srca_neg ? (~rem_abs_corr + 64'd1) : rem_abs_corr;

    always_comb begin
        div_zero_f = (srcb == 64'd0);

        if (div_zero_f) begin
            result = 64'hFFFF_FFFF_FFFF_FFFF;
            rem = srca;
        end else begin
            result = result_signed;
            rem = rem_signed;
        end
    end

endmodule
