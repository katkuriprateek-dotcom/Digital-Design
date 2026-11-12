
`timescale 1ns / 1ps

module sys_array_4x4(
    input wire clk,
    input wire rst,
    input wire clear,
    input wire [31:0] a_row_in,
    input wire [31:0] b_col_in,

    output wire [511:0] c_out
);

    // Internal data connections
    wire signed [7:0] a_wire [0:3][0:3];
    wire signed [7:0] b_wire [0:3][0:3];

    genvar i, j;

    // Generate 4x4 Processing Elements
    generate
        for (i = 0; i < 4; i = i + 1) begin : row
            for (j = 0; j < 4; j = j + 1) begin : col

                pe pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .clear(clear),
                    .a_in((j == 0) ? a_row_in[8*i +: 8] : a_wire[i][j-1]),
                    .b_in((i == 0) ? b_col_in[8*j +: 8] : b_wire[i-1][j]),
                    
                    .a_out(a_wire[i][j]),
                    .b_out(b_wire[i][j]),
                    .acc(c_out[32*(4*i+j) +: 32])
                );
            end
        end
    endgenerate
endmodule