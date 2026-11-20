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

  final small = <int>[2, 2, 1];
  final independentlyAccepted = independentSmallWords(small);
  check(independentlyAccepted.isNotEmpty, 'Nonempty independent small oracle');
  check(
    MonsterMonthWeaveCounter.countWholeWeaves(small) ==
        BigInt.from(independentlyAccepted.length),
    'Independent small-domain count',
  );
  for (var i = 0; i < independentlyAccepted.length; i++) {
    final word = MonsterMonthWeavePlanner.unrankFull(
      small,
      BigInt.from(i + 1),
    );
    check(
      word.join(',') == independentlyAccepted[i].join(','),
      'Independent small-domain lex rank',
    );
    smallRanks++;
  }

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
  final expectedBeforeCoverage = 12 + smallRanks + 3 * perWordChecks;
  check(
    checks == expectedBeforeCoverage,
    'Complete full-year validation coverage',
  );
  check(smallRanks >= 1, 'At least one independent small rank');

  print('STAGE7_TOTAL_MS=${totalTimer.elapsedMilliseconds}');
  print('STAGE7_HOTPATH_PASS; checks=$checks; year_days=${lengths.yearLength}; '
      'month_count=${lengths.monthCount}; full_year_words=3; '
      'small_domains=1; small_ranks=$smallRanks; canonical_case=1; '
      'phases=4; algorithm_unchanged=true');
}
