import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

import 'pastafari_calendar_cli.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;

void require(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError(label);
  }
}

String _formatCivilDate(GregorianCivilDate date) =>
    date.year.toString() +
    '-' +
    date.month.toString().padLeft(2, '0') +
    '-' +
    date.day.toString().padLeft(2, '0');

void main() {
  final calculationDate = GregorianCivilDate(BigInt.from(2026), 11, 28);
  final calculationDay = calculationDate.toSerialDay();
  final anchor = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(calculationDay),
  );
  final next = MonsterYearTraversal().next(calculationDay, anchor);
  final futureSerial = next.candidate.openGate + BigInt.one;
  final futureCivil = GregorianCivilDate.fromSerialDay(futureSerial);
  final watch = Stopwatch()..start();

  final futureOutput = runCalendarCli(<String>[
    'forward',
    '--calculation-date=2026-11-28',
    '--requested-date=' + _formatCivilDate(futureCivil),
    '--max-transitions=1',
  ]);
  final futureData = futureOutput['pastafarian_date'] as Map<String, Object?>;
  final futureCutlet = futureData['cutlet'] as Map<String, Object?>;
  final futureMonth = futureData['month'] as Map<String, Object?>;
  final futureDate = MonsterFiveFieldDate.fromComponents(
    yearNumber: BigInt.parse(futureData['year_number'] as String),
    cutletCanonicalIndex: futureCutlet['canonical_index'] as int,
    dayInCutlet: futureCutlet['day'] as int,
    monthCanonicalIndex: futureMonth['canonical_index'] as int,
    dayInMonth: futureMonth['day'] as int,
  );
  require(
    BigInt.parse(futureOutput['requested_serial_day'] as String) ==
        futureSerial,
    'CLI forward serial day',
  );
  require(futureDate.yearNumber == BigInt.from(5001), 'Fixed-c forward year');
  require(
    futureDate.cutletName ==
        SourceLanguageCatalog.cutletText(futureDate.cutletCanonicalIndex),
    'Future cutlet canonical name',
  );
  require(
    futureDate.monthName ==
        SourceLanguageCatalog.monthText(futureDate.monthCanonicalIndex),
    'Future month canonical name',
  );

  final futureInput = MonsterFiveFieldDate.fromComponents(
    yearNumber: futureDate.yearNumber,
    cutletCanonicalIndex: futureDate.cutletCanonicalIndex,
    dayInCutlet: futureDate.dayInCutlet,
    monthCanonicalIndex: futureDate.monthCanonicalIndex,
    dayInMonth: futureDate.dayInMonth,
  );
  final inverseOutput = runCalendarCli(<String>[
    'inverse',
    '--calculation-date=2026-11-28',
    '--year-number=' + futureInput.yearNumber.toString(),
    '--cutlet-index=' + futureInput.cutletCanonicalIndex.toString(),
    '--day-in-cutlet=' + futureInput.dayInCutlet.toString(),
    '--month-index=' + futureInput.monthCanonicalIndex.toString(),
    '--day-in-month=' + futureInput.dayInMonth.toString(),
    '--max-transitions=1',
  ]);
  final inverseDate = inverseOutput['gregorian_date'] as Map<String, Object?>;
  require(
    BigInt.parse(inverseOutput['serial_day'] as String) == futureSerial,
    'CLI inverse serial day',
  );
  require(inverseDate['year'] == futureCivil.year.toString(), 'Inverse year');
  require(inverseDate['month'] == futureCivil.month, 'Inverse month');
  require(inverseDate['day'] == futureCivil.day, 'Inverse day');

  var refused = false;
  try {
    PastafariGregorianConverter().toSerialDay(
      calculationDate,
      futureInput,
      maxTransitions: 0,
    );
  } on IncompleteMonsterYearNumberTraversal catch (error) {
    require(error.calculationDay == calculationDay, 'Fixed calculation day');
    require(error.requestedYearNumber == BigInt.from(5001), 'Requested year');
    require(error.completedTransitions == 0, 'No partial year transition');
    refused = true;
  }
  require(refused, 'Zero transition budget fails closed');

  var invalidBudget = false;
  try {
    PastafariGregorianConverter().toSerialDay(
      calculationDate,
      futureInput,
      maxTransitions: 65,
    );
  } on RangeError {
    invalidBudget = true;
  }
  require(invalidBudget, 'Transition budget above 64 rejected');

  var invalidComponent = false;
  try {
    MonsterFiveFieldDate.fromComponents(
      yearNumber: BigInt.from(5001),
      cutletCanonicalIndex: futureDate.cutletCanonicalIndex,
      dayInCutlet: 0,
      monthCanonicalIndex: futureDate.monthCanonicalIndex,
      dayInMonth: futureDate.dayInMonth,
    );
  } on ArgumentError {
    invalidComponent = true;
  }
  require(invalidComponent, 'Nonpositive day ordinal rejected');

  final wrongDayInCutlet = futureDate.dayInCutlet > 1
      ? futureDate.dayInCutlet - 1
      : futureDate.dayInCutlet + 1;
  final mismatch = MonsterFiveFieldDate.fromComponents(
    yearNumber: futureDate.yearNumber,
    cutletCanonicalIndex: futureDate.cutletCanonicalIndex,
    dayInCutlet: wrongDayInCutlet,
    monthCanonicalIndex: futureDate.monthCanonicalIndex,
    dayInMonth: futureDate.dayInMonth,
  );
  var inconsistent = false;
  try {
    PastafariGregorianConverter().toSerialDay(
      calculationDate,
      mismatch,
      maxTransitions: 1,
    );
  } on ArgumentError {
    inconsistent = true;
  }
  require(inconsistent, 'Conflicting cutlet/month coordinates rejected');

  final help = runCalendarCli(<String>['--help']);
  require((help['usage'] as List<String>).length >= 2, 'CLI help contract');
  var invalidUsage = false;
  try {
    runCalendarCli(<String>[
      'forward',
      '--calculation-date=2026-11-28',
    ]);
  } on FormatException {
    invalidUsage = true;
  }
  require(invalidUsage, 'CLI missing required argument rejected');

  final elapsed = watch.elapsedMilliseconds;
  print('PRODUCTION_INVERSE_FIXED_C_TIMING elapsed_ms=' + elapsed.toString());
  require(elapsed <= 240000, 'Fixed-c forward/inverse time budget');
  print('PRODUCTION_INVERSE_FIXED_C_PASS checks=' +
      checks.toString() +
      ' modern_calculation_day=2026-11-28 fixed_c=true transitions=1 elapsed_ms=' +
      elapsed.toString());
}
