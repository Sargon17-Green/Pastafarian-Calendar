import std/[algorithm, options, tables, strutils]
import ../src/[exact_bigint, source_language_catalog]

const
  TabletsDayInt* = -278522
  FoundationDayInt* = -15055671
  GateGapMin* = 42
  GateGapMax* = 963
  YearMinDays* = 252
  YearMaxDays* = 5778
  MinGateGapsPerYear* = 6
  MinCutlets* = 6
  MaxCutlets* = 17
  MinMonths* = 3
  MaxMonths* = 47
  MinMonthDays* = 4
  MaxMonthDays* = 123

  SealGateGap = 1
  SealYear5000 = 10
  SealNextYear = 11
  SealPreviousYear = 12
  SealCutletCount = 20
  SealCutletPartition = 21
  SealCutletNames = 22
  SealMonthCount = 30
  SealMonthLengths = 31
  SealMonthWeaving = 32
  SealMonthNames = 33

  Wheat = 1
  Barley = 2
  Salt = 3
  Bitter = 4
  Red = 5

let
  M* = pow2BigInt(127) - 1
  FoundationDay* = initBigInt(FoundationDayInt)
  TabletsDay* = initBigInt(TabletsDayInt)

type
  WorkCounts* = object
    action*: BigInt
    target*: BigInt
    distance*: BigInt
    connection*: BigInt
    direction*: int

  Stone* = array[1..5, BigInt]
  StoneTable* = array[1..46, Stone]
  HiddenDrops* = array[1..7, BigInt]
  VisibleDrops* = array[1..46, BigInt]
  Bowls* = array[1..6, BigInt]
  BowlOrder* = array[1..6, int]

  SauceResult* = object
    bowls*: Bowls
    orderAtDrop46*: BowlOrder

  AnswerStream* = object
    first*: BigInt
    directionStep*: int

  Year* = object
    number*: int64
    openGateIndex*: int
    closeGateIndex*: int
    openGateDay*: BigInt
    closeGateDay*: BigInt

  Cutlet* = object
    nameCanonicalIndex*: int
    openGateIndex*: int
    closeGateIndex*: int
    firstDay*: BigInt
    lastDay*: BigInt

  YearStructure* = object
    cutletCount*: int
    cutletPartition*: seq[int]
    cutletNameIndices*: seq[int]
    cutlets*: seq[Cutlet]
    monthCount*: int
    monthLengths*: seq[int]
    monthWeaving*: seq[int]
    monthNameIndices*: seq[int]

  CalendarDateCanonical* = object
    yearNumber*: int64
    cutletCanonicalIndex*: int
    dayInCutlet*: BigInt
    monthCanonicalIndex*: int
    dayInMonth*: BigInt

  CalendarDatePresented* = object
    yearNumber*: int64
    cutletName*: string
    dayInCutlet*: BigInt
    monthName*: string
    dayInMonth*: BigInt

  GateCache* = ref object
    gates*: Table[int, BigInt]
    minKnownGateIndex*: int
    maxKnownGateIndex*: int

  NormativeOracle* = ref object
    stones*: StoneTable
    gateCache*: GateCache

  GrindRow = tuple[a, b, c, d, kind: int]

  BoundedCompositionCounter* = ref object
    total*: int
    slots*: int
    lo*: int
    hi*: int
    memo*: Table[(int, int), BigInt]

  CutletPartitionCounter* = ref object
    total*: int
    slots*: int
    requiredBoundary*: Option[int]
    memo*: Table[(int, int, int, bool), BigInt]

  WeaveState* = object
    remaining*: seq[int]
    openedUpTo*: int
    closedUpTo*: int

  WeavingCounter* = ref object
    lengths*: seq[int]
    memo*: Table[string, BigInt]

const
  HiddenCoeff: array[7, array[4, int]] = [
    [3, 4, 6, 8],
    [5, 7, 10, 12],
    [7, 10, 14, 16],
    [9, 13, 18, 20],
    [11, 16, 22, 24],
    [13, 19, 26, 28],
    [15, 22, 30, 32]
  ]

  HiddenGrindStone: array[7, int] = [Wheat, Barley, Salt, Bitter, Red, Wheat, Barley]

  VisibleGrinds: array[11, GrindRow] = [
    (3, 5, 7, 11, Wheat),
    (5, 7, 11, 13, Barley),
    (7, 11, 13, 17, Salt),
    (11, 13, 17, 19, Bitter),
    (13, 17, 19, 23, Red),
    (17, 19, 23, 29, Wheat),
    (19, 23, 29, 31, Barley),
    (23, 29, 31, 37, Salt),
    (29, 31, 37, 41, Bitter),
    (31, 37, 41, 43, Red),
    (37, 41, 43, 47, Wheat)
  ]

  BowlPrime: array[1..6, int] = [17, 19, 23, 29, 31, 37]
  BowlStirStoneByPosition: array[1..6, int] = [Wheat, Barley, Salt, Bitter, Red, Wheat]

proc save*(x: BigInt): BigInt =
  1 + regularMod(x - 1, M)

