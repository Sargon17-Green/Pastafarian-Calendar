import 'dart:io';

import '../lib/src/monster_bowl_processor.dart';
import '../lib/src/monster_meatball_gates.dart';
import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;
final _modulus = (BigInt.one << 127) - BigInt.one;
final _foundation = MonsterWorkCounter.foundationDay;
final _choiceRange = BigInt.from(922);

void _check(bool condition, String label) {
  _checks++;
  if (!condition) {
    throw StateError('PRODUCTION07_CHECK_FAILED: $label');
  }
}

void _rejectArgument(void Function() action, String label) {
  var rejected = false;
  try {
    action();
  } on ArgumentError {
    rejected = true;
  }
  _check(rejected, label);
}

BigInt _normalize(BigInt value) {
  return ((value - BigInt.one) % _modulus) + BigInt.one;
}

final class _ReferenceGap {
  final BigInt targetDay;
  final BigInt firstAnswer;
  final int answerDirection;
  final BigInt choice;
  final BigInt length;

  const _ReferenceGap({
    required this.targetDay,
    required this.firstAnswer,
    required this.answerDirection,
    required this.choice,
    required this.length,
  });
}

/// Independent scalar oracle for §O; upstream §§E–K are already verified.
_ReferenceGap _referenceGap(
  BigInt signedOrdinal,
  List<MonsterSeedStone> stones,
) {
  final target = _foundation + signedOrdinal;
  final counts = const MonsterWorkCounter().calculate(_foundation, target);
  final feeds = const MonsterSeedFeeder().buildHiddenFeeds(counts, stones);
  final drops = const MonsterVisibleDropGenerator().buildVisibleDrops(
    counts: counts,
    hiddenFeeds: feeds,
    stones: stones,
  );
  final bowls = const MonsterBowlProcessor().process(
    counts: counts,
    visibleDrops: drops,
    stones: stones,
  );
  final position = (bowls.orderAt46.indexOf(1) + 1) % 6;
  final nextBowl = bowls.orderAt46[position];
  final current = bowls.finalBowls[0];
  final next = bowls.finalBowls[nextBowl - 1];
  final sixth = bowls.finalBowls[5];
  final first = _normalize(
    (current + BigInt.from(182)).pow(2) +
        BigInt.from(179) * next +
        BigInt.one,
  );
  final directionSeed = _normalize(
    (first + BigInt.from(195)).pow(2) +
        BigInt.from(193) * first +
        BigInt.from(197) * sixth,
  );
  final answerDirection = directionSeed.isOdd ? 1 : -1;
  final limit = (_modulus ~/ _choiceRange) * _choiceRange;
  var accepted = first;
  var rejected = 0;
  while (accepted > limit) {
    accepted = _normalize(accepted + BigInt.from(answerDirection));
    rejected++;
    if (rejected > 922) {
      throw StateError('Unbounded reference rejection');
    }
  }
  final choice = BigInt.one + ((accepted - BigInt.one) % _choiceRange);
  return _ReferenceGap(
    targetDay: target,
    firstAnswer: first,
    answerDirection: answerDirection,
    choice: choice,
    length: choice + BigInt.from(41),
  );
}

BigInt _referencePosition(
  int signedOrdinal,
  List<MonsterSeedStone> stones,
) {
  var position = _foundation;
  final sign = signedOrdinal.sign;
  for (var step = 1; step <= signedOrdinal.abs(); step++) {
    final gap = _referenceGap(BigInt.from(step * sign), stones);
    position += BigInt.from(sign) * gap.length;
  }
  return position;
}

