load 'src/source_language_catalog.ijs'

NB. Referință normativă curată, numai pentru teste.
NB. Acest fișier nu este încărcat de codul de producție.
NB. Toți indicii de tablouri J sunt zero-based; ID-urile normative rămân one-based.

TABLETS_DAY=: _278522x
FOUNDATION_DAY=: _15055671x
M=: <: 2x ^ 127

GATE_GAP_MIN=: 42x
GATE_GAP_MAX=: 963x
YEAR_MIN_DAYS=: 252x
YEAR_MAX_DAYS=: 5778x
MIN_CUTLETS=: 6
MAX_CUTLETS=: 17
MIN_MONTHS=: 3
MAX_MONTHS=: 47
MIN_MONTH_DAYS=: 4
MAX_MONTH_DAYS=: 123

SEAL_GATE_GAP=: 1x
SEAL_YEAR_5000=: 10x
SEAL_NEXT_YEAR=: 11x
SEAL_PREVIOUS_YEAR=: 12x
SEAL_CUTLET_COUNT=: 20x
SEAL_CUTLET_PARTITION=: 21x
SEAL_CUTLET_NAMES=: 22x
SEAL_MONTH_COUNT=: 30x
SEAL_MONTH_LENGTHS=: 31x
SEAL_MONTH_WEAVING=: 32x
SEAL_MONTH_NAMES=: 33x

WHEAT=: 0
BARLEY=: 1
SALT=: 2
BITTER=: 3
RED=: 4

nr_floorDiv=: 4 : 0
  x <.@% y
)

nr_regularMod=: 4 : 0
  x - y * (x nr_floorDiv y)
)

nr_save=: 3 : 0
  1x + ((y - 1x) nr_regularMod M)
)

nr_ceilDiv=: 4 : 0
  ((x + y - 1x) nr_floorDiv y)
)

nr_wrap1=: 4 : 0
  1 + ((x - 1) nr_regularMod y)
)

nr_dayCount=: 3 : 0
  if. y = FOUNDATION_DAY do.
    1x return.
  end.
  if. y > FOUNDATION_DAY do.
    1x + 2x * (y - FOUNDATION_DAY) return.
  end.
  2x * (FOUNDATION_DAY - y)
)

nr_workCounts=: 4 : 0
  cDay=. x
  tDay=. y
  c=. nr_dayCount cDay
  t=. nr_dayCount tDay
  distance=. 1x + | tDay - cDay
  connection=. c + t
  direction=. 2x
  if. tDay < cDay do. direction=. 1x end.
  if. tDay > cDay do. direction=. 3x end.
  c,t,distance,connection,direction
)