proc square(x: BigInt): BigInt = x * x

proc ceilDivInt(a, b: int): int =
  if a < 0 or b < 1:
    raise newException(ValueError, "E_CEILDIV_DOMAIN")
  (a + b - 1) div b

proc wrap1(position, size: int): int =
  if size < 1:
    raise newException(ValueError, "E_WRAP_SIZE")
  ((position - 1) mod size + size) mod size + 1

proc dayCount*(day: BigInt): BigInt =
  if day == FoundationDay:
    return initBigInt(1)
  if day > FoundationDay:
    return 2 * (day - FoundationDay) + 1
  2 * (FoundationDay - day)

proc workCounts*(calculationDay, targetDay: BigInt): WorkCounts =
  result.action = dayCount(calculationDay)
  result.target = dayCount(targetDay)
  result.distance = absDiff(targetDay, calculationDay) + 1
  result.connection = result.action + result.target
  if targetDay < calculationDay:
    result.direction = 1
  elif targetDay == calculationDay:
    result.direction = 2
  else:
    result.direction = 3

proc buildStones*(): StoneTable =
  result[1] = [
    initBigInt(17), initBigInt(29), initBigInt(43), initBigInt(71), initBigInt(101)
  ]
  for i in 2..46:
    let old = result[i - 1]
    var next: Stone
    next[Wheat] = save(square(old[Wheat]) + 3 * old[Barley] + i)
    next[Barley] = save(square(old[Barley]) + 5 * old[Salt] + old[Wheat])
    next[Salt] = save(square(old[Salt]) + 7 * old[Bitter] + old[Barley])
    next[Bitter] = save(square(old[Bitter]) + 11 * old[Red] + old[Salt])
    next[Red] = save(square(old[Red]) + 13 * old[Wheat] + old[Bitter])
    result[i] = next

proc buildHiddenDrops*(counts: WorkCounts, stones: StoneTable): HiddenDrops =
  for k in 1..7:
    let coeff = HiddenCoeff[k - 1]
    var x = counts.action +
            coeff[0] * counts.target +
            coeff[1] * counts.distance +
            coeff[2] * counts.connection +
            coeff[3] * counts.direction +
            stones[k][Wheat] + stones[k][Barley] + stones[k][Salt] +
            stones[k][Bitter] + stones[k][Red]
    x = save(x)
    for grind in 1..7:
      let oldX = x
      x = save(square(oldX) + 3 * oldX + stones[k][HiddenGrindStone[grind - 1]] + grind)
    result[k] = x

proc buildVisibleDrops*(counts: WorkCounts, stones: StoneTable, hidden: HiddenDrops): VisibleDrops =
  var timeline: array[-6..46, BigInt]
  for k in 1..7:
    timeline[1 - k] = hidden[k]
  for i in 1..46:
    let prev1 = timeline[i - 1]
    let prev3 = timeline[i - 3]
    let prev7 = timeline[i - 7]
    var x = save(
      stones[i][Wheat] * counts.action +
      stones[i][Barley] * counts.target +
      stones[i][Salt] * counts.distance +
      stones[i][Bitter] * counts.connection +
      stones[i][Red] * counts.direction +
      prev1 + 3 * prev3 + 5 * prev7 + i
    )
    for grind in 1..11:
      let oldX = x
      let row = VisibleGrinds[grind - 1]
      x = save(
        square(oldX) + row.a * oldX + row.b * prev1 + row.c * prev3 +
        row.d * prev7 + stones[i][row.kind]
      )
    timeline[i] = x
    result[i] = x

proc removeAt[T](values: var seq[T], index: int) =
  if index < 0 or index >= values.len:
    raise newException(IndexDefect, "E_REMOVE_INDEX")
  var i = index
  while i + 1 < values.len:
    values[i] = values[i + 1]
    inc i
  values.setLen(values.len - 1)

proc factorialInt(n: int): int =
  if n < 0:
    raise newException(ValueError, "E_FACTORIAL_DOMAIN")
  result = 1
  for i in 2..n:
    result *= i

proc permutationUnrank1*(rank1: int): BowlOrder =
  if rank1 < 1 or rank1 > 720:
    raise newException(ValueError, "E_PERMUTATION_RANK")
  var rank0 = rank1 - 1
  var remaining = @[1, 2, 3, 4, 5, 6]
  var outPos = 1
  for slotsLeft in countdown(remaining.len, 1):
    let block = factorialInt(slotsLeft - 1)
    let q = rank0 div block
    rank0 = rank0 mod block
    result[outPos] = remaining[q]
    removeAt(remaining, q)
    inc outPos

proc bowlOrderFromDrop*(dropValue: BigInt): BowlOrder =
  let orderNumber = (regularMod(dropValue - 1, 720) + 1).toInt()
  permutationUnrank1(orderNumber)

proc initialBowls*(counts: WorkCounts): Bowls =
  for bowlId in 1..6:
    let s = counts.action + counts.target * bowlId + counts.distance +
            counts.connection + counts.direction + BowlPrime[bowlId] * BowlPrime[bowlId]
    result[bowlId] = save(square(s) + bowlId)

