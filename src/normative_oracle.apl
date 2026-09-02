⍝ Saubere testinterne Referenz für Stage 1. Kein Produktionspfad darf diese Funktionen aufrufen.

∇ OracleInit
  ⎕IO←1
  ⎕CT←0
  M←170141183460469231731687303715884105727x
  TABLETS_DAY←¯278522
  FOUNDATION_DAY←¯15055671
  GATE_GAP_MIN←42
  GATE_GAP_MAX←963
  YEAR_MIN_DAYS←252
  YEAR_MAX_DAYS←5778
  MIN_CUTLETS←6
  MAX_CUTLETS←17
  MIN_MONTHS←3
  MAX_MONTHS←47
  MIN_MONTH_DAYS←4
  MAX_MONTH_DAYS←123
  SEAL_GATE_GAP←1
  SEAL_YEAR_5000←10
  SEAL_NEXT_YEAR←11
  SEAL_PREVIOUS_YEAR←12
  SEAL_CUTLET_COUNT←20
  SEAL_CUTLET_PARTITION←21
  SEAL_CUTLET_NAMES←22
  SEAL_MONTH_COUNT←30
  SEAL_MONTH_LENGTHS←31
  SEAL_MONTH_WEAVING←32
  SEAL_MONTH_NAMES←33
  WHEAT←1 ⋄ BARLEY←2 ⋄ SALT←3 ⋄ BITTER←4 ⋄ RED←5
  HIDDEN_COEFF←7 4⍴3 4 6 8  5 7 10 12  7 10 14 16  9 13 18 20  11 16 22 24  13 19 26 28  15 22 30 32
  HIDDEN_GRIND_STONE←WHEAT BARLEY SALT BITTER RED WHEAT BARLEY
  VISIBLE_GRINDS←11 5⍴3 5 7 11 WHEAT  5 7 11 13 BARLEY  7 11 13 17 SALT  11 13 17 19 BITTER  13 17 19 23 RED  17 19 23 29 WHEAT  19 23 29 31 BARLEY  23 29 31 37 SALT  29 31 37 41 BITTER  31 37 41 43 RED  37 41 43 47 WHEAT
  BOWL_PRIME←17 19 23 29 31 37
  BOWL_STIR_STONE_BY_POSITION←WHEAT BARLEY SALT BITTER RED WHEAT
  STONES←BuildStones
  GateReset
∇

∇ z←d RegularMod x
  z←d|x
∇

∇ z←Save x
  z←1+M RegularMod x-1
∇

∇ z←size Wrap1 position
  z←1+size RegularMod position-1
∇

∇ z←CeilDiv ab;a;b
  a←1⊃ab ⋄ b←2⊃ab
  z←⌊(a+b-1)÷b
∇

∇ z←DayCount day
  :If day=FOUNDATION_DAY
      z←1
  :ElseIf day>FOUNDATION_DAY
      z←1+2×day-FOUNDATION_DAY
  :Else
      z←2×FOUNDATION_DAY-day
  :EndIf
∇

∇ z←c WorkCounts t;cc;tt;distance;connection;direction
  cc←DayCount c
  tt←DayCount t
  distance←1+|t-c
  connection←cc+tt
  direction←2
  :If t<c
      direction←1
  :ElseIf t>c
      direction←3
  :EndIf
  z←cc tt distance connection direction
∇

∇ z←BuildStones;table;i;old;nw;nb;ns;nm;nr
  table←46 5⍴0x
  table[1;]←17x 29x 43x 71x 101x
  :For i :In 2+⍳45
      old←table[i-1;]
      nw←Save (old[WHEAT]×old[WHEAT])+3×old[BARLEY]+i
      nb←Save (old[BARLEY]×old[BARLEY])+5×old[SALT]+old[WHEAT]
      ns←Save (old[SALT]×old[SALT])+7×old[BITTER]+old[BARLEY]
      nm←Save (old[BITTER]×old[BITTER])+11×old[RED]+old[SALT]
      nr←Save (old[RED]×old[RED])+13×old[WHEAT]+old[BITTER]
      table[i;]←nw nb ns nm nr
  :EndFor
  z←table