void main() {
  final calculator = MonsterMeatballGateCalculator();
  final stones = const MonsterSeedFeeder().buildStones();
  var positiveCases = 0;
  var negativeCases = 0;
  var asymmetricPairs = 0;
  var recurrenceCases = 0;
  var minGap = BigInt.from(964);
  var maxGap = BigInt.zero;

  _check(calculator.gatePosition(BigInt.zero) == _foundation,
      'Foundation is gate zero');
  _check(MonsterMeatballGateCalculator.choiceModulus == _choiceRange,
      'Fixed gate modulus');

  for (var magnitude = 1; magnitude <= 50; magnitude++) {
    BigInt? forwardLength;
    BigInt? backwardLength;
    for (final sign in <int>[1, -1]) {
      final ordinal = BigInt.from(sign * magnitude);
      final actual = calculator.gapFor(ordinal);
      final expected = _referenceGap(ordinal, stones);
      _check(actual.signedOrdinal == ordinal, 'Signed ordinal preserved');
      _check(actual.targetDay == expected.targetDay, 'Independent pair');
      _check(actual.firstAnswer == expected.firstAnswer, 'Scalar A0');
      _check(actual.answerDirection == expected.answerDirection,
          'Scalar answer direction');
      _check(actual.choice == expected.choice, 'Independent N=922 choice');
      _check(actual.length == expected.length, 'Exact gap length');
      _check(actual.choice >= BigInt.one, 'Choice positive');
      _check(actual.choice <= _choiceRange, 'Choice at most 922');
      _check(actual.length >= BigInt.from(42), 'Minimum canonical gap');
      _check(actual.length <= BigInt.from(963), 'Maximum canonical gap');
      if (actual.length < minGap) {
        minGap = actual.length;
      }
      if (actual.length > maxGap) {
        maxGap = actual.length;
      }
      if (sign > 0) {
        positiveCases++;
        forwardLength = actual.length;
      } else {
        negativeCases++;
        backwardLength = actual.length;
      }
    }
    if (forwardLength != backwardLength) {
      asymmetricPairs++;
    }
  }

  final wideMagnitude = (BigInt.one << 127) + BigInt.from(19);
  for (final ordinal in <BigInt>[
    wideMagnitude,
    -wideMagnitude,
    wideMagnitude + BigInt.one,
    -(wideMagnitude + BigInt.one),
  ]) {
    final actual = calculator.gapFor(ordinal);
    final expected = _referenceGap(ordinal, stones);
    _check(actual.targetDay == expected.targetDay, 'Wide signed pair');
    _check(actual.firstAnswer == expected.firstAnswer, 'Wide A0');
    _check(actual.answerDirection == expected.answerDirection,
        'Wide response direction');
    _check(actual.choice == expected.choice, 'Wide independent choice');
    _check(actual.length == expected.length, 'Wide exact gap');
    _check(actual.length >= BigInt.from(42), 'Wide minimum gap');
    _check(actual.length <= BigInt.from(963), 'Wide maximum gap');
    if (ordinal.isNegative) {
      negativeCases++;
    } else {
      positiveCases++;
    }
  }

  for (var magnitude = 1; magnitude <= 8; magnitude++) {
    for (final sign in <int>[1, -1]) {
      final ordinal = sign * magnitude;
      final actual = calculator.gatePosition(BigInt.from(ordinal));
      final expected = _referencePosition(ordinal, stones);
      final predecessor =
          calculator.gatePosition(BigInt.from(sign * (magnitude - 1)));
      final currentGap = calculator.gapFor(BigInt.from(ordinal)).length;
      _check(actual == expected, 'Independent gate prefix');
      _check(
        actual == predecessor + BigInt.from(sign) * currentGap,
        'Canonical signed recurrence',
      );
      _check(
        sign > 0 ? actual > predecessor : actual < predecessor,
        'Strict monotonicity by direction',
      );
      recurrenceCases++;
    }
  }

  _rejectArgument(() => calculator.gapFor(BigInt.zero),
      'Gate zero has no gap');
  _rejectArgument(
      () => calculator.gatePosition(BigInt.from(33)),
      'Reject prefix above upper bound');
  _rejectArgument(
      () => calculator.gatePosition(BigInt.from(-33)),
      'Reject prefix below lower bound');
  _check(asymmetricPairs > 0, 'Positive and negative gaps not conflated');
  _check(positiveCases == 52, 'Positive cases include wide BigInts');
  _check(negativeCases == 52, 'Negative cases include wide BigInts');
  _check(recurrenceCases == 16, 'Both signed recurrence directions');
  _check(_checks >= 750, 'At least 750 real assertions');
  stdout.writeln(
    'PRODUCTION07_GATE_PASS; checks=$_checks; '
    'positive_cases=$positiveCases; negative_cases=$negativeCases; '
    'recurrence_cases=$recurrenceCases; asymmetric_pairs=$asymmetricPairs; '
    'min_gap=$minGap; max_gap=$maxGap; '
    'bowl=1; seal=1; choice_modulus=922; '
    'five_component_calendar_ready=false',
  );
}
