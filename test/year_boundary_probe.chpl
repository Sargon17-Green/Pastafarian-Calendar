use BigInteger;
use IO;
use List;
use Time;
use ExactMath;
use SourceLanguageCatalog;
use NormativeOracle;

var checks = 0;
var failures = 0;

proc check(condition: bool, description: string) {
  checks += 1;
  if !condition {
    failures += 1;
    writeln("YEAR_BOUNDARY_FAIL=", description);
  }
}

proc sameWord(const ref a: list(int), const ref b: list(int)): bool {
  if a.size != b.size then return false;
  for i in 0..<a.size do if a[i] != b[i] then return false;
  return true;
}

// Production Chapel sparse counter is compared against the retained legacy
// algorithm. The fixture domain matches the independent branch-local
// occurrence-poset oracle, but no oracle implementation is reused here.
proc checkSparseWeavingFamily(const ref lens: list(int),
                              ref families: int,
                              ref rankChecks: int) {
  var legacy: WeavingCounter;
  var sparseCounter: SparseWeavingCounter;
  for length in lens {
    legacy.lengths.pushBack(length);
    sparseCounter.lengths.pushBack(length);
  }
  const legacyRoot = legacy.countAll();
  const sparseRoot = sparseCounter.countAll();
  check(legacyRoot == sparseRoot,
        "sparse/legacy root mismatch family=" + families:string);
  if legacyRoot == sparseRoot {
    const rootCount = legacyRoot:int;
    for r in 1..rootCount {
      const rank1 = new bigint(r);
      const legacyWord = legacy.unrank1(rank1);
      const sparseWord = sparseCounter.unrank1(rank1);
      check(sameWord(legacyWord,sparseWord),
            "sparse/legacy unrank mismatch family=" + families:string +
            " rank=" + r:string);
      check(sparseCounter.rank1(sparseWord) == rank1,
            "sparse rank roundtrip family=" + families:string +
            " rank=" + r:string);
      rankChecks += 2;
    }
  }
  families += 1;
}

proc checkSparseWeavingDifferential() {
  var families = 0;
  var rankChecks = 0;
  // All length-1..4 vectors with at most four months and at most eight days.
  // The original base-3 loop accidentally omitted length 4.
  for m in 1..4 {
    var possibilities = 1;
    for j in 1..m do possibilities *= 4;
    for raw in 0..<possibilities {
      var digits = raw;
      var lensArray: [1..m] int;
      var days = 0;
      for j in 1..m by -1 {
        lensArray[j] = 1 + digits%4;
        digits /= 4;
        days += lensArray[j];
      }
      if days > 8 then continue;
      var lens = new list(int);
      for j in 1..m do lens.pushBack(lensArray[j]);
      checkSparseWeavingFamily(lens,families,rankChecks);
    }
  }

  // Seven additional distinct boundary families, also used by the independent
  // branch-local oracle. Its two other extras are already in the base domain.
  var extra0 = new list(int);
  extra0.pushBack(2); extra0.pushBack(2); extra0.pushBack(2);
  extra0.pushBack(2); extra0.pushBack(2);
  checkSparseWeavingFamily(extra0,families,rankChecks);

  var extra1 = new list(int);
  extra1.pushBack(2); extra1.pushBack(3);
  extra1.pushBack(2); extra1.pushBack(2);
  checkSparseWeavingFamily(extra1,families,rankChecks);

  var extra2 = new list(int);
  extra2.pushBack(3); extra2.pushBack(2);
  extra2.pushBack(3); extra2.pushBack(2);
  checkSparseWeavingFamily(extra2,families,rankChecks);

  var extra3 = new list(int);
  extra3.pushBack(2); extra3.pushBack(2);
  extra3.pushBack(3); extra3.pushBack(3);
  checkSparseWeavingFamily(extra3,families,rankChecks);

  var extra4 = new list(int);
  extra4.pushBack(3); extra4.pushBack(3);
  extra4.pushBack(2); extra4.pushBack(2);
  checkSparseWeavingFamily(extra4,families,rankChecks);

  var extra5 = new list(int);
  extra5.pushBack(4); extra5.pushBack(3); extra5.pushBack(2);
  checkSparseWeavingFamily(extra5,families,rankChecks);

  var extra6 = new list(int);
  extra6.pushBack(2); extra6.pushBack(4); extra6.pushBack(3);
  checkSparseWeavingFamily(extra6,families,rankChecks);

  writeln("YEAR_BOUNDARY_SPARSE_DIFFERENTIAL_FAMILIES=",families);
  writeln("YEAR_BOUNDARY_SPARSE_DIFFERENTIAL_RANKS=",rankChecks);
  check(families == 137 && rankChecks == 1982,
        "sparse/legacy differential cardinality");
  if failures == 0 then writeln("YEAR_BOUNDARY_SPARSE_DIFFERENTIAL_RESULT=PASS");
  else writeln("YEAR_BOUNDARY_SPARSE_DIFFERENTIAL_RESULT=FAIL");
}

proc sameDate(const ref a: CalendarDateResult,
              const ref b: CalendarDateResult): bool {
  return a.yearNumber == b.yearNumber &&
         a.cutletName == b.cutletName &&
         a.dayInCutlet == b.dayInCutlet &&
         a.monthName == b.monthName &&
         a.dayInMonth == b.dayInMonth;
}

proc independentDate(ref gates: GateOracle,
                     const ref year: Year,
                     const ref structure: YearStructure,
                     const ref targetDay: bigint): CalendarDateResult {
  const offsetBig = targetDay - (year.openGateDay + 1);
  if offsetBig < 0 || offsetBig >= structure.monthWeaving.size then
    halt("Independent date oracle received a day outside the year.");
  const offset = offsetBig:int;

  var cutletIndex = -1;
  var dayInCutlet = 0;
  var cursorGate = year.openGateIndex;
  for i in structure.cutletPartition.indices {
    const nextGate = cursorGate + structure.cutletPartition[i];
    const firstCutletDay = gates.ensureGateIndex(cursorGate) + 1;
    const lastCutletDay = gates.ensureGateIndex(nextGate);
    if targetDay >= firstCutletDay && targetDay <= lastCutletDay {
      cutletIndex = i;
      dayInCutlet = (targetDay - firstCutletDay + 1):int;
      break;
    }
    cursorGate = nextGate;
  }
  if cutletIndex < 0 then halt("Independent date oracle found no cutlet.");

  const monthId = structure.monthWeaving[offset];
  var dayInMonth = 0;
  for p in 0..offset do
    if structure.monthWeaving[p] == monthId then dayInMonth += 1;

  var resultValue: CalendarDateResult;
  resultValue.yearNumber = year.number;
  resultValue.cutletName =
    cutletNameByCanonicalIndex(structure.cutletNameIndices[cutletIndex]);
  resultValue.dayInCutlet = new bigint(dayInCutlet);
  resultValue.monthName =
    monthNameByCanonicalIndex(structure.monthNameIndices[monthId - 1]);
  resultValue.dayInMonth = dayInMonth;
  return resultValue;
}