∇

∇ z←BuildHidden counts;hidden;k;a;b;c;d;x;g;oldx;kind
  hidden←7⍴0x
  :For k :In ⍳7
      a b c d←HIDDEN_COEFF[k;]
      x←counts[1]+a×counts[2]+b×counts[3]+c×counts[4]+d×counts[5]+ +/STONES[k;]
      x←Save x
      :For g :In ⍳7
          oldx←x
          kind←HIDDEN_GRIND_STONE[g]
          x←Save (oldx×oldx)+3×oldx+STONES[k;kind]+g
      :EndFor
      hidden[k]←x
  :EndFor
  z←hidden
∇

∇ z←counts BuildVisible hidden;timeline;visible;i;p1;p3;p7;x;g;row;oldx;slot
  timeline←53⍴0x
  ⍝ Position 8 entspricht sichtbarer Tropfenposition 1; davor liegen sieben verborgene Werte.
  :For i :In ⍳7
      timeline[8-i]←hidden[i]
  :EndFor
  visible←46⍴0x
  :For i :In ⍳46
      p1←timeline[7+i-1]
      p3←timeline[7+i-3]
      p7←timeline[7+i-7]
      x←Save STONES[i;WHEAT]×counts[1]+STONES[i;BARLEY]×counts[2]+STONES[i;SALT]×counts[3]+STONES[i;BITTER]×counts[4]+STONES[i;RED]×counts[5]+p1+3×p3+5×p7+i
      :For g :In ⍳11
          row←VISIBLE_GRINDS[g;]
          oldx←x
          x←Save (oldx×oldx)+row[1]×oldx+row[2]×p1+row[3]×p3+row[4]×p7+STONES[i;row[5]]
      :EndFor
      timeline[7+i]←x
      visible[i]←x
  :EndFor
  z←visible
∇

∇ z←Factorial n;i
  z←1x
  :For i :In ⍳n
      z←z×i
  :EndFor
∇

∇ z←PermutationUnrank1 rank1;rank0;remaining;result;slots;block;q;chosen
  rank0←rank1-1
  remaining←⍳6
  result←⍬
  :While 0<⍴remaining
      slots←⍴remaining
      block←Factorial slots-1
      q←⌊rank0÷block
      rank0←block RegularMod rank0
      chosen←remaining[q+1]
      result←result,chosen
      remaining←((q+1)≠⍳⍴remaining)/remaining
  :EndWhile
  z←result
∇

∇ z←BowlOrderFromDrop drop;rank
  rank←1+720 RegularMod drop-1
  z←PermutationUnrank1 rank
∇

∇ z←InitialBowls counts;bowls;id;s
  bowls←6⍴0x
  :For id :In ⍳6
      s←counts[1]+counts[2]×id+counts[3]+counts[4]+counts[5]+BOWL_PRIME[id]×BOWL_PRIME[id]
      bowls[id]←Save (s×s)+id
  :EndFor
  z←bowls
∇

∇ z←bowls ApplyVisible visible;i;drop;order;old;pour;nextBowls;position;id;prev;next;kind;s;order46
  order46←⍬
  :For i :In ⍳46
      drop←visible[i]
      order←BowlOrderFromDrop drop
      old←bowls
      pour←6⍴0x
      pour[1]←Save (drop×drop)+STONES[i;WHEAT]×old[order[1]]+3×i
      pour[2]←Save (drop×drop)+STONES[i;BARLEY]×old[order[2]]+5×i
      pour[3]←Save (drop×drop)+STONES[i;SALT]×old[order[3]]+7×i
      nextBowls←6⍴0x
      :For position :In ⍳6
          id←order[position]
          prev←order[6 Wrap1 position-1]
          next←order[6 Wrap1 position+1]
          kind←BOWL_STIR_STONE_BY_POSITION[position]
          s←old[id]+2×old[prev]+3×old[next]+pour[position]+drop+STONES[i;kind]
          nextBowls[id]←Save (s×s)+5×old[prev]×old[next]+i×position
      :EndFor
      bowls←nextBowls
      :If i=46
          order46←order
      :EndIf
  :EndFor
  z←(⊂bowls),(⊂order46)
