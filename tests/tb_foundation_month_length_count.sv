`timescale 1ns/1ps
// Stage-1 TEST-ONLY exact bounded month-length composition counting.
// 45 months of length 4..123, exact sum 4244. This DP does not
// unrank the chosen sequence or implement the woven month calendar.
// The golden total below was obtained with an independent bignum
// recurrence, not from the SystemVerilog fixture.
module tb_foundation_month_length_count;
    localparam integer YEAR_LENGTH=4244;
    localparam integer NUMBER_OF_MONTHS=45;
    localparam integer LOW=4;
    localparam integer HIGH=123;
    localparam logic [383:0] EXPECTED =
        384'h3b999c3af2d83d8b41d8b6b0aa25e5fc7a260dcb4a823403855975a8c46102e640cc4;
    logic [383:0] before_count [0:YEAR_LENGTH];
    logic [383:0] after_count [0:YEAR_LENGTH];
    logic [383:0] sliding_sum;
    integer month_i, sum_i;

    initial begin
        for(sum_i=0;sum_i<=YEAR_LENGTH;sum_i=sum_i+1)
            before_count[sum_i]=384'd0;
        before_count[0]=384'd1;

        // f(m,s)=sum_{length=4}^{123} f(m-1,s-length)
        // This exact sliding window evaluates it in O(m*L) additions,
        // rather than O(m*L*120) additions. No truncation modulo M.
        for(month_i=1;month_i<=NUMBER_OF_MONTHS;month_i=month_i+1) begin
            sliding_sum=384'd0;
            for(sum_i=0;sum_i<=YEAR_LENGTH;sum_i=sum_i+1) begin
                if(sum_i>=LOW)
                    sliding_sum=sliding_sum+before_count[sum_i-LOW];
                if(sum_i>HIGH)
                    sliding_sum=sliding_sum-before_count[sum_i-HIGH-1];
                after_count[sum_i]=sliding_sum;
            end
            if(after_count[LOW*month_i]!==384'd1)
                $fatal(1,"MONTH_DP_MIN_BOUNDARY");
            if(HIGH*month_i<=YEAR_LENGTH &&
               after_count[HIGH*month_i]!==384'd1)
                $fatal(1,"MONTH_DP_MAX_BOUNDARY");
            for(sum_i=0;sum_i<=YEAR_LENGTH;sum_i=sum_i+1)
                before_count[sum_i]=after_count[sum_i];
        end
        if(before_count[YEAR_LENGTH]!==EXPECTED)
            $fatal(1,"MONTH45_LENGTH_COMPOSITION_COUNT_MISMATCH got=%h expected=%h",
                   before_count[YEAR_LENGTH],EXPECTED);
        if(before_count[YEAR_LENGTH]>=((384'd1<<127)-384'd1))
            $display("MONTH45_COMPOSITION_REQUIRES_WIDE_SELECTION");
        else $fatal(1,"EXPECTED_WIDE_MONTH_LENGTH_SELECTION");
        $display("STAGE1_MONTH45_LENGTH_COMPOSITION_COUNT_PASS bits=274");
        $finish;
    end
endmodule
