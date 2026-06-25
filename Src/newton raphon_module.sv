module newton_raphson_module(
    input  logic [63:0] Xo,           // Normalized X approximation [1.0, 2.0)
    input  logic [63:0] D,            // Normalized divisor [1.0, 2.0)
    output logic [63:0] Xn            // Updated X approximation
);

    // Internal signals for normalized fixed-point arithmetic
    // Since D and Xo are normalized to [1.0, 2.0), D*Xo is in [1.0, 4.0)
    logic [127:0] d_xo_product;       // D * Xo result (128-bit, intermediate precision)
    logic [127:0] two_minus_d_xo;     // 2 - (D*Xo) result (128-bit)
    logic [127:0] xn_product;         // Xo * (2 - D*Xo) result (128-bit)
    
    // ====================================================================
    // Stage 1: Compute D * Xo using Booth-Wallace Multiplier
    // For normalized values: D in [1.0, 2.0), Xo in [1.0, 2.0)
    // Result D*Xo will be in [1.0, 4.0)
    // ====================================================================
    booth_wallace_multiplier #(
        .SRC1_WIDTH(64),
        .SRC2_WIDTH(64)
    ) mult_d_xo (
        .srca(D),
        .srcb(Xo),
        .is_signed(1'b0),  // Unsigned multiplication for normalized values
        .result(d_xo_product)
    );
    
    // ====================================================================
    // Stage 2: Compute 2 - (D*Xo) in normalized fixed-point
    // 2.0 in fixed-point = 128'h0200_0000_0000_0000 (MSB at bit 62 for [1.0, 2.0))
    // Actually, 2.0 = 128'h0002_0000_0000_0000 in our normalized representation
    // We subtract: two_minus_d_xo = 2.0 - d_xo_product
    // ====================================================================
    assign two_minus_d_xo = 128'h0002_0000_0000_0000 - d_xo_product;
    
    // ====================================================================
    // Stage 3: Compute Xn = Xo * (2 - D*Xo) using Booth-Wallace Multiplier
    // Both operands are normalized, result maintains precision via MSB extraction
    // ====================================================================
    booth_wallace_multiplier #(
        .SRC1_WIDTH(64),
        .SRC2_WIDTH(64)
    ) mult_xn (
        .srca(Xo),
        .srcb(two_minus_d_xo[127:64]),  // Use upper 64 bits for normalized precision
        .is_signed(1'b0),                // Unsigned (normalized values are positive)
        .result(xn_product)
    );
    
    // ====================================================================
    // Output: Extract MSBs to maintain normalized fixed-point format
    // Shift right to extract the normalized 64-bit result from 128-bit product
    // ====================================================================
    assign Xn = xn_product[127:64];

endmodule