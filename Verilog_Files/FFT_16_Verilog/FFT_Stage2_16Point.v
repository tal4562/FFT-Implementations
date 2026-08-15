`timescale 1ns / 1ps

module FFT_Stage2_16Point (
    // --- 32 Inputs from Stage 1 (Z0 to Z15) ---
    input  signed [15:0] z0_real,  input signed [15:0] z0_imag,
    input  signed [15:0] z1_real,  input signed [15:0] z1_imag,
    input  signed [15:0] z2_real,  input signed [15:0] z2_imag,
    input  signed [15:0] z3_real,  input signed [15:0] z3_imag,
    input  signed [15:0] z4_real,  input signed [15:0] z4_imag,
    input  signed [15:0] z5_real,  input signed [15:0] z5_imag,
    input  signed [15:0] z6_real,  input signed [15:0] z6_imag,
    input  signed [15:0] z7_real,  input signed [15:0] z7_imag,
    input  signed [15:0] z8_real,  input signed [15:0] z8_imag,
    input  signed [15:0] z9_real,  input signed [15:0] z9_imag,
    input  signed [15:0] z10_real, input signed [15:0] z10_imag,
    input  signed [15:0] z11_real, input signed [15:0] z11_imag,
    input  signed [15:0] z12_real, input signed [15:0] z12_imag,
    input  signed [15:0] z13_real, input signed [15:0] z13_imag,
    input  signed [15:0] z14_real, input signed [15:0] z14_imag,
    input  signed [15:0] z15_real, input signed [15:0] z15_imag,

    // --- 32 Outputs to Stage 3 (A0 to A15) ---
    output signed [15:0] a0_real,  output signed [15:0] a0_imag,
    output signed [15:0] a1_real,  output signed [15:0] a1_imag,
    output signed [15:0] a2_real,  output signed [15:0] a2_imag,
    output signed [15:0] a3_real,  output signed [15:0] a3_imag,
    output signed [15:0] a4_real,  output signed [15:0] a4_imag,
    output signed [15:0] a5_real,  output signed [15:0] a5_imag,
    output signed [15:0] a6_real,  output signed [15:0] a6_imag,
    output signed [15:0] a7_real,  output signed [15:0] a7_imag,
    output signed [15:0] a8_real,  output signed [15:0] a8_imag,
    output signed [15:0] a9_real,  output signed [15:0] a9_imag,
    output signed [15:0] a10_real, output signed [15:0] a10_imag,
    output signed [15:0] a11_real, output signed [15:0] a11_imag,
    output signed [15:0] a12_real, output signed [15:0] a12_imag,
    output signed [15:0] a13_real, output signed [15:0] a13_imag,
    output signed [15:0] a14_real, output signed [15:0] a14_imag,
    output signed [15:0] a15_real, output signed [15:0] a15_imag
);

// --- Stage 2 Twiddle Factors (Q1.15 signed) ---
    localparam signed [15:0] W0_R = 16'sh7FFF;  // 1.0
    localparam signed [15:0] W0_I = 16'sh0000;  // 0.0

    localparam signed [15:0] W1_R = 16'sh5A82;  // 0.7071
    localparam signed [15:0] W1_I = -16'sh5A82; // -0.7071

    localparam signed [15:0] W2_R = 16'sh0000;  // 0.0
    localparam signed [15:0] W2_I = -16'sh7FFF; // -1.0

    localparam signed [15:0] W3_R = -16'sh5A82; // -0.7071
    localparam signed [15:0] W3_I = -16'sh5A82; // -0.7071



    // --- Stage 2 Butterflies (Spacing = 4) ---
    Butterfly_Twiddle BFU_S2_0 (.real1(z0_real),  .imag1(z0_imag),  .real2(z4_real),  .imag2(z4_imag),
                                .twiddle_real(W0_R), .twiddle_imag(W0_I),
                                .Y_real(a0_real), .Y_imag(a0_imag), .Z_real(a4_real), .Z_imag(a4_imag));

    Butterfly_Twiddle BFU_S2_1 (.real1(z1_real),  .imag1(z1_imag),  .real2(z5_real),  .imag2(z5_imag),
                                .twiddle_real(W1_R), .twiddle_imag(W1_I),
                                .Y_real(a1_real), .Y_imag(a1_imag), .Z_real(a5_real), .Z_imag(a5_imag));

    Butterfly_Twiddle BFU_S2_2 (.real1(z2_real),  .imag1(z2_imag),  .real2(z6_real),  .imag2(z6_imag),
                                .twiddle_real(W2_R), .twiddle_imag(W2_I),
                                .Y_real(a2_real), .Y_imag(a2_imag), .Z_real(a6_real), .Z_imag(a6_imag));

    Butterfly_Twiddle BFU_S2_3 (.real1(z3_real),  .imag1(z3_imag),  .real2(z7_real),  .imag2(z7_imag),
                                .twiddle_real(W3_R), .twiddle_imag(W3_I),
                                .Y_real(a3_real), .Y_imag(a3_imag), .Z_real(a7_real), .Z_imag(a7_imag));

    Butterfly_Twiddle BFU_S2_4 (.real1(z8_real),  .imag1(z8_imag),  .real2(z12_real), .imag2(z12_imag),
                                .twiddle_real(W0_R), .twiddle_imag(W0_I),
                                .Y_real(a8_real), .Y_imag(a8_imag), .Z_real(a12_real), .Z_imag(a12_imag));

    Butterfly_Twiddle BFU_S2_5 (.real1(z9_real),  .imag1(z9_imag),  .real2(z13_real), .imag2(z13_imag),
                                .twiddle_real(W1_R), .twiddle_imag(W1_I),
                                .Y_real(a9_real), .Y_imag(a9_imag), .Z_real(a13_real), .Z_imag(a13_imag));

    Butterfly_Twiddle BFU_S2_6 (.real1(z10_real), .imag1(z10_imag), .real2(z14_real), .imag2(z14_imag),
                                .twiddle_real(W2_R), .twiddle_imag(W2_I),
                                .Y_real(a10_real), .Y_imag(a10_imag), .Z_real(a14_real), .Z_imag(a14_imag));

    Butterfly_Twiddle BFU_S2_7 (.real1(z11_real), .imag1(z11_imag), .real2(z15_real), .imag2(z15_imag),
                                .twiddle_real(W3_R), .twiddle_imag(W3_I),
                                .Y_real(a11_real), .Y_imag(a11_imag), .Z_real(a15_real), .Z_imag(a15_imag));

endmodule
