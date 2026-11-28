`timescale 1ns/1ps
// QA only: native year selection; no host geometry input. Sauce reused from pinned general rank bench.
module tb_native_general_year;
    localparam logic signed [63:0] F=-64'sd15055671;
    logic signed [63:0] creation,target;
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
    logic signed [383:0] cnt_c,cnt_t,distance_count,sum_days,direction;
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

    task automatic sauce_state(input logic signed [63:0] cc,tt);
      begin
        creation=cc; target=tt;
        cnt_c=oracle_day_count(creation); cnt_t=oracle_day_count(target);
        distance_count=oracle_distance(creation,target);
        sum_days=oracle_sum(creation,target); direction=oracle_direction(creation,target);
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
            x=cnt_c+(2*k+1)*cnt_t+(3*k+1)*distance_count
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
            x=cnt_c+b*cnt_t+distance_count+sum_days+direction
               +prime_bowl[b]*prime_bowl[b];
            bowls[b]=saved(x*x+b);
        end

        for(i=1;i<=46;i=i+1) begin
            d=saved(stones[i][0]*cnt_c+stones[i][1]*cnt_t
               +stones[i][2]*distance_count+stones[i][3]*sum_days
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
      end
    endtask

    function automatic integer select_small(input integer bowl,seal,count);
        logic signed [383:0] aa,flow,lim;
        integer nb,ii;
        begin
            if(count<1) $fatal(1,"YEAR_EMPTY_CHOICE");
            nb=0;
            for(ii=0;ii<6;ii=ii+1)
                if(order_at46[ii]==bowl) nb=order_at46[(ii+1)%6];
            if(nb<1 || nb>6) $fatal(1,"YEAR_NEIGHBOR");
            aa=saved((bowls[bowl]+seal+384'sd181)*(bowls[bowl]+seal+384'sd181)
                     +384'sd179*bowls[nb]+seal);
            flow=saved((aa+seal+384'sd194)*(aa+seal+384'sd194)
                       +384'sd193*aa+384'sd197*bowls[6]);
            lim=MODULUS-(MODULUS%count);
            if(aa>lim) aa=flow[0] ? 384'sd1 : lim;
            select_small=1+int'((aa-384'sd1)%count);
        end
    endfunction
    integer gates[-1400:1400],glo,ghi;
    task automatic get_gate(input integer gi,output integer value);
        integer gap;
        begin
            if(gi < -1400 || gi > 1400) $fatal(1,"YEAR_GATE_CAP");
            while(ghi<gi) begin
                ghi=ghi+1; sauce_state(F,F+ghi);
                gap=41+select_small(1,1,922);
                gates[ghi]=gates[ghi-1]+gap;
            end
            while(glo>gi) begin
                glo=glo-1; sauce_state(F,F+glo);
                gap=41+select_small(1,1,922);
                gates[glo]=gates[glo+1]-gap;
            end
            value=gates[gi];
        end
    endtask
    integer hist[0:5778];
    task automatic select_year(input integer cc,tt,output integer yy,op,cl);
        integer ix,low,ai,bi,ga,gb,total,rr,len,aa,bb,nc,ch,trial;
        begin
            if(cc<F-50000 || cc>F+50000 || tt<F-50000 || tt>F+50000)
                $fatal(1,"YEAR_BOUNDED_DOMAIN");
            ix=0; get_gate(ix,ga);
            while(ga<cc) begin ix=ix+1; get_gate(ix,ga); end
            get_gate(ix-1,ga);
            while(ga>=cc) begin ix=ix-1; get_gate(ix-1,ga); end
            low=ix-1; get_gate(low,ga);
            while(ga>=cc-5778) begin low=low-1; get_gate(low,ga); end
            low=low+1;
            for(len=0;len<=5778;len=len+1) hist[len]=0;
            total=0;
            for(ai=low;ai<ix;ai=ai+1) begin
                get_gate(ai,ga); bi=(ix>ai+6)?ix:ai+6; get_gate(bi,gb);
                while(gb-ga<=5778) begin
                    hist[gb-ga]=hist[gb-ga]+1; total=total+1;
                    bi=bi+1; get_gate(bi,gb);
                end
            end
            sauce_state(cc,cc); rr=select_small(1,10,total); len=1;
            while(len<=5778 && rr>hist[len]) begin rr=rr-hist[len]; len=len+1; end
            if(len>5778) $fatal(1,"YEAR_LENGTH_RANK");
            aa=1401; bb=1401;
            for(ai=low;ai<ix;ai=ai+1) begin
                get_gate(ai,ga); bi=(ix>ai+6)?ix:ai+6; get_gate(bi,gb);
                while(gb-ga<=5778) begin
                    if(gb-ga==len) begin
                        rr=rr-1;
                        if(rr==0) begin aa=ai;bb=bi;end
                    end
                    bi=bi+1; get_gate(bi,gb);
                end
            end
            if(aa==1401 || bb==1401) $fatal(1,"YEAR_PAIR_RANK");
            yy=5000; get_gate(aa,op);get_gate(bb,cl);
            while(tt>cl) begin
                nc=0;get_gate(bb+6,trial);
                while(trial-cl<=5778) begin nc=nc+1;get_gate(bb+6+nc,trial);end
                sauce_state(cc,cl);ch=select_small(1,11,nc);
                aa=bb;bb=bb+5+ch;yy=yy+1;
                get_gate(aa,op);get_gate(bb,cl);
            end
            while(tt<=op) begin
                nc=0;get_gate(aa-6,trial);
                while(op-trial<=5778) begin nc=nc+1;get_gate(aa-6-nc,trial);end
                sauce_state(cc,op);ch=select_small(1,12,nc);
                bb=aa;aa=aa-5-ch;yy=yy-1;
                get_gate(aa,op);get_gate(bb,cl);
            end
            if(!(op<tt && tt<=cl && cl-op<=5778 && bb-aa>=6))
                $fatal(1,"YEAR_INTERVAL");
        end
    endtask
    integer cases;
    task automatic verify_case(input integer cc,tt,ey,eo,ec);
        integer yy,op,cl;
        begin
            select_year(cc,tt,yy,op,cl);
            if(yy!==ey || op!==eo || cl!==ec)
                $fatal(1,"YEAR_MISMATCH c=%0d t=%0d got=%0d,%0d,%0d expected=%0d,%0d,%0d",cc,tt,yy,op,cl,ey,eo,ec);
            cases=cases+1;
            $display("NATIVE_YEAR_CASE_PASS c=%0d t=%0d year=%0d open=%0d close=%0d",cc,tt,yy,op,cl);
        end
    endtask
    initial begin
        gates[0]=int'(F);glo=0;ghi=0;cases=0;
        verify_case(-15055671,-15055671,5000,-15057703,-15053459);
        verify_case(-15055671,-15055672,5000,-15057703,-15053459);
        verify_case(-15055671,-15055670,5000,-15057703,-15053459);
        verify_case(-15055671,-15056171,5000,-15057703,-15053459);
        verify_case(-15055671,-15055171,5000,-15057703,-15053459);
        verify_case(-15055671,-15061671,4999,-15061829,-15057703);
        verify_case(-15055671,-15049671,5001,-15053459,-15047892);
        verify_case(-15056905,-15056448,5000,-15058136,-15054508);
        verify_case(-15054437,-15053449,5000,-15055326,-15051795);
        verify_case(-15058171,-15053171,5002,-15053677,-15049766);
        verify_case(-15055671,-15057703,4999,-15061829,-15057703);
        verify_case(-15055671,-15057702,5000,-15057703,-15053459);
        verify_case(-15055671,-15053459,5000,-15057703,-15053459);
        verify_case(-15055671,-15053458,5001,-15053459,-15047892);
        verify_case(-15105671,-15105671,5000,-15107347,-15101857);
        verify_case(-15005671,-15005671,5000,-15011119,-15005659);
        verify_case(-15058171,-15045671,5003,-15049766,-15045219);
        verify_case(-15053171,-15065671,4996,-15070673,-15064992);
        if(cases!=18) $fatal(1,"YEAR_CASE_COUNT");
        $display("NATIVE_GENERAL_YEAR_PASS cases=%0d QA_ONLY",cases);
        $finish;
    end
endmodule
