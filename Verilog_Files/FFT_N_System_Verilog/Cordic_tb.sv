`timescale 1ns/1ps
module cordic_tb;

    logic signed [15:0] theta;
    wire  signed [15:0] cos_q;
    wire  signed [15:0] sin_q;

    cordic_rot dut (
        .theta  (theta),
        .cos_out(cos_q),
        .sin_out(sin_q)
    );

    real theta_deg, theta_rad;
    real cos_ref, sin_ref;
    real cos_dut, sin_dut;
    integer i;

    // Convert Q1.15 → real
    function real q_to_real(input signed [15:0] q);
        q_to_real = q / 32768.0;
    endfunction

    // Convert degrees → Q1.15 normalized by π
    function signed [15:0] deg_to_q(input real d);
        real rad;
        real qf;
        begin
            rad = d * 3.141592653589793 / 180.0;
            qf  = rad / 3.141592653589793;   // θ/π
            deg_to_q = $rtoi(qf * 32768.0);
        end
    endfunction

    initial begin
        $display("  CORDIC TEST [-90°, +90°]  ");
        $display("--------------------------------------------");

        for (i = -89; i <= 89; i = i + 1) begin
            theta_deg = i;
            theta = deg_to_q(theta_deg);

            theta_rad = theta_deg * 3.141592653589793 / 180.0;

            cos_ref = $cos(theta_rad);
            sin_ref = $sin(theta_rad);

            #1;

            cos_dut = q_to_real(cos_q);
            sin_dut = q_to_real(sin_q);

            if (($abs(cos_dut - cos_ref) > 1e-4) ||
                ($abs(sin_dut - sin_ref) > 1e-4))
            begin
                $display("ERROR at %0d deg:", i);
                $display("  COS: DUT=%f REF=%f", cos_dut, cos_ref);
                $display("  SIN: DUT=%f REF=%f", sin_dut, sin_ref);
            end
        end

        $display("Test complete.");
        $finish;
    end

endmodule
