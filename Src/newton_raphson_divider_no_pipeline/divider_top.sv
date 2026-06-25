module divider_top #(
	parameter int WIDTH = 64
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

	logic [63:0] srca_r;
	logic [63:0] srcb_r;
	logic        is_signed_r;
	logic [63:0] core_result;
	logic [63:0] core_rem;
	logic        core_div_zero_f;
	logic [63:0] result_r;
	logic [63:0] rem_r;
	logic        div_zero_f_r;

	divider #(
		.WIDTH(WIDTH)
	) u_divider (
		.srca(srca_r),
		.srcb(srcb_r),
		.is_signed(is_signed_r),
		.result(core_result),
		.rem(core_rem),
		.div_zero_f(core_div_zero_f)
	);

	always_ff @(posedge clk) begin
		if (rst) begin
			srca_r      <= '0;
			srcb_r      <= '0;
			is_signed_r <= 1'b0;
			result_r    <= '0;
			rem_r       <= '0;
			div_zero_f_r <= 1'b0;
		end else begin
			srca_r      <= srca;
			srcb_r      <= srcb;
			is_signed_r <= is_signed;
			result_r    <= core_result;
			rem_r       <= core_rem;
			div_zero_f_r <= core_div_zero_f;
		end
	end

	assign result     = result_r;
	assign rem        = rem_r;
	assign div_zero_f = div_zero_f_r;

endmodule
