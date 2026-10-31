import 'monster_modular_math.dart';
import 'monster_work_counts.dart';

/// A five-lane seed stone with immutable values.
final class MonsterSeedStone {
  final List<BigInt> lanes;

  MonsterSeedStone._(List<BigInt> values)
    : lanes = List<BigInt>.unmodifiable(values);

  BigInt lane(int index) => lanes[index];
}

/// Production-only, independent 46-stone generator and seven-feed pipeline.
/// No dependency on the normative reference or any other branch.
final class MonsterSeedFeeder {
  static const int stoneCount = 46;
  static const int hiddenFeedCount = 7;

  final MonsterModularMath math;

  const MonsterSeedFeeder({this.math = const MonsterModularMath()});

  List<MonsterSeedStone> buildStones() {
    var lanes = <BigInt>[
      BigInt.from(17),
      BigInt.from(29),
      BigInt.from(43),
      BigInt.from(71),
      BigInt.from(101),
    ];
    const mixing = <int>[3, 5, 7, 11, 13];
    final table = <MonsterSeedStone>[];
    for (var ordinal = 1; ordinal <= stoneCount; ordinal++) {
      table.add(MonsterSeedStone._(lanes));
      if (ordinal == stoneCount) {
        break;
      }
      final next = <BigInt>[];
      for (var channel = 0; channel < 5; channel++) {
        final future = lanes[(channel + 1) % 5];
        final carry = channel == 0
            ? BigInt.from(ordinal + 1)
            : lanes[channel - 1];
        next.add(
          math.save(
            math.square(lanes[channel]) +
                BigInt.from(mixing[channel]) * future +
                carry,
          ),
        );
      }
      lanes = next;
    }
    return List<MonsterSeedStone>.unmodifiable(table);
  }

  /// Seven hidden intermediate feeds, never a complete calendar result.
  List<BigInt> buildHiddenFeeds(
    MonsterWorkCounts counts,
    List<MonsterSeedStone> stones,
  ) {
    if (stones.length != stoneCount) {
      throw ArgumentError.value(stones.length, 'stones', 'Expected 46 stones.');
    }
    if (counts.action <= BigInt.zero ||
        counts.target <= BigInt.zero ||
        counts.distance <= BigInt.zero ||
        counts.connection != counts.action + counts.target ||
        counts.direction < 1 ||
        counts.direction > 3) {
      throw ArgumentError('Invalid work counts for seed feeding.');
    }

    final feeds = <BigInt>[];
    final direction = BigInt.from(counts.direction);
    for (var ordinal = 1; ordinal <= hiddenFeedCount; ordinal++) {
      final stone = stones[ordinal - 1];
      var value = math.save(
        counts.action +
            BigInt.from(2 * ordinal + 1) * counts.target +
            BigInt.from(3 * ordinal + 1) * counts.distance +
            BigInt.from(4 * ordinal + 2) * counts.connection +
            BigInt.from(4 * ordinal + 4) * direction +
            stone.lanes.fold<BigInt>(
              BigInt.zero,
              (sum, lane) => sum + lane,
            ),
      );
      for (var grind = 1; grind <= 7; grind++) {
        value = math.save(
          math.square(value) +
              BigInt.from(3) * value +
              stone.lane((grind - 1) % 5) +
              BigInt.from(grind),
        );
      }
      feeds.add(value);
    }
    return List<BigInt>.unmodifiable(feeds);
  }
}
