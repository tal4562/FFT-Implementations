`timescale 1ns/1ps
module BitReverse #(
    parameter N = 32
)(
    input  wire signed [15:0] x_real [0:N-1],
    input  wire signed [15:0] x_imag [0:N-1],
    output wire signed [15:0] y_real [0:N-1],
    output wire signed [15:0] y_imag [0:N-1]
);

localparam M = $clog2(N);

function automatic integer bit_reverse(input integer val);
    integer i, r;
    begin
        r = 0;
        for (i = 0; i < M; i=i+1) begin
            r = (r << 1) | (val & 1);
            val = val >> 1;
        end
        bit_reverse = r;
    end
endfunction

genvar k;
generate
    for (k = 0; k < N; k=k+1) begin : BR
        localparam integer r = bit_reverse(k);
        assign y_real[r] = x_real[k];
        assign y_imag[r] = x_imag[k];
    end
endgenerate

endmodule
