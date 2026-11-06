import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_month_lengths.dart';
import 'monster_month_weave_planner.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';
import 'monster_year_traversal.dart';
import 'source_language_catalog.dart';

/// §W names in chronological month-ID order. This is not a §X calendar date.
final class MonsterMonthNamePlan {
  final int monthCount;
  final BigInt nameSequenceCount;
  final MonsterEqualChoice nameChoice;
  final List<int> nameIndices;
  final List<String> names;

  MonsterMonthNamePlan._({
    required this.monthCount,
    required this.nameSequenceCount,
    required this.nameChoice,
    required List<int> nameIndices,
    required List<String> names,
  })  : nameIndices = List<int>.unmodifiable(nameIndices),
        names = List<String>.unmodifiable(names);
}

/// Exact one-based lexicographic selection of distinct canonical name indices.
///
/// Uses only falling factorials and an ordered set of surviving indices.
/// The Hebrew text is looked up after selection and is never sorted.
final class MonsterMonthNamePlanner {
  final MonsterBowlQuestionEngine questions;

  const MonsterMonthNamePlanner({
    this.questions = const MonsterBowlQuestionEngine(),
  });

  static void _validate(int population, int take) {
    if (population < 1 || population > 47) {
      throw RangeError.range(population, 1, 47, 'population');
    }
    if (take < 1 || take > population) {
      throw RangeError.range(take, 1, population, 'take');
    }
  }

  static BigInt countDistinctNames(int population, int take) {
    _validate(population, take);
    var total = BigInt.one;
    for (var i = 0; i < take; i++) {
      total *= BigInt.from(population - i);
    }
    return total;
  }

  static BigInt countNameSequences(int monthCount) {
    return countDistinctNames(47, monthCount);
  }

  /// General bounded form allows an exhaustive independent oracle for tiny pools.
  static List<int> unrankDistinctNames(
    int population,
    int take,
    BigInt rank,
  ) {
    final total = countDistinctNames(population, take);
    if (rank < BigInt.one || rank > total) {
      throw ArgumentError.value(rank, 'rank', 'Outside name domain.');
    }
    final remaining = <int>[for (var i = 1; i <= population; i++) i];
    final selected = <int>[];
    var ordinal = rank - BigInt.one;
    var suffixCount = total;
    for (var position = 0; position < take; position++) {
      final block = suffixCount ~/ BigInt.from(remaining.length);
      final offset = (ordinal ~/ block).toInt();
      if (offset < 0 || offset >= remaining.length) {
        throw StateError('§W lexicographic rank exceeded the name domain.');
      }
      selected.add(remaining.removeAt(offset));
      ordinal %= block;
      suffixCount = block;
    }
    if (ordinal != BigInt.zero) {
      throw StateError('§W name rank did not exhaust its domain.');
    }
    return List<int>.unmodifiable(selected);
  }

  static List<int> unrankNameIndices(int monthCount, BigInt rank) {
    return unrankDistinctNames(47, monthCount, rank);
  }

  /// Select one §W name for each accepted §U month ID, using bowl 5/seal 33.
  /// All questions use the same sauce (c, firstDayOfYear), not (c,c).
  MonsterMonthNamePlan plan(
    BigInt calculationDay,
    MonsterTraversedYear year,
    MonsterMonthLengthPlan lengths,
    MonsterMonthWeavePlan weave,
  ) {
    final span = year.candidate.closeGate - year.candidate.openGate;
    if (span != BigInt.from(lengths.yearLength) ||
        lengths.monthCount != lengths.lengths.length ||
        lengths.monthCount < 3 ||
        lengths.monthCount > 47 ||
        weave.monthIds.length != lengths.yearLength) {
      throw ArgumentError('§W requires an accepted matching §U/§V year.');
    }
    final outstanding = List<int>.of(lengths.lengths);
    for (final monthId in weave.monthIds) {
      if (monthId < 1 || monthId > lengths.monthCount) {
        throw ArgumentError('§W weave includes an invalid month ID.');
      }
      outstanding[monthId - 1]--;
      if (outstanding[monthId - 1] < 0) {
        throw ArgumentError('§W weave has excess month occurrences.');
      }
    }
    if (outstanding.any((count) => count != 0)) {
      throw ArgumentError('§W weave does not match the month lengths.');
    }
    if (SourceLanguageCatalog.monthNames.length != 47) {
      throw StateError('§W requires all 47 locked canonical names.');
    }
    final firstDay = year.candidate.openGate + BigInt.one;
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
    final count = countNameSequences(lengths.monthCount);
    final choice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 5,
        seal: 33,
      ),
      modulus: count,
    );
    final indices = unrankNameIndices(lengths.monthCount, choice.result);
    final names = <String>[
      for (final index in indices) SourceLanguageCatalog.monthText(index),
    ];
    return MonsterMonthNamePlan._(
      monthCount: lengths.monthCount,
      nameSequenceCount: count,
      nameChoice: choice,
      nameIndices: indices,
      names: names,
    );
  }
}