∇

∇ z←PostStir12 bowls;stir;old;saved;rank;order;nextBowls;position;id;prev;next;s
  :For stir :In ⍳12
      old←bowls
      saved←Save (+/old)+149×stir
      rank←1+720 RegularMod saved-1
      order←PermutationUnrank1 rank
      nextBowls←6⍴0x
      :For position :In ⍳6
          id←order[position]
          prev←order[6 Wrap1 position-1]
          next←order[6 Wrap1 position+1]
          s←old[id]+3×old[prev]+5×old[next]+saved+stir+position×position
          nextBowls[id]←Save (s×s)+7×old[prev]×old[next]
      :EndFor
      bowls←nextBowls
  :EndFor
  z←bowls
∇

∇ z←c Sauce t;counts;hidden;visible;bowls;pair;after;order46;final
  counts←c WorkCounts t
  hidden←BuildHidden counts
  visible←counts BuildVisible hidden
  bowls←InitialBowls counts
  pair←bowls ApplyVisible visible
  after←⊃pair[1]
  order46←⊃pair[2]
  final←PostStir12 after
  z←(⊂final),(⊂order46)
∇

∇ z←sauce AskBowl query;bowl;seal;bowls;order;pos;nextid;first;directionNumber;step
  bowl←query[1] ⋄ seal←query[2]
  bowls←⊃sauce[1]
  order←⊃sauce[2]
  pos←order⍳bowl
  nextid←order[6 Wrap1 pos+1]
  first←Save ((bowls[bowl]+seal+181)×(bowls[bowl]+seal+181))+179×bowls[nextid]+seal
  directionNumber←Save ((first+seal+194)×(first+seal+194))+193×first+197×bowls[6]
  step←¯1
  :If 1=2 RegularMod directionNumber
      step←1
  :EndIf
  z←first step
∇

∇ z←stream AnswerAt k
  z←1+M RegularMod stream[1]-1+stream[2]×k
∇

∇ z←stream ChooseRankShort n;limit;k;x
  limit←n×⌊M÷n
  k←0
  :Repeat
      x←stream AnswerAt k
      :If x≤limit
          z←1+n RegularMod x-1
          :Return
      :EndIf
      k←k+1
  :EndRepeat
∇

∇ z←stream ChooseRankWide n;places;space;j;wide;weight;limit
  places←1
  space←M
  :While space<n
      places←places+1
      space←space×M
  :EndWhile
  wide←1x
  weight←1x
  :For j :In 0,⍳places-1
      wide←wide+((stream AnswerAt j)-1)×weight
      weight←weight×M
  :EndFor
  limit←n×⌊space÷n
  :While wide>limit
      wide←1+space RegularMod wide-1+stream[2]
  :EndWhile
  z←1+n RegularMod wide-1
∇

∇ z←stream ChooseRank n
  :If n≤M
      z←stream ChooseRankShort n
  :Else
      z←stream ChooseRankWide n
  :EndIf
∇

∇ z←FallingFactorial nk;n;k;j
  n←nk[1] ⋄ k←nk[2]
  z←1x
  :For j :In 0,⍳k-1
      z←z×n-j
  :EndFor
∇

∇ z←masterCount UnrankDistinct args;k;rank;remaining;out;position;suffix;block;cand;chosen
  k←args[1] ⋄ rank←args[2]
  remaining←⍳masterCount
  out←⍬
  :For position :In ⍳k
      suffix←k-position
      block←FallingFactorial (⍴remaining)-1 suffix
      :For cand :In ⍳⍴remaining
          :If rank>block
              rank←rank-block
          :Else
              chosen←remaining[cand]
              out←out,chosen
              remaining←(cand≠⍳⍴remaining)/remaining
              :Leave
          :EndIf
      :EndFor
  :EndFor
  z←out
∇