nr_buildStones=: 3 : 0
  table=. 46 5 $ 0x
  table=. (17x 29x 43x 71x 101x) 0} table
  for_i. 2 + i.45 do.
    old=. (i - 2) { table
    w=. WHEAT { old
    b=. BARLEY { old
    s=. SALT { old
    m=. BITTER { old
    r=. RED { old
    nextW=. nr_save +/ (w*w),(3x*b),i
    nextB=. nr_save +/ (b*b),(5x*s),w
    nextS=. nr_save +/ (s*s),(7x*m),b
    nextM=. nr_save +/ (m*m),(11x*r),s
    nextR=. nr_save +/ (r*r),(13x*w),m
    next=. nextW,nextB,nextS,nextM,nextR
    table=. next (i - 1)} table
  end.
  table
)

STONES=: nr_buildStones ''

HIDDEN_COEFF=: 7 4 $  3 4 6 8,  5 7 10 12,  7 10 14 16,  9 13 18 20,  11 16 22 24,  13 19 26 28,  15 22 30 32

HIDDEN_GRIND_STONE=: WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY

VISIBLE_GRINDS=: 11 5 $  3 5 7 11,WHEAT,  5 7 11 13,BARLEY,  7 11 13 17,SALT,  11 13 17 19,BITTER,  13 17 19 23,RED,  17 19 23 29,WHEAT,  19 23 29 31,BARLEY,  23 29 31 37,SALT,  29 31 37 41,BITTER,  31 37 41 43,RED,  37 41 43 47,WHEAT

nr_buildHiddenDrops=: 3 : 0
  counts=. y
  hidden=. 7 $ 0x
  for_k. 1 + i.7 do.
    coeff=. (k - 1) { HIDDEN_COEFF
    a=. 0 { coeff
    b=. 1 { coeff
    c=. 2 { coeff
    d=. 3 { coeff
    stone=. (k - 1) { STONES
    value=. +/ (0{counts),(a*(1{counts)),(b*(2{counts)),(c*(3{counts)),(d*(4{counts)),(+/stone)
    value=. nr_save value
    for_g. 1 + i.7 do.
      old=. value
      kind=. (g - 1) { HIDDEN_GRIND_STONE
      value=. nr_save +/ (old*old),(3x*old),(kind{stone),g
    end.
    hidden=. value (k - 1)} hidden
  end.
  hidden
)

nr_buildVisibleDrops=: 3 : 0
  counts=. y
  hidden=. nr_buildHiddenDrops counts
  timeline=. 53 $ 0x
  for_k. 1 + i.7 do.
    timeline=. ((k - 1){hidden) (7 - k)} timeline
  end.
  for_i. 1 + i.46 do.
    p1=. ((i - 1) + 6) { timeline
    p3=. ((i - 3) + 6) { timeline
    p7=. ((i - 7) + 6) { timeline
    stone=. (i - 1) { STONES
    value=. nr_save +/ ((WHEAT{stone)*(0{counts)),((BARLEY{stone)*(1{counts)),((SALT{stone)*(2{counts)),((BITTER{stone)*(3{counts)),((RED{stone)*(4{counts)),p1,(3x*p3),(5x*p7),i
    for_g. 1 + i.11 do.
      row=. (g - 1) { VISIBLE_GRINDS
      old=. value
      a=. 0{row
      b=. 1{row
      c=. 2{row
      d=. 3{row
      kind=. 4{row
      value=. nr_save +/ (old*old),(a*old),(b*p1),(c*p3),(d*p7),(kind{stone)
    end.
    timeline=. value (i + 6)} timeline
  end.
  (7 + i.46) { timeline
)

nr_factorial=: 3 : 0
  if. y = 0 do. 1x return. end.
  */ 1x + i.y
)

nr_permutationUnrank1=: 4 : 0
  rank0=. x - 1x
  remaining=. y
  result=. 0 $ 0
  slots=. # remaining
  while. slots > 0 do.
    block=. nr_factorial slots - 1
    q=. rank0 nr_floorDiv block
    rank0=. rank0 nr_regularMod block
    qMachine=. <. q
    result=. result, qMachine { remaining
    remaining=. (qMachine {. remaining), (qMachine + 1) }. remaining
    slots=. slots - 1
  end.
  result
)

nr_bowlOrderFromNumber=: 3 : 0
  y nr_permutationUnrank1 1 2 3 4 5 6
)

nr_bowlOrderFromDrop=: 3 : 0
  orderNumber=. 1x + ((y - 1x) nr_regularMod 720x)
  nr_bowlOrderFromNumber orderNumber
)

BOWL_PRIME=: 17x 19x 23x 29x 31x 37x
BOWL_STIR_STONE_BY_POSITION=: WHEAT,BARLEY,SALT,BITTER,RED,WHEAT

nr_initialBowls=: 3 : 0
  counts=. y
  bowls=. 6 $ 0x
  for_id. 1 + i.6 do.
    prime=. (id - 1) { BOWL_PRIME
    s=. +/ (0{counts),((1{counts)*id),(2{counts),(3{counts),(4{counts),(prime*prime)
    bowls=. (nr_save +/ (s*s),id) (id - 1)} bowls
  end.
  bowls
)

nr_applyVisibleDropsToBowls=: 4 : 0
  bowls=. x
  visible=. y
  orderAt46=. 0 $ 0
  for_i. 1 + i.46 do.
    drop=. (i - 1) { visible
    order=. nr_bowlOrderFromDrop drop
    old=. bowls
    pour=. 6 $ 0x
    firstId=. 0 { order
    secondId=. 1 { order
    thirdId=. 2 { order
    stone=. (i - 1) { STONES
    pour=. (nr_save +/ (drop*drop),((WHEAT{stone)*((firstId-1){old)),(3x*i)) 0} pour
    pour=. (nr_save +/ (drop*drop),((BARLEY{stone)*((secondId-1){old)),(5x*i)) 1} pour
    pour=. (nr_save +/ (drop*drop),((SALT{stone)*((thirdId-1){old)),(7x*i)) 2} pour
    nextBowls=. 6 $ 0x
    for_position. 1 + i.6 do.
      id=. (position - 1) { order
      prevPosition=. (position - 1) nr_wrap1 6
      nextPosition=. (position + 1) nr_wrap1 6
      prevId=. (prevPosition - 1) { order
      nextId=. (nextPosition - 1) { order
      kind=. (position - 1) { BOWL_STIR_STONE_BY_POSITION
      s=. +/ ((id-1){old),(2x*((prevId-1){old)),(3x*((nextId-1){old)),((position-1){pour),drop,(kind{stone)
      value=. nr_save +/ (s*s),(5x*((prevId-1){old)*((nextId-1){old)),(i*position)
      nextBowls=. value (id - 1)} nextBowls
    end.
    bowls=. nextBowls
    if. i = 46 do. orderAt46=. order end.
  end.
  bowls;orderAt46
)

nr_postStir12=: 3 : 0
  bowls=. y
  for_stir. 1 + i.12 do.
    old=. bowls
    savedBowlSum=. nr_save +/ (+/old),(149x*stir)
    orderNumber=. 1x + ((savedBowlSum - 1x) nr_regularMod 720x)
    order=. nr_bowlOrderFromNumber orderNumber
    nextBowls=. 6 $ 0x
    for_position. 1 + i.6 do.
      id=. (position - 1) { order
      prevPosition=. (position - 1) nr_wrap1 6
      nextPosition=. (position + 1) nr_wrap1 6
      prevId=. (prevPosition - 1) { order
      nextId=. (nextPosition - 1) { order
      s=. +/ ((id-1){old),(3x*((prevId-1){old)),(5x*((nextId-1){old)),savedBowlSum,stir,(position*position)
      value=. nr_save +/ (s*s),(7x*((prevId-1){old)*((nextId-1){old))
      nextBowls=. value (id - 1)} nextBowls
    end.
    bowls=. nextBowls
  end.
  bowls
)

nr_sauce=: 4 : 0
  counts=. x nr_workCounts y
  hidden=. nr_buildHiddenDrops counts
  visible=. nr_buildVisibleDrops counts
  bowls=. nr_initialBowls counts
  pair=. bowls nr_applyVisibleDropsToBowls visible
  afterDrops=. > 0 { pair
  orderAt46=. > 1 { pair
  finalBowls=. nr_postStir12 afterDrops
  finalBowls;orderAt46
)

nr_nextBowlInDrop46Order=: 4 : 0
  sauceResult=. x
  queriedId=. y
  order=. > 1 { sauceResult
  pos=. order i. queriedId
  ((1 + pos) nr_regularMod 6) { order
)

nr_askBowl=: 3 : 0
  sauceResult=. > 0 { y
  queriedId=. > 1 { y
  seal=. > 2 { y
  bowls=. > 0 { sauceResult
  nextId=. sauceResult nr_nextBowlInDrop46Order queriedId
  firstBase=. ((queriedId-1){bowls) + seal + 181x
  first=. nr_save +/ (firstBase*firstBase),(179x*((nextId-1){bowls)),seal
  directionBase=. first + seal + 194x
  directionNumber=. nr_save +/ (directionBase*directionBase),(193x*first),(197x*(5{bowls))
  step=. _1x
  if. 1x = directionNumber nr_regularMod 2x do. step=. 1x end.
  first,step
)

nr_answerAt=: 4 : 0
  stream=. x
  k=. y
  first=. 0 { stream
  step=. 1 { stream
  1x + (((first - 1x) + step*k) nr_regularMod M)
)

nr_chooseRankShort=: 4 : 0
  stream=. x
  N=. y
  limit=. (M nr_floorDiv N) * N
  k=. 0x
  while. 1 do.
    value=. stream nr_answerAt k
    if. value <: limit do.
      1x + ((value - 1x) nr_regularMod N) return.
    end.
    k=. k + 1x
  end.
)

nr_chooseRankWide=: 4 : 0
  stream=. x
  N=. y
  places=. 1
  space=. M
  while. space < N do.
    places=. places + 1
    space=. space * M
  end.
  wide=. 1x
  weight=. 1x
  for_j. i.places do.
    digit=. (stream nr_answerAt j) - 1x
    wide=. wide + digit*weight
    weight=. weight*M
  end.
  limit=. (space nr_floorDiv N) * N
  while. wide > limit do.
    wide=. 1x + (((wide - 1x) + (1{stream)) nr_regularMod space)
  end.
  1x + ((wide - 1x) nr_regularMod N)
)

nr_chooseRank=: 4 : 0
  if. y <: M do.
    x nr_chooseRankShort y
  else.
    x nr_chooseRankWide y
  end.
)

nr_binomial=: 4 : 0
  k=. x
  n=. y
  if. (k < 0) +. k > n do. 0x return. end.
  k=. k <. n - k
  if. k = 0 do. 1x return. end.
  r=. 1x
  for_i. 1 + i.k do.
    r=. (r * ((n - k) + i)) <.@% i
  end.
  r
)

nr_fallingFactorial=: 4 : 0
  n=. x
  k=. y
  if. k = 0 do. 1x return. end.
  r=. 1x
  for_j. i.k do.
    r=. r * (n - j)
  end.
  r
)

nr_unrankDistinctIndices=: 3 : 0
  n=. > 0 { y
  k=. > 1 { y
  rank=. > 2 { y
  remaining=. 1 + i.n
  out=. 0 $ 0
  r=. rank
  for_position. 1 + i.k do.
    suffix=. k - position
    block=. ((#remaining) - 1) nr_fallingFactorial suffix
    q=. (r - 1x) nr_floorDiv block
    qMachine=. <. q
    chosen=. qMachine { remaining
    out=. out, chosen
    r=. 1x + ((r - 1x) nr_regularMod block)
    remaining=. (qMachine {. remaining), (qMachine + 1) }. remaining
  end.
  out
)

nr_positiveCompositionCount=: 4 : 0
  total=. x
  slots=. y
  if. slots = 0 do.
    (total = 0) { 0x 1x return.
  end.
  if. total < slots do. 0x return. end.
  (slots - 1) nr_binomial (total - 1)
)

nr_countCutletSuffix=: 3 : 0
  rem=. >0{y
  slots=. >1{y
  cumulative=. >2{y
  required=. >3{y
  hit=. >4{y
  if. slots = 0 do.
    if. rem ~: 0 do. 0x return. end.
    if. required = 0 do. 1x return. end.
    hit { 0x 1x return.
  end.
  if. rem < slots do. 0x return. end.
  if. (required = 0) +. hit do.
    rem nr_positiveCompositionCount slots return.
  end.
  delta=. required - cumulative
  if. delta <: 0 do. 0x return. end.
  total=. 0x
  for_rparts. 1 + i.(slots - 1) do.
    left=. delta nr_positiveCompositionCount rparts
    right=. (rem - delta) nr_positiveCompositionCount (slots - rparts)
    total=. total + left*right
  end.
  total
)

nr_cutletPartitionCount=: 3 : 0
  G=. >0{y
  K=. >1{y
  required=. >2{y
  nr_countCutletSuffix G;K;0;required;0
)

nr_unrankCutletPartition=: 3 : 0
  G=. >0{y
  K=. >1{y
  required=. >2{y
  rank=. >3{y
  rem=. G
  slots=. K
  cumulative=. 0
  hit=. 0
  r=. rank
  out=. 0$0
  while. slots > 0 do.
    maxX=. (rem - slots) + 1
    chosen=. 0
    for_value. 1 + i.maxX do.
      nextCumulative=. cumulative + value
      nextHit=. hit
      if. (required ~: 0) *. -. hit do.
        if. nextCumulative = required do.
          nextHit=. 1
        elseif. nextCumulative > required do.
          continue.
        end.
      end.
      block=. nr_countCutletSuffix (rem-value);(slots-1);nextCumulative;required;nextHit
      if. r > block do.
        r=. r - block
      else.
        chosen=. value
        rem=. rem - value
        slots=. slots - 1
        cumulative=. nextCumulative
        hit=. nextHit
        out=. out, value
        break.
      end.
    end.
    assert. chosen > 0
  end.
  out
)

nr_countBounded=: 3 : 0
  total=. >0{y
  slots=. >1{y
  lo=. >2{y
  hi=. >3{y
  shifted=. total - slots*lo
  width=. hi - lo
  if. shifted < 0 do. 0x return. end.
  if. shifted > slots*width do. 0x return. end.
  maxJ=. shifted nr_floorDiv (width + 1)
  maxJ=. slots <. maxJ
  answer=. 0x
  for_j. i.(1 + maxJ) do.
    top=. (shifted - j*(width+1)) + (slots - 1)
    term=. (j nr_binomial slots) * ((slots-1) nr_binomial top)
    if. 0 = j nr_regularMod 2 do.
      answer=. answer + term
    else.
      answer=. answer - term
    end.
  end.
  answer
)

nr_unrankBounded=: 3 : 0
  total=. >0{y
  slots=. >1{y
  lo=. >2{y
  hi=. >3{y
  rank=. >4{y
  rem=. total
  left=. slots
  r=. rank
  out=. 0$0
  while. left > 0 do.
    chosen=. _1
    for_value. lo + i.(1 + hi - lo) do.
      block=. nr_countBounded (rem-value);(left-1);lo;hi
      if. r > block do.
        r=. r - block
      else.
        chosen=. value
        out=. out,value
        rem=. rem - value
        left=. left - 1
        break.
      end.
    end.
    assert. chosen >: lo
  end.
  out
)

NB. Memoizarea țesăturii este proprietatea exclusivă a oracle-ului de test.
NR_WEAVE_LENGTHS=: 0$0
NR_WEAVE_MEMO_KEYS=: 0$a:
NR_WEAVE_MEMO_VALUES=: 0$0x

nr_weaveKey=: 3 : 0
  remaining=. >0{y
  opened=. >1{y
  closed=. >2{y
  (":opened),':', (":closed),':',":remaining
)

nr_weaveMemoReset=: 3 : 0
  NR_WEAVE_MEMO_KEYS=: 0$a:
  NR_WEAVE_MEMO_VALUES=: 0$0x
  1
)

nr_countWeavingsState=: 3 : 0
  remaining=. >0{y
  opened=. >1{y
  closed=. >2{y
  if. 0 = +/ remaining do. 1x return. end.
  key=. nr_weaveKey remaining;opened;closed
  pos=. NR_WEAVE_MEMO_KEYS i. <key
  if. pos < #NR_WEAVE_MEMO_KEYS do.
    pos { NR_WEAVE_MEMO_VALUES return.
  end.
  total=. 0x
  m=. #remaining
  for_j. 1 + i.m do.
    remj=. (j-1){remaining
    if. remj = 0 do. continue. end.
    orig=. (j-1){NR_WEAVE_LENGTHS
    alreadyOpened=. remj < orig
    if. (-. alreadyOpened) *. j ~: opened + 1 do. continue. end.
    willClose=. remj = 1
    if. willClose *. j ~: closed + 1 do. continue. end.
    nextOpened=. opened
    if. remj = orig do. nextOpened=. j end.
    nextRemaining=. (remj - 1) (j-1)} remaining
    nextClosed=. closed
    if. 0 = (j-1){nextRemaining do. nextClosed=. j end.
    total=. total + nr_countWeavingsState nextRemaining;nextOpened;nextClosed
  end.
  NR_WEAVE_MEMO_KEYS=: NR_WEAVE_MEMO_KEYS, <key
  NR_WEAVE_MEMO_VALUES=: NR_WEAVE_MEMO_VALUES, total
  total
)

nr_countWeavings=: 3 : 0
  NR_WEAVE_LENGTHS=: y
  nr_weaveMemoReset ''
  nr_countWeavingsState y;0;0
)

nr_unrankWeaving=: 4 : 0
  lengths=. x
  rank=. y
  NR_WEAVE_LENGTHS=: lengths
  nr_weaveMemoReset ''
  remaining=. lengths
  opened=. 0
  closed=. 0
  r=. rank
  out=. 0$0
  totalDays=. +/lengths
  while. #out < totalDays do.
    selected=. 0
    m=. #remaining
    for_j. 1 + i.m do.
      remj=. (j-1){remaining
      if. remj = 0 do. continue. end.
      orig=. (j-1){lengths
      alreadyOpened=. remj < orig
      if. (-. alreadyOpened) *. j ~: opened + 1 do. continue. end.
      willClose=. remj = 1
      if. willClose *. j ~: closed + 1 do. continue. end.
      nextOpened=. opened
      if. remj = orig do. nextOpened=. j end.
      nextRemaining=. (remj - 1) (j-1)} remaining
      nextClosed=. closed
      if. 0 = (j-1){nextRemaining do. nextClosed=. j end.
      block=. nr_countWeavingsState nextRemaining;nextOpened;nextClosed
      if. r > block do.
        r=. r - block
      else.
        selected=. j
        out=. out,j
        remaining=. nextRemaining
        opened=. nextOpened
        closed=. nextClosed
        break.
      end.
    end.
    assert. selected > 0
  end.
  out
)

nr_positiveGateGap=: 3 : 0
  r=. FOUNDATION_DAY nr_sauce FOUNDATION_DAY + y
  stream=. nr_askBowl r;1;SEAL_GATE_GAP
  41x + stream nr_chooseRank 922x
)

nr_negativeGateGap=: 3 : 0
  r=. FOUNDATION_DAY nr_sauce FOUNDATION_DAY - y
  stream=. nr_askBowl r;1;SEAL_GATE_GAP
  41x + stream nr_chooseRank 922x
)

NR_GATE_INDICES=: 0
NR_GATE_DAYS=: FOUNDATION_DAY
NR_MIN_GATE_INDEX=: 0
NR_MAX_GATE_INDEX=: 0

nr_resetGateCache=: 3 : 0
  NR_GATE_INDICES=: 0
  NR_GATE_DAYS=: FOUNDATION_DAY
  NR_MIN_GATE_INDEX=: 0
  NR_MAX_GATE_INDEX=: 0
  1
)

nr_ensureGateIndex=: 3 : 0
  k=. y
  if. k > NR_MAX_GATE_INDEX do.
    n=. NR_MAX_GATE_INDEX + 1
    while. n <: k do.
      p=. NR_GATE_INDICES i. n - 1
      prev=. p { NR_GATE_DAYS
      newDay=. prev + nr_positiveGateGap n
      NR_GATE_INDICES=: NR_GATE_INDICES,n
      NR_GATE_DAYS=: NR_GATE_DAYS,newDay
      NR_MAX_GATE_INDEX=: n
      n=. n + 1
    end.
  end.
  if. k < NR_MIN_GATE_INDEX do.
    n=. | NR_MIN_GATE_INDEX
    n=. n + 1
    while. n <: |k do.
      idx=. -n
      p=. NR_GATE_INDICES i. idx + 1
      prev=. p { NR_GATE_DAYS
      newDay=. prev - nr_negativeGateGap n
      NR_GATE_INDICES=: idx,NR_GATE_INDICES
      NR_GATE_DAYS=: newDay,NR_GATE_DAYS
      NR_MIN_GATE_INDEX=: idx
      n=. n + 1
    end.
  end.
  p=. NR_GATE_INDICES i. k
  p { NR_GATE_DAYS
)

nr_ensureGatesCover=: 4 : 0
  low=. x
  high=. y
  assert. low <: high
  while. 0{NR_GATE_DAYS > low do.
    nr_ensureGateIndex NR_MIN_GATE_INDEX - 1
  end.
  while. ({:NR_GATE_DAYS) < high do.
    nr_ensureGateIndex NR_MAX_GATE_INDEX + 1
  end.
  1
)

nr_gateIndexAtOrBefore=: 3 : 0
  y nr_ensureGatesCover y
  positions=. I. NR_GATE_DAYS <: y
  (>./positions) { NR_GATE_INDICES
)

nr_gateIndexAtOrAfter=: 3 : 0
  iBefore=. nr_gateIndexAtOrBefore y
  dayBefore=. nr_ensureGateIndex iBefore
  if. dayBefore = y do. iBefore return. end.
  iBefore + 1
)

nr_exactGateIndex=: 3 : 0
  iBefore=. nr_gateIndexAtOrBefore y
  dayBefore=. nr_ensureGateIndex iBefore
  if. dayBefore = y do. 1;iBefore else. 0;0 end.
)

nr_makeYear=: 3 : 0
  number=. >0{y
  openIdx=. >1{y
  closeIdx=. >2{y
  openDay=. nr_ensureGateIndex openIdx
  closeDay=. nr_ensureGateIndex closeIdx
  number,openIdx,closeIdx,openDay,closeDay
)

nr_validYearPair=: 4 : 0
  openIdx=. x
  closeIdx=. y
  if. closeIdx - openIdx < 6 do. 0 return. end.
  L=. (nr_ensureGateIndex closeIdx) - nr_ensureGateIndex openIdx
  (YEAR_MIN_DAYS <: L) *. L <: YEAR_MAX_DAYS
)

nr_year5000=: 3 : 0
  cDay=. y
  (cDay - YEAR_MAX_DAYS) nr_ensureGatesCover cDay + YEAR_MAX_DAYS
  opens=. 0$0
  closes=. 0$0
  lengths=. 0$0x
  openDays=. 0$0x
  count=. #NR_GATE_INDICES
  for_ap. i.count do.
    openIdx=. ap{NR_GATE_INDICES
    nrem=. (count - ap) - 1
    if. nrem <: 0 do. continue. end.
    for_bp. (ap + 1) + i.nrem do.
      closeIdx=. bp{NR_GATE_INDICES
      if. -. openIdx nr_validYearPair closeIdx do. continue. end.
      openDay=. ap{NR_GATE_DAYS
      closeDay=. bp{NR_GATE_DAYS
      if. -. (openDay < cDay) *. cDay <: closeDay do. continue. end.
      opens=. opens,openIdx
      closes=. closes,closeIdx
      lengths=. lengths,closeDay-openDay
      openDays=. openDays,openDay
    end.
  end.
  assert. #opens > 0
  keys=. lengths ,. openDays
  grade=. /: keys
  opens=. grade{opens
  closes=. grade{closes
  r=. cDay nr_sauce cDay
  stream=. nr_askBowl r;1;SEAL_YEAR_5000
  rank=. stream nr_chooseRank #opens
  pos=. (<.rank) - 1
  nr_makeYear 5000x;(pos{opens);pos{closes
)

nr_nextYear=: 4 : 0
  cDay=. x
  known=. y
  openIdx=. 2{known
  candidates=. 0$0
  lengths=. 0$0x
  closeIdx=. openIdx + 1
  while. 1 do.
    closeDay=. nr_ensureGateIndex closeIdx
    openDay=. nr_ensureGateIndex openIdx
    L=. closeDay - openDay
    if. L > YEAR_MAX_DAYS do. break. end.
    if. openIdx nr_validYearPair closeIdx do.
      candidates=. candidates,closeIdx
      lengths=. lengths,L
    end.
    closeIdx=. closeIdx + 1
  end.
  assert. #candidates > 0
  grade=. /: lengths
  candidates=. grade{candidates
  openDay=. nr_ensureGateIndex openIdx
  r=. cDay nr_sauce openDay
  stream=. nr_askBowl r;1;SEAL_NEXT_YEAR
  rank=. stream nr_chooseRank #candidates
  chosen=. ((<.rank)-1){candidates
  nr_makeYear ((0{known)+1x);openIdx;chosen
)

nr_previousYear=: 4 : 0
  cDay=. x
  known=. y
  closeIdx=. 1{known
  candidates=. 0$0
  lengths=. 0$0x
  openIdx=. closeIdx - 1
  while. 1 do.
    closeDay=. nr_ensureGateIndex closeIdx
    openDay=. nr_ensureGateIndex openIdx
    L=. closeDay - openDay
    if. L > YEAR_MAX_DAYS do. break. end.
    if. openIdx nr_validYearPair closeIdx do.
      candidates=. candidates,openIdx
      lengths=. lengths,L
    end.
    openIdx=. openIdx - 1
  end.
  assert. #candidates > 0
  grade=. /: lengths
  candidates=. grade{candidates
  closeDay=. nr_ensureGateIndex closeIdx
  r=. cDay nr_sauce closeDay
  stream=. nr_askBowl r;1;SEAL_PREVIOUS_YEAR
  rank=. stream nr_chooseRank #candidates
  chosen=. ((<.rank)-1){candidates
  nr_makeYear ((0{known)-1x);chosen;closeIdx
)

nr_findTargetYear=: 4 : 0
  cDay=. x
  tDay=. y
  year=. nr_year5000 cDay
  while. tDay > 4{year do.
    year=. cDay nr_nextYear year
  end.
  while. tDay <: 3{year do.
    year=. cDay nr_previousYear year
  end.
  assert. ((3{year) < tDay) *. tDay <: 4{year
  year
)

nr_chooseCutletCount=: 4 : 0
  structureSauce=. x
  year=. y
  gaps=. (2{year) - 1{year
  upper=. MAX_CUTLETS <. gaps
  candidates=. MIN_CUTLETS + i.(1 + upper - MIN_CUTLETS)
  stream=. nr_askBowl structureSauce;2;SEAL_CUTLET_COUNT
  rank=. stream nr_chooseRank #candidates
  ((<.rank)-1){candidates
)

nr_requiredCutletBoundary=: 4 : 0
  cDay=. x
  year=. y
  exact=. nr_exactGateIndex cDay
  found=. >0{exact
  if. -. found do. 0 return. end.
  g=. >1{exact
  if. (1{year) < g do.
    if. g < 2{year do.
      g - (1{year) return.
    end.
  end.
  0
)

nr_chooseCutletPartition=: 3 : 0
  cDay=. >0{y
  structureSauce=. >1{y
  year=. >2{y
  K=. >3{y
  G=. (2{year) - 1{year
  required=. cDay nr_requiredCutletBoundary year
  count=. nr_cutletPartitionCount G;K;required
  stream=. nr_askBowl structureSauce;2;SEAL_CUTLET_PARTITION
  rank=. stream nr_chooseRank count
  nr_unrankCutletPartition G;K;required;rank
)

nr_chooseCutletNames=: 4 : 0
  structureSauce=. x
  K=. y
  count=. 17 nr_fallingFactorial K
  stream=. nr_askBowl structureSauce;5;SEAL_CUTLET_NAMES
  rank=. stream nr_chooseRank count
  nr_unrankDistinctIndices 17;K;rank
)

nr_materializeCutlets=: 3 : 0
  year=. >0{y
  partition=. >1{y
  names=. >2{y
  K=. #partition
  cutlets=. K 5 $ 0x
  cursor=. 1{year
  for_k. 1 + i.K do.
    openIdx=. cursor
    closeIdx=. cursor + (k-1){partition
    firstDay=. 1x + nr_ensureGateIndex openIdx
    lastDay=. nr_ensureGateIndex closeIdx
    row=. ((k-1){names),openIdx,closeIdx,firstDay,lastDay
    cutlets=. row (k-1)} cutlets
    cursor=. closeIdx
  end.
  cutlets
)

nr_chooseMonthCount=: 4 : 0
  structureSauce=. x
  year=. y
  L=. (4{year) - 3{year
  low=. L nr_ceilDiv 123x
  high=. 47x <. L nr_floorDiv 4x
  assert. (3x <: low) *. low <: high
  count=. (high - low) + 1x
  stream=. nr_askBowl structureSauce;3;SEAL_MONTH_COUNT
  rank=. stream nr_chooseRank count
  low + (rank - 1x)
)

nr_chooseMonthLengths=: 3 : 0
  structureSauce=. >0{y
  year=. >1{y
  monthCount=. >2{y
  L=. (4{year) - 3{year
  count=. nr_countBounded L;monthCount;4;123
  stream=. nr_askBowl structureSauce;3;SEAL_MONTH_LENGTHS
  rank=. stream nr_chooseRank count
  nr_unrankBounded L;monthCount;4;123;rank
)

nr_chooseMonthWeaving=: 4 : 0
  structureSauce=. x
  lengths=. y
  count=. nr_countWeavings lengths
  stream=. nr_askBowl structureSauce;4;SEAL_MONTH_WEAVING
  rank=. stream nr_chooseRank count
  lengths nr_unrankWeaving rank
)

nr_chooseMonthNames=: 4 : 0
  structureSauce=. x
  K=. y
  count=. 47 nr_fallingFactorial K
  stream=. nr_askBowl structureSauce;5;SEAL_MONTH_NAMES
  rank=. stream nr_chooseRank count
  nr_unrankDistinctIndices 47;K;rank
)

nr_buildYearStructure=: 4 : 0
  cDay=. x
  year=. y
  firstDay=. 1x + (3{year)
  structureSauce=. cDay nr_sauce firstDay
  cutletCount=. structureSauce nr_chooseCutletCount year
  partition=. nr_chooseCutletPartition cDay;structureSauce;year;cutletCount
  cutletNames=. structureSauce nr_chooseCutletNames cutletCount
  cutlets=. nr_materializeCutlets year;partition;cutletNames
  monthCount=. structureSauce nr_chooseMonthCount year
  monthLengths=. nr_chooseMonthLengths structureSauce;year;monthCount
  weaving=. structureSauce nr_chooseMonthWeaving monthLengths
  monthNames=. structureSauce nr_chooseMonthNames monthCount
  cutletCount;partition;cutletNames;cutlets;monthCount;monthLengths;weaving;monthNames
)

nr_calendarDate=: 4 : 0
  cDay=. x
  tDay=. y
  year=. cDay nr_findTargetYear tDay
  structure=. cDay nr_buildYearStructure year
  cutlets=. >3{structure
  chosen=. _1
  for_k. 1 + i.#cutlets do.
    row=. (k-1){cutlets
    if. (3{row) <: tDay do.
      if. tDay <: 4{row do.
        chosen=. k
        break.
      end.
    end.
  end.
  assert. chosen > 0
  row=. (chosen-1){cutlets
  cutletCanonical=. 0{row
  dayInCutlet=. (tDay - (3{row)) + 1x
  weaving=. >6{structure
  monthNames=. >7{structure
  offset=. tDay - ((3{year) + 1x)
  monthId=. (<.offset){weaving
  monthCanonical=. (monthId-1){monthNames
  prefix=. (1 + <.offset) {. weaving
  dayInMonth=. +/ monthId = prefix
  cutletName=. cutletNameFromCanonicalIndex <.cutletCanonical
  monthName=. monthNameFromCanonicalIndex <.monthCanonical
  (0{year);cutletName;dayInCutlet;monthName;dayInMonth
)
