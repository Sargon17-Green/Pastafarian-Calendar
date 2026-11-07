import 'monster_meatball_partition.dart';
import 'monster_month_lengths.dart';
import 'monster_month_names.dart';
import 'monster_month_weave_planner.dart';
import 'monster_year_traversal.dart';
import 'source_language_catalog.dart';

/// Normative §X tuple, with Hebrew display strings at the output boundary.
final class MonsterFiveFieldDate {
  final BigInt yearNumber;
  final int cutletCanonicalIndex;
  final String cutletName;
  final int dayInCutlet;
  final int monthCanonicalIndex;
  final String monthName;
  final int dayInMonth;

  const MonsterFiveFieldDate._({
    required this.yearNumber,
    required this.cutletCanonicalIndex,
    required this.cutletName,
    required this.dayInCutlet,
    required this.monthCanonicalIndex,
    required this.monthName,
    required this.dayInMonth,
  });

  List<Object> get canonicalComponents => List<Object>.unmodifiable(<Object>[
        yearNumber,
        cutletCanonicalIndex,
        dayInCutlet,
        monthCanonicalIndex,
        dayInMonth,
      ]);
}

/// Complete §X operation, without recomputing or mutating selected ranks.
final class MonsterFiveFieldCalendar {
  final MonsterYearTraversal traversal;
  final MonsterMeatballPartitioner cutletPlanner;
  final MonsterMonthLengthPlanner lengthPlanner;
  final MonsterMonthWeavePlanner weavePlanner;
  final MonsterMonthNamePlanner namePlanner;

  MonsterFiveFieldCalendar({
    MonsterYearTraversal? traversal,
    MonsterMeatballPartitioner? cutletPlanner,
    this.lengthPlanner = const MonsterMonthLengthPlanner(),
    this.weavePlanner = const MonsterMonthWeavePlanner(),
    this.namePlanner = const MonsterMonthNamePlanner(),
  })  : traversal = traversal ?? MonsterYearTraversal(),
        cutletPlanner = cutletPlanner ?? MonsterMeatballPartitioner();

  MonsterFiveFieldDate calculate(
    BigInt calculationDay,
    BigInt requestedDay, {
    int maxTransitions = MonsterYearTraversal.maximumTransitions,
  }) {
    final year = traversal.resolve(
      calculationDay,
      requestedDay,
      maxTransitions: maxTransitions,
    );
    final cutlets = cutletPlanner.partition(calculationDay, year);
    final lengths = lengthPlanner.plan(calculationDay, year);
    final weave = weavePlanner.plan(calculationDay, year, lengths);
    final names = namePlanner.plan(calculationDay, year, lengths, weave);
    return project(
      yearNumber: year.yearNumber,
      openGate: year.candidate.openGate,
      closeGate: year.candidate.closeGate,
      requestedDay: requestedDay,
      cutlets: cutlets.meatballs,
      monthLengths: lengths.lengths,
      monthIds: weave.monthIds,
      monthNameIndices: names.nameIndices,
    );
  }

  /// Pure indexing seam for tiny independent synthetic-year oracles.
  static MonsterFiveFieldDate project({
    required BigInt yearNumber,
    required BigInt openGate,
    required BigInt closeGate,
    required BigInt requestedDay,
    required List<MonsterMeatball> cutlets,
    required List<int> monthLengths,
    required List<int> monthIds,
    required List<int> monthNameIndices,
  }) {
    final span = closeGate - openGate;
    if (span <= BigInt.zero ||
        span > BigInt.from(5778) ||
        span != BigInt.from(monthIds.length) ||
        requestedDay <= openGate ||
        requestedDay > closeGate) {
      throw ArgumentError('§X requested day is outside the proven span.');
    }
    final m = monthLengths.length;
    if (m < 3 ||
        m > 47 ||
        monthNameIndices.length != m ||
        cutlets.isEmpty ||
        cutlets.length > 17) {
      throw ArgumentError('§X component dimensions disagree.');
    }
    var total = 0;
    for (final n in monthLengths) {
      if (n < 4 || n > 123) {
        throw ArgumentError('§X month length outside 4..123.');
      }
      total += n;
    }
    if (total != monthIds.length) {
      throw ArgumentError('§X month lengths do not cover the year.');
    }
    final usedNames = <int>{};
    for (final nameIndex in monthNameIndices) {
      if (nameIndex < 1 || nameIndex > 47 || !usedNames.add(nameIndex)) {
        throw ArgumentError('§X month name indices must be distinct.');
      }
    }
    var edge = openGate;
    for (var i = 0; i < cutlets.length; i++) {
      final cutlet = cutlets[i];
      if (cutlet.number != i + 1 ||
          cutlet.openGate != edge ||
          cutlet.closeGate <= edge ||
          cutlet.nameIndex < 1 ||
          cutlet.nameIndex > 17 ||
          cutlet.name != SourceLanguageCatalog.cutletText(cutlet.nameIndex)) {
        throw ArgumentError('§X cutlets do not partition the year.');
      }
      edge = cutlet.closeGate;
    }
    if (edge != closeGate) {
      throw ArgumentError('§X final cutlet gate disagrees with the year.');
    }
    final first = List<int>.filled(m, -1);
    final last = List<int>.filled(m, -1);
    final frequencies = List<int>.filled(m, 0);
    for (var day = 0; day < monthIds.length; day++) {
      final id = monthIds[day];
      if (id < 1 || id > m) {
        throw ArgumentError('§X weave month ID out of range.');
      }
      final j = id - 1;
      if (first[j] < 0) {
        first[j] = day;
      }
      last[j] = day;
      frequencies[j]++;
    }
    for (var j = 0; j < m; j++) {
      if (frequencies[j] != monthLengths[j]) {
        throw ArgumentError('§X weave multiplicities disagree.');
      }
      if (j > 0 &&
          (first[j - 1] >= first[j] || last[j - 1] >= last[j])) {
        throw ArgumentError('§X weave first/last ordering disagrees.');
      }
    }
    final offset = (requestedDay - openGate - BigInt.one).toInt();
    final month = monthIds[offset];
    var dayInMonth = 0;
    for (var day = 0; day <= offset; day++) {
      if (monthIds[day] == month) {
        dayInMonth++;
      }
    }
    MonsterMeatball? cutletAtDay;
    for (final cutlet in cutlets) {
      if (cutlet.contains(requestedDay)) {
        cutletAtDay = cutlet;
        break;
      }
    }
    if (cutletAtDay == null) {
      throw StateError('§X requested day has no cutlet.');
    }
    final monthIndex = monthNameIndices[month - 1];
    return MonsterFiveFieldDate._(
      yearNumber: yearNumber,
      cutletCanonicalIndex: cutletAtDay.nameIndex,
      cutletName: cutletAtDay.name,
      dayInCutlet: (requestedDay - cutletAtDay.openGate).toInt(),
      monthCanonicalIndex: monthIndex,
      monthName: SourceLanguageCatalog.monthText(monthIndex),
      dayInMonth: dayInMonth,
    );
  }
}
