import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_year_selection.dart';

import '../test_support/normative_reference.dart' as normative;

var checks = 0;

void require(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError(label);
  }
}

void expectRange(void Function() action, String name) {
  var rejected = false;
  try {
    action();
  } on RangeError catch (error) {
    require(error.name == name, 'RangeError field $name');
    rejected = true;
  }
  require(rejected, 'RangeError required for $name');
}

void expectIncomplete(
  void Function() action,
  BigInt day,
  BigInt year,
  int budget,
) {
  var rejected = false;
  try {
    action();
  } on IncompleteMonsterYearNumberTraversal catch (error) {
    require(error.calculationDay == day, 'fixed calculation day');
    require(error.requestedYearNumber == year, 'requested year');
    require(error.completedTransitions == 0, 'no partial transitions');
    require(error.maximumTransitions == budget, 'exact transition budget');
    rejected = true;
  }
  require(rejected, 'insufficient transition budget');
}

void main() {
  final watch = Stopwatch()..start();
  final c = GregorianCivilDate(BigInt.from(2026), 11, 28);
  final day = c.toSerialDay();
  final anchor = MonsterYear5000Selector().select(day).selectedYear;
  final reference = normative.NormativeReference(
    anchorGateIndex: anchor.openOrdinal,
    anchorGateDay: anchor.openGate,
  );
  final current = reference.year5000(day);
  final previous = reference.previousYear(day, current);
  require(previous.number == BigInt.from(4999), 'previous year label');
  require(previous.closeGateDay == current.openGateDay, 'shared boundary');
  require(current.openGateDay == anchor.openGate, 'conditioned anchor');

  // The last civil day of a year is the last day of the final cutlet
  // and final chronological month. This follows from partition coverage
  // and strictly increasing last occurrence order, without unranking
  // a production weave or using its month IDs to construct the tuple.
  final target = previous.closeGateDay;
  final sauce = normative.NormativeReference.sauce(
    day,
    previous.openGateDay + BigInt.one,
  );
  final cutletCount = reference.chooseCutletCount(sauce, previous);
  final partition = reference.chooseCutletPartition(
    day,
    sauce,
    previous,
    cutletCount,
  );
  final cutletNames = reference.chooseCutletNames(sauce, cutletCount);
  final cutlets = reference.materializeCutlets(
    previous,
    partition,
    cutletNames,
  );
  final monthCount = reference.chooseMonthCount(sauce, previous);
  final monthLengths = reference.chooseMonthLengths(
    sauce,
    previous,
    monthCount,
  );
  final monthNames = reference.chooseMonthNames(sauce, monthCount);
  final cutlet = cutlets.last;
  require(cutlet.lastDay == target, 'independent final cutlet ends at target');
  final cutletDay = (cutlet.lastDay - cutlet.firstDay + BigInt.one).toInt();
  final monthDay = monthLengths.last.toInt();
  require(cutletDay > 1 && monthDay > 1, 'nontrivial final ordinals');

  MonsterFiveFieldDate input({
    BigInt? year,
    int? cutletOrdinal,
    int? monthOrdinal,
  }) =>
      MonsterFiveFieldDate.fromComponents(
        yearNumber: year ?? previous.number,
        cutletCanonicalIndex: cutlet.nameCanonicalIndex,
        dayInCutlet: cutletOrdinal ?? cutletDay,
        monthCanonicalIndex: monthNames.last,
        dayInMonth: monthOrdinal ?? monthDay,
      );

  final converter = PastafariGregorianConverter();
  final expected = input();
  final civil = GregorianCivilDate.fromSerialDay(target);
  final forward = converter.calculate(c, civil, maxTransitions: 1);
  for (var i = 0; i < expected.canonicalComponents.length; i++) {
    require(
      forward.canonicalComponents[i] == expected.canonicalComponents[i],
      'independent final-day coordinate $i',
    );
  }
  require(
    converter.toSerialDay(c, expected, maxTransitions: 1) == target,
    '4999 inverse from independent boundary tuple',
  );

  expectIncomplete(
    () => converter.toSerialDay(c, expected, maxTransitions: 0),
    day,
    previous.number,
    0,
  );
  final distant = input(year: BigInt.from(4935));
  expectIncomplete(
    () => converter.toSerialDay(c, distant, maxTransitions: 64),
    day,
    distant.yearNumber,
    64,
  );
  for (final budget in <int>[-1, 65]) {
    expectRange(
      () => converter.toSerialDay(c, expected, maxTransitions: budget),
      'maxTransitions',
    );
  }
  expectRange(
    () => converter.toSerialDay(
      c,
      input(monthOrdinal: monthDay + 1),
      maxTransitions: 1,
    ),
    'dayInMonth',
  );
  expectRange(
    () => converter.toSerialDay(
      c,
      input(cutletOrdinal: cutletDay + 1),
      maxTransitions: 1,
    ),
    'dayInCutlet',
  );
  var inconsistent = false;
  try {
    converter.toSerialDay(
      c,
      input(cutletOrdinal: cutletDay - 1),
      maxTransitions: 1,
    );
  } on ArgumentError catch (error) {
    require(error is! RangeError, 'conflicting valid ordinal, not range error');
    inconsistent = true;
  }
  require(inconsistent, 'conflicting coordinates rejected');
  final elapsed = watch.elapsedMilliseconds;
  require(elapsed <= 1000000, 'previous inverse time budget');
  print(
    'PRODUCTION_INVERSE_PREVIOUS_PASS checks=$checks '
    'fixed_c=2026-11-28 year=4999 transitions=1 '
    'anchor_conditioned=true independent_boundary_tuple=true '
    'elapsed_ms=$elapsed',
  );
}
