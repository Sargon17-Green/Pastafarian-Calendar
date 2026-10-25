`timescale 1ns/1ps
// Stage 1: native SystemVerilog *exact rank-interval replay* of 4243
// Python-produced (skipped, selected) arithmetic witness pairs.
// This replay checks wide-integer lexical rank arithmetic independently.
// It does NOT compute the witness blocks or perform full native unrank.
module tb_weave_full_rank_replay;
    localparam integer WIDTH=22528, BYTES=2809, DAYS=4244, MONTHS=45;
    logic [7:0] month_word[0:DAYS-1];
    logic [WIDTH-1:0] root,rank,parent,skipped,selected,remaining_rank;
    integer lengths[1:MONTHS],remaining[1:MONTHS];
    integer f,record_no,month,started,j;
    integer negative_test;

    task automatic read_big(input integer file_handle,
                            output logic [WIDTH-1:0] val);
        integer k,byte_read;
        begin
            val='0;
            for(k=BYTES-1;k>=0;k=k-1) begin
                byte_read=$fgetc(file_handle);
                if(byte_read<0)
                    $fatal(1,"FULL_YEAR_RANK_REPLAY_TRUNCATED_WITNESS");
                val[k*8+:8]=byte_read[7:0];
            end
        end
    endtask

    task automatic read_big_file(input string path,
                                 output logic [WIDTH-1:0] val);
        integer file_handle;
        begin
            file_handle=$fopen(path,"rb");
            if(file_handle==0)
                $fatal(1,"FULL_YEAR_RANK_REPLAY_MISSING_ROOT_OR_RANK");
            read_big(file_handle,val);
            if($fgetc(file_handle)!=-1)
                $fatal(1,"FULL_YEAR_RANK_REPLAY_WRONG_INTEGER_SIZE");
            $fclose(file_handle);
        end
    endtask

    initial begin
        lengths[1]=115;
        lengths[2]=108;
        lengths[3]=119;
        lengths[4]=109;
        lengths[5]=106;
        lengths[6]=81;
        lengths[7]=115;
        lengths[8]=114;
        lengths[9]=117;
        lengths[10]=120;
        lengths[11]=98;
        lengths[12]=52;
        lengths[13]=81;
        lengths[14]=97;
        lengths[15]=121;
        lengths[16]=97;
        lengths[17]=115;
        lengths[18]=96;
        lengths[19]=107;
        lengths[20]=61;
        lengths[21]=106;
        lengths[22]=115;
        lengths[23]=119;
        lengths[24]=39;
        lengths[25]=84;
        lengths[26]=103;
        lengths[27]=115;
        lengths[28]=107;
        lengths[29]=55;
        lengths[30]=119;
        lengths[31]=97;
        lengths[32]=50;
        lengths[33]=122;
        lengths[34]=110;
        lengths[35]=81;
        lengths[36]=54;
        lengths[37]=101;
        lengths[38]=83;
        lengths[39]=88;
        lengths[40]=40;
        lengths[41]=25;
        lengths[42]=77;
        lengths[43]=98;
        lengths[44]=122;
        lengths[45]=105;
        for(j=1;j<=MONTHS;j=j+1)
            remaining[j]=0;
        $readmemh("build/foundation_weave_all4244.hex",month_word);
        if(month_word[0]!=8'd1)
            $fatal(1,"FULL_YEAR_RANK_REPLAY_FIRST_MONTH");
        remaining[1]=lengths[1]-1;
        started=1;
        read_big_file("build/foundation_weave_root.bin",root);
        read_big_file("build/foundation_weave_rank.bin",rank);
        if(root==0 || rank==0 || rank>root ||
           root[22469]!==1'b1 || rank[22468]!==1'b1)
            $fatal(1,"FULL_YEAR_RANK_REPLAY_ROOT_RANK_RANGE");
        parent=root;
        negative_test=$test$plusargs("mutate_ledger");

        f=$fopen("build/foundation_weave_rank_intervals.bin","rb");
        if(f==0)
            $fatal(1,"FULL_YEAR_RANK_REPLAY_MISSING_WITNESS");
        for(record_no=2;record_no<=DAYS;record_no=record_no+1) begin
            read_big(f,skipped);
            read_big(f,selected);
            month=int'(month_word[record_no-1]);
            if(month<1 || month>MONTHS || month>started+1)
                $fatal(1,"FULL_YEAR_RANK_REPLAY_ILLEGAL_LEX_MONTH at=%0d",record_no);
            if(negative_test!=0 && record_no==2)
                skipped=rank;
            if(selected==0 || skipped>=rank || skipped>parent ||
               selected>parent-skipped)
                $fatal(1,"FULL_YEAR_RANK_REPLAY_INVALID_BLOCK at=%0d",record_no);
            remaining_rank=rank-skipped;
            if(remaining_rank==0 || remaining_rank>selected)
                $fatal(1,"FULL_YEAR_RANK_REPLAY_SELECTION_BOUND at=%0d",record_no);

            // A brand new label is the lexicographically last
            // admissible choice, and therefore must exhaust the
            // rightmost block of its parent count.
            if(month==started+1) begin
                if(skipped+selected!==parent)
                    $fatal(1,"FULL_YEAR_RANK_REPLAY_FRESH_TAIL at=%0d",record_no);
                started=started+1;
                remaining[started]=lengths[started]-1;
            end else begin
                if(remaining[month]<=0)
                    $fatal(1,"FULL_YEAR_RANK_REPLAY_MONTH_EXHAUSTED at=%0d",record_no);
                remaining[month]=remaining[month]-1;
            end
            rank=remaining_rank;
            parent=selected;
            if(record_no==8 || record_no==11 ||
               record_no==2032 || record_no==DAYS)
                $display("FULL_YEAR_RANK_REPLAY_PROGRESS position=%0d ordinal=%0d started=%0d",record_no,month,started);
        end
        if($fgetc(f)!=-1)
            $fatal(1,"FULL_YEAR_RANK_REPLAY_TRAILING_WITNESS");
        $fclose(f);
        if(started!=MONTHS || rank!==WIDTH'(1) || parent!==WIDTH'(1))
            $fatal(1,"FULL_YEAR_RANK_REPLAY_TERMINAL_RANK");
        for(j=1;j<=MONTHS;j=j+1)
            if(remaining[j]!=0)
                $fatal(1,"FULL_YEAR_RANK_REPLAY_UNCONSUMED_MONTH at=%0d",j);
        if(month_word[2031]!=8'd8)
            $fatal(1,"FULL_YEAR_RANK_REPLAY_FOUNDATION_MONTH");
        $display("STAGE1_FULL_YEAR_NATIVE_SV_EXACT_RANK_INTERVAL_REPLAY_PASS steps=4243 word_days=4244");
        $display("STAGE1_FULL_YEAR_NATIVE_SV_BLOCK_GENERATION_AND_PRODUCTION_RTL_STILL_PENDING");
        $finish;
    end
endmodule
