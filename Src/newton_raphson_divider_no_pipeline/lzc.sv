module lzc #(
    parameter int WIDTH = 64
) (
    input  logic [WIDTH-1:0] in,
    output logic [$clog2(WIDTH):0] out
);

    logic [WIDTH-1:0] temp;
    logic             found_one;
    
    assign temp = in;

    always_comb begin
        out = 0;
        found_one = 1'b0;
        for (int i = WIDTH-1; i >= 0; i--) begin
            if (temp[i] && !found_one) begin
                out = WIDTH - i - 1;
                found_one = 1'b1;
            end
        end
    end

endmodule