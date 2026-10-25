`timescale 1ns/1ps
// Stage-1 test-only independent native SystemVerilog child-block counter.
// Reads only the H_7(746) and H_7(745) values from an archive
// CREATED by native SystemVerilog, not from a Python ledger.
// Computes A(r) and every old-month block by native binomial products.
// The fresh month 8 block is parent minus all seven old blocks.
// This does NOT implement the 4244-choice general unrank.
module tb_weave_native_H_children7;
    localparam integer WIDTH=22528, CWIDTH=864, CLIMBS=CWIDTH/32;
    localparam integer BE_BYTES=2809, REC_BYTES=5633;
    integer lengths[1:45], caps[1:45];
    integer f, n, s, q, t, i, j, fresh, copied, prefix, offset;
    logic [WIDTH-1:0] h_parent, h_child, parent, old_total;
    logic [WIDTH-1:0] children[1:8], factor_parent;
    logic [WIDTH:0] check_sum;

    function automatic logic [CWIDTH-1:0] exact_div_small(
        input logic [CWIDTH-1:0] input_value,
        input integer divisor
    );
        logic [CWIDTH-1:0] quotient;
        logic [63:0] limb_value,carry;
        integer k;
        begin
            if(divisor<=0 || divisor>4244)
                $fatal(1,"CHILDREN7_DIVISOR_RANGE");
            quotient='0;carry='0;
            for(k=CLIMBS-1;k>=0;k=k-1) begin
                limb_value=(carry<<32)|{32'b0,input_value[k*32+:32]};
                quotient[k*32+:32]=limb_value/$unsigned(divisor);
                carry=limb_value%$unsigned(divisor);
            end
            if(carry!==0)
                $fatal(1,"CHILDREN7_BINOMIAL_DIV_NOT_EXACT");
            exact_div_small=quotient;
        end
    endfunction
    function automatic logic [CWIDTH-1:0] binomial(
        input integer top,input integer k
    );
        integer idx,take;
        logic [CWIDTH-1:0] coeff,tmp;
        begin
            if(k<0 || k>top || top>4244)
                $fatal(1,"CHILDREN7_INVALID_BINOMIAL");
            take=(k<top-k)?k:top-k;
            coeff=CWIDTH'(1);
            for(idx=1;idx<=take;idx=idx+1) begin
                tmp=coeff*$unsigned(top-take+idx);
                coeff=exact_div_small(tmp,idx);
            end
            binomial=coeff;
        end
    endfunction

    function automatic logic [WIDTH-1:0] factor_A(
        input integer consumed_month
    );
        integer x,rest, running;
        logic [WIDTH-1:0] a;
        begin
            a=WIDTH'(1); running=0;
            for(x=1;x<=7;x=x+1) begin
                rest=lengths[x]-1;
                if(x==consumed_month) rest=rest-1;
                if(rest<1)
                    $fatal(1,"CHILDREN7_EXHAUSTED_ACTIVE_MONTH");
                if(running>0)
                    a=a*WIDTH'(binomial(running+rest-1,rest-1));
                running=running+rest;
            end
            factor_A=a;
        end
    endfunction

    task automatic H_lookup(input integer month_count,
                            input integer remaining_n,
                            output logic [WIDTH-1:0] val);
        integer idx,x,read_count;
        begin
            if(month_count<1 || month_count>45 ||
               remaining_n<0 || remaining_n>caps[month_count])
                $fatal(1,"CHILDREN7_INVALID_H_QUERY");
            idx=remaining_n;
            for(x=45;x>month_count;x=x-1)
                idx=idx+caps[x]+1;
            if($fseek(f,idx*REC_BYTES,0)!=0)
                $fatal(1,"CHILDREN7_H_SEEK_FAIL");
            read_count=$fscanf(f,"%h",val);
            if(read_count!=1)
                $fatal(1,"CHILDREN7_H_PARSE_FAIL");
        end
    endtask
    task automatic write_big(input string path,
                             input logic [WIDTH-1:0] val);
        integer out,k;
        begin
            out=$fopen(path,"wb");
            if(out==0) $fatal(1,"CHILDREN7_OUTPUT_OPEN");
            for(k=BE_BYTES-1;k>=0;k=k-1)
                $fwrite(out,"%c",val[k*8+:8]);
            $fclose(out);
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
        prefix=0;
        for(j=1;j<=45;j=j+1) begin
            prefix=prefix+lengths[j];
            caps[j]=prefix-j;
        end
        if(caps[7]!=746)
            $fatal(1,"CHILDREN7_FOUNDATION_PREFIX_CAP");
        f=$fopen("build/native_H_table.hex","r");
        if(f==0)
            $fatal(1,"CHILDREN7_NATIVE_TABLE_MISSING");
        H_lookup(7,746,h_parent);
        H_lookup(7,745,h_child);
        if(h_child>=h_parent)
            $fatal(1,"CHILDREN7_H_ORDER");
        factor_parent=factor_A(0);
        parent=factor_parent*h_parent;
        if(parent==0)
            $fatal(1,"CHILDREN7_ZERO_PARENT");
        write_big("build/native_H_children7_parent.bin",parent);
        old_total='0;
        for(i=1;i<=7;i=i+1) begin
            children[i]=factor_A(i)*h_child;
            check_sum={1'b0,old_total}+{1'b0,children[i]};
            if(check_sum[WIDTH] || check_sum[WIDTH-1:0]>parent)
                $fatal(1,"CHILDREN7_OLD_CHILDREN_EXCEED_PARENT");
            old_total=check_sum[WIDTH-1:0];
            write_big($sformatf("build/native_H_children7_%0d.bin",i),
                      children[i]);
        end
        children[8]=parent-old_total;
        if(children[8]==0 || parent!=old_total+children[8])
            $fatal(1,"CHILDREN7_FRESH_MONTH_PARTITION");
        write_big("build/native_H_children7_8.bin",children[8]);
        $fclose(f);
        $display("STAGE1_NATIVE_H_CHILDREN7_COUNT_PASS parent_and_eight_children=native_SV");
        $finish;
    end
endmodule
