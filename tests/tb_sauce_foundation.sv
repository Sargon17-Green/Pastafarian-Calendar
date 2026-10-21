`timescale 1ns/1ps
// Independent test-only reconstruction from the normative Scroll.
// Checkpoint is c=t=Foundation; no production RTL is imported.
module tb_sauce_foundation;
    import pcal_stage1_oracle_pkg::*;
    localparam logic signed [383:0] MODULUS =
        (384'sd1 << 127) - 384'sd1;
    logic signed [383:0] stones [1:46][0:4];
    logic signed [383:0] hidden [1:7];
    logic signed [383:0] drops [-6:46];
    logic signed [383:0] bowls [1:6];
    logic signed [383:0] old_bowls [1:6];
    logic signed [383:0] new_bowls [1:6];
    logic signed [383:0] pour [1:3];
    logic signed [383:0] cnt_c,cnt_t,dist,sum_days,direction;
    logic signed [383:0] x,sr,u,sum_bowls,d;
    integer order [0:5];
    integer order_at46 [0:5];
    integer prime_bowl [1:6];
    integer a [1:11], bcoef [1:11], ccoef [1:11], dcoef [1:11];
    integer rank, av [0:5], facts [0:5];
    integer i,j,k,r,q,b,p,n,idx,rank0,stone_idx,z;

    function automatic logic signed [383:0] saved(
        input logic signed [383:0] value
    );
        logic signed [383:0] rem;
        begin
            rem = (value - 384'sd1) % MODULUS;
            if (rem < 0) rem = rem + MODULUS;
            saved = rem + 384'sd1;
        end
    endfunction

    task automatic lex_order(input integer ordinal);
        integer idx_local, remainder_local, row,col, available [0:5];
        integer factorials [0:5];
        begin
            factorials[0]=120; factorials[1]=24; factorials[2]=6;
            factorials[3]=2; factorials[4]=1; factorials[5]=1;
            for (row=0;row<6;row=row+1) available[row]=row+1;
            remainder_local=ordinal-1;
            for (row=0;row<6;row=row+1) begin
                idx_local=remainder_local/factorials[row];
                remainder_local=remainder_local%factorials[row];
                order[row]=available[idx_local];
                for(col=idx_local;col<5-row;col=col+1)
                    available[col]=available[col+1];
            end
        end
    endtask

    initial begin
        cnt_c = oracle_day_count(-64'sd15055671);
        cnt_t = oracle_day_count(-64'sd15055671);
        dist = oracle_distance(-64'sd15055671,-64'sd15055671);
        sum_days = oracle_sum(-64'sd15055671,-64'sd15055671);
        direction = oracle_direction(-64'sd15055671,-64'sd15055671);
        if(cnt_c!=384'sd1 || cnt_t!=384'sd1 ||
           dist!=384'sd1 || sum_days!=384'sd2 ||
           direction!=384'sd2) $fatal(1,"FOUNDATION_WORK_COUNTS");

        // The stone snapshot is immutable for each new row.
        stones[1][0]=384'sd17; stones[1][1]=384'sd29;
        stones[1][2]=384'sd43; stones[1][3]=384'sd71;
        stones[1][4]=384'sd101;
        for (i=2;i<=46;i=i+1) begin
            stones[i][0]=saved(stones[i-1][0]*stones[i-1][0]
                               +384'sd3*stones[i-1][1]+i);
            stones[i][1]=saved(stones[i-1][1]*stones[i-1][1]
                               +384'sd5*stones[i-1][2]+stones[i-1][0]);
            stones[i][2]=saved(stones[i-1][2]*stones[i-1][2]
                               +384'sd7*stones[i-1][3]+stones[i-1][1]);
            stones[i][3]=saved(stones[i-1][3]*stones[i-1][3]
                               +384'sd11*stones[i-1][4]+stones[i-1][2]);
            stones[i][4]=saved(stones[i-1][4]*stones[i-1][4]
                               +384'sd13*stones[i-1][0]+stones[i-1][3]);
        end

        for(k=1;k<=7;k=k+1) begin
            x=cnt_c+(2*k+1)*cnt_t+(3*k+1)*dist
                +(4*k+2)*sum_days+(4*k+4)*direction;
            for(j=0;j<5;j=j+1) x=x+stones[k][j];
            x=saved(x);
            for(r=1;r<=7;r=r+1) begin
                stone_idx=(r-1)%5;
                x=saved(x*x+384'sd3*x+stones[k][stone_idx]+r);
            end
            hidden[k]=x;
            drops[1-k]=x;
        end
        if(hidden[1]!=384'sd119390830530032782664128530203002080344)
            $fatal(1,"HIDDEN_1");
        if(hidden[7]!=384'sd6164285870955721082771365327359496898)
            $fatal(1,"HIDDEN_7");

        a[1]=3; a[2]=5; a[3]=7; a[4]=11; a[5]=13;
        a[6]=17; a[7]=19; a[8]=23; a[9]=29; a[10]=31;a[11]=37;
        bcoef[1]=5;bcoef[2]=7;bcoef[3]=11;bcoef[4]=13;bcoef[5]=17;
        bcoef[6]=19;bcoef[7]=23;bcoef[8]=29;bcoef[9]=31;
        bcoef[10]=37;bcoef[11]=41;
        ccoef[1]=7;ccoef[2]=11;ccoef[3]=13;ccoef[4]=17;
        ccoef[5]=19;ccoef[6]=23;ccoef[7]=29;ccoef[8]=31;
        ccoef[9]=37;ccoef[10]=41;ccoef[11]=43;
        dcoef[1]=11;dcoef[2]=13;dcoef[3]=17;dcoef[4]=19;
        dcoef[5]=23;dcoef[6]=29;dcoef[7]=31;dcoef[8]=37;
        dcoef[9]=41;dcoef[10]=43;dcoef[11]=47;

        prime_bowl[1]=17;prime_bowl[2]=19;prime_bowl[3]=23;
        prime_bowl[4]=29;prime_bowl[5]=31;prime_bowl[6]=37;
        for(b=1;b<=6;b=b+1) begin
            x=cnt_c+b*cnt_t+dist+sum_days+direction
               +prime_bowl[b]*prime_bowl[b];
            bowls[b]=saved(x*x+b);
        end

        for(i=1;i<=46;i=i+1) begin
            d=saved(stones[i][0]*cnt_c+stones[i][1]*cnt_t
               +stones[i][2]*dist+stones[i][3]*sum_days
               +stones[i][4]*direction+drops[i-1]
               +384'sd3*drops[i-3]+384'sd5*drops[i-7]+i);
            x=d;
            for(r=1;r<=11;r=r+1) begin
                stone_idx=(r-1)%5;
                x=saved(x*x+a[r]*x+bcoef[r]*drops[i-1]
                        +ccoef[r]*drops[i-3]+dcoef[r]*drops[i-7]
                        +stones[i][stone_idx]);
            end
            drops[i]=x;
            rank=1+int'((x-384'sd1)%384'sd720);
            lex_order(rank);
            for(b=1;b<=6;b=b+1) old_bowls[b]=bowls[b];
            pour[1]=saved(x*x+stones[i][0]*old_bowls[order[0]]+3*i);
            pour[2]=saved(x*x+stones[i][1]*old_bowls[order[1]]+5*i);
            pour[3]=saved(x*x+stones[i][2]*old_bowls[order[2]]+7*i);
            for(q=1;q<=6;q=q+1) begin
                b=order[q-1];
                p=order[(q+4)%6];
                n=order[q%6];
                stone_idx=(q-1)%5;
                u=old_bowls[b]+384'sd2*old_bowls[p]
                  +384'sd3*old_bowls[n]+x+stones[i][stone_idx];
                if(q<=3) u=u+pour[q];
                new_bowls[b]=saved(u*u+384'sd5*old_bowls[p]
                                   *old_bowls[n]+i*q);
            end
            for(b=1;b<=6;b=b+1) bowls[b]=new_bowls[b];
            if(i==46)
                for(q=0;q<6;q=q+1) order_at46[q]=order[q];
        end
        if(drops[1]!=384'sd56644603826892212324764499696091907135)
            $fatal(1,"VISIBLE_1");
        if(drops[46]!=384'sd141872771689426650819909896585756512282)
            $fatal(1,"VISIBLE_46");
        if(order_at46[0]!=4 || order_at46[1]!=5 ||
           order_at46[2]!=2 || order_at46[3]!=3 ||
           order_at46[4]!=6 || order_at46[5]!=1)
            $fatal(1,"ORDER_AT46");

        for(r=1;r<=12;r=r+1) begin
            sum_bowls=384'sd0;
            for(b=1;b<=6;b=b+1) begin
                old_bowls[b]=bowls[b];
                sum_bowls=sum_bowls+old_bowls[b];
            end
            sr=saved(sum_bowls+149*r);
            rank=1+int'((sr-384'sd1)%384'sd720);
            lex_order(rank);
            for(q=1;q<=6;q=q+1) begin
                b=order[q-1];
                p=order[(q+4)%6];
                n=order[q%6];
                u=old_bowls[b]+384'sd3*old_bowls[p]
                  +384'sd5*old_bowls[n]+sr+r+q*q;
                new_bowls[b]=saved(u*u+384'sd7*old_bowls[p]
                                   *old_bowls[n]);
            end
            for(b=1;b<=6;b=b+1) bowls[b]=new_bowls[b];
        end
        if(bowls[1]!=384'sd65286679584284972964194865805379907599
           || bowls[2]!=384'sd127720283375330263615328810127751035299
           || bowls[3]!=384'sd54364069496183805843611594721403108554
           || bowls[4]!=384'sd93072329024469476118876155742008280619
           || bowls[5]!=384'sd54867842942953573450868747713087920246
           || bowls[6]!=384'sd111207247632761530752404582123499651367)
            $fatal(1,"CANONICAL_SAVED_SUM_BOWLS");
        $display("STAGE1_TEST_ONLY_SAUCE_FOUNDATION_PASS");
        $finish;
    end
endmodule
