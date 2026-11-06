import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_names.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';
import '../lib/src/source_language_catalog.dart';

var checks = 0;
var independentRanks = 0;
var bruteDomains = 0;
var canonicalAnchors = 0;

void check(bool condition, String detail) {
  checks++;
  if (!condition) {
    throw StateError('PRODUCTION15_NAMES_FAILED: $detail');
  }
}

bool equalInts(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Independent oracle: visit all index permutations and retain leaf words.
/// It never uses a factorial, rank blocks, or the production selector.
List<List<int>> enumerateNameWords(int pool, int take) {
  final result = <List<int>>[];
  final word = <int>[];
  final used = List<bool>.filled(pool + 1, false);

  void visit() {
    if (word.length == take) {
      result.add(List<int>.of(word));
      return;
    }
    for (var candidate = 1; candidate <= pool; candidate++) {
      if (used[candidate]) {
        continue;
      }
      used[candidate] = true;
      word.add(candidate);
      visit();
      word.removeLast();
      used[candidate] = false;
    }
  }

  visit();
  return result;
}

void exhaustiveOracle() {
  for (var population = 2; population <= 6; population++) {
    for (var take = 1; take <= population && take <= 4; take++) {
      final words = enumerateNameWords(population, take);
      final total = MonsterMonthNamePlanner.countDistinctNames(
        population,
        take,
      );
      check(total == BigInt.from(words.length), 'Brute count');
      for (var rank = 1; rank <= words.length; rank++) {
        final actual = MonsterMonthNamePlanner.unrankDistinctNames(
          population,
          take,
          BigInt.from(rank),
        );
        check(
          equalInts(actual, words[rank - 1]),
          'Independent lexicographic rank $rank',
        );
        independentRanks++;
      }
      bruteDomains++;
    }
  }
  check(bruteDomains == 17, '17 independent brute domains');
  check(independentRanks == 804, '804 independently enumerated ranks');
}

void boundaryAndCatalogOracle() {
  final full = MonsterMonthNamePlanner.countNameSequences(47);
  check(full > (BigInt.one << 127), '47! exceeds 127 bits');
  final first = MonsterMonthNamePlanner.unrankNameIndices(47, BigInt.one);
  final last = MonsterMonthNamePlanner.unrankNameIndices(47, full);
  check(first.length == 47 && last.length == 47, 'Full domain length');
  for (var i = 0; i < 47; i++) {
    check(first[i] == i + 1, 'Lexicographic first full permutation');
    check(last[i] == 47 - i, 'Lexicographic last full permutation');
    check(
      SourceLanguageCatalog.monthNames[i].canonicalIndex == i + 1,
      'Canonical source index lock',
    );
    check(
      SourceLanguageCatalog.monthText(i + 1).isNotEmpty,
      'Canonical Hebrew text exists',
    );
  }
  final lastThree = MonsterMonthNamePlanner.unrankNameIndices(
    3,
    MonsterMonthNamePlanner.countNameSequences(3),
  );
  check(equalInts(lastThree, <int>[47, 46, 45]), 'Last three-name tuple');
  var refused = false;
  try {
    MonsterMonthNamePlanner.unrankNameIndices(3, BigInt.zero);
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Zero name rank rejected');
  refused = false;
  try {
    MonsterMonthNamePlanner.unrankNameIndices(
      3,
      MonsterMonthNamePlanner.countNameSequences(3) + BigInt.one,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Out-of-domain name rank rejected');
  refused = false;
  try {
    MonsterMonthNamePlanner.countNameSequences(0);
  } on RangeError {
    refused = true;
  }
  check(refused, 'Zero month count rejected');
  refused = false;
  try {
    MonsterMonthNamePlanner.countNameSequences(48);
  } on RangeError {
    refused = true;
  }
  check(refused, 'Month count above 47 rejected');
  refused = false;
  try {
    first.add(0);
  } on UnsupportedError {
    refused = true;
  }
  check(refused, 'Result list is immutable');
}

void canonicalOracle() {
  final day = MonsterWorkCounter.foundationDay;
  final year = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(day),
  );
  final lengths = const MonsterMonthLengthPlanner().plan(day, year);
  final weave = const MonsterMonthWeavePlanner().plan(day, year, lengths);
  final watch = Stopwatch()..start();
  final names = const MonsterMonthNamePlanner().plan(
    day,
    year,
    lengths,
    weave,
  );
  watch.stop();
  check(watch.elapsed.inSeconds <= 120, 'Canonical §W budget 120s');
  check(names.monthCount == lengths.monthCount, 'One name per month ID');
  check(names.nameIndices.length == lengths.monthCount, 'Index count');
  check(names.names.length == lengths.monthCount, 'Hebrew name count');
  check(
    names.nameSequenceCount ==
        MonsterMonthNamePlanner.countNameSequences(lengths.monthCount),
    'Seal33 exact complete domain',
  );
  check(names.nameChoice.modulus == names.nameSequenceCount, 'Seal33 modulus');
  check(
    names.nameChoice.result >= BigInt.one &&
        names.nameChoice.result <= names.nameSequenceCount,
    'Seal33 exact one-based rank',
  );
  final direct = MonsterMonthNamePlanner.unrankNameIndices(
    lengths.monthCount,
    names.nameChoice.result,
  );
  check(equalInts(direct, names.nameIndices), 'Canonical name rank');
  check(
    names.nameIndices.toSet().length == lengths.monthCount,
    'Distinct canonical indices',
  );
  for (var i = 0; i < lengths.monthCount; i++) {
    check(
      names.names[i] == SourceLanguageCatalog.monthText(names.nameIndices[i]),
      'Hebrew month text uses index order',
    );
  }
  canonicalAnchors++;
}

void main() {
  exhaustiveOracle();
  boundaryAndCatalogOracle();
  canonicalOracle();
  check(checks >= 1000, 'At least 1000 checked predicates');
  check(bruteDomains == 17, 'Exhaustive small domains');
  check(independentRanks == 804, 'Exhaustive independent ranks');
  check(canonicalAnchors == 1, 'One canonical §W anchor');
  print('PRODUCTION15_NAMES_PASS; checks=$checks; '
      'brute_domains=$bruteDomains; independent_ranks=$independentRanks; '
      'canonical_anchors=$canonicalAnchors; names_ready=true; '
      'five_component_calendar_ready=false');
}