∇ z←BoundedCount args;total;slots;lo;hi;dp;k;rem;x
  total←args[1] ⋄ slots←args[2] ⋄ lo←args[3] ⋄ hi←args[4]
  dp←(slots+1,total+1)⍴0x
  dp[1;1]←1x
  :For k :In ⍳slots
      :For rem :In 0,⍳total
          :For x :In lo-1+⍳hi-lo+1
              :If rem≥x
                  dp[k+1;rem+1]←dp[k+1;rem+1]+dp[k;rem-x+1]
              :EndIf
          :EndFor
      :EndFor
  :EndFor
  z←dp[slots+1;total+1]
∇

∇ z←BoundedUnrank args;total;slots;lo;hi;rank;out;position;x;count;rem
  total←args[1] ⋄ slots←args[2] ⋄ lo←args[3] ⋄ hi←args[4] ⋄ rank←args[5]
  out←⍬ ⋄ rem←total
  :For position :In ⍳slots
      :For x :In lo-1+⍳hi-lo+1
          :If rem-x<0
              :Continue
          :EndIf
          count←BoundedCount (rem-x) (slots-position) lo hi
          :If rank>count
              rank←rank-count
          :Else
              out←out,x
              rem←rem-x
              :Leave
          :EndIf
      :EndFor
  :EndFor
  z←out
∇

∇ GateReset
  GATE_INDEX←,0
  GATE_DAY←,FOUNDATION_DAY
∇

∇ z←GateGet k;p
  p←GATE_INDEX⍳k
  :If p>⍴GATE_INDEX
      z←0
  :Else
      z←GATE_DAY[p]
  :EndIf
∇

∇ GatePut pair;k;day;p
  k←pair[1] ⋄ day←pair[2]
  p←GATE_INDEX⍳k
  :If p>⍴GATE_INDEX
      GATE_INDEX←GATE_INDEX,k
      GATE_DAY←GATE_DAY,day
  :Else
      GATE_DAY[p]←day
  :EndIf
∇

∇ z←GateGap signedStep;q;r;stream
  q←FOUNDATION_DAY+signedStep
  r←FOUNDATION_DAY Sauce q
  stream←r AskBowl 1 SEAL_GATE_GAP
  z←41+stream ChooseRank 922
∇

∇ EnsureGate k;max;min;n;prev;day
  max←⌈/GATE_INDEX ⋄ min←⌊/GATE_INDEX
  :If k>max
      :For n :In max+⍳k-max
          prev←GateGet n-1
          day←prev+GateGap n
          GatePut n day
      :EndFor
  :ElseIf k<min
      n←min-1
      :While n≥k
          prev←GateGet n+1
          day←prev-GateGap n
          GatePut n day
          n←n-1
      :EndWhile
  :EndIf
∇

∇ EnsureGatesCover bounds;low;high;min;max
  low←bounds[1] ⋄ high←bounds[2]
  :Repeat
      min←⌊/GATE_INDEX
      :If (GateGet min)≤low ⋄ :Leave ⋄ :EndIf
      EnsureGate min-1
  :EndRepeat
  :Repeat
      max←⌈/GATE_INDEX
      :If (GateGet max)≥high ⋄ :Leave ⋄ :EndIf
      EnsureGate max+1
  :EndRepeat
∇

∇ z←GateIndexAtOrBefore day;idx;days;order;p
  EnsureGatesCover day day
  order←⍋GATE_INDEX
  idx←GATE_INDEX[order]
  days←GATE_DAY[order]
  p←+/days≤day
  z←idx[p]
∇

∇ z←ExactGateIndex day;i
  i←GateIndexAtOrBefore day
  :If (GateGet i)=day
      z←i
  :Else
      z←0x
  :EndIf
∇

∇ z←ValidYearPair pair;i;j;length
  i←pair[1] ⋄ j←pair[2]
  :If (j-i)<6
      z←0 ⋄ :Return
  :EndIf
  length←(GateGet j)-GateGet i
  z←(YEAR_MIN_DAYS≤length)∧length≤YEAR_MAX_DAYS
