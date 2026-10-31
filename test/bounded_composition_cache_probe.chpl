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
     cutletReconfigured != 6 || cutletBoundaryOracle != 3 ||
     cutletFreshCount != 3 then
    halt("The cutlet-partition cache-reconfiguration witness did not match its contract.");

  writeln("CUTLET_PARTITION_CACHE_REUSE_WITNESS=REPRODUCED");
}
