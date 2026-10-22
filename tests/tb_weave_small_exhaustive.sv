`timescale 1ns/1ps
// Stage 1 test-only: exhaustive lexical weave unranking for toy calendars.
// The normative constraints are the ordered FIRST and ordered LAST
// occurrence of months. Lengths here are intentionally small; this
// test does NOT compute the 45-month/4244-day production-sized weave.
module tb_weave_small_exhaustive;
    integer lengths[0:3],powers[0:3],ways[0:624];
    integer place[0:7], words[0:30];
    integer tests=0, total_words_checked=0;

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

    task automatic run_toy(input integer id, input integer months,
                           input integer a, input integer b,
                           input integer c, input integer d,
                           input integer expected_count);
        integer state,j,k,valid,done,used,blocks;
        integer total,limit,raw,pos,which,first_index,last_index;
        integer code,count,accept,new_count,rank,chosen,unrank_code;
        integer next_state,seen[0:3];
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
        if(tests!=8 || total_words_checked<60000)
            $fatal(1,"TOY_WEAVE_COVERAGE");
        $display("STAGE1_WEAVE_EXHAUSTIVE_AND_LEX_UNRANK_PASS cases=%0d words=%0d",
                 tests,total_words_checked);
        $finish;
    end
endmodule
