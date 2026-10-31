import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';

/// One signed meatball gate interval; not a complete calendar date.
final class MonsterGateGap {
  final BigInt signedOrdinal;
  final BigInt targetDay;
  final BigInt firstAnswer;
  final int answerDirection;
  final BigInt choice;
  final BigInt length;

  const MonsterGateGap({
    required this.signedOrdinal,
    required this.targetDay,
    required this.firstAnswer,
    required this.answerDirection,
    required this.choice,
    required this.length,
  });
}

/// The §O forward and backward gate paths remain independent.
final class MonsterMeatballGateCalculator {
  static const int maxPrefixSteps = 32;
  static final BigInt choiceModulus = BigInt.from(922);

  final MonsterWorkCounter _counter = const MonsterWorkCounter();
  final MonsterSeedFeeder _feeder = const MonsterSeedFeeder();
  final MonsterVisibleDropGenerator _visible =
      const MonsterVisibleDropGenerator();
  final MonsterBowlProcessor _processor = const MonsterBowlProcessor();
  final MonsterBowlQuestionEngine _questions =
      const MonsterBowlQuestionEngine();
  final List<MonsterSeedStone> _stones;

  MonsterMeatballGateCalculator()
      : _stones = const MonsterSeedFeeder().buildStones();

  /// A positive n uses (F,F+n), a negative n uses (F,F-n).
  MonsterGateGap gapFor(BigInt signedOrdinal) {
    if (signedOrdinal == BigInt.zero) {
      throw ArgumentError.value(
          signedOrdinal, 'signedOrdinal', 'Gate zero has no interval.');
    }
    final foundation = MonsterWorkCounter.foundationDay;
    final targetDay = foundation + signedOrdinal;
    final counts = _counter.calculate(foundation, targetDay);
    final feeds = _feeder.buildHiddenFeeds(counts, _stones);
    final drops = _visible.buildVisibleDrops(
      counts: counts,
      hiddenFeeds: feeds,
      stones: _stones,
    );
    final bowls = _processor.process(
      counts: counts,
      visibleDrops: drops,
      stones: _stones,
    );
    final answer = _questions.createAnswerSequence(
      bowls: bowls,
      bowlId: 1,
      seal: 1,
    );
    final chosen = _questions.chooseEqual(
      sequence: answer,
      modulus: choiceModulus,
    );
    return MonsterGateGap(
      signedOrdinal: signedOrdinal,
      targetDay: targetDay,
      firstAnswer: answer.a0,
      answerDirection: answer.direction,
      choice: chosen.result,
      length: chosen.result + BigInt.from(41),
    );
  }

  /// A bounded prefix only: no year, month, or complete date calculation.
  BigInt gatePosition(BigInt signedOrdinal) {
    if (signedOrdinal.abs() > BigInt.from(maxPrefixSteps)) {
      throw ArgumentError.value(
        signedOrdinal,
        'signedOrdinal',
        'The bounded gate prefix permits at most 32 intervals.',
      );
    }
    var position = MonsterWorkCounter.foundationDay;
    final sign = signedOrdinal.sign;
    final steps = signedOrdinal.abs().toInt();
    for (var step = 1; step <= steps; step++) {
      final gap = gapFor(BigInt.from(sign * step));
      position += BigInt.from(sign) * gap.length;
    }
    return position;
  }
}
