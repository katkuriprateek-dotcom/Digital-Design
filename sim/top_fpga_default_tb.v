`timescale 1ns / 1ps

module top_fpga_default_tb;

    reg clk;
    reg rst;

    integer i;
    integer timeout_count;

    reg [127:0] matrix_a_test;
    reg [127:0] matrix_b_test;

    wire [511:0] result_from_vio;

    assign result_from_vio[255:0] = dut.vio_inst.probe_in0;
    assign result_from_vio[511:256] = dut.vio_inst.probe_in1;

    top_fpga dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        timeout_count = 0;

        /*
            Matrix A  = [ 1   2   3   4  ]
                        | 5   6   7   8  |
                        | 9   10  11  12 |
                        [ 13  14  15  16 ] 
                        
            Matrix B  = [ 1  0  0  0 ]
                        | 0  1  0  0 |
                        | 0  0  1  0 |
                        [ 0  0  0  1 ]                       
        */

        // hex input
        matrix_a_test = 128'h100f0e0d0c0b0a090807060504030201;
        matrix_b_test = 128'h01000000010000000100000001000000;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        force dut.vio_inst.probe_out0 = matrix_a_test;
        force dut.vio_inst.probe_out1 = matrix_b_test;
        force dut.vio_inst.probe_out2 = 1'b0;

        repeat (2) @(negedge clk);
        force dut.vio_inst.probe_out2 = 1'b1;
        @(negedge clk);
        force dut.vio_inst.probe_out2 = 1'b0;

        $display("Running default 4x4 matrix multiplication...");

        while ((dut.vio_inst.probe_in2 !== 1'b1) &&
               (timeout_count < 30)) begin
            @(negedge clk);
            timeout_count = timeout_count + 1;
        end

        if (dut.vio_inst.probe_in2 !== 1'b1) begin
            $display("ERROR: RESULT TIMEOUT");
        end
        else begin
            $display("RESULT MATRIX C:");
            for (i = 0; i < 16; i = i + 1) begin
                $write("%0d\t", $signed(result_from_vio[32*i +: 32]));
                if ((i % 4) == 3)
                    $display("");
            end
        end

        $finish;
    end
endmodule
