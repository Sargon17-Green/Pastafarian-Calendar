import 'monster_bowl_processor.dart';
import 'monster_modular_math.dart';

/// One sealed-bowl answer stream, anchored to the saved orderAt46.
final class MonsterBowlAnswerSequence {
  final int bowlId;
  final int seal;
  final int nextBowlId;
  final BigInt a0;
  final BigInt directionValue;
  final int direction;
  final MonsterModularMath _math;

  const MonsterBowlAnswerSequence._({
    required this.bowlId,
    required this.seal,
    required this.nextBowlId,
    required this.a0,
    required this.directionValue,
    required this.direction,
    required MonsterModularMath math,
  }) : _math = math;

  BigInt answerAt(BigInt index) {
    if (index < BigInt.zero) {
      throw ArgumentError.value(index, 'index', 'Expected a nonnegative index.');
    }
    return _math.save(a0 + BigInt.from(direction) * index);
  }
}

/// Result of the canonical short or wide equal-choice mechanism.
final class MonsterEqualChoice {
  final String branch;
  final BigInt modulus;
  final int width;
  final BigInt ringSize;
  final BigInt limit;
  final BigInt initial;
  final List<BigInt> digits;
  final BigInt accepted;
  final BigInt rejected;
  final BigInt result;

  MonsterEqualChoice._({
    required this.branch,
    required this.modulus,
    required this.width,
    required this.ringSize,
    required this.limit,
    required this.initial,
    required List<BigInt> digits,
    required this.accepted,
    required this.rejected,
    required this.result,
  }) : digits = List<BigInt>.unmodifiable(digits);
}

final class _RingAcceptance {
  final BigInt accepted;
  final BigInt rejected;

  const _RingAcceptance(this.accepted, this.rejected);
}

/// Implements README §§L–N only; it does not map seals to question moduli.
final class MonsterBowlQuestionEngine {
  static const List<int> canonicalSeals = <int>[
    1,
    10,
    11,
    12,
    20,
    21,
    22,
    30,
    31,
    32,
    33,
  ];
  static const int maxWideDigits = 4096;

  final MonsterModularMath math;

  const MonsterBowlQuestionEngine({
    this.math = const MonsterModularMath(),
  });

  MonsterBowlAnswerSequence createAnswerSequence({
    required MonsterBowlResult bowls,
    required int bowlId,
    required int seal,
  }) {
    if (bowlId < 1 || bowlId > 6) {
      throw ArgumentError.value(bowlId, 'bowlId', 'Expected a fixed bowl ID 1..6.');
    }
    if (!canonicalSeals.contains(seal)) {
      throw ArgumentError.value(seal, 'seal', 'Unknown canonical seal.');
    }
    if (bowls.finalBowls.length != 6 ||
        bowls.orderAt46.length != 6 ||
        bowls.dropStages.length != 46 ||
        bowls.orderAt46.toSet().length != 6 ||
        !bowls.orderAt46.contains(bowlId) ||
        !_sameOrder(bowls.orderAt46, bowls.dropStages.last.order)) {
      throw ArgumentError('A complete bowl result with saved orderAt46 is required.');
    }

    final modulus = MonsterModularMath.modulus;
    for (final value in bowls.finalBowls) {
      if (value < BigInt.one || value > modulus) {
        throw ArgumentError('Final bowl values must be in [1,M].');
      }
    }

    final position = bowls.orderAt46.indexOf(bowlId);
    final nextBowlId = bowls.orderAt46[(position + 1) % 6];
    final current = bowls.finalBowls[bowlId - 1];
    final next = bowls.finalBowls[nextBowlId - 1];
    final fixedSixth = bowls.finalBowls[5];
    final z = BigInt.from(seal);
    final a0 = math.save(
      math.square(current + z + BigInt.from(181)) +
          BigInt.from(179) * next +
          z,
    );
    final directionValue = math.save(
      math.square(a0 + z + BigInt.from(194)) +
          BigInt.from(193) * a0 +
          BigInt.from(197) * fixedSixth,
    );
    final direction = directionValue.isOdd ? 1 : -1;

    return MonsterBowlAnswerSequence._(
      bowlId: bowlId,
      seal: seal,
      nextBowlId: nextBowlId,
      a0: a0,
      directionValue: directionValue,
      direction: direction,
      math: math,
    );
  }