proc applyVisibleDropsToBowls*(bowlsIn: Bowls, visible: VisibleDrops, stones: StoneTable): tuple[bowls: Bowls, orderAtDrop46: BowlOrder] =
  var bowls = bowlsIn
  var latched: BowlOrder
  for i in 1..46:
    let drop = visible[i]
    let order = bowlOrderFromDrop(drop)
    let old = bowls
    var pour: array[1..6, BigInt]
    pour[1] = save(square(drop) + stones[i][Wheat] * old[order[1]] + 3 * i)
    pour[2] = save(square(drop) + stones[i][Barley] * old[order[2]] + 5 * i)
    pour[3] = save(square(drop) + stones[i][Salt] * old[order[3]] + 7 * i)
    pour[4] = zeroBigInt()
    pour[5] = zeroBigInt()
    pour[6] = zeroBigInt()
    var nextBowls: Bowls
    for position in 1..6:
      let bowlId = order[position]
      let prevId = order[wrap1(position - 1, 6)]
      let nextId = order[wrap1(position + 1, 6)]
      let stoneKind = BowlStirStoneByPosition[position]
      let s = old[bowlId] + 2 * old[prevId] + 3 * old[nextId] + pour[position] +
              drop + stones[i][stoneKind]
      nextBowls[bowlId] = save(square(s) + 5 * old[prevId] * old[nextId] + i * position)
    bowls = nextBowls
    if i == 46:
      latched = order
  (bowls, latched)

proc postStir12*(bowlsIn: Bowls): Bowls =
  var bowls = bowlsIn
  for stir in 1..12:
    let old = bowls
    let savedBowlSum = save(
      old[1] + old[2] + old[3] + old[4] + old[5] + old[6] + 149 * stir
    )
    let orderNumber = (regularMod(savedBowlSum - 1, 720) + 1).toInt()
    let order = permutationUnrank1(orderNumber)
    var nextBowls: Bowls
    for position in 1..6:
      let bowlId = order[position]
      let prevId = order[wrap1(position - 1, 6)]
      let nextId = order[wrap1(position + 1, 6)]
      let s = old[bowlId] + 3 * old[prevId] + 5 * old[nextId] +
              savedBowlSum + stir + position * position
      nextBowls[bowlId] = save(square(s) + 7 * old[prevId] * old[nextId])
    bowls = nextBowls
  bowls

proc sauce*(oracle: NormativeOracle, calculationDay, targetDay: BigInt): SauceResult =
  let counts = workCounts(calculationDay, targetDay)
  let hidden = buildHiddenDrops(counts, oracle.stones)
  let visible = buildVisibleDrops(counts, oracle.stones, hidden)
  let bowls = initialBowls(counts)
  let afterDrops = applyVisibleDropsToBowls(bowls, visible, oracle.stones)
  result.bowls = postStir12(afterDrops.bowls)
  result.orderAtDrop46 = afterDrops.orderAtDrop46

proc nextBowlInDrop46Order*(sauceResult: SauceResult, queriedBowlId: int): int =
  if queriedBowlId < 1 or queriedBowlId > 6:
    raise newException(ValueError, "E_QUERY_BOWL")
  var pos = 0
  for i in 1..6:
    if sauceResult.orderAtDrop46[i] == queriedBowlId:
      pos = i
      break
  if pos == 0:
    raise newException(ValueError, "E_QUERY_ORDER")
  sauceResult.orderAtDrop46[wrap1(pos + 1, 6)]

proc askBowl*(sauceResult: SauceResult, queriedBowlId, seal: int): AnswerStream =
  let nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId)
  result.first = save(
    square(sauceResult.bowls[queriedBowlId] + seal + 181) +
    179 * sauceResult.bowls[nextId] + seal
  )
  let directionNumber = save(
    square(result.first + seal + 1 + 193) + 193 * result.first + 197 * sauceResult.bowls[6]
  )
  if regularMod(directionNumber, 2).toInt() == 1:
    result.directionStep = 1
  else:
    result.directionStep = -1

proc answerAt*(stream: AnswerStream, k: int): BigInt =
  if k < 0:
    raise newException(ValueError, "E_ANSWER_OFFSET")
  1 + regularMod(stream.first - 1 + stream.directionStep * k, M)

proc chooseRankShort*(stream: AnswerStream, n: BigInt): BigInt =
  if n < 1 or n > M:
    raise newException(ValueError, "E_SHORT_PICK_DOMAIN")
  let acceptanceLimit = floorDiv(M, n) * n
  var k = 0
  while true:
    let x = answerAt(stream, k)
    if x <= acceptanceLimit:
      return regularMod(x - 1, n) + 1
    inc k

proc smallestPowerCount(base, n: BigInt): tuple[k: int, space: BigInt] =
  var k = 1
  var space = base
  while space < n:
    inc k
    space = space * base
  (k, space)