proc checkpoint(phaseName: string) {
  writeln("YEAR_BOUNDARY_PHASE=", phaseName);
  try! stdout.flush();
}

// Bounded research-only transpose window: after(i+1) is exactly zero
// outside its packed support. The skipped high cells have zero suffix;
// below the first supported predecessor index the suffix is constant.
// No production algorithm or normative acceptance is altered.
proc researchSparseTransposeWindowed(const ref after: SparseWeavingVec,
                                      n: int, k: int,
                                      spec: SparseWeavingGapSpec): SparseWeavingVec {
  var dense: [0..n] bigint;
  const lo = max(0, after.first - 1);
  const hi = min(n, after.first + after.values.size - 2);
  if hi < lo then return sparseWeavingPack(dense);
  var suffix = new bigint(0);
  const lowActive = max(spec.q, after.first-1);
  const highActive = hi;
  const useRecurrence = spec.fixedSum == 0 && spec.tail == 0 &&
                        k >= 8 && highActive-lowActive >= 8;
  var coefficient = new bigint(0);
  if useRecurrence then
    coefficient = sparseWeavingChooseBig(k-2+n-highActive,n-highActive);
  for i in lo..hi by -1 {
    const a = after.at(i+1);
    if a != 0 {
      if useRecurrence && i >= lowActive && i <= highActive {
        if coefficient != 0 then suffix += a*coefficient;
      } else {
        const factor = sparseWeavingWeight(i,n,k,spec);
        if factor != 0 then suffix += a*factor;
      }
    }
    dense[i] = suffix;
    if useRecurrence && i <= highActive && i > lowActive then
      coefficient = (coefficient * new bigint(k-1+n-i)) /
                    new bigint(n-i+1);
  }
  for i in 0..<lo do dense[i] = suffix;
  return sparseWeavingPack(dense);
}

// Independent small transfer-matrix oracle: count gap allocations by
// finite DP over individual gaps, not by binomial coefficients or suffix
// recurrence. Fixed prefix is already consumed; the first occupied gap and
// final gap must be positive, with the observed tail as an extra lower bound.
proc researchGapAllocationCount(i: int, n: int, k: int,
                                spec: SparseWeavingGapSpec): bigint {
  if i < spec.q {
    if spec.firstFixed != i || spec.fixedSum == 0 then return new bigint(0);
  } else {
    if spec.fixedSum != 0 || (i > spec.q && spec.tail > 0) then
      return new bigint(0);
  }
  if spec.fixedSum > k then return new bigint(0);
  var ways: [0..k] int;
  ways[spec.fixedSum] = 1;
  for j in spec.q..n {
    var nextWays: [0..k] int;
    var lower = 0;
    if j == spec.q then lower = spec.tail;
    if j == i || j == n then lower = max(lower,1);
    for used in 0..k {
      if ways[used] == 0 then continue;
      for count in lower..(k-used) {
        if j < i && count != 0 then continue;
        nextWays[used+count] += ways[used];
      }
    }
    ways = nextWays;
  }
  return new bigint(ways[k]);
}

proc checkResearchSparseTransposeMatrixOracle() {
  var cases = 0, entries = 0, recurrenceCases = 0;
  for n in 0..12 {
    for k in 1..10 {
      for q in 0..n {
        for shape in 0..5 {
          var spec: SparseWeavingGapSpec;
          spec.q = q;
          if shape == 1 then spec.tail = 2;
          if shape == 2 && q > 0 {
            spec.fixedSum = 1;
            spec.firstFixed = q-1;
          }
          if shape == 5 && q > 0 {
            spec.fixedSum = 2;
            spec.firstFixed = q/2;
            spec.tail = 1;
          }
          var adjoint: [0..n+k] bigint;
          if shape == 3 {
            adjoint[n+1] = new bigint(-7);
          } else if shape != 4 {
            for j in 0..n+k {
              if j%3 != 0 {
                if j%2 == 0 then adjoint[j] = new bigint(j+2);
                else adjoint[j] = new bigint(-(j+2));
              }
            }
          }
          const packed = sparseWeavingPack(adjoint);
          const actual = researchSparseTransposeWindowed(packed,n,k,spec);
          const lowActive = max(q,packed.first-1);
          const highActive = min(n,packed.first+packed.values.size-2);
          if spec.fixedSum == 0 && spec.tail == 0 && k >= 8 &&
             highActive-lowActive >= 8 then recurrenceCases += 1;
          // Explicit column-by-column matrix multiplication against the
          // original dense adjoint; no call to either transpose or weight
          // implementation to construct the oracle.
          var columnWeights: [0..n] bigint;
          for i in 0..n do
            columnWeights[i] = researchGapAllocationCount(i,n,k,spec);
          var expected: [0..n] bigint;
          for p in 0..n {
            for i in 0..n {
              if p <= i then expected[p] += adjoint[i+1]*columnWeights[i];
            }
            if actual.at(p) != expected[p] then
              halt("Independent transpose matrix mismatch n=",n,
                   " k=",k," q=",q," shape=",shape," p=",p);
            entries += 1;
          }
          var first = -1, last = -1;
          for p in 0..n {
            if expected[p] != 0 {
              if first < 0 then first = p;
              last = p;
            }
          }
          if first < 0 {
            if actual.values.size != 0 then halt("Nonempty zero transpose");
          } else if actual.first != first ||
                    actual.values.size != last-first+1 then
            halt("Independent transpose packing mismatch");
          cases += 1;
        }
      }
    }
  }
  if cases != 5460 || entries != 49140 || recurrenceCases != 75 then
    halt("Independent transpose matrix oracle cardinality mismatch");
  writeln("RESEARCH_TRANSPOSE_MATRIX_CASES=",cases);
  writeln("RESEARCH_TRANSPOSE_MATRIX_ENTRIES=",entries);
  writeln("RESEARCH_TRANSPOSE_MATRIX_RECURRENCE_CASES=",recurrenceCases);
  writeln("RESEARCH_TRANSPOSE_MATRIX_RESULT=EXACT_INDEPENDENT_MATRIX_PASS");
  try! stdout.flush();
}

