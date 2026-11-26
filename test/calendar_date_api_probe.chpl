use BigInteger;
use IO;
use Time;
use ExactMath only FOUNDATION_DAY;
use NormativeOracle;

var checks = 0;
var failures = 0;

proc check(condition: bool, description: string) {
  checks += 1;
  if !condition {
    failures += 1;
    writeln("YEAR_BOUNDARY_API_FAIL=", description);
  }
}

proc main() {
  const calculationDay = FOUNDATION_DAY;
  var gates: GateOracle;
  const expectedYear = gates.year5000(calculationDay);
  const firstDay = expectedYear.openGateDay + 1;

  writeln("YEAR_BOUNDARY_CALENDAR_DATE_API_BEGIN");
  writeln("YEAR_BOUNDARY_API_TARGET_DAY=", firstDay);
  try! stdout.flush();

  var apiTimer: stopwatch;
  apiTimer.start();
  const actual = calendarDate(gates, calculationDay, firstDay);
  apiTimer.stop();

  writeln("YEAR_BOUNDARY_CALENDAR_DATE_API_END");
  writeln("YEAR_BOUNDARY_API_SECONDS=", apiTimer.elapsed());
  writeln("YEAR_BOUNDARY_API_ACTUAL_YEAR_NUMBER=", actual.yearNumber);
  writeln("YEAR_BOUNDARY_API_ACTUAL_CUTLET_NAME=", actual.cutletName);
  writeln("YEAR_BOUNDARY_API_ACTUAL_DAY_IN_CUTLET=", actual.dayInCutlet);
  writeln("YEAR_BOUNDARY_API_ACTUAL_MONTH_NAME=", actual.monthName);
  writeln("YEAR_BOUNDARY_API_ACTUAL_DAY_IN_MONTH=", actual.dayInMonth);

  check(actual.yearNumber == expectedYear.number,
        "calendarDate resolves the same year as year5000");
  check(actual.dayInCutlet == 1,
        "first day of year starts at cutlet day one");
  check(actual.dayInMonth == 1,
        "first day of year starts at month day one");
  check(actual.cutletName != "",
        "calendarDate returns a nonempty Ukrainian cutlet name");
  check(actual.monthName != "",
        "calendarDate returns a nonempty Ukrainian month name");

  writeln("YEAR_BOUNDARY_API_CHECKS=", checks);
  writeln("YEAR_BOUNDARY_API_FAILURES=", failures);
  if failures != 0 then halt("Checked calendarDate API probe failed.");
  writeln("YEAR_BOUNDARY_CALENDAR_DATE_API_RESULT=PASS");
}
