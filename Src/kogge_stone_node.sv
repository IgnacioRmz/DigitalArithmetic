module kogge_stone_node (
    input  logic g_left,
    input  logic p_left,
    input  logic g_right,
    input  logic p_right,
    output logic g_out,
    output logic p_out
);

    assign g_out = g_left | (p_left & g_right);
    assign p_out = p_left & p_right;

endmodule
