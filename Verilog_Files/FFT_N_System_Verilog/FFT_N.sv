`timescale 1ns/1ps

// =========================================================================
// MODULE 1: Butterfly_Twiddle (Sub-module - The Arithmetic Core)
// =========================================================================
// Radix-2 Decimation-in-Frequency (DIF) Butterfly
// Inputs/Outputs are assumed to be in Q1.15 format (1 sign bit, 1 integer bit, 15 fraction bits)

module Butterfly_Twiddle (
    input  signed [15:0] real1, imag1,
    input  signed [15:0] real2, imag2,
    input  signed [15:0] twiddle_real, twiddle_imag,
    output signed [15:0] Y_real, Y_imag,
    output signed [15:0] Z_real, Z_imag
);

    // Complex multiply (Q2.30)
    wire signed [31:0] P_r_full = real2 * twiddle_real - imag2 * twiddle_imag;
    wire signed [31:0] P_i_full = real2 * twiddle_imag + imag2 * twiddle_real;

    // Rounding constant = 2^14 = 0x00004000
    wire signed [31:0] P_r_rounded = P_r_full + 32'sh00004000;
    wire signed [31:0] P_i_rounded = P_i_full + 32'sh00004000;

    // Slice: [30:15]
    wire signed [15:0] P_real = P_r_rounded[30:15];
    wire signed [15:0] P_imag = P_i_rounded[30:15];

    // Butterfly
    wire signed [16:0] Y_r_full = real1 + P_real;
    wire signed [16:0] Y_i_full = imag1 + P_imag;
    wire signed [16:0] Z_r_full = real1 - P_real;
    wire signed [16:0] Z_i_full = imag1 - P_imag;

    // Scale (divide by 2)
    assign Y_real = Y_r_full[16:1];
    assign Y_imag = Y_i_full[16:1];
    assign Z_real = Z_r_full[16:1];
    assign Z_imag = Z_i_full[16:1];

endmodule

// =========================================================================
// MODULE 2: FFT_Q1p15 (Top-Level Module - Stages and Control)
//   - Synthesizable, pipelined: 2 cycles per butterfly (register inputs, write outputs)
//   - INIT (bit-reverse) performed over N cycles
// =========================================================================

module FFT_Q1p15 #(
    parameter N = 16,
    parameter DATA_WIDTH = 16
)(
    // Control Signals
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     start,
    output reg                      done,

    // Data Input/Output (Bit-Reversed Input handled in INIT loop)
    input  wire signed [DATA_WIDTH-1:0] x_real [0:N-1],
    input  wire signed [DATA_WIDTH-1:0] x_imag [0:N-1],

    // Output (in natural order)
    output reg signed [DATA_WIDTH-1:0] y_real [0:N-1],
    output reg signed [DATA_WIDTH-1:0] y_imag [0:N-1]
);

localparam STAGES = $clog2(N);
localparam ADDR_WIDTH = $clog2(N);
real PI = 3.141592653589793;

// --- Embedded Twiddle Factor LUT (Q1.15) ---
reg signed [DATA_WIDTH-1:0] tw_real [0:N/2-1];
reg signed [DATA_WIDTH-1:0] tw_imag [0:N/2-1];

integer k;
initial begin
    $display("\n--- Twiddle Factor LUT (N=%0d) ---", N);
    for (k=0; k<N/2; k=k+1) begin
        // W_N^k = cos(-2pi*k/N) + j*sin(-2pi*k/N)
        tw_real[k] = $rtoi(32767.0 * $cos(2.0*PI*k/N));
        tw_imag[k] = $rtoi(-32767.0 * $sin(2.0*PI*k/N));
        $display("W_N^%0d: Real (Q1.15)= %d, Imag (Q1.15)= %d", k, tw_real[k], tw_imag[k]);
    end
    $display("----------------------------------\n");
end

// --- Internal Ping-Pong Buffers (17 bits: Q1.15 + 1 overflow bit) ---
reg signed [DATA_WIDTH:0] stage_real_A [0:N-1];
reg signed [DATA_WIDTH:0] stage_imag_A [0:N-1];
reg signed [DATA_WIDTH:0] stage_real_B [0:N-1];
reg signed [DATA_WIDTH:0] stage_imag_B [0:N-1];

// FSM States
localparam STATE_IDLE    = 3'd0,
           STATE_INIT    = 3'd1,   // Bit reversal over N cycles
           STATE_COMPUTE = 3'd2,   // 2 cycles per butterfly (register inputs, write outputs)
           STATE_FINISH  = 3'd3;

reg [2:0] state;
reg [ADDR_WIDTH:0] stage_count;      // track 1..STAGES
reg [ADDR_WIDTH-1:0] butterfly_index; // 0..N-1 (address pointer)
reg compute_phase;                   // 0 = capture inputs, 1 = write outputs

// Butterfly I/O
wire signed [DATA_WIDTH-1:0] butterfly_Y_r, butterfly_Y_i;
wire signed [DATA_WIDTH-1:0] butterfly_Z_r, butterfly_Z_i;
reg signed [DATA_WIDTH-1:0] butterfly_X1_r, butterfly_X1_i;
reg signed [DATA_WIDTH-1:0] butterfly_X2_r, butterfly_X2_i;
reg signed [DATA_WIDTH-1:0] twiddle_Wr_reg, twiddle_Wi_reg;

// Internal temporaries (combinational use)
integer s;
integer half_step;
integer tw_increment;
integer idx1, idx2;
integer tw_idx;
wire group_start;
wire [ADDR_WIDTH-1:0] bitrev_addr;

// bit_reverse function (combinational)
function [ADDR_WIDTH-1:0] bit_reverse;
    input [ADDR_WIDTH-1:0] in;
    integer ii;
    begin
        for (ii = 0; ii < ADDR_WIDTH; ii = ii + 1)
            bit_reverse[ii] = in[ADDR_WIDTH-1-ii];
    end
endfunction

// instantiate butterfly (combinational)
Butterfly_Twiddle U_BUTTERFLY (
    .real1(butterfly_X1_r), .imag1(butterfly_X1_i),
    .real2(butterfly_X2_r), .imag2(butterfly_X2_i),
    .twiddle_real(twiddle_Wr_reg), .twiddle_imag(twiddle_Wi_reg),
    .Y_real(butterfly_Y_r), .Y_imag(butterfly_Y_i),
    .Z_real(butterfly_Z_r), .Z_imag(butterfly_Z_i)
);

// group_start: true when butterfly_index is beginning of a butterfly group for current half_step
assign group_start = ((butterfly_index % (2* (1 << ( (stage_count==0) ? 0 : stage_count-1 ) ))) < (1 << ( (stage_count==0) ? 0 : stage_count-1 )));

// compute bitrev for INIT stage
assign bitrev_addr = bit_reverse(butterfly_index);

// --------------------------------------------------------------------------
// Synchronous FSM
// --------------------------------------------------------------------------
integer tmp_half;
always @(posedge clk) begin
    // default
    done <= 1'b0;

    if (reset) begin
        state <= STATE_IDLE;
        stage_count <= 0;
        butterfly_index <= 0;
        compute_phase <= 0;
        // (Optionally clear RAMs)
    end else begin
        case (state)
            // ----------------
            STATE_IDLE: begin
                if (start) begin
                    state <= STATE_INIT;
                    butterfly_index <= 0;
                    compute_phase <= 0;
                    stage_count <= 0;
                end
            end

            // ----------------
            STATE_INIT: begin
                // Do one element per cycle: bit-reversed write into stage A
                stage_real_A[butterfly_index] <= { x_real[bitrev_addr][DATA_WIDTH-1], x_real[bitrev_addr] }; // sign-extend into 17 bits
                stage_imag_A[butterfly_index] <= { x_imag[bitrev_addr][DATA_WIDTH-1], x_imag[bitrev_addr] };

                if (butterfly_index == N-1) begin
                    // finished init, start first stage
                    stage_count <= 1;
                    butterfly_index <= 0;
                    compute_phase <= 0;
                    state <= STATE_COMPUTE;
                end else begin
                    butterfly_index <= butterfly_index + 1;
                end
            end

            // ----------------
            STATE_COMPUTE: begin
                // s = stage_count - 1  (0-based stage)
                s = stage_count - 1;
                tmp_half = (1 << s);
                half_step = tmp_half;
                tw_increment = N >> (s+1);

                idx1 = butterfly_index;
                idx2 = butterfly_index + half_step;

                if (compute_phase == 0) begin
                    // Phase 0: capture inputs and twiddle into registers (one cycle)
                    // Determine whether we are reading from A or B depending on s parity
                    if ((s & 1) == 1) begin
                        // odd stage: read from B
                        butterfly_X1_r <= stage_real_B[idx1][DATA_WIDTH-1:0];
                        butterfly_X1_i <= stage_imag_B[idx1][DATA_WIDTH-1:0];
                        butterfly_X2_r <= stage_real_B[idx2][DATA_WIDTH-1:0];
                        butterfly_X2_i <= stage_imag_B[idx2][DATA_WIDTH-1:0];
                    end else begin
                        // even stage: read from A
                        butterfly_X1_r <= stage_real_A[idx1][DATA_WIDTH-1:0];
                        butterfly_X1_i <= stage_imag_A[idx1][DATA_WIDTH-1:0];
                        butterfly_X2_r <= stage_real_A[idx2][DATA_WIDTH-1:0];
                        butterfly_X2_i <= stage_imag_A[idx2][DATA_WIDTH-1:0];
                    end

                    // compute twiddle index for this butterfly (even if this is not a group_start, value ok)
                    tw_idx = (butterfly_index & (half_step - 1)) * tw_increment;
                    twiddle_Wr_reg <= tw_real[tw_idx];
                    twiddle_Wi_reg <= tw_imag[tw_idx];

                    // move to write phase next cycle
                    compute_phase <= 1'b1;
                end else begin
                    // Phase 1: write outputs (butterfly outputs correspond to inputs captured previous cycle)
                    if ((butterfly_index % (2*half_step)) < half_step) begin
                        // this is the start of a group -> perform butterfly write
                        if ((s & 1) == 1) begin
                            // odd stage: write to A
                            stage_real_A[idx1] <= {butterfly_Y_r[DATA_WIDTH-1], butterfly_Y_r};
                            stage_imag_A[idx1] <= {butterfly_Y_i[DATA_WIDTH-1], butterfly_Y_i};
                            stage_real_A[idx2] <= {butterfly_Z_r[DATA_WIDTH-1], butterfly_Z_r};
                            stage_imag_A[idx2] <= {butterfly_Z_i[DATA_WIDTH-1], butterfly_Z_i};
                        end else begin
                            // even stage: write to B
                            stage_real_B[idx1] <= {butterfly_Y_r[DATA_WIDTH-1], butterfly_Y_r};
                            stage_imag_B[idx1] <= {butterfly_Y_i[DATA_WIDTH-1], butterfly_Y_i};
                            stage_real_B[idx2] <= {butterfly_Z_r[DATA_WIDTH-1], butterfly_Z_r};
                            stage_imag_B[idx2] <= {butterfly_Z_i[DATA_WIDTH-1], butterfly_Z_i};
                        end
                    end
                    // advance index and return to capture phase
                    if (butterfly_index == N-1) begin
                        // end of stage
                        if (stage_count == STAGES) begin
                            state <= STATE_FINISH;
                        end else begin
                            stage_count <= stage_count + 1;
                            butterfly_index <= 0;
                            compute_phase <= 0;
                        end
                    end else begin
                        butterfly_index <= butterfly_index + 1;
                        compute_phase <= 1'b0;
                    end
                end
            end

            // ----------------
            STATE_FINISH: begin
                // Choose final buffer depending on STAGES parity:
                // if STAGES is even -> final results in A (we started with A), else in B.
                if ((STAGES % 2) == 0) begin
                    for (k = 0; k < N; k = k + 1) begin
                        y_real[k] <= stage_real_A[k][DATA_WIDTH-1:0];
                        y_imag[k] <= stage_imag_A[k][DATA_WIDTH-1:0];
                    end
                end else begin
                    for (k = 0; k < N; k = k + 1) begin
                        y_real[k] <= stage_real_B[k][DATA_WIDTH-1:0];
                        y_imag[k] <= stage_imag_B[k][DATA_WIDTH-1:0];
                    end
                end
                done <= 1'b1;
                state <= STATE_IDLE;
            end

            // ----------------
            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule
