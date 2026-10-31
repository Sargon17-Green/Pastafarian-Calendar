import 'monster_modular_math.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';

/// One simultaneous bowl update caused by one visible drop.
final class MonsterBowlDropUpdate {
  final int position;
  final int bowlId;
  final int previousBowlId;
  final int followingBowlId;
  final BigInt oldValue;
  final BigInt directPour;
  final int stoneIndex;
  final BigInt stone;
  final BigInt u;
  final BigInt value;

  const MonsterBowlDropUpdate({
    required this.position,
    required this.bowlId,
    required this.previousBowlId,
    required this.followingBowlId,
    required this.oldValue,
    required this.directPour,
    required this.stoneIndex,
    required this.stone,
    required this.u,
    required this.value,
  });
}

/// Complete trace for one visible-drop update across all six fixed bowl IDs.
final class MonsterBowlDropStage {
  final int dropIndex;
  final BigInt dropValue;
  final int permutationRank;
  final List<int> order;
  final List<BigInt> before;
  final List<BigInt> directPours;
  final List<MonsterBowlDropUpdate> updates;
  final List<BigInt> after;

  MonsterBowlDropStage._({
    required this.dropIndex,
    required this.dropValue,
    required this.permutationRank,
    required List<int> order,
    required List<BigInt> before,
    required List<BigInt> directPours,
    required List<MonsterBowlDropUpdate> updates,
    required List<BigInt> after,
  })  : order = List<int>.unmodifiable(order),
        before = List<BigInt>.unmodifiable(before),
        directPours = List<BigInt>.unmodifiable(directPours),
        updates = List<MonsterBowlDropUpdate>.unmodifiable(updates),
        after = List<BigInt>.unmodifiable(after);
}

/// One simultaneous bowl update in a post-drop stir.
final class MonsterBowlStirUpdate {
  final int position;
  final int bowlId;
  final int previousBowlId;
  final int followingBowlId;
  final BigInt oldValue;
  final BigInt u;
  final BigInt value;

  const MonsterBowlStirUpdate({
    required this.position,
    required this.bowlId,
    required this.previousBowlId,
    required this.followingBowlId,
    required this.oldValue,
    required this.u,
    required this.value,
  });
}

/// Complete trace for one of the twelve post-drop stirring passes.
final class MonsterBowlPostStir {
  final int step;
  final BigInt savedSum;
  final int permutationRank;
  final List<int> order;
  final List<BigInt> before;
  final List<MonsterBowlStirUpdate> updates;
  final List<BigInt> after;

  MonsterBowlPostStir._({
    required this.step,
    required this.savedSum,
    required this.permutationRank,
    required List<int> order,
    required List<BigInt> before,
    required List<MonsterBowlStirUpdate> updates,
    required List<BigInt> after,
  })  : order = List<int>.unmodifiable(order),
        before = List<BigInt>.unmodifiable(before),
        updates = List<MonsterBowlStirUpdate>.unmodifiable(updates),
        after = List<BigInt>.unmodifiable(after);
}

/// Immutable result; all bowl vectors are indexed by fixed bowl ID 1..6.
final class MonsterBowlResult {
  final List<BigInt> initial;
  final List<MonsterBowlDropStage> dropStages;
  final List<int> orderAt46;
  final List<BigInt> afterDrops;
  final List<MonsterBowlPostStir> postStirs;
  final List<BigInt> finalBowls;

  MonsterBowlResult._({
    required List<BigInt> initial,
    required List<MonsterBowlDropStage> dropStages,
    required List<int> orderAt46,
    required List<BigInt> afterDrops,
    required List<MonsterBowlPostStir> postStirs,
    required List<BigInt> finalBowls,
  })  : initial = List<BigInt>.unmodifiable(initial),
        dropStages = List<MonsterBowlDropStage>.unmodifiable(dropStages),
        orderAt46 = List<int>.unmodifiable(orderAt46),
        afterDrops = List<BigInt>.unmodifiable(afterDrops),
        postStirs = List<MonsterBowlPostStir>.unmodifiable(postStirs),
        finalBowls = List<BigInt>.unmodifiable(finalBowls);
}

/// Implements README §§H–K: six bowls, 46 drop updates, and twelve post-stirs.
final class MonsterBowlProcessor {
  static const int bowlCount = 6;
  static const int visibleDropCount = 46;
  static const int postStirCount = 12;
  static const int permutationCount = 720;