  bool _sameOrder(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  _RingAcceptance _acceptOnRing({
    required BigInt candidate,
    required BigInt limit,
    required BigInt ringSize,
    required int direction,
  }) {
    if (candidate < BigInt.one || candidate > ringSize) {
      throw ArgumentError.value(candidate, 'candidate', 'Outside answer ring.');
    }
    if (limit < BigInt.one || limit > ringSize) {
      throw ArgumentError.value(limit, 'limit', 'Outside answer ring.');
    }
    if (direction != 1 && direction != -1) {
      throw ArgumentError.value(direction, 'direction', 'Expected +1 or -1.');
    }
    if (candidate <= limit) {
      return _RingAcceptance(candidate, BigInt.zero);
    }
    if (direction == 1) {
      return _RingAcceptance(
        BigInt.one,
        ringSize - candidate + BigInt.one,
      );
    }
    return _RingAcceptance(limit, candidate - limit);
  }

  MonsterEqualChoice chooseEqual({
    required MonsterBowlAnswerSequence sequence,
    required BigInt modulus,
  }) {
    return chooseEqualFromStart(
      firstAnswer: sequence.a0,
      direction: sequence.direction,
      modulus: modulus,
    );
  }

  /// Generic §N entry point, also used to test exact wrap/rejection boundaries.
  MonsterEqualChoice chooseEqualFromStart({
    required BigInt firstAnswer,
    required int direction,
    required BigInt modulus,
  }) {
    final m = MonsterModularMath.modulus;
    if (modulus <= BigInt.zero) {
      throw ArgumentError.value(modulus, 'modulus', 'N must be positive.');
    }
    if (firstAnswer < BigInt.one || firstAnswer > m) {
      throw ArgumentError.value(firstAnswer, 'firstAnswer', 'Expected A0 in [1,M].');
    }
    if (direction != 1 && direction != -1) {
      throw ArgumentError.value(direction, 'direction', 'Expected +1 or -1.');
    }

    if (modulus <= m) {
      final limit = (m ~/ modulus) * modulus;
      final accepted = _acceptOnRing(
        candidate: firstAnswer,
        limit: limit,
        ringSize: m,
        direction: direction,
      );
      return MonsterEqualChoice._(
        branch: 'short',
        modulus: modulus,
        width: 1,
        ringSize: m,
        limit: limit,
        initial: firstAnswer,
        digits: const <BigInt>[],
        accepted: accepted.accepted,
        rejected: accepted.rejected,
        result: BigInt.one + ((accepted.accepted - BigInt.one) % modulus),
      );
    }

    var ringSize = m;
    var width = 1;
    while (ringSize < modulus) {
      ringSize *= m;
      width++;
      if (width > maxWideDigits) {
        throw ArgumentError.value(
          modulus,
          'modulus',
          'Wide choice exceeds the 4096-digit computation policy.',
        );
      }
    }

    var initial = BigInt.one;
    var place = BigInt.one;
    final digits = <BigInt>[];
    for (var index = 0; index < width; index++) {
      final digit = math.save(
        firstAnswer + BigInt.from(direction) * BigInt.from(index),
      );
      digits.add(digit);
      initial += (digit - BigInt.one) * place;
      place *= m;
    }

    final limit = (ringSize ~/ modulus) * modulus;
    final accepted = _acceptOnRing(
      candidate: initial,
      limit: limit,
      ringSize: ringSize,
      direction: direction,
    );
    return MonsterEqualChoice._(
      branch: 'wide',
      modulus: modulus,
      width: width,
      ringSize: ringSize,
      limit: limit,
      initial: initial,
      digits: digits,
      accepted: accepted.accepted,
      rejected: accepted.rejected,
      result: BigInt.one + ((accepted.accepted - BigInt.one) % modulus),
    );
  }
}
