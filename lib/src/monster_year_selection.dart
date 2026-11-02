import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';
import 'monster_year_eligibility.dart';
import 'monster_year_locator.dart';

/// Constructed only after §Q enumeration has proved both outer sentinels.
final class MonsterYear5000Selection {
  final BigInt calculationDay;
  final BigInt yearNumber;
  final BigInt choiceIndex;
  final BigInt candidateCount;
  final BigInt sauceFirst;
  final BigInt sauceSecond;
  final int bowlId;
  final int seal;
  final MonsterYearCandidate selectedYear;
  final MonsterEqualChoice choice;

  const MonsterYear5000Selection._({
    required this.calculationDay,
    required this.yearNumber,
    required this.choiceIndex,
    required this.candidateCount,
    required this.sauceFirst,
    required this.sauceSecond,
    required this.bowlId,
    required this.seal,
    required this.selectedYear,
    required this.choice,
  });
}

/// Exact §Q candidate enumeration, followed by the canonical §§M,N question.
final class MonsterYear5000Selector {
  final MonsterYearLocator locator;
  final MonsterBowlQuestionEngine questions;

  MonsterYear5000Selector({
    MonsterYearLocator? locator,
    this.questions = const MonsterBowlQuestionEngine(),
  }) : locator = locator ?? MonsterYearLocator();

  MonsterYear5000Selection select(BigInt calculationDay) {
    final preview = locator.sentinelSearch(calculationDay);
    preview.requireComplete();
    if (preview.candidates.isEmpty) {
      throw StateError('No eligible §Q year contains the calculation day.');
    }
    // Year sauce: exactly (c,c), not (Foundation,c).
    final counts = const MonsterWorkCounter().calculate(
      calculationDay,
      calculationDay,
    );
    final feeder = const MonsterSeedFeeder();
    final stones = feeder.buildStones();
    final feeds = feeder.buildHiddenFeeds(counts, stones);
    final droplets = const MonsterVisibleDropGenerator().buildVisibleDrops(
      counts: counts,
      hiddenFeeds: feeds,
      stones: stones,
    );
    final bowls = const MonsterBowlProcessor().process(
      counts: counts,
      visibleDrops: droplets,
      stones: stones,
    );
    final sequence = questions.createAnswerSequence(
      bowls: bowls,
      bowlId: 1,
      seal: 10,
    );
    final candidateCount = BigInt.from(preview.candidates.length);
    final choice = questions.chooseEqual(
      sequence: sequence,
      modulus: candidateCount,
    );
    if (choice.result < BigInt.one || choice.result > candidateCount) {
      throw StateError('§N returned an index outside the complete §Q list.');
    }
    return MonsterYear5000Selection._(
      calculationDay: calculationDay,
      yearNumber: BigInt.from(5000),
      choiceIndex: choice.result,
      candidateCount: candidateCount,
      sauceFirst: calculationDay,
      sauceSecond: calculationDay,
      bowlId: 1,
      seal: 10,
      selectedYear: preview.candidates[(choice.result - BigInt.one).toInt()],
      choice: choice,
    );
  }
}
