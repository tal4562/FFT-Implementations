module FFT_Stage0_16Point (
    // --- 32 Inputs (X0 to X15) ---
    input  signed [15:0] x0_real,  input signed [15:0] x0_imag,
    input  signed [15:0] x1_real,  input signed [15:0] x1_imag,
    input  signed [15:0] x2_real,  input signed [15:0] x2_imag,
    input  signed [15:0] x3_real,  input signed [15:0] x3_imag,
    input  signed [15:0] x4_real,  input signed [15:0] x4_imag,
    input  signed [15:0] x5_real,  input signed [15:0] x5_imag,
    input  signed [15:0] x6_real,  input signed [15:0] x6_imag,
    input  signed [15:0] x7_real,  input signed [15:0] x7_imag,
    input  signed [15:0] x8_real,  input signed [15:0] x8_imag,
    input  signed [15:0] x9_real,  input signed [15:0] x9_imag,
    input  signed [15:0] x10_real, input signed [15:0] x10_imag,
    input  signed [15:0] x11_real, input signed [15:0] x11_imag,
    input  signed [15:0] x12_real, input signed [15:0] x12_imag,
    input  signed [15:0] x13_real, input signed [15:0] x13_imag,
    input  signed [15:0] x14_real, input signed [15:0] x14_imag,
    input  signed [15:0] x15_real, input signed [15:0] x15_imag,
    
    // --- 32 Outputs (Y0 to Y15) ---
    output signed [15:0] y0_real,  output signed [15:0] y0_imag,
    output signed [15:0] y1_real,  output signed [15:0] y1_imag,
    output signed [15:0] y2_real,  output signed [15:0] y2_imag,
    output signed [15:0] y3_real,  output signed [15:0] y3_imag,
    output signed [15:0] y4_real,  output signed [15:0] y4_imag,
    output signed [15:0] y5_real,  output signed [15:0] y5_imag,
    output signed [15:0] y6_real,  output signed [15:0] y6_imag,
    output signed [15:0] y7_real,  output signed [15:0] y7_imag,
    output signed [15:0] y8_real,  output signed [15:0] y8_imag,
    output signed [15:0] y9_real,  output signed [15:0] y9_imag,
    output signed [15:0] y10_real, output signed [15:0] y10_imag,
    output signed [15:0] y11_real, output signed [15:0] y11_imag,
    output signed [15:0] y12_real, output signed [15:0] y12_imag,
    output signed [15:0] y13_real, output signed [15:0] y13_imag,
    output signed [15:0] y14_real, output signed [15:0] y14_imag,
    output signed [15:0] y15_real, output signed [15:0] y15_imag
);

    localparam signed [15:0] W0_R = 16'sh7FFF; // 1.0 in Q1.15
    localparam signed [15:0] W0_I = 16'sh0000; // 0.0 in Q1.15

    // BFU 0: X0 and X1 -> Y0 and Y1 (Output indices are for the result of the butterfly)
     Butterfly_Twiddle BFU0 (
        .real1(x0_real), .imag1(x0_imag),
        .real2(x1_real), .imag2(x1_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y0_real), .Y_imag(y0_imag), // Output 0 (Sum)
        .Z_real(y1_real), .Z_imag(y1_imag)  // Output 1 (Difference)
    );

    // BFU 1: X2 and X3 -> Y2 and Y3
    Butterfly_Twiddle BFU1 (
        .real1(x2_real), .imag1(x2_imag),
        .real2(x3_real), .imag2(x3_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y2_real), .Y_imag(y2_imag),
        .Z_real(y3_real), .Z_imag(y3_imag)
    );

    // BFU 2: X4 and X5 -> Y4 and Y5
    Butterfly_Twiddle BFU2 (
        .real1(x4_real), .imag1(x4_imag),
        .real2(x5_real), .imag2(x5_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y4_real), .Y_imag(y4_imag),
        .Z_real(y5_real), .Z_imag(y5_imag)
    );

    // BFU 3: X6 and X7 -> Y6 and Y7
    Butterfly_Twiddle BFU3 (
        .real1(x6_real), .imag1(x6_imag),
        .real2(x7_real), .imag2(x7_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y6_real), .Y_imag(y6_imag),
        .Z_real(y7_real), .Z_imag(y7_imag)
    );

    // BFU 4: X8 and X9 -> Y8 and Y9
    Butterfly_Twiddle BFU4 (
        .real1(x8_real), .imag1(x8_imag),
        .real2(x9_real), .imag2(x9_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y8_real), .Y_imag(y8_imag),
        .Z_real(y9_real), .Z_imag(y9_imag)
    );

    // BFU 5: X10 and X11 -> Y10 and Y11
    Butterfly_Twiddle BFU5 (
        .real1(x10_real), .imag1(x10_imag),
        .real2(x11_real), .imag2(x11_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y10_real), .Y_imag(y10_imag),
        .Z_real(y11_real), .Z_imag(y11_imag)
    );

    // BFU 6: X12 and X13 -> Y12 and Y13
    Butterfly_Twiddle BFU6 (
        .real1(x12_real), .imag1(x12_imag),
        .real2(x13_real), .imag2(x13_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y12_real), .Y_imag(y12_imag),
        .Z_real(y13_real), .Z_imag(y13_imag)
    );

    // BFU 7: X14 and X15 -> Y14 and Y15
    Butterfly_Twiddle BFU7 (
        .real1(x14_real), .imag1(x14_imag),
        .real2(x15_real), .imag2(x15_imag),
        .twiddle_real(W0_R),
        .twiddle_imag(W0_I),
        .Y_real(y14_real), .Y_imag(y14_imag),
        .Z_real(y15_real), .Z_imag(y15_imag)
    );

endmodule // FFT_Stage0_16Point