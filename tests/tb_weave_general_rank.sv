`timescale 1ns/1ps
// Independent test-only reconstruction from the normative Scroll.
// QA only: generalized native Sauce and wide rank selection, supplied year opening and independently verified root.
// No native year/geometry selection or production acceptance implied.
module tb_weave_general_rank;
    localparam integer WIDTH=32768, BYTES=4096;
    localparam logic signed [63:0] F=-64'sd15055671;
    logic signed [63:0] creation, opening, target;
    logic signed [383:0] a0, direction_seed, step, digit;
    logic [WIDTH-1:0] root, space, wide0, limit, accepted, ordinal;
    integer digits, neighbor, fi, fo, codepoint;
    string root_path, rank_path;
    // Remainder via bounded binary shift/subtract: domain/root <= M, root <= 32095 bits.
    function automatic logic [WIDTH-1:0] rem_wide(input logic [WIDTH-1:0] numerator, divisor);
        logic [WIDTH-1:0] rr, shifted;
        integer k;
        begin
            rr=numerator;
            for(k=127;k>=0;k=k-1) begin
                shifted=divisor<<k;
                if(rr>=shifted) rr=rr-shifted;
            end
            rem_wide=rr;
        end
    endfunction
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

    initial begin
        if(!$value$plusargs("creation=%d",creation) || !$value$plusargs("opening=%d",opening) ||
           !$value$plusargs("root=%s",root_path) || !$value$plusargs("rank=%s",rank_path))
            $fatal(1,"GENERAL_RANK_ARGUMENTS");
        if(creation<F-50000 || creation>F+50000 || opening<F-55778 || opening>F+50000)
            $fatal(1,"GENERAL_RANK_BOUNDED_DOMAIN");
        target=opening+64'sd1;
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
        neighbor=0;
        for(q=0;q<6;q=q+1) if(order_at46[q]==4) neighbor=order_at46[(q+1)%6];
        if(neighbor<1 || neighbor>6) $fatal(1,"GENERAL_RANK_NEIGHBOR");
        a0=saved((bowls[4]+384'sd213)*(bowls[4]+384'sd213)
                 +384'sd179*bowls[neighbor]+384'sd32);
        direction_seed=saved((a0+384'sd226)*(a0+384'sd226)
                 +384'sd193*a0+384'sd197*bowls[6]);
        step=direction_seed[0] ? 384'sd1 : -384'sd1;

        root='0;
        fi=$fopen(root_path,"rb");
        if(fi==0) $fatal(1,"GENERAL_RANK_ROOT_OPEN");
        for(i=BYTES-1;i>=0;i=i-1) begin
            codepoint=$fgetc(fi);
            if(codepoint<0) $fatal(1,"GENERAL_RANK_ROOT_SHORT");
            root[i*8+:8]=codepoint[7:0];
        end
        if($fgetc(fi)!=-1) $fatal(1,"GENERAL_RANK_ROOT_LONG");
        $fclose(fi);
        if(root==0 || root[WIDTH-1:32095]!='0) $fatal(1,"GENERAL_RANK_ROOT_RANGE");
        space=WIDTH'(MODULUS); digits=1;
        while(space<root && digits<253) begin
            space=(space<<127)-space;
            digits=digits+1;
        end
        if(space<root) $fatal(1,"GENERAL_RANK_DOMAIN_CAP");
        wide0='0;
        for(i=digits-1;i>=0;i=i-1) begin
            digit=saved(a0+step*i)-384'sd1;
            if(digit<0 || digit>=MODULUS) $fatal(1,"GENERAL_RANK_DIGIT");
            wide0=(wide0<<127)-wide0+WIDTH'(digit);
        end
        if(wide0>=space) $fatal(1,"GENERAL_RANK_INITIAL_RANGE");
        limit=space-rem_wide(space,root);
        if(limit==0) $fatal(1,"GENERAL_RANK_LIMIT");
        accepted=wide0+WIDTH'(1);
        if(accepted>limit) accepted=step==384'sd1 ? WIDTH'(1) : limit;
        ordinal=rem_wide(accepted-WIDTH'(1),root)+WIDTH'(1);
        if(ordinal==0 || ordinal>root) $fatal(1,"GENERAL_RANK_ORDINAL_RANGE");
        fo=$fopen(rank_path,"wb");
        if(fo==0) $fatal(1,"GENERAL_RANK_OUTPUT_OPEN");
        for(i=BYTES-1;i>=0;i=i-1) $fwrite(fo,"%c",ordinal[i*8+:8]);
        $fclose(fo);
        $display("GENERAL_NATIVE_RANK_PASS digits=%0d step=%0d",digits,step);
        $finish;
    end
endmodule