∇

∇ z←SortYear5000 candidates;out;used;n;p;q;best;bestLen;bestOpen;len;open
  n←1↑⍴candidates
  out←0 4⍴0x
  used←n⍴0
  :For p :In ⍳n
      best←0 ⋄ bestLen←0x ⋄ bestOpen←0x
      :For q :In ⍳n
          :If used[q] ⋄ :Continue ⋄ :EndIf
          len←candidates[q;3] ⋄ open←candidates[q;4]
          :If (best=0)∨(len<bestLen)∨((len=bestLen)∧open<bestOpen)
              best←q ⋄ bestLen←len ⋄ bestOpen←open
          :EndIf
      :EndFor
      out←out⍪candidates[best;]
      used[best]←1
  :EndFor
  z←out
∇

∇ z←Year5000 c;low;high;indices;sortedIdx;a;b;i;j;open;close;len;candidates;r;stream;rank;chosen
  EnsureGatesCover (c-YEAR_MAX_DAYS) (c+YEAR_MAX_DAYS)
  sortedIdx←GATE_INDEX[⍋GATE_INDEX]
  candidates←0 4⍴0x
  :For a :In ⍳⍴sortedIdx
      i←sortedIdx[a]
      :For b :In a+⍳(⍴sortedIdx)-a
          j←sortedIdx[b]
          :If ~ValidYearPair i j ⋄ :Continue ⋄ :EndIf
          open←GateGet i ⋄ close←GateGet j
          :If ~((open<c)∧c≤close) ⋄ :Continue ⋄ :EndIf
          len←close-open
          candidates←candidates⍪i j len open
      :EndFor
  :EndFor
  candidates←SortYear5000 candidates
  r←c Sauce c
  stream←r AskBowl 1 SEAL_YEAR_5000
  rank←stream ChooseRank 1↑⍴candidates
  chosen←candidates[rank;]
  z←5000 chosen[1] chosen[2] (GateGet chosen[1]) (GateGet chosen[2])
∇

∇ z←SortByLength candidates;out;used;n;p;q;best;bestLen
  n←1↑⍴candidates
  out←0 2⍴0x
  used←n⍴0
  :For p :In ⍳n
      best←0 ⋄ bestLen←0x
      :For q :In ⍳n
          :If used[q] ⋄ :Continue ⋄ :EndIf
          :If (best=0)∨candidates[q;2]<bestLen
              best←q ⋄ bestLen←candidates[q;2]
          :EndIf
      :EndFor
      out←out⍪candidates[best;]
      used[best]←1
  :EndFor
  z←out
∇

∇ z←c NextYear known;openIdx;j;len;candidates;r;stream;rank;chosen
  openIdx←known[3]
  EnsureGatesCover (GateGet openIdx) ((GateGet openIdx)+YEAR_MAX_DAYS)
  candidates←0 2⍴0x
  j←openIdx+1
  :Repeat
      EnsureGate j
      len←(GateGet j)-GateGet openIdx
      :If len>YEAR_MAX_DAYS ⋄ :Leave ⋄ :EndIf
      :If ValidYearPair openIdx j
          candidates←candidates⍪j len
      :EndIf
      j←j+1
  :EndRepeat
  candidates←SortByLength candidates
  r←c Sauce GateGet openIdx
  stream←r AskBowl 1 SEAL_NEXT_YEAR
  rank←stream ChooseRank 1↑⍴candidates
  chosen←candidates[rank;1]
  z←(known[1]+1) openIdx chosen (GateGet openIdx) (GateGet chosen)
∇

