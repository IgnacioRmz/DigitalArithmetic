module array_multiplier_top #(
	parameter   int SRC1_WIDTH      = 32,
	parameter   int SRC2_WIDTH      = SRC1_WIDTH
) (
	input  logic                    clk,
	input  logic                    rst_n,
	input  logic [SRC1_WIDTH-1:0]   srca,
	input  logic [SRC2_WIDTH-1:0]   srcb,
	input  logic                    is_signed,
	output logic [RESULT_WIDTH-1:0] result
);

	localparam  int RESULT_WIDTH    = (SRC1_WIDTH + SRC2_WIDTH);

	logic [SRC1_WIDTH-1:0]   srca_r;
	logic [SRC2_WIDTH-1:0]   srcb_r;
	logic                    is_signed_r;
	logic [RESULT_WIDTH-1:0] core_result;
	logic [RESULT_WIDTH-1:0] result_r;

	array_multiplier #(
		.SRC1_WIDTH(SRC1_WIDTH),
		.SRC2_WIDTH(SRC2_WIDTH)
	) u_array_multiplier (
		.srca(srca_r),
		.srcb(srcb_r),
		.is_signed(is_signed_r),
		.result(core_result)
	);

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			srca_r      <= '0;
			srcb_r      <= '0;
			is_signed_r <= 1'b0;
			result_r    <= '0;
		end else begin
			srca_r      <= srca;
			srcb_r      <= srcb;
			is_signed_r <= is_signed;
			result_r    <= core_result;
		end
	end

	assign result = result_r;

endmodule
