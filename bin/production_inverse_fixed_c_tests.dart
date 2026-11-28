import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;

void require(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError(label);
  }
}

bool sameDate(GregorianCivilDate a, GregorianCivilDate b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

void main() {
  final calculationDate = GregorianCivilDate(BigInt.from(2026), 11, 28);
  final calculationDay = calculationDate.toSerialDay();
  final anchor = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(calculationDay),
  );
  final traversal = MonsterYearTraversal();
  final next = traversal.next(calculationDay, anchor);
  final previous = traversal.previous(calculationDay, anchor);
  final futureSerial = next.candidate.openGate + BigInt.one;
  final pastSerial = previous.candidate.closeGate;
  final futureCivil = GregorianCivilDate.fromSerialDay(futureSerial);
  final pastCivil = GregorianCivilDate.fromSerialDay(pastSerial);
  final converter = PastafariGregorianConverter();
  final watch = Stopwatch()..start();

  final futureDate = converter.calculate(
    calculationDate,
    futureCivil,
    maxTransitions: 1,
  );
  final pastDate = converter.calculate(
    calculationDate,
    pastCivil,
    maxTransitions: 1,
  );
  require(futureDate.yearNumber == BigInt.from(5001), 'Fixed-c forward year');
  require(pastDate.yearNumber == BigInt.from(4999), 'Fixed-c backward year');
  require(
    futureDate.cutletName ==
        SourceLanguageCatalog.cutletText(futureDate.cutletCanonicalIndex),
    'Future cutlet canonical name',
  );
  require(
    pastDate.monthName ==
        SourceLanguageCatalog.monthText(pastDate.monthCanonicalIndex),
    'Past month canonical name',
  );

  final futureInput = MonsterFiveFieldDate.fromComponents(
    yearNumber: futureDate.yearNumber,
    cutletCanonicalIndex: futureDate.cutletCanonicalIndex,
    dayInCutlet: futureDate.dayInCutlet,
    monthCanonicalIndex: futureDate.monthCanonicalIndex,
    dayInMonth: futureDate.dayInMonth,
  );
  final pastInput = MonsterFiveFieldDate.fromComponents(
    yearNumber: pastDate.yearNumber,
    cutletCanonicalIndex: pastDate.cutletCanonicalIndex,
    dayInCutlet: pastDate.dayInCutlet,
    monthCanonicalIndex: pastDate.monthCanonicalIndex,
    dayInMonth: pastDate.dayInMonth,
  );
  final futureBack = converter.toSerialDay(
    calculationDate,
    futureInput,
    maxTransitions: 1,
  );
  final pastBack = converter.toGregorian(
    calculationDate,
    pastInput,
    maxTransitions: 1,
  );
  require(futureBack == futureSerial, 'Future inverse serial day');
  require(sameDate(pastBack, pastCivil), 'Past inverse Gregorian date');

  var refused = false;
  try {
    converter.toSerialDay(calculationDate, futureInput, maxTransitions: 0);
  } on IncompleteMonsterYearNumberTraversal catch (error) {
    require(error.calculationDay == calculationDay, 'Fixed calculation day');
    require(error.requestedYearNumber == BigInt.from(5001), 'Requested year');
    require(error.completedTransitions == 0, 'No partial year transition');
    refused = true;
  }
  require(refused, 'Zero transition budget fails closed');

  var invalidBudget = false;
  try {
    converter.toSerialDay(calculationDate, futureInput, maxTransitions: 65);
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

  final mismatch = MonsterFiveFieldDate.fromComponents(
    yearNumber: futureDate.yearNumber,
    cutletCanonicalIndex: futureDate.cutletCanonicalIndex,
    dayInCutlet: futureDate.dayInCutlet + 1,
    monthCanonicalIndex: futureDate.monthCanonicalIndex,
    dayInMonth: futureDate.dayInMonth,
  );
  var inconsistent = false;
  try {
    converter.toSerialDay(calculationDate, mismatch, maxTransitions: 1);
  } on ArgumentError {
    inconsistent = true;
  }
  require(inconsistent, 'Conflicting cutlet/month coordinates rejected');

  final elapsed = watch.elapsedMilliseconds;
  require(elapsed <= 240000, 'Fixed-c forward/inverse time budget');
  print('PRODUCTION_INVERSE_FIXED_C_PASS checks=' +
      checks.toString() +
      ' modern_calculation_day=2026-11-28 fixed_c=true transitions=1 elapsed_ms=' +
      elapsed.toString());
}
