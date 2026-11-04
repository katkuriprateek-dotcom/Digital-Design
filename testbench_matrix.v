`include "module.v"

`timescale 1ns / 1ps

module tb_sys_array_4x4;

    reg clk;
    reg rst;
    reg clear;
    reg [31:0] a_row_in;
    reg [31:0] b_col_in;
    wire [511:0] c_out;

    reg signed [7:0] matrix_a [0:3][0:3];
    reg signed [7:0] matrix_b [0:3][0:3];
    reg signed [31:0] actual;
    integer cycle;
    integer row;
    integer col;

    sys_array_4x4 uut (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .a_row_in(a_row_in),
        .b_col_in(b_col_in),
        .c_out(c_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_sys_array_4x4);
        clk = 0;
        rst = 1;
        clear = 0;
        a_row_in = 0;
        b_col_in = 0;
        actual = 0;

        matrix_a[0][0] = 3;  matrix_a[0][1] = -2; matrix_a[0][2] = 1; matrix_a[0][3] = 2;
        matrix_a[1][0] = 1;  matrix_a[1][1] = 2;  matrix_a[1][2] = 2; matrix_a[1][3] = -1;
        matrix_a[2][0] = -4; matrix_a[2][1] = 3;  matrix_a[2][2] = 7; matrix_a[2][3] = 8;
        matrix_a[3][0] = 4;  matrix_a[3][1] = -8; matrix_a[3][2] = 3; matrix_a[3][3] = 5;

        matrix_b[0][0] = 3;  matrix_b[0][1] = 5;  matrix_b[0][2] = 7; matrix_b[0][3] = -6;
        matrix_b[1][0] = -4; matrix_b[1][1] = 3;  matrix_b[1][2] = 8; matrix_b[1][3] = 1;
        matrix_b[2][0] = 4;  matrix_b[2][1] = 2;  matrix_b[2][2] = 0; matrix_b[2][3] = 9;
        matrix_b[3][0] = -2; matrix_b[3][1] = -3; matrix_b[3][2] = 3; matrix_b[3][3] = -2;

        repeat (2) @(negedge clk);
        rst = 0;
        clear = 1;
        @(negedge clk);
        clear = 0;

        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
            for (row = 0; row < 4; row = row + 1) begin
                if (cycle >= row && cycle - row < 4)
                    a_row_in[8*row +: 8] = matrix_a[row][cycle - row];
                else
                    a_row_in[8*row +: 8] = 0;
            end

            for (col = 0; col < 4; col = col + 1) begin
                if (cycle >= col && cycle - col < 4)
                    b_col_in[8*col +: 8] = matrix_b[cycle - col][col];
                else
                    b_col_in[8*col +: 8] = 0;
            end
            @(negedge clk);
        end

        a_row_in = 0;
        b_col_in = 0;
        repeat (4) @(negedge clk);

        for (row = 0; row < 4; row = row + 1) begin
            for (col = 0; col < 4; col = col + 1) begin
                actual = $signed(c_out[32*(4*row + col) +: 32]);
                $display("C[%0d][%0d] = %0d", row, col, actual);
                #1;
            end
        end

        #30;
        $finish;
    end

endmodule