  static const List<int> _bowlPrimes = <int>[17, 19, 23, 29, 31, 37];
  static const List<int> _stonePosition = <int>[0, 1, 2, 3, 4, 0];
  static const List<int> _factorials = <int>[1, 1, 2, 6, 24, 120];

  final MonsterModularMath math;

  const MonsterBowlProcessor({this.math = const MonsterModularMath()});

  List<int> _permutationAtRank(int rank) {
    if (rank < 1 || rank > permutationCount) {
      throw ArgumentError.value(rank, 'rank', 'Expected a rank in 1..720.');
    }
    final remaining = <int>[1, 2, 3, 4, 5, 6];
    var offset = rank - 1;
    final order = <int>[];
    for (var size = bowlCount; size >= 1; size--) {
      final block = _factorials[size - 1];
      final choice = offset ~/ block;
      offset %= block;
      order.add(remaining.removeAt(choice));
    }
    return List<int>.unmodifiable(order);
  }

  void _validateCounts(MonsterWorkCounts counts) {
    if (counts.action <= BigInt.zero ||
        counts.target <= BigInt.zero ||
        counts.distance <= BigInt.zero ||
        counts.connection != counts.action + counts.target ||
        counts.direction < 1 ||
        counts.direction > 3) {
      throw ArgumentError('Invalid work counts for bowl processing.');
    }
  }

