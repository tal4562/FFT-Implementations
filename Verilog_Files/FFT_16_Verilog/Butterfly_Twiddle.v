module Butterfly_Twiddle (
    input  signed [15:0] real1, imag1,
    input  signed [15:0] real2, imag2,
    input  signed [15:0] twiddle_real, twiddle_imag,
    output signed [15:0] Y_real, Y_imag,
    output signed [15:0] Z_real, Z_imag
);

    // --- 1. Complex multiply: P = X2 * W ---
    // cast Q1.15 to 32 bits to store the multiplication result
    wire signed [31:0] P_real_full = real2*twiddle_real - imag2*twiddle_imag;
    wire signed [31:0] P_imag_full = real2*twiddle_imag + imag2*twiddle_real;

    // --- 2. Truncate to Q1.15 ---
    wire signed [15:0] P_real = P_real_full[30:15]; // 16-bit Q1.15
    wire signed [15:0] P_imag = P_imag_full[30:15];

    // --- 3. Butterfly add/subtract ---
    wire signed [16:0] Y_r_full = real1 + P_real;
    wire signed [16:0] Y_i_full = imag1 + P_imag;
    wire signed [16:0] Z_r_full = real1 - P_real;
    wire signed [16:0] Z_i_full = imag1 - P_imag;

    // --- 4. Double scale: divide by 2 ---
    // Prevents Q1.15 overflows
    assign Y_real = Y_r_full[16:1]; // shift right 1
    assign Y_imag = Y_i_full[16:1];
    assign Z_real = Z_r_full[16:1];
    assign Z_imag = Z_i_full[16:1];

endmodule
