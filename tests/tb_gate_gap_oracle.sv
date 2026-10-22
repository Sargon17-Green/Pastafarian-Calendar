`timescale 1ns/1ps
// Test-only gate/gap oracle. Reconstructed solely from the normative Scroll.
// No production module is imported, no calendar date is claimed.
module tb_gate_gap_oracle;
    import pcal_stage1_oracle_pkg::*;
    localparam logic signed [383:0] MODULUS =
        (384'sd1 << 127) - 384'sd1;
    logic signed [383:0] stones [1:46][0:4];
    logic signed [383:0] hidden [1:7];
    logic signed [383:0] drops [-6:46];
    logic signed [383:0] bowls [1:6];
    logic signed [383:0] old_bowls [1:6];
    logic signed [383:0] new_bowls [1:6];
    logic signed [383:0] start_post_stir_bowls [1:6];
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


    logic signed [383:0] a0, flow, acceptance_limit, accepted;
    integer successor_bowl, qnext, step, gap_value, ordinal, rejects;
    integer positive_expected [1:10];
    integer negative_expected [1:12];
    integer case_count, input_n;
    integer positive_sum, negative_sum;
    integer pos_prefix [0:10], neg_prefix [0:12];
    integer cand_length [0:127], cand_open [0:127], cand_close [0:127];
    integer cand_count, ii, jj, aa, bb, tmp;
    integer year_ordinal, year_next;
    logic signed [383:0] year_a0, year_flow, year_limit, year_accepted;
    task automatic run_gate(input logic signed [63:0] c,
                            input logic signed [63:0] t,
                            output integer gap);
        begin
            cnt_c=oracle_day_count(c);
            cnt_t=oracle_day_count(t);
            dist=oracle_distance(c,t);
            sum_days=oracle_sum(c,t);
            direction=oracle_direction(c,t);
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
        for(b=1;b<=6;b=b+1) start_post_stir_bowls[b]=bowls[b];
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

            successor_bowl=0;
            for (qnext=0;qnext<6;qnext=qnext+1) begin
                if (order_at46[qnext]==1)
                    successor_bowl=order_at46[(qnext+1)%6];
            end
            if (successor_bowl<1 || successor_bowl>6)
                $fatal(1,"NEXT_BOWL_MISSING");
            a0=saved((bowls[1]+384'sd1+384'sd181)
                     *(bowls[1]+384'sd1+384'sd181)
                     +384'sd179*bowls[successor_bowl]+384'sd1);
            flow=saved((a0+384'sd1+384'sd1+384'sd193)
                     *(a0+384'sd1+384'sd1+384'sd193)
                     +384'sd193*a0+384'sd197*bowls[6]);
            step=(flow%384'sd2)==384'sd1 ? 1 : -1;
            acceptance_limit=(MODULUS/384'sd922)*384'sd922;
            if (a0<=acceptance_limit) begin
                accepted=a0;
                rejects=0;
            end else if (step==1) begin
                accepted=384'sd1;
                // For a huge ring this count may exceed int; the
                // count is deliberately not exposed as a 32-bit port.
                rejects=-1;
            end else begin
                accepted=acceptance_limit;
                rejects=-1;
            end
            ordinal=1+int'((accepted-384'sd1)%384'sd922);
            gap=41+ordinal;
            if (ordinal<1 || ordinal>922 || gap<42 || gap>963)
                $fatal(1,"GATE_GAP_RANGE");
        end
    endtask

    initial begin
        positive_expected[1]=345;
        positive_expected[2]=818;
        positive_expected[3]=831;
        positive_expected[4]=218;
        positive_expected[5]=854;
        positive_expected[6]=136;
        positive_expected[7]=674;
        positive_expected[8]=649;
        positive_expected[9]=617;
        positive_expected[10]=763;
        negative_expected[1]=503;
        negative_expected[2]=441;
        negative_expected[3]=329;
        negative_expected[4]=759;
        negative_expected[5]=433;
        negative_expected[6]=890;
        negative_expected[7]=558;
        negative_expected[8]=414;
        negative_expected[9]=488;
        negative_expected[10]=51;
        negative_expected[11]=546;
        negative_expected[12]=746;
        case_count=0;
        pos_prefix[0]=0;
        neg_prefix[0]=0;
        for(input_n=1;input_n<=12;input_n=input_n+1) begin
            run_gate(-64'sd15055671,-64'sd15055671-input_n,gap_value);
            if(gap_value!=negative_expected[input_n])
                $fatal(1,"NEGATIVE_GATE_GAP_VECTOR");
            neg_prefix[input_n]=neg_prefix[input_n-1]+gap_value;
            case_count=case_count+1;
            if(input_n<=10) begin
                run_gate(-64'sd15055671,-64'sd15055671+input_n,gap_value);
                if(gap_value!=positive_expected[input_n])
                    $fatal(1,"POSITIVE_GATE_GAP_VECTOR");
                pos_prefix[input_n]=pos_prefix[input_n-1]+gap_value;
                case_count=case_count+1;
            end
        end

        if(pos_prefix[4]!=2212 || neg_prefix[4]!=2032 ||
           -64'sd15055671+pos_prefix[4]!=-64'sd15053459 ||
           -64'sd15055671-neg_prefix[4]!=-64'sd15057703)
            $fatal(1,"YEAR5000_CANONICAL_GATE_BOUNDS");

        // Enumerate candidate (open,close] containing Foundation.
        cand_count=0;
        for(ii=1;ii<=12;ii=ii+1) begin
            for(jj=0;jj<=10;jj=jj+1) begin
                tmp=neg_prefix[ii]+pos_prefix[jj];
                if(ii+jj>=6 && tmp>=252 && tmp<=5778) begin
                    if(cand_count>=128) $fatal(1,"CANDIDATE_CAPACITY");
                    cand_length[cand_count]=tmp;
                    cand_open[cand_count]=-15055671-neg_prefix[ii];
                    cand_close[cand_count]=-15055671+pos_prefix[jj];
                    cand_count=cand_count+1;
                end
            end
        end
        if(cand_count!=43) $fatal(1,"YEAR5000_CANDIDATE_COUNT");

        // Canonical ordering is by length and then opening gate.
        for(aa=0;aa<cand_count;aa=aa+1) begin
            for(bb=aa+1;bb<cand_count;bb=bb+1) begin
                if(cand_length[bb]<cand_length[aa] ||
                   (cand_length[bb]==cand_length[aa] &&
                    cand_open[bb]<cand_open[aa])) begin
                    tmp=cand_length[bb];
                    cand_length[bb]=cand_length[aa];
                    cand_length[aa]=tmp;
                    tmp=cand_open[bb];
                    cand_open[bb]=cand_open[aa];
                    cand_open[aa]=tmp;
                    tmp=cand_close[bb];
                    cand_close[bb]=cand_close[aa];
                    cand_close[aa]=tmp;
                end
            end
        end

        // Query (c,c) sauce bowl 1 with seal 10 for Year 5000.
        run_gate(-64'sd15055671,-64'sd15055671,gap_value);
        year_next=0;
        for(ii=0;ii<6;ii=ii+1)
            if(order_at46[ii]==1) year_next=order_at46[(ii+1)%6];
        if(year_next<1 || year_next>6) $fatal(1,"YEAR_NEXT_BOWL");
        year_a0=saved((bowls[1]+384'sd10+384'sd181)
                      *(bowls[1]+384'sd10+384'sd181)
                      +384'sd179*bowls[year_next]+384'sd10);
        year_flow=saved((year_a0+384'sd10+384'sd1+384'sd193)
                        *(year_a0+384'sd10+384'sd1+384'sd193)
                        +384'sd193*year_a0+384'sd197*bowls[6]);
        year_limit=(MODULUS/cand_count)*cand_count;
        if(year_a0<=year_limit) year_accepted=year_a0;
        else if(year_flow%384'sd2==384'sd1) year_accepted=384'sd1;
        else year_accepted=year_limit;
        year_ordinal=1+int'((year_accepted-384'sd1)%cand_count);
        if(year_ordinal!=15 ||
           cand_length[year_ordinal-1]!=4244 ||
           cand_open[year_ordinal-1]!=-15057703 ||
           cand_close[year_ordinal-1]!=-15053459)
            $fatal(1,"YEAR5000_CANONICAL_SELECTION");

        $display("STAGE1_TEST_ONLY_GATE_GAPS_PASS cases=%0d",case_count);
        $display("STAGE1_YEAR5000_REFERENCE_PASS candidates=%0d rank=%0d",
                 cand_count,year_ordinal);
        $finish;
    end
endmodule
