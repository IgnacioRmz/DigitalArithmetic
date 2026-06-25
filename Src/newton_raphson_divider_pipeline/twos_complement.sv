module twos_complement #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH-1:0] value,
    input  logic             convert,
    output logic [WIDTH-1:0] result
);

    assign result = convert ? (~value + 1'b1) : value;

endmodule