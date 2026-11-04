import '../lib/src/monster_meatball_partition.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';
import '../lib/src/source_language_catalog.dart';

var checks = 0;
var bruteCases = 0;
var nameProbes = 0;
var anchors = 0;

void check(bool condition, String detail) {
  checks++;
  if (!condition) {
    throw StateError('PRODUCTION11_MEATBALL_FAILED: $detail');
  }
}

/// Independent small-domain oracle: enumerate ordered positive vectors.
List<List<int>> bruteCompositions(int g, int k, int? forced) {
  final solutions = <List<int>>[];
  void visit(int used, List<int> parts, bool hasCut) {
    if (parts.length == k - 1) {
      final finalSize = g - used;
      if (finalSize > 0 && (forced == null || hasCut)) {
        solutions.add(<int>[...parts, finalSize]);
      }
      return;
    }
    for (var size = 1; size <= g - used - (k - parts.length - 1); size++) {
      final cut = used + size;
      visit(cut, <int>[...parts, size], hasCut || cut == forced);
    }
  }

  visit(0, <int>[], false);
  return solutions;
}

/// Independent small-domain name enumeration, never sorting display strings.
List<List<int>> bruteNames(int k) {
  final solutions = <List<int>>[];
  void visit(List<int> prefix, List<int> available) {
    if (prefix.length == k) {
      solutions.add(prefix);
      return;
    }
    for (final candidate in available) {
      visit(
        <int>[...prefix, candidate],
        <int>[
          for (final a in available)
            if (a != candidate) a
        ],
      );
    }
  }

  visit(<int>[], <int>[for (var i = 1; i <= 17; i++) i]);
  return solutions;
}

void compositionOracle() {
  for (var g = 6; g <= 11; g++) {
    for (var k = 6; k <= g && k <= 8; k++) {
      for (final required in <int?>[null, g ~/ 2]) {
        final brute = bruteCompositions(g, k, required);
        final count = MonsterMeatballPartitioner.countCompositions(
          g,
          k,
          mandatoryCut: required,
        );
        check(count == BigInt.from(brute.length), 'Brute count g=$g k=$k');
        check(brute.isNotEmpty, 'Expected at least one composition');
        final ranks = <int>{1, (brute.length + 1) ~/ 2, brute.length};
        for (final rank in ranks) {
          final actual = MonsterMeatballPartitioner.unrankComposition(
            g,
            k,
            BigInt.from(rank),
            mandatoryCut: required,
          );
          check(
            actual.join(',') == brute[rank - 1].join(','),
            'Brute lexicographic composition rank=$rank',
          );
        }
        bruteCases++;
      }
    }
  }
  check(
    MonsterMeatballPartitioner.countCompositions(137, 17) >
        BigInt.from(1000000),
    'Wide combinatorial domain counted exactly',
  );
  check(
    MonsterMeatballPartitioner.countCompositions(
          17,
          17,
          mandatoryCut: 8,
        ) ==
        BigInt.one,
    'All-ones composition with a required internal cut',
  );
  var refused = false;
  try {
    MonsterMeatballPartitioner.unrankComposition(
      8,
      6,
      BigInt.zero,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Zero composition rank rejected');
  refused = false;
  try {
    MonsterMeatballPartitioner.countCompositions(
      8,
      6,
      mandatoryCut: 8,
    );
  } on RangeError {
    refused = true;
  }
  check(refused, 'Invalid mandatory cut rejected');
}

void namesOracle() {
  for (var k = 1; k <= 3; k++) {
    final oracle = bruteNames(k);
    final count = MonsterMeatballPartitioner.countNameSequences(k);
    check(count == BigInt.from(oracle.length), 'Independent name count');
    for (final rank in <int>{1, (oracle.length + 1) ~/ 2, oracle.length}) {
      final chosen = MonsterMeatballPartitioner.unrankNames(
        k,
        BigInt.from(rank),
      );
      check(
        chosen.join(',') == oracle[rank - 1].join(','),
        'Independent canonical name permutation',
      );
      nameProbes++;
    }
  }
  check(
    MonsterMeatballPartitioner.countNameSequences(17) ==
        BigInt.parse('355687428096000'),
    '17! exact without floating point',
  );
}

void canonicalCase(BigInt c) {
  final anchor = MonsterYear5000Selector().select(c);
  final year = MonsterTraversedYear.from5000(anchor);
  final p = MonsterMeatballPartitioner().partition(c, year);
  check(p.firstDayOfYear == year.candidate.openGate + BigInt.one,
      '§S common sauce second component');
  check(p.meatballCount >= 6 && p.meatballCount <= 17,
      'Count within canonical 6..17');
  check(p.meatballCount <= p.intervalCount, 'Count <= gate intervals');
  check(p.meatballs.length == p.meatballCount, 'Full partition list');
  check(p.countChoice.result == BigInt.from(p.meatballCount - 5),
      'Seal20 1-based count mapping');
  check(
    p.compositionCount ==
        MonsterMeatballPartitioner.countCompositions(
          p.intervalCount,
          p.meatballCount,
          mandatoryCut: p.mandatoryCut,
        ),
    'Full domain count',
  );
  check(
      p.compositionChoice.result >= BigInt.one &&
          p.compositionChoice.result <= p.compositionCount,
      'Seal21 rank in complete domain');
  check(
      p.nameSequenceCount ==
          MonsterMeatballPartitioner.countNameSequences(p.meatballCount),
      'Seal22 domain count');
  final chosenNames = MonsterMeatballPartitioner.unrankNames(
    p.meatballCount,
    p.namesChoice.result,
  );
  var accumulated = 0;
  final unique = <int>{};
  for (var i = 0; i < p.meatballs.length; i++) {
    final b = p.meatballs[i];
    check(b.number == i + 1, 'Meatball number');
    check(b.intervalCount > 0, 'Positive interval block');
    check(b.openGate < b.closeGate, 'Nonempty meatball');
    check(b.nameIndex == chosenNames[i], 'Rank-derived name index');
    check(b.name == SourceLanguageCatalog.cutletText(b.nameIndex),
        'Canonical Hebrew display name');
    check(unique.add(b.nameIndex), 'No reused canonical name');
    if (i > 0) {
      check(p.meatballs[i - 1].closeGate == b.openGate,
          'Adjacent meatball gates');
    }
    accumulated += b.intervalCount;
    if (p.mandatoryCut != null && accumulated == p.mandatoryCut) {
      check(b.closeGate == c, 'Required internal gate retained');
    }
  }
  check(accumulated == p.intervalCount, 'All §O intervals covered');
  check(p.meatballs.first.openGate == year.candidate.openGate,
      'Year opening gate');
  check(p.meatballs.last.closeGate == year.candidate.closeGate,
      'Year closing gate');
  check(unique.length == p.meatballCount, 'Distinct canonical names');
  anchors++;
}

void main() {
  compositionOracle();
  namesOracle();
  final f = MonsterWorkCounter.foundationDay;
  for (final c in <BigInt>[f - BigInt.one, f, f + BigInt.one]) {
    canonicalCase(c);
  }
  check(bruteCases == 30, 'Thirty independent composition domains');
  check(nameProbes == 9, 'Nine independent name permutation probes');
  check(anchors == 3, 'Three canonical calculation-day anchors');
  check(checks >= 175, 'Adequate independently counted checks');
  print('PRODUCTION11_MEATBALL_PASS; checks=$checks; '
      'composition_domains=$bruteCases; name_probes=$nameProbes; '
      'canonical_anchors=$anchors; meatball_component_ready=true; '
      'five_component_calendar_ready=false');
}
