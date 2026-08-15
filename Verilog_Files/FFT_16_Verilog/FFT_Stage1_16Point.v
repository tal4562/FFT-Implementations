module FFT_Stage1_16Point (
    // --- 32 Inputs from Stage 0 (Y0 to Y15) ---
    input  signed [15:0] y0_real,  input signed [15:0] y0_imag,
    input  signed [15:0] y1_real,  input signed [15:0] y1_imag,
    input  signed [15:0] y2_real,  input signed [15:0] y2_imag,
    input  signed [15:0] y3_real,  input signed [15:0] y3_imag,
    input  signed [15:0] y4_real,  input signed [15:0] y4_imag,
    input  signed [15:0] y5_real,  input signed [15:0] y5_imag,
    input  signed [15:0] y6_real,  input signed [15:0] y6_imag,
    input  signed [15:0] y7_real,  input signed [15:0] y7_imag,
    input  signed [15:0] y8_real,  input signed [15:0] y8_imag,
    input  signed [15:0] y9_real,  input signed [15:0] y9_imag,
    input  signed [15:0] y10_real, input signed [15:0] y10_imag,
    input  signed [15:0] y11_real, input signed [15:0] y11_imag,
    input  signed [15:0] y12_real, input signed [15:0] y12_imag,
    input  signed [15:0] y13_real, input signed [15:0] y13_imag,
    input  signed [15:0] y14_real, input signed [15:0] y14_imag,
    input  signed [15:0] y15_real, input signed [15:0] y15_imag,
    
    // --- 32 Outputs to Stage 2 (Z0 to Z15) ---
    output signed [15:0] z0_real,  output signed [15:0] z0_imag,
    output signed [15:0] z1_real,  output signed [15:0] z1_imag,
    output signed [15:0] z2_real,  output signed [15:0] z2_imag,
    output signed [15:0] z3_real,  output signed [15:0] z3_imag,
    output signed [15:0] z4_real,  output signed [15:0] z4_imag,
    output signed [15:0] z5_real,  output signed [15:0] z5_imag,
    output signed [15:0] z6_real,  output signed [15:0] z6_imag,
    output signed [15:0] z7_real,  output signed [15:0] z7_imag,
    output signed [15:0] z8_real,  output signed [15:0] z8_imag,
    output signed [15:0] z9_real,  output signed [15:0] z9_imag,
    output signed [15:0] z10_real, output signed [15:0] z10_imag,
    output signed [15:0] z11_real, output signed [15:0] z11_imag,
    output signed [15:0] z12_real, output signed [15:0] z12_imag,
    output signed [15:0] z13_real, output signed [15:0] z13_imag,
    output signed [15:0] z14_real, output signed [15:0] z14_imag,
    output signed [15:0] z15_real, output signed [15:0] z15_imag
    );
    
    localparam signed [15:0] W0_R = 16'sh7FFF; // 1.0
    localparam signed [15:0] W0_I = 16'sh0000; // 0.0

    localparam signed [15:0] W1_R = 16'sh0000; // 0.0
    localparam signed [15:0] W1_I = -16'sh7FFF; // -1.0 in Q1.15


 // BFU 0 (i=0): Inputs Y0, Y2. TF: W^0 (Correct)
    Butterfly_Twiddle BFU_S1_0 (
        .real1(y0_real), .imag1(y0_imag),
        .real2(y2_real), .imag2(y2_imag),
        .twiddle_real(W0_R), .twiddle_imag(W0_I),
        .Y_real(z0_real), .Y_imag(z0_imag),
        .Z_real(z2_real), .Z_imag(z2_imag)
    );

    // BFU 1 (i=1): Inputs Y1, Y3. TF: W^0 (Should be W^0)
    Butterfly_Twiddle BFU_S1_1 (
        .real1(y1_real), .imag1(y1_imag),
        .real2(y3_real), .imag2(y3_imag),
        .twiddle_real(W1_R), .twiddle_imag(W1_I), // *** FIXED: Was W^4 ***
        .Y_real(z1_real), .Y_imag(z1_imag),
        .Z_real(z3_real), .Z_imag(z3_imag)
    );

    // BFU 2 (i=2): Inputs Y4, Y6. TF: W^1 (Should be W^1)
    Butterfly_Twiddle BFU_S1_2 (
        .real1(y4_real), .imag1(y4_imag),
        .real2(y6_real), .imag2(y6_imag),
        .twiddle_real(W0_R), .twiddle_imag(W0_I), // *** FIXED: Was W^0 ***
        .Y_real(z4_real), .Y_imag(z4_imag),
        .Z_real(z6_real), .Z_imag(z6_imag)
    );

    // BFU 3 (i=3): Inputs Y5, Y7. TF: W^1 (Should be W^1)
    Butterfly_Twiddle BFU_S1_3 (
        .real1(y5_real), .imag1(y5_imag),
        .real2(y7_real), .imag2(y7_imag),
        .twiddle_real(W1_R), .twiddle_imag(W1_I), // *** FIXED: Was W^4 ***
        .Y_real(z5_real), .Y_imag(z5_imag),
        .Z_real(z7_real), .Z_imag(z7_imag)
    );

    // BFU 4 (i=4): Inputs Y8, Y10. TF: W^2 (Should be W^2)
    Butterfly_Twiddle BFU_S1_4 (
        .real1(y8_real), .imag1(y8_imag),
        .real2(y10_real), .imag2(y10_imag),
        .twiddle_real(W0_R), .twiddle_imag(W0_I), // *** FIXED: Was W^0 ***
        .Y_real(z8_real), .Y_imag(z8_imag),
        .Z_real(z10_real), .Z_imag(z10_imag)
    );

    // BFU 5 (i=5): Inputs Y9, Y11. TF: W^2 (Should be W^2)
    Butterfly_Twiddle BFU_S1_5 (
        .real1(y9_real), .imag1(y9_imag),
        .real2(y11_real), .imag2(y11_imag),
        .twiddle_real(W1_R), .twiddle_imag(W1_I), // *** FIXED: Was W^4 ***
        .Y_real(z9_real), .Y_imag(z9_imag),
        .Z_real(z11_real), .Z_imag(z11_imag)
    );

    // BFU 6 (i=6): Inputs Y12, Y14. TF: W^3 (Should be W^3)
    Butterfly_Twiddle BFU_S1_6 (
        .real1(y12_real), .imag1(y12_imag),
        .real2(y14_real), .imag2(y14_imag),
        .twiddle_real(W0_R), .twiddle_imag(W0_I), // *** FIXED: Was W^0 ***
        .Y_real(z12_real), .Y_imag(z12_imag),
        .Z_real(z14_real), .Z_imag(z14_imag)
    );

    // BFU 7 (i=7): Inputs Y13, Y15. TF: W^3 (Should be W^3)
    Butterfly_Twiddle BFU_S1_7 (
        .real1(y13_real), .imag1(y13_imag),
        .real2(y15_real), .imag2(y15_imag),
        .twiddle_real(W1_R), .twiddle_imag(W1_I), // *** FIXED: Was W^4 ***
        .Y_real(z13_real), .Y_imag(z13_imag),
        .Z_real(z15_real), .Z_imag(z15_imag)
    );

endmodule