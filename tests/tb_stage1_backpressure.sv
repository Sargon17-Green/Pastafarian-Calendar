`timescale 1ns/1ps
// Stage-1 deterministic stress test of transaction backpressure.
// This deliberately checks a bootstrap that produces NO calendar date.
module tb_stage1_backpressure;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic reset_n = 1'b1;
    logic req_valid = 1'b0, req_ready, done, date_valid;
    logic signed [63:0] calculation_day = 64'sd0;
    logic signed [63:0] target_day = 64'sd0;
    logic signed [63:0] captured_calculation_day, captured_target_day;
    logic [63:0] accepted_count;
    logic [1:0] diagnostic_phase;

    pcal_stage1_bootstrap dut (
        .clk(clk),.reset_n(reset_n),
        .req_valid(req_valid),.req_ready(req_ready),
        .calculation_day(calculation_day),.target_day(target_day),
        .done(done),.date_valid(date_valid),
        .captured_calculation_day(captured_calculation_day),
        .captured_target_day(captured_target_day),
        .accepted_count(accepted_count),
        .diagnostic_phase(diagnostic_phase)
    );

    logic [31:0] state = 32'hace0_4211;
    logic [1:0] expected_phase = 2'd0;
    logic signed [63:0] expected_c = 64'sd0, expected_t = 64'sd0;
    logic [63:0] expected_count = 64'd0;
    integer cycle, handshakes = 0, forced_resets = 0;

    function automatic logic [31:0] evolve(input logic [31:0] s);
        evolve = s * 32'd1664525 + 32'd1013904223;
    endfunction

    initial begin
        #1;
        reset_n=1'b0;
        #1;
        if(req_ready !== 1'b1 || date_valid !== 1'b0 ||
           done !== 1'b0 || accepted_count !== 64'd0)
            $fatal(1,"INITIAL_ASYNC_RESET");

        for(cycle=0;cycle<4096;cycle=cycle+1) begin
            @(negedge clk);
            state=evolve(state);
            reset_n = ((cycle % 211) != 0) ? 1'b1 : 1'b0;
            req_valid=state[4];
            calculation_day=$signed({state,evolve(state)});
            state=evolve(state);
            target_day=$signed({evolve(state),state});

            if(!reset_n) begin
                expected_phase=2'd0;
                expected_c=64'sd0;
                expected_t=64'sd0;
                expected_count=64'd0;
                forced_resets=forced_resets+1;
                #1;
                if(req_ready !== 1'b1 || done !== 1'b0 ||
                   date_valid !== 1'b0 || accepted_count !== 64'd0)
                    $fatal(1,"ASYNCHRONOUS_RESET_CYCLE");
            end else begin
                case(expected_phase)
                    2'd0: begin
                        if(req_valid) begin
                            expected_c=calculation_day;
                            expected_t=target_day;
                            expected_count=expected_count+64'd1;
                            handshakes=handshakes+1;
                            expected_phase=2'd1;
                        end
                    end
                    2'd1: expected_phase=2'd2;
                    2'd2: expected_phase=2'd3;
                    2'd3: expected_phase=2'd0;
                    default: $fatal(1,"BAD_REFERENCE_PHASE");
                endcase
            end
            @(posedge clk);
            #1;
            if(diagnostic_phase !== expected_phase ||
               captured_calculation_day !== expected_c ||
               captured_target_day !== expected_t ||
               accepted_count !== expected_count ||
               req_ready !== (expected_phase==2'd0) ||
               done !== (expected_phase==2'd3) ||
               date_valid !== 1'b0)
                $fatal(1,"BACKPRESSURE_CONTEXT_INVARIANT");
        end
        if(handshakes < 400 || forced_resets < 10)
            $fatal(1,"INSUFFICIENT_STRESS_COVERAGE");
        $display("STAGE1_BACKPRESSURE_SCOREBOARD_PASS cycles=%0d handshakes=%0d resets=%0d",
                 4096,handshakes,forced_resets);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1,"BACKPRESSURE_TIMEOUT");
    end
endmodule
