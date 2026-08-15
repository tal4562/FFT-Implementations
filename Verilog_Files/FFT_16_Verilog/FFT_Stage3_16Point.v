module FFT_Stage3_16Point (
    // --- 32 Inputs from Stage 2 (A0 to A15, 16-bit Q1.15) ---
    input  signed [15:0] a0_real,  input signed [15:0] a0_imag,
    input  signed [15:0] a1_real,  input signed [15:0] a1_imag,
    input  signed [15:0] a2_real,  input signed [15:0] a2_imag,
    input  signed [15:0] a3_real,  input signed [15:0] a3_imag,
    input  signed [15:0] a4_real,  input signed [15:0] a4_imag,
    input  signed [15:0] a5_real,  input signed [15:0] a5_imag,
    input  signed [15:0] a6_real,  input signed [15:0] a6_imag,
    input  signed [15:0] a7_real,  input signed [15:0] a7_imag,
    input  signed [15:0] a8_real,  input signed [15:0] a8_imag,
    input  signed [15:0] a9_real,  input signed [15:0] a9_imag,
    input  signed [15:0] a10_real, input signed [15:0] a10_imag,
    input  signed [15:0] a11_real, input signed [15:0] a11_imag,
    input  signed [15:0] a12_real, input signed [15:0] a12_imag,
    input  signed [15:0] a13_real, input signed [15:0] a13_imag,
    input  signed [15:0] a14_real, input signed [15:0] a14_imag,
    input  signed [15:0] a15_real, input signed [15:0] a15_imag,

    // --- 32 Outputs (Xk0 to Xk15, 16-bit Q1.15) ---
    output signed [15:0] xk0_real,  output signed [15:0] xk0_imag,
    output signed [15:0] xk1_real,  output signed [15:0] xk1_imag,
    output signed [15:0] xk2_real,  output signed [15:0] xk2_imag,
    output signed [15:0] xk3_real,  output signed [15:0] xk3_imag,
    output signed [15:0] xk4_real,  output signed [15:0] xk4_imag,
    output signed [15:0] xk5_real,  output signed [15:0] xk5_imag,
    output signed [15:0] xk6_real,  output signed [15:0] xk6_imag,
    output signed [15:0] xk7_real,  output signed [15:0] xk7_imag,
    output signed [15:0] xk8_real,  output signed [15:0] xk8_imag,
    output signed [15:0] xk9_real,  output signed [15:0] xk9_imag,
    output signed [15:0] xk10_real, output signed [15:0] xk10_imag,
    output signed [15:0] xk11_real, output signed [15:0] xk11_imag,
    output signed [15:0] xk12_real, output signed [15:0] xk12_imag,
    output signed [15:0] xk13_real, output signed [15:0] xk13_imag,
    output signed [15:0] xk14_real, output signed [15:0] xk14_imag,
    output signed [15:0] xk15_real, output signed [15:0] xk15_imag
);
// --- 16-Point FFT Twiddle Factors (W^k = exp(-j*2*pi*k/16)) ---
// Q1.15 signed format, ready for Verilog

    // --- Stage 4 Twiddle Factors (Q1.15 signed) ---
    localparam signed [15:0] W0_R = 16'sh7FFF;  localparam signed [15:0] W0_I = 16'sh0000; // 1.0 + j0.0
    localparam signed [15:0] W1_R = 16'sh7641;  localparam signed [15:0] W1_I = -16'sh30FC; // 0.9239 - j0.3827
    localparam signed [15:0] W2_R = 16'sh5A82;  localparam signed [15:0] W2_I = -16'sh5A82; // 0.7071 - j0.7071
    localparam signed [15:0] W3_R = 16'sh30FC;  localparam signed [15:0] W3_I = -16'sh7641; // 0.3827 - j0.9239
    localparam signed [15:0] W4_R = 16'sh0000;  localparam signed [15:0] W4_I = -16'sh7FFF; // 0.0 - j1.0
    localparam signed [15:0] W5_R = -16'sh30FC; localparam signed [15:0] W5_I = -16'sh7641; // -0.3827 - j0.9239
    localparam signed [15:0] W6_R = -16'sh5A82; localparam signed [15:0] W6_I = -16'sh5A82; // -0.7071 - j0.7071
    localparam signed [15:0] W7_R = -16'sh7641; localparam signed [15:0] W7_I = -16'sh30FC; // -0.9239 - j0.3827



    
    
    // --- 8 Butterfly Instantiations (Spacing = 8) ---

    // BFU 0 (i=0): Inputs A0, A8. TF: W^0
    Butterfly_Twiddle BFU_S3_0 (
        .real1(a0_real), .imag1(a0_imag),
        .real2(a8_real), .imag2(a8_imag),
        .twiddle_real(W0_R), .twiddle_imag(W0_I),
        .Y_real(xk0_real), .Y_imag(xk0_imag), // Output Xk0
        .Z_real(xk8_real), .Z_imag(xk8_imag)  // Output Xk8
    );

    // BFU 1 (i=1): Inputs A1, A9. TF: W^1
    Butterfly_Twiddle BFU_S3_1 (
        .real1(a1_real), .imag1(a1_imag),
        .real2(a9_real), .imag2(a9_imag),
        .twiddle_real(W1_R), .twiddle_imag(W1_I),
        .Y_real(xk1_real), .Y_imag(xk1_imag), // Output Xk1
        .Z_real(xk9_real), .Z_imag(xk9_imag)  // Output Xk9
    );

    // BFU 2 (i=2): Inputs A2, A10. TF: W^2
    Butterfly_Twiddle BFU_S3_2 (
        .real1(a2_real), .imag1(a2_imag),
        .real2(a10_real), .imag2(a10_imag),
        .twiddle_real(W2_R), .twiddle_imag(W2_I),
        .Y_real(xk2_real), .Y_imag(xk2_imag), // Output Xk2
        .Z_real(xk10_real), .Z_imag(xk10_imag) // Output Xk10
    );

    // BFU 3 (i=3): Inputs A3, A11. TF: W^3
    Butterfly_Twiddle BFU_S3_3 (
        .real1(a3_real), .imag1(a3_imag),
        .real2(a11_real), .imag2(a11_imag),
        .twiddle_real(W3_R), .twiddle_imag(W3_I),
        .Y_real(xk3_real), .Y_imag(xk3_imag), // Output Xk3
        .Z_real(xk11_real), .Z_imag(xk11_imag) // Output Xk11
    );

    // BFU 4 (i=4): Inputs A4, A12. TF: W^4
    Butterfly_Twiddle BFU_S3_4 (
        .real1(a4_real), .imag1(a4_imag),
        .real2(a12_real), .imag2(a12_imag),
        .twiddle_real(W4_R), .twiddle_imag(W4_I),
        .Y_real(xk4_real), .Y_imag(xk4_imag), // Output Xk4
        .Z_real(xk12_real), .Z_imag(xk12_imag) // Output Xk12
    );

    // BFU 5 (i=5): Inputs A5, A13. TF: W^5
    Butterfly_Twiddle BFU_S3_5 (
        .real1(a5_real), .imag1(a5_imag),
        .real2(a13_real), .imag2(a13_imag),
        .twiddle_real(W5_R), .twiddle_imag(W5_I),
        .Y_real(xk5_real), .Y_imag(xk5_imag), // Output Xk5
        .Z_real(xk13_real), .Z_imag(xk13_imag) // Output Xk13
    );

    // BFU 6 (i=6): Inputs A6, A14. TF: W^6
    Butterfly_Twiddle BFU_S3_6 (
        .real1(a6_real), .imag1(a6_imag),
        .real2(a14_real), .imag2(a14_imag),
        .twiddle_real(W6_R), .twiddle_imag(W6_I),
        .Y_real(xk6_real), .Y_imag(xk6_imag), // Output Xk6
        .Z_real(xk14_real), .Z_imag(xk14_imag) // Output Xk14
    );

    // BFU 7 (i=7): Inputs A7, A15. TF: W^7
    Butterfly_Twiddle BFU_S3_7 (
        .real1(a7_real), .imag1(a7_imag),
        .real2(a15_real), .imag2(a15_imag),
        .twiddle_real(W7_R), .twiddle_imag(W7_I),
        .Y_real(xk7_real), .Y_imag(xk7_imag), // Output Xk7
        .Z_real(xk15_real), .Z_imag(xk15_imag) // Output Xk15
    );

endmodule // FFT_Stage3_16Point