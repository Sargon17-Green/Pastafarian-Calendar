`timescale 1ns/1ps
// Test-only gate/gap oracle. Reconstructed solely from the normative Scroll.
// No production module is imported, no calendar date is claimed.
module tb_gate_gap_oracle;
    import pcal_stage1_oracle_pkg::*;
    import pcal_exact_division_pkg::*;
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
            distance_count=oracle_distance(c,t);
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

    // Stage-1 cutlet validation for c=t=Foundation, year-5000 gates.
    integer cutlet_count, cutlet_choice, comp_count, comp_choice;
    integer piece_parts [0:127][0:7];
    integer cutlet_gaps [1:8];
    integer permutation_count, names_choice, remaining_rank;
    integer name_values [0:7], available_names [0:16];
    integer gap_pos, mask, popcount, last_break, piece_no, mask_bit;
    integer compare_state, swapping, slot, candidate, product, choose_slot;
    integer name_i, name_j, chosen_cutlet_pos, chosen_day;
    integer gate_covered, start_gap, selected_piece_length;
    integer month_min, month_max, month_choice, month_count;
    logic [383:0] month_dp [0:45][0:4244];
    logic [383:0] month_running, month_total, month_wide,
                  month_bound, month_accepted, month_zero_rank,
                  month_rank, month_block;
    logic signed [383:0] month_A0, month_flow, month_digit;
    integer expected_month_lengths [0:44];
    integer selected_month_lengths [0:44];
    integer dp_month_i, dp_sum_i, unrank_month_i, trial_month_length;
    integer remaining_month_days, assigned_length, month_direction;
    integer month_next_bowl, month_query_i;

    // Bowl query per normative sections M/N, with the immutable
    // orderAt46. Used only for small-domain test-only selections.
    task automatic query_short(
        input integer bowl_id,
        input integer seal_value,
        input integer choice_total,
        output integer answer_index
    );
        integer next_id, qpos;
        logic signed [383:0] answer_zero, flow_dir, accept_bound, picked;
        begin
            if(choice_total < 1 || choice_total > 980179200)
                $fatal(1,"SHORT_QUERY_UNSUPPORTED_CHOICE_COUNT");
            next_id=0;
            for(qpos=0;qpos<6;qpos=qpos+1)
                if(order_at46[qpos]==bowl_id)
                    next_id=order_at46[(qpos+1)%6];
            if(next_id<1 || next_id>6) $fatal(1,"QUERY_NEXT_BOWL");

            answer_zero=saved((bowls[bowl_id]+seal_value+384'sd181)
                               *(bowls[bowl_id]+seal_value+384'sd181)
                               +384'sd179*bowls[next_id]+seal_value);
            flow_dir=saved((answer_zero+seal_value+384'sd1+384'sd193)
                            *(answer_zero+seal_value+384'sd1+384'sd193)
                            +384'sd193*answer_zero+384'sd197*bowls[6]);
            accept_bound=(MODULUS/choice_total)*choice_total;
            if(answer_zero<=accept_bound) picked=answer_zero;
            else if((flow_dir%384'sd2)==384'sd1) picked=384'sd1;
            else picked=accept_bound;
            answer_index=1+int'((picked-384'sd1)%choice_total);
            if(answer_index<1 || answer_index>choice_total)
                $fatal(1,"QUERY_SHORT_RANGE");
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

        // Stage 1 oracle cutlet component: Q-S-T for c=t=Foundation.
        // YEAR 5000 open=-15057703, firstDay=-15057702. The 8 gaps
        // in chronological order are negative #4..#1, then positive #1..#4.
        cutlet_gaps[1]=negative_expected[4];
        cutlet_gaps[2]=negative_expected[3];
        cutlet_gaps[3]=negative_expected[2];
        cutlet_gaps[4]=negative_expected[1];
        for(gap_pos=5;gap_pos<=8;gap_pos=gap_pos+1)
            cutlet_gaps[gap_pos]=positive_expected[gap_pos-4];

        run_gate(-64'sd15055671,-64'sd15057702,gap_value);
        query_short(2,20,3,cutlet_choice);
        cutlet_count=5+cutlet_choice;  // 6..min(17,G=8)
        if(cutlet_count<6 || cutlet_count>8)
            $fatal(1,"FOUNDATION_CUTLET_COUNT_RANGE");

        // Enumerate all positive compositions of G=8 with K parts;
        // require a breakpoint at internal gate #4, namely c=Foundation.
        comp_count=0;
        for(mask=0;mask<128;mask=mask+1) begin
            popcount=0;
            for(gap_pos=1;gap_pos<=7;gap_pos=gap_pos+1)
                if((mask & (1 << (gap_pos-1)))!=0)
                    popcount=popcount+1;
            if(popcount==(cutlet_count-1) && (mask & 8)!=0) begin
                piece_no=0;
                last_break=0;
                for(gap_pos=1;gap_pos<=7;gap_pos=gap_pos+1)
                    if((mask & (1 << (gap_pos-1)))!=0) begin
                        piece_parts[comp_count][piece_no]=gap_pos-last_break;
                        last_break=gap_pos;
                        piece_no=piece_no+1;
                    end
                piece_parts[comp_count][piece_no]=8-last_break;
                if(piece_no+1!=cutlet_count)
                    $fatal(1,"COMPOSITION_PIECE_COUNT");
                comp_count=comp_count+1;
            end
        end
        if(comp_count<1 || comp_count>15)
            $fatal(1,"ELIGIBLE_COMPOSITION_COUNT_RANGE");

        // Explicit lexicographic sort of composition tuples.
        for(aa=0;aa<comp_count;aa=aa+1) begin
            for(bb=aa+1;bb<comp_count;bb=bb+1) begin
                compare_state=0;
                for(slot=0;slot<cutlet_count;slot=slot+1) begin
                    if(compare_state==0 &&
                       piece_parts[aa][slot]!=piece_parts[bb][slot]) begin
                        if(piece_parts[bb][slot]<piece_parts[aa][slot])
                            compare_state=-1;
                        else compare_state=1;
                    end
                end
                if(compare_state==-1) begin
                    for(slot=0;slot<cutlet_count;slot=slot+1) begin
                        swapping=piece_parts[aa][slot];
                        piece_parts[aa][slot]=piece_parts[bb][slot];
                        piece_parts[bb][slot]=swapping;
                    end
                end
            end
        end
        query_short(2,21,comp_count,comp_choice);

        // At c=Foundation: the fourth chronological gate is c itself.
        // Locate its cutlet, and measure the number of days from
        // that cutlet's first day to c inclusive.
        gate_covered=0;
        chosen_cutlet_pos=0;
        chosen_day=0;
        for(slot=0;slot<cutlet_count;slot=slot+1) begin
            selected_piece_length=0;
            for(name_i=0;name_i<piece_parts[comp_choice-1][slot];name_i=name_i+1)
                selected_piece_length=selected_piece_length+
                    cutlet_gaps[gate_covered+name_i+1];
            gate_covered=gate_covered+piece_parts[comp_choice-1][slot];
            if(gate_covered==4) begin
                chosen_cutlet_pos=slot+1;
                chosen_day=selected_piece_length;
            end
        end
        if(gate_covered!=8 || chosen_cutlet_pos==0)
            $fatal(1,"FOUNDATION_CUTLET_BOUNDARY");

        // Assign K distinct canonical indices by lexical unranking of
        // 17Pk sequences, bowl 5 seal 22, not string alphabetization.
        permutation_count=1;
        for(slot=0;slot<cutlet_count;slot=slot+1)
            permutation_count=permutation_count*(17-slot);
        if(permutation_count<=0 || permutation_count>980179200)
            $fatal(1,"CUTLET_NAMES_CHOICE_RANGE");
        query_short(5,22,permutation_count,names_choice);
        remaining_rank=names_choice-1;
        for(name_i=0;name_i<17;name_i=name_i+1)
            available_names[name_i]=name_i+1;
        for(slot=0;slot<cutlet_count;slot=slot+1) begin
            product=1;
            for(name_i=0;name_i<cutlet_count-slot-1;name_i=name_i+1)
                product=product*(16-slot-name_i);
            choose_slot=remaining_rank/product;
            remaining_rank=remaining_rank%product;
            if(choose_slot<0 || choose_slot>16-slot)
                $fatal(1,"CUTLET_NAME_UNRANK_DIGIT");
            name_values[slot]=available_names[choose_slot];
            for(name_i=choose_slot;name_i<16-slot;name_i=name_i+1)
                available_names[name_i]=available_names[name_i+1];
        end
        for(name_i=0;name_i<cutlet_count;name_i=name_i+1) begin
            if(name_values[name_i]<1 || name_values[name_i]>17)
                $fatal(1,"CUTLET_NAME_INDEX_RANGE");
            for(name_j=name_i+1;name_j<cutlet_count;name_j=name_j+1)
                if(name_values[name_i]==name_values[name_j])
                    $fatal(1,"CUTLET_NAME_COLLISION");
        end
        // External normative checkpoint for the full cutlet construction.
        // This is intentionally stronger than the final (10,503) check:
        // a wrong composition order could coincidentally retain that pair.
        if(cutlet_count!=6 || comp_count!=15 || comp_choice!=9 ||
           names_choice!=7851263 || chosen_cutlet_pos!=3)
            $fatal(1,"FOUNDATION_CUTLET_CANONICAL_INTERMEDIATE");
        if(piece_parts[comp_choice-1][0]!=1 ||
           piece_parts[comp_choice-1][1]!=2 ||
           piece_parts[comp_choice-1][2]!=1 ||
           piece_parts[comp_choice-1][3]!=2 ||
           piece_parts[comp_choice-1][4]!=1 ||
           piece_parts[comp_choice-1][5]!=1)
            $fatal(1,"FOUNDATION_CUTLET_COMPOSITION_VECTOR");
        if(name_values[0]!=15 || name_values[1]!=17 ||
           name_values[2]!=10 || name_values[3]!=14 ||
           name_values[4]!=8 || name_values[5]!=13)
            $fatal(1,"FOUNDATION_CUTLET_NAMES_VECTOR");
        $display("STAGE1_FOUNDATION_CUTLET_DETAIL K=%0d compositions=%0d comp_rank=%0d names_rank=%0d ordinal=%0d index=%0d day=%0d",
                 cutlet_count,comp_count,comp_choice,names_choice,
                 chosen_cutlet_pos,name_values[chosen_cutlet_pos-1],chosen_day);
        if(name_values[chosen_cutlet_pos-1]!=10 || chosen_day!=503)
            $fatal(1,"FOUNDATION_CANONICAL_CUTLET_10_DAY_503");
        $display("STAGE1_FOUNDATION_CUTLET_REFERENCE_PASS index=10 day=503");
        // Next independent oracle layer (U): the *number* of months.
        // Length composition, weave, name assignment are not yet implemented.
        month_min=(4244+122)/123;
        month_max=(4244/4 < 47) ? 4244/4 : 47;
        if(month_min!=35 || month_max!=47)
            $fatal(1,"FOUNDATION_MONTH_COUNT_BOUNDS");
        query_short(3,30,month_max-month_min+1,month_choice);
        month_count=month_min+month_choice-1;
        if(month_choice!=11 || month_count!=45)
            $fatal(1,"FOUNDATION_MONTH_COUNT_45");
        $display("STAGE1_FOUNDATION_MONTH_CARDINALITY_PASS min=%0d max=%0d choice=%0d count=%0d",
                 month_min,month_max,month_choice,month_count);
        // Exact number of lexical length vectors:
        // for m=45, sum=4244, each length in the closed range 4..123.
        // Test-only 384-bit unsigned DP, retaining every subproblem.
        for(dp_sum_i=0;dp_sum_i<=4244;dp_sum_i=dp_sum_i+1)
            month_dp[0][dp_sum_i]=(dp_sum_i==0) ? 384'd1 : 384'd0;
        for(dp_month_i=1;dp_month_i<=45;dp_month_i=dp_month_i+1) begin
            month_running=384'd0;
            for(dp_sum_i=0;dp_sum_i<=4244;dp_sum_i=dp_sum_i+1) begin
                if(dp_sum_i>=4)
                    month_running=month_running+month_dp[dp_month_i-1][dp_sum_i-4];
                if(dp_sum_i>=124)
                    month_running=month_running-month_dp[dp_month_i-1][dp_sum_i-124];
                month_dp[dp_month_i][dp_sum_i]=month_running;
            end
        end
        month_total=month_dp[45][4244];
        if(month_total!==384'h3b999c3af2d83d8b41d8b6b0aa25e5fc7a260dcb4a823403855975a8c46102e640cc4)
            $fatal(1,"MONTH45_COMPOSITION_TOTAL");

        // Canonical wide answer, bowl 3, seal 31, three base-M digits
        // taken from consecutive flow positions. Division uses the
        // independent *test-only* 384-bit exact long divider.
        month_next_bowl=0;
        for(month_query_i=0;month_query_i<6;month_query_i=month_query_i+1)
            if(order_at46[month_query_i]==3)
                month_next_bowl=order_at46[(month_query_i+1)%6];
        if(month_next_bowl<1 || month_next_bowl>6)
            $fatal(1,"MONTH_NEXT_BOWL");
        month_A0=saved((bowls[3]+384'sd31+384'sd181)
                        *(bowls[3]+384'sd31+384'sd181)
                        +384'sd179*bowls[month_next_bowl]+384'sd31);
        month_flow=saved((month_A0+384'sd31+384'sd1+384'sd193)
                          *(month_A0+384'sd31+384'sd1+384'sd193)
                          +384'sd193*month_A0+384'sd197*bowls[6]);
        month_direction=(month_flow%384'sd2==384'sd1) ? 1 : -1;
        month_wide=384'd1;
        for(month_query_i=0;month_query_i<3;month_query_i=month_query_i+1) begin
            month_digit=384'sd1+((month_A0-384'sd1+month_direction*month_query_i+MODULUS)%MODULUS);
            if(month_query_i==0)
                month_wide=month_wide+(month_digit-384'sd1);
            else if(month_query_i==1)
                month_wide=month_wide+(month_digit-384'sd1)*MODULUS;
            else
                month_wide=month_wide+(month_digit-384'sd1)*MODULUS*MODULUS;
        end
        month_bound=exact_quotient_384(MODULUS*MODULUS*MODULUS,month_total)*month_total;
        if(month_wide<=month_bound)
            month_accepted=month_wide;
        else if(month_direction==1)
            month_accepted=384'd1;
        else
            month_accepted=month_bound;
        month_zero_rank=exact_remainder_384(month_accepted-384'd1,month_total);
        month_rank=month_zero_rank+384'd1;
        if(month_rank!==384'h2dc4103440a9bb51a98553c5d90d5b6b1e2b77cd88cf16203b5f39498173def210a65)
            $fatal(1,"MONTH45_CANONICAL_WIDE_SELECTION");
        if(month_total <= MODULUS*MODULUS ||
           month_total > MODULUS*MODULUS*MODULUS)
            $fatal(1,"MONTH45_MUST_REQUIRE_THREE_DIGITS");

        // Lexicographic unranking of the *entire* length composition.
        // For each candidate length, the DP value counts exactly the
        // remaining suffix block; never approximate the giant rank.
        expected_month_lengths[0]=115;
        expected_month_lengths[1]=108;
        expected_month_lengths[2]=119;
        expected_month_lengths[3]=109;
        expected_month_lengths[4]=106;
        expected_month_lengths[5]=81;
        expected_month_lengths[6]=115;
        expected_month_lengths[7]=114;
        expected_month_lengths[8]=117;
        expected_month_lengths[9]=120;
        expected_month_lengths[10]=98;
        expected_month_lengths[11]=52;
        expected_month_lengths[12]=81;
        expected_month_lengths[13]=97;
        expected_month_lengths[14]=121;
        expected_month_lengths[15]=97;
        expected_month_lengths[16]=115;
        expected_month_lengths[17]=96;
        expected_month_lengths[18]=107;
        expected_month_lengths[19]=61;
        expected_month_lengths[20]=106;
        expected_month_lengths[21]=115;
        expected_month_lengths[22]=119;
        expected_month_lengths[23]=39;
        expected_month_lengths[24]=84;
        expected_month_lengths[25]=103;
        expected_month_lengths[26]=115;
        expected_month_lengths[27]=107;
        expected_month_lengths[28]=55;
        expected_month_lengths[29]=119;
        expected_month_lengths[30]=97;
        expected_month_lengths[31]=50;
        expected_month_lengths[32]=122;
        expected_month_lengths[33]=110;
        expected_month_lengths[34]=81;
        expected_month_lengths[35]=54;
        expected_month_lengths[36]=101;
        expected_month_lengths[37]=83;
        expected_month_lengths[38]=88;
        expected_month_lengths[39]=40;
        expected_month_lengths[40]=25;
        expected_month_lengths[41]=77;
        expected_month_lengths[42]=98;
        expected_month_lengths[43]=122;
        expected_month_lengths[44]=105;
        remaining_month_days=4244;
        for(unrank_month_i=0;unrank_month_i<45;unrank_month_i=unrank_month_i+1) begin
            assigned_length=0;
            for(trial_month_length=4;trial_month_length<=123;trial_month_length=trial_month_length+1) begin
                month_block=384'd0;
                if(remaining_month_days>=trial_month_length &&
                   remaining_month_days-trial_month_length<=4244)
                    month_block=month_dp[44-unrank_month_i][remaining_month_days-trial_month_length];
                if(assigned_length==0) begin
                    if(month_zero_rank<month_block) begin
                        assigned_length=trial_month_length;
                        remaining_month_days=remaining_month_days-trial_month_length;
                    end else
                        month_zero_rank=month_zero_rank-month_block;
                end
            end
            if(assigned_length<4 || assigned_length>123 ||
               assigned_length!=expected_month_lengths[unrank_month_i])
                $fatal(1,"MONTH45_LENGTH_LEX_UNRANK i=%0d got=%0d expected=%0d",
                       unrank_month_i,assigned_length,expected_month_lengths[unrank_month_i]);
            selected_month_lengths[unrank_month_i]=assigned_length;
        end
        if(remaining_month_days!=0 || month_zero_rank!==384'd0)
            $fatal(1,"MONTH45_UNRANK_CONSERVATION");
        $display("STAGE1_FOUNDATION_MONTH_LENGTH_UNRANK_PASS months=45 year_days=4244");



        $display("STAGE1_TEST_ONLY_GATE_GAPS_PASS cases=%0d",case_count);
        $display("STAGE1_YEAR5000_REFERENCE_PASS candidates=%0d rank=%0d",
                 cand_count,year_ordinal);
        $finish;
    end
endmodule
