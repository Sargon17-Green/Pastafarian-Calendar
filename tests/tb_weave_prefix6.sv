`timescale 1ns/1ps
// Stage 1 TEST ONLY: exact canonical sixth weave ordinal.
// Input binaries are independently SHA-checked by the CI runner.
// The 4244-symbol word and production ASIC RTL remain outside this fixture.
module tb_weave_prefix6;
    localparam integer WIDTH=22528, LIMBS=WIDTH/32, BYTES=2809;
    logic [WIDTH-1:0] root,rank,p11,p121,p122,p123,p1231,p1232,p1233,p1234;
    logic [WIDTH-1:0] p12341,p12342,p12343,p12344,p12345;
    logic [WIDTH-1:0] p123451,p123452,p123453,p123454,p123455,p123456;
    logic [WIDTH-1:0] prior_rank, local_rank, old_blocks;

    task automatic read_binary(input string path,output logic [WIDTH-1:0] val);
        integer f,j,b;
        begin
            val='0;
            f=$fopen(path,"rb");
            if(f==0) $fatal(1,"PREFIX6_MISSING_INPUT");
            for(j=BYTES-1;j>=0;j=j-1) begin
                b=$fgetc(f);
                if(b<0) $fatal(1,"PREFIX6_TRUNCATED_INPUT");
                val[j*8+:8]=b[7:0];
            end
            if($fgetc(f)!=-1) $fatal(1,"PREFIX6_EXCESS_INPUT");
            $fclose(f);
        end
    endtask
    task automatic write_binary(input string path,input logic [WIDTH-1:0] val);
        integer f,j;
        begin
            f=$fopen(path,"wb");
            if(f==0) $fatal(1,"PREFIX6_OUTPUT_OPEN");
            for(j=BYTES-1;j>=0;j=j-1)
                $fwrite(f,"%c",val[j*8+:8]);
            $fclose(f);
        end
    endtask
    function automatic logic [WIDTH-1:0] exact_ratio(
        input logic [WIDTH-1:0] base,
        input integer multiplier,input integer denominator
    );
        logic [WIDTH-1:0] n,q;
        logic [63:0] w,carry;
        integer limb;
        begin
            if(multiplier<=0 || multiplier>200000000 ||
               denominator<=0 || denominator>200000000)
                $fatal(1,"PREFIX6_BAD_RATIO_ARGUMENT");
            // Reference counts are 22465 bits; a <=28-bit
            // multiplication must not wrap a 22528-bit word.
            if(base[WIDTH-1:WIDTH-34]!=='0)
                $fatal(1,"PREFIX6_MULTIPLY_WIDTH_GUARD");
            n=base*WIDTH'(multiplier);
            q='0;carry='0;
            for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
                w=(carry<<32)|{32'b0,n[limb*32+:32]};
                q[limb*32+:32]=w/$unsigned(denominator);
                carry=w%$unsigned(denominator);
            end
            if(carry!==64'd0 || q*WIDTH'(denominator)!==n)
                $fatal(1,"PREFIX6_NONEXACT_RATIO");
            exact_ratio=q;
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
        read_binary("build/foundation_weave_prefix12342.bin",p12342);
        read_binary("build/foundation_weave_prefix12343.bin",p12343);
        read_binary("build/foundation_weave_prefix12344.bin",p12344);
        read_binary("build/foundation_weave_prefix12345.bin",p12345);
        read_binary("build/foundation_weave_prefix123451.bin",p123451);
        if(root==0 || rank==0 || rank>root ||
           p12345==0 || p123451==0 ||
           root!==p11+p121+p122+p123 ||
           p123!==p1231+p1232+p1233+p1234 ||
           p1234!==p12341+p12342+p12343+p12344+p12345)
            $fatal(1,"PREFIX6_INVALID_PRIOR_PARTITION");

        // Active remaining counts after selected prefix [1,2,3,4,5]:
        // [114,107,118,108,105].
        // From the exact last-occurrence ordered multinomial count,
        // all previously seen-label block ratios to label 1:
        p123452=exact_ratio(p123451,53,57);
        p123453=exact_ratio(p123451,330,323);
        p123454=exact_ratio(p123451,306020,328491);
        p123455=exact_ratio(p123451,132658240,146835477);
        old_blocks=p123451+p123452+p123453+p123454+p123455;
        if(old_blocks>=p12345)
            $fatal(1,"PREFIX6_OLD_BLOCKS_OUTSIDE_PARENT");
        p123456=p12345-old_blocks;

        // Subtract all blocks lexicographically preceding prefix
        // [1,2,3,4,5], preserving one-based rank semantics.
        prior_rank=p11+p121+p122+p1231+p1232+p1233+
                   p12341+p12342+p12343+p12344;
        if(rank<=prior_rank) $fatal(1,"PREFIX6_RANK_BEFORE_PARENT");
        local_rank=rank-prior_rank;
        if(local_rank>p12345 || local_rank<=old_blocks ||
           local_rank-old_blocks>p123456)
            $fatal(1,"PREFIX6_GOLDEN_ORDINAL_NOT_SIX");

        write_binary("build/foundation_weave_prefix123452.bin",p123452);
        write_binary("build/foundation_weave_prefix123453.bin",p123453);
        write_binary("build/foundation_weave_prefix123454.bin",p123454);
        write_binary("build/foundation_weave_prefix123455.bin",p123455);
        write_binary("build/foundation_weave_prefix123456.bin",p123456);
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX6_PASS ordinals=1,2,3,4,5,6");
        $finish;
    end
endmodule
