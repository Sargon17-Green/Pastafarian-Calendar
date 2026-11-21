// Source-fresh Year 5000 canonical weaving choice; research only.
// Does not call exponential WeavingCounter.countAll or chooseMonthWeaving.
use BigInteger;
use List;
use ExactMath;
use NormativeOracle;

config const rootDecimal = "";

proc csvLengths(const ref values: list(int)): string {
  var out = "";
  for value in values {
    if out != "" then out += ",";
    out += value:string;
  }
  return out;
}

proc main() {
  if rootDecimal == "" then halt("Missing exact independently counted root.");
  const root = new bigint(rootDecimal);
  if root <= 1 || root <= M then halt("Invalid wide-rank root.");
  const calculationDay = FOUNDATION_DAY;
  var gates: GateOracle;
  const year = gates.year5000(calculationDay);
  const r = sauce(calculationDay, year.openGateDay + 1);
  const monthCount = chooseMonthCount(r, year);
  const monthLengths = chooseMonthLengths(r, year, monthCount);
  var totalDays = 0;
  for days in monthLengths do totalDays += days;
  if year.number != new bigint(5000) || monthCount != 45 || totalDays != 4244 then
    halt("Year 5000 canonical month input changed.");
  const stream = askBowl(r, 4, SEAL_MONTH_WEAVING);
  const rank1 = chooseRank(stream, root);
  if rank1 < 1 || rank1 > root then halt("Canonical selection outside exact root.");
  writeln("CANONICAL_BRIDGE_YEAR=", year.number);
  writeln("CANONICAL_BRIDGE_MONTH_LENGTHS=", csvLengths(monthLengths));
  writeln("CANONICAL_BRIDGE_STREAM_FIRST=", stream.first);
  writeln("CANONICAL_BRIDGE_STREAM_STEP=", stream.directionStep);
  writeln("CANONICAL_BRIDGE_SELECTED_RANK1=", rank1);
  writeln("CANONICAL_BRIDGE_STAGE6=NOT_CLAIMED");
}
