use NormativeOracle only BoundedCompositionCounter;

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
}
