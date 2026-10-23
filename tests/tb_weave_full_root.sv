`timescale 1ns/1ps
// Test-only 22528-bit exact Foundation root count: NO date/weave chosen.
// The entire 45-month count is verified by external SHA256.
module tb_weave_full_root;
    parameter integer WIDTH=22528;
    localparam integer CWIDTH=864;
    localparam integer LENGTH=4244, MONTHS=45, CLIMBS=CWIDTH/32;
    logic [WIDTH-1:0] prior [0:LENGTH], nextrow [0:LENGTH];
    logic [CWIDTH-1:0] comb [0:LENGTH], numerator;
    logic [WIDTH-1:0] prefix_count, root_count;
    integer month_lengths[0:MONTHS-1];
    integer first_count, new_count, month_index, k, t, i;
    integer stop_after, root_file, start_month, prefix11;
    logic [WIDTH-1:0] all_zeroes;

    function automatic logic [CWIDTH-1:0] exact_small_div(
        input logic [CWIDTH-1:0] n,input integer d
    );
        logic [CWIDTH-1:0] quotient;
        logic [63:0] word,carry;
        integer limb;
        begin
            quotient='0; carry='0;
            if(d<=0 || d>LENGTH) $fatal(1,"DIVISOR_OUT_OF_RANGE");
            for(limb=CLIMBS-1;limb>=0;limb=limb-1) begin
                word=(carry<<32)|{32'b0,n[limb*32+:32]};
                quotient[limb*32+:32]=word/$unsigned(d);
                carry=word%$unsigned(d);
            end
            if(carry!==64'd0) $fatal(1,"NONEXACT_SMALL_DIVISION");
            exact_small_div=quotient;
        end
    endfunction

    function automatic integer bits(input logic [WIDTH-1:0] v);
        integer b;
        begin
            bits=0;
            for(b=WIDTH-1;b>=0;b=b-1)
                if(v[b] && bits==0) bits=b+1;
        end
    endfunction

    initial begin
        month_lengths[0]=115;
        month_lengths[1]=108;
        month_lengths[2]=119;
        month_lengths[3]=109;
        month_lengths[4]=106;
        month_lengths[5]=81;
        month_lengths[6]=115;
        month_lengths[7]=114;
        month_lengths[8]=117;
        month_lengths[9]=120;
        month_lengths[10]=98;
        month_lengths[11]=52;
        month_lengths[12]=81;
        month_lengths[13]=97;
        month_lengths[14]=121;
        month_lengths[15]=97;
        month_lengths[16]=115;
        month_lengths[17]=96;
        month_lengths[18]=107;
        month_lengths[19]=61;
        month_lengths[20]=106;
        month_lengths[21]=115;
        month_lengths[22]=119;
        month_lengths[23]=39;
        month_lengths[24]=84;
        month_lengths[25]=103;
        month_lengths[26]=115;
        month_lengths[27]=107;
        month_lengths[28]=55;
        month_lengths[29]=119;
        month_lengths[30]=97;
        month_lengths[31]=50;
        month_lengths[32]=122;
        month_lengths[33]=110;
        month_lengths[34]=81;
        month_lengths[35]=54;
        month_lengths[36]=101;
        month_lengths[37]=83;
        month_lengths[38]=88;
        month_lengths[39]=40;
        month_lengths[40]=25;
        month_lengths[41]=77;
        month_lengths[42]=98;
        month_lengths[43]=122;
        month_lengths[44]=105;
        new_count=0;
        for(i=0;i<MONTHS;i=i+1) begin
            if(month_lengths[i]<4 || month_lengths[i]>123)
                $fatal(1,"INVALID_MONTH_LENGTH");
            new_count=new_count+month_lengths[i];
        end
        if(new_count!=LENGTH) $fatal(1,"WRONG_YEAR_LENGTH");
        stop_after=45;
        if($value$plusargs("stop_after=%d",stop_after)) begin
            if(stop_after<2 || stop_after>45)
                $fatal(1,"STOP_AFTER_INVALID");
        end
        for(i=0;i<=LENGTH;i=i+1) begin
            prior[i]='0;nextrow[i]='0;comb[i]='0;
        end
        prefix11=$test$plusargs("prefix11");
        if(prefix11!=0) begin
            if(stop_after!=45) $fatal(1,"PREFIX11_REQUIRES_FULL_MONTH_COUNT");
            // Independent suffix completion oracle after the FIRST TWO
            // woven symbols are (1,1). The first month has 113 copies
            // left, while months 2..45 have not yet begun.
            //
            // Insert all occurrences of the first fresh month (#2)
            // among the remaining 113 old letters, with the last new
            // copy following the last old letter. With k old letters
            // before the first new copy, the exact block size is
            // C(l2 + N-k-2,N-k) when k<N and one when k=N.
            // No artificial "month 1 must appear first" constraint is
            // re-applied after a valid prefix has already started it.
            first_count=month_lengths[0]-2;
            comb[0]=CWIDTH'(1);
            for(t=1;t<=first_count;t=t+1) begin
                numerator=comb[t-1]*$unsigned(month_lengths[1]+t-2);
                comb[t]=exact_small_div(numerator,t);
            end
            for(k=0;k<=first_count;k=k+1)
                prior[k+1]=WIDTH'(comb[first_count-k]);
            first_count=first_count+month_lengths[1];
            start_month=3;
        end else begin
            prior[1]=WIDTH'(1);
            first_count=month_lengths[0];
            start_month=2;
        end
        for(month_index=start_month;month_index<=stop_after;month_index=month_index+1) begin
            new_count=first_count+month_lengths[month_index-1];
            for(k=0;k<=new_count;k=k+1) nextrow[k]='0;
            comb[0]=CWIDTH'(1);
            for(t=1;t<first_count;t=t+1) begin
                numerator=comb[t-1]*$unsigned(month_lengths[month_index-1]+t-2);
                comb[t]=exact_small_div(numerator,t);
            end
            prefix_count='0;
            for(k=1;k<=first_count;k=k+1) begin
                prefix_count=prefix_count+prior[k];
                if(k==first_count) nextrow[k+1]=prefix_count;
                else nextrow[k+1]=prefix_count*comb[first_count-k];
            end
            root_count='0;
            for(k=1;k<=new_count;k=k+1) begin
                root_count=root_count+nextrow[k];
                prior[k]=nextrow[k];
            end
            if(root_count=='0 || bits(root_count)>WIDTH-48)
                $fatal(1,"WIDTH_GUARD_OR_ZERO_COUNT");
            first_count=new_count;
            if(prefix11==0) case(month_index)
                2: if(bits(root_count)!=217) $fatal(1,"MEDIUM_ROOT_2");
                3: if(bits(root_count)!=528) $fatal(1,"MEDIUM_ROOT_3");
                4: if(bits(root_count)!=880) $fatal(1,"MEDIUM_ROOT_4");
                5: if(bits(root_count)!=1262) $fatal(1,"MEDIUM_ROOT_5");
                6: if(bits(root_count)!=1602) $fatal(1,"MEDIUM_ROOT_6");
            endcase
            $display("FULL_ROOT_PROGRESS months=%0d days=%0d bits=%0d",
                     month_index,new_count,bits(root_count));
            $fflush();
        end
        if(prefix11!=0) begin
            if(first_count!=4242 || bits(root_count)!=22465)
                $fatal(1,"PREFIX11_COUNT_WIDTH");
            root_file=$fopen("build/foundation_weave_prefix11.bin","wb");
            if(root_file==0) $fatal(1,"PREFIX11_FILE_OPEN_FAILED");
            for(i=2808;i>=0;i=i-1)
                $fwrite(root_file,"%c",root_count[i*8+:8]);
            $fclose(root_file);
            $display("STAGE1_FOUNDATION_WEAVE_PREFIX11_WRITTEN bits=22465 bytes=2809");
        end else if(stop_after==45) begin
            if(first_count!=4244 || bits(root_count)!=22470)
                $fatal(1,"ROOT_WIDTH_CHECKPOINT");
            if(root_count[479:0]!==480'h9ee02ae1d19ddbd2b9d29efcd0c9bbcddae2a4bcd271d0f85ce66a191c7130d0297ed5918ba7eb26aed483715a31dcc6ad4761227200307294007f78)
                $fatal(1,"ROOT_LOW_CHECKPOINT");
            root_file=$fopen("build/foundation_weave_root.bin","wb");
            if(root_file==0) $fatal(1,"ROOT_BINARY_OPEN_FAILED");
            for(i=2808;i>=0;i=i-1)
                $fwrite(root_file,"%c",root_count[i*8+:8]);
            $fclose(root_file);
            $display("STAGE1_FOUNDATION_FULL_WEAVE_ROOT_WRITTEN bits=22470 bytes=2809");
        end else
            $display("STAGE1_PARTIAL_FULLWIDTH_WEAVE_PROBE_PASS months=%0d",
                     stop_after);
        $finish;
    end
endmodule