proc chooseRankWide*(stream: AnswerStream, n: BigInt): BigInt =
  if n <= M:
    raise newException(ValueError, "E_WIDE_PICK_DOMAIN")
  let power = smallestPowerCount(M, n)
  var wide = oneBigInt()
  var weight = oneBigInt()
  for j in 0..<power.k:
    let digit = answerAt(stream, j) - 1
    wide = wide + digit * weight
    weight = weight * M
  let acceptanceLimit = floorDiv(power.space, n) * n
  while wide > acceptanceLimit:
    wide = 1 + regularMod(wide - 1 + stream.directionStep, power.space)
  regularMod(wide - 1, n) + 1

proc chooseRank*(stream: AnswerStream, n: BigInt): BigInt =
  if n < 1:
    raise newException(ValueError, "E_PICK_DOMAIN")
  if n <= M:
    chooseRankShort(stream, n)
  else:
    chooseRankWide(stream, n)

proc fallingFactorial*(n, k: int): BigInt =
  if n < 0 or k < 0 or k > n:
    raise newException(ValueError, "E_FALLING_FACTORIAL_DOMAIN")
  result = oneBigInt()
  for j in 0..<k:
    result = result * (n - j)

proc unrankDistinctIndices*(masterCount, k: int, rank1: BigInt): seq[int] =
  if masterCount < 0 or k < 0 or k > masterCount:
    raise newException(ValueError, "E_DISTINCT_UNRANK_DOMAIN")
  let total = fallingFactorial(masterCount, k)
  if rank1 < 1 or rank1 > total:
    raise newException(ValueError, "E_DISTINCT_UNRANK_RANK")
  var remaining = newSeq[int](masterCount)
  for i in 0..<masterCount:
    remaining[i] = i + 1
  var r = rank1
  result = @[]
  for position in 1..k:
    let suffixLength = k - position
    let block = fallingFactorial(remaining.len - 1, suffixLength)
    var chosen = -1
    for candidatePos in 0..<remaining.len:
      if r > block:
        r = r - block
      else:
        chosen = candidatePos
        break
    if chosen < 0:
      raise newException(ValueError, "E_DISTINCT_UNRANK_INTERNAL")
    result.add(remaining[chosen])
    removeAt(remaining, chosen)

proc newBoundedCompositionCounter*(total, slots, lo, hi: int): BoundedCompositionCounter =
  BoundedCompositionCounter(
    total: total,
    slots: slots,
    lo: lo,
    hi: hi,
    memo: initTable[(int, int), BigInt]()
  )

proc countSuffix*(counter: BoundedCompositionCounter, rem, slots: int): BigInt =
  if slots == 0:
    return if rem == 0: oneBigInt() else: zeroBigInt()
  if rem < slots * counter.lo or rem > slots * counter.hi:
    return zeroBigInt()
  let key = (rem, slots)
  if counter.memo.hasKey(key):
    return counter.memo[key]
  var total = zeroBigInt()
  for x in counter.lo..counter.hi:
    total = total + counter.countSuffix(rem - x, slots - 1)
  counter.memo[key] = total
  total

proc countAll*(counter: BoundedCompositionCounter): BigInt =
  counter.countSuffix(counter.total, counter.slots)

proc unrank1*(counter: BoundedCompositionCounter, rank1: BigInt): seq[int] =
  let totalCount = counter.countAll()
  if rank1 < 1 or rank1 > totalCount:
    raise newException(ValueError, "E_BOUNDED_UNRANK_RANK")
  var r = rank1
  var rem = counter.total
  var slots = counter.slots
  result = @[]
  while slots > 0:
    var selected = false
    for x in counter.lo..counter.hi:
      let block = counter.countSuffix(rem - x, slots - 1)
      if r > block:
        r = r - block
      else:
        result.add(x)
        rem -= x
        dec slots
        selected = true
        break
    if not selected:
      raise newException(ValueError, "E_BOUNDED_UNRANK_INTERNAL")

proc newCutletPartitionCounter*(total, slots: int, requiredBoundary: Option[int]): CutletPartitionCounter =
  CutletPartitionCounter(
    total: total,
    slots: slots,
    requiredBoundary: requiredBoundary,
    memo: initTable[(int, int, int, bool), BigInt]()
  )

proc countCutletState(counter: CutletPartitionCounter, rem, slots, cumulative: int, hitBoundary: bool): BigInt =
  if slots == 0:
    if rem != 0:
      return zeroBigInt()
    if counter.requiredBoundary.isNone:
      return oneBigInt()
    return if hitBoundary: oneBigInt() else: zeroBigInt()
  if rem < slots:
    return zeroBigInt()
  let key = (rem, slots, cumulative, hitBoundary)
  if counter.memo.hasKey(key):
    return counter.memo[key]
  var total = zeroBigInt()
  let maxX = rem - (slots - 1)
  for x in 1..maxX:
    let nextCumulative = cumulative + x
    var nextHit = hitBoundary
    if counter.requiredBoundary.isSome and not hitBoundary:
      let boundary = counter.requiredBoundary.get()
      if nextCumulative == boundary:
        nextHit = true
      elif nextCumulative > boundary:
        continue
    total = total + counter.countCutletState(rem - x, slots - 1, nextCumulative, nextHit)
  counter.memo[key] = total
  total

proc countAll*(counter: CutletPartitionCounter): BigInt =
  counter.countCutletState(counter.total, counter.slots, 0, false)

proc unrank1*(counter: CutletPartitionCounter, rank1: BigInt): seq[int] =
  let totalCount = counter.countAll()
  if rank1 < 1 or rank1 > totalCount:
    raise newException(ValueError, "E_CUTLET_UNRANK_RANK")
  var r = rank1
  var rem = counter.total
  var slots = counter.slots
  var cumulative = 0
  var hit = false
  result = @[]
  while slots > 0:
    let maxX = rem - (slots - 1)
    var selected = false
    for x in 1..maxX:
      let nextCumulative = cumulative + x
      var nextHit = hit
      if counter.requiredBoundary.isSome and not hit:
        let boundary = counter.requiredBoundary.get()
        if nextCumulative == boundary:
          nextHit = true
        elif nextCumulative > boundary:
          continue
      let block = counter.countCutletState(rem - x, slots - 1, nextCumulative, nextHit)
      if r > block:
        r = r - block
      else:
        result.add(x)
        rem -= x
        dec slots
        cumulative = nextCumulative
        hit = nextHit
        selected = true
        break
    if not selected:
      raise newException(ValueError, "E_CUTLET_UNRANK_INTERNAL")

proc newGateCache*(): GateCache =
  result = GateCache(
    gates: initTable[int, BigInt](),
    minKnownGateIndex: 0,
    maxKnownGateIndex: 0
  )
  result.gates[0] = FoundationDay

proc gateDay*(cache: GateCache, index: int): BigInt =
  if not cache.gates.hasKey(index):
    raise newException(ValueError, "E_GATE_NOT_READY")
  cache.gates[index]

proc newNormativeOracle*(): NormativeOracle =
  NormativeOracle(stones: buildStones(), gateCache: newGateCache())

proc positiveGateGap(oracle: NormativeOracle, n: int): int =
  if n < 1:
    raise newException(ValueError, "E_POSITIVE_GATE_INDEX")
  let r = oracle.sauce(FoundationDay, FoundationDay + n)
  let stream = askBowl(r, 1, SealGateGap)
  41 + chooseRank(stream, initBigInt(922)).toInt()

proc negativeGateGap(oracle: NormativeOracle, n: int): int =
  if n < 1:
    raise newException(ValueError, "E_NEGATIVE_GATE_INDEX")
  let r = oracle.sauce(FoundationDay, FoundationDay - n)
  let stream = askBowl(r, 1, SealGateGap)
  41 + chooseRank(stream, initBigInt(922)).toInt()

proc ensureGateIndex*(oracle: NormativeOracle, k: int): BigInt =
  let cache = oracle.gateCache
  if k > cache.maxKnownGateIndex:
    for n in (cache.maxKnownGateIndex + 1)..k:
      cache.gates[n] = cache.gates[n - 1] + oracle.positiveGateGap(n)
      cache.maxKnownGateIndex = n
  if k < cache.minKnownGateIndex:
    var n = cache.minKnownGateIndex - 1
    while n >= k:
      cache.gates[n] = cache.gates[n + 1] - oracle.negativeGateGap(abs(n))
      cache.minKnownGateIndex = n
      dec n
  cache.gates[k]

proc ensureGatesCover*(oracle: NormativeOracle, lowDay, highDay: BigInt) =
  if lowDay > highDay:
    raise newException(ValueError, "E_GATE_COVER_RANGE")
  let cache = oracle.gateCache
  while cache.gates[cache.minKnownGateIndex] > lowDay:
    discard oracle.ensureGateIndex(cache.minKnownGateIndex - 1)
  while cache.gates[cache.maxKnownGateIndex] < highDay:
    discard oracle.ensureGateIndex(cache.maxKnownGateIndex + 1)

proc gateIndexAtOrBefore*(oracle: NormativeOracle, day: BigInt): int =
  oracle.ensureGatesCover(day, day)
  let cache = oracle.gateCache
  var lo = cache.minKnownGateIndex
  var hi = cache.maxKnownGateIndex
  while lo < hi:
    let mid = lo + (hi - lo + 1) div 2
    if cache.gates[mid] <= day:
      lo = mid
    else:
      hi = mid - 1
  lo

proc exactGateIndex*(oracle: NormativeOracle, day: BigInt): Option[int] =
  let i = oracle.gateIndexAtOrBefore(day)
  if oracle.gateCache.gates[i] == day:
    some(i)
  else:
    none(int)

proc yearLength(oracle: NormativeOracle, openIndex, closeIndex: int): BigInt =
  oracle.gateCache.gates[closeIndex] - oracle.gateCache.gates[openIndex]

proc validYearPair(oracle: NormativeOracle, openIndex, closeIndex: int): bool =
  if closeIndex - openIndex < MinGateGapsPerYear:
    return false
  let length = oracle.yearLength(openIndex, closeIndex)
  length >= YearMinDays and length <= YearMaxDays

