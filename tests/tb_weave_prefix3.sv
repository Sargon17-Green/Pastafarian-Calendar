`timescale 1ns/1ps
// Test-only exact third woven ordinal of Foundation's selected word.
// Runner MUST validate full-root, full-rank, prefix11 and prefix121
// SHA256 BEFORE executing this testbench. No assumptions of contiguous
// month blocks; ordinal index is NOT the canonical month-name index.
module tb_weave_prefix3;
    localparam integer WIDTH=22528, LIMBS=WIDTH/32, BYTES=2809;
    logic [WIDTH-1:0] full_count, selected_rank, prefix11, prefix121;
    logic [WIDTH-1:0] prefix122, prefix123, remaining_rank;
    logic [WIDTH-1:0] numerator, quotient;
    logic [63:0] word, carry;
    integer k,i,fh,j;
    task automatic read_binary(
        input string filename, output logic [WIDTH-1:0] value
    );
        integer handle, octet, pos;
        begin
            value='0;
            handle=$fopen(filename,"rb");
            if(handle==0) $fatal(1,"PREFIX3_INPUT_NOT_FOUND");
            for(pos=BYTES-1;pos>=0;pos=pos-1) begin
                octet=$fgetc(handle);
                if(octet<0) $fatal(1,"PREFIX3_SHORT_FILE");
                value[pos*8+:8]=octet[7:0];
            end
            if($fgetc(handle)!=-1) $fatal(1,"PREFIX3_EXTRA_BYTES");
            $fclose(handle);
        end
    endtask

    task automatic write_binary(
        input string filename, input logic [WIDTH-1:0] value
    );
        integer handle, pos;
        begin
            handle=$fopen(filename,"wb");
            if(handle==0) $fatal(1,"PREFIX3_OUTPUT_OPEN");
            for(pos=BYTES-1;pos>=0;pos=pos-1)
                $fwrite(handle,"%c",value[pos*8+:8]);
            $fclose(handle);
        end
    endtask

    initial begin
        read_binary("build/foundation_weave_root.bin",full_count);
        read_binary("build/foundation_weave_rank.bin",selected_rank);
        read_binary("build/foundation_weave_prefix11.bin",prefix11);
        read_binary("build/foundation_weave_prefix121.bin",prefix121);
        if(selected_rank==0 || selected_rank>full_count ||
           prefix11>=full_count || prefix121>=full_count)
            $fatal(1,"PREFIX3_INVALID_INPUT");

        // Once months 1 and 2 have BOTH first appeared, last-order
        // constraints give the active two-month subsequence count:
        // prefix121 active factor C(219,113)
        // prefix122 active factor C(219,114).
        // All later fresh-month transfers depend on *total* active
        // length 220 only. Hence prefix122 = prefix121*(106/114)
        // = prefix121*(53/57). Exact divide by 57 limb-by-limb.
        numerator=prefix121*WIDTH'(53);
        quotient='0;carry='0;
        for(k=LIMBS-1;k>=0;k=k-1) begin
            word=(carry<<32)|{32'b0,numerator[k*32+:32]};
            quotient[k*32+:32]=word/64'd57;
            carry=word%64'd57;
        end
        if(carry!==64'd0)
            $fatal(1,"PREFIX3_RATIO_NOT_EXACT");
        prefix122=quotient;
        if(prefix122*WIDTH'(57)!==prefix121*WIDTH'(53))
            $fatal(1,"PREFIX3_RATIO_INVARIANT");

        // After [1,2], the next symbol is restricted to
        // 1, 2, or first appearance of 3, in that lexical order.
        if(full_count<=prefix11+prefix121+prefix122)
            $fatal(1,"PREFIX3_BLOCKS_EXCEED_ROOT");
        prefix123=full_count-prefix11-prefix121-prefix122;
        remaining_rank=selected_rank-prefix11;
        if(selected_rank<=prefix11 || remaining_rank<=prefix121+prefix122 ||
           remaining_rank-prefix121-prefix122>prefix123)
            $fatal(1,"PREFIX3_EXPECTED_MONTH_THREE");
        write_binary("build/foundation_weave_prefix122.bin",prefix122);
        write_binary("build/foundation_weave_prefix123.bin",prefix123);
        $display("STAGE1_FOUNDATION_WEAVE_LEX_PREFIX3_PASS first=1 second=2 third=3");
        $finish;
    end
endmodule