proc checkResearchSparseTransposeWindowedFinite() {
  var cases = 0;
  // Small exhaustive dimensions with deterministic sparse, dense and empty
  // adjoints; include zero/tail/fixed specifications. Differential only:
  // this compares against the existing Chapel primitive, not an
  // independent mathematical oracle or a whole-year performance gate.
  for n in 0..9 {
    for k in 1..6 {
      for shape in 0..4 {
        var dense: [0..n+k] bigint;
        if shape != 4 {
          for t in 0..n+k {
            if (t+shape)%4 != 0 then
              dense[t] = new bigint((t+1)*(shape+2));
          }
        }
        const after = sparseWeavingPack(dense);
        for q in 0..min(3,n) {
          var spec: SparseWeavingGapSpec;
          spec.q = q;
          if shape == 1 then spec.tail = 2;
          if shape == 2 {
            spec.fixedSum = 1;
            if q > 0 then spec.firstFixed = q-1;
          }
          if shape == 3 {
            spec.tail = 1;
            if q > 0 then spec.firstFixed = q-1;
          }
          const baseline = sparseWeavingTranspose(after,n,k,spec);
          const optimized = researchSparseTransposeWindowed(after,n,k,spec);
          if baseline.first != optimized.first ||
             baseline.values.size != optimized.values.size then
            halt("Windowed transpose finite shape mismatch n=",n,
                 " k=",k," shape=",shape," q=",q);
          for t in 0..<baseline.values.size {
            if baseline.values[t] != optimized.values[t] then
              halt("Windowed transpose finite mismatch n=",n,
                   " k=",k," shape=",shape," q=",q," t=",t);
          }
          cases += 1;
        }
      }
    }
  }
  writeln("RESEARCH_WINDOWED_TRANSPOSE_FINITE_CASES=",cases);
  writeln("RESEARCH_WINDOWED_TRANSPOSE_FINITE_RESULT=EXACT_DIFFERENTIAL_PASS");
  try! stdout.flush();
}

// Research-only non-mutating attribution for one candidate-block snapshot.
// Reconstructs the current candidate partition from the same Chapel primitives
// and compares every exact bigint block with production. This is deliberately
// NOT an independent mathematical oracle, speedup claim, or Stage 6 gate.
// Research-only singleton specialization. A fixed positive prefix permits
// only firstFixed; a positive tail without a fixed prefix permits only q.
// Other specs use the unchanged production transfer. No production promotion.
proc researchForwardSingletonEligible(spec: SparseWeavingGapSpec): bool {
  return spec.fixedSum > 0 || (spec.tail > 0 && spec.firstFixed < 0);
}

proc researchSparseForwardSingleton(const ref previous: SparseWeavingVec,
                                    n: int, k: int,
                                    spec: SparseWeavingGapSpec): SparseWeavingVec {
  if !researchForwardSingletonEligible(spec) then
    return sparseWeavingTransfer(previous,n,k,spec);
  var result: SparseWeavingVec;
  var i = spec.q;
  if spec.fixedSum > 0 then i = spec.firstFixed;
  if i < 0 || i > n || (spec.fixedSum > 0 && i >= spec.q) then return result;
  var cumulative = new bigint(0);
  const count = max(0,min(previous.values.size,i-previous.first+1));
  for t in 0..<count do cumulative += previous.values[t];
  if cumulative == 0 then return result;
  const value = cumulative*sparseWeavingWeight(i,n,k,spec);
  if value != 0 {
    result.first = i+1;
    result.values.pushBack(value);
  }
  return result;
}


// Bounded research-only forward transfer for the unconstrained suffix case.
// The production kernel allocates and packs [0..n+k], although its first
// possible nonzero output is firstActive+1 and its last is n+1. Restrict both
// the recurrence loop and dense packing domain to that exact output window.
// Constrained fixed-prefix/tail specs deliberately fall back unchanged.
proc researchSparseForwardWindowedEligible(
    const ref previous: SparseWeavingVec, n: int,
    spec: SparseWeavingGapSpec): bool {
  return spec.fixedSum == 0 && spec.tail == 0 && spec.firstFixed < 0 &&
         previous.values.size > 0 && max(spec.q,previous.first) <= n;
}

proc researchSparseForwardWindowed(const ref previous: SparseWeavingVec,
                                   n: int, k: int,
                                   spec: SparseWeavingGapSpec): SparseWeavingVec {
  if !researchSparseForwardWindowedEligible(previous,n,spec) then
    return sparseWeavingTransfer(previous,n,k,spec);

  const firstActive = max(spec.q,previous.first);
  var cumulative = new bigint(0);
  const prefixCount = max(0,min(previous.values.size,
                                firstActive-previous.first));
  for t in 0..<prefixCount do cumulative += previous.values[t];

  var dense: [firstActive+1..n+1] bigint;
  const useRecurrence = k >= 8 && n-firstActive >= 8;
  var coefficient = new bigint(0);
  if useRecurrence then
    coefficient = sparseWeavingChooseBig(k-2+n-firstActive,n-firstActive);

  for i in firstActive..n {
    cumulative += previous.at(i);
    if cumulative != 0 {
      if useRecurrence {
        if coefficient != 0 then dense[i+1] = cumulative*coefficient;
      } else {
        const factor = sparseWeavingWeight(i,n,k,spec);
        if factor != 0 then dense[i+1] = cumulative*factor;
      }
    }
    if useRecurrence && i < n then
      coefficient = (coefficient * new bigint(n-i)) /
                    new bigint(k-2+n-i);
  }
  return sparseWeavingPack(dense);
}

