`timescale 1ns / 1ps

module matrix_skew_controller (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [127:0] matrix_a,
    input wire [127:0] matrix_b,

    output reg clear,
    output reg [31:0] a_row_in,
    output reg [31:0] b_col_in,
    output reg busy,
    output reg done,
    output wire [511:0] c_out
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam CLEAR = 2'b01;
    localparam RUN   = 2'b10;
    localparam DONE  = 2'b11;

    reg [1:0] state;

    // Internal matrix storage
    reg [127:0] A_reg;
    reg [127:0] B_reg;

    // Cycle counter: 0 to 9
    reg [3:0] cycle_count;

    // Start edge detection
    reg start_d;
    wire start_pulse;

    assign start_pulse = start & ~start_d;

    // Systolic array
    sys_array_4x4 systolic_inst (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .a_row_in(a_row_in),
        .b_col_in(b_col_in),
        .c_out(c_out)
    );

    // Sequential FSM
    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            cycle_count <= 4'd0;
            A_reg <= 128'd0;
            B_reg <= 128'd0;
            done    <= 1'b0;
            start_d <= 1'b0;
        end
        else begin
            start_d <= start;
            
            done <= 1'b0;       // Default one-clock completion pulse

            case (state)
                IDLE: begin                         // IDLE
                    cycle_count <= 4'd0;
                    if (start_pulse) begin
                        A_reg <= matrix_a;
                        B_reg <= matrix_b;
                        state <= CLEAR;
                    end
                end

                CLEAR: begin                        // CLEAR
                    cycle_count <= 4'd0;
                    state <= RUN;
                end

                RUN: begin                          // RUN
                    if (cycle_count == 4'd9) begin
                        state <= DONE;
                        cycle_count <= 4'd0;
                        done <= 1'b1;
                    end
                    else begin
                        cycle_count <= cycle_count + 1'b1;
                    end
                end

                DONE: begin                         // DONE
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    cycle_count <= 4'd0;
                end
            endcase
        end
    end

    // Input skew generation
    integer i;
    integer k;
    
    always @(*) begin
        a_row_in = 32'd0;
        b_col_in = 32'd0;
        clear = 1'b0;
        busy  = 1'b0;
        k = 0;

        case (state)
            IDLE: begin
                clear = 1'b0;
                busy  = 1'b0;
            end

            CLEAR: begin
                clear = 1'b1;
                busy  = 1'b1;
            end

            RUN: begin
                clear = 1'b0;
                busy  = 1'b1;

                // Matrix A: row-wise skewing
                for (i = 0; i < 4; i = i + 1) begin
                    if ((cycle_count >= i) &&
                        (cycle_count <= i + 3)) begin
                        k = cycle_count - i;
                        a_row_in[8*i +: 8] =
                            A_reg[8*(4*i + k) +: 8];
                    end
                end

                // Matrix B: column-wise skewing
                for (i = 0; i < 4; i = i + 1) begin
                    if ((cycle_count >= i) &&
                        (cycle_count <= i + 3)) begin
                        k = cycle_count - i;
                        b_col_in[8*i +: 8] =
                            B_reg[8*(4*k + i) +: 8];
                    end
                end
            end

            DONE: begin
                clear = 1'b0;
                busy  = 1'b0;
            end
            default: begin
                clear = 1'b0;
                busy  = 1'b0;
            end
        endcase
    end
endmodule