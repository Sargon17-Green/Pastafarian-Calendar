module NormativeOracle {
  use BigInteger;
  use List;
  use Map;
  use ExactMath;
  use SourceLanguageCatalog;

  const GATE_GAP_MIN = 42;
  const GATE_GAP_MAX = 963;
  const YEAR_MIN_DAYS = 252;
  const YEAR_MAX_DAYS = 5778;
  const MIN_GATE_GAPS_PER_YEAR = 6;
  const MIN_CUTLETS = 6;
  const MAX_CUTLETS = 17;
  const MIN_MONTHS = 3;
  const MAX_MONTHS = 47;
  const MIN_MONTH_DAYS = 4;
  const MAX_MONTH_DAYS = 123;

  const SEAL_GATE_GAP = 1;
  const SEAL_YEAR_5000 = 10;
  const SEAL_NEXT_YEAR = 11;
  const SEAL_PREVIOUS_YEAR = 12;
  const SEAL_CUTLET_COUNT = 20;
  const SEAL_CUTLET_PARTITION = 21;
  const SEAL_CUTLET_NAMES = 22;
  const SEAL_MONTH_COUNT = 30;
  const SEAL_MONTH_LENGTHS = 31;
  const SEAL_MONTH_WEAVING = 32;
  const SEAL_MONTH_NAMES = 33;

  const WHEAT = 1;
  const BARLEY = 2;
  const SALT = 3;
  const BITTER = 4;
  const RED = 5;

  record WorkCounts {
    var action: bigint;
    var target: bigint;
    var distance: bigint;
    var connection: bigint;
    var direction: int;
  }

  record Stone {
    var wheat: bigint;
    var barley: bigint;
    var salt: bigint;
    var bitter: bigint;
    var red: bigint;

    proc value(kind: int): bigint {
      select kind {
        when WHEAT do return wheat;
        when BARLEY do return barley;
        when SALT do return salt;
        when BITTER do return bitter;
        when RED do return red;
        otherwise do halt("Невідомий вид каменю.");
      }
      return new bigint(0);
    }
  }

  record SauceResult {
    var bowls: [1..6] bigint;
    var orderAtDrop46: [1..6] int;
  }

  record AnswerStream {
    var first: bigint;
    var directionStep: int;
  }

  record Year {
    var number: bigint;
    var openGateIndex: int;
    var closeGateIndex: int;
    var openGateDay: bigint;
    var closeGateDay: bigint;
  }

  record YearCandidate {
    var openIndex: int;
    var closeIndex: int;
    var openDay: bigint;
    var closeDay: bigint;
  }

  record Cutlet {
    var canonicalNameIndex: int;
    var openGateIndex: int;
    var closeGateIndex: int;
    var firstDay: bigint;
    var lastDay: bigint;
  }

  record YearStructure {
    var cutletCount: int;
    var cutletPartition: list(int);
    var cutletNameIndices: list(int);
    var cutlets: list(Cutlet);
    var monthCount: int;
    var monthLengths: list(int);
    var monthWeaving: list(int);
    var monthNameIndices: list(int);
  }

  record CalendarDateResult {
    var yearNumber: bigint;
    var cutletName: string;
    var dayInCutlet: bigint;
    var monthName: string;
    var dayInMonth: int;
  }

  proc dayCount(const ref day: bigint): bigint {
    if day == FOUNDATION_DAY then return new bigint(1);
    if day > FOUNDATION_DAY then return 2 * (day - FOUNDATION_DAY) + 1;
    return 2 * (FOUNDATION_DAY - day);
  }

  proc workCounts(const ref calculationDay: bigint,
                  const ref targetDay: bigint): WorkCounts {
    var out: WorkCounts;
    out.action = dayCount(calculationDay);
    out.target = dayCount(targetDay);
    out.distance = absBig(targetDay - calculationDay) + 1;
    out.connection = out.action + out.target;
    if targetDay < calculationDay then
      out.direction = 1;
    else if targetDay == calculationDay then
      out.direction = 2;
    else
      out.direction = 3;
    return out;
  }

  proc buildStones() {
    var stones: [1..46] Stone;
    stones[1] = new Stone(new bigint(17), new bigint(29), new bigint(43),
                          new bigint(71), new bigint(101));

    for i in 2..46 {
      const old = stones[i - 1];
      var next: Stone;
      next.wheat = save(square(old.wheat) + 3 * old.barley + i);
      next.barley = save(square(old.barley) + 5 * old.salt + old.wheat);
      next.salt = save(square(old.salt) + 7 * old.bitter + old.barley);
      next.bitter = save(square(old.bitter) + 11 * old.red + old.salt);
      next.red = save(square(old.red) + 13 * old.wheat + old.bitter);
      stones[i] = next;
    }
    return stones;
  }

  proc buildHiddenDrops(const ref counts: WorkCounts, const ref stones) {
    const A: [1..7] int = [3, 5, 7, 9, 11, 13, 15];
    const B: [1..7] int = [4, 7, 10, 13, 16, 19, 22];
    const C: [1..7] int = [6, 10, 14, 18, 22, 26, 30];
    const D: [1..7] int = [8, 12, 16, 20, 24, 28, 32];
    const grindStone: [1..7] int = [WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY];
    var hidden: [1..7] bigint;

    for k in 1..7 {
      var x = counts.action
            + A[k] * counts.target
            + B[k] * counts.distance
            + C[k] * counts.connection
            + D[k] * counts.direction
            + stones[k].wheat + stones[k].barley + stones[k].salt
            + stones[k].bitter + stones[k].red;
      x = save(x);
      for grind in 1..7 {
        const oldX = x;
        x = save(square(oldX) + 3 * oldX + stones[k].value(grindStone[grind]) + grind);
      }
      hidden[k] = x;
    }
    return hidden;
  }

  proc priorValue(const ref visible: [1..46] bigint,
                  const ref hidden: [1..7] bigint,
                  i: int, back: int): bigint {
    const slot = i - back;
    if slot >= 1 then return visible[slot];
    return hidden[1 - slot];
  }

  proc buildVisibleDrops(const ref counts: WorkCounts,
                         const ref stones,
                         const ref hidden: [1..7] bigint) {
    const grindA: [1..11] int = [3,5,7,11,13,17,19,23,29,31,37];
    const grindB: [1..11] int = [5,7,11,13,17,19,23,29,31,37,41];
    const grindC: [1..11] int = [7,11,13,17,19,23,29,31,37,41,43];
    const grindD: [1..11] int = [11,13,17,19,23,29,31,37,41,43,47];
    const grindKind: [1..11] int = [WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT];
    var visible: [1..46] bigint;

    for i in 1..46 {
      const p1 = priorValue(visible, hidden, i, 1);
      const p3 = priorValue(visible, hidden, i, 3);
      const p7 = priorValue(visible, hidden, i, 7);

      var x = save(
          stones[i].wheat * counts.action
        + stones[i].barley * counts.target
        + stones[i].salt * counts.distance
        + stones[i].bitter * counts.connection
        + stones[i].red * counts.direction
        + p1 + 3 * p3 + 5 * p7 + i
      );

      for grind in 1..11 {
        const oldX = x;
        x = save(square(oldX)
               + grindA[grind] * oldX
               + grindB[grind] * p1
               + grindC[grind] * p3
               + grindD[grind] * p7
               + stones[i].value(grindKind[grind]));
      }
      visible[i] = x;
    }
    return visible;
  }

  proc factorialInt(n: int): int {
    var out = 1;
    for i in 2..n do out *= i;
    return out;
  }

  proc permutationUnrank1(rank1: int) {
    if rank1 < 1 || rank1 > 720 then halt("Ранг перестановки має бути в межах 1..720.");
    var remaining = new list(int);
    for x in 1..6 do remaining.pushBack(x);
    var result: [1..6] int;
    var rank0 = rank1 - 1;

    for position in 1..6 {
      const slotsLeft = 7 - position;
      const block = factorialInt(slotsLeft - 1);
      const q = rank0 / block;
      rank0 %= block;
      result[position] = remaining[q];
      remaining.getAndRemove(q);
    }
    return result;
  }

  proc bowlOrderFromDrop(const ref dropValue: bigint) {
    const rank = (regularMod(dropValue - 1, 720) + 1):int;
    return permutationUnrank1(rank);
  }

  proc initialBowls(const ref counts: WorkCounts) {
    const primes: [1..6] int = [17,19,23,29,31,37];
    var bowls: [1..6] bigint;
    for id in 1..6 {
      const s = counts.action
              + counts.target * id
              + counts.distance
              + counts.connection
              + counts.direction
              + primes[id] * primes[id];
      bowls[id] = save(square(s) + id);
    }
    return bowls;
  }

  proc applyVisibleDropsToBowls(in bowls: [1..6] bigint,
                                const ref visible: [1..46] bigint,
                                const ref stones) {
    const stoneByPosition: [1..6] int = [WHEAT,BARLEY,SALT,BITTER,RED,WHEAT];
    var orderAt46: [1..6] int;

    for i in 1..46 {
      const drop = visible[i];
      const order = bowlOrderFromDrop(drop);
      const old = bowls;
      var pour: [1..6] bigint;
      var nextBowls: [1..6] bigint;

      const firstBowl = order[1];
      const secondBowl = order[2];
      const thirdBowl = order[3];
      pour[1] = save(square(drop) + stones[i].wheat * old[firstBowl] + 3 * i);
      pour[2] = save(square(drop) + stones[i].barley * old[secondBowl] + 5 * i);
      pour[3] = save(square(drop) + stones[i].salt * old[thirdBowl] + 7 * i);
      pour[4] = 0; pour[5] = 0; pour[6] = 0;

      for position in 1..6 {
        const bowlId = order[position];
        const prevId = order[wrap1(position - 1, 6)];
        const nextId = order[wrap1(position + 1, 6)];
        const s = old[bowlId]
                + 2 * old[prevId]
                + 3 * old[nextId]
                + pour[position]
                + drop
                + stones[i].value(stoneByPosition[position]);
        nextBowls[bowlId] = save(square(s)
                               + 5 * old[prevId] * old[nextId]
                               + i * position);
      }
      bowls = nextBowls;
      if i == 46 then orderAt46 = order;
    }
    return (bowls, orderAt46);
  }

  proc postStir12(in bowls: [1..6] bigint) {
    for stir in 1..12 {
      const old = bowls;
      const savedBowlSum = save(old[1] + old[2] + old[3] + old[4] + old[5] + old[6] + 149 * stir);
      const orderNumber = (regularMod(savedBowlSum - 1, 720) + 1):int;
      const order = permutationUnrank1(orderNumber);
      var nextBowls: [1..6] bigint;

      for position in 1..6 {
        const bowlId = order[position];
        const prevId = order[wrap1(position - 1, 6)];
        const nextId = order[wrap1(position + 1, 6)];
        const s = old[bowlId]
                + 3 * old[prevId]
                + 5 * old[nextId]
                + savedBowlSum
                + stir
                + position * position;
        nextBowls[bowlId] = save(square(s) + 7 * old[prevId] * old[nextId]);
      }
      bowls = nextBowls;
    }
    return bowls;
  }

  proc sauce(const ref calculationDay: bigint,
             const ref targetDay: bigint): SauceResult {
    const counts = workCounts(calculationDay, targetDay);
    const stones = buildStones();
    const hidden = buildHiddenDrops(counts, stones);
    const visible = buildVisibleDrops(counts, stones, hidden);
    const bowls0 = initialBowls(counts);
    const (afterDrops, orderAt46) = applyVisibleDropsToBowls(bowls0, visible, stones);
    const finalBowls = postStir12(afterDrops);
    var out: SauceResult;
    out.bowls = finalBowls;
    out.orderAtDrop46 = orderAt46;
    return out;
  }

  proc nextBowlInDrop46Order(const ref sauceResult: SauceResult,
                             queriedBowlId: int): int {
    var pos = 0;
    for p in 1..6 do if sauceResult.orderAtDrop46[p] == queriedBowlId then pos = p;
    if pos == 0 then halt("Запитана чаша відсутня в порядку 46-ї краплі.");
    return sauceResult.orderAtDrop46[wrap1(pos + 1, 6)];
  }

  proc askBowl(const ref sauceResult: SauceResult,
               queriedBowlId: int, seal: int): AnswerStream {
    const nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId);
    const first = save(square(sauceResult.bowls[queriedBowlId] + seal + 181)
                     + 179 * sauceResult.bowls[nextId]
                     + seal);
    const directionNumber = save(square(first + seal + 1 + 193)
                               + 193 * first
                               + 197 * sauceResult.bowls[6]);
    var out: AnswerStream;
    out.first = first;
    if regularMod(directionNumber, 2) == 1 then out.directionStep = 1;
    else out.directionStep = -1;
    return out;
  }

  proc answerAt(const ref stream: AnswerStream, k: bigint): bigint {
    return 1 + regularMod(stream.first - 1 + stream.directionStep * k, M);
  }

  proc answerAt(const ref stream: AnswerStream, k: int): bigint {
    return answerAt(stream, new bigint(k));
  }

  proc chooseRankShort(const ref stream: AnswerStream, const ref n: bigint): bigint {
    if n < 1 || n > M then halt("Короткий вибір отримав недопустимий розмір простору.");
    const acceptanceLimit = floorDiv(M, n) * n;
    var k = new bigint(0);
    while true {
      const x = answerAt(stream, k);
      if x <= acceptanceLimit then return regularMod(x - 1, n) + 1;
      k += 1;
    }
    return new bigint(0);
  }

  proc chooseRankWide(const ref stream: AnswerStream, const ref n: bigint): bigint {
    if n <= M then halt("Широкий вибір вимагає простір, більший за M.");
    var places = 1;
    var space = M;
    while space < n {
      places += 1;
      space *= M;
    }

    var wide = new bigint(1);
    var weight = new bigint(1);
    for j in 0..<places {
      wide += (answerAt(stream, j) - 1) * weight;
      weight *= M;
    }

    const acceptanceLimit = floorDiv(space, n) * n;
    while wide > acceptanceLimit do
      wide = 1 + regularMod(wide - 1 + stream.directionStep, space);
    return regularMod(wide - 1, n) + 1;
  }

  proc chooseRank(const ref stream: AnswerStream, const ref n: bigint): bigint {
    if n < 1 then halt("Простір вибору має бути непорожнім.");
    if n <= M then return chooseRankShort(stream, n);
    return chooseRankWide(stream, n);
  }

  proc chooseRank(const ref stream: AnswerStream, n: int): bigint {
    return chooseRank(stream, new bigint(n));
  }

  record GateOracle {
    var gates: map(int, bigint);
    var minKnownGateIndex: int = 0;
    var maxKnownGateIndex: int = 0;
    var initialized: bool = false;

    proc ref initialize() {
      if initialized then return;
      gates.add(0, FOUNDATION_DAY);
      minKnownGateIndex = 0;
      maxKnownGateIndex = 0;
      initialized = true;
    }

    proc ref setGate(index: int, const ref day: bigint) {
      if gates.contains(index) then gates[index] = day;
      else gates.add(index, day);
    }

    proc ref positiveGateGap(n: int): int {
      const r = sauce(FOUNDATION_DAY, FOUNDATION_DAY + n);
      const stream = askBowl(r, 1, SEAL_GATE_GAP);
      return 41 + chooseRank(stream, 922):int;
    }

    proc ref negativeGateGap(n: int): int {
      const r = sauce(FOUNDATION_DAY, FOUNDATION_DAY - n);
      const stream = askBowl(r, 1, SEAL_GATE_GAP);
      return 41 + chooseRank(stream, 922):int;
    }

    proc ref ensureGateIndex(k: int): bigint {
      initialize();

      if k > maxKnownGateIndex {
        for n in (maxKnownGateIndex + 1)..k {
          const prior = gates[n - 1];
          setGate(n, prior + positiveGateGap(n));
          maxKnownGateIndex = n;
        }
      }

      if k < minKnownGateIndex {
        var n = minKnownGateIndex - 1;
        while n >= k {
          const later = gates[n + 1];
          setGate(n, later - negativeGateGap(-n));
          minKnownGateIndex = n;
          n -= 1;
        }
      }
      return gates[k];
    }

    proc ref ensureGatesCover(const ref lowDay: bigint,
                              const ref highDay: bigint) {
      if lowDay > highDay then halt("Межі покриття воріт задано у зворотному порядку.");
      initialize();
      while gates[minKnownGateIndex] > lowDay do
        ensureGateIndex(minKnownGateIndex - 1);
      while gates[maxKnownGateIndex] < highDay do
        ensureGateIndex(maxKnownGateIndex + 1);
    }

    proc ref gateIndexAtOrBefore(const ref day: bigint): int {
      ensureGatesCover(day, day);
      var lo = minKnownGateIndex;
      var hi = maxKnownGateIndex;
      while lo < hi {
        const mid = lo + (hi - lo + 1) / 2;
        if gates[mid] <= day then lo = mid;
        else hi = mid - 1;
      }
      return lo;
    }

    proc ref gateIndexAtOrAfter(const ref day: bigint): int {
      const i = gateIndexAtOrBefore(day);
      if gates[i] == day then return i;
      ensureGateIndex(i + 1);
      return i + 1;
    }

    proc ref exactGateIndex(const ref day: bigint, out index: int): bool {
      const i = gateIndexAtOrBefore(day);
      index = i;
      return gates[i] == day;
    }

    proc ref validYearPair(openIndex: int, closeIndex: int): bool {
      if closeIndex - openIndex < MIN_GATE_GAPS_PER_YEAR then return false;
      const length = ensureGateIndex(closeIndex) - ensureGateIndex(openIndex);
      return length >= YEAR_MIN_DAYS && length <= YEAR_MAX_DAYS;
    }

    proc candidateComesBefore(const ref a: YearCandidate,
                              const ref b: YearCandidate): bool {
      const lenA = a.closeDay - a.openDay;
      const lenB = b.closeDay - b.openDay;
      if lenA < lenB then return true;
      if lenA > lenB then return false;
      return a.openDay < b.openDay;
    }

    proc ref year5000(const ref calculationDay: bigint): Year {
      ensureGatesCover(calculationDay - YEAR_MAX_DAYS,
                       calculationDay + YEAR_MAX_DAYS);
      var sorted = new list(YearCandidate);

      for i in minKnownGateIndex..<maxKnownGateIndex {
        for j in (i + 1)..maxKnownGateIndex {
          if j - i < MIN_GATE_GAPS_PER_YEAR then continue;
          const openDay = gates[i];
          const closeDay = gates[j];
          const length = closeDay - openDay;
          if length < YEAR_MIN_DAYS then continue;
          if length > YEAR_MAX_DAYS then break;
          if !(openDay < calculationDay && calculationDay <= closeDay) then continue;

          const candidate = new YearCandidate(i, j, openDay, closeDay);
          var insertion = 0;
          while insertion < sorted.size &&
                !candidateComesBefore(candidate, sorted[insertion]) do insertion += 1;
          sorted.insert(insertion, candidate);
        }
      }

      if sorted.size == 0 then halt("Не знайдено кандидата для року 5000.");
      const r = sauce(calculationDay, calculationDay);
      const stream = askBowl(r, 1, SEAL_YEAR_5000);
      const chosenIndex = chooseRank(stream, sorted.size):int - 1;
      const chosen = sorted[chosenIndex];
      return new Year(new bigint(5000), chosen.openIndex, chosen.closeIndex,
                      chosen.openDay, chosen.closeDay);
    }

    proc ref nextYear(const ref calculationDay: bigint,
                      const ref knownYear: Year): Year {
      const openIndex = knownYear.closeGateIndex;
      const openDay = ensureGateIndex(openIndex);
      ensureGatesCover(openDay, openDay + YEAR_MAX_DAYS);
      var candidates = new list(int);
      var closeIndex = openIndex + 1;

      while true {
        const closeDay = ensureGateIndex(closeIndex);
        const length = closeDay - openDay;
        if length > YEAR_MAX_DAYS then break;
        if closeIndex - openIndex >= MIN_GATE_GAPS_PER_YEAR && length >= YEAR_MIN_DAYS then
          candidates.pushBack(closeIndex);
        closeIndex += 1;
      }

      if candidates.size == 0 then halt("Не знайдено наступного року.");
      const r = sauce(calculationDay, openDay);
      const stream = askBowl(r, 1, SEAL_NEXT_YEAR);
      const selected = candidates[chooseRank(stream, candidates.size):int - 1];
      return new Year(knownYear.number + 1, openIndex, selected,
                      openDay, ensureGateIndex(selected));
    }

    proc ref previousYear(const ref calculationDay: bigint,
                          const ref knownYear: Year): Year {
      const closeIndex = knownYear.openGateIndex;
      const closeDay = ensureGateIndex(closeIndex);
      ensureGatesCover(closeDay - YEAR_MAX_DAYS, closeDay);
      var candidates = new list(int);
      var openIndex = closeIndex - 1;

      while true {
        const openDay = ensureGateIndex(openIndex);
        const length = closeDay - openDay;
        if length > YEAR_MAX_DAYS then break;
        if closeIndex - openIndex >= MIN_GATE_GAPS_PER_YEAR && length >= YEAR_MIN_DAYS then
          candidates.pushBack(openIndex);
        openIndex -= 1;
      }

      if candidates.size == 0 then halt("Не знайдено попереднього року.");
      const r = sauce(calculationDay, closeDay);
      const stream = askBowl(r, 1, SEAL_PREVIOUS_YEAR);
      const selected = candidates[chooseRank(stream, candidates.size):int - 1];
      return new Year(knownYear.number - 1, selected, closeIndex,
                      ensureGateIndex(selected), closeDay);
    }

    proc ref findTargetYear(const ref calculationDay: bigint,
                            const ref targetDay: bigint): Year {
      var y = year5000(calculationDay);
      while targetDay > y.closeGateDay do y = nextYear(calculationDay, y);
      while targetDay <= y.openGateDay do y = previousYear(calculationDay, y);
      if !(y.openGateDay < targetDay && targetDay <= y.closeGateDay) then
        halt("Цільовий день не належить знайденому інтервалу року.");
      return y;
    }
  }

  record CutletPartitionCounter {
    var totalGaps: int;
    var slotsTotal: int;
    var requiredBoundary: int = -1;
    var memo: map(string, bigint);

    proc key(rem: int, slots: int, cumulative: int, hit: bool): string {
      return rem:string + ":" + slots:string + ":" + cumulative:string + ":" + hit:string;
    }

    proc ref countState(rem: int, slots: int,
                        cumulative: int, hitBoundary: bool): bigint {
      if slots == 0 {
        if rem != 0 then return new bigint(0);
        if requiredBoundary < 0 then return new bigint(1);
        if hitBoundary then return new bigint(1);
        return new bigint(0);
      }
      if rem < slots then return new bigint(0);

      const k = key(rem, slots, cumulative, hitBoundary);
      if memo.contains(k) then return memo[k];

      var total = new bigint(0);
      const maxX = rem - (slots - 1);
      for x in 1..maxX {
        const nextCumulative = cumulative + x;
        var nextHit = hitBoundary;
        if requiredBoundary >= 0 && !hitBoundary {
          if nextCumulative == requiredBoundary then
            nextHit = true;
          else if nextCumulative > requiredBoundary then
            continue;
        }
        total += countState(rem - x, slots - 1, nextCumulative, nextHit);
      }
      memo.add(k, total);
      return total;
    }

    proc ref countAll(): bigint {
      return countState(totalGaps, slotsTotal, 0, false);
    }

    proc ref unrank1(const ref rank1: bigint): list(int) {
      const all = countAll();
      if rank1 < 1 || rank1 > all then halt("Ранг розбиття котлет поза межами сімейства.");
      var r = rank1;
      var rem = totalGaps;
      var slots = slotsTotal;
      var cumulative = 0;
      var hit = false;
      var out = new list(int);

      while slots > 0 {
        const maxX = rem - (slots - 1);
        var selected = false;
        for x in 1..maxX {
          const nextCumulative = cumulative + x;
          var nextHit = hit;
          if requiredBoundary >= 0 && !hit {
            if nextCumulative == requiredBoundary then
              nextHit = true;
            else if nextCumulative > requiredBoundary then
              continue;
          }
          const block = countState(rem - x, slots - 1, nextCumulative, nextHit);
          if r > block then
            r -= block;
          else {
            out.pushBack(x);
            rem -= x;
            slots -= 1;
            cumulative = nextCumulative;
            hit = nextHit;
            selected = true;
            break;
          }
        }
        if !selected then halt("Не вдалося відкрити ранг розбиття котлет.");
      }
      return out;
    }
  }

  record BoundedCompositionCounter {
    var totalValue: int;
    var slotsTotal: int;
    var lo: int;
    var hi: int;
    var memo: map(string, bigint);

    proc key(rem: int, slots: int): string {
      return rem:string + ":" + slots:string;
    }

    proc ref countState(rem: int, slots: int): bigint {
      if slots == 0 {
        if rem == 0 then return new bigint(1);
        return new bigint(0);
      }
      if rem < slots * lo || rem > slots * hi then return new bigint(0);
      const k = key(rem, slots);
      if memo.contains(k) then return memo[k];
      var total = new bigint(0);
      for x in lo..hi do total += countState(rem - x, slots - 1);
      memo.add(k, total);
      return total;
    }

    proc ref countAll(): bigint {
      return countState(totalValue, slotsTotal);
    }

    proc ref unrank1(const ref rank1: bigint): list(int) {
      const all = countAll();
      if rank1 < 1 || rank1 > all then halt("Ранг обмеженої композиції поза межами сімейства.");
      var r = rank1;
      var rem = totalValue;
      var slots = slotsTotal;
      var out = new list(int);

      while slots > 0 {
        var selected = false;
        for x in lo..hi {
          const block = countState(rem - x, slots - 1);
          if r > block then
            r -= block;
          else {
            out.pushBack(x);
            rem -= x;
            slots -= 1;
            selected = true;
            break;
          }
        }
        if !selected then halt("Не вдалося відкрити ранг обмеженої композиції.");
      }
      return out;
    }
  }

  proc unrankDistinctNameIndices(masterCount: int, k: int,
                                 const ref rank1: bigint): list(int) {
    const total = fallingFactorialBig(masterCount, k);
    if rank1 < 1 || rank1 > total then halt("Ранг набору різних назв поза межами сімейства.");
    var remaining = new list(int);
    for i in 1..masterCount do remaining.pushBack(i);
    var out = new list(int);
    var r = rank1;

    for position in 1..k {
      const suffixLength = k - position;
      const block = fallingFactorialBig(remaining.size - 1, suffixLength);
      var chosenPosition = -1;
      for candidatePosition in remaining.indices {
        if r > block then
          r -= block;
        else {
          chosenPosition = candidatePosition;
          break;
        }
      }
      if chosenPosition < 0 then halt("Не вдалося відкрити ранг різних назв.");
      out.pushBack(remaining[chosenPosition]);
      remaining.getAndRemove(chosenPosition);
    }
    return out;
  }

  proc chooseCutletCount(const ref structureSauce: SauceResult,
                         const ref year: Year): int {
    const gateGaps = year.closeGateIndex - year.openGateIndex;
    var candidates = new list(int);
    for k in MIN_CUTLETS..MAX_CUTLETS do if k <= gateGaps then candidates.pushBack(k);
    if candidates.size == 0 then halt("Немає допустимої кількості котлет.");
    const stream = askBowl(structureSauce, 2, SEAL_CUTLET_COUNT);
    return candidates[chooseRank(stream, candidates.size):int - 1];
  }

  proc chooseCutletPartition(ref gates: GateOracle,
                             const ref calculationDay: bigint,
                             const ref structureSauce: SauceResult,
                             const ref year: Year,
                             cutletCount: int): list(int) {
    const totalGaps = year.closeGateIndex - year.openGateIndex;
    var gateIndex = 0;
    const isExactGate = gates.exactGateIndex(calculationDay, gateIndex);
    var required = -1;
    if isExactGate &&
       year.openGateIndex < gateIndex && gateIndex < year.closeGateIndex then
      required = gateIndex - year.openGateIndex;

    var counter: CutletPartitionCounter;
    counter.totalGaps = totalGaps;
    counter.slotsTotal = cutletCount;
    counter.requiredBoundary = required;
    const stream = askBowl(structureSauce, 2, SEAL_CUTLET_PARTITION);
    const rank = chooseRank(stream, counter.countAll());
    return counter.unrank1(rank);
  }

  proc chooseCutletNameIndices(const ref structureSauce: SauceResult,
                               cutletCount: int): list(int) {
    const n = fallingFactorialBig(17, cutletCount);
    const stream = askBowl(structureSauce, 5, SEAL_CUTLET_NAMES);
    return unrankDistinctNameIndices(17, cutletCount, chooseRank(stream, n));
  }

  proc materializeCutlets(ref gates: GateOracle,
                          const ref year: Year,
                          const ref partition: list(int),
                          const ref nameIndices: list(int)): list(Cutlet) {
    if partition.size != nameIndices.size then halt("Кількість меж котлет і назв не збігається.");
    var out = new list(Cutlet);
    var cursorGate = year.openGateIndex;
    for i in partition.indices {
      const openIndex = cursorGate;
      const closeIndex = cursorGate + partition[i];
      const c = new Cutlet(nameIndices[i], openIndex, closeIndex,
                           gates.ensureGateIndex(openIndex) + 1,
                           gates.ensureGateIndex(closeIndex));
      out.pushBack(c);
      cursorGate = closeIndex;
    }
    return out;
  }

  proc chooseMonthCount(const ref structureSauce: SauceResult,
                        const ref year: Year): int {
    const lengthBig = year.closeGateDay - year.openGateDay;
    const length = lengthBig:int;
    const minMonths = (length + MAX_MONTH_DAYS - 1) / MAX_MONTH_DAYS;
    const maxMonths = min(MAX_MONTHS, length / MIN_MONTH_DAYS);
    if minMonths < MIN_MONTHS || minMonths > maxMonths then
      halt("Нормативні межі кількості місяців порушені.");
    const stream = askBowl(structureSauce, 3, SEAL_MONTH_COUNT);
    return minMonths + chooseRank(stream, maxMonths - minMonths + 1):int - 1;
  }

  proc chooseMonthLengths(const ref structureSauce: SauceResult,
                          const ref year: Year,
                          monthCount: int): list(int) {
    const length = (year.closeGateDay - year.openGateDay):int;
    var counter: BoundedCompositionCounter;
    counter.totalValue = length;
    counter.slotsTotal = monthCount;
    counter.lo = MIN_MONTH_DAYS;
    counter.hi = MAX_MONTH_DAYS;
    const stream = askBowl(structureSauce, 3, SEAL_MONTH_LENGTHS);
    const rank = chooseRank(stream, counter.countAll());
    return counter.unrank1(rank);
  }

  record WeavingCounter {
    var lengths: list(int);
    var memo: map(string, bigint);

    proc stateKey(const ref remaining: list(int), openedUpTo: int,
                  closedUpTo: int): string {
      var key = openedUpTo:string + ":" + closedUpTo:string;
      for x in remaining do key += ":" + x:string;
      return key;
    }

    proc legalMove(const ref remaining: list(int), openedUpTo: int,
                   closedUpTo: int, monthId: int): bool {
      const idx = monthId - 1;
      if remaining[idx] == 0 then return false;
      const alreadyOpened = remaining[idx] < lengths[idx];
      if !alreadyOpened && monthId != openedUpTo + 1 then return false;
      const willClose = remaining[idx] == 1;
      if willClose && monthId != closedUpTo + 1 then return false;
      return true;
    }

    proc ref countState(const ref remaining: list(int), openedUpTo: int,
                        closedUpTo: int): bigint {
      var allZero = true;
      for x in remaining do if x != 0 then allZero = false;
      if allZero then return new bigint(1);

      const key = stateKey(remaining, openedUpTo, closedUpTo);
      if memo.contains(key) then return memo[key];
      var total = new bigint(0);
      const m = lengths.size;
      for monthId in 1..m {
        if !legalMove(remaining, openedUpTo, closedUpTo, monthId) then continue;
        const idx = monthId - 1;
        var nextRemaining = remaining;
        var nextOpened = openedUpTo;
        var nextClosed = closedUpTo;
        if nextRemaining[idx] == lengths[idx] then nextOpened = monthId;
        nextRemaining[idx] -= 1;
        if nextRemaining[idx] == 0 then nextClosed = monthId;
        total += countState(nextRemaining, nextOpened, nextClosed);
      }
      memo.add(key, total);
      return total;
    }

    proc ref countAll(): bigint {
      return countState(lengths, 0, 0);
    }

    proc ref unrank1(const ref rank1: bigint): list(int) {
      const total = countAll();
      if rank1 < 1 || rank1 > total then halt("Ранг шитва місяців поза межами сімейства.");
      var remaining = lengths;
      var openedUpTo = 0;
      var closedUpTo = 0;
      var r = rank1;
      var out = new list(int);
      var targetLength = 0;
      for x in lengths do targetLength += x;

      while out.size < targetLength {
        var selected = false;
        for monthId in 1..lengths.size {
          if !legalMove(remaining, openedUpTo, closedUpTo, monthId) then continue;
          const idx = monthId - 1;
          var nextRemaining = remaining;
          var nextOpened = openedUpTo;
          var nextClosed = closedUpTo;
          if nextRemaining[idx] == lengths[idx] then nextOpened = monthId;
          nextRemaining[idx] -= 1;
          if nextRemaining[idx] == 0 then nextClosed = monthId;
          const block = countState(nextRemaining, nextOpened, nextClosed);
          if r > block then
            r -= block;
          else {
            out.pushBack(monthId);
            remaining = nextRemaining;
            openedUpTo = nextOpened;
            closedUpTo = nextClosed;
            selected = true;
            break;
          }
        }
        if !selected then halt("Не вдалося відкрити ранг шитва місяців.");
      }
      return out;
    }
  }

  proc chooseMonthWeaving(const ref structureSauce: SauceResult,
                          const ref monthLengths: list(int)): list(int) {
    var counter: WeavingCounter;
    counter.lengths = monthLengths;
    const stream = askBowl(structureSauce, 4, SEAL_MONTH_WEAVING);
    return counter.unrank1(chooseRank(stream, counter.countAll()));
  }

  proc chooseMonthNameIndices(const ref structureSauce: SauceResult,
                              monthCount: int): list(int) {
    const n = fallingFactorialBig(47, monthCount);
    const stream = askBowl(structureSauce, 5, SEAL_MONTH_NAMES);
    return unrankDistinctNameIndices(47, monthCount, chooseRank(stream, n));
  }

  proc buildYearStructure(ref gates: GateOracle,
                          const ref calculationDay: bigint,
                          const ref year: Year): YearStructure {
    const firstDay = year.openGateDay + 1;
    const r = sauce(calculationDay, firstDay);
    var out: YearStructure;
    out.cutletCount = chooseCutletCount(r, year);
    out.cutletPartition = chooseCutletPartition(gates, calculationDay, r, year, out.cutletCount);
    out.cutletNameIndices = chooseCutletNameIndices(r, out.cutletCount);
    out.cutlets = materializeCutlets(gates, year, out.cutletPartition, out.cutletNameIndices);
    out.monthCount = chooseMonthCount(r, year);
    out.monthLengths = chooseMonthLengths(r, year, out.monthCount);
    out.monthWeaving = chooseMonthWeaving(r, out.monthLengths);
    out.monthNameIndices = chooseMonthNameIndices(r, out.monthCount);
    return out;
  }

  proc calendarDate(ref gates: GateOracle,
                    const ref calculationDay: bigint,
                    const ref targetDay: bigint): CalendarDateResult {
    const year = gates.findTargetYear(calculationDay, targetDay);
    const structure = buildYearStructure(gates, calculationDay, year);

    var chosenCutletIndex = -1;
    for i in structure.cutlets.indices {
      const c = structure.cutlets[i];
      if c.firstDay <= targetDay && targetDay <= c.lastDay {
        chosenCutletIndex = i;
        break;
      }
    }
    if chosenCutletIndex < 0 then halt("Цільовий день не належить жодній котлеті.");
    const chosenCutlet = structure.cutlets[chosenCutletIndex];
    const dayInCutlet = targetDay - chosenCutlet.firstDay + 1;

    const yearOffset0 = (targetDay - (year.openGateDay + 1)):int;
    const monthId = structure.monthWeaving[yearOffset0];
    const monthNameIndex = structure.monthNameIndices[monthId - 1];
    var dayInMonth = 0;
    for p in 0..yearOffset0 do
      if structure.monthWeaving[p] == monthId then dayInMonth += 1;

    var result: CalendarDateResult;
    result.yearNumber = year.number;
    result.cutletName = cutletNameByCanonicalIndex(chosenCutlet.canonicalNameIndex);
    result.dayInCutlet = dayInCutlet;
    result.monthName = monthNameByCanonicalIndex(monthNameIndex);
    result.dayInMonth = dayInMonth;
    return result;
  }
}
