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

  /// Construct input components; canonical Hebrew names are derived by index.
  factory MonsterFiveFieldDate.fromComponents({
    required BigInt yearNumber,
    required int cutletCanonicalIndex,
    required int dayInCutlet,
    required int monthCanonicalIndex,
    required int dayInMonth,
  }) {
    if (dayInCutlet < 1) {
      throw ArgumentError.value(dayInCutlet, 'dayInCutlet', 'Must be positive.');
    }
    if (dayInMonth < 1) {
      throw ArgumentError.value(dayInMonth, 'dayInMonth', 'Must be positive.');
    }
    return MonsterFiveFieldDate._(
      yearNumber: yearNumber,
      cutletCanonicalIndex: cutletCanonicalIndex,
      cutletName: SourceLanguageCatalog.cutletText(cutletCanonicalIndex),
      dayInCutlet: dayInCutlet,
      monthCanonicalIndex: monthCanonicalIndex,
      monthName: SourceLanguageCatalog.monthText(monthCanonicalIndex),
      dayInMonth: dayInMonth,
    );
  }

  List<Object> get canonicalComponents => List<Object>.unmodifiable(<Object>[
        yearNumber,
        cutletCanonicalIndex,
        dayInCutlet,
        monthCanonicalIndex,
        dayInMonth,
      ]);
}

/// The inverse year-number search has a finite, explicit transition budget.
final class IncompleteMonsterYearNumberTraversal implements Exception {
  final BigInt calculationDay;
  final BigInt requestedYearNumber;
  final int completedTransitions;
  final int maximumTransitions;

  const IncompleteMonsterYearNumberTraversal(
    this.calculationDay,
    this.requestedYearNumber,
    this.completedTransitions,
    this.maximumTransitions,
  );

  @override
  String toString() => 'Incomplete §R year-number traversal.';
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

  /// Invert five numeric components to the exact serial day under fixed c.
  /// Both the year-number walk and all partition questions retain calculationDay.
  BigInt toSerialDay(
    BigInt calculationDay,
    MonsterFiveFieldDate date, {
    int maxTransitions = MonsterYearTraversal.maximumTransitions,
  }) {
    final cutletName = SourceLanguageCatalog.cutletText(
      date.cutletCanonicalIndex,
    );
    final monthName = SourceLanguageCatalog.monthText(
      date.monthCanonicalIndex,
    );
    if (date.cutletName != cutletName || date.monthName != monthName) {
      throw ArgumentError('Canonical names disagree with their indices.');
    }
    if (date.dayInCutlet < 1 || date.dayInMonth < 1) {
      throw ArgumentError('Day ordinals must be positive.');
    }
    if (maxTransitions < 0 ||
        maxTransitions > MonsterYearTraversal.maximumTransitions) {
      throw RangeError.range(
        maxTransitions,
        0,
        MonsterYearTraversal.maximumTransitions,
      );
    }

    var year = MonsterTraversedYear.from5000(
      traversal.anchor.select(calculationDay),
    );
    final delta = date.yearNumber - year.yearNumber;
    final requiredTransitions = delta.abs();
    if (requiredTransitions > BigInt.from(maxTransitions)) {
      throw IncompleteMonsterYearNumberTraversal(
        calculationDay,
        date.yearNumber,
        0,
        maxTransitions,
      );
    }
    final transitionCount = requiredTransitions.toInt();
    for (var step = 0; step < transitionCount; step++) {
      year = delta < BigInt.zero
          ? traversal.previous(calculationDay, year)
          : traversal.next(calculationDay, year);
    }

    final partition = cutletPlanner.partition(calculationDay, year);
    final lengths = lengthPlanner.plan(calculationDay, year);
    final weave = weavePlanner.plan(calculationDay, year, lengths);
    final names = namePlanner.plan(calculationDay, year, lengths, weave);

    final monthPosition = names.nameIndices.indexOf(date.monthCanonicalIndex);
    if (monthPosition < 0) {
      throw ArgumentError('Month name is not selected for this year.');
    }
    final monthLength = lengths.lengths[monthPosition];
    if (date.dayInMonth > monthLength) {
      throw RangeError.range(date.dayInMonth, 1, monthLength, 'dayInMonth');
    }
    final monthId = monthPosition + 1;
    var occurrence = 0;
    var offset = -1;
    for (var day = 0; day < weave.monthIds.length; day++) {
      if (weave.monthIds[day] == monthId) {
        occurrence++;
        if (occurrence == date.dayInMonth) {
          offset = day;
          break;
        }
      }
    }
    if (offset < 0) {
      throw StateError('Selected month occurrence is missing from the weave.');
    }
    final requestedDay = year.candidate.openGate + BigInt.from(offset + 1);

    final matchingCutlets = partition.meatballs
        .where((cutlet) => cutlet.nameIndex == date.cutletCanonicalIndex)
        .toList();
    if (matchingCutlets.length != 1) {
      throw ArgumentError('Cutlet name is not unique in this year.');
    }
    final cutlet = matchingCutlets.single;
    final cutletLength = cutlet.closeGate - cutlet.openGate;
    if (date.dayInCutlet > cutletLength.toInt()) {
      throw RangeError.range(
        date.dayInCutlet,
        1,
        cutletLength.toInt(),
        'dayInCutlet',
      );
    }
    final cutletDay = cutlet.openGate + BigInt.from(date.dayInCutlet);
    if (cutletDay != requestedDay) {
      throw ArgumentError('Cutlet and month components identify different days.');
    }
    return requestedDay;
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
      if (j > 0 && (first[j - 1] >= first[j] || last[j - 1] >= last[j])) {
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
