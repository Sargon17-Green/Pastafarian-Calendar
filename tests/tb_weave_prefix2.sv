`timescale 1ns/1ps
// Test-only first two canonical month ordinals of the Foundation weave.
// Inputs are the root count, rank and suffix-block SHA-checked by CI.
// This code does not substitute for the remaining 4242 lexical decisions.
module tb_weave_prefix2;
    localparam integer WIDTH=22528;
    localparam integer NUM_BYTES=2809;
    logic [WIDTH-1:0] count_all, count_prefix11, rank;
    logic [WIDTH-1:0] prefix12_count, remaining_rank;
    integer file_in,i,bytevalue,which,ordinal;
    task automatic read_exact(
        input string filename,output logic [WIDTH-1:0] val
    );
        integer fh,bb,j;
        begin
            val='0;
            fh=$fopen(filename,"rb");
            if(fh==0) $fatal(1,"PREFIX2_OPEN_FAILED");
            for(j=NUM_BYTES-1;j>=0;j=j-1) begin
                bb=$fgetc(fh);
                if(bb<0) $fatal(1,"PREFIX2_SHORT_INPUT");
                val[j*8+:8]=bb[7:0];
            end
            if($fgetc(fh)!=-1) $fatal(1,"PREFIX2_LONG_INPUT");
            $fclose(fh);
        end
    endtask

    initial begin
        read_exact("build/foundation_weave_root.bin",count_all);
        read_exact("build/foundation_weave_prefix11.bin",count_prefix11);
        read_exact("build/foundation_weave_rank.bin",rank);
        if(count_all==0 || rank==0 || rank>count_all ||
           count_prefix11==0 || count_prefix11>=count_all)
            $fatal(1,"PREFIX2_INPUT_RANGE");
        if(count_prefix11[22464]!==1'b1 ||
           count_prefix11[WIDTH-1:22465]!=='0)
            $fatal(1,"PREFIX11_WIDTH");
        prefix12_count=count_all-count_prefix11;
        // First symbol must be month 1. Next symbol can be only
        // month 1 or first appearance of month 2.
        if(rank<=count_prefix11) begin
            ordinal=1;
            remaining_rank=rank;
        end else begin
            ordinal=2;
            remaining_rank=rank-count_prefix11;
        end
        if(ordinal!=2 || remaining_rank==0 ||
           remaining_rank>prefix12_count)
            $fatal(1,"FOUNDATION_WEAVE_FIRST_TWO_GOLDEN");
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX_PASS first=1 second=2 prefix11bits=22465 remainingbits=%0d",
                 WIDTH);
        $finish;
    end
endmodule
