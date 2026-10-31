// DISCOVERY 03: bounded, independent research only. This is NOT Stage 6 acceptance.
// No expected-red is asserted without a real, reproduced mismatch.
use BigInteger;
use Map;
use List;
use ExactMath;
use LegacyRemainder;
use Patch01Adapter;
use LegacyDayTag;
use Patch02Adapter;
use NormativeOracle only CutletPartitionCounter, BoundedCompositionCounter, WeavingCounter;

var checks = 0;
var failures = 0;

proc check(condition: bool, description: string) {
  checks += 1;
  if condition then
    writeln("ГАРАЗД: ", description);
  else {
    failures += 1;
    writeln("ПОМИЛКА: ", description);
  }
}

// Direct exhaustive enumeration: never call the implementation's counter
// to generate expected triples. Positive compositions are lexicographically
// ordered by their first, then second part.
proc probeCutletCompositions(total: int, requiredBoundary: int) {
  var tested: CutletPartitionCounter;
  tested.totalGaps = total;
  tested.slotsTotal = 3;
  tested.requiredBoundary = requiredBoundary;

  var enumerated = 0;
  for first in 1..total {
    for second in 1..total {
      const third = total - first - second;
      if third < 1 then continue;
      if requiredBoundary >= 0 &&
         first != requiredBoundary &&
         first + second != requiredBoundary then continue;

      enumerated += 1;
      const actual = tested.unrank1(new bigint(enumerated));
      check(actual.size == 3 &&
            actual[0] == first &&
            actual[1] == second &&
            actual[2] == third,
            "Котлети: пряма нумерація, N=" + total:string +
            ", B=" + requiredBoundary:string +
            ", ранг=" + enumerated:string);
    }
  }
  check(tested.countAll() == enumerated,
        "Котлети: незалежна потужність N=" + total:string +
        ", B=" + requiredBoundary:string);
}

// Independent exhaustive two-slot bounded compositions.
proc probeBoundedCompositions(total: int, lower: int, upper: int) {
  var tested: BoundedCompositionCounter;
  tested.totalValue = total;
  tested.slotsTotal = 2;
  tested.lo = lower;
  tested.hi = upper;

  var enumerated = 0;
  for first in lower..upper {
    const second = total - first;
    if second < lower || second > upper then continue;
    enumerated += 1;
    const actual = tested.unrank1(new bigint(enumerated));
    check(actual.size == 2 &&
          actual[0] == first && actual[1] == second,
          "Місяці: прямий ранг " + enumerated:string);
  }
  check(tested.countAll() == enumerated,
        "Місяці: незалежна потужність");
}

// For two months of length 4, first opening forces position 0 to month 1,
// and first closing forces position 7 to month 2. Any three of positions
// 1..6 are the other month-1 positions: C(6,3)=20 legal weavings.
// This uses enumeration of positions, not the tested DP recurrence.
proc probeWeaving() {
  var lengths = new list(int);
  lengths.pushBack(4);
  lengths.pushBack(4);
  var tested: WeavingCounter;
  tested.lengths = lengths;

  var oracleKeys: map(string, bool);
  var enumerated = 0;
  for a in 1..4 {
    for b in (a + 1)..5 {
      for c in (b + 1)..6 {
        var key = "";
        for position in 0..7 {
          if position == 0 || position == a ||
             position == b || position == c then
            key += "1";
          else
            key += "2";
        }
        oracleKeys.add(key, true);
        enumerated += 1;
      }
    }
  }
  check(enumerated == 20 && oracleKeys.size == 20,
        "Плетиво: незалежна комбінаційна кількість C(6,3)=20");
  check(tested.countAll() == enumerated,
        "Плетиво: DP проти прямого переліку");

  var seen: map(string, bool);
  for rank in 1..enumerated {
    const actual = tested.unrank1(new bigint(rank));
    var key = "";
    for monthId in actual do key += monthId:string;
    check(actual.size == 8 && oracleKeys.contains(key),
          "Плетиво: належність до незалежного набору, ранг=" + rank:string);
    check(!seen.contains(key),
          "Плетиво: відсутність дубля, ранг=" + rank:string);
    if !seen.contains(key) then seen.add(key, true);
    if rank == 1 then
      check(key == "11112222", "Плетиво: перший лексикографічний ранг");
    if rank == enumerated then
      check(key == "12221112", "Плетиво: останній лексикографічний ранг");
  }
  check(seen.size == oracleKeys.size,
        "Плетиво: всі і тільки допустимі перестановки");
}