∇ z←c PreviousYear known;closeIdx;i;len;candidates;r;stream;rank;chosen
  closeIdx←known[2]
  EnsureGatesCover ((GateGet closeIdx)-YEAR_MAX_DAYS) (GateGet closeIdx)
  candidates←0 2⍴0x
  i←closeIdx-1
  :Repeat
      EnsureGate i
      len←(GateGet closeIdx)-GateGet i
      :If len>YEAR_MAX_DAYS ⋄ :Leave ⋄ :EndIf
      :If ValidYearPair i closeIdx
          candidates←candidates⍪i len
      :EndIf
      i←i-1
  :EndRepeat
  candidates←SortByLength candidates
  r←c Sauce GateGet closeIdx
  stream←r AskBowl 1 SEAL_PREVIOUS_YEAR
  rank←stream ChooseRank 1↑⍴candidates
  chosen←candidates[rank;1]
  z←(known[1]-1) chosen closeIdx (GateGet chosen) (GateGet closeIdx)
∇

∇ z←c FindTargetYear t;y
  y←Year5000 c
  :While t>y[5]
      y←c NextYear y
  :EndWhile
  :While t≤y[4]
      y←c PreviousYear y
  :EndWhile
  z←y
∇

⍝ Die folgenden DP-Helfer arbeiten auf canonicalIndex und exakten rationalen Ganzzahlen.

∇ CutletMemoReset
  CP_KEYS←0 4⍴0
  CP_VALUES←0⍴0x
  CP_REQUIRED←0
∇

∇ z←CutletCountState state;rem;slots;cum;hit;key;p;total;maxx;x;nextcum;nexthit
  rem←state[1] ⋄ slots←state[2] ⋄ cum←state[3] ⋄ hit←state[4]
  :If slots=0
      z←(rem=0)∧((CP_REQUIRED=0)∨hit) ⋄ :Return
  :EndIf
  :If rem<slots
      z←0x ⋄ :Return
  :EndIf
  :For p :In ⍳1↑⍴CP_KEYS
      :If ∧/CP_KEYS[p;]=state
          z←CP_VALUES[p] ⋄ :Return
      :EndIf
  :EndFor
  total←0x
  maxx←rem-(slots-1)
  :For x :In ⍳maxx
      nextcum←cum+x ⋄ nexthit←hit
      :If (CP_REQUIRED≠0)∧~hit
          :If nextcum=CP_REQUIRED
              nexthit←1
          :ElseIf nextcum>CP_REQUIRED
              :Continue
          :EndIf
      :EndIf
      total←total+CutletCountState (rem-x) (slots-1) nextcum nexthit
  :EndFor
  CP_KEYS←CP_KEYS⍪state
  CP_VALUES←CP_VALUES,total
  z←total
∇

∇ z←CutletFamilyCount args;g;k;required
  g←args[1] ⋄ k←args[2] ⋄ required←args[3]
  CutletMemoReset
  CP_REQUIRED←required
  z←CutletCountState g k 0 0
∇

∇ z←CutletFamilyUnrank args;g;k;required;rank;rem;slots;cum;hit;out;maxx;x;nextcum;nexthit;block
  g←args[1] ⋄ k←args[2] ⋄ required←args[3] ⋄ rank←args[4]
  CutletMemoReset
  CP_REQUIRED←required
  rem←g ⋄ slots←k ⋄ cum←0 ⋄ hit←0 ⋄ out←⍬
  :While slots>0
      maxx←rem-(slots-1)
      :For x :In ⍳maxx
          nextcum←cum+x ⋄ nexthit←hit
          :If (required≠0)∧~hit
              :If nextcum=required
                  nexthit←1
              :ElseIf nextcum>required
                  :Continue
              :EndIf
          :EndIf
          block←CutletCountState (rem-x) (slots-1) nextcum nexthit
          :If rank>block
              rank←rank-block
          :Else
              out←out,x
              rem←rem-x ⋄ slots←slots-1 ⋄ cum←nextcum ⋄ hit←nexthit
              :Leave
          :EndIf
      :EndFor
  :EndWhile
  z←out
∇

∇ WeaveMemoReset lengths
  WEAVE_LENGTHS←lengths
  WEAVE_KEYS←⍬
  WEAVE_VALUES←0⍴0x
∇

∇ z←StateRemaining state
  z←⊃state[1]
∇

