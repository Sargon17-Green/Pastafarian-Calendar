import '../lib/src/monster_five_field_calendar.dart';
import '../lib/src/monster_meatball_partition.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/source_language_catalog.dart';

var checks = 0;
var syntheticCases = 0;
var canonicalAnchors = 0;

void check(bool ok, String description) {
  checks++;
  if (!ok) {
    throw StateError('PRODUCTION16_DATE_FAILED: $description');
  }
}

void reject(void Function() body, String description) {
  var rejected = false;
  try {
    body();
  } on ArgumentError {
    rejected = true;
  }
  check(rejected, description);
}

/// Independent absolute cutlet and prefix-occurrence oracle.
void syntheticOracle() {
  const cutletIndices = <int>[3, 5, 7, 9, 11, 13];
  const monthNames = <int>[20, 4, 47];
  final cutlets = <MonsterMeatball>[
    for (var i = 0; i < 6; i++)
      MonsterMeatball(
        number: i + 1,
        intervalCount: 1,
        openGate: BigInt.from(i * 2),
        closeGate: BigInt.from(i * 2 + 2),
        nameIndex: cutletIndices[i],
        name: SourceLanguageCatalog.cutletText(cutletIndices[i]),
      ),
  ];
  final weaves = <List<int>>[
    <int>[1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3],
    <int>[1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    <int>[1, 1, 2, 2, 3, 3, 1, 2, 3, 1, 2, 3],
  ];
  for (final weave in weaves) {
    for (var offset = 0; offset < weave.length; offset++) {
      final date = MonsterFiveFieldCalendar.project(
        yearNumber: BigInt.from(900),
        openGate: BigInt.zero,
        closeGate: BigInt.from(12),
        requestedDay: BigInt.from(offset + 1),
        cutlets: cutlets,
        monthLengths: <int>[4, 4, 4],
        monthIds: weave,
        monthNameIndices: monthNames,
      );
      final cutletPosition = offset ~/ 2;
      final monthId = weave[offset];
      var expectedMonthDay = 0;
      for (var i = 0; i <= offset; i++) {
        if (weave[i] == monthId) {
          expectedMonthDay++;
        }
      }
      check(date.yearNumber == BigInt.from(900), 'Year number');
      check(date.cutletCanonicalIndex == cutletIndices[cutletPosition],
          'Independent cutlet index');
      check(date.dayInCutlet == offset % 2 + 1, 'Independent cutlet day');
      check(date.monthCanonicalIndex == monthNames[monthId - 1],
          'Independent month index');
      check(date.dayInMonth == expectedMonthDay,
          'Independent inclusive month occurrence');
      check(date.cutletName ==
          SourceLanguageCatalog.cutletText(cutletIndices[cutletPosition]),
          'Locked cutlet text');
      check(date.monthName ==
          SourceLanguageCatalog.monthText(monthNames[monthId - 1]),
          'Locked month text');
      final tuple = date.canonicalComponents;
      check(tuple.length == 5, 'Exactly five components');
      check(tuple[2] == date.dayInCutlet && tuple[4] == expectedMonthDay,
          'Numeric tuple values');
      var immutable = false;
      try {
        tuple.add(0);
      } on UnsupportedError {
        immutable = true;
      }
      check(immutable, 'Canonical tuple immutable');
      syntheticCases++;
    }
  }
  check(syntheticCases == 36, '36 complete synthetic date mappings');

  void projectWrong({
    required BigInt requested,
    List<int>? lengths,
    List<int>? ids,
    List<int>? indices,
  }) {
    MonsterFiveFieldCalendar.project(
      yearNumber: BigInt.one,
      openGate: BigInt.zero,
      closeGate: BigInt.from(12),
      requestedDay: requested,
      cutlets: cutlets,
      monthLengths: lengths ?? <int>[4, 4, 4],
      monthIds: ids ?? weaves.first,
      monthNameIndices: indices ?? monthNames,
    );
  }
  reject(() => projectWrong(requested: BigInt.zero), 'Open gate excluded');
  reject(() => projectWrong(requested: BigInt.from(13)),
      'After closing gate excluded');
  reject(
    () => projectWrong(requested: BigInt.one, indices: <int>[20, 20, 47]),
    'Duplicate name refused',
  );
  reject(
    () => projectWrong(requested: BigInt.one, lengths: <int>[5, 3, 4]),
    'Month shorter than 4 refused',
  );
  reject(
    () => projectWrong(
      requested: BigInt.one,
      ids: <int>[1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 2],
    ),
    'Wrong multiplicities refused',
  );
}

/// Normative retained-sum README AC.1; never use superseded AC.2.
void canonicalOracle() {
  final foundation = MonsterWorkCounter.foundationDay;
  final cases = <({int delta, int cutlet, int cutletDay, int month, int monthDay})>[
    (delta: 0, cutlet: 10, cutletDay: 503, month: 20, monthDay: 56),
    (delta: -1, cutlet: 10, cutletDay: 502, month: 32, monthDay: 21),
    (delta: 1, cutlet: 14, cutletDay: 1, month: 29, monthDay: 38),
  ];
  final clock = Stopwatch()..start();
  final calculator = MonsterFiveFieldCalendar();
  for (final testCase in cases) {
    final result = calculator.calculate(
      foundation,
      foundation + BigInt.from(testCase.delta),
    );
    check(result.yearNumber == BigInt.from(5000), 'Canonical year 5000');
    check(result.cutletCanonicalIndex == testCase.cutlet,
        'AC.1 cutlet index');
    check(result.dayInCutlet == testCase.cutletDay, 'AC.1 cutlet ordinal');
    check(result.monthCanonicalIndex == testCase.month, 'AC.1 month index');
    check(result.dayInMonth == testCase.monthDay, 'AC.1 month ordinal');
    check(result.cutletName ==
        SourceLanguageCatalog.cutletText(testCase.cutlet),
        'AC.1 Hebrew cutlet');
    check(result.monthName ==
        SourceLanguageCatalog.monthText(testCase.month),
        'AC.1 Hebrew month');
    canonicalAnchors++;
  }
  clock.stop();
  check(clock.elapsed.inSeconds <= 240, 'Three canonical results <=240s');
  print('PRODUCTION16_CANONICAL_TIME_MS=$clock.elapsedMilliseconds');
}

void main() {
  syntheticOracle();
  canonicalOracle();
  check(checks >= 380, 'At least 380 checks');
  check(syntheticCases == 36, '36 independent synthetic projections');
  check(canonicalAnchors == 3, 'Three normative AC.1 vectors');
  print('PRODUCTION16_DATE_PASS; checks=$checks; '
      'synthetic_cases=$syntheticCases; canonical_anchors=$canonicalAnchors; '
      'five_component_calendar_ready=true');
}