proc checkResearchForwardSingletonMatrix() {
  var cases = 0, entries = 0, singletonCases = 0, windowedCases = 0;
  for n in 0..12 {
    for k in 1..10 {
      for q in 0..n {
        for shape in 0..5 {
          var spec: SparseWeavingGapSpec;
          spec.q = q;
          if shape == 1 then spec.tail = 2;
          if shape == 2 && q > 0 {
            spec.fixedSum = 1;
            spec.firstFixed = q-1;
          }
          if shape == 5 && q > 0 {
            spec.fixedSum = 2;
            spec.firstFixed = q/2;
            spec.tail = 1;
          }
          var input: [0..n] bigint;
          if shape == 3 then input[n] = new bigint(-7);
          else if shape != 4 {
            for i in 0..n {
              if i%3 != 0 {
                if i%2 == 0 then input[i] = new bigint(i+2);
                else input[i] = new bigint(-(i+2));
              }
            }
          }
          const packed = sparseWeavingPack(input);
          const actual = researchSparseForwardSingleton(packed,n,k,spec);
          const windowed = researchSparseForwardWindowed(packed,n,k,spec);
          const baseline = sparseWeavingTransfer(packed,n,k,spec);
          if researchForwardSingletonEligible(spec) then singletonCases += 1;
          if researchSparseForwardWindowedEligible(packed,n,spec) then
            windowedCases += 1;
          var expected: [0..n+k] bigint;
          for i in 0..n {
            const w = researchGapAllocationCount(i,n,k,spec);
            for p in 0..i do expected[i+1] += input[p]*w;
          }
          for t in 0..n+k {
            if actual.at(t) != expected[t] ||
               baseline.at(t) != expected[t] ||
               windowed.at(t) != expected[t] then
              halt("Forward transfer matrix mismatch n=",n," k=",k,
                   " q=",q," shape=",shape," t=",t);
            entries += 1;
          }
          if actual.first != baseline.first ||
             actual.values.size != baseline.values.size then
            halt("Forward singleton packing mismatch");
          if windowed.first != baseline.first ||
             windowed.values.size != baseline.values.size then
            halt("Forward windowed packing mismatch");
          cases += 1;
        }
      }
    }
  }
  // Independent fixture enumeration: shape 0 contributes 900 eligible
  // cases, shape 3's terminal singleton contributes 910, and q=0 shapes 2
  // and 5 contribute 120 each. The earlier 1140 expectation omitted shape 3.
  writeln("RESEARCH_FORWARD_MATRIX_CASES=",cases);
  writeln("RESEARCH_FORWARD_MATRIX_ENTRIES=",entries);
  writeln("RESEARCH_FORWARD_SINGLETON_CASES=",singletonCases);
  writeln("RESEARCH_FORWARD_WINDOWED_ELIGIBLE_CASES=",windowedCases);
  if cases != 5460 || entries != 79170 ||
     singletonCases != 2470 || windowedCases != 2050 then
    halt("Forward independent matrix oracle cardinality mismatch: cases=",
         cases," entries=",entries," singletonCases=",singletonCases,
         " windowedCases=",windowedCases," expected=5460/79170/2470/2050");
  writeln("RESEARCH_FORWARD_MATRIX_RESULT=EXACT_INDEPENDENT_MATRIX_PASS");
  writeln("RESEARCH_FORWARD_WINDOWED_MATRIX_RESULT=EXACT_INDEPENDENT_MATRIX_PASS");
  try! stdout.flush();
}

proc profileResearchForwardWindowed(const ref lens: [?D] int,
                                      const ref states: [?S] SparseWeavingVec,
                                      const ref sizes: [?Z] int,
                                      const ref specs: [?Q] SparseWeavingGapSpec,
                                      chosen: int, step: int) {
  var baselineSeconds = 0.0, windowedSeconds = 0.0;
  var calls = 0, optimizedCalls = 0;
  for j in max(2,chosen)..D.high {
    var baseline: SparseWeavingVec = new SparseWeavingVec();
    var windowed: SparseWeavingVec = new SparseWeavingVec();
    var bt: stopwatch;
    var wt: stopwatch;
    if j%2 == 0 {
      bt.start();
      baseline = sparseWeavingTransfer(states[j-1],sizes[j-1],lens[j],specs[j]);
      bt.stop();
      wt.start();
      windowed = researchSparseForwardWindowed(states[j-1],sizes[j-1],
                                                 lens[j],specs[j]);
      wt.stop();
    } else {
      wt.start();
      windowed = researchSparseForwardWindowed(states[j-1],sizes[j-1],
                                                 lens[j],specs[j]);
      wt.stop();
      bt.start();
      baseline = sparseWeavingTransfer(states[j-1],sizes[j-1],lens[j],specs[j]);
      bt.stop();
    }
    if baseline.first != states[j].first ||
       baseline.values.size != states[j].values.size ||
       windowed.first != baseline.first ||
       windowed.values.size != baseline.values.size then
      halt("Windowed forward snapshot packing mismatch step=",step,
           " month=",j);
    for t in 0..<baseline.values.size {
      if baseline.values[t] != states[j].values[t] ||
         windowed.values[t] != baseline.values[t] then
        halt("Windowed forward snapshot value mismatch step=",step,
             " month=",j," index=",t);
    }
    const optimized = researchSparseForwardWindowedEligible(
      states[j-1],sizes[j-1],specs[j]);
    writeln("RESEARCH_WINDOWED_FORWARD_COST step=",step," month=",j,
            " n=",sizes[j-1]," k=",lens[j],
            " inputFirst=",states[j-1].first,
            " inputSupport=",states[j-1].values.size,
            " outputFirst=",baseline.first,
            " outputSupport=",baseline.values.size,
            " q=",specs[j].q," fixedSum=",specs[j].fixedSum,
            " firstFixed=",specs[j].firstFixed," tail=",specs[j].tail,
            " optimized=",optimized,
            " baselineSeconds=",bt.elapsed(),
            " windowedSeconds=",wt.elapsed());
    baselineSeconds += bt.elapsed();
    windowedSeconds += wt.elapsed();
    calls += 1;
    if optimized then optimizedCalls += 1;
  }
  writeln("RESEARCH_WINDOWED_FORWARD_STEP_",step,"_CALLS=",calls);
  writeln("RESEARCH_WINDOWED_FORWARD_STEP_",step,"_OPTIMIZED_CALLS=",optimizedCalls);
  writeln("RESEARCH_WINDOWED_FORWARD_STEP_",step,"_BASELINE_SECONDS=",baselineSeconds);
  writeln("RESEARCH_WINDOWED_FORWARD_STEP_",step,"_WINDOWED_SECONDS=",windowedSeconds);
  writeln("RESEARCH_WINDOWED_FORWARD_STEP_",step,"_RESULT=EXACT_SELECTED_SUFFIX_MATCH_RESEARCH_ONLY");
  try! stdout.flush();
}

