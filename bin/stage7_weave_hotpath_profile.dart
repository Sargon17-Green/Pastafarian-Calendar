import 'dart:io';

import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_weave_counter.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;
var smallRanks = 0;
final timings = <String, int>{};

void check(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError('STAGE7_HOTPATH_FAILED: $label');
  }
}

T measure<T>(String name, T Function() compute) {
  final timer = Stopwatch()..start();
  final value = compute();
  timer.stop();
  timings[name] = timer.elapsedMilliseconds;
  print('STAGE7_PHASE_${name}_MS=${timer.elapsedMilliseconds}');
  return value;
}

// An independent leaf-filter oracle: enumerate ordinary multiset words
// before checking first and last appearance orders. No production DP used.
List<List<int>> independentSmallWords(List<int> lengths) {
  final remaining = List<int>.of(lengths);
  final current = <int>[];
  final accepted = <List<int>>[];
  final days = lengths.fold<int>(0, (sum, n) => sum + n);

  void visit() {
    if (current.length == days) {
      final first = List<int>.filled(lengths.length, -1);
      final last = List<int>.filled(lengths.length, -1);
      for (var day = 0; day < days; day++) {
        final index = current[day] - 1;
        if (first[index] == -1) {
          first[index] = day;
        }
        last[index] = day;
      }
      for (var i = 1; i < lengths.length; i++) {
        if (first[i - 1] >= first[i] || last[i - 1] >= last[i]) {
          return;
        }
      }
      accepted.add(List<int>.of(current));
      return;
    }
    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i] == 0) {
        continue;
      }
      remaining[i]--;
      current.add(i + 1);
      visit();
      current.removeLast();
      remaining[i]++;
    }
  }

  visit();
  return accepted;
}

void validateFullWord(List<int> lengths, List<int> word) {
  final days = lengths.fold<int>(0, (sum, n) => sum + n);
  check(word.length == days, 'Full-year word length');
  final observed = List<int>.filled(lengths.length, 0);
  final first = List<int>.filled(lengths.length, -1);
  final last = List<int>.filled(lengths.length, -1);
  for (var day = 0; day < word.length; day++) {
    final index = word[day] - 1;
    check(index >= 0 && index < lengths.length, 'Day month index');
    observed[index]++;
    if (first[index] == -1) {
      first[index] = day;
    }
    last[index] = day;
  }
  for (var i = 0; i < lengths.length; i++) {
    check(observed[i] == lengths[i], 'Exact month multiplicity');
    if (i > 0) {
      check(first[i - 1] < first[i], 'Ascending first occurrences');
      check(last[i - 1] < last[i], 'Ascending last occurrences');
    }
  }
}

/// SHA-256 of UTF-8 decimal count or comma-separated month IDs (no newline).
/// The native Ubuntu CI runner supplies sha256sum.
void recordBaselineDigest(String label, String payload) {
  final temp = Directory.systemTemp.createTempSync('stage7_baseline_');
  try {
    final file = File('${temp.path}/payload.txt');
    file.writeAsStringSync(payload, flush: true);
    final run = Process.runSync('sha256sum', <String>[file.path]);
    final match = RegExp(r'^[0-9a-f]{64}').firstMatch(run.stdout.toString());
    if (run.exitCode != 0 || match == null) {
      throw StateError('Stage7 baseline SHA-256 unavailable: $label');
    }
    print('STAGE7_BASELINE_${label}_SHA256=${match.group(0)}');
  } finally {
    temp.deleteSync(recursive: true);
  }
}

bool rejectsRank(List<int> lengths, BigInt rank) {
  try {
    MonsterMonthWeavePlanner.unrankFull(lengths, rank);
  } on ArgumentError {
    return true;
  }
  return false;
}