proc makeYear(oracle: NormativeOracle, number: int64, openIndex, closeIndex: int): Year =
  Year(
    number: number,
    openGateIndex: openIndex,
    closeGateIndex: closeIndex,
    openGateDay: oracle.gateCache.gates[openIndex],
    closeGateDay: oracle.gateCache.gates[closeIndex]
  )

proc year5000*(oracle: NormativeOracle, calculationDay: BigInt): Year =
  oracle.ensureGatesCover(calculationDay - YearMaxDays, calculationDay + YearMaxDays)
  var candidates: seq[(int, int)] = @[]
  let cache = oracle.gateCache
  for i in cache.minKnownGateIndex..<cache.maxKnownGateIndex:
    for j in (i + 1)..cache.maxKnownGateIndex:
      if not oracle.validYearPair(i, j):
        continue
      if not (cache.gates[i] < calculationDay and calculationDay <= cache.gates[j]):
        continue
      candidates.add((i, j))
  candidates.sort(proc(a, b: (int, int)): int =
    let lengthCmp = cmp(oracle.yearLength(a[0], a[1]), oracle.yearLength(b[0], b[1]))
    if lengthCmp != 0:
      return lengthCmp
    cmp(cache.gates[a[0]], cache.gates[b[0]])
  )
  if candidates.len == 0:
    raise newException(ValueError, "E_YEAR5000_CANDIDATES")
  let r = oracle.sauce(calculationDay, calculationDay)
  let stream = askBowl(r, 1, SealYear5000)
  let rank = chooseRank(stream, initBigInt(candidates.len)).toInt()
  let chosen = candidates[rank - 1]
  oracle.makeYear(5000, chosen[0], chosen[1])

proc nextYear*(oracle: NormativeOracle, calculationDay: BigInt, knownYear: Year): Year =
  let openIndex = knownYear.closeGateIndex
  var candidates: seq[int] = @[]
  var closeIndex = openIndex + 1
  while true:
    discard oracle.ensureGateIndex(closeIndex)
    if oracle.yearLength(openIndex, closeIndex) > YearMaxDays:
      break
    if oracle.validYearPair(openIndex, closeIndex):
      candidates.add(closeIndex)
    inc closeIndex
  candidates.sort(proc(a, b: int): int =
    let lengthCmp = cmp(oracle.yearLength(openIndex, a), oracle.yearLength(openIndex, b))
    if lengthCmp != 0: lengthCmp else: system.cmp(a, b)
  )
  if candidates.len == 0:
    raise newException(ValueError, "E_NEXT_YEAR_CANDIDATES")
  let r = oracle.sauce(calculationDay, oracle.gateCache.gates[openIndex])
  let stream = askBowl(r, 1, SealNextYear)
  let rank = chooseRank(stream, initBigInt(candidates.len)).toInt()
  oracle.makeYear(knownYear.number + 1, openIndex, candidates[rank - 1])

proc previousYear*(oracle: NormativeOracle, calculationDay: BigInt, knownYear: Year): Year =
  let closeIndex = knownYear.openGateIndex
  var candidates: seq[int] = @[]
  var openIndex = closeIndex - 1
  while true:
    discard oracle.ensureGateIndex(openIndex)
    if oracle.yearLength(openIndex, closeIndex) > YearMaxDays:
      break
    if oracle.validYearPair(openIndex, closeIndex):
      candidates.add(openIndex)
    dec openIndex
  candidates.sort(proc(a, b: int): int =
    let lengthCmp = cmp(oracle.yearLength(a, closeIndex), oracle.yearLength(b, closeIndex))
    if lengthCmp != 0: lengthCmp else: system.cmp(b, a)
  )
  if candidates.len == 0:
    raise newException(ValueError, "E_PREVIOUS_YEAR_CANDIDATES")
  let r = oracle.sauce(calculationDay, oracle.gateCache.gates[closeIndex])
  let stream = askBowl(r, 1, SealPreviousYear)
  let rank = chooseRank(stream, initBigInt(candidates.len)).toInt()
  oracle.makeYear(knownYear.number - 1, candidates[rank - 1], closeIndex)

proc findTargetYear*(oracle: NormativeOracle, calculationDay, targetDay: BigInt): Year =
  var y = oracle.year5000(calculationDay)
  while targetDay > y.closeGateDay:
    y = oracle.nextYear(calculationDay, y)
  while targetDay <= y.openGateDay:
    y = oracle.previousYear(calculationDay, y)
  if not (y.openGateDay < targetDay and targetDay <= y.closeGateDay):
    raise newException(ValueError, "E_TARGET_YEAR_INTERVAL")
  y

proc chooseCutletCount(oracle: NormativeOracle, structureSauce: SauceResult, year: Year): int =
  let gateGaps = year.closeGateIndex - year.openGateIndex
  var candidates: seq[int] = @[]
  for k in MinCutlets..MaxCutlets:
    if k <= gateGaps:
      candidates.add(k)
  if candidates.len == 0:
    raise newException(ValueError, "E_CUTLET_COUNT_CANDIDATES")
  let stream = askBowl(structureSauce, 2, SealCutletCount)
  let rank = chooseRank(stream, initBigInt(candidates.len)).toInt()
  candidates[rank - 1]