// Previously documented scars serve ONLY as controls, not as new witnesses.
proc probeHistoricalControls() {
  for multiplier in -2..2 {
    const raw = new bigint(multiplier) * M;
    const legacy = oldRemainder(raw);
    check(legacy == 0 && applyPatch01(legacy) == M,
          "Контроль відкриття 01, множник=" + multiplier:string);
  }
  for delta in -4..4 {
    const day = FOUNDATION_DAY + delta;
    const legacy = oldDayTag(day);
    const distance = if delta < 0 then new bigint(-delta) else new bigint(delta);
    const directOracle = if delta < 0 then 2 * distance else 2 * distance + 1;
    check(applyPatch02(legacy, day) == directOracle,
          "Контроль латки 02, зміщення=" + delta:string);
    check((legacy != directOracle) == (delta >= 0),
          "Контроль історичного сліду 02, зміщення=" + delta:string);
  }
}


// A distinct family from the two-month C(6,3) fixture: three months of
// four days. Generate every 4+4+4 word lexicographically, then filter
// complete words by their opening and closing positions. This never invokes
// the implementation's legalMove or dynamic-programming state.
proc enumerateTripletWeavings(ref positions: [0..11] int,
                              step: int, used1: int, used2: int, used3: int,
                              ref oracle: list(string)) {
  if step == 12 {
    var first: [1..3] int;
    var last: [1..3] int;
    for p in 0..11 {
      const monthId = positions[p];
      if first[monthId] == 0 then first[monthId] = p + 1;
      last[monthId] = p + 1;
    }
    if first[1] < first[2] && first[2] < first[3] &&
       last[1] < last[2] && last[2] < last[3] {
      var key = "";
      for monthId in positions do key += monthId:string;
      oracle.pushBack(key);
    }
    return;
  }
  if used1 < 4 {
    positions[step] = 1;
    enumerateTripletWeavings(positions, step + 1, used1 + 1, used2, used3, oracle);
  }
  if used2 < 4 {
    positions[step] = 2;
    enumerateTripletWeavings(positions, step + 1, used1, used2 + 1, used3, oracle);
  }
  if used3 < 4 {
    positions[step] = 3;
    enumerateTripletWeavings(positions, step + 1, used1, used2, used3 + 1, oracle);
  }
}

proc probeThreeMonthWeaving() {
  var lengths = new list(int);
  for monthId in 1..3 do lengths.pushBack(4);
  var tested: WeavingCounter;
  tested.lengths = lengths;

  var positions: [0..11] int;
  var independentOracle = new list(string);
  enumerateTripletWeavings(positions, 0, 0, 0, 0, independentOracle);

  check(independentOracle.size == 1301,
        "Три місяці: прямий повний перелік 4+4+4 дає 1301");
  check(tested.countAll() == independentOracle.size,
        "Три місяці: кількість DP збігається з прямим переліком");
  for index0 in independentOracle.indices {
    const rank = index0 + 1;
    const actual = tested.unrank1(new bigint(rank));
    var key = "";
    for monthId in actual do key += monthId:string;
    check(actual.size == 12 && key == independentOracle[index0],
          "Три місяці: незалежний лексикографічний ранг=" + rank:string);
  }
}


