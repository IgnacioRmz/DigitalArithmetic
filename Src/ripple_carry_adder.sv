module ripple_carry_adder # (
    parameter WIDTH = 4
)(
    input  logic [WIDTH-1:0] srca,          // Operando 1
    input  logic [WIDTH-1:0] srcb,          // Operando 2
    input  logic             cin,           // Carry de entrada
    input  logic             is_signed,     // Indica si la operacion es signed(1) o unsigned(0)
    output logic [WIDTH-1:0] result,        // Resultado
    output logic             cout,          // Carry de salida
    output logic             zero_f,        // Bandera de cero
    output logic             ov_f           // Bandera de overflow
);
    
    logic [WIDTH:0] carry;

    assign carry[0] = cin; 
    assign cout     = carry[WIDTH];
    assign zero_f   = (result == '0);
    assign ov_f = is_signed ? (carry[WIDTH] ^ carry[WIDTH-1]) : carry[WIDTH];
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : fa_gen
            full_adder fa_inst(
                .A(srca[i]),
                .B(srcb[i]),
                .Cin(carry[i]),
                .S(result[i]),
                .Cout(carry[i+1])
            );
        end
    endgenerate

endmodule 