proc chooseCutletPartition(oracle: NormativeOracle, calculationDay: BigInt, structureSauce: SauceResult, year: Year, cutletCount: int): seq[int] =
  let totalGaps = year.closeGateIndex - year.openGateIndex
  let exactGate = oracle.exactGateIndex(calculationDay)
  var required = none(int)
  if exactGate.isSome:
    let g = exactGate.get()
    if year.openGateIndex < g and g < year.closeGateIndex:
      required = some(g - year.openGateIndex)
  let family = newCutletPartitionCounter(totalGaps, cutletCount, required)
  let count = family.countAll()
  if count < 1:
    raise newException(ValueError, "E_CUTLET_PARTITION_EMPTY")
  let stream = askBowl(structureSauce, 2, SealCutletPartition)
  let rank = chooseRank(stream, count)
  family.unrank1(rank)

proc chooseCutletNames(structureSauce: SauceResult, cutletCount: int): seq[int] =
  let n = fallingFactorial(17, cutletCount)
  let stream = askBowl(structureSauce, 5, SealCutletNames)
  let rank = chooseRank(stream, n)
  unrankDistinctIndices(17, cutletCount, rank)

proc materializeCutlets(oracle: NormativeOracle, year: Year, partition, names: seq[int]): seq[Cutlet] =
  if partition.len != names.len:
    raise newException(ValueError, "E_CUTLET_MATERIALIZE_LENGTH")
  var cursorGate = year.openGateIndex
  result = @[]
  for k in 0..<partition.len:
    let openGateIndex = cursorGate
    let closeGateIndex = cursorGate + partition[k]
    discard oracle.ensureGateIndex(closeGateIndex)
    result.add(Cutlet(
      nameCanonicalIndex: names[k],
      openGateIndex: openGateIndex,
      closeGateIndex: closeGateIndex,
      firstDay: oracle.gateCache.gates[openGateIndex] + 1,
      lastDay: oracle.gateCache.gates[closeGateIndex]
    ))
    cursorGate = closeGateIndex

proc chooseMonthCount(structureSauce: SauceResult, year: Year): int =
  let length = (year.closeGateDay - year.openGateDay).toInt()
  let minCount = ceilDivInt(length, MaxMonthDays)
  let maxCount = min(MaxMonths, length div MinMonthDays)
  if minCount < MinMonths or minCount > maxCount or maxCount > MaxMonths:
    raise newException(ValueError, "E_MONTH_COUNT_BOUNDS")
  let stream = askBowl(structureSauce, 3, SealMonthCount)
  let rank = chooseRank(stream, initBigInt(maxCount - minCount + 1)).toInt()
  minCount + rank - 1

proc chooseMonthLengths(structureSauce: SauceResult, year: Year, monthCount: int): seq[int] =
  let length = (year.closeGateDay - year.openGateDay).toInt()
  let family = newBoundedCompositionCounter(length, monthCount, MinMonthDays, MaxMonthDays)
  let count = family.countAll()
  if count < 1:
    raise newException(ValueError, "E_MONTH_LENGTH_FAMILY_EMPTY")
  let stream = askBowl(structureSauce, 3, SealMonthLengths)
  let rank = chooseRank(stream, count)
  family.unrank1(rank)

proc cloneInts(values: seq[int]): seq[int] =
  result = newSeq[int](values.len)
  for i, value in values:
    result[i] = value

proc newWeavingCounter*(lengths: seq[int]): WeavingCounter =
  WeavingCounter(lengths: cloneInts(lengths), memo: initTable[string, BigInt]())

proc initialWeaveState*(lengths: seq[int]): WeaveState =
  WeaveState(remaining: cloneInts(lengths), openedUpTo: 0, closedUpTo: 0)

proc legalWeaveMove*(counter: WeavingCounter, state: WeaveState, j: int): bool =
  if j < 1 or j > state.remaining.len:
    return false
  let idx = j - 1
  if state.remaining[idx] == 0:
    return false
  let alreadyOpened = state.remaining[idx] < counter.lengths[idx]
  if not alreadyOpened and j != state.openedUpTo + 1:
    return false
  let willClose = state.remaining[idx] == 1
  if willClose and j != state.closedUpTo + 1:
    return false
  true

proc applyWeaveMove*(counter: WeavingCounter, state: WeaveState, j: int): WeaveState =
  if not counter.legalWeaveMove(state, j):
    raise newException(ValueError, "E_WEAVE_MOVE")
  result.remaining = cloneInts(state.remaining)
  result.openedUpTo = state.openedUpTo
  result.closedUpTo = state.closedUpTo
  let idx = j - 1
  if result.remaining[idx] == counter.lengths[idx]:
    result.openedUpTo = j
  dec result.remaining[idx]
  if result.remaining[idx] == 0:
    result.closedUpTo = j

