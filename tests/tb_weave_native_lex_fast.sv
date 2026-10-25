`timescale 1ns/1ps
// Stage-1 test-only native SystemVerilog lexical unrank. This module reads
// only native-SV generated H_s(N) and a pinned initial rank. It NEVER reads
// Python's word or rank-interval ledger. No production RTL claim is implied.
module tb_weave_native_lex_fast;
localparam integer WIDTH=22528,CWIDTH=864,LIMBS=27;
localparam integer MONTHS=45,DAYS=4244,BYTES=2809,REC_BYTES=5633;
integer lengths[1:MONTHS],caps[1:MONTHS],remaining[1:MONTHS];
integer fd,out,k,n,started,position,max_positions,choice,prev_max;
integer mutate_old_h;
logic [WIDTH-1:0] rank,parent,h_parent,h_old,h_fresh;
logic [WIDTH-1:0] factor,child_factor,child[1:MONTHS],fresh,old_sum;
logic [WIDTH-1:0] calculated_parent,selected_count,grandchild;
logic [WIDTH:0] wide_sum;
integer first_active,accum[1:MONTHS];
logic [WIDTH-1:0] prefix_factor[1:MONTHS],suffix_factor[1:MONTHS];
logic [WIDTH-1:0] fast_child_factor[1:MONTHS];

function automatic logic [CWIDTH-1:0] exact_div_small(
    input logic [CWIDTH-1:0] dividend,input integer divisor);
    logic [CWIDTH-1:0] quotient;
    logic [63:0] v,carry;
    integer limb;
    begin
        if(divisor<1 || divisor>DAYS)
            $fatal(1,"NATIVE_LEX_INVALID_DIVISOR");
        quotient='0;carry='0;
        for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
            v=(carry<<32)|{32'b0,dividend[limb*32+:32]};
            quotient[limb*32+:32]=v/$unsigned(divisor);
            carry=v%$unsigned(divisor);
        end
        if(carry!=0) $fatal(1,"NATIVE_LEX_INEXACT_DIVISION");
        exact_div_small=quotient;
    end
endfunction

function automatic logic [CWIDTH-1:0] choose_exact(
    input integer top,input integer bottom);
    integer j,small;
    logic [CWIDTH-1:0] value,product;
    begin
        if(top<0 || top>DAYS || bottom<0 || bottom>top)
            $fatal(1,"NATIVE_LEX_INVALID_BINOMIAL");
        small=(bottom<top-bottom)?bottom:top-bottom;
        value=CWIDTH'(1);
        for(j=1;j<=small;j=j+1) begin
            product=value*$unsigned(top-small+j);
            value=exact_div_small(product,j);
        end
        choose_exact=value;
    end
endfunction

// Completed month labels can be zero only in a leading prefix;
// otherwise the ascending-last-appearance constraint is violated.
function automatic logic [WIDTH-1:0] factor_A();
    integer j,running,copies;
    logic saw_positive;
    logic [WIDTH-1:0] value;
    begin
        value=WIDTH'(1);running=0;saw_positive=0;
        for(j=1;j<=started;j=j+1) begin
            copies=remaining[j];
            if(copies<0) $fatal(1,"NATIVE_LEX_NEGATIVE_REMAINING");
            if(copies==0) begin
                if(saw_positive) value='0;
            end else if(value!=0) begin
                saw_positive=1;
                running=running+copies;
                if(running>copies)
                    value=value*WIDTH'(choose_exact(running-1,copies-1));
            end
        end
        factor_A=value;
    end
endfunction

task automatic read_big(input string path,output logic [WIDTH-1:0] value);
    integer f,j,b;
    begin
        value='0;
        f=$fopen(path,"rb");
        if(f==0) $fatal(1,"NATIVE_LEX_MISSING_RANK_OR_ROOT");
        for(j=BYTES-1;j>=0;j=j-1) begin
            b=$fgetc(f);
            if(b<0) $fatal(1,"NATIVE_LEX_TRUNCATED_RANK_OR_ROOT");
            value[j*8+:8]=b[7:0];
        end
        if($fgetc(f)!=-1) $fatal(1,"NATIVE_LEX_OVERSIZE_RANK_OR_ROOT");
        $fclose(f);
    end
endtask

task automatic h_lookup(input integer month_count,input integer copies,
                        output logic [WIDTH-1:0] value);
    integer j,cell,at,read_n;
    begin
        if(month_count<1 || month_count>MONTHS ||
           copies<0 || copies>caps[month_count])
            $fatal(1,"NATIVE_LEX_H_INDEX_RANGE");
        cell=copies;
        for(j=MONTHS;j>month_count;j=j-1)
            cell=cell+caps[j]+1;
        at=cell*REC_BYTES;
        if($fseek(fd,at,0)!=0) $fatal(1,"NATIVE_LEX_H_SEEK_FAILURE");
        read_n=$fscanf(fd,"%h",value);
        if(read_n!=1) $fatal(1,"NATIVE_LEX_H_READ_FAILURE");
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
    prev_max=0;
    for(k=1;k<=MONTHS;k=k+1) begin
        prev_max=prev_max+lengths[k];
        caps[k]=prev_max-k;
        remaining[k]=0;
    end
    if(prev_max!=DAYS || caps[45]!=4199)
        $fatal(1,"NATIVE_LEX_INVALID_DIMENSIONS");
    // Exhaustion-order corner cases, independent of the H archive.
    started=3;
    remaining[1]=0;remaining[2]=1;remaining[3]=2;
    if(factor_A()!==WIDTH'(2)) $fatal(1,"NATIVE_LEX_EDGE_LEADING_ZERO");
    remaining[1]=1;remaining[2]=0;remaining[3]=2;
    if(factor_A()!==WIDTH'(0)) $fatal(1,"NATIVE_LEX_EDGE_INTERIOR_ZERO");
    remaining[1]=1;remaining[2]=2;remaining[3]=0;
    if(factor_A()!==WIDTH'(0)) $fatal(1,"NATIVE_LEX_EDGE_TRAILING_ZERO");
    remaining[1]=0;remaining[2]=0;remaining[3]=2;
    if(factor_A()!==WIDTH'(1)) $fatal(1,"NATIVE_LEX_EDGE_ONLY_LAST_ACTIVE");
    remaining[1]=0;remaining[2]=0;remaining[3]=0;
    if(factor_A()!==WIDTH'(1)) $fatal(1,"NATIVE_LEX_EDGE_ALL_EXHAUSTED");
    remaining[1]=2;remaining[2]=1;remaining[3]=2;
    if(factor_A()!==WIDTH'(4)) $fatal(1,"NATIVE_LEX_EDGE_FULL_ACTIVE");
    for(k=1;k<=MONTHS;k=k+1) remaining[k]=0;
    $display("STAGE1_NATIVE_LEX_EXHAUSTED_MONTH_CASES_PASS cases=6");

    if(!$value$plusargs("max_positions=%d",max_positions))
        max_positions=64;
    if(max_positions<2 || max_positions>DAYS)
        $fatal(1,"NATIVE_LEX_INVALID_POSITION_CAP");
    mutate_old_h=$test$plusargs("mutate_old_H");

    read_big("build/native_H_root.bin",parent);
    read_big("build/native_lex_rank.bin",rank);
    if(parent==0 || rank==0 || rank>parent)
        $fatal(1,"NATIVE_LEX_RANK_RANGE");
    fd=$fopen("build/native_H_table.hex","r");
    if(fd==0) $fatal(1,"NATIVE_LEX_MISSING_NATIVE_H_TABLE");
    out=$fopen("build/native_lex_fast_prefix.bin","wb");
    if(out==0) $fatal(1,"NATIVE_LEX_OUTPUT_OPEN");
    $fwrite(out,"%c",8'd1);
    started=1;remaining[1]=lengths[1]-1;n=remaining[1];
    for(position=2;position<=max_positions;position=position+1) begin
        // Precompute A(r-e_i) for ALL candidates in O(started)
        // binomial calls, rather than O(started^2) repeated products.
        first_active=0;
        for(k=1;k<=started;k=k+1) begin
            if(remaining[k]>0 && first_active==0) first_active=k;
            accum[k]=remaining[k]+((k==1)?0:accum[k-1]);
            fast_child_factor[k]='0;
        end
        factor=WIDTH'(1);
        if(first_active>0) begin
            for(k=first_active;k<=started;k=k+1)
                if(remaining[k]<=0)
                    $fatal(1,"NATIVE_LEX_FAST_INTERIOR_EXHAUSTION at=%0d",position);
            prefix_factor[first_active]=WIDTH'(1);
            for(k=first_active+1;k<=started;k=k+1)
                prefix_factor[k]=prefix_factor[k-1]*
                    WIDTH'(choose_exact(accum[k]-1,remaining[k]-1));
            suffix_factor[started]=WIDTH'(1);
            for(k=started-1;k>=first_active;k=k-1)
                suffix_factor[k]=suffix_factor[k+1]*
                    WIDTH'(choose_exact(accum[k+1]-2,remaining[k+1]-1));
            factor=prefix_factor[started];
            fast_child_factor[first_active]=suffix_factor[first_active];
            for(k=first_active+1;k<=started;k=k+1)
                if(remaining[k]>1)
                    fast_child_factor[k]=prefix_factor[k-1]*
                        WIDTH'(choose_exact(accum[k]-2,remaining[k]-2))*
                        suffix_factor[k];
        end
        if(position<=64 || position==255 || position==256 ||
           position>=DAYS-105)
            if(factor!==factor_A())
                $fatal(1,"NATIVE_LEX_FAST_PARENT_REFERENCE_MISMATCH at=%0d",position);
        if(factor==0) $fatal(1,"NATIVE_LEX_ILLEGAL_PARENT_ORDER");
        h_lookup(started,n,h_parent);
        calculated_parent=factor*h_parent;
        if(calculated_parent!==parent)
            $fatal(1,"NATIVE_LEX_PARENT_COUNT_MISMATCH at=%0d",position);
        if(n>0) h_lookup(started,n-1,h_old);
        else h_old='0;
        if(mutate_old_h && position==2) h_old=h_old+WIDTH'(1);
        old_sum='0;
        for(k=1;k<=started;k=k+1) begin
            child[k]='0;
            if(remaining[k]>0) begin
                if(position<=64 || position>=DAYS-105) begin
                    remaining[k]=remaining[k]-1;
                    if(fast_child_factor[k]!==factor_A())
                        $fatal(1,"NATIVE_LEX_FAST_CHILD_REFERENCE_MISMATCH at=%0d month=%0d",position,k);
                    remaining[k]=remaining[k]+1;
                end
                child[k]=fast_child_factor[k]*h_old;
            end
            wide_sum={1'b0,old_sum}+{1'b0,child[k]};
            if(wide_sum[WIDTH] || wide_sum[WIDTH-1:0]>parent)
                $fatal(1,"NATIVE_LEX_OLD_BLOCK_OVERFLOW at=%0d",position);
            old_sum=wide_sum[WIDTH-1:0];
        end
        fresh=parent-old_sum;
        if(started==MONTHS) begin
            if(fresh!=0)
                $fatal(1,"NATIVE_LEX_EXTRA_FRESH_MONTH at=%0d",position);
        end else begin
            // Independently verify rightmost first-fresh block by H_(s+1).
            child_factor=factor*
                WIDTH'(choose_exact(n+lengths[started+1]-2,
                                    lengths[started+1]-2));
            h_lookup(started+1,n+lengths[started+1]-1,h_fresh);
            grandchild=child_factor*h_fresh;
            if(fresh!==grandchild)
                $fatal(1,"NATIVE_LEX_FRESH_PARTITION_MISMATCH at=%0d",position);
        end
        choice=0;selected_count='0;
        for(k=1;k<=started;k=k+1) begin
            if(choice==0) begin
                if(child[k]>0 && rank<=child[k]) begin
                    choice=k;selected_count=child[k];
                end else rank=rank-child[k];
            end
        end
        if(choice==0) begin
            if(started==MONTHS || fresh==0 || rank==0 || rank>fresh)
                $fatal(1,"NATIVE_LEX_UNRANK_NO_CHOICE at=%0d",position);
            started=started+1;
            remaining[started]=lengths[started]-1;
            n=n+remaining[started];
            selected_count=fresh;
            choice=started;
        end else begin
            remaining[choice]=remaining[choice]-1;
            n=n-1;
        end
        if(selected_count==0 || rank==0 || rank>selected_count)
            $fatal(1,"NATIVE_LEX_SELECTED_BLOCK_RANGE at=%0d",position);
        parent=selected_count;
        if(position==255 && started!=45)
            $fatal(1,"NATIVE_LEX_FAST_MONTH45_START_BOUNDARY");
        if(position==256 && started!=45)
            $fatal(1,"NATIVE_LEX_FAST_ALL_45_STARTED_BOUNDARY");
        $fwrite(out,"%c",choice);
        if(position==8 || position==11 || position==32 ||
           position==64 || position==255 || position==256 || position==2032 || position==DAYS) begin
            $display("NATIVE_LEX_PREFIX_PROGRESS position=%0d ordinal=%0d started=%0d",
                     position,choice,started);
            $fflush();
        end
    end
    $fclose(out);$fclose(fd);
    if(max_positions==DAYS) begin
        if(started!=MONTHS || rank!=WIDTH'(1) || parent!=WIDTH'(1))
            $fatal(1,"NATIVE_LEX_TERMINAL_RANK");
        for(k=1;k<=MONTHS;k=k+1)
            if(remaining[k]!=0)
                $fatal(1,"NATIVE_LEX_REMAINING_COPIES at=%0d",k);
    end
    $display("STAGE1_NATIVE_LEX_FAST_SV_PASS positions=%0d archive=native_H blocks=native_SV",
             max_positions);
    $finish;
end
endmodule