// Separate asymmetrical month family 2+3+4: direct full-word enumeration.
// Do not derive the oracle from WeavingCounter.legalMove/countState/unrank1.
// The distinct first/last occurrence orders define validity.
proc enumerateUnequalTriplets(ref positions: [0..8] int,
                              step: int, used1: int, used2: int, used3: int,
                              ref candidateCount: int,
                              ref oracle: list(string)) {
  if step == 9 {
    candidateCount += 1;
    var first: [1..3] int;
    var last: [1..3] int;
    for p in 0..8 {
      const monthId = positions[p];
      if first[monthId] == 0 then first[monthId] = p + 1;
      last[monthId] = p + 1;
    }
    if first[1] < first[2] && first[2] < first[3] &&
       last[1] < last[2] && last[2] < last[3] {
      var key = "";
      for monthId in positions do key += monthId:string;
      oracle.pushBack(key);
    }
    return;
  }
  if used1 < 2 {
    positions[step] = 1;
    enumerateUnequalTriplets(positions, step + 1, used1 + 1,
                             used2, used3, candidateCount, oracle);
  }
  if used2 < 3 {
    positions[step] = 2;
    enumerateUnequalTriplets(positions, step + 1, used1,
                             used2 + 1, used3, candidateCount, oracle);
  }
  if used3 < 4 {
    positions[step] = 3;
    enumerateUnequalTriplets(positions, step + 1, used1,
                             used2, used3 + 1, candidateCount, oracle);
  }
}

proc probeUnequalThreeMonthWeaving() {
  var lengths = new list(int);
  lengths.pushBack(2);
  lengths.pushBack(3);
  lengths.pushBack(4);
  var tested: WeavingCounter;
  tested.lengths = lengths;

  var positions: [0..8] int;
  var independentOracle = new list(string);
  var candidates = 0;
  enumerateUnequalTriplets(positions, 0, 0, 0, 0,
                           candidates, independentOracle);

  check(candidates == 1260,
        "Нерівні місяці: повний перелік 2+3+4 має 1260 слів");
  check(independentOracle.size == 50,
        "Нерівні місяці: 50 законних слів за порядками відкриття і закриття");
  check(tested.countAll() == independentOracle.size,
        "Нерівні місяці: DP потужність проти прямого переліку");
  for index0 in independentOracle.indices {
    const rank = index0 + 1;
    const actual = tested.unrank1(new bigint(rank));
    var key = "";
    for monthId in actual do key += monthId:string;
    check(actual.size == 9 && key == independentOracle[index0],
          "Нерівні місяці: незалежний лексикографічний ранг=" + rank:string);
  }
}


// Four distinct months, two days each. All 8!/(2!)^4=2520
// multiset words are enumerated directly. A word is legal only when
// the first and last occurrences both follow month order 1,2,3,4.
// With two occurrences per month, the independent legal count is
// Catalan(4) = binomial(8,4) - binomial(8,3) = 14.
// No WeavingCounter transitions are consulted while generating the oracle.
proc enumerateFourShortMonthWeavings(ref positions: [0..7] int,
                                     step: int,
                                     used1: int, used2: int,
                                     used3: int, used4: int,
                                     ref candidateCount: int,
                                     ref oracle: list(string)) {
  if step == 8 {
    candidateCount += 1;
    var first: [1..4] int;
    var last: [1..4] int;
    for p in 0..7 {
      const monthId = positions[p];
      if first[monthId] == 0 then first[monthId] = p + 1;
      last[monthId] = p + 1;
    }
    if first[1] < first[2] && first[2] < first[3] && first[3] < first[4] &&
       last[1] < last[2] && last[2] < last[3] && last[3] < last[4] {
      var key = "";
      for monthId in positions do key += monthId:string;
      oracle.pushBack(key);
    }
    return;
  }

  if used1 < 2 {
    positions[step] = 1;
    enumerateFourShortMonthWeavings(positions, step + 1,
                                    used1 + 1, used2, used3, used4,
                                    candidateCount, oracle);
  }
  if used2 < 2 {
    positions[step] = 2;
    enumerateFourShortMonthWeavings(positions, step + 1,
                                    used1, used2 + 1, used3, used4,
                                    candidateCount, oracle);
  }
  if used3 < 2 {
    positions[step] = 3;
    enumerateFourShortMonthWeavings(positions, step + 1,
                                    used1, used2, used3 + 1, used4,
                                    candidateCount, oracle);
  }
  if used4 < 2 {
    positions[step] = 4;
    enumerateFourShortMonthWeavings(positions, step + 1,
                                    used1, used2, used3, used4 + 1,
                                    candidateCount, oracle);
  }
}

