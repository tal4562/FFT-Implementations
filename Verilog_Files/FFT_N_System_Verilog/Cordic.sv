// ===============================================================
//   CORDIC ROTATION MODE — Works for θ ∈ [−90°, +90°]
//   Inputs/outputs are Q1.15
//   theta is normalized as: Q = theta_rad / π (your rule)
// ===============================================================
module cordic_rot (
    input  wire signed [15:0] theta,  // θ/π in Q1.15, valid: ±16384
    output wire signed [15:0] cos_out,
    output wire signed [15:0] sin_out
);

    localparam ITER = 15;

    // Pre-computed arctan(2^-i) normalized by π (i.e. atan/π in Q1.15)
    // Example: atan(1)/π = 0.25 → 8192 in Q1.15 → 0x2000
    reg signed [15:0] ATAN [0:14];
    initial begin
        ATAN[0]  = 16'sh2000; // atan(1)/π
        ATAN[1]  = 16'sh12E4;
        ATAN[2]  = 16'sh09FB;
        ATAN[3]  = 16'sh0511;
        ATAN[4]  = 16'sh028B;
        ATAN[5]  = 16'sh0146;
        ATAN[6]  = 16'sh00A3;
        ATAN[7]  = 16'sh0051;
        ATAN[8]  = 16'sh0029;
        ATAN[9]  = 16'sh0014;
        ATAN[10] = 16'sh000A;
        ATAN[11] = 16'sh0005;
        ATAN[12] = 16'sh0003;
        ATAN[13] = 16'sh0001;
        ATAN[14] = 16'sh0001;
    end

    // Gain-compensation: 1/K ≈ 0.607252935 → 0.6073 in Q1.15 = 0x4DBA
    localparam signed [15:0] X0 = 16'sh4DBA; 
    localparam signed [15:0] Y0 = 16'sh0000;

    wire signed [15:0] x [0:ITER];
    wire signed [15:0] y [0:ITER];
    wire signed [15:0] z [0:ITER];

    assign x[0] = X0;
    assign y[0] = Y0;
    assign z[0] = theta;

    genvar i;
    generate
        for (i = 0; i < ITER; i = i + 1) begin : stage
            wire signed [15:0] di = z[i][15] ? -16'sd1 : 16'sd1;

            wire signed [15:0] x_shift = x[i] >>> i;
            wire signed [15:0] y_shift = y[i] >>> i;

            assign x[i+1] = x[i] - di * y_shift;
            assign y[i+1] = y[i] + di * x_shift;
            assign z[i+1] = z[i] - di * ATAN[i];
        end
    endgenerate

    assign cos_out = x[ITER];
    assign sin_out = y[ITER];

endmodule
