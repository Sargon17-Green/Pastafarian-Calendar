import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

import 'pastafari_calendar_cli.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';
import '../test_support/normative_reference.dart' as normative;
import 'stage2_production14_weave_tests.dart' as weave_oracle;

var checks = 0;
var differentialSamples = 0;

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


void differentialBoundaryOracle() {
  final differentialWatch = Stopwatch()..start();
  final checksAtStart = checks;
  final calculationDate = GregorianCivilDate(BigInt.from(2026), 11, 28);
  final calculationDay = calculationDate.toSerialDay();
  final productionCalendar = MonsterFiveFieldCalendar();
  final productionYear = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(calculationDay),
  );

  final reference = normative.NormativeReference(
    anchorGateIndex: productionYear.candidate.openOrdinal,
    anchorGateDay: productionYear.candidate.openGate,
  );
  final referenceYear = reference.year5000(calculationDay);

  void compareYear(
    normative.Year expected,
    MonsterTraversedYear actual,
    String label,
  ) {
    require(expected.number == actual.yearNumber, label + ' year number');
    require(
      expected.openGateIndex == actual.candidate.openOrdinal,
      label + ' opening gate index',
    );
    require(
      expected.closeGateIndex == actual.candidate.closeOrdinal,
      label + ' closing gate index',
    );
    require(
      expected.openGateDay == actual.candidate.openGate,
      label + ' opening gate day',
    );
    require(
      expected.closeGateDay == actual.candidate.closeGate,
      label + ' closing gate day',
    );
  }

  compareYear(referenceYear, productionYear, 'Independent §R year 5000');
  final referencePrevious =
      reference.previousYear(calculationDay, referenceYear);
  final referenceNext = reference.nextYear(calculationDay, referenceYear);
  final productionPrevious =
      productionCalendar.traversal.previous(calculationDay, productionYear);
  final productionNext =
      productionCalendar.traversal.next(calculationDay, productionYear);
  require(
    referencePrevious.number == BigInt.from(4999),
    'Independent predecessor is year 4999',
  );
  require(
    referenceNext.number == BigInt.from(5001),
    'Independent successor is year 5001',
  );
  require(
    referencePrevious.closeGateDay == referenceYear.openGateDay,
    'Independent predecessor shares the opening boundary',
  );
  require(
    referenceNext.openGateDay == referenceYear.closeGateDay,
    'Independent successor shares the closing boundary',
  );
  compareYear(referencePrevious, productionPrevious, 'Independent §R year 4999');
  compareYear(referenceNext, productionNext, 'Independent §R year 5001');

  final independentlyClosedGate =
      reference.ensureGateIndex(referenceYear.closeGateIndex);
  require(
    independentlyClosedGate == referenceYear.closeGateDay,
    'Independent §O gate chain reaches the selected close gate',
  );
  require(
    referenceYear.openGateDay < calculationDay &&
        calculationDay <= referenceYear.closeGateDay,
    'Fixed calculation day lies in independently selected year 5000',
  );

  final structureSauce = reference.sauce(
    calculationDay,
    referenceYear.openGateDay + BigInt.one,
  );
  final referenceCutletCount =
      reference.chooseCutletCount(structureSauce, referenceYear);
  final referenceCutletPartition = reference.chooseCutletPartition(
    calculationDay,
    structureSauce,
    referenceYear,
    referenceCutletCount,
  );
  final referenceCutletNames =
      reference.chooseCutletNames(structureSauce, referenceCutletCount);
  final referenceCutlets = reference.materializeCutlets(
    referenceYear,
    referenceCutletPartition,
    referenceCutletNames,
  );

  final productionCutlets =
      productionCalendar.cutletPlanner.partition(
    calculationDay,
    productionYear,
  );
  require(
    productionCutlets.meatballCount == referenceCutletCount,
    'Independent §S cutlet count',
  );
  require(
    productionCutlets.meatballs.length == referenceCutlets.length,
    'Independent §T cutlet count',
  );
  for (var i = 0; i < referenceCutlets.length; i++) {
    final expected = referenceCutlets[i];
    final actual = productionCutlets.meatballs[i];
    require(
      BigInt.from(actual.intervalCount) == referenceCutletPartition[i],
      'Independent §T partition interval ' + (i + 1).toString(),
    );
    require(
      actual.nameIndex == referenceCutletNames[i] &&
          actual.nameIndex == expected.nameCanonicalIndex,
      'Independent §T cutlet name index ' + (i + 1).toString(),
    );
    require(
      actual.openGate == reference.ensureGateIndex(expected.openGateIndex) &&
          actual.closeGate == reference.ensureGateIndex(expected.closeGateIndex),
      'Independent §T cutlet gates ' + (i + 1).toString(),
    );
    require(
      actual.openGate + BigInt.one == expected.firstDay &&
          actual.closeGate == expected.lastDay,
      'Independent §T cutlet civil span ' + (i + 1).toString(),
    );
  }

  final referenceMonthCount =
      reference.chooseMonthCount(structureSauce, referenceYear);
  final referenceMonthLengths = reference.chooseMonthLengths(
    structureSauce,
    referenceYear,
    referenceMonthCount,
  );
  final productionMonthLengths =
      productionCalendar.lengthPlanner.plan(calculationDay, productionYear);
  require(
    productionMonthLengths.monthCount == referenceMonthCount,
    'Independent §U month count',
  );
  require(
    productionMonthLengths.lengths.length == referenceMonthLengths.length,
    'Independent §U month length vector size',
  );
  for (var i = 0; i < referenceMonthLengths.length; i++) {
    require(
      BigInt.from(productionMonthLengths.lengths[i]) ==
          referenceMonthLengths[i],
      'Independent §U month length ' + (i + 1).toString(),
    );
  }

  final productionWeave = productionCalendar.weavePlanner.plan(
    calculationDay,
    productionYear,
    productionMonthLengths,
  );
  final referenceMonthNames =
      reference.chooseMonthNames(structureSauce, referenceMonthCount);
  final productionMonthNames = productionCalendar.namePlanner.plan(
    calculationDay,
    productionYear,
    productionMonthLengths,
    productionWeave,
  );
  require(
    productionMonthNames.nameIndices.length == referenceMonthNames.length,
    'Independent §W month name count',
  );
  for (var i = 0; i < referenceMonthNames.length; i++) {
    require(
      productionMonthNames.nameIndices[i] == referenceMonthNames[i],
      'Independent §W month name index ' + (i + 1).toString(),
    );
  }

  final referenceWeaveRank = normative.NormativeReference.chooseRank(
    normative.NormativeReference.askBowl(
      structureSauce,
      4,
      normative.NormativeReference.sealMonthWeaving,
    ),
    productionWeave.weaveCount,
  );
  require(
    productionWeave.weaveChoice.result == referenceWeaveRank,
    'Independent §V bowl rank',
  );
  weave_oracle.validateWeave(
    productionMonthLengths.lengths,
    productionWeave.monthIds,
  );

  final referenceStructure = normative.YearStructure(
    cutletCount: referenceCutletCount,
    cutletPartition: referenceCutletPartition,
    cutletNameCanonicalIndices: referenceCutletNames,
    cutlets: referenceCutlets,
    monthCount: referenceMonthCount,
    monthLengths: referenceMonthLengths,
    monthWeaving: productionWeave.monthIds,
    monthNameCanonicalIndices: referenceMonthNames,
  );

  final firstDay = referenceYear.openGateDay + BigInt.one;
  final samples = <BigInt, Set<String>>{};
  void addSample(BigInt day, String label) {
    samples.putIfAbsent(day, () => <String>{}).add(label);
  }

  addSample(firstDay, 'year-start');
  addSample(referenceYear.closeGateDay, 'year-end');

  BigInt? fallbackCutletBoundary;
  BigInt? independentCutletBoundary;
  for (final cutlet in referenceCutlets.skip(1)) {
    final day = cutlet.firstDay;
    if (day == referenceYear.closeGateDay) {
      continue;
    }
    fallbackCutletBoundary ??= day;
    final offset = (day - firstDay).toInt();
    final isMonthBoundary = productionWeave.monthIds[offset] !=
        productionWeave.monthIds[offset - 1];
    if (!isMonthBoundary) {
      independentCutletBoundary = day;
      break;
    }
  }
  final cutletBoundary =
      independentCutletBoundary ?? fallbackCutletBoundary;
  if (cutletBoundary != null) {
    addSample(cutletBoundary, 'cutlet-boundary');
  }

  BigInt? fallbackMonthBoundary;
  BigInt? independentMonthBoundary;
  for (var offset = 1; offset < productionWeave.monthIds.length; offset++) {
    if (productionWeave.monthIds[offset] !=
        productionWeave.monthIds[offset - 1]) {
      final day = firstDay + BigInt.from(offset);
      fallbackMonthBoundary ??= day;
      if (!samples.containsKey(day)) {
        independentMonthBoundary = day;
        break;
      }
    }
  }
  final monthBoundary = independentMonthBoundary ?? fallbackMonthBoundary;
  if (monthBoundary != null) {
    addSample(monthBoundary, 'month-boundary');
  }
  require(cutletBoundary != null, 'Independent interior cutlet boundary exists');
  require(monthBoundary != null, 'Independent interior month boundary exists');
  require(samples.length >= 3, 'At least three distinct boundary samples');

  final converter = PastafariGregorianConverter();
  for (final entry in samples.entries) {
    final targetDay = entry.key;
    final labels = entry.value;
    final tuple = reference.calendarDateFromStructure(
      referenceYear,
      referenceStructure,
      targetDay,
    );
    require(
      tuple.yearNumber == BigInt.from(5000),
      'Reference tuple retains fixed year 5000',
    );

    final cutletIndex = SourceLanguageCatalog.cutletNames
        .singleWhere((name) => name.text == tuple.cutletName)
        .canonicalIndex;
    final monthIndex = SourceLanguageCatalog.monthNames
        .singleWhere((name) => name.text == tuple.monthName)
        .canonicalIndex;
    final cutlet = referenceCutlets.singleWhere(
      (item) => item.nameCanonicalIndex == cutletIndex,
    );
    final cutletProjection =
        cutlet.firstDay + tuple.dayInCutlet - BigInt.one;

    final monthPosition = referenceMonthNames.indexOf(monthIndex);
    if (monthPosition < 0) {
      throw StateError('Reference month name is absent from §W selection.');
    }
    final monthId = monthPosition + 1;
    var occurrence = BigInt.zero;
    BigInt? monthProjection;
    for (var offset = 0;
        offset < productionWeave.monthIds.length;
        offset++) {
      if (productionWeave.monthIds[offset] == monthId) {
        occurrence += BigInt.one;
        if (occurrence == tuple.dayInMonth) {
          monthProjection = firstDay + BigInt.from(offset);
          break;
        }
      }
    }
    if (monthProjection == null) {
      throw StateError('Reference month occurrence is absent from §V weave.');
    }
    require(
      cutletProjection == monthProjection && monthProjection == targetDay,
      'Independent cutlet/month coordinates agree at ' + labels.join('+'),
    );
    if (labels.contains('year-start')) {
      require(
        tuple.dayInCutlet == BigInt.one && tuple.dayInMonth == BigInt.one,
        'First day of year is first in its cutlet and month',
      );
    }
    if (labels.contains('year-end')) {
      final lastCutlet = referenceCutlets.last;
      require(
        tuple.dayInCutlet ==
            lastCutlet.lastDay - lastCutlet.firstDay + BigInt.one,
        'Last day of year is last in its cutlet',
      );
      require(
        tuple.dayInMonth == referenceMonthLengths.last,
        'Last day of year is last in its month',
      );
    }
    if (labels.contains('cutlet-boundary')) {
      require(
        tuple.dayInCutlet == BigInt.one,
        'First day of an interior cutlet',
      );
    }
    if (labels.contains('month-boundary')) {
      require(
        tuple.dayInMonth == BigInt.one,
        'First occurrence at an interior month boundary',
      );
    }

    final inverseInput = MonsterFiveFieldDate.fromComponents(
      yearNumber: tuple.yearNumber,
      cutletCanonicalIndex: cutletIndex,
      dayInCutlet: tuple.dayInCutlet.toInt(),
      monthCanonicalIndex: monthIndex,
      dayInMonth: tuple.dayInMonth.toInt(),
    );
    final actualDay = converter.toSerialDay(
      calculationDate,
      inverseInput,
      maxTransitions: 0,
    );
    require(
      actualDay == targetDay,
      'Production inverse matches independent boundary oracle: ' +
          labels.join('+'),
    );
  }

  differentialSamples = samples.length;
  differentialWatch.stop();
  final differentialChecks = checks - checksAtStart;
  require(
    differentialWatch.elapsedMilliseconds <= 330000,
    'Independent inverse boundary oracle time budget',
  );
  print(
    'PRODUCTION_INVERSE_DIFFERENTIAL_TIME_MS=' +
        differentialWatch.elapsedMilliseconds.toString(),
  );
  print(
    'PRODUCTION_INVERSE_DIFFERENTIAL_PASS samples=' +
        differentialSamples.toString() +
        ' checks=' +
        differentialChecks.toString() +
        ' fixed_c=2026-11-28 year=5000 transitions=0',
  );
}

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

  differentialBoundaryOracle();

  final elapsed = watch.elapsedMilliseconds;
  print('PRODUCTION_INVERSE_FIXED_C_TIMING elapsed_ms=' + elapsed.toString());
  require(
    elapsed <= 450000,
    'Fixed-c forward/inverse and differential time budget',
  );
  print('PRODUCTION_INVERSE_FIXED_C_PASS checks=' +
      checks.toString() +
      ' modern_calculation_day=2026-11-28 fixed_c=true transitions=1 differential_samples=' +
      differentialSamples.toString() +
      ' elapsed_ms=' +
      elapsed.toString());
}