proc probeFourShortMonthWeavings() {
  var lengths = new list(int);
  for monthId in 1..4 do lengths.pushBack(2);
  var tested: WeavingCounter;
  tested.lengths = lengths;

  var positions: [0..7] int;
  var independentOracle = new list(string);
  var candidates = 0;
  enumerateFourShortMonthWeavings(positions, 0, 0, 0, 0, 0,
                                  candidates, independentOracle);

  check(candidates == 2520,
        "Чотири місяці: усі 2520 мультимножинних слів 2+2+2+2");
  check(independentOracle.size == 14,
        "Чотири місяці: незалежна кількість Catalan(4)=14");
  check(tested.countAll() == independentOracle.size,
        "Чотири місяці: DP-потужність проти прямого переліку");
  for index0 in independentOracle.indices {
    const rank = index0 + 1;
    const actual = tested.unrank1(new bigint(rank));
    var key = "";
    for monthId in actual do key += monthId:string;
    check(actual.size == 8 && key == independentOracle[index0],
          "Чотири місяці: незалежний лексикографічний ранг=" + rank:string);
  }
}



// Independent asymmetrical four-month family 2+2+3+3. The oracle is
// assembled by complete lexicographic word enumeration, then an independent
// first/last-occurrence filter. Production DP transitions are not consulted.
proc enumerateFourUnequalMonthWeavings(ref positions: [0..9] int,
                                       step: int,
                                       used1: int, used2: int,
                                       used3: int, used4: int,
                                       ref candidateCount: int,
                                       ref oracle: list(string)) {
  if step == 10 {
    candidateCount += 1;
    var first: [1..4] int;
    var last: [1..4] int;
    for p in 0..9 {
      const monthId = positions[p];
      if first[monthId] == 0 then first[monthId] = p + 1;
      last[monthId] = p + 1;
    }
    if first[1] < first[2] && first[2] < first[3] && first[3] < first[4] &&
       last[1] < last[2] && last[2] < last[3] && last[3] < last[4] {
      var key = "";
      for monthId in positions do key += monthId:string;
      oracle.pushBack(key);
    }
    return;
  }
  if used1 < 2 {
    positions[step] = 1;
    enumerateFourUnequalMonthWeavings(positions, step + 1,
                                      used1 + 1, used2, used3, used4,
                                      candidateCount, oracle);
  }
  if used2 < 2 {
    positions[step] = 2;
    enumerateFourUnequalMonthWeavings(positions, step + 1,
                                      used1, used2 + 1, used3, used4,
                                      candidateCount, oracle);
  }
  if used3 < 3 {
    positions[step] = 3;
    enumerateFourUnequalMonthWeavings(positions, step + 1,
                                      used1, used2, used3 + 1, used4,
                                      candidateCount, oracle);
  }
  if used4 < 3 {
    positions[step] = 4;
    enumerateFourUnequalMonthWeavings(positions, step + 1,
                                      used1, used2, used3, used4 + 1,
                                      candidateCount, oracle);
  }
}

proc probeFourUnequalMonthWeavings() {
  var lengths = new list(int);
  lengths.pushBack(2);
  lengths.pushBack(2);
  lengths.pushBack(3);
  lengths.pushBack(3);
  var tested: WeavingCounter;
  tested.lengths = lengths;

  var positions: [0..9] int;
  var independentOracle = new list(string);
  var candidates = 0;
  enumerateFourUnequalMonthWeavings(positions, 0, 0, 0, 0, 0,
                                    candidates, independentOracle);

  check(candidates == 25200,
        "Чотири нерівні місяці: прямий перелік 25200 слів 2+2+3+3");
  check(independentOracle.size == 97,
        "Чотири нерівні місяці: 97 законних слів за першими й останніми входженнями");
  check(tested.countAll() == independentOracle.size,
        "Чотири нерівні місяці: потужність DP проти прямого переліку");
  for index0 in independentOracle.indices {
    const rank = index0 + 1;
    const actual = tested.unrank1(new bigint(rank));
    var key = "";
    for monthId in actual do key += monthId:string;
    check(actual.size == 10 && key == independentOracle[index0],
          "Чотири нерівні місяці: незалежний лексикографічний ранг=" + rank:string);
  }
}