  MonsterBowlResult process({
    required MonsterWorkCounts counts,
    required List<MonsterVisibleDrop> visibleDrops,
    required List<MonsterSeedStone> stones,
  }) {
    _validateCounts(counts);
    if (stones.length != MonsterSeedFeeder.stoneCount) {
      throw ArgumentError.value(
        stones.length,
        'stones',
        'Expected the complete 46-stone table.',
      );
    }
    if (visibleDrops.length != visibleDropCount) {
      throw ArgumentError.value(
        visibleDrops.length,
        'visibleDrops',
        'Expected exactly 46 ordered visible drops.',
      );
    }

    final modulus = MonsterModularMath.modulus;
    for (var index = 0; index < visibleDropCount; index++) {
      final drop = visibleDrops[index];
      if (drop.index != index + 1 ||
          drop.steps.length != 11 ||
          drop.value != drop.steps.last.after ||
          drop.value < BigInt.one ||
          drop.value > modulus) {
        throw ArgumentError.value(
          drop.index,
          'visibleDrops[$index]',
          'Visible drops must be complete, ordered and normalized.',
        );
      }
    }

    final initial = <BigInt>[];
    final direction = BigInt.from(counts.direction);
    for (var bowlId = 1; bowlId <= bowlCount; bowlId++) {
      final ordinal = BigInt.from(bowlId);
      final prime = BigInt.from(_bowlPrimes[bowlId - 1]);
      final seed = counts.action +
          ordinal * counts.target +
          counts.distance +
          counts.connection +
          direction +
          prime * prime;
      initial.add(math.save(math.square(seed) + ordinal));
    }

    var bowls = List<BigInt>.from(initial);
    final dropStages = <MonsterBowlDropStage>[];
    List<int>? orderAt46;

    for (var dropIndex = 1;
        dropIndex <= visibleDropCount;
        dropIndex++) {
      final dropValue = visibleDrops[dropIndex - 1].value;
      final rank = ((dropValue - BigInt.one) %
                  BigInt.from(permutationCount))
              .toInt() +
          1;
      final order = _permutationAtRank(rank);
      final stone = stones[dropIndex - 1];
      final before = List<BigInt>.unmodifiable(bowls);

      final directPours = <BigInt>[];
      for (var positionIndex = 0;
          positionIndex < bowlCount;
          positionIndex++) {
        if (positionIndex >= 3) {
          directPours.add(BigInt.zero);
        } else {
          final bowlId = order[positionIndex];
          final oldValue = bowls[bowlId - 1];
          final pour = math.save(
            math.square(dropValue) +
                stone.lane(positionIndex) * oldValue +
                BigInt.from(3 + 2 * positionIndex) *
                    BigInt.from(dropIndex),
          );
          directPours.add(pour);
        }
      }

      final next = List<BigInt>.filled(bowlCount, BigInt.zero);
      final updates = <MonsterBowlDropUpdate>[];
      for (var positionIndex = 0;
          positionIndex < bowlCount;
          positionIndex++) {
        final position = positionIndex + 1;
        final bowlId = order[positionIndex];
        final previousBowlId = order[(positionIndex + bowlCount - 1) %
            bowlCount];
        final followingBowlId = order[(positionIndex + 1) % bowlCount];
        final oldValue = bowls[bowlId - 1];
        final previousValue = bowls[previousBowlId - 1];
        final followingValue = bowls[followingBowlId - 1];
        final directPour = directPours[positionIndex];
        final stoneIndex = _stonePosition[positionIndex];
        final stoneValue = stone.lane(stoneIndex);
        final u = oldValue +
            BigInt.from(2) * previousValue +
            BigInt.from(3) * followingValue +
            directPour +
            dropValue +
            stoneValue;
        final value = math.save(
          math.square(u) +
              BigInt.from(5) * previousValue * followingValue +
              BigInt.from(dropIndex) * BigInt.from(position),
        );
        next[bowlId - 1] = value;
        updates.add(
          MonsterBowlDropUpdate(
            position: position,
            bowlId: bowlId,
            previousBowlId: previousBowlId,
            followingBowlId: followingBowlId,
            oldValue: oldValue,
            directPour: directPour,
            stoneIndex: stoneIndex,
            stone: stoneValue,
            u: u,
            value: value,
          ),
        );
      }

      final after = List<BigInt>.unmodifiable(next);
      dropStages.add(
        MonsterBowlDropStage._(
          dropIndex: dropIndex,
          dropValue: dropValue,
          permutationRank: rank,
          order: order,
          before: before,
          directPours: directPours,
          updates: updates,
          after: after,
        ),
      );
      bowls = next;
      if (dropIndex == visibleDropCount) {
        orderAt46 = order;
      }
    }

    final savedOrderAt46 = orderAt46;
    if (savedOrderAt46 == null) {
      throw StateError('The 46th drop order was not captured.');
    }
    final afterDrops = List<BigInt>.unmodifiable(bowls);

    final postStirs = <MonsterBowlPostStir>[];
    for (var step = 1; step <= postStirCount; step++) {
      final before = List<BigInt>.unmodifiable(bowls);
      var bowlSum = BigInt.zero;
      for (final value in before) {
        bowlSum += value;
      }
      final savedSum = math.save(
        bowlSum + BigInt.from(149) * BigInt.from(step),
      );
      final rank = ((savedSum - BigInt.one) %
                  BigInt.from(permutationCount))
              .toInt() +
          1;
      final order = _permutationAtRank(rank);
      final next = List<BigInt>.filled(bowlCount, BigInt.zero);
      final updates = <MonsterBowlStirUpdate>[];

      for (var positionIndex = 0;
          positionIndex < bowlCount;
          positionIndex++) {
        final position = positionIndex + 1;
        final bowlId = order[positionIndex];
        final previousBowlId = order[(positionIndex + bowlCount - 1) %
            bowlCount];
        final followingBowlId = order[(positionIndex + 1) % bowlCount];
        final oldValue = before[bowlId - 1];
        final previousValue = before[previousBowlId - 1];
        final followingValue = before[followingBowlId - 1];
        final u = oldValue +
            BigInt.from(3) * previousValue +
            BigInt.from(5) * followingValue +
            savedSum +
            BigInt.from(step) +
            BigInt.from(position * position);
        final value = math.save(
          math.square(u) +
              BigInt.from(7) * previousValue * followingValue,
        );
        next[bowlId - 1] = value;
        updates.add(
          MonsterBowlStirUpdate(
            position: position,
            bowlId: bowlId,
            previousBowlId: previousBowlId,
            followingBowlId: followingBowlId,
            oldValue: oldValue,
            u: u,
            value: value,
          ),
        );
      }

      final after = List<BigInt>.unmodifiable(next);
      postStirs.add(
        MonsterBowlPostStir._(
          step: step,
          savedSum: savedSum,
          permutationRank: rank,
          order: order,
          before: before,
          updates: updates,
          after: after,
        ),
      );
      bowls = next;
    }

    return MonsterBowlResult._(
      initial: initial,
      dropStages: dropStages,
      orderAt46: savedOrderAt46,
      afterDrops: afterDrops,
      postStirs: postStirs,
      finalBowls: bowls,
    );
  }
}
