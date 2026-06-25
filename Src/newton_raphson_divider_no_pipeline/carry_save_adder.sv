module carry_save_adder #(parameter WIDTH = 8) (
    input  logic [WIDTH-1:0] A,
    input  logic [WIDTH-1:0] B,
    input  logic [WIDTH-1:0] C,
    output logic [WIDTH-1:0] Sum,
    output logic [WIDTH:0]   Carry 
);

    assign Carry[0] = 1'b0; 
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : csa
            full_adder fa (
                .A(A[i]),
                .B(B[i]),
                .Cin(C[i]),
                .S(Sum[i]),
                .Cout(Carry[i+1])
            );
        end
    endgenerate

endmodule