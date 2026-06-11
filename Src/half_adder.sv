module half_adder(
    input  logic A,
    input  logic B,
    output logic S,
    output logic Cout
);

    assign S    = A ^ B;
    assign Cout = A & B;

endmodule