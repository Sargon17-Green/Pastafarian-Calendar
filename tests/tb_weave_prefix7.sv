`timescale 1ns/1ps
// Stage-1 test-only seventh woven ordinal, NOT full calendar RTL.
// Reads all earlier SHA-verified prefix blocks. One independent
// full-precision [1,2,3,4,5,6,1] block is provided by the new
// suffix-count kernel; other started-label blocks use exact ratios.
module tb_weave_prefix7;
    localparam integer WIDTH=22528, LIMBS=WIDTH/32, BYTES=2809;
    logic [WIDTH-1:0] root,rank,p11,p121,p122,p123;
    logic [WIDTH-1:0] p123i[1:4],p1234i[1:5];
    logic [WIDTH-1:0] p12345i[1:6],p123456i[1:7];
    logic [WIDTH-1:0] prior_rank,local_rank,old_blocks,all_blocks;
    integer i;

    task automatic read_binary(input string filename,
                               output logic [WIDTH-1:0] val);
        integer f,b,k;
        begin
            val='0; f=$fopen(filename,"rb");
            if(f==0) $fatal(1,"PREFIX7_INPUT_FILE_MISSING");
            for(k=BYTES-1;k>=0;k=k-1) begin
                b=$fgetc(f);
                if(b<0) $fatal(1,"PREFIX7_INPUT_TRUNCATED");
                val[k*8+:8]=b[7:0];
            end
            if($fgetc(f)!=-1) $fatal(1,"PREFIX7_INPUT_TOO_LONG");
            $fclose(f);
        end
    endtask
    task automatic write_binary(input string filename,
                                input logic [WIDTH-1:0] val);
        integer f,k;
        begin
            f=$fopen(filename,"wb");
            if(f==0) $fatal(1,"PREFIX7_OUTPUT_FILE_OPEN");
            for(k=BYTES-1;k>=0;k=k-1)
                $fwrite(f,"%c",val[k*8+:8]);
            $fclose(f);
        end
    endtask
    function automatic logic [WIDTH-1:0] exact_ratio(
        input logic [WIDTH-1:0] base,
        input integer mult,input integer denom
    );
        logic [WIDTH-1:0] numerator,quotient;
        logic [63:0] word,carry;
        integer limb;
        begin
            if(mult<=0 || denom<=0 || mult>1073741824 || denom>1073741824)
                $fatal(1,"PREFIX7_RATIO_RANGE");
            if(base[WIDTH-1:WIDTH-34]!=='0)
                $fatal(1,"PREFIX7_MULTIPLICATION_WIDTH_GUARD");
            numerator=base*WIDTH'(mult);
            quotient='0;carry='0;
            for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
                word=(carry<<32)|{32'b0,numerator[limb*32+:32]};
                quotient[limb*32+:32]=word/$unsigned(denom);
                carry=word%$unsigned(denom);
            end
            if(carry!==64'd0 || quotient*WIDTH'(denom)!==numerator)
                $fatal(1,"PREFIX7_RATIO_NONEXACT");
            exact_ratio=quotient;
        end
    endfunction

    initial begin
        read_binary("build/foundation_weave_root.bin",root);
        read_binary("build/foundation_weave_rank.bin",rank);
        read_binary("build/foundation_weave_prefix11.bin",p11);
        read_binary("build/foundation_weave_prefix121.bin",p121);
        read_binary("build/foundation_weave_prefix122.bin",p122);
        read_binary("build/foundation_weave_prefix123.bin",p123);
        for(i=1;i<=4;i=i+1)
            read_binary($sformatf("build/foundation_weave_prefix123%0d.bin",i),p123i[i]);
        for(i=1;i<=5;i=i+1)
            read_binary($sformatf("build/foundation_weave_prefix1234%0d.bin",i),p1234i[i]);
        for(i=1;i<=6;i=i+1)
            read_binary($sformatf("build/foundation_weave_prefix12345%0d.bin",i),p12345i[i]);
        read_binary("build/foundation_weave_prefix1234561.bin",p123456i[1]);

        if(root==0 || rank==0 || rank>root ||
           root!==p11+p121+p122+p123 ||
           p123!==p123i[1]+p123i[2]+p123i[3]+p123i[4] ||
           p123i[4]!==p1234i[1]+p1234i[2]+p1234i[3]+
                        p1234i[4]+p1234i[5] ||
           p1234i[5]!==p12345i[1]+p12345i[2]+p12345i[3]+
                          p12345i[4]+p12345i[5]+p12345i[6] ||
           p123456i[1]==0)
            $fatal(1,"PREFIX7_PREVIOUS_PARTITIONS_INVALID");

        // After selected prefix [1,2,3,4,5,6], positive active
        // remaining counts = [114,107,118,108,105,80].
        // Exact ratios of next old-label branches j vs branch 1:
        p123456i[2]=exact_ratio(p123456i[1],53,57);
        p123456i[3]=exact_ratio(p123456i[1],330,323);
        p123456i[4]=exact_ratio(p123456i[1],306020,328491);
        p123456i[5]=exact_ratio(p123456i[1],132658240,146835477);
        p123456i[6]=exact_ratio(p123456i[1],365288495,533244627);

        old_blocks='0;
        for(i=1;i<=6;i=i+1) old_blocks=old_blocks+p123456i[i];
        if(old_blocks>=p12345i[6])
            $fatal(1,"PREFIX7_OLD_BLOCKS_EXCEED_PARENT");
        p123456i[7]=p12345i[6]-old_blocks;
        all_blocks=old_blocks+p123456i[7];
        if(all_blocks!==p12345i[6])
            $fatal(1,"PREFIX7_BLOCK_SUM_CONSERVATION");

        // Subtract exactly the earlier lexicographic siblings of
        // each of the six preceding canonical choices.
        prior_rank=p11+p121+p122;
        for(i=1;i<=3;i=i+1) prior_rank=prior_rank+p123i[i];
        for(i=1;i<=4;i=i+1) prior_rank=prior_rank+p1234i[i];
        for(i=1;i<=5;i=i+1) prior_rank=prior_rank+p12345i[i];
        if(rank<=prior_rank)
            $fatal(1,"PREFIX7_RANK_BEFORE_PARENT");
        local_rank=rank-prior_rank;
        if(local_rank>p12345i[6] || local_rank<=old_blocks ||
           local_rank-old_blocks>p123456i[7])
            $fatal(1,"PREFIX7_GOLDEN_ORDINAL_NOT_SEVEN");

        for(i=2;i<=7;i=i+1)
            write_binary($sformatf("build/foundation_weave_prefix123456%0d.bin",i),
                         p123456i[i]);
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX7_PASS ordinals=1,2,3,4,5,6,7");
        $finish;
    end
endmodule
