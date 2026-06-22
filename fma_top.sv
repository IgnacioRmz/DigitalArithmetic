module fma_top #(
	parameter int SRC1_WIDTH   = 64,
	parameter int SRC2_WIDTH   = SRC1_WIDTH,
	parameter int SRC3_WIDTH   = SRC1_WIDTH,
	parameter int RESULT_WIDTH = (SRC1_WIDTH + SRC2_WIDTH)
) (
	input  logic [SRC1_WIDTH-1:0]   srca,
	input  logic [SRC2_WIDTH-1:0]   srcb,
	input  logic [SRC3_WIDTH-1:0]   srcc,
	input  logic                    is_fma,
	input  logic                    is_signed,
	input  logic                    clk,
	input  logic                    rst_n,
	output logic [RESULT_WIDTH-1:0] result
);

	logic [SRC1_WIDTH-1:0]   srca_r;
	logic [SRC2_WIDTH-1:0]   srcb_r;
	logic [SRC3_WIDTH-1:0]   srcc_r;
	logic                    is_fma_r;
	logic                    is_signed_r;
	logic [RESULT_WIDTH-1:0] core_result;
	logic [RESULT_WIDTH-1:0] result_r;

	fma #(
		.SRC1_WIDTH(SRC1_WIDTH),
		.SRC2_WIDTH(SRC2_WIDTH),
		.SRC3_WIDTH(SRC3_WIDTH)
	) u_fma (
		.srca(srca_r),
		.srcb(srcb_r),
		.srcc(srcc_r),
		.is_fma(is_fma_r),
		.is_signed(is_signed_r),
		.result(core_result)
	);

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			srca_r      <= '0;
			srcb_r      <= '0;
			srcc_r      <= '0;
			is_fma_r    <= 1'b0;
			is_signed_r <= 1'b0;
			result_r    <= '0;
		end else begin
			srca_r      <= srca;
			srcb_r      <= srcb;
			srcc_r      <= srcc;
			is_fma_r    <= is_fma;
			is_signed_r <= is_signed;
			result_r    <= core_result;
		end
	end

	assign result = result_r;

endmodule
