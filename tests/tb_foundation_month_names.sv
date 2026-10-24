`timescale 1ns/1ps
// Test-only independent name-index selection for the Foundation year.
// No language strings, physical weave assumptions, or production RTL.
module tb_foundation_month_names;
    import pcal_exact_division_pkg::*;
    localparam logic [383:0] M=(384'd1<<127)-384'd1;
    localparam logic [383:0] BO5=384'd69216999894300723029207159165527918879;
    localparam logic [383:0] BO6=384'd102967821965301591097533657552300482421;
    localparam logic [383:0] A0_WITNESS=384'd64807661530580137725274994811043336616;
    localparam logic [383:0] D_WITNESS=384'd34584297955042037302508316358667844100;
    localparam logic [383:0] RANK_WITNESS=384'd47595793958504905307317451810724820201647031065686669524994;
    logic [383:0] a0,direction_value,N,space,answer,limit,rank,
                  zero_rank,suffix_size,choice,expected_a0;
    integer expected_index[0:44], selected_index[0:44], available[0:46];
    integer i,j,pos,chosen,remaining,jj,missing,seen[1:47];
    integer successor;
    function automatic logic [383:0] canon_save(input logic [383:0] val);
        canon_save=384'd1+exact_remainder_384(val-384'd1,M);
    endfunction

    initial begin
        // The source snapshot's orderAt46 is [2,5,6,4,3,1]:
        // the next bowl after #5 is #6.
        successor=6;
        a0=canon_save((BO5+384'd33+384'd181)*
                      (BO5+384'd33+384'd181)
                      +384'd179*BO6+384'd33);
        if(a0!==A0_WITNESS)
            $fatal(1,"MONTH_NAMES_A0_REFERENCE");
        direction_value=canon_save((a0+384'd33+384'd1+384'd193)*
                          (a0+384'd33+384'd1+384'd193)
                          +384'd193*a0+384'd197*BO6);
        if(direction_value!==D_WITNESS || direction_value[0]!==1'b0)
            $fatal(1,"MONTH_NAMES_BOWL5_DIRECTION");

        N=384'd1;
        for(i=3;i<=47;i=i+1) N=N*i;
        // 47P45=47!/2!, exactly 197 bits. 2-digit selection.
        if(N!==384'd129311620755584090321482177576805989984598816194560000000000)
            $fatal(1,"MONTH_NAMES_47P45_COUNT");
        space=M*M;
        if(N>=space || N<=M) $fatal(1,"MONTH_NAMES_TWO_DIGITS");
        // D is even -> reverse; A_j=A0-j, so each base-M digit
        // A_j-1=A0-1-j; two digits are enough for this query.
        answer=384'd1+(a0-384'd1)+(a0-384'd2)*M;
        limit=exact_quotient_384(space,N)*N;
        if(answer>limit)
            $fatal(1,"MONTH_NAMES_UNEXPECTED_REJECTION");
        rank=exact_remainder_384(answer-384'd1,N)+384'd1;
        if(rank!==RANK_WITNESS)
            $fatal(1,"MONTH_NAMES_CHOICE_RANK");

        expected_index[0]=18;
        expected_index[1]=14;
        expected_index[2]=37;
        expected_index[3]=28;
        expected_index[4]=24;
        expected_index[5]=42;
        expected_index[6]=6;
        expected_index[7]=20;
        expected_index[8]=19;
        expected_index[9]=41;
        expected_index[10]=16;
        expected_index[11]=39;
        expected_index[12]=25;
        expected_index[13]=1;
        expected_index[14]=9;
        expected_index[15]=38;
        expected_index[16]=3;
        expected_index[17]=46;
        expected_index[18]=27;
        expected_index[19]=40;
        expected_index[20]=12;
        expected_index[21]=43;
        expected_index[22]=35;
        expected_index[23]=32;
        expected_index[24]=29;
        expected_index[25]=10;
        expected_index[26]=44;
        expected_index[27]=36;
        expected_index[28]=23;
        expected_index[29]=17;
        expected_index[30]=33;
        expected_index[31]=5;
        expected_index[32]=30;
        expected_index[33]=15;
        expected_index[34]=11;
        expected_index[35]=45;
        expected_index[36]=8;
        expected_index[37]=4;
        expected_index[38]=7;
        expected_index[39]=31;
        expected_index[40]=34;
        expected_index[41]=22;
        expected_index[42]=13;
        expected_index[43]=2;
        expected_index[44]=26;
        zero_rank=rank-384'd1;
        for(i=0;i<47;i=i+1) begin
            available[i]=i+1;
            seen[i+1]=0;
        end
        remaining=47;
        for(pos=0;pos<45;pos=pos+1) begin
            suffix_size=384'd1;
            // Number of ways to fill the remaining 44-pos slots.
            for(j=0;j<44-pos;j=j+1)
                suffix_size=suffix_size*(46-pos-j);
            choice=exact_quotient_384(zero_rank,suffix_size);
            zero_rank=exact_remainder_384(zero_rank,suffix_size);
            if(choice>=remaining)
                $fatal(1,"MONTH_NAMES_CHOICE_DIGIT");
            chosen=available[int'(choice)];
            selected_index[pos]=chosen;
            if(chosen!=expected_index[pos] || chosen<1 || chosen>47)
                $fatal(1,"MONTH_NAMES_GOLDEN_SEQUENCE at=%0d got=%0d expected=%0d",
                       pos,chosen,expected_index[pos]);
            if(seen[chosen]!=0) $fatal(1,"MONTH_NAMES_DUPLICATE");
            seen[chosen]=1;
            for(j=int'(choice);j<remaining-1;j=j+1)
                available[j]=available[j+1];
            remaining=remaining-1;
        end
        if(zero_rank!==384'd0 || remaining!=2 ||
           available[0]!=21 || available[1]!=47)
            $fatal(1,"MONTH_NAMES_RANK_CONSERVATION");
        for(i=1;i<=47;i=i+1)
            if(i==21 || i==47) begin
                if(seen[i]!=0) $fatal(1,"MONTH_NAMES_UNUSED_INVARIANT");
            end else if(seen[i]!=1) $fatal(1,"MONTH_NAMES_MISSING_INVARIANT");

        $display("STAGE1_FOUNDATION_47P45_MONTH_NAME_UNRANK_PASS count=45 unused=21,47");
        $finish;
    end
endmodule
