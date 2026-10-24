`timescale 1ns/1ps
// Stage 1 test-only ordinal #8, using independently SHA-verified prior
// block binaries and exactly ONE fresh 22528-bit suffix count.
// Signed 32-bit integer ratios are NOT safe for old month #7:
// 2917684055/2982394728, so use 64-bit unsigned numerator/divisor.
module tb_weave_prefix8;
    localparam integer WIDTH=22528, LIMBS=WIDTH/32, BYTES=2809;
    logic [WIDTH-1:0] root,rank,p11,p121,p122,p123;
    logic [WIDTH-1:0] p123i[1:4], p1234i[1:5];
    logic [WIDTH-1:0] p12345i[1:6], p123456i[1:7],p1234567i[1:8];
    logic [WIDTH-1:0] prior_rank,local_rank,old_blocks;
    integer i;

    task automatic read_binary(input string file_name,
                               output logic [WIDTH-1:0] val);
        integer f,b,k;
        begin
            val='0; f=$fopen(file_name,"rb");
            if(f==0) $fatal(1,"PREFIX8_MISSING_INPUT");
            for(k=BYTES-1;k>=0;k=k-1) begin
                b=$fgetc(f);
                if(b<0) $fatal(1,"PREFIX8_SHORT_INPUT");
                val[k*8+:8]=b[7:0];
            end
            if($fgetc(f)!=-1) $fatal(1,"PREFIX8_LONG_INPUT");
            $fclose(f);
        end
    endtask
    task automatic write_binary(input string file_name,
                                input logic [WIDTH-1:0] val);
        integer f,k;
        begin
            f=$fopen(file_name,"wb");
            if(f==0) $fatal(1,"PREFIX8_OUTPUT_OPEN");
            for(k=BYTES-1;k>=0;k=k-1)
                $fwrite(f,"%c",val[k*8+:8]);
            $fclose(f);
        end
    endtask
    function automatic logic [WIDTH-1:0] exact_ratio_64(
        input logic [WIDTH-1:0] base,
        input logic [63:0] numerator_factor,
        input logic [63:0] denominator
    );
        logic [WIDTH-1:0] numerator,quotient;
        logic [63:0] word,carry;
        integer limb;
        begin
            if(numerator_factor==0 || numerator_factor>64'd4294967295 ||
               denominator==0 || denominator>64'd4294967295)
                $fatal(1,"PREFIX8_RATIO_ARG_RANGE");
            if(base[WIDTH-1:WIDTH-34]!=='0)
                $fatal(1,"PREFIX8_32BIT_FACTOR_WIDTH_GUARD");
            numerator=base*WIDTH'(numerator_factor);
            quotient='0;carry='0;
            for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
                // Carry <2^32 and one 32-bit limb fit in 64 bits.
                word=(carry<<32)|{32'b0,numerator[limb*32+:32]};
                quotient[limb*32+:32]=word/denominator;
                carry=word%denominator;
            end
            if(carry!==64'd0 ||
               quotient*WIDTH'(denominator)!==numerator)
                $fatal(1,"PREFIX8_NONEXACT_RATIO");
            exact_ratio_64=quotient;
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
        for(i=1;i<=7;i=i+1)
            read_binary($sformatf("build/foundation_weave_prefix123456%0d.bin",i),p123456i[i]);
        read_binary("build/foundation_weave_prefix12345671.bin",p1234567i[1]);

        if(root==0 || rank==0 || rank>root || p1234567i[1]==0 ||
           root!==p11+p121+p122+p123 ||
           p123!==p123i[1]+p123i[2]+p123i[3]+p123i[4] ||
           p123i[4]!==p1234i[1]+p1234i[2]+p1234i[3]+
                        p1234i[4]+p1234i[5] ||
           p1234i[5]!==p12345i[1]+p12345i[2]+p12345i[3]+
                          p12345i[4]+p12345i[5]+p12345i[6] ||
           p12345i[6]!==p123456i[1]+p123456i[2]+p123456i[3]+
                          p123456i[4]+p123456i[5]+p123456i[6]+
                          p123456i[7])
            $fatal(1,"PREFIX8_PRIOR_PARTITIONS_INVALID");

        // Active remaining counts after [1..7]:
        // [114,107,118,108,105,80,114].
        // Candidate next-old-label blocks relative to next label 1.
        p1234567i[2]=exact_ratio_64(p1234567i[1],64'd53,64'd57);
        p1234567i[3]=exact_ratio_64(p1234567i[1],64'd330,64'd323);
        p1234567i[4]=exact_ratio_64(p1234567i[1],64'd306020,64'd328491);
        p1234567i[5]=exact_ratio_64(p1234567i[1],64'd132658240,64'd146835477);
        p1234567i[6]=exact_ratio_64(p1234567i[1],64'd365288495,64'd533244627);
        p1234567i[7]=exact_ratio_64(p1234567i[1],64'd2917684055,64'd2982394728);
        old_blocks='0;
        for(i=1;i<=7;i=i+1) old_blocks=old_blocks+p1234567i[i];
        if(old_blocks>=p123456i[7])
            $fatal(1,"PREFIX8_OLD_BLOCKS_EXCEED_PARENT");
        p1234567i[8]=p123456i[7]-old_blocks;
        if(old_blocks+p1234567i[8]!==p123456i[7])
            $fatal(1,"PREFIX8_BLOCK_PARTITION");

        // Earlier branches from each of the 7 canonical decisions.
        prior_rank=p11+p121+p122;
        for(i=1;i<=3;i=i+1) prior_rank=prior_rank+p123i[i];
        for(i=1;i<=4;i=i+1) prior_rank=prior_rank+p1234i[i];
        for(i=1;i<=5;i=i+1) prior_rank=prior_rank+p12345i[i];
        for(i=1;i<=6;i=i+1) prior_rank=prior_rank+p123456i[i];
        if(rank<=prior_rank)
            $fatal(1,"PREFIX8_RANK_BEFORE_PARENT");
        local_rank=rank-prior_rank;
        if(local_rank>p123456i[7] ||
           local_rank<=p1234567i[1]+p1234567i[2]+p1234567i[3] ||
           local_rank>p1234567i[1]+p1234567i[2]+p1234567i[3]+p1234567i[4])
            $fatal(1,"PREFIX8_GOLDEN_ORDINAL_NOT_FOUR");

        for(i=2;i<=8;i=i+1)
            write_binary($sformatf("build/foundation_weave_prefix1234567%0d.bin",i),
                         p1234567i[i]);
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX8_PASS ordinals=1,2,3,4,5,6,7,4");
        $finish;
    end
endmodule