proc profileSparseCandidateSubphases(const ref lens: [?D] int,
                                     const ref states: [?S] SparseWeavingVec,
                                     const ref sizes: [?Z] int,
                                     const ref specs: [?Q] SparseWeavingGapSpec,
                                     const ref used: [?U] int,
                                     opened: int, closed: int,
                                     const ref total: bigint,
                                     step: int) {
  const m = D.high;
  const expected = sparseWeavingCandidateBlocks(lens, states, sizes, specs,
                                                 used, opened, closed, total);
  var observed: [D] bigint;
  var identity: [0..sizes[m]] bigint;
  for i in 0..sizes[m] do identity[i] = new bigint(1);
  var adjoint = sparseWeavingPack(identity);
  var transposeSeconds = 0.0;
  var windowedSeconds = 0.0;
  var windowedCalls = 0;
  var trialSeconds = 0.0;
  var dotSeconds = 0.0;
  var transposeCalls = 0;
  var trialCalls = 0;
  var dotCalls = 0;
  if m >= 2 {
    for j in 2..m by -1 {
      if sparseWeavingEligible(j, lens, used, opened, closed) {
        const own = sparseWeavingExtendSpec(specs[j], j, j);
        var trialTimer: stopwatch;
        trialTimer.start();
        const trial = sparseWeavingTransfer(states[j-1], sizes[j-1],
                                             lens[j], own);
        trialTimer.stop();
        trialSeconds += trialTimer.elapsed();
        trialCalls += 1;
        var dotTimer: stopwatch;
        dotTimer.start();
        observed[j] = sparseWeavingDot(adjoint, trial);
        dotTimer.stop();
        dotSeconds += dotTimer.elapsed();
        dotCalls += 1;
      }
      const older = sparseWeavingExtendSpec(specs[j], j, 1);
      var transposeTimer: stopwatch;
      transposeTimer.start();
      const baselineAdjoint = sparseWeavingTranspose(adjoint, sizes[j-1],
                                                     lens[j], older);
      transposeTimer.stop();
      transposeSeconds += transposeTimer.elapsed();
      var windowedTimer: stopwatch;
      windowedTimer.start();
      const windowedAdjoint = researchSparseTransposeWindowed(adjoint,
                                                    sizes[j-1], lens[j], older);
      windowedTimer.stop();
      windowedSeconds += windowedTimer.elapsed();
      windowedCalls += 1;
      if baselineAdjoint.first != windowedAdjoint.first ||
         baselineAdjoint.values.size != windowedAdjoint.values.size then
        halt("Windowed transpose snapshot shape mismatch step=",step,
             " month=",j);
      for t in 0..<baselineAdjoint.values.size {
        if baselineAdjoint.values[t] != windowedAdjoint.values[t] then
          halt("Windowed transpose snapshot value mismatch step=",step,
               " month=",j," index=",t);
      }
      adjoint = baselineAdjoint;
      transposeCalls += 1;
    }
  }
  if sparseWeavingEligible(1, lens, used, opened, closed) {
    var dotTimer: stopwatch;
    dotTimer.start();
    observed[1] = sparseWeavingDot(adjoint, states[1]);
    dotTimer.stop();
    dotSeconds += dotTimer.elapsed();
    dotCalls += 1;
  }
  var partition = new bigint(0);
  for j in D {
    if observed[j] != expected[j] then
      halt("Candidate subphase diagnostic exact block mismatch at step ",
           step, " month ", j);
    partition += observed[j];
  }
  if partition != total then
    halt("Candidate subphase diagnostic exact partition mismatch at step ",
         step);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_TRANSPOSE_SECONDS=", transposeSeconds);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_WINDOWED_SECONDS=", windowedSeconds);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_WINDOWED_CALLS=", windowedCalls);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_WINDOWED_RESULT=EXACT_TRANSPOSE_MATCH_RESEARCH_ONLY");
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_TRIAL_SECONDS=", trialSeconds);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_DOT_SECONDS=", dotSeconds);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_TRANSPOSE_CALLS=", transposeCalls);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_TRIAL_CALLS=", trialCalls);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_DOT_CALLS=", dotCalls);
  writeln("YEAR_BOUNDARY_CANDIDATE_SAMPLE_STEP_", step,
          "_RESULT=EXACT_BLOCK_MATCH_RESEARCH_ONLY");
  try! stdout.flush();
}

