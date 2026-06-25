module absolute #(
    parameter int WIDTH = 64
) (
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

    twos_complement #(
        .WIDTH(WIDTH)
    ) u_twos_complement (
        .value  (in),
        .convert(in[WIDTH-1]), // Convert if the number is negative
        .result (out)
    );

endmodule