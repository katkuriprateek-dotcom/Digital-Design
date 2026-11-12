
`timescale 1ns / 1ps

module result_storage (

    input wire clk,
    input wire rst,
    input wire start,               // New multiplication request
    input wire done,                // Completion signal from matrix skew controller
    input wire [511:0] c_in,        // Results from systolic array

    output reg [511:0] result_out,  // Stored results
    output reg result_valid         // Indicates stored results are valid
);

    // START EDGE DETECTION
    reg start_d;
    wire start_pulse;

    assign start_pulse = start & ~start_d;

    // RESULT STORAGE
    always @(posedge clk) begin
        if (rst) begin
            result_out   <= 512'd0;
            result_valid <= 1'b0;
            start_d      <= 1'b0;
        end
        else begin
            start_d <= start;           // Store previous start state
            if (start_pulse) begin      // New multiplication request
                result_valid <= 1'b0;
            end
            else if (done) begin        // Capture completed multiplication
                result_out   <= c_in;
                result_valid <= 1'b1;
            end
        end
    end
endmodule