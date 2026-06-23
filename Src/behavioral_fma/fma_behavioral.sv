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

    always_comb begin
        if (is_signed) begin
            result = $signed(srca) * $signed(srcb);
            if (is_fma) begin
                result = $signed(result) + $signed(srcc);
            end
        end else begin
            result = srca * srcb;
            if (is_fma) begin
                result = result + srcc;
            end
        end
    end

endmodule