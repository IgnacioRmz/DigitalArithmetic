module wallace_reducer #(
    parameter int RESULT_WIDTH = 64,
    parameter int PP_COUNT     = 16
) (
    input  logic [RESULT_WIDTH-1:0] partial_products [PP_COUNT-1:0],
    output logic [RESULT_WIDTH-1:0] result
);

    generate
        genvar i;
        
        if (PP_COUNT == 1) begin : gen_width_one
            assign result = partial_products[0];
        end else if (PP_COUNT == 2) begin : gen_width_two
            ripple_carry_adder #(
                .WIDTH(RESULT_WIDTH)
            ) final_add (
                .srca(partial_products[0]),
                .srcb(partial_products[1]),
                .cin(1'b0),
                .is_signed(1'b0),
                .result(result),
                .cout(),
                .zero_f(),
                .ov_f()
            );
        end else begin : gen_csa_chain
            logic [RESULT_WIDTH-1:0] csa_sum   [PP_COUNT-3:0];
            logic [RESULT_WIDTH-1:0] csa_carry [PP_COUNT-3:0];
            logic [RESULT_WIDTH-1:0] final_sum;
            logic [RESULT_WIDTH-1:0] final_carry;

            for (i = 0; i < PP_COUNT - 2; i++) begin : csa_gen
                logic [RESULT_WIDTH:0] carry_temp;

                if (i == 0) begin : csa_first
                    carry_save_adder #(
                        .WIDTH(RESULT_WIDTH)
                    ) csa_inst (
                        .A(partial_products[0]),
                        .B(partial_products[1]),
                        .C(partial_products[2]),
                        .Sum(csa_sum[0]),
                        .Carry(carry_temp)
                    );
                end else begin : csa_next
                    carry_save_adder #(
                        .WIDTH(RESULT_WIDTH)
                    ) csa_inst (
                        .A(csa_sum[i-1]),
                        .B(csa_carry[i-1]),
                        .C(partial_products[i+2]),
                        .Sum(csa_sum[i]),
                        .Carry(carry_temp)
                    );
                end

                assign csa_carry[i] = carry_temp[RESULT_WIDTH-1:0];
            end

            assign final_sum   = csa_sum[PP_COUNT-3];
            assign final_carry = csa_carry[PP_COUNT-3];

            ripple_carry_adder #(
                .WIDTH(RESULT_WIDTH)
            ) final_add (
                .srca(final_sum),
                .srcb(final_carry),
                .cin(1'b0),
                .is_signed(1'b0),
                .result(result),
                .cout(),
                .zero_f(),
                .ov_f()
            );
        end
    endgenerate

endmodule