// Independent four-month bridge shape 2+3+3+2. Complete words are generated
// lexicographically by residual multiplicities; legality is calculated only
// from first/last occurrences in each finished word. The tested DP engine is
// never used to construct the expected ordered oracle.
proc enumerateFourBridgeMonthWeavings(ref positions: [0..9] int,
                                      step: int,
                                      used1: int, used2: int,
                                      used3: int, used4: int,
                                      ref candidateCount: int,
                                      ref oracle: list(string)) {
  if step == 10 {
    candidateCount += 1;
    var first: [1..4] int;
    var last: [1..4] int;
    for p in 0..9 {
      const monthId = positions[p];
      if first[monthId] == 0 then first[monthId] = p + 1;
      last[monthId] = p + 1;
    }
    if first[1] < first[2] && first[2] < first[3] && first[3] < first[4] &&
       last[1] < last[2] && last[2] < last[3] && last[3] < last[4] {
      var key = "";
      for monthId in positions do key += monthId:string;
      oracle.pushBack(key);
    }
    return;
  }
  if used1 < 2 {
    positions[step] = 1;
    enumerateFourBridgeMonthWeavings(positions, step + 1,
                                     used1 + 1, used2, used3, used4,
                                     candidateCount, oracle);
  }
  if used2 < 3 {
    positions[step] = 2;
    enumerateFourBridgeMonthWeavings(positions, step + 1,
                                     used1, used2 + 1, used3, used4,
                                     candidateCount, oracle);
  }
  if used3 < 3 {
    positions[step] = 3;
    enumerateFourBridgeMonthWeavings(positions, step + 1,
                                     used1, used2, used3 + 1, used4,
                                     candidateCount, oracle);
  }
  if used4 < 2 {
    positions[step] = 4;
    enumerateFourBridgeMonthWeavings(positions, step + 1,
                                     used1, used2, used3, used4 + 1,
                                     candidateCount, oracle);
  }
}

proc probeFourBridgeMonthWeavings() {
  var lengths = new list(int);
  lengths.pushBack(2);
  lengths.pushBack(3);
  lengths.pushBack(3);
  lengths.pushBack(2);
  var tested: WeavingCounter;
  tested.lengths = lengths;

  var positions: [0..9] int;
  var independentOracle = new list(string);
  var candidates = 0;
  enumerateFourBridgeMonthWeavings(positions, 0, 0, 0, 0, 0,
                                   candidates, independentOracle);

  check(candidates == 25200,
        "Чотири місяці 2+3+3+2: прямий перелік 25200 слів");
  check(independentOracle.size == 126,
        "Чотири місяці 2+3+3+2: незалежні 126 законних слів");
  check(tested.countAll() == independentOracle.size,
        "Чотири місяці 2+3+3+2: потужність DP проти повного переліку");
  for index0 in independentOracle.indices {
    const rank = index0 + 1;
    const actual = tested.unrank1(new bigint(rank));
    var key = "";
    for monthId in actual do key += monthId:string;
    check(actual.size == 10 && key == independentOracle[index0],
          "Чотири місяці 2+3+3+2: незалежний лексикографічний ранг=" + rank:string);
  }
}

proc main() {
  writeln("DISCOVERY03_RESEARCH_ONLY=YES");
  probeCutletCompositions(7, 2);
  probeCutletCompositions(8, 3);
  probeCutletCompositions(9, -1);
  probeBoundedCompositions(12, 4, 8);
  probeWeaving();
  probeThreeMonthWeaving();
  probeUnequalThreeMonthWeaving();
  probeFourShortMonthWeavings();
  probeFourUnequalMonthWeavings();
  probeFourBridgeMonthWeavings();
  probeHistoricalControls();
  writeln("DISCOVERY03_PROBE_CHECKS=", checks);
  writeln("DISCOVERY03_PROBE_FAILURES=", failures);
  if failures != 0 then halt("Дослідний оракул знайшов розбіжність; потрібна перевірка, а не автоматичне expected-red.");
  writeln("DISCOVERY03_PROBE_RESULT=NO_WITNESS_IN_TESTED_FAMILIES");
}
