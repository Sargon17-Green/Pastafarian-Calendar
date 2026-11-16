import '../lib/src/monster_five_field_calendar.dart';
import '../lib/src/monster_meatball_partition.dart';
import '../lib/src/monster_month_weave_counter.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/source_language_catalog.dart';

var checks = 0;
var bruteWords = 0;
var validWords = 0;
var rankProbes = 0;
var projectionCases = 0;
var rejections = 0;

void check(bool condition, String description) {
  checks++;
  if (!condition) {
    throw StateError('DISCOVERY17_FAILED: $description');
  }
}

void reject(void Function() operation, String description) {
  var caught = false;
  try {
    operation();
  } on ArgumentError {
    caught = true;
  }
  check(caught, description);
  rejections++;
}

bool same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Enumerate every distinct multiset word without production DP or counters.
/// Validate first and last appearance ONLY at the completed leaf.
List<List<int>> independentWords(List<int> lengths) {
  final m = lengths.length;
  final n = lengths.fold<int>(0, (sum, x) => sum + x);
  final used = List<int>.filled(m, 0);
  final word = List<int>.filled(n, 0);
  final words = <List<int>>[];
  void visit(int depth) {
    if (depth == n) {
      bruteWords++;
      final first = List<int>.filled(m, n);
      final last = List<int>.filled(m, -1);
      for (var t = 0; t < n; t++) {
        final j = word[t] - 1;
        if (first[j] == n) first[j] = t;
        last[j] = t;
      }
      for (var j = 1; j < m; j++) {
        if (first[j - 1] >= first[j] || last[j - 1] >= last[j]) {
          return;
        }
      }
      validWords++;
      words.add(List<int>.unmodifiable(word));
      return;
    }
    for (var j = 0; j < m; j++) {
      if (used[j] == lengths[j]) continue;
      used[j]++;
      word[depth] = j + 1;
      visit(depth + 1);
      used[j]--;
    }
  }
  visit(0);
  return words;
}

List<MonsterMeatball> fourCutlets(BigInt open, int n) {
  final edges = <int>[0, 3, 6, 9, n];
  final names = <int>[3, 5, 7, 9];
  return <MonsterMeatball>[
    for (var j = 0; j < 4; j++)
      MonsterMeatball(
        number: j + 1,
        intervalCount: 1,
        openGate: open + BigInt.from(edges[j]),
        closeGate: open + BigInt.from(edges[j + 1]),
        nameIndex: names[j],
        name: SourceLanguageCatalog.cutletText(names[j]),
      ),
  ];
}

void projectAllDays(List<int> word, List<int> lengths, int domain) {
  final year = BigInt.from(900 + domain);
  final open = BigInt.from(-123456 - domain * 20);
  final pieces = fourCutlets(open, word.length);
  const names = <int>[47, 4, 20];
  for (var day = 0; day < word.length; day++) {
    final id = word[day];
    var inclusiveCount = 0;
    for (var t = 0; t <= day; t++) {
      if (word[t] == id) inclusiveCount++;
    }
    final cutlet = day < 3 ? 0 : day < 6 ? 1 : day < 9 ? 2 : 3;
    final start = <int>[0, 3, 6, 9][cutlet];
    final date = MonsterFiveFieldCalendar.project(
      yearNumber: year,
      openGate: open,
      closeGate: open + BigInt.from(word.length),
      requestedDay: open + BigInt.from(day + 1),
      cutlets: pieces,
      monthLengths: lengths,
      monthIds: word,
      monthNameIndices: names,
    );
    check(date.yearNumber == year, 'Year number at day $day');
    check(date.cutletCanonicalIndex == pieces[cutlet].nameIndex,
        'Cutlet index at day $day');
    check(date.dayInCutlet == day - start + 1,
        'Absolute cutlet ordinal at day $day');
    check(date.monthCanonicalIndex == names[id - 1],
        'Month canonical index at day $day');
    check(date.dayInMonth == inclusiveCount,
        'Inclusive month prefix at day $day');
    check(date.cutletName ==
        SourceLanguageCatalog.cutletText(pieces[cutlet].nameIndex),
        'Hebrew cutlet at day $day');
    check(date.monthName == SourceLanguageCatalog.monthText(names[id - 1]),
        'Hebrew month at day $day');
    final tuple = date.canonicalComponents;
    check(tuple.length == 5, 'Five components at day $day');
    check(tuple[0] == year &&
        tuple[1] == pieces[cutlet].nameIndex &&
        tuple[2] == day - start + 1 &&
        tuple[3] == names[id - 1] &&
        tuple[4] == inclusiveCount, 'Numeric tuple at day $day');
    projectionCases++;
  }
}

