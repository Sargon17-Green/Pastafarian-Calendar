`timescale 1ns/1ps
// Stage 1 independent fourth woven ordinal of Foundation's year.
// Requires binary inputs separately SHA-checked by CI. Not the full
// 4244-day lexical word; no natural-language string ordering.
module tb_weave_prefix4;
    localparam integer WIDTH=22528, LIMBS=WIDTH/32, BYTES=2809;
    logic [WIDTH-1:0] root,rank,p11,p121,p122,p123,p1231;
    logic [WIDTH-1:0] p1232,p1233,p1234,selected,old_prefix;
    logic [WIDTH-1:0] dividend,result;
    logic [63:0] word,carry;
    integer i,j,fh;

    task automatic read_binary(input string path,
                               output logic [WIDTH-1:0] val);
        integer f,b,k;
        begin
            val='0;
            f=$fopen(path,"rb");
            if(f==0) $fatal(1,"PREFIX4_INPUT_FILE_MISSING");
            for(k=BYTES-1;k>=0;k=k-1) begin
                b=$fgetc(f);
                if(b<0) $fatal(1,"PREFIX4_SHORT_INPUT");
                val[k*8+:8]=b[7:0];
            end
            if($fgetc(f)!=-1) $fatal(1,"PREFIX4_EXTRA_INPUT_BYTES");
            $fclose(f);
        end
    endtask

    task automatic write_binary(input string path,
                                input logic [WIDTH-1:0] val);
        integer f,k;
        begin
            f=$fopen(path,"wb");
            if(f==0) $fatal(1,"PREFIX4_OUTPUT_FILE_ERROR");
            for(k=BYTES-1;k>=0;k=k-1)
                $fwrite(f,"%c",val[k*8+:8]);
            $fclose(f);
        end
    endtask

    function automatic logic [WIDTH-1:0] exact_small_ratio(
        input logic [WIDTH-1:0] n,
        input integer multiplier,
        input integer divisor
    );
        logic [WIDTH-1:0] q,v;
        logic [63:0] current,rem;
        integer limb;
        begin
            if(divisor<1 || divisor>1024 || multiplier<1 || multiplier>1024)
                $fatal(1,"PREFIX4_RATIO_PARAMETERS");
            v=n*WIDTH'(multiplier);
            // The chosen blocks are much smaller than 22528-bit
            // space; this avoids unsigned multiply truncation.
            if(v<n) $fatal(1,"PREFIX4_MULTIPLICATION_OVERFLOW");
            q='0;rem='0;
            for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
                current=(rem<<32)|{32'b0,v[limb*32+:32]};
                q[limb*32+:32]=current/$unsigned(divisor);
                rem=current%$unsigned(divisor);
            end
            if(rem!==64'd0) $fatal(1,"PREFIX4_RATIO_NOT_EXACT");
            if(q*WIDTH'(divisor)!==v)
                $fatal(1,"PREFIX4_RATIO_RECONSTRUCTION");
            exact_small_ratio=q;
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
        if(root==0 || rank==0 || rank>root || p11==0 ||
           p121==0 || p122==0 || p123==0 || p1231==0)
            $fatal(1,"PREFIX4_BAD_VALIDATED_INPUT");
        // After fixed prefix [1,2,3] active remaining counts are
        // [114,107,118] and their total is 339.
        //
        // Exact last-occurrence-ordered active-word factors:
        // F(113,107,118) : F(114,106,118) : F(114,107,117)
        //               = 1 : 53/57 : 330/323.
        // All future fresh-month insertion counts depend only on
        // the unchanged total 338 remaining active copies.
        p1232=exact_small_ratio(p1231,53,57);
        p1233=exact_small_ratio(p1231,330,323);
        if(p1231+p1232+p1233>=p123 ||
           p11+p121+p122+p123!==root)
            $fatal(1,"PREFIX4_PARTITION_CONSERVATION");
        p1234=p123-p1231-p1232-p1233;
        selected=rank-p11-p121-p122;
        if(rank<=p11+p121+p122 ||
           selected<=p1231+p1232+p1233 ||
           selected-p1231-p1232-p1233>p1234)
            $fatal(1,"PREFIX4_EXPECTED_MONTH_FOUR");

        write_binary("build/foundation_weave_prefix1232.bin",p1232);
        write_binary("build/foundation_weave_prefix1233.bin",p1233);
        write_binary("build/foundation_weave_prefix1234.bin",p1234);
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX4_PASS ordinals=1,2,3,4");
        $finish;
    end
endmodule
