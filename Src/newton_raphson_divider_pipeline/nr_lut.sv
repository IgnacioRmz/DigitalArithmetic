module nr_lut (
    input  logic [3:0] in_val,
    output logic [4:0] x0_out 
);

    // Since it is normalized, in_val[3] will always be 1
    logic [2:0] lut_addr;
    assign lut_addr = in_val[2:0];

    always_comb begin
        case (lut_addr)
            3'b000: x0_out = 5'b1_0000; // In: 1.000 (4'b1000) -> Out: 1.0000 (5'b1_0000)
            3'b001: x0_out = 5'b0_1110; // In: 1.125 (4'b1001) -> Out: 0.8750 (5'b0_1110)
            3'b010: x0_out = 5'b0_1101; // In: 1.250 (4'b1010) -> Out: 0.8125 (5'b0_1101)
            3'b011: x0_out = 5'b0_1100; // In: 1.375 (4'b1011) -> Out: 0.7500 (5'b0_1100)
            3'b100: x0_out = 5'b0_1011; // In: 1.500 (4'b1100) -> Out: 0.6875 (5'b0_1011)
            3'b101: x0_out = 5'b0_1010; // In: 1.625 (4'b1101) -> Out: 0.6250 (5'b0_1010)
            3'b110: x0_out = 5'b0_1001; // In: 1.750 (4'b1110) -> Out: 0.5625 (5'b0_1001)
            3'b111: x0_out = 5'b0_1001; // In: 1.875 (4'b1111) -> Out: 0.5625 (5'b0_1001)
            default: x0_out = 5'b1_0000;
        endcase
    end

endmodule