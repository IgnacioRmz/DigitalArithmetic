`timescale 1ns/1ns

module tb_multiplier_cfg #(
  parameter int SRC1_WIDTH = 32,
  parameter int SRC2_WIDTH = 32,
  parameter int RAND_ITERS = 500,
  parameter int SEED       = 32'h1BADB002
) (
  output logic done,
  output int   num_pass,
  output int   num_errors
);
  localparam int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH);

  logic [SRC1_WIDTH-1:0]   srca;
  logic [SRC2_WIDTH-1:0]   srcb;
  logic                    is_signed;
  logic [RESULT_WIDTH-1:0] result;
  logic [RESULT_WIDTH-1:0] exp_result;

  wallace_multiplier #(
    .SRC1_WIDTH(SRC1_WIDTH),
    .SRC2_WIDTH(SRC2_WIDTH)
  ) dut (
    .srca(srca),
    .srcb(srcb),
    .is_signed(is_signed),
    .result(result)
  );

  task automatic check_case(
    input logic [SRC1_WIDTH-1:0] a,
    input logic [SRC2_WIDTH-1:0] b,
    input logic                  signed_mode,
    input string                 tag
  );
    begin
      srca      = a;
      srcb      = b;
      is_signed = signed_mode;
      #1;

      if (signed_mode) begin
        exp_result = $signed(srca) * $signed(srcb);
      end else begin
        exp_result = $unsigned(srca) * $unsigned(srcb);
      end

      if (result === exp_result) begin
        num_pass++;
      end else begin
        $error("[%0dx%0d][%s] srca=0x%0h srcb=0x%0h is_signed=%0b exp=0x%0h got=0x%0h",
               SRC1_WIDTH, SRC2_WIDTH, tag, srca, srcb, is_signed, exp_result, result);
        num_errors++;
      end
    end
  endtask

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

  function automatic logic [SRC1_WIDTH-1:0] pattern_mix_a();
    logic [SRC1_WIDTH-1:0] val;
    begin
      val = '0;
      for (int bit_idx = 0; bit_idx < SRC1_WIDTH; bit_idx++) begin
        val[bit_idx] = ~bit_idx[0];
      end
      return val;
    end
  endfunction

  function automatic logic [SRC2_WIDTH-1:0] pattern_mix_b();
    logic [SRC2_WIDTH-1:0] val;
    begin
      val = '0;
      for (int bit_idx = 0; bit_idx < SRC2_WIDTH; bit_idx++) begin
        val[bit_idx] = bit_idx[0];
      end
      return val;
    end
  endfunction

  initial begin
    logic [SRC1_WIDTH-1:0] all_ones_a;
    logic [SRC2_WIDTH-1:0] all_ones_b;
    logic [SRC1_WIDTH-1:0] min_signed_a;
    logic [SRC2_WIDTH-1:0] min_signed_b;
    logic [SRC1_WIDTH-1:0] rand_a;
    logic [SRC2_WIDTH-1:0] rand_b;
    int seed_var;

    done       = 1'b0;
    num_pass   = 0;
    num_errors = 0;

    all_ones_a  = {SRC1_WIDTH{1'b1}};
    all_ones_b  = {SRC2_WIDTH{1'b1}};
    min_signed_a = '0;
    min_signed_b = '0;
    min_signed_a[SRC1_WIDTH-1] = 1'b1;
    min_signed_b[SRC2_WIDTH-1] = 1'b1;

    seed_var = SEED;
    void'($urandom(seed_var));

    // Directed vectors for basic correctness and corner behavior.
    check_case('0, '0, 1'b0, "u_zero_zero");
    check_case('0, all_ones_b, 1'b0, "u_zero_maxb");
    check_case(all_ones_a, '0, 1'b0, "u_maxa_zero");
    check_case(all_ones_a, all_ones_b, 1'b0, "u_max_max");

    check_case(min_signed_a, 'd1, 1'b1, "s_min_x_1");
    check_case('d1, min_signed_b, 1'b1, "s_1_x_min");
    check_case(min_signed_a, min_signed_b, 1'b1, "s_min_x_min");
    check_case(all_ones_a, all_ones_b, 1'b1, "s_neg1_x_neg1");

    check_case({SRC1_WIDTH{1'b1}} >> 1, {SRC2_WIDTH{1'b1}} >> 1, 1'b0, "u_halfscale");
    check_case(pattern_mix_a(),
           pattern_mix_b(),
               1'b0,
               "u_pattern_mix");

    // Randomized sweep with random sign mode per trial.
    for (int idx = 0; idx < RAND_ITERS; idx++) begin
      randomize_a(rand_a);
      randomize_b(rand_b);
      check_case(rand_a, rand_b, $urandom_range(0, 1), $sformatf("rand_%0d", idx));
    end

    $display("CFG[%0dx%0d] PASS=%0d ERR=%0d", SRC1_WIDTH, SRC2_WIDTH, num_pass, num_errors);
    done = 1'b1;
  end

endmodule

module tb_multiplier_stress;
  logic done0, done1, done2, done3;
  int pass0, pass1, pass2, pass3;
  int err0, err1, err2, err3;

  tb_multiplier_cfg #(.SRC1_WIDTH(8),  .SRC2_WIDTH(8),  .RAND_ITERS(300), .SEED(32'h0000A001)) cfg0 (
    .done(done0), .num_pass(pass0), .num_errors(err0)
  );

  tb_multiplier_cfg #(.SRC1_WIDTH(16), .SRC2_WIDTH(9),  .RAND_ITERS(400), .SEED(32'h0000B002)) cfg1 (
    .done(done1), .num_pass(pass1), .num_errors(err1)
  );

  tb_multiplier_cfg #(.SRC1_WIDTH(27), .SRC2_WIDTH(45), .RAND_ITERS(700), .SEED(32'h0000C003)) cfg2 (
    .done(done2), .num_pass(pass2), .num_errors(err2)
  );

  tb_multiplier_cfg #(.SRC1_WIDTH(33), .SRC2_WIDTH(17), .RAND_ITERS(600), .SEED(32'h0000D004)) cfg3 (
    .done(done3), .num_pass(pass3), .num_errors(err3)
  );

  initial begin
    int total_pass;
    int total_err;

    wait(done0 && done1 && done2 && done3);

    total_pass = pass0 + pass1 + pass2 + pass3;
    total_err  = err0 + err1 + err2 + err3;

    $display("STRESS_SUMMARY PASS=%0d ERR=%0d", total_pass, total_err);
    if (total_err == 0) begin
      $display("STRESS TEST PASS");
    end else begin
      $display("STRESS TEST FAILED");
    end

    $finish();
  end
endmodule
