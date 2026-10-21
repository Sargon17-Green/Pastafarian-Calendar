`timescale 1ns/1ps
// Stage 1 transaction-reset regression; never claims a calendar result.
module tb_stage1_reset;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic reset_n = 1'b0;
    logic req_valid = 1'b0;
    logic req_ready, done, date_valid;
    logic signed [63:0] calculation_day = 64'sd0;
    logic signed [63:0] target_day = 64'sd0;
    logic signed [63:0] captured_calculation_day;
    logic signed [63:0] captured_target_day;
    logic [63:0] accepted_count;
    logic [1:0] diagnostic_phase;

    pcal_stage1_bootstrap dut (
        .clk(clk),
        .reset_n(reset_n),
        .req_valid(req_valid),
        .req_ready(req_ready),
        .calculation_day(calculation_day),
        .target_day(target_day),
        .done(done),
        .date_valid(date_valid),
        .captured_calculation_day(captured_calculation_day),
        .captured_target_day(captured_target_day),
        .accepted_count(accepted_count),
        .diagnostic_phase(diagnostic_phase)
    );

    task automatic verify_reset;
        begin
            #1;
            if (req_ready !== 1'b1 ||
                done !== 1'b0 ||
                date_valid !== 1'b0 ||
                accepted_count !== 64'd0 ||
                captured_calculation_day !== 64'sd0 ||
                captured_target_day !== 64'sd0 ||
                diagnostic_phase !== 2'd0)
                $fatal(1, "RESET_AT_ANY_PHASE");
        end
    endtask

    initial begin
        verify_reset();
        repeat (3) @(negedge clk);
        reset_n = 1'b1;

        @(negedge clk);
        calculation_day = 64'sh8000000000000000;
        target_day = 64'sh7fffffffffffffff;
        req_valid = 1'b1;
        @(negedge clk);
        req_valid = 1'b0;
        if (accepted_count !== 64'd1 || req_ready !== 1'b0)
            $fatal(1, "REQUEST_BEFORE_MID_FLIGHT_RESET");
        if (captured_calculation_day !== 64'sh8000000000000000 ||
            captured_target_day !== 64'sh7fffffffffffffff)
            $fatal(1, "SIGNED_DAY_CAPTURE");
        reset_n = 1'b0;
        verify_reset();

        @(negedge clk);
        reset_n = 1'b1;
        @(negedge clk);
        calculation_day = -64'sd15055671;
        target_day = -64'sd15055672;
        req_valid = 1'b1;
        @(negedge clk);
        req_valid = 1'b0;
        if (accepted_count !== 64'd1)
            $fatal(1, "COUNTER_RESTART");
        if (captured_calculation_day !== -64'sd15055671 ||
            captured_target_day !== -64'sd15055672)
            $fatal(1, "CAPTURE_AFTER_RESET");

        @(negedge clk);
        if (diagnostic_phase !== 2'd2)
            $fatal(1, "OBSERVE_PHASE");
        @(negedge clk);
        if (!done || req_ready || date_valid)
            $fatal(1, "DONE_NOT_DATE");
        reset_n = 1'b0;
        verify_reset();
        @(negedge clk);
        reset_n = 1'b1;
        @(negedge clk);
        if (!req_ready || done || accepted_count !== 64'd0)
            $fatal(1, "RESET_RETURN_IDLE");
        $display("STAGE1_RESET_RECOVERY_CONTRACT_PASS");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "RESET_TEST_TIMEOUT");
    end
endmodule
