`timescale 1ns / 1ps

module tb_Topmodule;

    reg clk;
    reg rst;
    reg clear;
    reg signed [7:0] a_in;
    reg signed [7:0] b_in;
    
    wire signed [31:0] acc;
    wire signed [7:0] a_out;
    wire signed [7:0] b_out;

    Topmodule uut (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .a_in(a_in),
        .b_in(b_in),
        .acc(acc),
        .a_out(a_out),
        .b_out(b_out)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_Topmodule);
        
        clk = 0;
        rst = 1;
        clear = 0;
        a_in = 0;
        b_in = 0;

        #15;
        rst = 0;
        
        clear = 1;
        #10;
        clear = 0;

        a_in = 3;
        b_in = 4;
        #10; 

        a_in = -2;
        b_in = 5;
        #10; 
        
        #50;
        $finish;
    end

endmodule