// Source-fresh, bounded attribution of production sparse unrank steps.
// Calls the unchanged production sparse primitives; it is not an oracle or
// a substitute for full chooseMonthWeaving / calendarDate acceptance.
proc probeSparseWeavingPrefix(const ref monthLengths: list(int),
                              const ref expectedRoot: bigint,
                              const ref selectedRank: bigint) {
  const m = monthLengths.size;
  var lens: [1..m] int;
  for i in 1..m do lens[i] = monthLengths[i-1];
  var specs: [1..m] SparseWeavingGapSpec;
  var states: [1..m] SparseWeavingVec;
  var sizes: [1..m] int;
  var total = sparseWeavingSetup(lens, states, sizes, specs);
  check(total == expectedRoot, "diagnostic prefix root matches source-fresh root");
  if total != expectedRoot then return;
  check(selectedRank >= 1 && selectedRank <= total,
        "diagnostic selected rank within exact root");
  if selectedRank < 1 || selectedRank > total then return;

  var residual = selectedRank - new bigint(1);
  var used: [1..m] int;
  var opened = 0, closed = 0;
  var completed = 0;
  // Bounded source-fresh phase attribution, with production code unchanged.
  var candidateSeconds = 0.0;
  var forwardSeconds = 0.0;
  var candidateCalls = 0;
  var transposeCalls = 0;
  var trialForwardCalls = 0;
  var takeForwardCalls = 0;
  var prefixTimer: stopwatch;
  prefixTimer.start();
  for step in 1..min(32, sizes[m]) {
    var candidateTimer: stopwatch;
    candidateTimer.start();
    const blocks = sparseWeavingCandidateBlocks(lens, states, sizes, specs,
                                                 used, opened, closed, total);
    candidateTimer.stop();
    candidateSeconds += candidateTimer.elapsed();
    candidateCalls += 1;
    transposeCalls += max(0, m-1);
    for candidate in 2..m {
      if sparseWeavingEligible(candidate, lens, used, opened, closed) then
        trialForwardCalls += 1;
    }
    var chosen = 0;
    for c in 1..m {
      if residual >= blocks[c] then residual -= blocks[c];
      else {
        chosen = c;
        var forwardTimer: stopwatch;
        forwardTimer.start();
        sparseWeavingTake(c, lens, states, sizes, specs, used,
                          opened, closed, total, blocks[c]);
        forwardTimer.stop();
        forwardSeconds += forwardTimer.elapsed();
        takeForwardCalls += max(0, m - max(2,c) + 1);
        break;
      }
    }
    if chosen == 0 then halt("Diagnostic sparse prefix failed to select a block");
    completed = step;
    if step == 1 || step == 4 || step == 8 || step == 16 || step == 32 {
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_SECONDS=", prefixTimer.elapsed());
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_BLOCKS_SECONDS=", candidateSeconds);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_TAKE_SECONDS=", forwardSeconds);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_TRANSPOSE_CALLS=", transposeCalls);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_TRIAL_FORWARD_CALLS=", trialForwardCalls);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_TAKE_FORWARD_CALLS=", takeForwardCalls);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_LAST_MONTH=", chosen);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_OPENED=", opened);
      writeln("YEAR_BOUNDARY_PREFIX_STEP_", step, "_CLOSED=", closed);
      try! stdout.flush();
    }
    // Stop the prefix stopwatch while sampling, so the prior 32-step
    // baseline excludes diagnostic measurement overhead.
    if step == 1 || step == 8 || step == 16 || step == 32 {
      prefixTimer.stop();
      profileSparseCandidateSubphases(lens, states, sizes, specs, used,
                                      opened, closed, total, step);
      profileResearchForwardWindowed(lens, states, sizes, specs, chosen, step);
      prefixTimer.start();
    }
    if prefixTimer.elapsed() >= 30.0 then break;
  }
  prefixTimer.stop();
  writeln("YEAR_BOUNDARY_PREFIX_COMPLETED_STEPS=", completed);
  writeln("YEAR_BOUNDARY_PREFIX_ELAPSED_SECONDS=", prefixTimer.elapsed());
  writeln("YEAR_BOUNDARY_PREFIX_CANDIDATE_SECONDS=", candidateSeconds);
  writeln("YEAR_BOUNDARY_PREFIX_FORWARD_SECONDS=", forwardSeconds);
  writeln("YEAR_BOUNDARY_PREFIX_CANDIDATE_CALLS=", candidateCalls);
  writeln("YEAR_BOUNDARY_PREFIX_TRANSPOSE_CALLS=", transposeCalls);
  writeln("YEAR_BOUNDARY_PREFIX_TRIAL_FORWARD_CALLS=", trialForwardCalls);
  writeln("YEAR_BOUNDARY_PREFIX_TAKE_FORWARD_CALLS=", takeForwardCalls);
  writeln("YEAR_BOUNDARY_PREFIX_MAX_STEPS=32");
  writeln("YEAR_BOUNDARY_PREFIX_SOFT_BUDGET_SECONDS=30");
  writeln("YEAR_BOUNDARY_PREFIX_RESULT=RESEARCH_ONLY");
  // Research-only isolated transfer spectrum at the frozen bounded prefix
  // checkpoint. Replaying transitions does not update any production state,
  // and is timed only AFTER prefixTimer stops, preserving its baseline.
  // Exact vectors are compared outside timing; this is not an independent
  // algorithm oracle or Stage 6 acceptance evidence.
  var replaySeconds = 0.0;
  var replayCount = 0;
  writeln("YEAR_BOUNDARY_TRANSFER_REPLAY_PREFIX_STEPS=", completed);
  for j in 2..m {
    var replayTimer: stopwatch;
    replayTimer.start();
    const replayState = sparseWeavingTransfer(states[j-1], sizes[j-1],
                                               lens[j], specs[j]);
    replayTimer.stop();
    const elapsed = replayTimer.elapsed();
    if replayState.first != states[j].first ||
       replayState.values.size != states[j].values.size then
      halt("Year boundary transfer replay shape mismatch at month ", j);
    for t in 0..<replayState.values.size {
      if replayState.values[t] != states[j].values[t] then
        halt("Year boundary transfer replay value mismatch at month ", j,
             " index ", t);
    }
    replaySeconds += elapsed;
    replayCount += 1;
    writeln("YEAR_BOUNDARY_TRANSFER_REPLAY_MONTH_", j, "_SECONDS=", elapsed);
    writeln("YEAR_BOUNDARY_TRANSFER_REPLAY_MONTH_", j, "_SUPPORT=", replayState.values.size);
  }
  writeln("YEAR_BOUNDARY_TRANSFER_REPLAY_CALLS=", replayCount);
  writeln("YEAR_BOUNDARY_TRANSFER_REPLAY_TOTAL_SECONDS=", replaySeconds);
  writeln("YEAR_BOUNDARY_TRANSFER_REPLAY_RESULT=EXACT_STATE_MATCH_RESEARCH_ONLY");
  try! stdout.flush();
}

