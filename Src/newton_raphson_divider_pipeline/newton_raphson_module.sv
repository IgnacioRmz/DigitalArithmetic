module newton_raphson_module(
    input  logic [63:0] Xo,           // Normalized X approximation [1.0, 2.0)
    input  logic [63:0] D,            // Normalized divisor [1.0, 2.0)
    output logic [63:0] Xn            // Updated X approximation
);
    // Behavioral Q1.63 fixed-point Newton-Raphson step:
    // Xn = Xo * (2 - Xo*D)
    // D and Xo are normalized. 2.0 is represented as 1<<64 in extended precision.
    localparam logic [64:0] TWO_Q63 = 65'h1_0000_0000_0000_0000;

    logic [127:0] xo_d_full;
    logic [64:0]  xo_d_q63;
    logic [64:0]  term_q63;
    logic [129:0] xn_full;

    always_comb begin
        xo_d_full = D * Xo;
        xo_d_q63 = {1'b0, xo_d_full[126:63]};
        term_q63 = TWO_Q63 - xo_d_q63;

        xn_full = Xo * term_q63[63:0];
        Xn = xn_full[126:63];
    end

endmodule