
`timescale 1ns / 1ps

module top_fpga_vio_tb;

    reg clk;
    reg rst;

    integer i;
    integer errors;
    integer timeout_count;

    reg [127:0] matrix_a_test;
    reg [127:0] matrix_b_test;

    // =====================================
    // 1. CONNECT 512-BIT RESULT FROM VIO
    // =====================================

    wire [511:0] result_from_vio;

    assign result_from_vio[255:0] =
        dut.vio_inst.probe_in0;

    assign result_from_vio[511:256] =
        dut.vio_inst.probe_in1;

    // =====================================
    // 2. DUT: TOP FPGA INCLUDING VIO
    // =====================================

    top_fpga dut (
        .clk(clk),
        .rst(rst)
    );

    // =====================================
    // 3. CLOCK GENERATION
    // =====================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =====================================
    // 4. MAIN TEST
    // =====================================

    initial begin

        rst = 1'b1;
        errors = 0;
        timeout_count = 0;

        matrix_a_test = 128'd0;
        matrix_b_test = 128'd0;

        // ---------------------------------
        // STEP 1: RESET
        // ---------------------------------

        repeat (5) @(negedge clk);

        rst = 1'b0;

        repeat (2) @(negedge clk);

        // ---------------------------------
        // STEP 2: MATRIX A
        //
        //  1   2   3   4
        //  5   6   7   8
        //  9  10  11  12
        // 13  14  15  16
        // ---------------------------------

        for (i = 0; i < 16; i = i + 1) begin
            matrix_a_test[8*i +: 8] = i + 1;
        end

        // ---------------------------------
        // STEP 3: MATRIX B (IDENTITY)
        //
        // 1 0 0 0
        // 0 1 0 0
        // 0 0 1 0
        // 0 0 0 1
        // ---------------------------------

        for (i = 0; i < 16; i = i + 1) begin

            if ((i == 0) || (i == 5) ||
                (i == 10) || (i == 15))

                matrix_b_test[8*i +: 8] = 8'd1;

            else

                matrix_b_test[8*i +: 8] = 8'd0;

        end

        // ---------------------------------
        // STEP 4: DRIVE VIO OUTPUT PROBES
        // ---------------------------------

        force dut.vio_inst.probe_out0 = matrix_a_test;
        force dut.vio_inst.probe_out1 = matrix_b_test;
        force dut.vio_inst.probe_out2 = 1'b0;

        repeat (2) @(negedge clk);

        // ---------------------------------
        // STEP 5: START MULTIPLICATION
        // ---------------------------------

        force dut.vio_inst.probe_out2 = 1'b1;

        @(negedge clk);

        force dut.vio_inst.probe_out2 = 1'b0;

        $display("");
        $display("MULTIPLICATION STARTED THROUGH VIO");

        // ---------------------------------
        // STEP 6: WAIT FOR RESULT VALID
        // ---------------------------------

        while ((dut.vio_inst.probe_in2 !== 1'b1) &&
               (timeout_count < 30)) begin

            @(negedge clk);

            timeout_count = timeout_count + 1;

        end

        // ---------------------------------
        // STEP 7: CHECK RESULT VALID
        // ---------------------------------

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

                $write("%0d\t", result_from_vio[32*i +: 32]);

                if ((i % 4) == 3)
                    $display("");

            end

            $display("--------------------------------");

            // VERIFY ALL 16 RESULTS

            for (i = 0; i < 16; i = i + 1) begin

                if (result_from_vio[32*i +: 32] !== (i + 1)) begin

                    $display(
                        "FAIL: C[%0d][%0d] Expected=%0d Actual=%0d",
                        i / 4,
                        i % 4,
                        i + 1,
                        result_from_vio[32*i +: 32]
                    );

                    errors = errors + 1;

                end

                else begin

                    $display(
                        "PASS: C[%0d][%0d] = %0d",
                        i / 4,
                        i % 4,
                        result_from_vio[32*i +: 32]
                    );

                end

            end

        end

        // ---------------------------------
        // STEP 8: FINAL STATUS
        // ---------------------------------

        $display("");
        $display("================================");

        if (errors == 0)
            $display("TEST PASSED: ALL RESULTS CORRECT");

        else
            $display("TEST FAILED: %0d ERRORS", errors);

        $display("================================");

        $finish;

    end

endmodule
