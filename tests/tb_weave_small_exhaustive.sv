`timescale 1ns/1ps
// Stage 1 test-only: exhaustive lexical weave unranking for toy calendars.
// The normative constraints are the ordered FIRST and ordered LAST
// occurrence of months. Lengths here are intentionally small; this
// test does NOT compute the 45-month/4244-day production-sized weave.
module tb_weave_small_exhaustive;
    integer lengths[0:3],powers[0:3],ways[0:624];
    integer place[0:7], words[0:30];
    integer tests=0, total_words_checked=0;
    integer prefix_witnesses_checked=0;

    // Can next month j (zero based) appear from this used-count state?
    function automatic integer valid_move(input integer state,
                                          input integer j,
                                          input integer months);
        integer k, u, earlier, okay;
        begin
            okay=(j>=0 && j<months);
            u=(state/powers[j])%5;
            if (u>=lengths[j]) okay=0;
            if (u==0) begin
                // Month j cannot start before every smaller-index
                // month has appeared at least once.
                for(k=0;k<j;k=k+1)
                    if(((state/powers[k])%5)==0) okay=0;
            end
            if(u+1==lengths[j]) begin
                // Month j cannot finish before every smaller-index
                // month has completely finished.
                for(k=0;k<j;k=k+1)
                    if(((state/powers[k])%5)!=lengths[k]) okay=0;
            end
            valid_move=okay;
        end
    endfunction


    function automatic integer exact_binomial(input integer nn, input integer kk);
        integer i, acc;
        begin
            if(kk<0 || nn<0 || kk>nn) exact_binomial=0;
            else begin
                acc=1;
                for(i=1;i<=kk;i=i+1)
                    acc=(acc*(nn-i+1))/i;
                exact_binomial=acc;
            end
        end
    endfunction

    // Polynomial-sized transfer for a legal prefix, not a dense
    // tensor over (length_1+1)*...*(length_m+1) count states.
    // s = highest month seen so far. Remaining copies of months
    // <=s have no further first-appearance constraints; after
    // they finish, fresh months s+1..m must start and finish in order.
    task automatic count_prefix_fast(
        input integer m,
        input integer prefix_value,
        input integer prefix_length,
        output integer answer
    );
        integer remaining[0:3], fresh_dp[0:9], next_dp[0:9];
        integer i,j,k,month_label,x,s,oldN,mul,pre,ans,coefficient;
        begin
            for(i=0;i<4;i=i+1) remaining[i]=lengths[i];
            x=prefix_value;
            s=0;
            for(i=prefix_length-1;i>=0;i=i-1) begin
                month_label=x%10;
                x=x/10;
                if(month_label<1 || month_label>m)
                    $fatal(1,"FAST_PREFIX_INVALID_LABEL");
                remaining[month_label-1]=remaining[month_label-1]-1;
                if(month_label>s) s=month_label;
            end

            // Active labels already started in the prefix:
            // insert increasing labels, requiring only that the
            // last new occurrence follow the last old occurrence.
            oldN=0;mul=1;
            for(j=0;j<s;j=j+1)
                if(remaining[j]>0) begin
                    if(oldN>0)
                        mul=mul*exact_binomial(oldN+remaining[j]-1,oldN);
                    oldN=oldN+remaining[j];
                end

            if(s==m) answer=mul;
            else begin
                for(i=0;i<10;i=i+1) fresh_dp[i]=0;
                // First previously unseen label: its first suffix
                // appearance may occur after any old letter.
                if(oldN==0) fresh_dp[1]=mul;
                else for(k=0;k<=oldN;k=k+1) begin
                    coefficient=(k==oldN)?1:
                        exact_binomial(remaining[s]+oldN-k-2,oldN-k);
                    fresh_dp[k+1]=mul*coefficient;
                end
                oldN=oldN+remaining[s];
                // Every subsequent *fresh* label must appear first
                // after the first occurrence of its predecessor.
                for(j=s+1;j<m;j=j+1) begin
                    for(i=0;i<10;i=i+1) next_dp[i]=0;
                    pre=0;
                    for(k=1;k<=oldN;k=k+1) begin
                        pre=pre+fresh_dp[k];
                        coefficient=(k==oldN)?1:
                            exact_binomial(remaining[j]+oldN-k-2,oldN-k);
                        next_dp[k+1]=pre*coefficient;
                    end
                    oldN=oldN+remaining[j];
                    for(i=0;i<10;i=i+1) fresh_dp[i]=next_dp[i];
                end
                ans=0;
                for(k=1;k<=oldN;k=k+1) ans=ans+fresh_dp[k];
                answer=ans;
            end
        end
    endtask

    task automatic run_toy(input integer id, input integer months,
                           input integer a, input integer b,
                           input integer c, input integer d,
                           input integer expected_count);
        integer state,j,k,valid,done,used,blocks;
        integer total,limit,raw,pos,which,first_index,last_index;
        integer code,count,accept,new_count,rank,chosen,unrank_code;
        integer next_state,seen[0:3];
        integer prefix_len,prefix_value,reference_count,fast_count,other_rank,power_ten;
        begin
            lengths[0]=a;lengths[1]=b;lengths[2]=c;lengths[3]=d;
            powers[0]=1; powers[1]=5; powers[2]=25; powers[3]=125;
            total=0;
            for(j=0;j<months;j=j+1) begin
                if(lengths[j]<1 || lengths[j]>4)
                    $fatal(1,"TOY_MONTH_LENGTH_RANGE");
                total=total+lengths[j];
            end
            if(total>8 || months<2 || months>4)
                $fatal(1,"TOY_CASE_SIZE");

            // Bottom-up exact suffix counting. Every legal increment
            // increases state by powers[j], so descending order is valid.
            for(state=624;state>=0;state=state-1) begin
                valid=1;done=1;
                for(j=0;j<4;j=j+1) begin
                    used=(state/powers[j])%5;
                    if(j>=months && used!=0) valid=0;
                    if(j<months && used>lengths[j]) valid=0;
                    if(j<months && used!=lengths[j]) done=0;
                end
                ways[state]=0;
                if(valid) begin
                    if(done) ways[state]=1;
                    else for(j=0;j<months;j=j+1)
                        if(valid_move(state,j,months))
                            ways[state]=ways[state]+ways[state+powers[j]];
                end
            end
            if(ways[0]!=expected_count)
                $fatal(1,"TOY_WEAVE_DP_COUNT id=%0d got=%0d expected=%0d",
                       id,ways[0],expected_count);

            // Independent full enumeration of all m^L words, with an
            // explicit prefix automaton, NOT calling valid_move/ways.
            place[total-1]=1;
            for(pos=total-2;pos>=0;pos=pos-1)
                place[pos]=place[pos+1]*months;
            limit=months*place[0];
            count=0;
            for(raw=0;raw<limit;raw=raw+1) begin
                for(j=0;j<4;j=j+1) seen[j]=0;
                first_index=1;last_index=1;valid=1;code=0;
                for(pos=0;pos<total;pos=pos+1) begin
                    which=((raw/place[pos])%months)+1;
                    j=which-1;
                    seen[j]=seen[j]+1;
                    code=code*10+which;
                    if(seen[j]>lengths[j]) valid=0;
                    if(seen[j]==1) begin
                        if(which!=first_index) valid=0;
                        first_index=first_index+1;
                    end
                    if(seen[j]==lengths[j]) begin
                        if(which!=last_index) valid=0;
                        last_index=last_index+1;
                    end
                end
                for(j=0;j<months;j=j+1)
                    if(seen[j]!=lengths[j]) valid=0;
                if(valid) begin
                    if(count>=31) $fatal(1,"TOY_WITNESS_CAPACITY");
                    words[count]=code;
                    count=count+1;
                end
            end
            if(count!=expected_count)
                $fatal(1,"TOY_WEAVE_EXHAUSTIVE_COUNT id=%0d got=%0d expected=%0d",
                       id,count,expected_count);
            total_words_checked=total_words_checked+limit;

            // Prove *all* lexical ranks, not just the total count.
            for(rank=0;rank<count;rank=rank+1) begin
                state=0;blocks=rank;unrank_code=0;
                for(pos=0;pos<total;pos=pos+1) begin
                    chosen=-1;
                    for(j=0;j<months;j=j+1) begin
                        if(chosen<0 && valid_move(state,j,months)) begin
                            next_state=state+powers[j];
                            if(blocks<ways[next_state]) begin
                                chosen=j;
                                state=next_state;
                            end else
                                blocks=blocks-ways[next_state];
                        end
                    end
                    if(chosen<0) $fatal(1,"TOY_WEAVE_UNRANK_EMPTY");
                    unrank_code=unrank_code*10+chosen+1;
                end
                if(blocks!=0 || unrank_code!=words[rank])
                    $fatal(1,"TOY_WEAVE_UNRANK_MISMATCH id=%0d rank=%0d got=%0d expected=%0d",
                           id,rank+1,unrank_code,words[rank]);
            end

            // For every legal prefix of every valid word, compare
            // exact count of remaining legal lexical completions
            // against an independently enumerated reference set.
            for(rank=0;rank<count;rank=rank+1) begin
                power_ten=1;
                for(prefix_len=total;prefix_len>=0;prefix_len=prefix_len-1) begin
                    prefix_value=words[rank]/power_ten;
                    reference_count=0;
                    for(other_rank=0;other_rank<count;other_rank=other_rank+1)
                        if(words[other_rank]/power_ten==prefix_value)
                            reference_count=reference_count+1;
                    count_prefix_fast(months,prefix_value,prefix_len,fast_count);
                    if(fast_count!=reference_count)
                        $fatal(1,"TOY_WEAVE_PREFIX_FAST_COUNT id=%0d prefix=%0d got=%0d expected=%0d",
                               id,prefix_value,fast_count,reference_count);
                    prefix_witnesses_checked=prefix_witnesses_checked+1;
                    power_ten=power_ten*10;
                end
            end
            tests=tests+1;
            $display("STAGE1_TOY_WEAVE_CASE_PASS id=%0d months=%0d length=%0d weaves=%0d",
                     id,months,total,count);
        end
    endtask

    initial begin
        run_toy(1,2,2,2,0,0,2);
        run_toy(2,3,2,2,2,0,5);
        run_toy(3,3,3,2,2,0,9);
        run_toy(4,4,2,2,2,2,14);
        run_toy(5,3,4,2,1,0,4);
        run_toy(6,4,1,1,1,1,1);
        run_toy(7,3,1,2,1,0,1);
        run_toy(8,2,4,4,0,0,20);
        if(tests!=8 || total_words_checked<60000 || prefix_witnesses_checked<200)
            $fatal(1,"TOY_WEAVE_COVERAGE");
        $display("STAGE1_WEAVE_EXHAUSTIVE_AND_LEX_UNRANK_PASS cases=%0d words=%0d prefixes=%0d",
                 tests,total_words_checked,prefix_witnesses_checked);
        $finish;
    end
endmodule
