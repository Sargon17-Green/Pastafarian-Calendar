import '../lib/src/monster_five_field_calendar.dart';
import '../lib/src/monster_meatball_partition.dart';
import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_names.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/monster_year_traversal.dart';
import '../lib/src/source_language_catalog.dart';

var checks = 0;
final phaseMilliseconds = <String, int>{};

void requireCondition(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError('STAGE6_PROFILE_FAILED: $label');
  }
}

T measure<T>(String phase, T Function() operation) {
  final timer = Stopwatch()..start();
  final result = operation();
  timer.stop();
  phaseMilliseconds[phase] = timer.elapsedMilliseconds;
  print('STAGE6_PHASE_${phase.toUpperCase()}_MS=${timer.elapsedMilliseconds}');
  return result;
}

void main() {
  final foundation = BigInt.from(-15055671);
  final total = Stopwatch()..start();

  final year = measure(
    'year',
    () => MonsterYearTraversal().resolve(
      foundation,
      foundation,
      maxTransitions: 0,
    ),
  );
  final cutlets = measure(
    'cutlets',
    () => MonsterMeatballPartitioner().partition(foundation, year),
  );
  final lengths = measure(
    'lengths',
    () => const MonsterMonthLengthPlanner().plan(foundation, year),
  );
  final weave = measure(
    'weave',
    () => const MonsterMonthWeavePlanner().plan(foundation, year, lengths),
  );
  final names = measure(
    'names',
    () => const MonsterMonthNamePlanner().plan(
      foundation,
      year,
      lengths,
      weave,
    ),
  );
  final date = measure(
    'projection',
    () => MonsterFiveFieldCalendar.project(
      yearNumber: year.yearNumber,
      openGate: year.candidate.openGate,
      closeGate: year.candidate.closeGate,
      requestedDay: foundation,
      cutlets: cutlets.meatballs,
      monthLengths: lengths.lengths,
      monthIds: weave.monthIds,
      monthNameIndices: names.nameIndices,
    ),
  );
  total.stop();

  requireCondition(year.yearNumber == BigInt.from(5000), 'Year 5000');
  requireCondition(
      year.contains(foundation), 'Foundation within selected year');
  requireCondition(cutlets.meatballs.isNotEmpty, 'At least one cutlet');
  requireCondition(
    lengths.lengths.length >= 3 && lengths.lengths.length <= 47,
    'Month count within canonical bounds',
  );
  requireCondition(
    weave.monthIds.length ==
        (year.candidate.closeGate - year.candidate.openGate).toInt(),
    'Weave spans selected year',
  );
  requireCondition(
    names.nameIndices.length == lengths.lengths.length,
    'Name count matches month count',
  );
  // Literal retained-sum AC.1 oracle, not calculated from the planners.
  requireCondition(date.yearNumber == BigInt.from(5000), 'AC.1 year');
  requireCondition(date.cutletCanonicalIndex == 10, 'AC.1 cutlet');
  requireCondition(date.dayInCutlet == 503, 'AC.1 cutlet day');
  requireCondition(date.monthCanonicalIndex == 20, 'AC.1 month');
  requireCondition(date.dayInMonth == 56, 'AC.1 month day');
  requireCondition(
    date.cutletName == SourceLanguageCatalog.cutletText(10),
    'Locked Hebrew cutlet name',
  );
  requireCondition(
    date.monthName == SourceLanguageCatalog.monthText(20),
    'Locked Hebrew month name',
  );
  requireCondition(date.canonicalComponents.length == 5, 'Five components');
  requireCondition(phaseMilliseconds.length == 6, 'Six measured phases');
  var phaseSum = 0;
  for (final milliseconds in phaseMilliseconds.values) {
    phaseSum += milliseconds;
  }
  requireCondition(
    phaseSum <= total.elapsedMilliseconds,
    'Phase durations within total duration',
  );
  requireCondition(
    total.elapsedMilliseconds <= 120000,
    'Bounded profile within 120 seconds',
  );
  requireCondition(checks >= 17, 'At least 18 profile checks');

  print('STAGE6_PROFILE_TIME_MS=${total.elapsedMilliseconds}');
  print('STAGE6_PROFILE_PASS; checks=$checks; canonical_anchors=1; '
      'phases=6; pipeline_consistent=true; retained_sum_ac1=true');
}
