`timescale 1ns/1ps
// Stage 1 test-only fifth woven month ordinal at Foundation.
// Uses proven rank, SHA-proven preceding block counts and an
// independent 22528-bit count after prefix [1,2,3,4,1].
// It does not imply a complete SystemVerilog 4244-symbol unrank.
module tb_weave_prefix5;
    localparam integer WIDTH=22528, LIMBS=WIDTH/32, BYTES=2809;
    logic [WIDTH-1:0] root, rank, p11, p121, p122, p123;
    logic [WIDTH-1:0] p1231, p1232, p1233, p1234, p12341;
    logic [WIDTH-1:0] p12342, p12343, p12344, p12345;
    logic [WIDTH-1:0] already_skipped, fifth_rank, old_blocks;

    task automatic read_binary(input string path,
                               output logic [WIDTH-1:0] val);
        integer fh,bytevalue,j;
        begin
            val='0;fh=$fopen(path,"rb");
            if(fh==0) $fatal(1,"PREFIX5_INPUT_MISSING");
            for(j=BYTES-1;j>=0;j=j-1) begin
                bytevalue=$fgetc(fh);
                if(bytevalue<0) $fatal(1,"PREFIX5_SHORT_INPUT");
                val[j*8+:8]=bytevalue[7:0];
            end
            if($fgetc(fh)!=-1) $fatal(1,"PREFIX5_LONG_INPUT");
            $fclose(fh);
        end
    endtask

    task automatic write_binary(input string path,
                                input logic [WIDTH-1:0] val);
        integer fh,j;
        begin
            fh=$fopen(path,"wb");
            if(fh==0) $fatal(1,"PREFIX5_OUTPUT_OPEN");
            for(j=BYTES-1;j>=0;j=j-1)
                $fwrite(fh,"%c",val[j*8+:8]);
            $fclose(fh);
        end
    endtask

    function automatic logic [WIDTH-1:0] ratio(
        input logic [WIDTH-1:0] input_count,
        input integer multiplier,input integer denominator
    );
        logic [WIDTH-1:0] num,q;
        logic [63:0] word,rem;
        integer limb;
        begin
            if(multiplier<=0 || multiplier>524288 ||
               denominator<=0 || denominator>524288)
                $fatal(1,"PREFIX5_RATIO_ARGUMENTS");
            num=input_count*WIDTH'(multiplier);
            if(num<input_count || num[WIDTH-1:WIDTH-21]!=='0)
                $fatal(1,"PREFIX5_RATIO_MULTIPLY_WIDTH_GUARD");
            q='0;rem=64'd0;
            for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
                word=(rem<<32)|{32'b0,num[limb*32+:32]};
                q[limb*32+:32]=word/$unsigned(denominator);
                rem=word%$unsigned(denominator);
            end
            if(rem!==64'd0 || q*WIDTH'(denominator)!==num)
                $fatal(1,"PREFIX5_EXACT_RATIO_FAILURE");
            ratio=q;
        end
    endfunction

    initial begin
        read_binary("build/foundation_weave_root.bin",root);
        read_binary("build/foundation_weave_rank.bin",rank);
        read_binary("build/foundation_weave_prefix11.bin",p11);
        read_binary("build/foundation_weave_prefix121.bin",p121);
        read_binary("build/foundation_weave_prefix122.bin",p122);
        read_binary("build/foundation_weave_prefix123.bin",p123);
        read_binary("build/foundation_weave_prefix1231.bin",p1231);
        read_binary("build/foundation_weave_prefix1232.bin",p1232);
        read_binary("build/foundation_weave_prefix1233.bin",p1233);
        read_binary("build/foundation_weave_prefix1234.bin",p1234);
        read_binary("build/foundation_weave_prefix12341.bin",p12341);

        if(root==0 || rank==0 || rank>root || p12341==0 ||
           root!==p11+p121+p122+p123 ||
           p123!==p1231+p1232+p1233+p1234)
            $fatal(1,"PREFIX5_PRIOR_PARTITION_INVALID");

        // All first four month labels have appeared in the prefix.
        // There are [114,107,118,108] active appearances remaining.
        // The four old-label blocks have equal future-fresh-month
        // insertion factor, and their ordered-LAST active word factors
        // satisfy these exact rational relations:
        //
        // C([1,2,3,4,2]) / C([1,2,3,4,1]) = 53/57
        // C([1,2,3,4,3]) / C([1,2,3,4,1]) = 330/323
        // C([1,2,3,4,4]) / C([1,2,3,4,1]) = 306020/328491
        p12342=ratio(p12341,53,57);
        p12343=ratio(p12341,330,323);
        p12344=ratio(p12341,306020,328491);
        old_blocks=p12341+p12342+p12343+p12344;
        if(old_blocks>=p1234)
            $fatal(1,"PREFIX5_OLD_BLOCKS_EXCEED_PARENT");
        p12345=p1234-old_blocks;

        already_skipped=p11+p121+p122+p1231+p1232+p1233;
        if(rank<=already_skipped)
            $fatal(1,"PREFIX5_INVALID_PRIOR_RANK");
        fifth_rank=rank-already_skipped;
        if(fifth_rank<=old_blocks || fifth_rank>p1234)
            $fatal(1,"PREFIX5_EXPECTED_FIFTH_ORDINAL");
        if(fifth_rank-old_blocks>p12345)
            $fatal(1,"PREFIX5_SELECTED_RANK_OUTSIDE_BLOCK");

        write_binary("build/foundation_weave_prefix12342.bin",p12342);
        write_binary("build/foundation_weave_prefix12343.bin",p12343);
        write_binary("build/foundation_weave_prefix12344.bin",p12344);
        write_binary("build/foundation_weave_prefix12345.bin",p12345);
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX5_PASS ordinals=1,2,3,4,5");
        $finish;
    end
endmodule
