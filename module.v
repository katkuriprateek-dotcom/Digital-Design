module Topmodule (
    input clk,
    input rst, 
    input clear ,
    input signed [7:0] a_in , 
    input signed [7:0] b_in,
    output reg signed [31:0] acc,
    output reg signed [7:0] a_out,
    output reg signed [7:0] b_out      
);
    wire signed [15:0] w1;
    assign w1 = a_in * b_in;
    always @(posedge clk) begin
        if(rst == 1'b1) begin
            acc <= {32{1'b0}};
            a_out <= {8{1'b0}};
            b_out <= {8{1'b0}};
        end
        else begin
            if(clear == 1'b1) begin
                acc <= {32{1'b0}};
                a_out <= a_in;
                b_out <= b_in;                
            end 
            else begin
                acc <= acc + w1;
                a_out <= a_in;
                b_out <= b_in; 
            end
        end
    end
endmodule

module sys_array_4x4(
    input clk,
    input rst,
    input clear,
    input [31:0] a_row_in, 
    input [31:0] b_col_in, 
    output wire [511:0] c_out
);
    wire signed [7:0] a_wire [0:3][0:3];
    wire signed [7:0] b_wire [0:3][0:3];
    genvar i,j;
    generate
        for (i=0;i < 4;i=i+1) begin : row
            for (j=0;j<4 ;j=j+1 ) begin : col
                Topmodule pe_inst (
                .clk(clk),
                .rst(rst),
                .clear(clear),
                .a_in((j == 0) ? a_row_in[8*i +: 8] : a_wire[i][j-1]),
                .b_in((i == 0) ? b_col_in[8*j +: 8] : b_wire[i-1][j]),
                .a_out(a_wire[i][j]),
                .b_out(b_wire[i][j]),
                .acc(c_out[32*(4*i + j) +: 32])
            );
            end
        end
    endgenerate
endmodule