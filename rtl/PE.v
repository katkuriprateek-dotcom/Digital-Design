module pe (
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