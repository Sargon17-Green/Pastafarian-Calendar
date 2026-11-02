use BigInteger;
use IO;
use List;
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

proc main() {
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
  for targetDay in sampleDays {
    checkpoint("CALENDAR_DATE_BEGIN_" + targetDay:string);
    const actual = calendarDate(gates, calculationDay, targetDay);
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

  writeln("YEAR_BOUNDARY_PROBE_CHECKS=", checks);
  writeln("YEAR_BOUNDARY_PROBE_FAILURES=", failures);
  writeln("YEAR_BOUNDARY_CALENDAR_DATE_COMPARISONS=", calendarDateChecks);
  if failures != 0 then halt("Year-boundary/date decomposition probe failed.");
  writeln("YEAR_BOUNDARY_PROBE_RESULT=PASS");
}