∇ z←state WeaveLegal j;remaining;opened;closed;already;willClose
  remaining←StateRemaining state
  opened←state[2] ⋄ closed←state[3]
  :If remaining[j]=0
      z←0 ⋄ :Return
  :EndIf
  already←remaining[j]<WEAVE_LENGTHS[j]
  :If (~already)∧j≠opened+1
      z←0 ⋄ :Return
  :EndIf
  willClose←remaining[j]=1
  :If willClose∧j≠closed+1
      z←0 ⋄ :Return
  :EndIf
  z←1
∇

∇ z←state WeaveApply j;remaining;opened;closed
  remaining←StateRemaining state
  opened←state[2] ⋄ closed←state[3]
  :If remaining[j]=WEAVE_LENGTHS[j]
      opened←j
  :EndIf
  remaining[j]←remaining[j]-1
  :If remaining[j]=0
      closed←j
  :EndIf
  z←(⊂remaining),opened,closed
∇

∇ z←WeaveCountState state;i;total;j;next
  :If 0=+/StateRemaining state
      z←1x ⋄ :Return
  :EndIf
  :For i :In ⍳⍴WEAVE_KEYS
      :If state≡⊃WEAVE_KEYS[i]
          z←WEAVE_VALUES[i] ⋄ :Return
      :EndIf
  :EndFor
  total←0x
  :For j :In ⍳⍴WEAVE_LENGTHS
      :If state WeaveLegal j
          next←state WeaveApply j
          total←total+WeaveCountState next
      :EndIf
  :EndFor
  WEAVE_KEYS←WEAVE_KEYS,⊂state
  WEAVE_VALUES←WEAVE_VALUES,total
  z←total
∇

∇ z←WeavingCount lengths;state
  WeaveMemoReset lengths
  state←(⊂lengths),0,0
  z←WeaveCountState state
∇

∇ z←WeavingUnrank args;lengths;rank;state;out;j;next;block;total
  lengths←⊃args[1] ⋄ rank←args[2]
  WeaveMemoReset lengths
  state←(⊂lengths),0,0
  out←⍬ ⋄ total←+/lengths
  :While (⍴out)<total
      :For j :In ⍳⍴lengths
          :If ~state WeaveLegal j ⋄ :Continue ⋄ :EndIf
          next←state WeaveApply j
          block←WeaveCountState next
          :If rank>block
              rank←rank-block
          :Else
              out←out,j
              state←next
              :Leave
          :EndIf
      :EndFor
  :EndWhile
  z←out
∇

⍝ Jahresstruktur und endgültige Fünferausgabe. Namen bleiben bis zur Präsentation canonicalIndex.

∇ z←sauce ChooseCutletCount year;gaps;candidates;k;stream;rank
  gaps←year[3]-year[2]
  candidates←⍬
  :For k :In 6-1+⍳12
      :If k≤gaps
          candidates←candidates,k
      :EndIf
  :EndFor
  stream←sauce AskBowl 2 SEAL_CUTLET_COUNT
  rank←stream ChooseRank ⍴candidates
  z←candidates[rank]
∇

∇ z←ChooseCutletPartition args;c;year;sauce;k;g;required;familyCount;stream;rank
  c←⊃args[1] ⋄ year←⊃args[2] ⋄ sauce←⊃args[3] ⋄ k←args[4]
  g←ExactGateIndex c
  required←0
  :If (g≠0)∧(year[2]<g)∧g<year[3]
      required←g-year[2]
  :EndIf
  familyCount←CutletFamilyCount (year[3]-year[2]) k required
  stream←sauce AskBowl 2 SEAL_CUTLET_PARTITION
  rank←stream ChooseRank familyCount
  z←CutletFamilyUnrank (year[3]-year[2]) k required rank
∇

∇ z←sauce ChooseCutletNames k;n;stream;rank
  n←FallingFactorial 17 k
  stream←sauce AskBowl 5 SEAL_CUTLET_NAMES
  rank←stream ChooseRank n
  z←17 UnrankDistinct k rank
∇

