`timescale 1ns/1ps
// Stage-1 independent test-only arithmetic properties.
// No production RTL or calendar output is imported.
module tb_stage1_arithmetic_properties;
    import pcal_stage1_oracle_pkg::*;
    localparam logic signed [255:0] M = (256'sd1 << 127) - 256'sd1;
    localparam logic signed [63:0] F = -64'sd15055671;
    logic [31:0] seed;
    logic signed [63:0] c, t;
    logic signed [255:0] n_c, n_t, dc, dt, x, saved_x;
    integer checks, i;
    logic [1:0] fwd, rev;

    function automatic logic [31:0] next32(input logic [31:0] value);
        next32 = value * 32'd1664525 + 32'd1013904223;
    endfunction

    task automatic test_pair(input logic signed [63:0] left_day,
                             input logic signed [63:0] right_day);
        begin
            n_c = oracle_day_count(left_day);
            n_t = oracle_day_count(right_day);
            dc = oracle_distance(left_day, right_day);
            dt = oracle_distance(right_day, left_day);
            if(n_c <= 256'sd0 || n_t <= 256'sd0)
                $fatal(1,"DAY_COUNT_POSITIVE");
            if((left_day < F && n_c%256'sd2!=256'sd0) ||
               (left_day >= F && n_c%256'sd2!=256'sd1) ||
               (right_day < F && n_t%256'sd2!=256'sd0) ||
               (right_day >= F && n_t%256'sd2!=256'sd1))
                $fatal(1,"DAY_COUNT_PARITY");
            if(dc !== dt || dc < 256'sd1)
                $fatal(1,"DISTANCE_SYMMETRY");
            if(oracle_sum(left_day,right_day) !==
               oracle_sum(right_day,left_day))
                $fatal(1,"SUM_SYMMETRY");
            if(oracle_sum(left_day,right_day) !== n_c+n_t)
                $fatal(1,"SUM_OF_DAY_COUNTS");
            fwd = oracle_direction(left_day,right_day);
            rev = oracle_direction(right_day,left_day);
            if((fwd==2'd1 && rev!=2'd3) ||
               (fwd==2'd3 && rev!=2'd1) ||
               (fwd==2'd2 && rev!=2'd2))
                $fatal(1,"DIRECTION_DUALITY");
            checks = checks + 1;
        end
    endtask

    initial begin
        seed = 32'h7026f55a;
        checks = 0;
        test_pair(F,F);
        test_pair(F-64'sd1,F);
        test_pair(F,F+64'sd1);
        test_pair(64'sh8000000000000000,
                  64'sh7fffffffffffffff);
        test_pair(64'sh7fffffffffffffff,
                  64'sh8000000000000000);
        test_pair(64'sh8000000000000000,
                  64'sh8000000000000000);
        test_pair(64'sh7fffffffffffffff,
                  64'sh7fffffffffffffff);

        for (i=0;i<4096;i=i+1) begin
            seed = next32(seed);
            c = $signed({seed, next32(seed)});
            seed = next32(seed);
            t = $signed({next32(seed), seed});
            test_pair(c,t);

            // Every tested value remains in 1..M after SAVE.
            x = oracle_day_count(c) + oracle_day_count(t)
                + oracle_distance(c,t)
                - oracle_distance(t,c) - 256'sd17;
            saved_x = oracle_save(x);
            if(saved_x < 256'sd1 || saved_x > M)
                $fatal(1,"SAVE_RANGE");
            if(oracle_save(x + M) !== saved_x ||
               oracle_save(x - M) !== saved_x)
                $fatal(1,"SAVE_PERIODICITY");
            if(oracle_save(oracle_save(x)) !== saved_x)
                $fatal(1,"SAVE_IDEMPOTENT");
        end

        if(checks!=4103) $fatal(1,"CASE_COUNT");
        $display("STAGE1_ARITHMETIC_PROPERTIES_PASS cases=%0d",checks);
        $finish;
    end
endmodule
