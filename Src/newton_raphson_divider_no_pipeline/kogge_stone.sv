module kogge_stone_adder #(
    parameter WIDTH = 4
) (
    input  logic [WIDTH-1:0] srca,          // Operando 1
    input  logic [WIDTH-1:0] srcb,          // Operando 2
    input  logic             cin,           // Carry de entrada
    input  logic             is_signed,     // Indica si la operacion es signed(1) o unsigned(0)
    output logic [WIDTH-1:0] result,        // Resultado
    output logic             cout,          // Carry de salida
    output logic             zero_f,        // Bandera de cero
    output logic             ov_f           // Bandera de overflow
);
 
    // Stages needed
    localparam integer STAGES = $clog2(WIDTH);

    // Array to save the generate and propagate values at each stage
    wire [WIDTH-1:0] G_Array [0:STAGES];
    wire [WIDTH-1:0] P_Array [0:STAGES];

    logic [WIDTH-1:0] P;
    logic [WIDTH-1:0] G;
    wire [WIDTH-1:0] C;  

    always_comb begin
        P = srca ^ srcb;
        G = srca & srcb;
    end
 
    // Initialize first row
    genvar s, i;
    generate
        for (i = 0; i < WIDTH; i++) begin : init_prefix
            assign G_Array[0][i] = (i == 0) ? (G[0] | (P[0] & cin)) : G[i];
            assign P_Array[0][i] = P[i];
        end
 
        for (s = 1; s <= STAGES; s++) begin : stage_loop
            for (i = 0; i < WIDTH; i++) begin : node_loop
                localparam integer shift = 1 << (s - 1);
                if (i < shift) begin                     // determine if position needs to be connected to node
                    assign G_Array[s][i] = G_Array[s-1][i];
                    assign P_Array[s][i] = P_Array[s-1][i];
                end else begin
                    kogge_stone_node ks_node (
                        .g_left(G_Array[s-1][i]),
                        .p_left(P_Array[s-1][i]),
                        .g_right(G_Array[s-1][i-shift]),
                        .p_right(P_Array[s-1][i-shift]),
                        .g_out(G_Array[s][i]),
                        .p_out(P_Array[s][i])
                    );
                end
            end
        end
    endgenerate
 
    // Carry and Sum Calculation
    generate
        for (i = 0; i < WIDTH; i++) begin : carry_sum
            assign C[i] = G_Array[STAGES][i];
            assign result[i] = P[i] ^ ((i == 0) ? cin : C[i-1]);
        end
    endgenerate

    logic [WIDTH:0] carry;
    assign carry = {C, cin};

    assign cout = carry[WIDTH];

    // Zero flag
    assign zero_f = (result == {WIDTH{1'b0}});

    // Overflow flag
    assign ov_f = is_signed ? (carry[WIDTH] ^ carry[WIDTH-1]) : carry[WIDTH];
 
endmodule