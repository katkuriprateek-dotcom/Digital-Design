
`timescale 1ns / 1ps

module top_fpga (
    input wire clk,
    input wire rst
);

    // VIO INPUTS: LAPTOP TO FPGA
    wire [127:0] matrix_a;
    wire [127:0] matrix_b;
    wire start;

    // MATRIX CONTROLLER SIGNALS
    wire clear;

    wire [31:0] a_row_in;
    wire [31:0] b_col_in;

    wire busy;
    wire done;

    // SYSTOLIC ARRAY OUTPUT
    wire [511:0] c_out;

    // STORED RESULTS
    wire [511:0] result_out;
    wire result_valid;

    // 5. VIO IP
    vio_matrix vio_inst (
        .clk(clk),

        // VIO outputs: Input data to FPGA
        .probe_out0(matrix_a),
        .probe_out1(matrix_b),
        .probe_out2(start),

        // VIO inputs: FPGA outputs to VIO
        .probe_in0(result_out[255:0]),
        .probe_in1(result_out[511:256]),
        .probe_in2(result_valid),
        .probe_in3(busy)
    );

    // 6. MATRIX SKEW CONTROLLER
    matrix_skew_controller controller_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .matrix_a(matrix_a),
        .matrix_b(matrix_b),
        .clear(clear),
        .a_row_in(a_row_in),
        .b_col_in(b_col_in),
        .busy(busy),
        .done(done),
        .c_out(c_out)
    );

    // 7. RESULT STORAGE
    result_storage result_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .c_in(c_out),
        .result_out(result_out),
        .result_valid(result_valid)
    );
endmodule
