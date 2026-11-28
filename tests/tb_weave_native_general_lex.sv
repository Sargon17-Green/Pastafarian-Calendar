`timescale 1ns/1ps
// Stage-1 test-only native SystemVerilog lexical unrank. This module reads
// only native-SV generated H_s(N) and a pinned initial rank. It NEVER reads
// Python's word or rank-interval ledger. No production RTL claim is implied.
module tb_weave_native_general_lex;
// QA candidate: generalized host geometry and rank, native H table only.
// Not compiled or accepted. Does not select year, sauce, or rank natively.
localparam integer WIDTH=32768,CWIDTH=896,LIMBS=CWIDTH/32;
localparam integer MAXMONTHS=47,MAXDAYS=5778,BYTES=WIDTH/8,REC_BYTES=WIDTH/4+1;
integer MONTHS,DAYS,geom,scan_rc,extra,record_count,scan_tmp;
longint unsigned table_bytes;
string geom_path,root_path,rank_path,table_path,word_path;
integer lengths[1:MAXMONTHS],caps[1:MAXMONTHS],remaining[1:MAXMONTHS];
integer fd,out,k,n,started,position,max_positions,choice,prev_max;
integer mutate_old_h;
logic [WIDTH-1:0] rank,parent,h_parent,h_old,h_fresh;
logic [WIDTH-1:0] factor,child_factor,child[1:MAXMONTHS],fresh,old_sum;
logic [WIDTH-1:0] calculated_parent,selected_count,grandchild;
logic [WIDTH:0] wide_sum;
integer first_active,accum[1:MAXMONTHS];
logic [WIDTH-1:0] split_mass;
logic [WIDTH-1:0] fast_child_factor[1:MAXMONTHS];

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
    integer j,binomial_take;
    logic [CWIDTH-1:0] value,product;
    logic [CWIDTH+12:0] wide_product;
    begin
        if(top<0 || top>DAYS || bottom<0 || bottom>top || bottom>122)
            $fatal(1,"NATIVE_LEX_INVALID_BINOMIAL");
        binomial_take=(bottom<top-bottom)?bottom:top-bottom;
        value=CWIDTH'(1);
        for(j=1;j<=binomial_take;j=j+1) begin
            wide_product=(CWIDTH+13)'(value)*$unsigned(top-binomial_take+j);
            if(wide_product[CWIDTH+12:CWIDTH]!==13'd0) $fatal(1,"GENERAL_LEX_BINOMIAL_OVERFLOW");
            product=wide_product[CWIDTH-1:0];
            value=exact_div_small(product,j);
        end
        choose_exact=value;
    end
endfunction

// EXPERIMENTAL v010: exact x*m/d for 0<=m<=d<=DAYS.
// Reduce gcd; remove powers of two; divide odd part using a base-2^64
// modular inverse and signed carry. No truncation or non-exact ratios.
function automatic logic [WIDTH-1:0] split_ratio_exact(
    input logic [WIDTH-1:0] x,input integer numerator,input integer denominator);
    logic [WIDTH-1:0] y,q;
    logic [63:0] m,d,inv,qword,word;
    logic signed [127:0] carry,u,delta;
    integer g,a,b,t,words,i,shift;
    begin
        if(numerator<0 || denominator<1 || numerator>denominator || denominator>DAYS)
            $fatal(1,"NATIVE_LEX_RATIO_DOMAIN");
        if(numerator==0 || x=='0) split_ratio_exact='0;
        else if(numerator==denominator) split_ratio_exact=x;
        else begin
            a=numerator;b=denominator;
            while(b!=0) begin t=a%b;a=b;b=t;end
            g=a;m=$unsigned(numerator/g);d=$unsigned(denominator/g);
            words=WIDTH/64;
            while(words>0 && x[(words-1)*64+:64]=='0) words=words-1;
            y=x;shift=0;
            while(d[0]==0) begin
                if(y[0]!=0) $fatal(1,"NATIVE_LEX_RATIO_INEXACT_POWER2");
                y=y>>1;d=d>>1;shift=shift+1;
            end
            inv=64'd1;
            for(i=0;i<6;i=i+1) inv=inv*(64'd2-d*inv);
            if(64'(d*inv)!=64'd1) $fatal(1,"NATIVE_LEX_RATIO_BAD_INVERSE");
            q='0;carry=128'sd0;
            for(i=0;i<words;i=i+1) begin
                word=y[i*64+:64];
                u=$signed({64'b0,word})*$signed({64'b0,m})+carry;
                qword=u[63:0]*inv;
                delta=u-$signed({64'b0,qword})*$signed({64'b0,d});
                if(delta[63:0]!=0) $fatal(1,"NATIVE_LEX_RATIO_INTERNAL");
                carry=delta>>>64;
                q[i*64+:64]=qword;
            end
            if(carry!=128'sd0 || q>x) $fatal(1,"NATIVE_LEX_RATIO_INEXACT");
            split_ratio_exact=q;
        end
    end
endfunction

// Exact schoolbook product with active 256-bit limbs. Both input widths
// may be large, but zero/one (including H_45) bypass the limb loops.
function automatic logic [WIDTH-1:0] mul_checked(
    input logic [WIDTH-1:0] a,input logic [WIDTH-1:0] b);
    localparam integer NWORDS=WIDTH/256;
    logic [WIDTH-1:0] q;
    logic [255:0] aa,bb,carry;
    logic [511:0] t;
    integer na,nb,i,j,k;
    begin
        if(a=='0 || b=='0) mul_checked='0;
        else if(a==WIDTH'(1)) mul_checked=b;
        else if(b==WIDTH'(1)) mul_checked=a;
        else begin
            na=NWORDS;nb=NWORDS;
            while(na>0 && a[(na-1)*256+:256]=='0) na=na-1;
            while(nb>0 && b[(nb-1)*256+:256]=='0) nb=nb-1;
            q='0;
            for(j=0;j<nb;j=j+1) begin
                bb=b[j*256+:256];carry='0;
                if(bb!='0) begin
                    for(i=0;i<na;i=i+1) begin
                        aa=a[i*256+:256];k=i+j;
                        if(k>=NWORDS) begin
                            if(aa!='0 || carry!='0)
                                $fatal(1,"NATIVE_LEX_CHUNK_PRODUCT_OVERFLOW");
                        end else begin
                            t=aa*bb+{256'b0,q[k*256+:256]}+{256'b0,carry};
                            q[k*256+:256]=t[255:0];carry=t[511:256];
                        end
                    end
                    k=na+j;
                    if(carry!='0) begin
                        if(k>=NWORDS) $fatal(1,"NATIVE_LEX_CHUNK_CARRY_OVERFLOW");
                        if(q[k*256+:256]!='0) $fatal(1,"NATIVE_LEX_CHUNK_INTERNAL");
                        q[k*256+:256]=carry;
                    end
                end
            end
            mul_checked=q;
        end
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
                    value=mul_checked(value,WIDTH'(choose_exact(running-1,copies-1)));
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
    integer j,row_index,read_n;
    longint unsigned at;
    begin
        if(month_count<1 || month_count>MONTHS ||
           copies<0 || copies>caps[month_count])
            $fatal(1,"NATIVE_LEX_H_INDEX_RANGE");
        row_index=copies;
        for(j=MONTHS;j>month_count;j=j-1)
            row_index=row_index+caps[j]+1;
        at=64'(row_index)*REC_BYTES;
        if(at+REC_BYTES>table_bytes || at>64'd2147483647) $fatal(1,"GENERAL_LEX_H_OFFSET_RANGE");
        if($fseek(fd,at,0)!=0) $fatal(1,"NATIVE_LEX_H_SEEK_FAILURE");
        read_n=$fscanf(fd,"%h",value);
        if(read_n!=1 || $isunknown(value) || value==0 || $ftell(fd)!=at+REC_BYTES-1 || $fgetc(fd)!=10)
            $fatal(1,"NATIVE_LEX_H_READ_FAILURE");
    end
endtask

initial begin
    if(!$value$plusargs("geometry=%s",geom_path) || !$value$plusargs("root=%s",root_path) ||
       !$value$plusargs("rank=%s",rank_path) || !$value$plusargs("table=%s",table_path) ||
       !$value$plusargs("word=%s",word_path)) $fatal(1,"GENERAL_LEX_REQUIRED_PATHS");
    if(word_path==geom_path || word_path==root_path || word_path==rank_path || word_path==table_path)
        $fatal(1,"GENERAL_LEX_PATH_COLLISION");
    geom=$fopen(geom_path,"r");
    if(!geom) $fatal(1,"GENERAL_LEX_OPEN_GEOMETRY");
    scan_rc=$fscanf(geom,"%d",MONTHS);
    if(scan_rc!=1 || $isunknown(MONTHS) || MONTHS<1 || MONTHS>MAXMONTHS)
        $fatal(1,"GENERAL_LEX_MONTH_COUNT");
    DAYS=0;record_count=0;
    for(k=1;k<=MONTHS;k=k+1) begin
        scan_rc=$fscanf(geom,"%d",scan_tmp); lengths[k]=scan_tmp;
        if(scan_rc!=1 || $isunknown(lengths[k]) || lengths[k]<4 || lengths[k]>123)
            $fatal(1,"GENERAL_LEX_LENGTH");
        DAYS=DAYS+lengths[k];caps[k]=DAYS-k;remaining[k]=0;
        if(DAYS>MAXDAYS) $fatal(1,"GENERAL_LEX_DAY_CAP");
        record_count=record_count+caps[k]+1;
    end
    scan_rc=$fscanf(geom,"%d",extra);
    if(scan_rc!=-1) $fatal(1,"GENERAL_LEX_TRAILING_GEOMETRY");
    $fclose(geom);
    if(record_count>137663) $fatal(1,"GENERAL_LEX_RECORD_CAP");
    table_bytes=64'(record_count)*REC_BYTES;
    // Use only a non-Foundation H archive generated by the generalized H bench.
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
        max_positions=DAYS;
    if($isunknown(max_positions) || max_positions<1 || max_positions>DAYS)
        $fatal(1,"NATIVE_LEX_INVALID_POSITION_CAP");
    mutate_old_h=$test$plusargs("mutate_old_H");

    read_big(root_path,parent);
    read_big(rank_path,rank);
    if(parent==0 || rank==0 || rank>parent)
        $fatal(1,"NATIVE_LEX_RANK_RANGE");
    fd=$fopen(table_path,"rb");
    if(fd==0) $fatal(1,"NATIVE_LEX_MISSING_NATIVE_H_TABLE");
    if($fseek(fd,0,2)!=0 || $ftell(fd)!=table_bytes) $fatal(1,"GENERAL_LEX_H_SIZE");
    h_lookup(1,lengths[1]-1,h_parent);
    if(h_parent!==parent) $fatal(1,"GENERAL_LEX_ROOT_TABLE_MISMATCH");
    out=$fopen(word_path,"wb");
    if(out==0) $fatal(1,"NATIVE_LEX_OUTPUT_OPEN");
    $fwrite(out,"%c",8'd1);
    started=1;remaining[1]=lengths[1]-1;n=remaining[1];
    factor=WIDTH'(1);
    for(position=2;position<=max_positions;position=position+1) begin
        // Carry A(r) from the previous selected block. Split the integer
        // number of completions descending through active labels. Each
        // split uses m=r[k]-1 and d=accum[k]-1, not wide binomials.
        first_active=0;
        for(k=1;k<=started;k=k+1) begin
            if(remaining[k]<0) $fatal(1,"NATIVE_LEX_NEGATIVE_REMAINING");
            if(remaining[k]>0 && first_active==0) first_active=k;
            accum[k]=remaining[k]+((k==1)?0:accum[k-1]);
            fast_child_factor[k]='0;
        end
        if(accum[started]!=n) $fatal(1,"NATIVE_LEX_ACCUM_MISMATCH");
        if(first_active>0) begin
            for(k=first_active;k<=started;k=k+1)
                if(remaining[k]<=0)
                    $fatal(1,"NATIVE_LEX_FAST_INTERIOR_EXHAUSTION at=%0d",position);
            split_mass=factor;
            for(k=started;k>first_active;k=k-1) begin
                fast_child_factor[k]=split_ratio_exact(split_mass,remaining[k]-1,accum[k]-1);
                if(fast_child_factor[k]>split_mass) $fatal(1,"NATIVE_LEX_SPLIT_RANGE");
                split_mass=split_mass-fast_child_factor[k];
            end
            fast_child_factor[first_active]=split_mass;
        end else if(factor!==WIDTH'(1) || n!=0)
            $fatal(1,"NATIVE_LEX_EMPTY_FACTOR");
        if(position<=16 || position>=DAYS-16)
            if(factor!==factor_A())
                $fatal(1,"NATIVE_LEX_FAST_PARENT_REFERENCE_MISMATCH at=%0d",position);
        if(factor==0) $fatal(1,"NATIVE_LEX_ILLEGAL_PARENT_ORDER");
        h_lookup(started,n,h_parent);
        calculated_parent=mul_checked(factor,h_parent);
        if(calculated_parent!==parent)
            $fatal(1,"NATIVE_LEX_PARENT_COUNT_MISMATCH at=%0d",position);
        if(n>0) h_lookup(started,n-1,h_old);
        else h_old='0;
        if(mutate_old_h && position==2) h_old=h_old+WIDTH'(1);
        old_sum='0;
        for(k=1;k<=started;k=k+1) begin
            child[k]='0;
            if(remaining[k]>0) begin
                if(position<=16 || position>=DAYS-16) begin
                    remaining[k]=remaining[k]-1;
                    if(fast_child_factor[k]!==factor_A())
                        $fatal(1,"NATIVE_LEX_FAST_CHILD_REFERENCE_MISMATCH at=%0d month=%0d",position,k);
                    remaining[k]=remaining[k]+1;
                end
                child[k]=mul_checked(fast_child_factor[k],h_old);
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
            child_factor=mul_checked(factor,
                WIDTH'(choose_exact(n+lengths[started+1]-2,
                                    lengths[started+1]-2)));
            h_lookup(started+1,n+lengths[started+1]-1,h_fresh);
            grandchild=mul_checked(child_factor,h_fresh);
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
            factor=child_factor;
            choice=started;
        end else begin
            remaining[choice]=remaining[choice]-1;
            factor=fast_child_factor[choice];
            n=n-1;
        end
        if(selected_count==0 || rank==0 || rank>selected_count)
            $fatal(1,"NATIVE_LEX_SELECTED_BLOCK_RANGE at=%0d",position);
        parent=selected_count;
        $fwrite(out,"%c",choice);
        if(position%64==0) begin
            $display("NATIVE_LEX_V010_HEARTBEAT position=%0d started=%0d",position,started);
            $fflush(out);$fflush();
        end
    end
    $fclose(out);$fclose(fd);
    if(max_positions==DAYS) begin
        if(started!=MONTHS || rank!=WIDTH'(1) || parent!=WIDTH'(1) || factor!=WIDTH'(1))
            $fatal(1,"NATIVE_LEX_TERMINAL_RANK");
        for(k=1;k<=MONTHS;k=k+1)
            if(remaining[k]!=0)
                $fatal(1,"NATIVE_LEX_REMAINING_COPIES at=%0d",k);
        $display("GENERAL_LEX_TERMINAL_RANK_ONE days=%0d months=%0d",DAYS,MONTHS);
    end
    $display("GENERAL_LEX_CANDIDATE_PASS positions=%0d archive=native_H blocks=native_SV",
             max_positions);
    $finish;
end
endmodule
