// Native Chapel research only; exact polynomial root count, not Stage 6.
use BigInteger;
use List;
use ExactMath;
use NormativeOracle;

proc polynomialRootCount(const ref lengths: list(int)): bigint {
  if lengths.size == 0 then halt("Empty month list.");
  var capacity = 0;
  for k in lengths {
    if k <= 0 then halt("Nonpositive month length.");
    capacity += k;
  }
  var previous: [0..capacity] bigint;
  var next: [0..capacity] bigint;
  var prefix: [0..capacity] bigint;
  var days = lengths[0];
  previous[1] = new bigint(1);
  for month in 1..<lengths.size {
    const k = lengths[month];
    prefix[0] = new bigint(0);
    for p in 1..days do prefix[p] = prefix[p-1] + previous[p];
    for p in 1..(days+k) do next[p] = new bigint(0);
    next[days+1] = prefix[days];
    if k >= 2 {
      var coefficient = new bigint(k-1);
      for t in 1..days {
        const gap = days-t;
        next[gap+1] = prefix[gap] * coefficient;
        if t < days {
          coefficient = (coefficient * new bigint(t+k-1)) /
                        new bigint(t+1);
        }
      }
    }
    days += k;
    for p in 1..days do previous[p] = next[p];
  }
  var total = new bigint(0);
  for p in 1..days do total += previous[p];
  return total;
}

proc csv(const ref lengths: list(int)): string {
  var resultValue = "";
  for k in lengths {
    if resultValue != "" then resultValue += ",";
    resultValue += k:string;
  }
  return resultValue;
}

proc main() {
  var cases = 0;
  for m in 1..4 {
    var possibilities = 1;
    for q in 1..m do possibilities *= 3;
    for raw in 0..<possibilities {
      var digits = raw;
      var lengths = new list(int);
      var days = 0;
      for j in 1..m {
        const k = 1 + digits % 3;
        digits /= 3;
        lengths.pushBack(k);
        days += k;
      }
      if days > 8 then continue;
      const actual = polynomialRootCount(lengths);
      var reference: WeavingCounter;
      reference.lengths = lengths;
      if actual != reference.countAll() then
        halt("Native small-case differential mismatch: " + csv(lengths));
      writeln("WEAVING_NATIVE_POLY_CASE=", csv(lengths), ";", actual);
      cases += 1;
    }
  }
  writeln("WEAVING_NATIVE_POLY_FINITE_CASES=", cases);
  var gates: GateOracle;
  const year = gates.year5000(FOUNDATION_DAY);
  const r = sauce(FOUNDATION_DAY, year.openGateDay+1);
  const months = chooseMonthCount(r, year);
  const lengths = chooseMonthLengths(r, year, months);
  var days = 0;
  for k in lengths do days += k;
  writeln("WEAVING_NATIVE_POLY_MONTH_LENGTHS=", csv(lengths));
  writeln("WEAVING_NATIVE_POLY_MONTHS=", months);
  writeln("WEAVING_NATIVE_POLY_DAYS=", days);
  writeln("WEAVING_NATIVE_POLY_ROOT_DECIMAL=", polynomialRootCount(lengths));
  writeln("WEAVING_NATIVE_POLY_ROOT_COUNT_ONLY=COMPLETE");
  writeln("WEAVING_NATIVE_POLY_RANK_UNRANK=NOT_TESTED");
  writeln("WEAVING_NATIVE_POLY_PRODUCTION_CHANGE=NONE");
}
