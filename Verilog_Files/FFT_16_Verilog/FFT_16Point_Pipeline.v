module FFT_16Point_Pipeline (
    // --- 32 Inputs (X_in[0] to X_in[15] - NATURAL ORDER) ---
    input  signed [15:0] x_in0_real,  input signed [15:0] x_in0_imag,
    input  signed [15:0] x_in1_real,  input signed [15:0] x_in1_imag,
    input  signed [15:0] x_in2_real,  input signed [15:0] x_in2_imag,
    input  signed [15:0] x_in3_real,  input signed [15:0] x_in3_imag,
    input  signed [15:0] x_in4_real,  input signed [15:0] x_in4_imag,
    input  signed [15:0] x_in5_real,  input signed [15:0] x_in5_imag,
    input  signed [15:0] x_in6_real,  input signed [15:0] x_in6_imag,
    input  signed [15:0] x_in7_real,  input signed [15:0] x_in7_imag,
    input  signed [15:0] x_in8_real,  input signed [15:0] x_in8_imag,
    input  signed [15:0] x_in9_real,  input signed [15:0] x_in9_imag,
    input  signed [15:0] x_in10_real, input signed [15:0] x_in10_imag,
    input  signed [15:0] x_in11_real, input signed [15:0] x_in11_imag,
    input  signed [15:0] x_in12_real, input signed [15:0] x_in12_imag,
    input  signed [15:0] x_in13_real, input signed [15:0] x_in13_imag,
    input  signed [15:0] x_in14_real, input signed [15:0] x_in14_imag,
    input  signed [15:0] x_in15_real, input signed [15:0] x_in15_imag,

    // --- 32 Outputs (Xk[0] to Xk[15] - BIT-REVERSED ORDER) ---
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

    // --- Intermediate wires for pipelined stages ---
    wire signed [15:0] y_real[0:15], y_imag[0:15];
    wire signed [15:0] z_real[0:15], z_imag[0:15];
    wire signed [15:0] a_real[0:15], a_imag[0:15];

    // --- Bit-reversal input mapping ---
    wire signed [15:0] y_br_real[0:15], y_br_imag[0:15];
    assign y_br_real[0]  = x_in0_real;  assign y_br_imag[0]  = x_in0_imag;   // BR(0)=0
    assign y_br_real[1]  = x_in8_real;  assign y_br_imag[1]  = x_in8_imag;   // BR(1)=8
    assign y_br_real[2]  = x_in4_real;  assign y_br_imag[2]  = x_in4_imag;   // BR(2)=4
    assign y_br_real[3]  = x_in12_real; assign y_br_imag[3]  = x_in12_imag;  // BR(3)=12
    assign y_br_real[4]  = x_in2_real;  assign y_br_imag[4]  = x_in2_imag;   // BR(4)=2
    assign y_br_real[5]  = x_in10_real; assign y_br_imag[5]  = x_in10_imag;  // BR(5)=10
    assign y_br_real[6]  = x_in6_real;  assign y_br_imag[6]  = x_in6_imag;   // BR(6)=6
    assign y_br_real[7]  = x_in14_real; assign y_br_imag[7]  = x_in14_imag;  // BR(7)=14
    assign y_br_real[8]  = x_in1_real;  assign y_br_imag[8]  = x_in1_imag;   // BR(8)=1
    assign y_br_real[9]  = x_in9_real;  assign y_br_imag[9]  = x_in9_imag;   // BR(9)=9
    assign y_br_real[10] = x_in5_real;  assign y_br_imag[10] = x_in5_imag;   // BR(10)=5
    assign y_br_real[11] = x_in13_real; assign y_br_imag[11] = x_in13_imag;  // BR(11)=13
    assign y_br_real[12] = x_in3_real;  assign y_br_imag[12] = x_in3_imag;   // BR(12)=3
    assign y_br_real[13] = x_in11_real; assign y_br_imag[13] = x_in11_imag;  // BR(13)=11
    assign y_br_real[14] = x_in7_real;  assign y_br_imag[14] = x_in7_imag;   // BR(14)=7
    assign y_br_real[15] = x_in15_real; assign y_br_imag[15] = x_in15_imag;  // BR(15)=15

    // --- Stage 0 ---
    FFT_Stage0_16Point ST0 (
        .x0_real(y_br_real[0]),  .x0_imag(y_br_imag[0]),
        .x1_real(y_br_real[1]),  .x1_imag(y_br_imag[1]),
        .x2_real(y_br_real[2]),  .x2_imag(y_br_imag[2]),
        .x3_real(y_br_real[3]),  .x3_imag(y_br_imag[3]),
        .x4_real(y_br_real[4]),  .x4_imag(y_br_imag[4]),
        .x5_real(y_br_real[5]),  .x5_imag(y_br_imag[5]),
        .x6_real(y_br_real[6]),  .x6_imag(y_br_imag[6]),
        .x7_real(y_br_real[7]),  .x7_imag(y_br_imag[7]),
        .x8_real(y_br_real[8]),  .x8_imag(y_br_imag[8]),
        .x9_real(y_br_real[9]),  .x9_imag(y_br_imag[9]),
        .x10_real(y_br_real[10]), .x10_imag(y_br_imag[10]),
        .x11_real(y_br_real[11]), .x11_imag(y_br_imag[11]),
        .x12_real(y_br_real[12]), .x12_imag(y_br_imag[12]),
        .x13_real(y_br_real[13]), .x13_imag(y_br_imag[13]),
        .x14_real(y_br_real[14]), .x14_imag(y_br_imag[14]),
        .x15_real(y_br_real[15]), .x15_imag(y_br_imag[15]),

        .y0_real(y_real[0]),   .y0_imag(y_imag[0]),
        .y1_real(y_real[1]),   .y1_imag(y_imag[1]),
        .y2_real(y_real[2]),   .y2_imag(y_imag[2]),
        .y3_real(y_real[3]),   .y3_imag(y_imag[3]),
        .y4_real(y_real[4]),   .y4_imag(y_imag[4]),
        .y5_real(y_real[5]),   .y5_imag(y_imag[5]),
        .y6_real(y_real[6]),   .y6_imag(y_imag[6]),
        .y7_real(y_real[7]),   .y7_imag(y_imag[7]),
        .y8_real(y_real[8]),   .y8_imag(y_imag[8]),
        .y9_real(y_real[9]),   .y9_imag(y_imag[9]),
        .y10_real(y_real[10]), .y10_imag(y_imag[10]),
        .y11_real(y_real[11]), .y11_imag(y_imag[11]),
        .y12_real(y_real[12]), .y12_imag(y_imag[12]),
        .y13_real(y_real[13]), .y13_imag(y_imag[13]),
        .y14_real(y_real[14]), .y14_imag(y_imag[14]),
        .y15_real(y_real[15]), .y15_imag(y_imag[15])
    );

    // --- Stage 1 ---
    FFT_Stage1_16Point ST1 (
        .y0_real(y_real[0]),   .y0_imag(y_imag[0]),
        .y1_real(y_real[1]),   .y1_imag(y_imag[1]),
        .y2_real(y_real[2]),   .y2_imag(y_imag[2]),
        .y3_real(y_real[3]),   .y3_imag(y_imag[3]),
        .y4_real(y_real[4]),   .y4_imag(y_imag[4]),
        .y5_real(y_real[5]),   .y5_imag(y_imag[5]),
        .y6_real(y_real[6]),   .y6_imag(y_imag[6]),
        .y7_real(y_real[7]),   .y7_imag(y_imag[7]),
        .y8_real(y_real[8]),   .y8_imag(y_imag[8]),
        .y9_real(y_real[9]),   .y9_imag(y_imag[9]),
        .y10_real(y_real[10]), .y10_imag(y_imag[10]),
        .y11_real(y_real[11]), .y11_imag(y_imag[11]),
        .y12_real(y_real[12]), .y12_imag(y_imag[12]),
        .y13_real(y_real[13]), .y13_imag(y_imag[13]),
        .y14_real(y_real[14]), .y14_imag(y_imag[14]),
        .y15_real(y_real[15]), .y15_imag(y_imag[15]),

        .z0_real(z_real[0]),   .z0_imag(z_imag[0]),
        .z1_real(z_real[1]),   .z1_imag(z_imag[1]),
        .z2_real(z_real[2]),   .z2_imag(z_imag[2]),
        .z3_real(z_real[3]),   .z3_imag(z_imag[3]),
        .z4_real(z_real[4]),   .z4_imag(z_imag[4]),
        .z5_real(z_real[5]),   .z5_imag(z_imag[5]),
        .z6_real(z_real[6]),   .z6_imag(z_imag[6]),
        .z7_real(z_real[7]),   .z7_imag(z_imag[7]),
        .z8_real(z_real[8]),   .z8_imag(z_imag[8]),
        .z9_real(z_real[9]),   .z9_imag(z_imag[9]),
        .z10_real(z_real[10]), .z10_imag(z_imag[10]),
        .z11_real(z_real[11]), .z11_imag(z_imag[11]),
        .z12_real(z_real[12]), .z12_imag(z_imag[12]),
        .z13_real(z_real[13]), .z13_imag(z_imag[13]),
        .z14_real(z_real[14]), .z14_imag(z_imag[14]),
        .z15_real(z_real[15]), .z15_imag(z_imag[15])
    );

    // --- Stage 2 ---
    FFT_Stage2_16Point ST2 (
        .z0_real(z_real[0]),   .z0_imag(z_imag[0]),
        .z1_real(z_real[1]),   .z1_imag(z_imag[1]),
        .z2_real(z_real[2]),   .z2_imag(z_imag[2]),
        .z3_real(z_real[3]),   .z3_imag(z_imag[3]),
        .z4_real(z_real[4]),   .z4_imag(z_imag[4]),
        .z5_real(z_real[5]),   .z5_imag(z_imag[5]),
        .z6_real(z_real[6]),   .z6_imag(z_imag[6]),
        .z7_real(z_real[7]),   .z7_imag(z_imag[7]),
        .z8_real(z_real[8]),   .z8_imag(z_imag[8]),
        .z9_real(z_real[9]),   .z9_imag(z_imag[9]),
        .z10_real(z_real[10]), .z10_imag(z_imag[10]),
        .z11_real(z_real[11]), .z11_imag(z_imag[11]),
        .z12_real(z_real[12]), .z12_imag(z_imag[12]),
        .z13_real(z_real[13]), .z13_imag(z_imag[13]),
        .z14_real(z_real[14]), .z14_imag(z_imag[14]),
        .z15_real(z_real[15]), .z15_imag(z_imag[15]),

        .a0_real(a_real[0]),   .a0_imag(a_imag[0]),
        .a1_real(a_real[1]),   .a1_imag(a_imag[1]),
        .a2_real(a_real[2]),   .a2_imag(a_imag[2]),
        .a3_real(a_real[3]),   .a3_imag(a_imag[3]),
        .a4_real(a_real[4]),   .a4_imag(a_imag[4]),
        .a5_real(a_real[5]),   .a5_imag(a_imag[5]),
        .a6_real(a_real[6]),   .a6_imag(a_imag[6]),
        .a7_real(a_real[7]),   .a7_imag(a_imag[7]),
        .a8_real(a_real[8]),   .a8_imag(a_imag[8]),
        .a9_real(a_real[9]),   .a9_imag(a_imag[9]),
        .a10_real(a_real[10]), .a10_imag(a_imag[10]),
        .a11_real(a_real[11]), .a11_imag(a_imag[11]),
        .a12_real(a_real[12]), .a12_imag(a_imag[12]),
        .a13_real(a_real[13]), .a13_imag(a_imag[13]),
        .a14_real(a_real[14]), .a14_imag(a_imag[14]),
        .a15_real(a_real[15]), .a15_imag(a_imag[15])
    );

    // --- Stage 3 ---
    FFT_Stage3_16Point ST3 (
        .a0_real(a_real[0]),   .a0_imag(a_imag[0]),
        .a1_real(a_real[1]),   .a1_imag(a_imag[1]),
        .a2_real(a_real[2]),   .a2_imag(a_imag[2]),
        .a3_real(a_real[3]),   .a3_imag(a_imag[3]),
        .a4_real(a_real[4]),   .a4_imag(a_imag[4]),
        .a5_real(a_real[5]),   .a5_imag(a_imag[5]),
        .a6_real(a_real[6]),   .a6_imag(a_imag[6]),
        .a7_real(a_real[7]),   .a7_imag(a_imag[7]),
        .a8_real(a_real[8]),   .a8_imag(a_imag[8]),
        .a9_real(a_real[9]),   .a9_imag(a_imag[9]),
        .a10_real(a_real[10]), .a10_imag(a_imag[10]),
        .a11_real(a_real[11]), .a11_imag(a_imag[11]),
        .a12_real(a_real[12]), .a12_imag(a_imag[12]),
        .a13_real(a_real[13]), .a13_imag(a_imag[13]),
        .a14_real(a_real[14]), .a14_imag(a_imag[14]),
        .a15_real(a_real[15]), .a15_imag(a_imag[15]),

        .xk0_real(xk0_real),   .xk0_imag(xk0_imag),
        .xk1_real(xk1_real),   .xk1_imag(xk1_imag),
        .xk2_real(xk2_real),   .xk2_imag(xk2_imag),
        .xk3_real(xk3_real),   .xk3_imag(xk3_imag),
        .xk4_real(xk4_real),   .xk4_imag(xk4_imag),
        .xk5_real(xk5_real),   .xk5_imag(xk5_imag),
        .xk6_real(xk6_real),   .xk6_imag(xk6_imag),
        .xk7_real(xk7_real),   .xk7_imag(xk7_imag),
        .xk8_real(xk8_real),   .xk8_imag(xk8_imag),
        .xk9_real(xk9_real),   .xk9_imag(xk9_imag),
        .xk10_real(xk10_real), .xk10_imag(xk10_imag),
        .xk11_real(xk11_real), .xk11_imag(xk11_imag),
        .xk12_real(xk12_real), .xk12_imag(xk12_imag),
        .xk13_real(xk13_real), .xk13_imag(xk13_imag),
        .xk14_real(xk14_real), .xk14_imag(xk14_imag),
        .xk15_real(xk15_real), .xk15_imag(xk15_imag)
    );

endmodule
