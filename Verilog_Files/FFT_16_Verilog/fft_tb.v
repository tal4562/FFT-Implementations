`timescale 1ns / 1ps

module fft_tb;

    localparam DATA_WIDTH = 16;
    localparam N = 16;

    // --- 1. Internal Data Arrays (REGs for assignment in initial block) ---
    reg signed [DATA_WIDTH-1:0] x_data_real [0:N-1];
    reg signed [DATA_WIDTH-1:0] x_data_imag [0:N-1];

    // --- 2. DUT Port Signals (WIRES connecting to the DUT) ---
    wire [DATA_WIDTH-1:0] x_in0_real, x_in0_imag, x_in1_real, x_in1_imag, x_in2_real, x_in2_imag;
    wire [DATA_WIDTH-1:0] x_in3_real, x_in3_imag, x_in4_real, x_in4_imag, x_in5_real, x_in5_imag;
    wire [DATA_WIDTH-1:0] x_in6_real, x_in6_imag, x_in7_real, x_in7_imag, x_in8_real, x_in8_imag;
    wire [DATA_WIDTH-1:0] x_in9_real, x_in9_imag, x_in10_real, x_in10_imag, x_in11_real, x_in11_imag;
    wire [DATA_WIDTH-1:0] x_in12_real, x_in12_imag, x_in13_real, x_in13_imag, x_in14_real, x_in14_imag;
    wire [DATA_WIDTH-1:0] x_in15_real, x_in15_imag;

    wire [DATA_WIDTH-1:0] xk0_real, xk0_imag, xk1_real, xk1_imag, xk2_real, xk2_imag;
    wire [DATA_WIDTH-1:0] xk3_real, xk3_imag, xk4_real, xk4_imag, xk5_real, xk5_imag;
    wire [DATA_WIDTH-1:0] xk6_real, xk6_imag, xk7_real, xk7_imag, xk8_real, xk8_imag;
    wire [DATA_WIDTH-1:0] xk9_real, xk9_imag, xk10_real, xk10_imag, xk11_real, xk11_imag;
    wire [DATA_WIDTH-1:0] xk12_real, xk12_imag, xk13_real, xk13_imag, xk14_real, xk14_imag;
    wire [DATA_WIDTH-1:0] xk15_real, xk15_imag;

    // --- 3. Arrays to simplify display ---
    wire signed [DATA_WIDTH-1:0] xk_result_real [0:N-1];
    wire signed [DATA_WIDTH-1:0] xk_result_imag [0:N-1];

    // --- 4. Mapping Inputs ---
    assign x_in0_real  = x_data_real[0];   assign x_in0_imag  = x_data_imag[0];
    assign x_in1_real  = x_data_real[1];   assign x_in1_imag  = x_data_imag[1];
    assign x_in2_real  = x_data_real[2];   assign x_in2_imag  = x_data_imag[2];
    assign x_in3_real  = x_data_real[3];   assign x_in3_imag  = x_data_imag[3];
    assign x_in4_real  = x_data_real[4];   assign x_in4_imag  = x_data_imag[4];
    assign x_in5_real  = x_data_real[5];   assign x_in5_imag  = x_data_imag[5];
    assign x_in6_real  = x_data_real[6];   assign x_in6_imag  = x_data_imag[6];
    assign x_in7_real  = x_data_real[7];   assign x_in7_imag  = x_data_imag[7];
    assign x_in8_real  = x_data_real[8];   assign x_in8_imag  = x_data_imag[8];
    assign x_in9_real  = x_data_real[9];   assign x_in9_imag  = x_data_imag[9];
    assign x_in10_real = x_data_real[10];  assign x_in10_imag = x_data_imag[10];
    assign x_in11_real = x_data_real[11];  assign x_in11_imag = x_data_imag[11];
    assign x_in12_real = x_data_real[12];  assign x_in12_imag = x_data_imag[12];
    assign x_in13_real = x_data_real[13];  assign x_in13_imag = x_data_imag[13];
    assign x_in14_real = x_data_real[14];  assign x_in14_imag = x_data_imag[14];
    assign x_in15_real = x_data_real[15];  assign x_in15_imag = x_data_imag[15];

    // --- 5. Mapping Outputs ---
    assign xk_result_real[0]  = xk0_real;   assign xk_result_imag[0]  = xk0_imag;
    assign xk_result_real[1]  = xk1_real;   assign xk_result_imag[1]  = xk1_imag;
    assign xk_result_real[2]  = xk2_real;   assign xk_result_imag[2]  = xk2_imag;
    assign xk_result_real[3]  = xk3_real;   assign xk_result_imag[3]  = xk3_imag;
    assign xk_result_real[4]  = xk4_real;   assign xk_result_imag[4]  = xk4_imag;
    assign xk_result_real[5]  = xk5_real;   assign xk_result_imag[5]  = xk5_imag;
    assign xk_result_real[6]  = xk6_real;   assign xk_result_imag[6]  = xk6_imag;
    assign xk_result_real[7]  = xk7_real;   assign xk_result_imag[7]  = xk7_imag;
    assign xk_result_real[8]  = xk8_real;   assign xk_result_imag[8]  = xk8_imag;
    assign xk_result_real[9]  = xk9_real;   assign xk_result_imag[9]  = xk9_imag;
    assign xk_result_real[10] = xk10_real;  assign xk_result_imag[10] = xk10_imag;
    assign xk_result_real[11] = xk11_real;  assign xk_result_imag[11] = xk11_imag;
    assign xk_result_real[12] = xk12_real;  assign xk_result_imag[12] = xk12_imag;
    assign xk_result_real[13] = xk13_real;  assign xk_result_imag[13] = xk13_imag;
    assign xk_result_real[14] = xk14_real;  assign xk_result_imag[14] = xk14_imag;
    assign xk_result_real[15] = xk15_real;  assign xk_result_imag[15] = xk15_imag;

    // --- 6. Instantiate DUT ---
    FFT_16Point_Pipeline DUT (
        .x_in0_real(x_in0_real), .x_in0_imag(x_in0_imag),
        .x_in1_real(x_in1_real), .x_in1_imag(x_in1_imag),
        .x_in2_real(x_in2_real), .x_in2_imag(x_in2_imag),
        .x_in3_real(x_in3_real), .x_in3_imag(x_in3_imag),
        .x_in4_real(x_in4_real), .x_in4_imag(x_in4_imag),
        .x_in5_real(x_in5_real), .x_in5_imag(x_in5_imag),
        .x_in6_real(x_in6_real), .x_in6_imag(x_in6_imag),
        .x_in7_real(x_in7_real), .x_in7_imag(x_in7_imag),
        .x_in8_real(x_in8_real), .x_in8_imag(x_in8_imag),
        .x_in9_real(x_in9_real), .x_in9_imag(x_in9_imag),
        .x_in10_real(x_in10_real), .x_in10_imag(x_in10_imag),
        .x_in11_real(x_in11_real), .x_in11_imag(x_in11_imag),
        .x_in12_real(x_in12_real), .x_in12_imag(x_in12_imag),
        .x_in13_real(x_in13_real), .x_in13_imag(x_in13_imag),
        .x_in14_real(x_in14_real), .x_in14_imag(x_in14_imag),
        .x_in15_real(x_in15_real), .x_in15_imag(x_in15_imag),

        .xk0_real(xk0_real), .xk0_imag(xk0_imag),
        .xk1_real(xk1_real), .xk1_imag(xk1_imag),
        .xk2_real(xk2_real), .xk2_imag(xk2_imag),
        .xk3_real(xk3_real), .xk3_imag(xk3_imag),
        .xk4_real(xk4_real), .xk4_imag(xk4_imag),
        .xk5_real(xk5_real), .xk5_imag(xk5_imag),
        .xk6_real(xk6_real), .xk6_imag(xk6_imag),
        .xk7_real(xk7_real), .xk7_imag(xk7_imag),
        .xk8_real(xk8_real), .xk8_imag(xk8_imag),
        .xk9_real(xk9_real), .xk9_imag(xk9_imag),
        .xk10_real(xk10_real), .xk10_imag(xk10_imag),
        .xk11_real(xk11_real), .xk11_imag(xk11_imag),
        .xk12_real(xk12_real), .xk12_imag(xk12_imag),
        .xk13_real(xk13_real), .xk13_imag(xk13_imag),
        .xk14_real(xk14_real), .xk14_imag(xk14_imag),
        .xk15_real(xk15_real), .xk15_imag(xk15_imag)
    );

    integer n;
    integer outfile;

    initial begin
        // --- VCD dump for waveform viewing ---
        $dumpfile("fft.vcd");
        $dumpvars(0, fft_tb);

        // --- Open output file ---
        outfile = $fopen("fft_16_output.txt", "w");

        // --- Initialize inputs to 0 ---
        for (n = 0; n < N; n = n + 1) begin
            x_data_real[n] = 16'sh0000;
            x_data_imag[n] = 16'sh0000;
        end

        // --- 0.5 * cos(2*pi*n/16) input in Q1.15 ---
        x_data_real[0]  = 16'sh4000;  // 0.5
        x_data_real[1]  = 16'sh3B21;
        x_data_real[2]  = 16'sh2D41;
        x_data_real[3]  = 16'sh187E;
        x_data_real[4]  = 16'sh0000;
        x_data_real[5]  = -16'sh187E;
        x_data_real[6]  = -16'sh2D41;
        x_data_real[7]  = -16'sh3B21;
        x_data_real[8]  = -16'sh4000;
        x_data_real[9]  = -16'sh3B21;
        x_data_real[10] = -16'sh2D41;
        x_data_real[11] = -16'sh187E;
        x_data_real[12] = 16'sh0000;
        x_data_real[13] = 16'sh187E;
        x_data_real[14] = 16'sh2D41;
        x_data_real[15] = 16'sh3B21;

        // --- Wait for FFT to process (pipelined) ---
        #10;

        // --- Display and write results ---
        $display("--- FFT Result ---");
        for (n = 0; n < N; n = n + 1) begin
            $display("Xk[%0d] = %h + j%h", n, xk_result_real[n], xk_result_imag[n]);
            $fwrite(outfile, "%h %h\n", xk_result_real[n], xk_result_imag[n]);
        end

        // --- Close file and finish simulation ---
        $fclose(outfile);
        $finish;
    end


endmodule
