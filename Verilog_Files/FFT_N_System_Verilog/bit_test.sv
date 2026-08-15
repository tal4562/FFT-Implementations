`timescale 1ns/1ps

module BitReverse_tb;

    // Parameters
    parameter int N = 1024;

    // Inputs
    logic signed [15:0] x_real [0:N-1];
    logic signed [15:0] x_imag [0:N-1];

    // Outputs
    logic signed [15:0] y_real [0:N-1];
    logic signed [15:0] y_imag [0:N-1];

    // Instantiate BitReverse
    BitReverse #(N) uut (
        .x_real(x_real),
        .x_imag(x_imag),
        .y_real(y_real),
        .y_imag(y_imag)
    );

    int i, b, reversed_index;
    int errors;

    initial begin
        // --- Initialize inputs ---
        for (i = 0; i < N; i++) begin
            x_real[i] = i;       // simple test: real = index
            x_imag[i] = -i;      // simple test: imag = -index
        end

        #1; // wait a delta cycle for combinational outputs

        $display("=== BIT REVERSE TEST ===");

        errors = 0;
        for (i = 0; i < N; i++) begin
            // Compute expected bit-reversed index
            reversed_index = 0;
            for (b = 0; b < $clog2(N); b++) begin
                reversed_index = (reversed_index << 1) | ((i >> b) & 1);
            end

            // Check outputs
            if (y_real[reversed_index] !== x_real[i] || y_imag[reversed_index] !== x_imag[i]) begin
                $display("ERROR at index %0d: got (%0d,%0d), expected (%0d,%0d)",
                         reversed_index, y_real[reversed_index], y_imag[reversed_index],
                         x_real[i], x_imag[i]);
                errors++;
            end
        end

        if (errors == 0)
            $display("All outputs correct!");
        else
            $display("Total errors: %0d", errors);

        $finish;
    end

endmodule
