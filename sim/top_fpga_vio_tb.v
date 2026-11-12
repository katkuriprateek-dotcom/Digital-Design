
`timescale 1ns / 1ps

module top_fpga_vio_tb;

    reg clk;
    reg rst;

    integer i;
    integer errors;
    integer timeout_count;
    integer output_file;

    reg [127:0] matrix_a_test;
    reg [127:0] matrix_b_test;

    reg [127:0] input_words [0:1];

    reg [31:0] expected_value;

    // 512-bit result from VIO
    wire [511:0] result_from_vio;

    assign result_from_vio[255:0] =
        dut.vio_inst.probe_in0;

    assign result_from_vio[511:256] =
        dut.vio_inst.probe_in1;

    // DUT: TOP FPGA INCLUDING VIO
    top_fpga dut (
        .clk(clk),
        .rst(rst)
    );

    // CLOCK GENERATION: 100 MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // MAIN TEST
    initial begin

        rst = 1'b1;
        errors = 0;
        timeout_count = 0;
        output_file = 0;

        matrix_a_test = 128'd0;
        matrix_b_test = 128'd0;

        input_words[0] = 128'd0;
        input_words[1] = 128'd0;

        // STEP 1: RESET
        repeat (5) @(negedge clk);

        rst = 1'b0;

        repeat (2) @(negedge clk);

        // STEP 2: READ PYTHON INPUT FILE
        $display("");
        $display("Reading matrix_input.mem...");

        $readmemh("matrix_input.mem", input_words);

        matrix_a_test = input_words[0];
        matrix_b_test = input_words[1];

        // Check for unknown input values
        if ((^matrix_a_test === 1'bx) ||
            (^matrix_b_test === 1'bx)) begin

            $display("ERROR: Invalid or missing matrix_input.mem");
            $finish;

        end

        $display("Matrix A and Matrix B loaded successfully.");

        // STEP 3: DRIVE VIO OUTPUT PROBES
        force dut.vio_inst.probe_out0 = matrix_a_test;
        force dut.vio_inst.probe_out1 = matrix_b_test;
        force dut.vio_inst.probe_out2 = 1'b0;

        repeat (2) @(negedge clk);

        // STEP 4: START MULTIPLICATION
        force dut.vio_inst.probe_out2 = 1'b1;

        @(negedge clk);

        force dut.vio_inst.probe_out2 = 1'b0;

        $display("");
        $display("MULTIPLICATION STARTED THROUGH VIO");

        // STEP 5: WAIT FOR RESULT VALID
        while ((dut.vio_inst.probe_in2 !== 1'b1) &&
               (timeout_count < 30)) begin

            @(negedge clk);

            timeout_count = timeout_count + 1;

        end

        // STEP 6: CHECK RESULT VALID
        if (dut.vio_inst.probe_in2 !== 1'b1) begin

            $display("ERROR: RESULT TIMEOUT");

            errors = errors + 1;

        end

        else begin

            $display("");
            $display("RESULT MATRIX C:");
            $display("--------------------------------");

            // DISPLAY RESULT MATRIX
            for (i = 0; i < 16; i = i + 1) begin

                $write("%0d\t", $signed(result_from_vio[32*i +: 32]));

                if ((i % 4) == 3)
                    $display("");

            end

            $display("--------------------------------");

            // STEP 8: SAVE RESULT TO OUTPUT FILE
            output_file = $fopen("matrix_output.mem", "w");
            if (output_file == 0) begin
                $display("ERROR: Cannot create matrix_output.mem");
                errors = errors + 1;
            end
            else begin

                $fdisplay(output_file, "%0128h", result_from_vio);

                $fclose(output_file);

                $display("");
                $display("Result saved to matrix_output.mem");
            end
        end

        // STEP 9: FINAL STATUS
        $display("");
        $display("================================");

        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d ERRORS", errors);

        $display("================================");

        $finish;
    end
endmodule