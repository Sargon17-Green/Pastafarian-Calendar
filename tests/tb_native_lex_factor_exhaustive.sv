`timescale 1ns/1ps
// QA-only arithmetic gate for the Stage 1 native lexical block factors.
// Independent of the 572MB H archive and Python rank-ledger witnesses.
// Three-label exhaustive permutation enumeration (r_i = 0..3) plus
// deterministic forty-five-label exact direct-vs-fast comparisons.
module tb_native_lex_factor_exhaustive;
  localparam integer WIDTH=2048, CWIDTH=864, LIMBS=27, MONTHS=45;
  integer rem[1:MONTHS], accum[1:MONTHS];
  logic [WIDTH-1:0] prefix_factor[1:MONTHS], suffix_factor[1:MONTHS];
  logic [WIDTH-1:0] fast_child[1:MONTHS], fast_parent;
  integer started,first_active;
  integer i,j,p,q,z,case_no,nlegal,nbad,ntoy,budget,digit,k;
  integer seen[1:3],last_seen[1:3],code,rest,old_count;
  int unsigned seed;
  bit mutant;

  function automatic logic [CWIDTH-1:0] divide_small(
      input logic [CWIDTH-1:0] dividend,
      input integer divisor);
    logic [CWIDTH-1:0] quotient;
    logic [63:0] curr,carry;
    integer limb;
    begin
      if(divisor<=0 || divisor>4244) $fatal(1,"FACTOR_UNIT_DIV_RANGE");
      quotient='0;
      carry='0;
      for(limb=LIMBS-1;limb>=0;limb=limb-1) begin
        curr=(carry<<32)|{32'b0,dividend[limb*32+:32]};
        quotient[limb*32+:32]=curr/$unsigned(divisor);
        carry=curr%$unsigned(divisor);
      end
      if(carry!=0) $fatal(1,"FACTOR_UNIT_NONEXACT_DIV");
      divide_small=quotient;
    end
  endfunction

  function automatic logic [CWIDTH-1:0] choose_exact(
      input integer top,input integer bottom);
    logic [CWIDTH-1:0] value,product;
    integer take,idx;
    begin
      if(top<0 || top>4244 || bottom<0 || bottom>top)
        $fatal(1,"FACTOR_UNIT_BAD_BINOMIAL");
      take=(bottom<top-bottom)?bottom:top-bottom;
      value=CWIDTH'(1);
      for(idx=1;idx<=take;idx=idx+1) begin
        product=value*$unsigned(top-take+idx);
        value=divide_small(product,idx);
      end
      choose_exact=value;
    end
  endfunction

  // Separate O(s^2) direct definition for the optimized O(s)
  // prefix/suffix computation to cross-check.
  function automatic logic [WIDTH-1:0] direct_factor();
    integer x,running,copycount;
    bit saw_positive;
    logic [WIDTH-1:0] ans;
    begin
      ans=WIDTH'(1);running=0;saw_positive=0;
      for(x=1;x<=started;x=x+1) begin
        copycount=rem[x];
        if(copycount<0) $fatal(1,"FACTOR_UNIT_NEGATIVE_REMAINING");
        if(copycount==0) begin
          if(saw_positive) ans='0;
        end else if(ans!=0) begin
          saw_positive=1;
          running=running+copycount;
          if(running>copycount)
            ans=ans*WIDTH'(choose_exact(running-1,copycount-1));
        end
      end
      direct_factor=ans;
    end
  endfunction

  task automatic fast_factors();
    integer x;
    bit valid;
    begin
      first_active=0;
      valid=1;
      for(x=1;x<=started;x=x+1) begin
        if(x==1) accum[x]=rem[x];
        else accum[x]=accum[x-1]+rem[x];
        if(rem[x]>0 && first_active==0) first_active=x;
        fast_child[x]='0;
      end
      fast_parent=WIDTH'(1);
      if(first_active>0) begin
        for(x=first_active;x<=started;x=x+1)
          if(rem[x]==0) valid=0;
        if(valid) begin
          prefix_factor[first_active]=WIDTH'(1);
          for(x=first_active+1;x<=started;x=x+1)
            prefix_factor[x]=prefix_factor[x-1]*
              WIDTH'(choose_exact(accum[x]-1,rem[x]-1));
          suffix_factor[started]=WIDTH'(1);
          for(x=started-1;x>=first_active;x=x-1)
            suffix_factor[x]=suffix_factor[x+1]*
              WIDTH'(choose_exact(accum[x+1]-2,rem[x+1]-1));
          fast_parent=prefix_factor[started];
          fast_child[first_active]=suffix_factor[first_active];
          for(x=first_active+1;x<=started;x=x+1)
            if(rem[x]>1)
              fast_child[x]=prefix_factor[x-1]*
                WIDTH'(choose_exact(accum[x]-2,rem[x]-2))*
                suffix_factor[x];
        end else fast_parent='0;
      end
    end
  endtask

  // An independent enumeration of ALL 3^N words of N remaining
  // positions (N<=9) counts only words with exact copies and
  // strictly ascending final occurrences, including exhausted
  // leading labels (last occurrence = -1).
  function automatic integer brute_three();
    integer total,limit,candidate,tmp,slot,sym,ordinal,counted;
    integer counter[1:3],last[1:3];
    begin
      total=rem[1]+rem[2]+rem[3];
      if(total==0) begin
        brute_three=1;
      end else begin
        limit=1;
        for(slot=0;slot<total;slot=slot+1) limit=limit*3;
        counted=0;
        for(candidate=0;candidate<limit;candidate=candidate+1) begin
          tmp=candidate;
          for(sym=1;sym<=3;sym=sym+1) begin
            counter[sym]=0;
            // Absent labels have already completed in increasing
            // label order. Give them DISTINCT ordered sentinels.
            last[sym]=sym-4;
          end
          for(slot=0;slot<total;slot=slot+1) begin
            ordinal=(tmp%3)+1;
            tmp=tmp/3;
            counter[ordinal]=counter[ordinal]+1;
            last[ordinal]=slot;
          end
          if(counter[1]==rem[1] && counter[2]==rem[2] &&
             counter[3]==rem[3] && last[1]<last[2] &&
             last[2]<last[3]) counted=counted+1;
        end
        brute_three=counted;
      end
    end
  endfunction

  initial begin
    mutant=$test$plusargs("mutate_fast");
    for(i=1;i<=MONTHS;i=i+1) rem[i]=0;
    started=3;
    ntoy=0;
    for(p=0;p<=3;p=p+1)
      for(q=0;q<=3;q=q+1)
        for(z=0;z<=3;z=z+1) begin
          rem[1]=p;rem[2]=q;rem[3]=z;
          fast_factors();
          if(fast_parent!==direct_factor() ||
             fast_parent!==WIDTH'(brute_three()))
            $fatal(1,"FACTOR_UNIT_TOY_BRUTE_MISMATCH r=%0d,%0d,%0d",p,q,z);
          if(fast_parent!=0) begin
            for(i=1;i<=3;i=i+1)
              if(rem[i]>0) begin
                rem[i]=rem[i]-1;
                if(fast_child[i]!==direct_factor())
                  $fatal(1,"FACTOR_UNIT_TOY_CHILD_MISMATCH at=%0d r=%0d,%0d,%0d",
                        i,p,q,z);
                rem[i]=rem[i]+1;
              end
          end
          ntoy=ntoy+1;
        end
    $display("STAGE1_LEX_FAST_TOY_PERMUTATIONS_PASS cases=%0d",ntoy);

    seed=32'h9e3779b9;
    nlegal=0;nbad=0;
    for(case_no=0;case_no<160;case_no=case_no+1) begin
      started=1+(case_no%45);
      seed=seed^(seed<<13);
      seed=seed^(seed>>17);
      seed=seed^(seed<<5);
      first_active=1+(seed%started);
      for(i=1;i<=started;i=i+1) begin
        if(i<first_active) rem[i]=0;
        else begin
          seed=seed^(seed<<13);
          seed=seed^(seed>>17);
          seed=seed^(seed<<5);
          rem[i]=1+(seed%8);
        end
      end
      fast_factors();
      if(mutant && case_no==0) fast_parent=fast_parent+WIDTH'(1);
      if(fast_parent!==direct_factor())
        $fatal(1,"FACTOR_UNIT_PARENT_MUTATION_REJECTED case=%0d",case_no);
      for(i=1;i<=started;i=i+1)
        if(rem[i]>0) begin
          rem[i]=rem[i]-1;
          if(fast_child[i]!==direct_factor())
            $fatal(1,"FACTOR_UNIT_CHILD_MISMATCH case=%0d label=%0d",case_no,i);
          rem[i]=rem[i]+1;
          nlegal=nlegal+1;
        end

      // Deliberately invalid zero after a nonzero: verify parent 0.
      if(started>=3) begin
        for(i=1;i<=started;i=i+1) rem[i]=2;
        rem[2]=0;
        fast_factors();
        if(fast_parent!==WIDTH'(0) || direct_factor()!==WIDTH'(0))
          $fatal(1,"FACTOR_UNIT_INTERIOR_ZERO_NOT_REJECTED case=%0d",case_no);
        nbad=nbad+1;
      end
    end
    $display("STAGE1_LEX_FAST_45_LABEL_FACTOR_QA_PASS synthetic=160 children=%0d invalid=%0d",
             nlegal,nbad);
    $finish;
  end
endmodule
