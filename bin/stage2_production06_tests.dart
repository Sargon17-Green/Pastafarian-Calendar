import 'dart:io';

import '../lib/src/monster_bowl_processor.dart';
import '../lib/src/monster_bowl_questions.dart';
import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;
final _modulus = (BigInt.one << 127) - BigInt.one;
const _seals = <int>[1, 10, 11, 12, 20, 21, 22, 30, 31, 32, 33];
const _offsets = <int>[-12, -2, -1, 0, 1, 2, 12];

void _check(bool condition, String label) {
  _checks++;
  if (!condition) {
    throw StateError('PRODUCTION06_CHECK_FAILED: $label');
  }
}

void _expectArgumentError(void Function() action, String label) {
  var rejected = false;
  try {
    action();
  } on ArgumentError {
    rejected = true;
  }
  _check(rejected, label);
}

bool _sameBigInts(List<BigInt> left, List<BigInt> right) {
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

BigInt _referenceNormalize(BigInt value) {
  return ((value - BigInt.one) % _modulus) + BigInt.one;
}

final class _ReferenceSequence {
  final int bowlId;
  final int seal;
  final int nextBowlId;
  final BigInt a0;
  final BigInt directionValue;
  final int direction;

  const _ReferenceSequence({
    required this.bowlId,
    required this.seal,
    required this.nextBowlId,
    required this.a0,
    required this.directionValue,
    required this.direction,
  });
}

final class _ReferenceChoice {
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

  const _ReferenceChoice({
    required this.branch,
    required this.modulus,
    required this.width,
    required this.ringSize,
    required this.limit,
    required this.initial,
    required this.digits,
    required this.accepted,
    required this.rejected,
    required this.result,
  });
}

_ReferenceSequence _referenceSequence(
  MonsterBowlResult bowls,
  int bowlId,
  int seal,
) {
  final position = bowls.orderAt46.indexOf(bowlId);
  final nextBowlId = bowls.orderAt46[(position + 1) % 6];
  final current = bowls.finalBowls[bowlId - 1];
  final next = bowls.finalBowls[nextBowlId - 1];
  final fixedSixth = bowls.finalBowls[5];
  final z = BigInt.from(seal);
  final a0 = _referenceNormalize(
    (current + z + BigInt.from(181)).pow(2) + BigInt.from(179) * next + z,
  );
  final directionValue = _referenceNormalize(
    (a0 + z + BigInt.from(194)).pow(2) +
        BigInt.from(193) * a0 +
        BigInt.from(197) * fixedSixth,
  );
  final direction = directionValue.remainder(BigInt.two) == BigInt.one ? 1 : -1;
  return _ReferenceSequence(
    bowlId: bowlId,
    seal: seal,
    nextBowlId: nextBowlId,
    a0: a0,
    directionValue: directionValue,
    direction: direction,
  );
}

BigInt _referenceAnswerAt(_ReferenceSequence sequence, BigInt index) {
  return _referenceNormalize(
    sequence.a0 + BigInt.from(sequence.direction) * index,
  );
}

_ReferenceChoice _referenceChoice(
  BigInt firstAnswer,
  int direction,
  BigInt modulus,
) {
  if (modulus <= _modulus) {
    final limit = (_modulus ~/ modulus) * modulus;
    var candidate = firstAnswer;
    var rejected = BigInt.zero;
    while (candidate > limit) {
      candidate = _referenceNormalize(
        candidate + BigInt.from(direction),
      );
      rejected += BigInt.one;
    }
    return _ReferenceChoice(
      branch: 'short',
      modulus: modulus,
      width: 1,
      ringSize: _modulus,
      limit: limit,
      initial: firstAnswer,
      digits: const <BigInt>[],
      accepted: candidate,
      rejected: rejected,
      result: BigInt.one + ((candidate - BigInt.one) % modulus),
    );
  }

  var ringSize = _modulus;
  var width = 1;
  while (ringSize < modulus) {
    ringSize *= _modulus;
    width++;
    if (width > 4096) {
      throw ArgumentError('Reference wide policy exceeded.');
    }
  }
  var initial = BigInt.one;
  var place = BigInt.one;
  final digits = <BigInt>[];
  for (var index = 0; index < width; index++) {
    final digit = _referenceNormalize(
      firstAnswer + BigInt.from(direction) * BigInt.from(index),
    );
    digits.add(digit);
    initial += (digit - BigInt.one) * place;
    place *= _modulus;
  }
  final limit = (ringSize ~/ modulus) * modulus;
  var candidate = initial;
  var rejected = BigInt.zero;
  if (candidate > limit) {
    if (direction == 1) {
      rejected = ringSize - candidate + BigInt.one;
      candidate = BigInt.one;
    } else {
      rejected = candidate - limit;
      candidate = limit;
    }
  }
  return _ReferenceChoice(
    branch: 'wide',
    modulus: modulus,
    width: width,
    ringSize: ringSize,
    limit: limit,
    initial: initial,
    digits: List<BigInt>.unmodifiable(digits),
    accepted: candidate,
    rejected: rejected,
    result: BigInt.one + ((candidate - BigInt.one) % modulus),
  );
}

void _compareChoice(MonsterEqualChoice actual, _ReferenceChoice expected) {
  _check(actual.branch == expected.branch, 'Choice branch');
  _check(actual.modulus == expected.modulus, 'Choice modulus');
  _check(actual.width == expected.width, 'Choice width');
  _check(actual.ringSize == expected.ringSize, 'Choice ring size');
  _check(actual.limit == expected.limit, 'Choice rejection limit');
  _check(actual.initial == expected.initial, 'Choice initial candidate');
  _check(_sameBigInts(actual.digits, expected.digits),
      'Least-significant-first digits');
  _check(actual.accepted == expected.accepted, 'First accepted candidate');
  _check(actual.rejected == expected.rejected, 'Rejected candidate count');
  _check(actual.result == expected.result, 'Equal-choice result');
  _check(actual.result >= BigInt.one && actual.result <= actual.modulus,
      'Result range');
  _check(actual.accepted >= BigInt.one && actual.accepted <= actual.limit,
      'Accepted range');
}

void main() {
  final feeder = const MonsterSeedFeeder();
  final counter = const MonsterWorkCounter();
  final visibleGenerator = const MonsterVisibleDropGenerator();
  final bowlProcessor = const MonsterBowlProcessor();
  final engine = const MonsterBowlQuestionEngine();
  final stones = feeder.buildStones();
  final moduli = <BigInt>[
    BigInt.one,
    BigInt.from(2),
    BigInt.from(17),
    BigInt.from(922),
    _modulus,
    _modulus + BigInt.one,
    _modulus.pow(2) - BigInt.from(2),
    _modulus.pow(2) + BigInt.one,
    _modulus.pow(3) - BigInt.one,
  ];
  const answerIndices = <int>[0, 1, 2, 17, 127];

  _check(
    MonsterBowlQuestionEngine.canonicalSeals.length == 11,
    'Eleven canonical seals',
  );
  _check(
    MonsterBowlQuestionEngine.canonicalSeals.toSet().containsAll(_seals),
    'Canonical seal IDs',
  );
  _check(!MonsterBowlQuestionEngine.canonicalSeals.contains(40),
      'Seal 40 remains blank');

  var sequenceCases = 0;
  var selectionCases = 0;
  var shortRejected = 0;
  var wideRejected = 0;
  var positiveDirections = 0;
  var negativeDirections = 0;

  for (final actionOffset in _offsets) {
    for (final targetOffset in _offsets) {
      final counts = counter.calculate(
        MonsterWorkCounter.foundationDay + BigInt.from(actionOffset),
        MonsterWorkCounter.foundationDay + BigInt.from(targetOffset),
      );
      final feeds = feeder.buildHiddenFeeds(counts, stones);
      final visible = visibleGenerator.buildVisibleDrops(
        counts: counts,
        hiddenFeeds: feeds,
        stones: stones,
      );
      final bowls = bowlProcessor.process(
        counts: counts,
        visibleDrops: visible,
        stones: stones,
      );

      for (final seal in _seals) {
        for (var bowlId = 1; bowlId <= 6; bowlId++) {
          final actual = engine.createAnswerSequence(
            bowls: bowls,
            bowlId: bowlId,
            seal: seal,
          );
          final expected = _referenceSequence(bowls, bowlId, seal);
          _check(actual.bowlId == expected.bowlId, 'Question bowl identity');
          _check(actual.seal == expected.seal, 'Question seal');
          _check(actual.nextBowlId == expected.nextBowlId,
              'Next bowl from orderAt46');
          _check(actual.a0 == expected.a0, 'Independent A0 oracle');
          _check(
            actual.directionValue == expected.directionValue,
            'Independent direction value oracle',
          );
          _check(actual.direction == expected.direction, 'Direction parity');
          if (actual.direction == 1) {
            positiveDirections++;
          } else {
            negativeDirections++;
          }

          for (final answerIndex in answerIndices) {
            _check(
              actual.answerAt(BigInt.from(answerIndex)) ==
                  _referenceAnswerAt(expected, BigInt.from(answerIndex)),
              'Answer stream digit',
            );
          }

          for (final modulus in moduli) {
            final actualChoice = engine.chooseEqual(
              sequence: actual,
              modulus: modulus,
            );
            final expectedChoice = _referenceChoice(
              expected.a0,
              expected.direction,
              modulus,
            );
            _compareChoice(actualChoice, expectedChoice);
            if (actualChoice.rejected > BigInt.zero) {
              if (actualChoice.branch == 'short') {
                shortRejected++;
              } else {
                wideRejected++;
              }
            }
            selectionCases++;
          }
          sequenceCases++;
        }
      }
    }
  }

  final syntheticShortForward = engine.chooseEqualFromStart(
    firstAnswer: _modulus,
    direction: 1,
    modulus: BigInt.from(17),
  );
  final syntheticShortBackward = engine.chooseEqualFromStart(
    firstAnswer: _modulus,
    direction: -1,
    modulus: BigInt.from(17),
  );
  final shortLimit = (_modulus ~/ BigInt.from(17)) * BigInt.from(17);
  _check(syntheticShortForward.accepted == BigInt.one, 'Short forward wrap');
  _check(syntheticShortForward.rejected == BigInt.one,
      'Short forward rejection count');
  _check(syntheticShortBackward.accepted == shortLimit, 'Short backward limit');
  _check(
    syntheticShortBackward.rejected == _modulus - shortLimit,
    'Short backward rejection count',
  );

  final syntheticWideForward = engine.chooseEqualFromStart(
    firstAnswer: _modulus - BigInt.one,
    direction: 1,
    modulus: _modulus.pow(2) - BigInt.from(2),
  );
  final syntheticWideBackward = engine.chooseEqualFromStart(
    firstAnswer: _modulus,
    direction: -1,
    modulus: _modulus.pow(2) - _modulus - BigInt.one,
  );
  _check(syntheticWideForward.width == 2, 'Wide forward width');
  _check(
    syntheticWideForward.initial > syntheticWideForward.limit,
    'Wide forward rejection branch reached',
  );
  _check(
      syntheticWideForward.accepted == BigInt.one, 'Wide forward wraps to one');
  _check(syntheticWideForward.rejected == BigInt.from(2),
      'Wide forward rejection count');
  _check(syntheticWideBackward.width == 2, 'Wide backward width');
  _check(
    syntheticWideBackward.initial > syntheticWideBackward.limit,
    'Wide backward rejection branch reached',
  );
  _check(
    syntheticWideBackward.accepted == syntheticWideBackward.limit,
    'Wide backward accepts at limit',
  );
  _check(
    syntheticWideBackward.rejected == BigInt.one,
    'Wide backward rejection count',
  );

  final foundation = MonsterWorkCounter.foundationDay;
  final foundationCounts = counter.calculate(foundation, foundation);
  final foundationFeeds = feeder.buildHiddenFeeds(foundationCounts, stones);
  final foundationVisible = visibleGenerator.buildVisibleDrops(
    counts: foundationCounts,
    hiddenFeeds: foundationFeeds,
    stones: stones,
  );
  final foundationBowls = bowlProcessor.process(
    counts: foundationCounts,
    visibleDrops: foundationVisible,
    stones: stones,
  );
  _check(
    _sameBigInts(
      foundationBowls.finalBowls,
      <BigInt>[
        BigInt.parse('65286679584284972964194865805379907599'),
        BigInt.parse('127720283375330263615328810127751035299'),
        BigInt.parse('54364069496183805843611594721403108554'),
        BigInt.parse('93072329024469476118876155742008280619'),
        BigInt.parse('54867842942953573450868747713087920246'),
        BigInt.parse('111207247632761530752404582123499651367'),
      ],
    ),
    'Canonical bowl checkpoint retained',
  );
  _check(
    _sameBigInts(
      foundationBowls.orderAt46.map(BigInt.from).toList(),
      <BigInt>[
        BigInt.from(4),
        BigInt.from(5),
        BigInt.from(2),
        BigInt.from(3),
        BigInt.from(6),
        BigInt.one
      ],
    ),
    'Canonical orderAt46 retained',
  );

  _expectArgumentError(
    () => engine.createAnswerSequence(
      bowls: foundationBowls,
      bowlId: 0,
      seal: 1,
    ),
    'Reject bowl ID zero',
  );
  _expectArgumentError(
    () => engine.createAnswerSequence(
      bowls: foundationBowls,
      bowlId: 1,
      seal: 40,
    ),
    'Reject reserved seal 40',
  );
  _expectArgumentError(
    () => engine.chooseEqualFromStart(
      firstAnswer: BigInt.one,
      direction: 0,
      modulus: BigInt.from(2),
    ),
    'Reject zero direction',
  );
  _expectArgumentError(
    () => engine.chooseEqualFromStart(
      firstAnswer: BigInt.zero,
      direction: 1,
      modulus: BigInt.from(2),
    ),
    'Reject first answer zero',
  );
  _expectArgumentError(
    () => engine.chooseEqualFromStart(
      firstAnswer: BigInt.one,
      direction: 1,
      modulus: BigInt.zero,
    ),
    'Reject zero modulus',
  );
  final sequence = engine.createAnswerSequence(
    bowls: foundationBowls,
    bowlId: 1,
    seal: 1,
  );
  _expectArgumentError(
    () => sequence.answerAt(-BigInt.one),
    'Reject negative answer index',
  );
  final wideChoice = engine.chooseEqual(
    sequence: sequence,
    modulus: _modulus + BigInt.one,
  );
  try {
    wideChoice.digits.add(BigInt.one);
    _check(false, 'Wide digit list must be immutable');
  } on UnsupportedError {
    _check(true, 'Wide digit list immutable');
  }

  _check(sequenceCases == 3234, 'Exactly 3234 bowl/seal sequences');
  _check(selectionCases == 29106, 'Exactly 29106 equal-choice cases');
  _check(positiveDirections > 0 && negativeDirections > 0,
      'Both answer directions exercised');
  _check(shortRejected > 0, 'Short rejection branch exercised');
  _check(wideRejected > 0, 'Wide rejection branch exercised');
  _check(_checks >= 100000, 'Minimum 100000 real assertions');
  stdout.writeln(
    'PRODUCTION06_SEALED_BOWL_PASS; checks=$_checks; '
    'sequence_cases=$sequenceCases; selection_cases=$selectionCases; '
    'short_rejections=$shortRejected; wide_rejections=$wideRejected; '
    'positive_directions=$positiveDirections; negative_directions=$negativeDirections; '
    'canonical_seals=11; five_component_calendar_ready=false',
  );
}