proc main() {
  checkResearchSparseTransposeWindowedFinite();
  checkResearchSparseTransposeMatrixOracle();
  checkResearchForwardSingletonMatrix();
  checkSparseWeavingDifferential();
  const calculationDay = FOUNDATION_DAY;
  var gates: GateOracle;
  checkpoint("YEAR5000_BEGIN");
  const year = gates.year5000(calculationDay);
  checkpoint("YEAR5000_END");
  const firstDay = year.openGateDay + 1;
  const lastDay = year.closeGateDay;
  const yearLength = (lastDay - year.openGateDay):int;
  const gateGapCount = year.closeGateIndex - year.openGateIndex;

  check(year.openGateDay < calculationDay && calculationDay <= year.closeGateDay,
        "year5000 interval must contain calculationDay");
  check(year.openGateIndex < 0 && year.closeGateIndex >= 0,
        "FOUNDATION_DAY gate index must lie at or after open gate");

  checkpoint("STRUCTURE_BEGIN");
  // Exact production call order; diagnostic checkpoints do not change acceptance.
  var structure: YearStructure;
  checkpoint("STRUCTURE_SAUCE_BEGIN");
  const r = sauce(calculationDay, firstDay);
  checkpoint("STRUCTURE_SAUCE_END");
  checkpoint("STRUCTURE_CUTLET_COUNT_BEGIN");
  structure.cutletCount = chooseCutletCount(r, year);
  checkpoint("STRUCTURE_CUTLET_COUNT_END");
  checkpoint("STRUCTURE_CUTLET_PARTITION_BEGIN");
  structure.cutletPartition = chooseCutletPartition(gates, calculationDay, r, year, structure.cutletCount);
  checkpoint("STRUCTURE_CUTLET_PARTITION_END");
  checkpoint("STRUCTURE_CUTLET_NAMES_BEGIN");
  structure.cutletNameIndices = chooseCutletNameIndices(r, structure.cutletCount);
  checkpoint("STRUCTURE_CUTLET_NAMES_END");
  checkpoint("STRUCTURE_MATERIALIZE_CUTLETS_BEGIN");
  structure.cutlets = materializeCutlets(gates, year, structure.cutletPartition, structure.cutletNameIndices);
  checkpoint("STRUCTURE_MATERIALIZE_CUTLETS_END");
  checkpoint("STRUCTURE_MONTH_COUNT_BEGIN");
  structure.monthCount = chooseMonthCount(r, year);
  checkpoint("STRUCTURE_MONTH_COUNT_END");
  checkpoint("STRUCTURE_MONTH_LENGTHS_BEGIN");
  structure.monthLengths = chooseMonthLengths(r, year, structure.monthCount);
  checkpoint("STRUCTURE_MONTH_LENGTHS_END");
  // Bounded snapshot of the exact input to the expensive weaving DP.
  // The product counts possible remaining vectors, not reachable memo states.
  var weavingInputTotal = 0;
  var weavingRemainingVectors = new bigint(1);
  var weavingGuaranteedReachable = new bigint(1);
  writeln("YEAR_BOUNDARY_WEAVING_MONTH_COUNT=", structure.monthCount);
  for i in 0..#structure.monthCount {
    const monthLength = structure.monthLengths[i];
    weavingInputTotal += monthLength;
    weavingRemainingVectors *= new bigint(monthLength + 1);
    weavingGuaranteedReachable *= new bigint(monthLength - 1);
    writeln("YEAR_BOUNDARY_WEAVING_LENGTH_", i + 1, "=", monthLength);
  }
  writeln("YEAR_BOUNDARY_WEAVING_INPUT_TOTAL=", weavingInputTotal);
  writeln("YEAR_BOUNDARY_WEAVING_POSSIBLE_REMAINING_VECTORS=", weavingRemainingVectors);
  // Constructive lower bound: all months opened, none closed, each remaining in 1..length-1.
  writeln("YEAR_BOUNDARY_WEAVING_GUARANTEED_REACHABLE_STATES=", weavingGuaranteedReachable);
  try! stdout.flush();
  // Research-only source-fresh setup attribution. Do not treat this as
  // production Stage 6 acceptance or as a replacement for chooseMonthWeaving.
  // Measure the same sparse root setup on the exact production month vector,
  // then preserve the original production call below unchanged.
  checkpoint("STRUCTURE_MONTH_WEAVING_ROOT_SETUP_DIAGNOSTIC_BEGIN");
  var setupDiagnostic: SparseWeavingCounter;
  setupDiagnostic.lengths = structure.monthLengths;
  var setupTimer: stopwatch;
  setupTimer.start();
  const diagnosticRoot = setupDiagnostic.countAll();
  setupTimer.stop();
  check(diagnosticRoot > 0, "source-fresh sparse weaving root is positive");
  writeln("YEAR_BOUNDARY_ROOT_SETUP_DIAGNOSTIC_SECONDS=", setupTimer.elapsed());
  writeln("YEAR_BOUNDARY_ROOT_SETUP_DIAGNOSTIC_MONTHS=", structure.monthCount);
  writeln("YEAR_BOUNDARY_ROOT_SETUP_DIAGNOSTIC_DAYS=", weavingInputTotal);
  writeln("YEAR_BOUNDARY_ROOT_SETUP_DIAGNOSTIC_RESULT=RESEARCH_ONLY");
  try! stdout.flush();
  checkpoint("STRUCTURE_MONTH_WEAVING_ROOT_SETUP_DIAGNOSTIC_END");
  checkpoint("STRUCTURE_MONTH_WEAVING_RANK_SELECTION_DIAGNOSTIC_BEGIN");
  var rankTimer: stopwatch;
  rankTimer.start();
  const rankStream = askBowl(r, 4, SEAL_MONTH_WEAVING);
  const selectedRank = chooseRank(rankStream, diagnosticRoot);
  rankTimer.stop();
  check(selectedRank >= 1 && selectedRank <= diagnosticRoot,
        "source-fresh production rank is within sparse root");
  writeln("YEAR_BOUNDARY_RANK_SELECTION_SECONDS=", rankTimer.elapsed());
  writeln("YEAR_BOUNDARY_RANK_SELECTION_RESULT=RESEARCH_ONLY");
  try! stdout.flush();
  checkpoint("STRUCTURE_MONTH_WEAVING_RANK_SELECTION_DIAGNOSTIC_END");
  checkpoint("STRUCTURE_MONTH_WEAVING_PREFIX_DIAGNOSTIC_BEGIN");
  probeSparseWeavingPrefix(structure.monthLengths, diagnosticRoot, selectedRank);
  checkpoint("STRUCTURE_MONTH_WEAVING_PREFIX_DIAGNOSTIC_END");
  checkpoint("STRUCTURE_MONTH_WEAVING_BEGIN");
  structure.monthWeaving = chooseMonthWeaving(r, structure.monthLengths);
  checkpoint("STRUCTURE_MONTH_WEAVING_END");
  checkpoint("STRUCTURE_MONTH_NAMES_BEGIN");
  structure.monthNameIndices = chooseMonthNameIndices(r, structure.monthCount);
  checkpoint("STRUCTURE_MONTH_NAMES_END");
  checkpoint("STRUCTURE_END");
  check(structure.cutletCount >= 6 && structure.cutletCount <= 17,
        "cutlet count range");
  check(structure.cutletPartition.size == structure.cutletCount,
        "partition count matches cutlet count");
  check(structure.cutletNameIndices.size == structure.cutletCount,
        "cutlet name count matches cutlet count");
  check(structure.cutlets.size == structure.cutletCount,
        "materialized cutlet count matches");
  check(structure.monthCount >= 3 && structure.monthCount <= 47,
        "month count range");
  check(structure.monthLengths.size == structure.monthCount,
        "month length count matches month count");
  check(structure.monthNameIndices.size == structure.monthCount,
        "month name count matches month count");
  check(structure.monthWeaving.size == yearLength,
        "month weaving spans every day in the year");

  var monthLengthSum = 0;
  for length in structure.monthLengths {
    check(length >= 4 && length <= 123, "month length within 4..123");
    monthLengthSum += length;
  }
  check(monthLengthSum == yearLength, "month lengths sum to year length");

  for monthId in 1..structure.monthCount {
    var occurrences = 0;
    for id in structure.monthWeaving do if id == monthId then occurrences += 1;
    check(occurrences == structure.monthLengths[monthId - 1],
          "month weaving frequency matches chosen month length");
  }

  var partitionSum = 0;
  for part in structure.cutletPartition {
    check(part >= 1, "cutlet partition parts are positive");
    partitionSum += part;
  }
  check(partitionSum == gateGapCount,
        "cutlet partition sums to number of gate gaps");

  var cursorGate = year.openGateIndex;
  var foundationBoundaryIndex = -1;
  var foundationCutletOpenGate = year.openGateIndex;
  var cumulativeGaps = 0;
  const foundationBoundary = -year.openGateIndex;
  for i in structure.cutlets.indices {
    const c = structure.cutlets[i];
    const nextGate = cursorGate + structure.cutletPartition[i];
    const expectedFirstDay = gates.ensureGateIndex(cursorGate) + 1;
    const expectedLastDay = gates.ensureGateIndex(nextGate);
    check(c.firstDay == expectedFirstDay, "cutlet begins after its opening gate");
    check(c.lastDay == expectedLastDay, "cutlet closes on its ending gate");
    check(c.openGateIndex == cursorGate && c.closeGateIndex == nextGate,
          "materialized cutlet gate indices match partition");
    check(c.canonicalNameIndex == structure.cutletNameIndices[i],
          "materialized cutlet name index matches selected name index");
    cumulativeGaps += structure.cutletPartition[i];
    if cumulativeGaps == foundationBoundary {
      foundationBoundaryIndex = i;
      foundationCutletOpenGate = cursorGate;
    }
    cursorGate = nextGate;
  }
  check(cursorGate == year.closeGateIndex,
        "cutlets cover all gate gaps without omission");
  check(foundationBoundaryIndex >= 0,
        "FOUNDATION_DAY is a cutlet boundary (or year close)");
  const foundationCutletLength =
    gates.ensureGateIndex(0) - gates.ensureGateIndex(foundationCutletOpenGate);

  checkpoint("NEIGHBOR_YEARS_BEGIN");
  const previousYear = gates.findTargetYear(calculationDay, year.openGateDay);
  const firstYearDay = gates.findTargetYear(calculationDay, firstDay);
  const closeYearDay = gates.findTargetYear(calculationDay, lastDay);
  const nextYear = gates.findTargetYear(calculationDay, lastDay + 1);
  checkpoint("NEIGHBOR_YEARS_END");
  check(previousYear.closeGateDay == year.openGateDay &&
        previousYear.number == year.number - 1,
        "open gate day belongs to previous year");
  check(firstYearDay.openGateDay == year.openGateDay &&
        firstYearDay.closeGateDay == year.closeGateDay &&
        firstYearDay.number == year.number,
        "open+1 belongs to current year");
  check(closeYearDay.openGateDay == year.openGateDay &&
        closeYearDay.closeGateDay == year.closeGateDay &&
        closeYearDay.number == year.number,
        "close gate day belongs to current year");
  check(nextYear.openGateDay == year.closeGateDay &&
        nextYear.number == year.number + 1,
        "close+1 belongs to next year");

  var sampleDays = new list(bigint);
  sampleDays.pushBack(firstDay);
  sampleDays.pushBack(calculationDay - 1);
  sampleDays.pushBack(calculationDay);
  if lastDay > calculationDay then sampleDays.pushBack(calculationDay + 1);
  sampleDays.pushBack(lastDay);

  var calendarDateChecks = 0;
  var fullCalendarDateCalls = 0;
  var reusedStructureDateCalls = 0;
  for targetDay in sampleDays {
    checkpoint("CALENDAR_DATE_BEGIN_" + targetDay:string);
    var actual: CalendarDateResult;
    if targetDay == firstDay {
      actual = calendarDate(gates, calculationDay, targetDay);
      fullCalendarDateCalls += 1;
    } else {
      actual = calendarDateFromStructure(year, structure, targetDay);
      reusedStructureDateCalls += 1;
    }
    checkpoint("CALENDAR_DATE_END_" + targetDay:string);
    checkpoint("INDEPENDENT_DATE_BEGIN_" + targetDay:string);
    const expected = independentDate(gates, year, structure, targetDay);
    checkpoint("INDEPENDENT_DATE_END_" + targetDay:string);
    check(sameDate(actual, expected),
          "calendarDate matches independent decomposition at targetDay=" + targetDay:string);
    calendarDateChecks += 1;
    if targetDay == firstDay {
      check(actual.dayInCutlet == 1 && actual.dayInMonth == 1,
            "first day of year starts cutlet and month at day one");
    }
    if targetDay == calculationDay {
      check(actual.dayInCutlet == foundationCutletLength,
            "FOUNDATION_DAY is last day of its cutlet");
    }
    if targetDay == calculationDay + 1 && lastDay > calculationDay {
      check(actual.dayInCutlet == 1,
            "day after FOUNDATION_DAY starts next cutlet");
    }
  }

  check(fullCalendarDateCalls == 1 &&
        reusedStructureDateCalls == sampleDays.size-1,
        "calendarDate full-build and reused-structure call counts");
  writeln("YEAR_BOUNDARY_CALENDAR_DATE_FULL_BUILD_CALLS=",fullCalendarDateCalls);
  writeln("YEAR_BOUNDARY_CALENDAR_DATE_REUSED_STRUCTURE_CALLS=",reusedStructureDateCalls);
  writeln("YEAR_BOUNDARY_PROBE_CHECKS=", checks);
  writeln("YEAR_BOUNDARY_PROBE_FAILURES=", failures);
  writeln("YEAR_BOUNDARY_CALENDAR_DATE_COMPARISONS=", calendarDateChecks);
  if failures != 0 then halt("Year-boundary/date decomposition probe failed.");
  writeln("YEAR_BOUNDARY_PROBE_RESULT=PASS");
}