void main() {
  const maximumMilliseconds = 180000;
  final foundation = BigInt.from(-15055671);
  final year = MonsterYearTraversal().resolve(
    foundation,
    foundation,
    maxTransitions: 0,
  );
  final lengths = const MonsterMonthLengthPlanner().plan(foundation, year);
  check(year.yearNumber == BigInt.from(5000), 'Canonical year');
  check(
    lengths.lengths.fold<int>(0, (sum, n) => sum + n) ==
        (year.candidate.closeGate - year.candidate.openGate).toInt(),
    'Canonical year/day total',
  );

  // The independent leaf filter deliberately never calls production DP.
  // Exactly six domains and 55 admissible one-based ranks.
  final fixtures = <List<int>>[
    <int>[2, 2, 1],
    <int>[2, 2, 2],
    <int>[3, 2, 2],
    <int>[2, 3, 2],
    <int>[1, 2, 2],
    <int>[3, 3, 2],
  ];
  final expectedCounts = <int>[2, 5, 9, 11, 2, 26];
  for (var fixture = 0; fixture < fixtures.length; fixture++) {
    final input = List<int>.of(fixtures[fixture]);
    final independentlyAccepted = independentSmallWords(input);
    check(independentlyAccepted.isNotEmpty, 'Oracle fixture $fixture');
    check(
      independentlyAccepted.length == expectedCounts[fixture],
      'Independent count fixture $fixture',
    );
    final counted = MonsterMonthWeaveCounter.countWholeWeaves(input);
    check(
      counted == BigInt.from(independentlyAccepted.length),
      'Production count fixture $fixture',
    );
    for (var rank = 1; rank <= independentlyAccepted.length; rank++) {
      final word = MonsterMonthWeavePlanner.unrankFull(
        input,
        BigInt.from(rank),
      );
      check(
        word.join(',') == independentlyAccepted[rank - 1].join(','),
        'Independent exact rank $rank fixture $fixture',
      );
      smallRanks++;
    }
    check(
      rejectsRank(input, BigInt.zero),
      'Reject rank zero fixture $fixture',
    );
    check(
      rejectsRank(input, counted + BigInt.one),
      'Reject rank count+1 fixture $fixture',
    );
    final firstWord = MonsterMonthWeavePlanner.unrankFull(input, BigInt.one);
    var mutationRejected = false;
    try {
      firstWord[0] = 99;
    } on UnsupportedError {
      mutationRejected = true;
    }
    check(mutationRejected, 'Immutable word fixture $fixture');
    check(
      input.join(',') == fixtures[fixture].join(','),
      'Immutable input fixture $fixture',
    );
  }
  check(smallRanks == 55, 'Six independent fixtures cover 55 ranks');

  final totalTimer = Stopwatch()..start();
  final count = measure(
    'COUNT',
    () => MonsterMonthWeaveCounter.countWholeWeaves(lengths.lengths),
  );
  final lexFirst = measure(
    'FIRST',
    () => MonsterMonthWeavePlanner.unrankFull(
      lengths.lengths,
      BigInt.one,
    ),
  );
  final lexLast = measure(
    'LAST',
    () => MonsterMonthWeavePlanner.unrankFull(lengths.lengths, count),
  );
  final canonical = measure(
    'CANONICAL',
    () => const MonsterMonthWeavePlanner().plan(foundation, year, lengths),
  );
  totalTimer.stop();

  // Record baseline before changing production: exact ASCII payloads,
  // comma-separated 1-based words and decimal BigInt, no trailing newline.
  recordBaselineDigest('COUNT', count.toString());
  recordBaselineDigest('FIRST', lexFirst.join(','));
  recordBaselineDigest('LAST', lexLast.join(','));
  recordBaselineDigest('CANONICAL', canonical.monthIds.join(','));
  print('STAGE7_BASELINE_CANONICAL_RANK=${canonical.weaveChoice.result}');

  check(count > (BigInt.one << 127), 'Exact large-count domain');
  check(canonical.weaveCount == count, 'Canonical count equals isolated count');
  check(canonical.weaveChoice.modulus == count, 'Canonical choice modulus');
  check(
    canonical.weaveChoice.result >= BigInt.one &&
        canonical.weaveChoice.result <= count,
    'Canonical rank in range',
  );
  validateFullWord(lengths.lengths, lexFirst);
  validateFullWord(lengths.lengths, lexLast);
  validateFullWord(lengths.lengths, canonical.monthIds);
  final literalFirst = <int>[
    for (var i = 0; i < lengths.lengths.length; i++)
      ...List<int>.filled(lengths.lengths[i], i + 1),
  ];
  check(lexFirst.join(',') == literalFirst.join(','), 'Literal first word');
  check(timings.length == 4, 'Four isolated phases');
  final phaseSum = timings.values.fold<int>(0, (sum, n) => sum + n);
  check(
    phaseSum <= totalTimer.elapsedMilliseconds,
    'Subphases bounded by total',
  );
  check(
    totalTimer.elapsedMilliseconds <= maximumMilliseconds,
    'Bounded hotpath measurement',
  );
  final perWordChecks = lengths.yearLength + 3 * lengths.monthCount - 1;
  // Initial 2 checks + six groups of 7 + 55 exact ranks + 1 coverage
  // check, followed by 8 independent full-year checks.
  final expectedBeforeCoverage = 108 + 3 * perWordChecks;
  check(
    checks == expectedBeforeCoverage,
    'Complete full-year validation coverage',
  );
  check(smallRanks >= 1, 'At least one independent small rank');

  print('STAGE7_TOTAL_MS=${totalTimer.elapsedMilliseconds}');
  print('STAGE7_HOTPATH_PASS; checks=$checks; year_days=${lengths.yearLength}; '
      'month_count=${lengths.monthCount}; full_year_words=3; '
      'small_domains=6; small_ranks=$smallRanks; canonical_case=1; '
      'phases=4; algorithm_unchanged=true');
}
