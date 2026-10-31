import 'monster_modular_math.dart';
import 'monster_seed_feeder.dart';

/// Converts seven hidden feeds into seven visible droplets using seven
/// synchronous, bounded mixing rounds. This is not a calendar result.
final class MonsterVisibleDropletMixer {
  static const int dropletCount = 7;
  static const int mixingRounds = 7;

  final MonsterModularMath math;

  const MonsterVisibleDropletMixer({this.math = const MonsterModularMath()});

  List<BigInt> buildVisibleDroplets({
    required List<BigInt> hiddenFeeds,
    required List<MonsterSeedStone> stones,
  }) {
    if (hiddenFeeds.length != dropletCount) {
      throw ArgumentError.value(
        hiddenFeeds.length,
        'hiddenFeeds',
        'Expected exactly seven hidden feeds.',
      );
    }
    if (stones.length != MonsterSeedFeeder.stoneCount) {
      throw ArgumentError.value(
        stones.length,
        'stones',
        'Expected the complete 46-stone seed table.',
      );
    }

    final modulus = MonsterModularMath.modulus;
    for (var index = 0; index < dropletCount; index++) {
      final feed = hiddenFeeds[index];
      if (feed < BigInt.one || feed > modulus) {
        throw ArgumentError.value(
          feed,
          'hiddenFeeds[$index]',
          'Every hidden feed must be in [1, 2^127 - 1].',
        );
      }
    }

    var state = <BigInt>[];
    for (var index = 0; index < dropletCount; index++) {
      final stone = stones[index];
      final initial = hiddenFeeds[index] +
          stone.lane(index % 5) +
          stone.lane((index + 1) % 5) +
          BigInt.from(index + 1);
      state.add(math.save(initial));
    }

    for (var round = 1; round <= mixingRounds; round++) {
      final next = <BigInt>[];
      for (var index = 0; index < dropletCount; index++) {
        final ordinal = BigInt.from(index + 1);
        final roundNumber = BigInt.from(round);
        final right = state[(index + 1) % dropletCount];
        final far = state[(index + 2) % dropletCount];
        final seasoning = stones[index].lane((index + round) % 5);
        final mixed = math.square(state[index]) +
            ordinal * right +
            roundNumber * far +
            seasoning +
            ordinal +
            roundNumber;
        next.add(math.save(mixed));
      }
      state = next;
    }

    return List<BigInt>.unmodifiable(state);
  }
}