void malformedInputs() {
  final open = BigInt.from(-1000);
  final end = open + BigInt.from(12);
  final cutlets = fourCutlets(open, 12);
  const lengths = <int>[4, 4, 4];
  const names = <int>[47, 4, 20];
  const weave = <int>[1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3];

  void call({
    BigInt? requested,
    BigInt? close,
    List<MonsterMeatball>? pieces,
    List<int>? sizes,
    List<int>? ids,
    List<int>? indices,
  }) {
    MonsterFiveFieldCalendar.project(
      yearNumber: BigInt.from(901),
      openGate: open,
      closeGate: close ?? end,
      requestedDay: requested ?? open + BigInt.one,
      cutlets: pieces ?? cutlets,
      monthLengths: sizes ?? lengths,
      monthIds: ids ?? weave,
      monthNameIndices: indices ?? names,
    );
  }

  List<MonsterMeatball> altered(
    int at, {
    int? number,
    int? index,
    String? title,
    int openShift = 0,
    int closeShift = 0,
  }) => <MonsterMeatball>[
    for (var j = 0; j < cutlets.length; j++)
      if (j != at)
        cutlets[j]
      else
        MonsterMeatball(
          number: number ?? cutlets[j].number,
          intervalCount: cutlets[j].intervalCount,
          openGate: cutlets[j].openGate + BigInt.from(openShift),
          closeGate: cutlets[j].closeGate + BigInt.from(closeShift),
          nameIndex: index ?? cutlets[j].nameIndex,
          name: title ?? cutlets[j].name,
        ),
  ];

  reject(() => call(requested: open), 'Open boundary excluded');
  reject(() => call(requested: end + BigInt.one), 'Close boundary exceeded');
  reject(() => call(close: end + BigInt.one), 'Year span disagreement');
  reject(() => call(close: open), 'Empty year span');
  reject(() => call(ids: <int>[0, ...weave.skip(1)]), 'Month ID zero');
  reject(() => call(ids: <int>[4, ...weave.skip(1)]), 'Month ID four');
  reject(() => call(sizes: <int>[4, 5, 4]), 'Incorrect month total');
  reject(() => call(sizes: <int>[3, 4, 5]), 'Month under four');
  reject(() => call(sizes: <int>[124, 4, 4]), 'Month above 123');
  reject(() => call(sizes: <int>[6, 6]), 'Too few months');
  reject(() => call(indices: <int>[47, 47, 20]), 'Duplicate names');
  reject(() => call(indices: <int>[0, 4, 20]), 'Name zero');
  reject(() => call(indices: <int>[48, 4, 20]), 'Name 48');
  reject(() => call(indices: <int>[47, 4]), 'Missing name');
  reject(() => call(ids: <int>[2, 2, 2, 2, 1, 1, 1, 1, 3, 3, 3, 3]),
      'Wrong first-appearance order');
  reject(() => call(ids: <int>[1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 1, 1]),
      'Wrong last-appearance order');
  reject(() => call(ids: <int>[1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 2]),
      'Wrong multiplicity');
  reject(() => call(pieces: <MonsterMeatball>[]), 'Empty cutlet list');
  reject(() => call(pieces: altered(0, number: 2)), 'Cutlet ordinal');
  reject(() => call(pieces: altered(1, openShift: 1)), 'Cutlet gap');
  reject(() => call(pieces: altered(0, title: 'שם לא תקין')),
      'Cutlet text mismatch');
  reject(() => call(pieces: altered(0, index: 18)), 'Cutlet index 18');
  reject(() => call(pieces: altered(3, closeShift: -1)),
      'Incomplete cutlet partition');
  reject(() => call(pieces: List<MonsterMeatball>.filled(18, cutlets.first)),
      'Over 17 cutlets');
}

void main() {
  final watch = Stopwatch()..start();
  const domains = <List<int>>[
    <int>[4, 4, 4],
    <int>[4, 5, 4],
    <int>[4, 4, 5],
    <int>[5, 4, 4],
  ];
  const expectedCounts = <int>[1301, 3499, 3101, 3101];
  for (var d = 0; d < domains.length; d++) {
    final lengths = domains[d];
    final words = independentWords(lengths);
    check(words.length == expectedCounts[d], 'Exhaustive domain count $d');
    check(MonsterMonthWeaveCounter.countWholeWeaves(lengths) ==
        BigInt.from(words.length), 'Production count vs brute $d');
    final ranks = <int>{1, (words.length + 1) ~/ 2, words.length};
    var seed = 170101 + d * 97;
    while (ranks.length < 67) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      ranks.add(1 + seed % words.length);
    }
    final selected = ranks.toList()..sort();
    check(selected.length == 67, '67 distinct seeded ranks');
    for (final rank in selected) {
      final expected = words[rank - 1];
      final actual = MonsterMonthWeavePlanner.unrankFull(
        lengths, BigInt.from(rank),
      );
      check(same(actual, expected), 'Independent full unrank $d/$rank');
      rankProbes++;
      projectAllDays(expected, lengths, d);
    }
    reject(() => MonsterMonthWeavePlanner.unrankFull(lengths, BigInt.zero),
        'Zero rank $d');
    reject(() => MonsterMonthWeavePlanner.unrankFull(
        lengths, BigInt.from(words.length + 1)), 'Too-large rank $d');
  }
  malformedInputs();
  check(bruteWords == 304920, '304920 independently brute words');
  check(validWords == 11002, '11002 admissible words');
  check(rankProbes == 268, '268 unrank probes');
  check(projectionCases == 3417, '3417 all-day projections');
  check(rejections == 32, '32 malformed and out-of-range rejects');
  check(checks >= 30000, 'At least 30000 assertions');
  watch.stop();
  check(watch.elapsedMilliseconds <= 90000, 'Under 90-second QA budget');
  print('DISCOVERY17_SYNTHETIC_TIME_MS=' +
      watch.elapsedMilliseconds.toString());
  print('DISCOVERY17_COVERAGE_PASS; checks=$checks; '
      'raw_words=$bruteWords; valid_words=$validWords; '
      'rank_probes=$rankProbes; projection_cases=$projectionCases; '
      'rejections=$rejections; canonical_anchors_retained=3; '
      'full_year_calculation_not_repeated=true');
}
