import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_meatball_gates.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';
import 'monster_year_traversal.dart';
import 'source_language_catalog.dart';

/// One canonical §S meatball with its §T canonical name index.
final class MonsterMeatball {
  final int number;
  final int intervalCount;
  final BigInt openGate;
  final BigInt closeGate;
  final int nameIndex;
  final String name;

  const MonsterMeatball({
    required this.number,
    required this.intervalCount,
    required this.openGate,
    required this.closeGate,
    required this.nameIndex,
    required this.name,
  });

  bool contains(BigInt day) => openGate < day && day <= closeGate;
}

/// Proven §S–T component only; no month or five-field calendar date.
final class MonsterMeatballPartition {
  final BigInt firstDayOfYear;
  final int intervalCount;
  final int meatballCount;
  final int? mandatoryCut;
  final BigInt compositionCount;
  final BigInt nameSequenceCount;
  final MonsterEqualChoice countChoice;
  final MonsterEqualChoice compositionChoice;
  final MonsterEqualChoice namesChoice;
  final List<MonsterMeatball> meatballs;

  MonsterMeatballPartition._({
    required this.firstDayOfYear,
    required this.intervalCount,
    required this.meatballCount,
    required this.mandatoryCut,
    required this.compositionCount,
    required this.nameSequenceCount,
    required this.countChoice,
    required this.compositionChoice,
    required this.namesChoice,
    required List<MonsterMeatball> meatballs,
  }) : meatballs = List<MonsterMeatball>.unmodifiable(meatballs);
}

/// Exact combinatorial unranking; independent test oracles enumerate tiny cases.
final class MonsterMeatballPartitioner {
  final MonsterMeatballGateCalculator gates;
  final MonsterBowlQuestionEngine questions;

  MonsterMeatballPartitioner({
    MonsterMeatballGateCalculator? gates,
    this.questions = const MonsterBowlQuestionEngine(),
  }) : gates = gates ?? MonsterMeatballGateCalculator();

  static BigInt _choose(int n, int k) {
    if (n < 0 || k < 0 || k > n) {
      return BigInt.zero;
    }
    final count = k < n - k ? k : n - k;
    var result = BigInt.one;
    for (var i = 1; i <= count; i++) {
      result = (result * BigInt.from(n - count + i)) ~/ BigInt.from(i);
    }
    return result;
  }

  static void _validateComposition(int g, int k, int? mandatoryCut) {
    if (g < 1 || g > 137) {
      throw RangeError.range(g, 1, 137, 'g');
    }
    if (k < 1 || k > g) {
      throw RangeError.range(k, 1, g, 'k');
    }
    if (mandatoryCut != null && (mandatoryCut <= 0 || mandatoryCut >= g)) {
      throw RangeError.range(mandatoryCut, 1, g - 1, 'mandatoryCut');
    }
  }

  /// Lexicographic positive compositions, optionally containing a required cut.
  static BigInt countCompositions(int g, int k, {int? mandatoryCut}) {
    _validateComposition(g, k, mandatoryCut);
    return mandatoryCut == null ? _choose(g - 1, k - 1) : _choose(g - 2, k - 2);
  }

  /// 1-based exact rank, with no list of exponential size materialized.
  static List<int> unrankComposition(
    int g,
    int k,
    BigInt rank, {
    int? mandatoryCut,
  }) {
    final total = countCompositions(g, k, mandatoryCut: mandatoryCut);
    if (rank < BigInt.one || rank > total) {
      throw ArgumentError.value(rank, 'rank', 'Outside composition domain.');
    }
    final result = <int>[];
    var used = 0;
    var fulfilled = false;
    var index = rank;
    for (var position = 0; position < k - 1; position++) {
      final partsLeft = k - position - 1;
      var selected = false;
      for (var size = 1; size <= g - used - partsLeft; size++) {
        final end = used + size;
        final hasCut = fulfilled || end == mandatoryCut;
        final possible = mandatoryCut == null || hasCut
            ? _choose(g - end - 1, partsLeft - 1)
            : end > mandatoryCut
                ? BigInt.zero
                : _choose(g - end - 2, partsLeft - 2);
        if (index > possible) {
          index -= possible;
          continue;
        }
        result.add(size);
        used = end;
        fulfilled = hasCut;
        selected = true;
        break;
      }
      if (!selected) {
        throw StateError('§S composition rank traversal exhausted.');
      }
    }
    result.add(g - used);
    if (mandatoryCut != null && !fulfilled) {
      throw StateError('§S required internal gate was omitted.');
    }
    return List<int>.unmodifiable(result);
  }

  static BigInt countNameSequences(int k) {
    if (k < 0 || k > 17) {
      throw RangeError.range(k, 0, 17, 'k');
    }
    var value = BigInt.one;
    for (var i = 0; i < k; i++) {
      value *= BigInt.from(17 - i);
    }
    return value;
  }

  /// Distinct canonical indices are ordered numerically, never by Hebrew text.
  static List<int> unrankNames(int k, BigInt rank) {
    final total = countNameSequences(k);
    if (rank < BigInt.one || rank > total) {
      throw ArgumentError.value(rank, 'rank', 'Outside name sequence domain.');
    }
    final available = <int>[for (var i = 1; i <= 17; i++) i];
    final result = <int>[];
    var zeroBased = rank - BigInt.one;
    for (var position = 0; position < k; position++) {
      var block = BigInt.one;
      for (var i = 0; i < k - position - 1; i++) {
        block *= BigInt.from(available.length - 1 - i);
      }
      final selectedIndex = (zeroBased ~/ block).toInt();
      zeroBased %= block;
      result.add(available.removeAt(selectedIndex));
    }
    return List<int>.unmodifiable(result);
  }

  MonsterMeatballPartition partition(
    BigInt calculationDay,
    MonsterTraversedYear year,
  ) {
    final candidate = year.candidate;
    final g = candidate.intervalCount.toInt();
    if (g < 6 || g > 137) {
      throw StateError('§S requires six to 137 proved year intervals.');
    }
    final boundaries = <BigInt>[candidate.openGate];
    var edge = candidate.openGate;
    int? mandatoryCut;
    for (var j = 1; j <= g; j++) {
      final right = candidate.openOrdinal + BigInt.from(j);
      final signed = MonsterYearTraversal.signedGapOrdinal(right);
      edge += gates.gapFor(signed).length;
      boundaries.add(edge);
      if (j < g && edge == calculationDay) {
        mandatoryCut = j;
      }
    }
    if (edge != candidate.closeGate) {
      throw StateError('§S year gate reconstruction disagrees with §R.');
    }
    final firstDay = candidate.openGate + BigInt.one;
    final work = const MonsterWorkCounter().calculate(
      calculationDay,
      firstDay,
    );
    final feeder = const MonsterSeedFeeder();
    final stones = feeder.buildStones();
    final feeds = feeder.buildHiddenFeeds(work, stones);
    final drops = const MonsterVisibleDropGenerator().buildVisibleDrops(
      counts: work,
      hiddenFeeds: feeds,
      stones: stones,
    );
    final bowls = const MonsterBowlProcessor().process(
      counts: work,
      visibleDrops: drops,
      stones: stones,
    );
    final maximumK = g < 17 ? g : 17;
    final countChoice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 2,
        seal: 20,
      ),
      modulus: BigInt.from(maximumK - 5),
    );
    final k = 5 + countChoice.result.toInt();
    final compositionCount = countCompositions(
      g,
      k,
      mandatoryCut: mandatoryCut,
    );
    if (compositionCount <= BigInt.zero) {
      throw StateError('§S has no eligible compositions.');
    }
    final compositionChoice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 2,
        seal: 21,
      ),
      modulus: compositionCount,
    );
    final parts = unrankComposition(
      g,
      k,
      compositionChoice.result,
      mandatoryCut: mandatoryCut,
    );
    final nameSequenceCount = countNameSequences(k);
    final namesChoice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 5,
        seal: 22,
      ),
      modulus: nameSequenceCount,
    );
    final names = unrankNames(k, namesChoice.result);
    final meatballs = <MonsterMeatball>[];
    var cursor = 0;
    for (var i = 0; i < k; i++) {
      final next = cursor + parts[i];
      meatballs.add(MonsterMeatball(
        number: i + 1,
        intervalCount: parts[i],
        openGate: boundaries[cursor],
        closeGate: boundaries[next],
        nameIndex: names[i],
        name: SourceLanguageCatalog.cutletText(names[i]),
      ));
      cursor = next;
    }
    if (cursor != g || meatballs.last.closeGate != candidate.closeGate) {
      throw StateError('§S composition did not partition the full year.');
    }
    return MonsterMeatballPartition._(
      firstDayOfYear: firstDay,
      intervalCount: g,
      meatballCount: k,
      mandatoryCut: mandatoryCut,
      compositionCount: compositionCount,
      nameSequenceCount: nameSequenceCount,
      countChoice: countChoice,
      compositionChoice: compositionChoice,
      namesChoice: namesChoice,
      meatballs: meatballs,
    );
  }
}
