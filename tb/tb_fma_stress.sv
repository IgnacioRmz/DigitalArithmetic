`timescale 1ns/1ns

module tb_fma_cfg #(
  parameter int SRC1_WIDTH = 64,
  parameter int SRC2_WIDTH = 64,
  parameter int SRC3_WIDTH = 64,
  parameter int RAND_ITERS = 800,
  parameter int SEED       = 32'h00C0FFEE
) (
  output logic done,
  output int   num_pass,
  output int   num_errors
);
  localparam int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH);

  logic [SRC1_WIDTH-1:0]   srca;
  logic [SRC2_WIDTH-1:0]   srcb;
  logic [SRC3_WIDTH-1:0]   srcc;
  logic                    is_fma;
  logic                    is_signed;
  logic [RESULT_WIDTH-1:0] result;

  logic [RESULT_WIDTH-1:0] exp_result;

  fma #(
    .SRC1_WIDTH(SRC1_WIDTH),
    .SRC2_WIDTH(SRC2_WIDTH),
    .SRC3_WIDTH(SRC3_WIDTH)
  ) dut (
    .srca(srca),
    .srcb(srcb),
    .srcc(srcc),
    .is_fma(is_fma),
    .is_signed(is_signed),
    .result(result)
  );

  function automatic logic [SRC1_WIDTH-1:0] pattern_mix_a();
    logic [SRC1_WIDTH-1:0] val;
    begin
      val = '0;
      for (int bit_idx = 0; bit_idx < SRC1_WIDTH; bit_idx++) begin
        val[bit_idx] = bit_idx[1] ^ bit_idx[0];
      end
      return val;
    end
  endfunction

  function automatic logic [SRC2_WIDTH-1:0] pattern_mix_b();
    logic [SRC2_WIDTH-1:0] val;
    begin
      val = '0;
      for (int bit_idx = 0; bit_idx < SRC2_WIDTH; bit_idx++) begin
        val[bit_idx] = ~bit_idx[0];
      end
      return val;
    end
  endfunction

  function automatic logic [SRC3_WIDTH-1:0] pattern_mix_c();
    logic [SRC3_WIDTH-1:0] val;
    begin
      val = '0;
      for (int bit_idx = 0; bit_idx < SRC3_WIDTH; bit_idx++) begin
        val[bit_idx] = bit_idx[0];
      end
      return val;
    end
  endfunction

  task automatic randomize_a(output logic [SRC1_WIDTH-1:0] val);
    int words;
    begin
      val   = '0;
      words = (SRC1_WIDTH + 31) / 32;
      for (int i = 0; i < words; i++) begin
        val = (val << 32) | $urandom();
      end
    end
  endtask

  task automatic randomize_b(output logic [SRC2_WIDTH-1:0] val);
    int words;
    begin
      val   = '0;
      words = (SRC2_WIDTH + 31) / 32;
      for (int i = 0; i < words; i++) begin
        val = (val << 32) | $urandom();
      end
    end
  endtask

  task automatic randomize_c(output logic [SRC3_WIDTH-1:0] val);
    int words;
    begin
      val   = '0;
      words = (SRC3_WIDTH + 31) / 32;
      for (int i = 0; i < words; i++) begin
        val = (val << 32) | $urandom();
      end
    end
  endtask

  task automatic check_case(
    input logic [SRC1_WIDTH-1:0] a,
    input logic [SRC2_WIDTH-1:0] b,
    input logic [SRC3_WIDTH-1:0] c,
    input logic                  fma_mode,
    input logic                  signed_mode,
    input string                 tag
  );
    logic [RESULT_WIDTH-1:0] c_ext;
    logic [RESULT_WIDTH-1:0] mul_val;
    begin
      srca      = a;
      srcb      = b;
      srcc      = c;
      is_fma    = fma_mode;
      is_signed = signed_mode;
      #1;

      if (signed_mode) begin
        c_ext    = {{(RESULT_WIDTH-SRC3_WIDTH){c[SRC3_WIDTH-1]}}, c};
        mul_val  = $signed(srca) * $signed(srcb);
        exp_result = is_fma ? ($signed(mul_val) + $signed(c_ext)) : mul_val;
      end else begin
        c_ext    = {{(RESULT_WIDTH-SRC3_WIDTH){1'b0}}, c};
        mul_val  = $unsigned(srca) * $unsigned(srcb);
        exp_result = is_fma ? (mul_val + c_ext) : mul_val;
      end

      if (result === exp_result) begin
        num_pass++;
      end else begin
        $error("[FMA %0dx%0dx%0d][%s] a=0x%0h b=0x%0h c=0x%0h is_fma=%0b is_signed=%0b exp=0x%0h got=0x%0h",
               SRC1_WIDTH, SRC2_WIDTH, SRC3_WIDTH, tag,
               srca, srcb, srcc, is_fma, is_signed, exp_result, result);
        num_errors++;
      end
    end
  endtask

  initial begin
    logic [SRC1_WIDTH-1:0] max_a;
    logic [SRC2_WIDTH-1:0] max_b;
    logic [SRC3_WIDTH-1:0] max_c;
    logic [SRC1_WIDTH-1:0] min_a;
    logic [SRC2_WIDTH-1:0] min_b;
    logic [SRC3_WIDTH-1:0] min_c;
    logic [SRC1_WIDTH-1:0] rand_a;
    logic [SRC2_WIDTH-1:0] rand_b;
    logic [SRC3_WIDTH-1:0] rand_c;
    int seed_var;

    done       = 1'b0;
    num_pass   = 0;
    num_errors = 0;

    max_a = {SRC1_WIDTH{1'b1}};
    max_b = {SRC2_WIDTH{1'b1}};
    max_c = {SRC3_WIDTH{1'b1}};

    min_a = '0;
    min_b = '0;
    min_c = '0;
    min_a[SRC1_WIDTH-1] = 1'b1;
    min_b[SRC2_WIDTH-1] = 1'b1;
    min_c[SRC3_WIDTH-1] = 1'b1;

    seed_var = SEED;
    void'($urandom(seed_var));

    // Directed sanity: zero, pass-through multiply, and srcc injection enable/disable.
    check_case('0, '0, '0, 1'b0, 1'b0, "u_zero_mul");
    check_case('0, '0, max_c, 1'b1, 1'b0, "u_add_c_only");
    check_case(max_a, '0, max_c, 1'b1, 1'b0, "u_zero_product_plus_c");
    check_case(max_a, max_b, '0, 1'b0, 1'b0, "u_mul_max");
    check_case(max_a, max_b, max_c, 1'b1, 1'b0, "u_mul_max_plus_cmax");

    // Directed signed behavior: min values, negative one, and sign-extended c.
    check_case(min_a, 'd1, '0, 1'b0, 1'b1, "s_minA_x_1");
    check_case('d1, min_b, '0, 1'b0, 1'b1, "s_1_x_minB");
    check_case(min_a, min_b, '0, 1'b0, 1'b1, "s_minA_x_minB");
    check_case(max_a, max_b, max_c, 1'b1, 1'b1, "s_neg1_x_neg1_plus_neg1");
    check_case('0, '0, min_c, 1'b1, 1'b1, "s_add_negative_c_only");

    // Patterns for long carry chains and mixed bit density.
    check_case(pattern_mix_a(), pattern_mix_b(), pattern_mix_c(), 1'b0, 1'b0, "u_pattern_mul");
    check_case(pattern_mix_a(), pattern_mix_b(), pattern_mix_c(), 1'b1, 1'b0, "u_pattern_fma");
    check_case(pattern_mix_a(), pattern_mix_b(), pattern_mix_c(), 1'b1, 1'b1, "s_pattern_fma");

    // Randomized stress across all control combinations.
    for (int idx = 0; idx < RAND_ITERS; idx++) begin
      randomize_a(rand_a);
      randomize_b(rand_b);
      randomize_c(rand_c);

      check_case(rand_a, rand_b, rand_c, 1'b0, 1'b0, $sformatf("rand_u_mul_%0d", idx));
      check_case(rand_a, rand_b, rand_c, 1'b1, 1'b0, $sformatf("rand_u_fma_%0d", idx));
      check_case(rand_a, rand_b, rand_c, 1'b0, 1'b1, $sformatf("rand_s_mul_%0d", idx));
      check_case(rand_a, rand_b, rand_c, 1'b1, 1'b1, $sformatf("rand_s_fma_%0d", idx));
    end

    $display("FMA_CFG[%0dx%0dx%0d] PASS=%0d ERR=%0d",
             SRC1_WIDTH, SRC2_WIDTH, SRC3_WIDTH, num_pass, num_errors);

    done = 1'b1;
  end

endmodule

module tb_fma_stress;
  logic done0, done1, done2, done3, done4;
  int pass0, pass1, pass2, pass3, pass4;
  int err0, err1, err2, err3, err4;

  tb_fma_cfg #(
    .SRC1_WIDTH(8),
    .SRC2_WIDTH(8),
    .SRC3_WIDTH(8),
    .RAND_ITERS(250),
    .SEED(32'h0000A101)
  ) cfg0 (
    .done(done0), .num_pass(pass0), .num_errors(err0)
  );

  tb_fma_cfg #(
    .SRC1_WIDTH(16),
    .SRC2_WIDTH(9),
    .SRC3_WIDTH(5),
    .RAND_ITERS(350),
    .SEED(32'h0000B202)
  ) cfg1 (
    .done(done1), .num_pass(pass1), .num_errors(err1)
  );

  tb_fma_cfg #(
    .SRC1_WIDTH(13),
    .SRC2_WIDTH(7),
    .SRC3_WIDTH(19),
    .RAND_ITERS(350),
    .SEED(32'h0000C303)
  ) cfg2 (
    .done(done2), .num_pass(pass2), .num_errors(err2)
  );

  tb_fma_cfg #(
    .SRC1_WIDTH(33),
    .SRC2_WIDTH(17),
    .SRC3_WIDTH(29),
    .RAND_ITERS(500),
    .SEED(32'h0000D404)
  ) cfg3 (
    .done(done3), .num_pass(pass3), .num_errors(err3)
  );

  tb_fma_cfg #(
    .SRC1_WIDTH(64),
    .SRC2_WIDTH(32),
    .SRC3_WIDTH(48),
    .RAND_ITERS(600),
    .SEED(32'h0000E505)
  ) cfg4 (
    .done(done4), .num_pass(pass4), .num_errors(err4)
  );

  initial begin
    int total_pass;
    int total_err;

    wait(done0 && done1 && done2 && done3 && done4);

    total_pass = pass0 + pass1 + pass2 + pass3 + pass4;
    total_err  = err0  + err1  + err2  + err3  + err4;

    $display("FMA_STRESS_SUMMARY PASS=%0d ERR=%0d", total_pass, total_err);

    if (total_err == 0) begin
      $display("FMA STRESS TEST PASS");
    end else begin
      $display("FMA STRESS TEST FAILED");
    end

    $finish();
  end
endmodule
