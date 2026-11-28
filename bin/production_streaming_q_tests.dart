import '../lib/src/monster_meatball_gates.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_locator.dart';

var checks = 0;

void require(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError(label);
  }
}

// Independent full prefix, retained only by QA. Each eligible pair is
// enumerated without using the production snapshot/window builder.
void compare(
  BigInt day,
  BigInt foundation,
  BigInt Function(BigInt) gap, {
  bool real = false,
}) {
  final lower = day - BigInt.from(5778);
  final upper = day + BigInt.from(5777);
  final full = <int, BigInt>{0: foundation};
  var left = foundation;
  var right = foundation;
  var lo = 0;
  var hi = 0;
  final watch = Stopwatch()..start();
  while (left >= lower) {
    lo--;
    left -= gap(BigInt.from(lo));
    full[lo] = left;
    require(-lo <= 400000, 'oracle left bound');
  }
  while (right <= upper) {
    hi++;
    right += gap(BigInt.from(hi));
    full[hi] = right;
    require(hi <= 400000, 'oracle right bound');
  }
  final oracleMs = watch.elapsedMilliseconds;
  var calls = 0;
  final seen = <BigInt>{};
  watch.reset();
  final window = MonsterYearLocator.streamGateWindow(
    day,
    foundation,
    (ordinal) {
      require(ordinal != BigInt.zero && seen.add(ordinal), 'duplicate gap');
      calls++;
      return gap(ordinal);
    },
    maximumGapCalls: 400000,
  );
  final streamMs = watch.elapsedMilliseconds;
  final keys = full.keys.toList()..sort();
  final local = keys.where((i) => full[i]! >= lower && full[i]! <= upper);
  final strictLeft = keys.lastWhere((i) => full[i]! < lower);
  final strictRight = keys.firstWhere((i) => full[i]! > upper);
  final expectedKeys = <int>[strictLeft, ...local, strictRight];
  require(window.length == expectedKeys.length, 'window count');
  require(window.length <= 278, 'window bound');
  require(calls == hi - lo, 'exact gap calls');
  for (final i in expectedKeys) {
    require(window[i] == full[i], 'signed position');
  }
  final expected = <(int, int, BigInt, BigInt)>[];
  for (final i in expectedKeys) {
    for (final j in expectedKeys) {
      final open = full[i]!;
      final close = full[j]!;
      final length = close - open;
      if (j - i >= 6 &&
          open < day &&
          close >= day &&
          length >= BigInt.from(252) &&
          length <= BigInt.from(5778)) {
        expected.add((i, j, open, close));
      }
    }
  }
  expected.sort((a, b) {
    final order = (a.$4 - a.$3).compareTo(b.$4 - b.$3);
    return order == 0 ? a.$3.compareTo(b.$3) : order;
  });
  final actual = MonsterYearLocator.fromGateSnapshot(day, window);
  require(actual.complete, 'strict sentinels');
  require(actual.candidates.length == expected.length, 'pair count');
  for (var i = 0; i < expected.length; i++) {
    final a = actual.candidates[i];
    final e = expected[i];
    require(
      a.openOrdinal == BigInt.from(e.$1) &&
          a.closeOrdinal == BigInt.from(e.$2) &&
          a.openGate == e.$3 &&
          a.closeGate == e.$4 &&
          a.length == e.$4 - e.$3,
      'ordered pair',
    );
  }
  if (real) {
    print('REAL_Q day=$day gaps=$calls window=${window.length} '
        'pairs=${expected.length} oracle_ms=$oracleMs stream_ms=$streamMs');
  }
}

void rejectBudget(BigInt day, int budget) {
  try {
    MonsterYearLocator.streamGateWindow(
      day,
      BigInt.zero,
      (_) => BigInt.from(42),
      maximumGapCalls: budget,
    );
  } on IncompleteMonsterYearDomain {
    checks++;
    return;
  }
  throw StateError('Missing budget rejection');
}

void main(List<String> args) {
  for (final gap in <BigInt Function(BigInt)>[
    (_) => BigInt.from(42),
    (_) => BigInt.from(963),
    (i) => BigInt.from(42) + (i * i + i * BigInt.from(17)) % BigInt.from(922),
  ]) {
    for (final day in <int>[
      -15795619, -20000, -5777, -1, 0, 1, 5778, 20000, 15795619,
    ]) {
      compare(BigInt.from(day), BigInt.zero, gap);
    }
  }
  rejectBudget(BigInt.zero, 1);
  rejectBudget(BigInt.one << 190, 400000);
  rejectBudget(BigInt.from(10000), 20);
  for (final invalid in <int>[41, 964]) {
    var rejected = false;
    try {
      MonsterYearLocator.streamGateWindow(
        BigInt.zero,
        BigInt.zero,
        (_) => BigInt.from(invalid),
        maximumGapCalls: 400000,
      );
    } on StateError {
      rejected = true;
    }
    require(rejected, 'invalid gap');
  }
  final calculator = MonsterMeatballGateCalculator();
  final f = MonsterWorkCounter.foundationDay;
  BigInt realGap(BigInt i) => calculator.gapFor(i).length;
  compare(f, f, realGap, real: true);
  print('PRODUCTION_STREAMING_Q_SYNTHETIC_NEAR_PASS checks=$checks');
  if (args.contains('--modern')) {
    final modern = BigInt.from(
      DateTime.utc(2026, 11, 28).difference(DateTime.utc(1, 1, 1)).inDays + 1,
    );
    compare(modern, f, realGap, real: true);
    print('PRODUCTION_STREAMING_Q_MODERN_PASS checks=$checks');
  }
}
