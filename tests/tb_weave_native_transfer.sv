`timescale 1ns/1ps
// Test-only native SystemVerilog count transfer H_s(N).
// Unlike the reference-interval replay, this bench COMPUTES the
// exact huge count coefficients itself, without a Python block ledger.
// Still not synthesizable production ASIC calendar RTL or full unrank.
module tb_weave_native_transfer;
    parameter integer WIDTH=22528, NMONTHS=45;
    localparam integer CWIDTH=864, CLIMBS=CWIDTH/32;
    localparam integer MAXDAYS=4244, FULL_BYTES=2809;
    integer month_length[1:45], cap[1:45], s,n,j,v,save_f;
    integer total_days, prefix_sum, bit_count;
    logic [WIDTH-1:0] next_row[0:MAXDAYS], row[0:MAXDAYS];
    logic [CWIDTH-1:0] coefficient,small_numerator;
    logic [WIDTH-1:0] term,prev_value,sum_check_root;
    logic [WIDTH:0] checked_sum;
    logic [WIDTH-1:0] checkpoint;

    function automatic logic [CWIDTH-1:0] div_small_exact(
        input logic [CWIDTH-1:0] input_number, input integer divisor
    );
        logic [CWIDTH-1:0] result;
        logic [63:0] curr,carry;
        integer limb;
        begin
            if(divisor<=0 || divisor>MAXDAYS)
                $fatal(1,"NATIVE_H_DIVISOR_OUT_OF_RANGE");
            result='0; carry='0;
            for(limb=CLIMBS-1;limb>=0;limb=limb-1) begin
                curr=(carry<<32)|{32'b0,input_number[limb*32+:32]};
                result[limb*32+:32]=curr/$unsigned(divisor);
                carry=curr%$unsigned(divisor);
            end
            if(carry!==64'd0)
                $fatal(1,"NATIVE_H_NONEXACT_COEFFICIENT_DIVISION");
            div_small_exact=result;
        end
    endfunction

    function automatic logic [CWIDTH-1:0] choose_exact(
        input integer top, input integer bottom
    );
        logic [CWIDTH-1:0] value,tmp;
        integer q,short_k;
        begin
            if(bottom<0 || bottom>top || top>MAXDAYS)
                $fatal(1,"NATIVE_H_BAD_BINOMIAL");
            short_k=(bottom<top-bottom)?bottom:top-bottom;
            value=CWIDTH'(1);
            for(q=1;q<=short_k;q=q+1) begin
                tmp=value*$unsigned(top-short_k+q);
                value=div_small_exact(tmp,q);
            end
            choose_exact=value;
        end
    endfunction

    function automatic logic [WIDTH-1:0] started_factor(
        input integer started
    );
        logic [WIDTH-1:0] value;
        integer active,remaining,jj,prior_sum;
        begin
            // One extra occurrence of month 1 is consumed
            // in [1,2,..,started,1]. Month 1 has L1-2 copies.
            value=WIDTH'(1);
            prior_sum=month_length[1]-2;
            for(jj=2;jj<=started;jj=jj+1) begin
                remaining=month_length[jj]-1;
                active=prior_sum+remaining;
                value=value*WIDTH'(choose_exact(active-1,remaining-1));
                prior_sum=active;
            end
            started_factor=value;
        end
    endfunction

    function automatic integer bit_length(input logic [WIDTH-1:0] val);
        integer b;
        begin
            bit_length=0;
            for(b=WIDTH-1;b>=0;b=b-1)
                if(val[b] && bit_length==0) bit_length=b+1;
        end
    endfunction

    task automatic write_full_word(
        input string filename, input logic [WIDTH-1:0] value
    );
        integer filehandle,b;
        begin
            filehandle=$fopen(filename,"wb");
            if(filehandle==0) $fatal(1,"NATIVE_H_BINARY_OUTPUT_FAILURE");
            for(b=FULL_BYTES-1;b>=0;b=b-1)
                $fwrite(filehandle,"%c",value[b*8+:8]);
            $fclose(filehandle);
        end
    endtask

    initial begin
        month_length[1]=115;
        month_length[2]=108;
        month_length[3]=119;
        month_length[4]=109;
        month_length[5]=106;
        month_length[6]=81;
        month_length[7]=115;
        month_length[8]=114;
        month_length[9]=117;
        month_length[10]=120;
        month_length[11]=98;
        month_length[12]=52;
        month_length[13]=81;
        month_length[14]=97;
        month_length[15]=121;
        month_length[16]=97;
        month_length[17]=115;
        month_length[18]=96;
        month_length[19]=107;
        month_length[20]=61;
        month_length[21]=106;
        month_length[22]=115;
        month_length[23]=119;
        month_length[24]=39;
        month_length[25]=84;
        month_length[26]=103;
        month_length[27]=115;
        month_length[28]=107;
        month_length[29]=55;
        month_length[30]=119;
        month_length[31]=97;
        month_length[32]=50;
        month_length[33]=122;
        month_length[34]=110;
        month_length[35]=81;
        month_length[36]=54;
        month_length[37]=101;
        month_length[38]=83;
        month_length[39]=88;
        month_length[40]=40;
        month_length[41]=25;
        month_length[42]=77;
        month_length[43]=98;
        month_length[44]=122;
        month_length[45]=105;
        if((NMONTHS!=6 && NMONTHS!=45) ||
           (NMONTHS==6 && WIDTH!=2048) ||
           (NMONTHS==45 && WIDTH!=22528))
            $fatal(1,"NATIVE_H_WIDTH_MONTH_PAIR_UNSUPPORTED");
        prefix_sum=0;
        for(j=1;j<=NMONTHS;j=j+1) begin
            if(month_length[j]<4 || month_length[j]>123)
                $fatal(1,"NATIVE_H_INVALID_LENGTH");
            prefix_sum=prefix_sum+month_length[j];
            cap[j]=prefix_sum-j;
        end
        total_days=prefix_sum;
        if(NMONTHS==45 && total_days!=4244)
            $fatal(1,"NATIVE_H_FOUNDATION_LENGTH_NOT_4244");

        // H_(NMONTHS)(n) == 1 for every reachable n,
        // because no fresh month remains. Only two 4245-entry
        // arrays are retained; no 45-dimensional state tensor.
        for(n=0;n<=MAXDAYS;n=n+1) begin
            next_row[n]=WIDTH'(1);
            row[n]='0;
        end
        for(s=NMONTHS-1;s>=1;s=s-1) begin
            v=month_length[s+1];
            coefficient=CWIDTH'(1);
            for(n=0;n<=cap[s];n=n+1) begin
                if(n>0) begin
                    small_numerator=coefficient*$unsigned(n+v-2);
                    coefficient=div_small_exact(small_numerator,n);
                end
                term=next_row[n+v-1]*WIDTH'(coefficient);
                prev_value=(n==0) ? WIDTH'(0) : row[n-1];
                checked_sum={1'b0,term}+{1'b0,prev_value};
                if(checked_sum[WIDTH]!==1'b0)
                    $fatal(1,"NATIVE_H_ADDITION_OVERFLOW");
                row[n]=checked_sum[WIDTH-1:0];
                if(row[n]==0)
                    $fatal(1,"NATIVE_H_ZERO_COUNT");
            end

            // The following are INDEPENDENT native SV count
            // checkpoints, not values read from Python binaries.
            if(NMONTHS==45) begin
                if(s==7 || s==3 || s==2) begin
                    checkpoint=started_factor(s)*row[cap[s]-1];
                    case(s)
                      7: write_full_word("build/native_H_prefix12345671.bin",checkpoint);
                      3: write_full_word("build/native_H_prefix1231.bin",checkpoint);
                      2: write_full_word("build/native_H_prefix121.bin",checkpoint);
                    endcase
                end
                if(s==1) begin
                    write_full_word("build/native_H_prefix11.bin",row[cap[1]-1]);
                end
            end

            for(n=0;n<=cap[s];n=n+1)
                next_row[n]=row[n];
            $display("NATIVE_H_TRANSFER_PROGRESS started=%0d maxN=%0d bits=%0d",
                     s,cap[s],bit_length(next_row[cap[s]]));
            $fflush();
        end
        sum_check_root=next_row[month_length[1]-1];
        if(NMONTHS==6) begin
            if(bit_length(sum_check_root)!=1602 ||
               sum_check_root!==2048'h3dbc36bdd8d0df2e7711f0c036831cb35ad4246a9f95b455e3ff30638060b82b3132c2b7904ca14805bb240862408ff4c054a2030e5ffa067b49c6114af17673ef7de19e35bc33b11311700ca82ca3d444467a3a2858b2e4ec38bcc9b54bfd7fc03d87460453bbdd62fe205c34782a28b80e1223f7259c9b87f4c4c964ebd7d3ab50f6229285bfd496f645854d639dd41a374bd2bcd72ac028c52b6bd56f290528d51aa9ec21fc354cab9c65d20ab38c4a94c86a8c2ace2ef307a18729b807b12df4d9a072abafce6)
                $fatal(1,"NATIVE_H_SIX_MONTH_GOLDEN");
            $display("STAGE1_NATIVE_H_TRANSFER_SIX_MONTH_ROOT_PASS bits=1602");
        end else begin
            if(bit_length(sum_check_root)!=22470)
                $fatal(1,"NATIVE_H_FULL_ROOT_BITS");
            write_full_word("build/native_H_root.bin",sum_check_root);
            $display("STAGE1_NATIVE_H_TRANSFER_45_MONTH_ROOT_COMPUTED bits=22470 days=4244");
        end
        $finish;
    end
endmodule
