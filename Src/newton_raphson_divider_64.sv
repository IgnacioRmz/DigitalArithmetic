module divider#(
  parameter int WIDTH = 64 //Just for compatibility with the testbench
) (
    input  logic        clk,
    input  logic        rst,
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
    logic [63:0] x1_next;
    logic [63:0] x2_next;
    logic [63:0] x3_next;
    logic [63:0] x4_next;
    logic [63:0] x1_out;
    logic [63:0] x2_out;
    logic [63:0] x3_out;
    logic [63:0] x4_out;
    logic [63:0] x5_out;
    logic [63:0] x6_out;
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

    logic [63:0]  abs_srca_s1;
    logic [63:0]  abs_srca_s2;
    logic [63:0]  abs_srca_s3;
    logic [63:0]  abs_srca_s4;
    logic [63:0]  abs_srca_s5;
    logic [63:0]  abs_srcb_s1;
    logic [63:0]  abs_srcb_s2;
    logic [63:0]  abs_srcb_s3;
    logic [63:0]  abs_srcb_s4;
    logic [63:0]  abs_srcb_s5;
    logic [63:0]  srca_s1;
    logic [63:0]  srca_s2;
    logic [63:0]  srca_s3;
    logic [63:0]  srca_s4;
    logic [63:0]  srca_s5;
    logic [63:0]  shifted_abs_srcb_s1;
    logic [63:0]  shifted_abs_srcb_s2;
    logic [63:0]  shifted_abs_srcb_s3;
    logic [63:0]  shifted_abs_srcb_s4;
    logic [63:0]  shifted_abs_srcb_s5;
    logic [5:0]   shift_amount_s1;
    logic [5:0]   shift_amount_s2;
    logic [5:0]   shift_amount_s3;
    logic [5:0]   shift_amount_s4;
    logic [5:0]   shift_amount_s5;
    logic         srca_neg_s1;
    logic         srca_neg_s2;
    logic         srca_neg_s3;
    logic         srca_neg_s4;
    logic         srca_neg_s5;
    logic         srcb_neg_s1;
    logic         srcb_neg_s2;
    logic         srcb_neg_s3;
    logic         srcb_neg_s4;
    logic         srcb_neg_s5;
    logic         quotient_neg_s1;
    logic         quotient_neg_s2;
    logic         quotient_neg_s3;
    logic         quotient_neg_s4;
    logic         quotient_neg_s5;
    logic         div_zero_s1;
    logic         div_zero_s2;
    logic         div_zero_s3;
    logic         div_zero_s4;
    logic         div_zero_s5;

    logic [63:0]  q_abs_s6;
    logic [63:0]  abs_srca_s6;
    logic [63:0]  abs_srcb_s6;
    logic         quotient_neg_s6;
    logic         srca_neg_s6;
    logic         div_zero_s6;
    logic [63:0]  srca_s6;

    // S0 pipeline register (cuts abs+lzc+shift+lut combinational path)
    logic [63:0]  abs_srca_s0;
    logic [63:0]  abs_srcb_s0;
    logic [63:0]  srca_s0;
    logic [63:0]  shifted_abs_srcb_s0;
    logic [5:0]   shift_amount_s0;
    logic [63:0]  x0_seed_s0;
    logic         srca_neg_s0;
    logic         srcb_neg_s0;
    logic         quotient_neg_s0;
    logic         div_zero_s0;

    assign shift_amount = lzc_out[5:0];
    assign x0_seed = {x0_lut, 59'd0};


    assign srca_neg = srca_neg_s4;
    assign srcb_neg = srcb_neg_s4;
    assign quotient_neg = quotient_neg_s4;

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
        .Xo(x0_seed_s0),
        .D(shifted_abs_srcb_s0),
        .Xn(x1_next)
    );

    newton_raphson_module newton_raphson_iter2 (
        .Xo(x1_out),
        .D(shifted_abs_srcb_s1),
        .Xn(x2_next)
    );

    newton_raphson_module newton_raphson_iter3 (
        .Xo(x2_out),
        .D(shifted_abs_srcb_s2),
        .Xn(x3_next)
    );

    newton_raphson_module newton_raphson_iter4 (
        .Xo(x3_out),
        .D(shifted_abs_srcb_s3),
        .Xn(x4_next)
    );

    // S0: Front-end register stage
    always_ff @(posedge clk) begin
        if (rst) begin
            abs_srca_s0       <= '0;
            abs_srcb_s0       <= '0;
            srca_s0           <= '0;
            shifted_abs_srcb_s0 <= '0;
            shift_amount_s0   <= '0;
            x0_seed_s0        <= '0;
            srca_neg_s0       <= '0;
            srcb_neg_s0       <= '0;
            quotient_neg_s0   <= '0;
            div_zero_s0       <= '0;
        end else begin
            abs_srca_s0       <= abs_srca;
            abs_srcb_s0       <= abs_srcb;
            srca_s0           <= srca;
            shifted_abs_srcb_s0 <= shifted_abs_srcb;
            shift_amount_s0   <= shift_amount;
            x0_seed_s0        <= x0_seed;
            srca_neg_s0       <= is_signed & srca[63];
            srcb_neg_s0       <= is_signed & srcb[63];
            quotient_neg_s0   <= (is_signed & srca[63]) ^ (is_signed & srcb[63]);
            div_zero_s0       <= (srcb == 64'd0);
        end
    end

    // NR iteration pipeline registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x1_out <= '0;
            x2_out <= '0;
            x3_out <= '0;
            x4_out <= '0;

            abs_srca_s1 <= '0;
            abs_srca_s2 <= '0;
            abs_srca_s3 <= '0;
            abs_srca_s4 <= '0;
            abs_srca_s5 <= '0;

            abs_srcb_s1 <= '0;
            abs_srcb_s2 <= '0;
            abs_srcb_s3 <= '0;
            abs_srcb_s4 <= '0;
            abs_srcb_s5 <= '0;

            srca_s1 <= '0;
            srca_s2 <= '0;
            srca_s3 <= '0;
            srca_s4 <= '0;
            srca_s5 <= '0;

            shifted_abs_srcb_s1 <= '0;
            shifted_abs_srcb_s2 <= '0;
            shifted_abs_srcb_s3 <= '0;
            shifted_abs_srcb_s4 <= '0;
            shifted_abs_srcb_s5 <= '0;

            shift_amount_s1 <= '0;
            shift_amount_s2 <= '0;
            shift_amount_s3 <= '0;
            shift_amount_s4 <= '0;
            shift_amount_s5 <= '0;

            srca_neg_s1 <= '0;
            srca_neg_s2 <= '0;
            srca_neg_s3 <= '0;
            srca_neg_s4 <= '0;
            srca_neg_s5 <= '0;

            srcb_neg_s1 <= '0;
            srcb_neg_s2 <= '0;
            srcb_neg_s3 <= '0;
            srcb_neg_s4 <= '0;
            srcb_neg_s5 <= '0;

            quotient_neg_s1 <= '0;
            quotient_neg_s2 <= '0;
            quotient_neg_s3 <= '0;
            quotient_neg_s4 <= '0;
            quotient_neg_s5 <= '0;

            div_zero_s1 <= '0;
            div_zero_s2 <= '0;
            div_zero_s3 <= '0;
            div_zero_s4 <= '0;
            div_zero_s5 <= '0;
        end else begin
            x1_out <= x1_next;
            x2_out <= x2_next;
            x3_out <= x3_next;
            x4_out <= x4_next;

            abs_srca_s1 <= abs_srca_s0;
            abs_srca_s2 <= abs_srca_s1;
            abs_srca_s3 <= abs_srca_s2;
            abs_srca_s4 <= abs_srca_s3;
            abs_srca_s5 <= abs_srca_s4;

            abs_srcb_s1 <= abs_srcb_s0;
            abs_srcb_s2 <= abs_srcb_s1;
            abs_srcb_s3 <= abs_srcb_s2;
            abs_srcb_s4 <= abs_srcb_s3;
            abs_srcb_s5 <= abs_srcb_s4;

            srca_s1 <= srca_s0;
            srca_s2 <= srca_s1;
            srca_s3 <= srca_s2;
            srca_s4 <= srca_s3;
            srca_s5 <= srca_s4;

            shifted_abs_srcb_s1 <= shifted_abs_srcb_s0;
            shifted_abs_srcb_s2 <= shifted_abs_srcb_s1;
            shifted_abs_srcb_s3 <= shifted_abs_srcb_s2;
            shifted_abs_srcb_s4 <= shifted_abs_srcb_s3;
            shifted_abs_srcb_s5 <= shifted_abs_srcb_s4;

            shift_amount_s1 <= shift_amount_s0;
            shift_amount_s2 <= shift_amount_s1;
            shift_amount_s3 <= shift_amount_s2;
            shift_amount_s4 <= shift_amount_s3;
            shift_amount_s5 <= shift_amount_s4;

            srca_neg_s1 <= srca_neg_s0;
            srca_neg_s2 <= srca_neg_s1;
            srca_neg_s3 <= srca_neg_s2;
            srca_neg_s4 <= srca_neg_s3;
            srca_neg_s5 <= srca_neg_s4;

            srcb_neg_s1 <= srcb_neg_s0;
            srcb_neg_s2 <= srcb_neg_s1;
            srcb_neg_s3 <= srcb_neg_s2;
            srcb_neg_s4 <= srcb_neg_s3;
            srcb_neg_s5 <= srcb_neg_s4;

            quotient_neg_s1 <= quotient_neg_s0;
            quotient_neg_s2 <= quotient_neg_s1;
            quotient_neg_s3 <= quotient_neg_s2;
            quotient_neg_s4 <= quotient_neg_s3;
            quotient_neg_s5 <= quotient_neg_s4;

            div_zero_s1 <= div_zero_s0;
            div_zero_s2 <= div_zero_s1;
            div_zero_s3 <= div_zero_s2;
            div_zero_s4 <= div_zero_s3;
            div_zero_s5 <= div_zero_s4;
        end
    end

    // Four-iteration mode: keep debug taps available.
    assign x5_out = x4_out;
    assign x6_out = x4_out;

    booth_wallace_multiplier #(
        .SRC1_WIDTH(64),
        .SRC2_WIDTH(64)
    ) mult_quotient (
        .srca(abs_srca_s4),
        .srcb(x4_out),
        .is_signed(1'b0),
        .result(res_mult)
    );

    assign denorm_shift_amount = 7'd126 - {1'b0, shift_amount_s4};

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

    // Stage 6 pipeline register: cuts the two-multiplier critical path
    // (abs_srca_s5 -> mult_quotient -> q_abs -> rem multiply -> result)
    always_ff @(posedge clk) begin
        if (rst) begin
            q_abs_s6        <= '0;
            abs_srca_s6     <= '0;
            abs_srcb_s6     <= '0;
            quotient_neg_s6 <= '0;
            srca_neg_s6     <= '0;
            div_zero_s6     <= '0;
            srca_s6         <= '0;
        end else begin
            q_abs_s6        <= q_abs;
            abs_srca_s6     <= abs_srca_s4;
            abs_srcb_s6     <= abs_srcb_s4;
            quotient_neg_s6 <= quotient_neg_s4;
            srca_neg_s6     <= srca_neg_s4;
            div_zero_s6     <= div_zero_s4;
            srca_s6         <= srca_s4;
        end
    end

    assign rem_abs = abs_srca_s6 - (q_abs_s6 * abs_srcb_s6);


    always_comb begin
        q_abs_corr = q_abs_s6;
        rem_abs_corr = rem_abs;

        // Final correction: if the remainder is still at least one divisor,
        // increment quotient and reduce remainder once.
        if (rem_abs >= abs_srcb_s6) begin
            q_abs_corr = q_abs_s6 + 64'd1;
            rem_abs_corr = rem_abs - abs_srcb_s6;
        end
    end

    twos_complement #(.WIDTH(64)) tc_result (
        .value(q_abs_corr),
        .convert(quotient_neg_s6),
        .result(result_signed)
    );

    twos_complement #(.WIDTH(64)) tc_rem (
        .value(rem_abs_corr),
        .convert(srca_neg_s6),
        .result(rem_signed)
    );

    always_comb begin
        div_zero_f = div_zero_s6;

        if (div_zero_f) begin
            result = 64'hFFFF_FFFF_FFFF_FFFF;
            rem = srca_s6;
        end else begin
            result = result_signed;
            rem = rem_signed;
        end
    end

endmodule
