`timescale 1ns/1ps
// QA candidate only, not production. Generalized native H transfer, one year.
// Input geometry is HOST data: text month count followed by that many lengths.
// No host H entries or expected root are read. Existing accepted H45 is unchanged.
// Example (not yet executed): iverilog -g2012 -s tb_weave_native_general_h
// -o general_h.vvp tests/tb_weave_native_general_h.sv
// timeout 240s vvp general_h.vvp +geometry=lengths.txt +root=root.bin
// Optional +table=H.hex emits descending rows; never request Foundation again.
// Proven domain: 1 <= m <= 47, 4 <= l_i <= 123, L <= 5778.
// H_s(N) counts suffixes with one fixed ordered old stream and new labels;
// replace the old stream by one symbol. At most 47 symbols, <= L positions.
// Thus every H entry, summand, partial sum, A factor, child and rank <=47^5778
// (32095 bits). Products before coefficient division <=5778*C(5778,122)
// (861 bits); 864 bits suffice, choose 896 for aligned margin.
// For future rational child-factor implementation, intermediate <=
// 47^5778*5778^47 (32682 bits); for choose-domain, M^253 (32131 bits),
// M=2^127-1. WIDTH=32768 accommodates these bounds, but future code must
// check each operation, not assume this bench proves rank or sauce.
// cap[s] <=122*s, so table has <=137663 records, 8193 bytes per record;
// use a 64-bit byte-offset in consumers (no signed-32-bit assumption).
// Scope: native H only, host geometry, no year selection/lex/tuple acceptance.
module tb_weave_native_general_h;
    localparam integer WIDTH=32768, CWIDTH=896, CLIMBS=CWIDTH/32;
    localparam integer MAXDAYS=5778, MAXMONTHS=47, FULL_BYTES=WIDTH/8;
    integer lengths[1:MAXMONTHS], cap[1:MAXMONTHS];
    integer m,L,s,n,j,v,f,rc,extra,outf,tf,records,expected_records,b,tmp_length;
    logic [WIDTH-1:0] next_row[0:MAXDAYS], row[0:MAXDAYS];
    logic [CWIDTH-1:0] coefficient;
    logic [CWIDTH+12:0] numerator;
    logic [WIDTH+CWIDTH-1:0] product;
    logic [WIDTH:0] sum;
    logic [WIDTH-1:0] running,root;
    string geom_path,root_path,table_path;

    function automatic logic [CWIDTH-1:0] divide_exact(
        input logic [CWIDTH-1:0] a, input integer d);
        logic [CWIDTH-1:0] q;
        logic [63:0] x,carry;
        integer i;
        begin
            if(d<1 || d>MAXDAYS) $fatal(1,"GENERAL_H_DIVISOR");
            q='0;carry='0;
            for(i=CLIMBS-1;i>=0;i=i-1) begin
                x=(carry<<32)|{32'b0,a[i*32+:32]};
                q[i*32+:32]=x/$unsigned(d);
                carry=x%$unsigned(d);
            end
            if(carry!==64'd0) $fatal(1,"GENERAL_H_NONEXACT_DIV");
            divide_exact=q;
        end
    endfunction

    function automatic integer bit_length(input logic [WIDTH-1:0] x);
        integer i;
        begin
            bit_length=0;
            for(i=WIDTH-1;i>=0;i=i-1)
                if(x[i] && bit_length==0) bit_length=i+1;
        end
    endfunction

    initial begin
        if(!$value$plusargs("geometry=%s",geom_path) ||
           !$value$plusargs("root=%s",root_path))
            $fatal(1,"GENERAL_H_REQUIRED_PATHS");
        if(geom_path==root_path) $fatal(1,"GENERAL_H_PATH_COLLISION");
        tf=0;
        if($value$plusargs("table=%s",table_path)) begin
            if(table_path==geom_path || table_path==root_path)
                $fatal(1,"GENERAL_H_PATH_COLLISION");
        end
        f=$fopen(geom_path,"r");
        if(!f) $fatal(1,"GENERAL_H_OPEN_GEOMETRY");
        rc=$fscanf(f,"%d",m);
        if(rc!=1 || m<1 || m>MAXMONTHS) $fatal(1,"GENERAL_H_MONTH_COUNT");
        L=0;expected_records=0;
        for(j=1;j<=m;j=j+1) begin
            rc=$fscanf(f,"%d",tmp_length); lengths[j]=tmp_length;
            if(rc!=1 || lengths[j]<4 || lengths[j]>123)
                $fatal(1,"GENERAL_H_LENGTH");
            L=L+lengths[j];cap[j]=L-j;
            if(L>MAXDAYS) $fatal(1,"GENERAL_H_DAY_CAP");
            expected_records=expected_records+cap[j]+1;
        end
        rc=$fscanf(f,"%d",extra);
        if(rc!=-1) $fatal(1,"GENERAL_H_TRAILING_GEOMETRY");
        $fclose(f);
        if(expected_records>137663) $fatal(1,"GENERAL_H_RECORD_CAP");
        if(table_path!="") begin
            tf=$fopen(table_path,"w");
            if(!tf) $fatal(1,"GENERAL_H_TABLE_OPEN");
        end
        records=0;
        for(n=0;n<=cap[m];n=n+1) begin
            next_row[n]=WIDTH'(1);
            if(tf) $fwrite(tf,"%h\n",next_row[n]);
            records=records+1;
        end
        for(s=m-1;s>=1;s=s-1) begin
            v=lengths[s+1]; coefficient=CWIDTH'(1); running='0;
            for(n=0;n<=cap[s];n=n+1) begin
                if(n>0) begin
                    numerator=(CWIDTH+13)'(coefficient)*$unsigned(n+v-2);
                    if(numerator[CWIDTH+12:CWIDTH]!==13'd0)
                        $fatal(1,"GENERAL_H_COEFFICIENT_OVERFLOW");
                    coefficient=divide_exact(numerator[CWIDTH-1:0],n);
                end
                if(n+v-1>cap[s+1]) $fatal(1,"GENERAL_H_INDEX");
                product=(WIDTH+CWIDTH)'(next_row[n+v-1])*coefficient;
                if(product[WIDTH+CWIDTH-1:WIDTH]!=={CWIDTH{1'b0}})
                    $fatal(1,"GENERAL_H_PRODUCT_OVERFLOW");
                sum={1'b0,running}+{1'b0,product[WIDTH-1:0]};
                if(sum[WIDTH]!==1'b0 || sum[WIDTH-1:0]===WIDTH'(0))
                    $fatal(1,"GENERAL_H_SUM_OVERFLOW_OR_ZERO");
                running=sum[WIDTH-1:0];row[n]=running;
                if(tf) $fwrite(tf,"%h\n",running);
                records=records+1;
            end
            for(n=0;n<=cap[s];n=n+1) next_row[n]=row[n];
            $display("GENERAL_H_PROGRESS s=%0d cap=%0d bits=%0d",s,cap[s],bit_length(running));
            $fflush();
        end
        if(tf) $fclose(tf);
        if(records!=expected_records) $fatal(1,"GENERAL_H_RECORD_COUNT");
        root=next_row[lengths[1]-1];
        if(bit_length(root)<1 || bit_length(root)>32095)
            $fatal(1,"GENERAL_H_ROOT_BOUND");
        outf=$fopen(root_path,"wb");
        if(!outf) $fatal(1,"GENERAL_H_ROOT_OPEN");
        for(b=FULL_BYTES-1;b>=0;b=b-1) $fwrite(outf,"%c",root[b*8+:8]);
        $fclose(outf);
        $display("GENERAL_H_CANDIDATE_PASS months=%0d days=%0d records=%0d root_bits=%0d",m,L,records,bit_length(root));
        $finish;
    end
endmodule
