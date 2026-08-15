`timescale 1ns/1ps
module FFT_tb;

// --- Parameters and Signals ---
parameter N = 1024;
localparam DATA_WIDTH = 16;
localparam FREQUENCY_BIN = 1; 

// Control 
reg clk = 0;
reg reset = 1;
reg start = 0;
wire done; 

// Data Input/Output Arrays
reg signed [DATA_WIDTH-1:0] x_real[0:N-1];
reg signed [DATA_WIDTH-1:0] x_imag[0:N-1];

wire signed [DATA_WIDTH-1:0] y_real[0:N-1];
wire signed [DATA_WIDTH-1:0] y_imag[0:N-1];

// Clock Generation (Period = 10 ns)
always #5 clk = ~clk;

real cosine_val;
real sinc_sample;
integer k; 
real local_CENTER; 
real local_SINC_WIDTH; 
real local_x_arg; 


// Define the Sinc function 
function automatic real sinc_func_real (input real x);
    localparam real PI = 3.141592653589793;
    
    // Handle the singularity: sinc(0) = 1.0
    if (x == 0.0) begin
        return 1.0;
    end else begin
        return $sin(x * PI) / (x * PI);
    end
endfunction


// =========================================================================
// INPUT GENERATION: SINC PULSE 
// =========================================================================
initial begin
    
    local_CENTER = (N / 2.0);    
    local_SINC_WIDTH = 2.0;   // <-- makes sample step = 0.5
    
    $display("\n--- Sinc Function Input Generation (N=%0d) ---", N);

    for (k = 0; k < N; k = k + 1) begin
        
        // x increases by 0.5
        local_x_arg = (k - local_CENTER) / local_SINC_WIDTH;
        
        // NumPy-like sinc
        sinc_sample = sinc_func_real(local_x_arg);
        
        // Apply amplitude
        cosine_val = 0.5 * sinc_sample;
        
        // Fixed-point conversion
        x_real[k] = $rtoi(32767.0 * cosine_val);
        x_imag[k] = 16'sd0; 

        $display("k=%0d, x=%f, sinc=%f, Q1.15=%d",
                 k, local_x_arg, sinc_sample, x_real[k]);
    end

    $display("--------------------------------------------------\n");
end



// --- Instantiate Synchronous FFT Module ---
FFT_Q1p15 #(
    .N(N), 
    .DATA_WIDTH(DATA_WIDTH)
) fft_inst (
    .clk(clk),
    .reset(reset),
    .start(start),
    .done(done),
    .x_real(x_real), // Connects the entire array
    .x_imag(x_imag), // Connects the entire array
    .y_real(y_real), // Connects the entire array
    .y_imag(y_imag)  // Connects the entire array
);

// --- Simulation Control ---
initial begin
    integer outfile;
    integer i; // Declare i locally for this block
    
    // 1. Reset and wait for 2 clock cycles
    #15; // Wait past the first clock edge
    reset = 0; // Release reset
    
    // 2. Start FFT on the next positive clock edge (single-cycle pulse)
    @(posedge clk) start = 1;
    @(posedge clk) start = 0; 

    $display("FFT started. N=%d. Waiting for 'done' signal...", N);
    
    // Wait until 'done' is asserted by the FFT module
    @(posedge done);

    // Add a small delay to ensure the final registers update
    #10; 

    // Write the computed FFT output
    outfile = $fopen("fft_N_output.txt","w");
    
    $display("\n--- FFT Results ---");
    for (i=0; i<N; i=i+1) begin
        $display("Bin %0d: Real=%d, Imag=%d", i, y_real[i], y_imag[i]);
        $fwrite(outfile, "%d %d\n", y_real[i], y_imag[i]);
    end
    
    $fclose(outfile);
    $display("\nFFT done, results (%d points) written to fft_final_output.txt", N);
    $finish;
end

endmodule