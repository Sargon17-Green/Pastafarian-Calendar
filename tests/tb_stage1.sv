`timescale 1ns/1ps
module tb_stage1;
    import pcal_stage1_oracle_pkg::*;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic reset_n = 1'b0;
    logic req_valid = 1'b0;
    logic req_ready;
    logic signed [63:0] calculation_day = '0, target_day = '0;
    logic done, date_valid;
    logic signed [63:0] captured_calculation_day, captured_target_day;
    logic [63:0] accepted_count;
    logic [1:0] diagnostic_phase;

    pcal_stage1_bootstrap dut (
        .clk(clk), .reset_n(reset_n),
        .req_valid(req_valid), .req_ready(req_ready),
        .calculation_day(calculation_day), .target_day(target_day),
        .done(done), .date_valid(date_valid),
        .captured_calculation_day(captured_calculation_day),
        .captured_target_day(captured_target_day),
        .accepted_count(accepted_count),
        .diagnostic_phase(diagnostic_phase)
    );

    task automatic submit_and_check(
        input logic signed [63:0] c,
        input logic signed [63:0] t,
        input logic [63:0] expected_count
    );
        integer ticks;
        begin
            @(negedge clk);
            if (!req_ready || done || date_valid)
                $fatal(1, "BOOT_READY_CONTRACT");
            calculation_day = c;
            target_day = t;
            req_valid = 1'b1;
            @(negedge clk);
            req_valid = 1'b1; // must be ignored while not ready
            calculation_day = 64'sd12345;
            target_day = -64'sd98765;
            if (req_ready) $fatal(1, "BUSY_READY_CONTRACT");
            if (captured_calculation_day !== c ||
                captured_target_day !== t)
                $fatal(1, "CONTEXT_OWNERSHIP");
            if (accepted_count !== expected_count)
                $fatal(1, "ACCEPTED_TRANSACTION_COUNT");
            @(negedge clk);
            req_valid = 1'b0;
            if (accepted_count !== expected_count)
                $fatal(1, "BUSY_REQUEST_NOT_IGNORED");
            ticks = 0;
            while (!done && ticks < 6) begin
                @(negedge clk);
                ticks = ticks + 1;
            end
            if (!done) $fatal(1, "BOOT_COMPLETION_TIMEOUT");
            if (date_valid) $fatal(1, "FALSE_CALENDAR_COMPLETION");
            if (captured_calculation_day !== c ||
                captured_target_day !== t)
                $fatal(1, "CONTEXT_CHANGED_WHILE_BUSY");
            @(negedge clk);
            if (!req_ready || done) $fatal(1, "BOOT_RETURN_IDLE");
        end
    endtask

    initial begin
        #1;
        if (ORACLE_M !== ((256'sd1 << 127) - 256'sd1))
            $fatal(1, "ORACLE_MODULUS");
        if (oracle_save(256'sd0) !== ORACLE_M)
            $fatal(1, "SAVE_ZERO");
        if (oracle_save(ORACLE_M) !== ORACLE_M)
            $fatal(1, "SAVE_M");
        if (oracle_save(ORACLE_M * 256'sd2) !== ORACLE_M)
            $fatal(1, "SAVE_2M");
        if (oracle_save(ORACLE_M + 256'sd1) !== 256'sd1)
            $fatal(1, "SAVE_M_PLUS_ONE");
        if (oracle_save(-256'sd1) !== ORACLE_M - 256'sd1)
            $fatal(1, "SAVE_NEGATIVE");
        if (oracle_day_count(-64'sd15055671) !== 256'sd1)
            $fatal(1, "FOUNDATION");
        if (oracle_day_count(-64'sd15055672) !== 256'sd2)
            $fatal(1, "FOUNDATION_MINUS_ONE");
        if (oracle_day_count(-64'sd15055670) !== 256'sd3)
            $fatal(1, "FOUNDATION_PLUS_ONE");
        if (oracle_distance(-64'sd15055671, -64'sd15055671)
            !== 256'sd1)
            $fatal(1, "DISTANCE_EQUAL_DAYS");
        if (oracle_distance(64'sh8000000000000000,
                            64'sh7fffffffffffffff)
            !== (256'sd1 << 64))
            $fatal(1, "DISTANCE_FULL_SIGNED_RANGE");
        if (oracle_sum(64'sh8000000000000000,
                       64'sh7fffffffffffffff) !== ((256'sd1 << 65) - 256'sd1))
            $fatal(1, "DAY_COUNT_SUM_SIGNED_EXTREMES");
        if (oracle_direction(64'sd3, 64'sd2) !== 2'd1 ||
            oracle_direction(64'sd3, 64'sd3) !== 2'd2 ||
            oracle_direction(64'sd3, 64'sd4) !== 2'd3)
            $fatal(1, "DIRECTION");
        repeat (3) @(negedge clk);
        reset_n = 1'b1;
        submit_and_check(-64'sd15055671, -64'sd15055671, 64'd1);
        submit_and_check(64'sd739834, -64'sd739834, 64'd2);
        $display("STAGE1_BOOTSTRAP_ORACLE_PRIMITIVES_PASS");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "GLOBAL_TIMEOUT");
    end
endmodule
