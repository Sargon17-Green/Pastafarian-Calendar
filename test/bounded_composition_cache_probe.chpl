use BigInteger;
use List;
use NormativeOracle only BoundedCompositionCounter, CutletPartitionCounter;

proc bruteThreeSlotCount(total: int, lo: int, hi: int): int {
  var resultValue = 0;
  for a in lo..hi {
    for b in lo..hi {
      for c in lo..hi {
        if a + b + c == total then resultValue += 1;
      }
    }
  }
  return resultValue;
}

proc bruteThreeSlotKeys(total: int, lo: int, hi: int,
                           requiredBoundary: int): list(string) {
  var words = new list(string);
  for a in lo..hi {
    for b in lo..hi {
      for c in lo..hi {
        if a + b + c == total &&
           (requiredBoundary < 0 || a == requiredBoundary ||
            a + b == requiredBoundary) then
          words.pushBack(a:string + b:string + c:string);
      }
    }
  }
  return words;
}

proc main() {
  var reused: BoundedCompositionCounter;
  reused.totalValue = 8;
  reused.slotsTotal = 3;
  reused.lo = 1;
  reused.hi = 5;

  const initialDp = reused.countAll();
  const initialOracle = bruteThreeSlotCount(8, 1, 5);

  reused.lo = 2;
  reused.hi = 4;
  const reusedDp = reused.countAll();
  const reconfiguredOracle = bruteThreeSlotCount(8, 2, 4);

  var fresh: BoundedCompositionCounter;
  fresh.totalValue = 8;
  fresh.slotsTotal = 3;
  fresh.lo = 2;
  fresh.hi = 4;
  const freshDp = fresh.countAll();

  writeln("BOUNDED_CACHE_INITIAL_DP=", initialDp);
  writeln("BOUNDED_CACHE_INITIAL_ORACLE=", initialOracle);
  writeln("BOUNDED_CACHE_REUSED_DP=", reusedDp);
  writeln("BOUNDED_CACHE_RECONFIGURED_ORACLE=", reconfiguredOracle);
  writeln("BOUNDED_CACHE_FRESH_DP=", freshDp);

  if initialDp != 18 || initialOracle != 18 ||
     reusedDp != 6 || reconfiguredOracle != 6 || freshDp != 6 then
    halt("The bounded-composition cache-reconfiguration fix did not match its contract.");

  writeln("BOUNDED_COMPOSITION_CACHE_REUSE_FIXED=PASS");

  var cutletReused: CutletPartitionCounter;
  cutletReused.totalGaps = 5;
  cutletReused.slotsTotal = 3;
  cutletReused.requiredBoundary = -1;
  const cutletInitial = cutletReused.countAll();
  const cutletInitialOracle = bruteThreeSlotCount(5, 1, 3);

  cutletReused.requiredBoundary = 2;
  const cutletReconfigured = cutletReused.countAll();
  var cutletFresh: CutletPartitionCounter;
  cutletFresh.totalGaps = 5;
  cutletFresh.slotsTotal = 3;
  cutletFresh.requiredBoundary = 2;
  const cutletFreshCount = cutletFresh.countAll();

  var cutletBoundaryOracle = 0;
  for a in 1..5 {
    for b in 1..5 {
      for c in 1..5 {
        if a + b + c == 5 && (a == 2 || a + b == 2) then
          cutletBoundaryOracle += 1;
      }
    }
  }

  writeln("CUTLET_CACHE_INITIAL_DP=", cutletInitial);
  writeln("CUTLET_CACHE_INITIAL_ORACLE=", cutletInitialOracle);
  writeln("CUTLET_CACHE_REUSED_DP=", cutletReconfigured);
  writeln("CUTLET_CACHE_BOUNDARY_ORACLE=", cutletBoundaryOracle);
  writeln("CUTLET_CACHE_FRESH_DP=", cutletFreshCount);

  if cutletInitial != 6 || cutletInitialOracle != 6 ||
     cutletReconfigured != 3 || cutletBoundaryOracle != 3 ||
     cutletFreshCount != 3 then
    halt("The cutlet-partition cache-reconfiguration fix did not match its contract.");

  const boundedWords = bruteThreeSlotKeys(8, 2, 4, -1);
  var boundedUnrankChecks = 0;
  for idx0 in boundedWords.indices {
    const actual = reused.unrank1(new bigint(idx0 + 1));
    var actualKey = "";
    for x in actual do actualKey += x:string;
    if actualKey != boundedWords[idx0] then
      halt("BoundedCompositionCounter reconfigured unrank mismatch.");
    boundedUnrankChecks += 1;
  }

  const cutletWords = bruteThreeSlotKeys(5, 1, 5, 2);
  var cutletUnrankChecks = 0;
  for idx1 in cutletWords.indices {
    const actual = cutletReused.unrank1(new bigint(idx1 + 1));
    var actualKey = "";
    for x in actual do actualKey += x:string;
    if actualKey != cutletWords[idx1] then
      halt("CutletPartitionCounter reconfigured unrank mismatch.");
    cutletUnrankChecks += 1;
  }

  writeln("BOUNDED_CACHE_UNRANK_CHECKS=", boundedUnrankChecks);
  writeln("CUTLET_CACHE_UNRANK_CHECKS=", cutletUnrankChecks);
  if boundedUnrankChecks != 6 || cutletUnrankChecks != 3 then
    halt("Cache-reconfiguration unrank coverage mismatch.");

  writeln("CUTLET_PARTITION_CACHE_REUSE_FIXED=PASS");
}
