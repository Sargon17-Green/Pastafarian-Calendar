import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_weave_counter.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;
var independentRanks = 0;
var fullYearCases = 0;
var canonicalAnchors = 0;

void check(bool condition, String detail) {
  checks++;
  if (!condition) {
    throw StateError('PRODUCTION14_WEAVE_FAILED: $detail');
  }
}

/// Independent oracle: enumerate ordinary multiset permutations first,
/// then filter both first- and last-appearance orders at the leaves.
/// It does not use the production suffix counter or its insertion formulas.
List<List<int>> enumerateAccepted(List<int> lengths) {
  final remaining = List<int>.of(lengths);
  final word = <int>[];
  final accepted = <List<int>>[];
  final total = lengths.fold<int>(0, (sum, n) => sum + n);
  void visit() {
    if (word.length == total) {
      final first = List<int>.filled(lengths.length, -1);
      final last = List<int>.filled(lengths.length, -1);
      for (var index = 0; index < word.length; index++) {
        final j = word[index] - 1;
        if (first[j] == -1) {
          first[j] = index;
        }
        last[j] = index;
      }
      var ordered = true;
      for (var j = 1; j < lengths.length; j++) {
        if (first[j - 1] >= first[j] || last[j - 1] >= last[j]) {
          ordered = false;
          break;
        }
      }
      if (ordered) {
        accepted.add(List<int>.of(word));
      }
      return;
    }
    for (var j = 0; j < remaining.length; j++) {
      if (remaining[j] == 0) {
        continue;
      }
      remaining[j]--;
      word.add(j + 1);
      visit();
      word.removeLast();
      remaining[j]++;
    }
  }

  visit();
  return accepted;
}

void validateWeave(List<int> lengths, List<int> word) {
  check(
    word.length == lengths.fold<int>(0, (sum, n) => sum + n),
    'Word covers exactly all days',
  );
  final counts = List<int>.filled(lengths.length, 0);
  final first = List<int>.filled(lengths.length, -1);
  final last = List<int>.filled(lengths.length, -1);
  for (var day = 0; day < word.length; day++) {
    final id = word[day];
    check(id >= 1 && id <= lengths.length, 'Month ID range');
    counts[id - 1]++;
    if (first[id - 1] == -1) {
      first[id - 1] = day;
    }
    last[id - 1] = day;
  }
  check(counts.join(',') == lengths.join(','), 'Exact multiplicities');
  for (var i = 1; i < lengths.length; i++) {
    check(first[i - 1] < first[i], 'First appearance order');
    check(last[i - 1] < last[i], 'Last appearance order');
  }
}

void independentSmallOracle() {
  for (final lengths in <List<int>>[
    <int>[1, 1, 1],
    <int>[1, 2, 1],
    <int>[2, 3],
    <int>[2, 1, 2],
    <int>[1, 3, 2],
    <int>[2, 2, 1, 2],
    <int>[3, 1, 3],
    <int>[2, 2, 2, 3],
  ]) {
    final expected = enumerateAccepted(lengths);
    check(expected.isNotEmpty, 'Brute domain nonempty');
    check(
      MonsterMonthWeaveCounter.countWholeWeaves(lengths) ==
          BigInt.from(expected.length),
      'Independent total count',
    );
    for (var i = 0; i < expected.length; i++) {
      final actual = MonsterMonthWeavePlanner.unrankFull(
        lengths,
        BigInt.from(i + 1),
      );
      check(
        actual.join(',') == expected[i].join(','),
        'Independent lex rank ${i + 1} for $lengths',
      );
      independentRanks++;
    }
  }
}

void refusalOracle() {
  var refused = false;
  try {
    MonsterMonthWeavePlanner.unrankFull(<int>[2, 3], BigInt.zero);
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Zero rank rejected');
  refused = false;
  try {
    final lengths = <int>[2, 3];
    MonsterMonthWeavePlanner.unrankFull(
      lengths,
      MonsterMonthWeaveCounter.countWholeWeaves(lengths) + BigInt.one,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Out-of-range rank rejected');
  refused = false;
  try {
    MonsterMonthWeavePlanner.unrankFull(<int>[0, 2, 3], BigInt.one);
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Invalid month vector rejected');
}

void scaleOracle() {
  final lengths = <int>[120, ...List<int>.filled(46, 123)];
  final watch = Stopwatch()..start();
  final total = MonsterMonthWeaveCounter.countWholeWeaves(lengths);
  check(total > (BigInt.one << 127), 'Large BigInt count, no truncation');
  for (final rank in <BigInt>[BigInt.one, total]) {
    final word = MonsterMonthWeavePlanner.unrankFull(lengths, rank);
    validateWeave(lengths, word);
    if (rank == BigInt.one) {
      final lexFirst = <int>[
        for (var i = 0; i < lengths.length; i++)
          ...List<int>.filled(lengths[i], i + 1),
      ];
      check(word.join(',') == lexFirst.join(','), 'Known lexicographic first');
    }
    fullYearCases++;
  }
  watch.stop();
  check(
    watch.elapsed.inSeconds <= 240,
    'Two full 5778-day ranks exceed 240-second budget',
  );
  print('PRODUCTION14_FULL_YEAR_TIME_MS=${watch.elapsedMilliseconds}');
}

void canonicalCase() {
  final day = MonsterWorkCounter.foundationDay;
  final year = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(day),
  );
  final lengths = const MonsterMonthLengthPlanner().plan(day, year);
  final selected = const MonsterMonthWeavePlanner().plan(
    day,
    year,
    lengths,
  );
  check(
    selected.weaveCount ==
        MonsterMonthWeaveCounter.countWholeWeaves(lengths.lengths),
    'Full count is the canonical §V modulus',
  );
  check(selected.weaveChoice.modulus == selected.weaveCount,
      'Bowl 4 seal 32 chooses exact full weave domain');
  check(
    selected.weaveChoice.result >= BigInt.one &&
        selected.weaveChoice.result <= selected.weaveCount,
    'Exact one-based §V rank',
  );
  validateWeave(lengths.lengths, selected.monthIds);
  canonicalAnchors++;
}

void main() {
  independentSmallOracle();
  refusalOracle();
  scaleOracle();
  canonicalCase();
  check(independentRanks >= 20, 'At least 20 independent exact ranks');
  check(fullYearCases == 2, 'Two full-year 5778-day boundary ranks');
  check(canonicalAnchors == 1, 'One canonical bowl 4 seal 32 anchor');
  print('PRODUCTION14_WEAVE_PASS; checks=$checks; '
      'independent_ranks=$independentRanks; full_year_cases=$fullYearCases; '
      'canonical_anchors=$canonicalAnchors; full_weave_ready=true; '
      'five_component_calendar_ready=false');
}
