import 'monster_modular_math.dart';
import 'monster_seed_feeder.dart';
import 'monster_work_counts.dart';

/// One exact grind in a visible drop's eleven-step trace.
final class MonsterVisibleDropStep {
  final int number;
  final BigInt before;
  final List<int> coefficients;
  final BigInt stone;
  final BigInt after;

  MonsterVisibleDropStep._({
    required this.number,
    required this.before,
    required List<int> coefficients,
    required this.stone,
    required this.after,
  }) : coefficients = List<int>.unmodifiable(coefficients);
}

/// Immutable, ordered trace for one of the 46 visible drops.
final class MonsterVisibleDrop {
  final int index;
  final BigInt dough;
  final List<BigInt> dependencies;
  final List<MonsterVisibleDropStep> steps;
  final BigInt value;

  MonsterVisibleDrop._({
    required this.index,
    required this.dough,
    required List<BigInt> dependencies,
    required List<MonsterVisibleDropStep> steps,
    required this.value,
  })  : dependencies = List<BigInt>.unmodifiable(dependencies),
        steps = List<MonsterVisibleDropStep>.unmodifiable(steps);
}

/// Source-derived generator for 46 visible drops, each with eleven exact grinds.
/// Hidden drops occupy positions 0,-1,...,-6 before visible drop 1.
final class MonsterVisibleDropGenerator {
  static const int visibleDropCount = 46;
  static const int hiddenFeedCount = 7;
  static const int grindsPerDrop = 11;

  static const List<List<int>> _grindRows = <List<int>>[
    <int>[3, 5, 7, 11, 0],
    <int>[5, 7, 11, 13, 1],
    <int>[7, 11, 13, 17, 2],
    <int>[11, 13, 17, 19, 3],
    <int>[13, 17, 19, 23, 4],
    <int>[17, 19, 23, 29, 0],
    <int>[19, 23, 29, 31, 1],
    <int>[23, 29, 31, 37, 2],
    <int>[29, 31, 37, 41, 3],
    <int>[31, 37, 41, 43, 4],
    <int>[37, 41, 43, 47, 0],
  ];

  final MonsterModularMath math;

  const MonsterVisibleDropGenerator({
    this.math = const MonsterModularMath(),
  });

  List<MonsterVisibleDrop> buildVisibleDrops({
    required MonsterWorkCounts counts,
    required List<BigInt> hiddenFeeds,
    required List<MonsterSeedStone> stones,
  }) {
    if (hiddenFeeds.length != hiddenFeedCount) {
      throw ArgumentError.value(
        hiddenFeeds.length,
        'hiddenFeeds',
        'Expected exactly seven hidden drops.',
      );
    }
    if (stones.length != MonsterSeedFeeder.stoneCount) {
      throw ArgumentError.value(
        stones.length,
        'stones',
        'Expected the complete 46-stone table.',
      );
    }
    if (counts.action <= BigInt.zero ||
        counts.target <= BigInt.zero ||
        counts.distance <= BigInt.zero ||
        counts.connection != counts.action + counts.target ||
        counts.direction < 1 ||
        counts.direction > 3) {
      throw ArgumentError('Invalid work counts for visible drops.');
    }

    final modulus = MonsterModularMath.modulus;
    for (var index = 0; index < hiddenFeedCount; index++) {
      final feed = hiddenFeeds[index];
      if (feed < BigInt.one || feed > modulus) {
        throw ArgumentError.value(
          feed,
          'hiddenFeeds[$index]',
          'Every hidden drop must be in [1, 2^127 - 1].',
        );
      }
    }

    final results = <MonsterVisibleDrop>[];

    BigInt dropAt(int position) {
      if (position >= 1) {
        return results[position - 1].value;
      }
      final hiddenOrdinal = 1 - position;
      if (hiddenOrdinal < 1 || hiddenOrdinal > hiddenFeedCount) {
        throw StateError(
            'Visible-drop dependency is outside the hidden prefix.');
      }
      return hiddenFeeds[hiddenOrdinal - 1];
    }

    final direction = BigInt.from(counts.direction);
    for (var index = 1; index <= visibleDropCount; index++) {
      final stone = stones[index - 1];
      final dependencies = <BigInt>[
        dropAt(index - 1),
        dropAt(index - 3),
        dropAt(index - 7),
      ];
      final dough = math.save(
        stone.lane(0) * counts.action +
            stone.lane(1) * counts.target +
            stone.lane(2) * counts.distance +
            stone.lane(3) * counts.connection +
            stone.lane(4) * direction +
            dependencies[0] +
            BigInt.from(3) * dependencies[1] +
            BigInt.from(5) * dependencies[2] +
            BigInt.from(index),
      );

      var value = dough;
      final steps = <MonsterVisibleDropStep>[];
      for (var round = 1; round <= grindsPerDrop; round++) {
        final coefficients = _grindRows[round - 1];
        final before = value;
        final stoneValue = stone.lane(coefficients[4]);
        value = math.save(
          math.square(before) +
              BigInt.from(coefficients[0]) * before +
              BigInt.from(coefficients[1]) * dependencies[0] +
              BigInt.from(coefficients[2]) * dependencies[1] +
              BigInt.from(coefficients[3]) * dependencies[2] +
              stoneValue,
        );
        steps.add(
          MonsterVisibleDropStep._(
            number: round,
            before: before,
            coefficients: coefficients,
            stone: stoneValue,
            after: value,
          ),
        );
      }

      results.add(
        MonsterVisibleDrop._(
          index: index,
          dough: dough,
          dependencies: dependencies,
          steps: steps,
          value: value,
        ),
      );
    }

    return List<MonsterVisibleDrop>.unmodifiable(results);
  }
}
