module shifter #(
    parameter int WIDTH = 64
) (
    input  logic [WIDTH-1:0] in,
    input  logic [$clog2(WIDTH)-1:0] shift_amount,
    input  logic direction, // 0 for left shift, 1 for right shift
    output logic [WIDTH-1:0] out
);

    always_comb begin
        if (direction == 0) begin
            out = in << shift_amount; // Left shift
        end else begin
            out = in >> shift_amount; // Right shift
        end
    end

endmodule