proc weaveKey(state: WeaveState): string =
  var parts = newSeq[string](state.remaining.len)
  for i, value in state.remaining:
    parts[i] = $value
  $state.openedUpTo & ":" & $state.closedUpTo & ":" & parts.join(",")

proc countWeavings*(counter: WeavingCounter, state: WeaveState): BigInt =
  var finished = true
  for value in state.remaining:
    if value != 0:
      finished = false
      break
  if finished:
    return oneBigInt()
  let key = weaveKey(state)
  if counter.memo.hasKey(key):
    return counter.memo[key]
  var total = zeroBigInt()
  for j in 1..state.remaining.len:
    if counter.legalWeaveMove(state, j):
      let next = counter.applyWeaveMove(state, j)
      total = total + counter.countWeavings(next)
  counter.memo[key] = total
  total

proc countAll*(counter: WeavingCounter): BigInt =
  counter.countWeavings(initialWeaveState(counter.lengths))

proc unrank1*(counter: WeavingCounter, rank1: BigInt): seq[int] =
  let total = counter.countAll()
  if rank1 < 1 or rank1 > total:
    raise newException(ValueError, "E_WEAVE_UNRANK_RANK")
  var state = initialWeaveState(counter.lengths)
  var r = rank1
  var totalLength = 0
  for value in counter.lengths:
    totalLength += value
  result = @[]
  while result.len < totalLength:
    var selected = false
    for j in 1..state.remaining.len:
      if not counter.legalWeaveMove(state, j):
        continue
      let next = counter.applyWeaveMove(state, j)
      let block = counter.countWeavings(next)
      if r > block:
        r = r - block
      else:
        result.add(j)
        state = next
        selected = true
        break
    if not selected:
      raise newException(ValueError, "E_WEAVE_UNRANK_INTERNAL")

proc chooseMonthWeaving(structureSauce: SauceResult, monthLengths: seq[int]): seq[int] =
  let family = newWeavingCounter(monthLengths)
  let count = family.countAll()
  if count < 1:
    raise newException(ValueError, "E_WEAVE_EMPTY")
  let stream = askBowl(structureSauce, 4, SealMonthWeaving)
  let rank = chooseRank(stream, count)
  family.unrank1(rank)

proc chooseMonthNames(structureSauce: SauceResult, monthCount: int): seq[int] =
  let n = fallingFactorial(47, monthCount)
  let stream = askBowl(structureSauce, 5, SealMonthNames)
  let rank = chooseRank(stream, n)
  unrankDistinctIndices(47, monthCount, rank)

proc buildYearStructure*(oracle: NormativeOracle, calculationDay: BigInt, year: Year): YearStructure =
  let firstDay = year.openGateDay + 1
  let r = oracle.sauce(calculationDay, firstDay)
  result.cutletCount = oracle.chooseCutletCount(r, year)
  result.cutletPartition = oracle.chooseCutletPartition(calculationDay, r, year, result.cutletCount)
  result.cutletNameIndices = chooseCutletNames(r, result.cutletCount)
  result.cutlets = oracle.materializeCutlets(year, result.cutletPartition, result.cutletNameIndices)
  result.monthCount = chooseMonthCount(r, year)
  result.monthLengths = chooseMonthLengths(r, year, result.monthCount)
  result.monthWeaving = chooseMonthWeaving(r, result.monthLengths)
  result.monthNameIndices = chooseMonthNames(r, result.monthCount)

proc calendarDateCanonical*(oracle: NormativeOracle, calculationDay, targetDay: BigInt): CalendarDateCanonical =
  let year = oracle.findTargetYear(calculationDay, targetDay)
  let structure = oracle.buildYearStructure(calculationDay, year)
  var chosen = -1
  for i, cutlet in structure.cutlets:
    if cutlet.firstDay <= targetDay and targetDay <= cutlet.lastDay:
      chosen = i
      break
  if chosen < 0:
    raise newException(ValueError, "E_CUTLET_NOT_FOUND")
  result.yearNumber = year.number
  result.cutletCanonicalIndex = structure.cutlets[chosen].nameCanonicalIndex
  result.dayInCutlet = targetDay - structure.cutlets[chosen].firstDay + 1
  let yearOffset0 = (targetDay - (year.openGateDay + 1)).toInt()
  if yearOffset0 < 0 or yearOffset0 >= structure.monthWeaving.len:
    raise newException(ValueError, "E_MONTH_OFFSET")
  let monthId = structure.monthWeaving[yearOffset0]
  result.monthCanonicalIndex = structure.monthNameIndices[monthId - 1]
  var occurrence = 0
  for p in 0..yearOffset0:
    if structure.monthWeaving[p] == monthId:
      inc occurrence
  result.dayInMonth = initBigInt(occurrence)

proc present*(value: CalendarDateCanonical): CalendarDatePresented =
  CalendarDatePresented(
    yearNumber: value.yearNumber,
    cutletName: cutletText(value.cutletCanonicalIndex),
    dayInCutlet: value.dayInCutlet,
    monthName: monthText(value.monthCanonicalIndex),
    dayInMonth: value.dayInMonth
  )