∇ z←MaterializeCutlets args;year;partition;k;rows;cursor;i;open;close
  year←⊃args[1] ⋄ partition←⊃args[2]
  k←⍴partition
  rows←k 4⍴0x
  cursor←year[2]
  :For i :In ⍳k
      open←cursor
      close←cursor+partition[i]
      rows[i;]←open close ((GateGet open)+1) (GateGet close)
      cursor←close
  :EndFor
  z←rows
∇

∇ z←sauce ChooseMonthCount year;length;lo;hi;count;stream;rank
  length←year[5]-year[4]
  lo←CeilDiv length 123
  hi←47⌊⌊length÷4
  count←hi-lo+1
  stream←sauce AskBowl 3 SEAL_MONTH_COUNT
  rank←stream ChooseRank count
  z←lo+rank-1
∇

∇ z←ChooseMonthLengths args;sauce;year;k;length;n;stream;rank
  sauce←⊃args[1] ⋄ year←⊃args[2] ⋄ k←args[3]
  length←year[5]-year[4]
  n←BoundedCount length k 4 123
  stream←sauce AskBowl 3 SEAL_MONTH_LENGTHS
  rank←stream ChooseRank n
  z←BoundedUnrank length k 4 123 rank
∇

∇ z←sauce ChooseMonthWeaving lengths;n;stream;rank
  n←WeavingCount lengths
  stream←sauce AskBowl 4 SEAL_MONTH_WEAVING
  rank←stream ChooseRank n
  z←WeavingUnrank (⊂lengths) rank
∇

∇ z←sauce ChooseMonthNames k;n;stream;rank
  n←FallingFactorial 47 k
  stream←sauce AskBowl 5 SEAL_MONTH_NAMES
  rank←stream ChooseRank n
  z←47 UnrankDistinct k rank
∇

∇ z←BuildYearStructure args;c;year;first;sauce;k;partition;cutletNameIdx;cutlets;m;monthLengths;weave;monthNameIdx
  c←⊃args[1] ⋄ year←⊃args[2]
  first←year[4]+1
  sauce←c Sauce first
  k←sauce ChooseCutletCount year
  partition←ChooseCutletPartition (⊂c),(⊂year),(⊂sauce),k
  cutletNameIdx←sauce ChooseCutletNames k
  cutlets←MaterializeCutlets (⊂year),(⊂partition)
  m←sauce ChooseMonthCount year
  monthLengths←ChooseMonthLengths (⊂sauce),(⊂year),m
  weave←sauce ChooseMonthWeaving monthLengths
  monthNameIdx←sauce ChooseMonthNames m
  z←(⊂year),(⊂partition),(⊂cutletNameIdx),(⊂cutlets),(⊂monthLengths),(⊂weave),(⊂monthNameIdx)
∇

∇ z←c CalendarDate t;year;structure;cutletNameIdx;cutlets;weave;monthNameIdx;i;cutletId;dayInCutlet;offset;monthId;dayInMonth;p
  year←c FindTargetYear t
  structure←BuildYearStructure (⊂c),(⊂year)
  cutletNameIdx←⊃structure[3]
  cutlets←⊃structure[4]
  weave←⊃structure[6]
  monthNameIdx←⊃structure[7]
  cutletId←0
  :For i :In ⍳1↑⍴cutlets
      :If (cutlets[i;3]≤t)∧t≤cutlets[i;4]
          cutletId←i
          :Leave
      :EndIf
  :EndFor
  :If cutletId=0
      ⎕←'FEHLER: Kein Schnitzel enthält den Zieltageswert.'
      ⎕SIGNAL 11
  :EndIf
  dayInCutlet←t-cutlets[cutletId;3]+1
  offset←t-(year[4]+1)
  monthId←weave[offset+1]
  dayInMonth←0
  :For p :In ⍳offset+1
      :If weave[p]=monthId
          dayInMonth←dayInMonth+1
      :EndIf
  :EndFor
  z←(⊂year[1]),(⊂CutletNameByIndex cutletNameIdx[cutletId]),(⊂dayInCutlet),(⊂MonthNameByIndex monthNameIdx[monthId]),(⊂dayInMonth)
∇
