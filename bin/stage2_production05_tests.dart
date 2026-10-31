import 'dart:io';

import '../lib/src/monster_bowl_processor.dart';
import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;
final _modulus = (BigInt.one << 127) - BigInt.one;
const _bowlPrimes = <int>[17, 19, 23, 29, 31, 37];
const _stonePosition = <int>[0, 1, 2, 3, 4, 0];

void _check(bool condition, String label) {
  _checks++;
  if (!condition) {
    throw StateError('PRODUCTION05_CHECK_FAILED: $label');
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

void _expectImmutable(void Function() action, String label) {
  var rejected = false;
  try {
    action();
  } on UnsupportedError {
    rejected = true;
  }
  _check(rejected, label);
}

bool _sameInts(List<int> left, List<int> right) {
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

List<List<int>> _buildReferencePermutations() {
  final permutations = <List<int>>[];

  void visit(List<int> prefix, List<int> remaining) {
    if (remaining.isEmpty) {
      permutations.add(List<int>.unmodifiable(prefix));
      return;
    }
    for (var index = 0; index < remaining.length; index++) {
      final nextPrefix = List<int>.from(prefix)..add(remaining[index]);
      final nextRemaining = List<int>.from(remaining)..removeAt(index);
      visit(nextPrefix, nextRemaining);
    }
  }

  visit(<int>[], <int>[1, 2, 3, 4, 5, 6]);
  return List<List<int>>.unmodifiable(permutations);
}

final _referencePermutations = _buildReferencePermutations();

final class _ReferenceDropUpdate {
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

  const _ReferenceDropUpdate({
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

final class _ReferenceDropStage {
  final int dropIndex;
  final BigInt dropValue;
  final int permutationRank;
  final List<int> order;
  final List<BigInt> before;
  final List<BigInt> directPours;
  final List<_ReferenceDropUpdate> updates;
  final List<BigInt> after;

  const _ReferenceDropStage({
    required this.dropIndex,
    required this.dropValue,
    required this.permutationRank,
    required this.order,
    required this.before,
    required this.directPours,
    required this.updates,
    required this.after,
  });
}

final class _ReferenceStirUpdate {
  final int position;
  final int bowlId;
  final int previousBowlId;
  final int followingBowlId;
  final BigInt oldValue;
  final BigInt u;
  final BigInt value;

  const _ReferenceStirUpdate({
    required this.position,
    required this.bowlId,
    required this.previousBowlId,
    required this.followingBowlId,
    required this.oldValue,
    required this.u,
    required this.value,
  });
}

final class _ReferenceStirStage {
  final int step;
  final BigInt savedSum;
  final int permutationRank;
  final List<int> order;
  final List<BigInt> before;
  final List<_ReferenceStirUpdate> updates;
  final List<BigInt> after;

  const _ReferenceStirStage({
    required this.step,
    required this.savedSum,
    required this.permutationRank,
    required this.order,
    required this.before,
    required this.updates,
    required this.after,
  });
}

final class _ReferenceBowlResult {
  final List<BigInt> initial;
  final List<_ReferenceDropStage> dropStages;
  final List<int> orderAt46;
  final List<BigInt> afterDrops;
  final List<_ReferenceStirStage> postStirs;
  final List<BigInt> finalBowls;

  const _ReferenceBowlResult({
    required this.initial,
    required this.dropStages,
    required this.orderAt46,
    required this.afterDrops,
    required this.postStirs,
    required this.finalBowls,
  });
}

/// Independent scalar bowl oracle; permutation order is generated recursively.
_ReferenceBowlResult _referenceBowlProcess(
  MonsterWorkCounts counts,
  List<List<BigInt>> stones,
  List<MonsterVisibleDrop> visibleDrops,
) {
  final initial = <BigInt>[];
  for (var bowlId = 1; bowlId <= 6; bowlId++) {
    final prime = BigInt.from(_bowlPrimes[bowlId - 1]);
    final ordinal = BigInt.from(bowlId);
    final terms = <BigInt>[
      counts.action,
      ordinal * counts.target,
      counts.distance,
      counts.connection,
      BigInt.from(counts.direction),
      prime * prime,
    ];
    var seed = BigInt.zero;
    for (final term in terms) {
      seed += term;
    }
    final initialTerms = <BigInt>[seed.pow(2), ordinal];
    var initialTotal = BigInt.zero;
    for (final term in initialTerms) {
      initialTotal += term;
    }
    initial.add(_referenceNormalize(initialTotal));
  }

  var bowls = List<BigInt>.from(initial);
  final dropStages = <_ReferenceDropStage>[];
  List<int>? orderAt46;

  for (var dropIndex = 1; dropIndex <= 46; dropIndex++) {
    final dropValue = visibleDrops[dropIndex - 1].value;
    final rank = ((dropValue - BigInt.one) % BigInt.from(720)).toInt() + 1;
    final order = _referencePermutations[rank - 1];
    final stone = stones[dropIndex - 1];
    final before = List<BigInt>.unmodifiable(bowls);

    final directPours = <BigInt>[];
    for (var positionIndex = 0; positionIndex < 6; positionIndex++) {
      if (positionIndex >= 3) {
        directPours.add(BigInt.zero);
      } else {
        final bowlId = order[positionIndex];
        final terms = <BigInt>[
          dropValue.pow(2),
          stone[positionIndex] * bowls[bowlId - 1],
          BigInt.from(3 + 2 * positionIndex) * BigInt.from(dropIndex),
        ];
        var total = BigInt.zero;
        for (final term in terms) {
          total += term;
        }
        directPours.add(_referenceNormalize(total));
      }
    }

    final next = List<BigInt>.filled(6, BigInt.zero);
    final updates = <_ReferenceDropUpdate>[];
    for (var positionIndex = 0; positionIndex < 6; positionIndex++) {
      final position = positionIndex + 1;
      final bowlId = order[positionIndex];
      final previousBowlId = order[(positionIndex + 5) % 6];
      final followingBowlId = order[(positionIndex + 1) % 6];
      final oldValue = bowls[bowlId - 1];
      final previousValue = bowls[previousBowlId - 1];
      final followingValue = bowls[followingBowlId - 1];
      final stoneIndex = _stonePosition[positionIndex];
      final stoneValue = stone[stoneIndex];
      final uTerms = <BigInt>[
        oldValue,
        BigInt.from(2) * previousValue,
        BigInt.from(3) * followingValue,
        directPours[positionIndex],
        dropValue,
        stoneValue,
      ];
      var u = BigInt.zero;
      for (final term in uTerms) {
        u += term;
      }
      final valueTerms = <BigInt>[
        u.pow(2),
        BigInt.from(5) * previousValue * followingValue,
        BigInt.from(dropIndex) * BigInt.from(position),
      ];
      var valueTotal = BigInt.zero;
      for (final term in valueTerms) {
        valueTotal += term;
      }
      final value = _referenceNormalize(valueTotal);
      next[bowlId - 1] = value;
      updates.add(
        _ReferenceDropUpdate(
          position: position,
          bowlId: bowlId,
          previousBowlId: previousBowlId,
          followingBowlId: followingBowlId,
          oldValue: oldValue,
          directPour: directPours[positionIndex],
          stoneIndex: stoneIndex,
          stone: stoneValue,
          u: u,
          value: value,
        ),
      );
    }

    final after = List<BigInt>.unmodifiable(next);
    dropStages.add(
      _ReferenceDropStage(
        dropIndex: dropIndex,
        dropValue: dropValue,
        permutationRank: rank,
        order: order,
        before: before,
        directPours: List<BigInt>.unmodifiable(directPours),
        updates: List<_ReferenceDropUpdate>.unmodifiable(updates),
        after: after,
      ),
    );
    bowls = next;
    if (dropIndex == 46) {
      orderAt46 = order;
    }
  }

  final savedOrderAt46 = orderAt46!;
  final afterDrops = List<BigInt>.unmodifiable(bowls);
  final postStirs = <_ReferenceStirStage>[];

  for (var step = 1; step <= 12; step++) {
    final before = List<BigInt>.unmodifiable(bowls);
    var bowlSum = BigInt.zero;
    for (final value in before) {
      bowlSum += value;
    }
    final savedSum = _referenceNormalize(
      bowlSum + BigInt.from(149) * BigInt.from(step),
    );
    final rank = ((savedSum - BigInt.one) % BigInt.from(720)).toInt() + 1;
    final order = _referencePermutations[rank - 1];
    final next = List<BigInt>.filled(6, BigInt.zero);
    final updates = <_ReferenceStirUpdate>[];

    for (var positionIndex = 0; positionIndex < 6; positionIndex++) {
      final position = positionIndex + 1;
      final bowlId = order[positionIndex];
      final previousBowlId = order[(positionIndex + 5) % 6];
      final followingBowlId = order[(positionIndex + 1) % 6];
      final oldValue = before[bowlId - 1];
      final previousValue = before[previousBowlId - 1];
      final followingValue = before[followingBowlId - 1];
      final uTerms = <BigInt>[
        oldValue,
        BigInt.from(3) * previousValue,
        BigInt.from(5) * followingValue,
        savedSum,
        BigInt.from(step),
        BigInt.from(position * position),
      ];
      var u = BigInt.zero;
      for (final term in uTerms) {
        u += term;
      }
      final valueTerms = <BigInt>[
        u.pow(2),
        BigInt.from(7) * previousValue * followingValue,
      ];
      var valueTotal = BigInt.zero;
      for (final term in valueTerms) {
        valueTotal += term;
      }
      final value = _referenceNormalize(valueTotal);
      next[bowlId - 1] = value;
      updates.add(
        _ReferenceStirUpdate(
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
      _ReferenceStirStage(
        step: step,
        savedSum: savedSum,
        permutationRank: rank,
        order: order,
        before: before,
        updates: List<_ReferenceStirUpdate>.unmodifiable(updates),
        after: after,
      ),
    );
    bowls = next;
  }

  return _ReferenceBowlResult(
    initial: List<BigInt>.unmodifiable(initial),
    dropStages: List<_ReferenceDropStage>.unmodifiable(dropStages),
    orderAt46: savedOrderAt46,
    afterDrops: afterDrops,
    postStirs: List<_ReferenceStirStage>.unmodifiable(postStirs),
    finalBowls: List<BigInt>.unmodifiable(bowls),
  );
}

void _compareBowlResult(
  MonsterBowlResult actual,
  _ReferenceBowlResult expected, {
  MonsterBowlResult? repeated,
}) {
  _check(
      _sameBigInts(actual.initial, expected.initial), 'Initial bowls oracle');
  _check(actual.dropStages.length == 46, 'Exactly 46 drop stages');
  _check(expected.dropStages.length == 46, 'Oracle has 46 drop stages');
  _check(actual.postStirs.length == 12, 'Exactly twelve post-stirs');
  _check(expected.postStirs.length == 12, 'Oracle has twelve post-stirs');
  _check(_sameInts(actual.orderAt46, expected.orderAt46), 'orderAt46 oracle');
  _check(
    _sameInts(actual.orderAt46, actual.dropStages.last.order),
    'Saved orderAt46 remains the 46th drop order',
  );
  _check(
    _sameBigInts(actual.afterDrops, expected.afterDrops),
    'Bowl state after 46 drops',
  );
  _check(
    _sameBigInts(actual.finalBowls, expected.finalBowls),
    'Final bowls oracle',
  );
  if (repeated != null) {
    _check(
      _sameBigInts(actual.finalBowls, repeated.finalBowls),
      'Deterministic bowl replay',
    );
    _check(
      _sameInts(actual.orderAt46, repeated.orderAt46),
      'Deterministic orderAt46 replay',
    );
  }

  for (var bowlIndex = 0; bowlIndex < 6; bowlIndex++) {
    _check(
      actual.initial[bowlIndex] >= BigInt.one &&
          actual.initial[bowlIndex] <= _modulus,
      'Initial bowl normalization',
    );
    _check(
      actual.afterDrops[bowlIndex] >= BigInt.one &&
          actual.afterDrops[bowlIndex] <= _modulus,
      'Post-drop bowl normalization',
    );
    _check(
      actual.finalBowls[bowlIndex] >= BigInt.one &&
          actual.finalBowls[bowlIndex] <= _modulus,
      'Final bowl normalization',
    );
  }

  for (var stageIndex = 0; stageIndex < 46; stageIndex++) {
    final stage = actual.dropStages[stageIndex];
    final oracle = expected.dropStages[stageIndex];
    _check(stage.dropIndex == stageIndex + 1, 'Drop-stage order');
    _check(stage.dropIndex == oracle.dropIndex, 'Oracle drop index');
    _check(stage.dropValue == oracle.dropValue, 'Oracle visible drop');
    _check(stage.permutationRank == oracle.permutationRank, 'Drop rank oracle');
    _check(_sameInts(stage.order, oracle.order), 'Drop permutation oracle');
    _check(_sameBigInts(stage.before, oracle.before), 'Drop snapshot oracle');
    _check(
      _sameBigInts(stage.directPours, oracle.directPours),
      'Direct-pour vector oracle',
    );
    _check(_sameBigInts(stage.after, oracle.after), 'Drop after-state oracle');
    _check(stage.updates.length == 6, 'Six updates per visible drop');
    _check(
        _sameInts(
            stage.order.toSet().toList()..sort(), <int>[1, 2, 3, 4, 5, 6]),
        'Drop order is a permutation');

    for (var positionIndex = 0; positionIndex < 6; positionIndex++) {
      final update = stage.updates[positionIndex];
      final referenceUpdate = oracle.updates[positionIndex];
      _check(update.position == positionIndex + 1, 'Drop update position');
      _check(update.position == referenceUpdate.position,
          'Oracle update position');
      _check(
          update.bowlId == stage.order[positionIndex], 'Fixed bowl identity');
      _check(update.bowlId == referenceUpdate.bowlId, 'Oracle bowl identity');
      _check(
        update.previousBowlId == referenceUpdate.previousBowlId,
        'Previous bowl identity',
      );
      _check(
        update.followingBowlId == referenceUpdate.followingBowlId,
        'Following bowl identity',
      );
      _check(update.oldValue == referenceUpdate.oldValue, 'Old bowl value');
      _check(
        update.directPour == referenceUpdate.directPour,
        'Direct-pour oracle',
      );
      _check(
          update.stoneIndex == referenceUpdate.stoneIndex, 'Stone lane index');
      _check(update.stone == referenceUpdate.stone, 'Stone lane value');
      _check(update.u == referenceUpdate.u, 'Drop mixing intermediate');
      _check(update.value == referenceUpdate.value, 'Drop bowl value');
      _check(
        stage.after[update.bowlId - 1] == update.value,
        'Drop assignment by fixed identity',
      );
      if (positionIndex >= 3) {
        _check(update.directPour == BigInt.zero,
            'No direct pour in positions 4–6');
      } else {
        _check(
          update.directPour >= BigInt.one && update.directPour <= _modulus,
          'Direct-pour normalization',
        );
      }
      _check(
        update.value >= BigInt.one && update.value <= _modulus,
        'Drop bowl normalization',
      );
    }
  }

  for (var stirIndex = 0; stirIndex < 12; stirIndex++) {
    final stir = actual.postStirs[stirIndex];
    final oracle = expected.postStirs[stirIndex];
    _check(stir.step == stirIndex + 1, 'Post-stir sequence');
    _check(stir.step == oracle.step, 'Oracle post-stir number');
    _check(stir.savedSum == oracle.savedSum, 'Canonical saved sum oracle');
    _check(
      stir.savedSum >= BigInt.one && stir.savedSum <= _modulus,
      'Saved sum normalization',
    );
    _check(
      stir.permutationRank == oracle.permutationRank,
      'Post-stir permutation rank',
    );
    _check(_sameInts(stir.order, oracle.order), 'Post-stir order oracle');
    _check(
        _sameBigInts(stir.before, oracle.before), 'Post-stir snapshot oracle');
    _check(
        _sameBigInts(stir.after, oracle.after), 'Post-stir after-state oracle');
    _check(stir.updates.length == 6, 'Six updates per post-stir');
    _check(
        _sameInts(stir.order.toSet().toList()..sort(), <int>[1, 2, 3, 4, 5, 6]),
        'Post-stir order is a permutation');

    for (var positionIndex = 0; positionIndex < 6; positionIndex++) {
      final update = stir.updates[positionIndex];
      final referenceUpdate = oracle.updates[positionIndex];
      _check(update.position == positionIndex + 1, 'Post-stir position');
      _check(
          update.position == referenceUpdate.position, 'Oracle stir position');
      _check(update.bowlId == stir.order[positionIndex],
          'Post-stir bowl identity');
      _check(
          update.bowlId == referenceUpdate.bowlId, 'Oracle stir bowl identity');
      _check(
        update.previousBowlId == referenceUpdate.previousBowlId,
        'Post-stir previous bowl',
      );
      _check(
        update.followingBowlId == referenceUpdate.followingBowlId,
        'Post-stir following bowl',
      );
      _check(
          update.oldValue == referenceUpdate.oldValue, 'Post-stir old value');
      _check(update.u == referenceUpdate.u, 'Post-stir intermediate');
      _check(update.value == referenceUpdate.value, 'Post-stir bowl value');
      _check(
        stir.after[update.bowlId - 1] == update.value,
        'Post-stir assignment by fixed identity',
      );
      _check(
        update.value >= BigInt.one && update.value <= _modulus,
        'Post-stir normalization',
      );
    }
  }
}

void main() {
  final feeder = const MonsterSeedFeeder();
  final counter = const MonsterWorkCounter();
  final visibleGenerator = const MonsterVisibleDropGenerator();
  final processor = const MonsterBowlProcessor();
  final stones = feeder.buildStones();
  final referenceStones = stones
      .map(
        (stone) => <BigInt>[
          for (var lane = 0; lane < 5; lane++) stone.lane(lane),
        ],
      )
      .toList(growable: false);

  _check(_referencePermutations.length == 720, '720 reference permutations');
  _check(
    _sameInts(_referencePermutations.first, <int>[1, 2, 3, 4, 5, 6]),
    'First lexicographic permutation',
  );
  _check(
    _sameInts(_referencePermutations.last, <int>[6, 5, 4, 3, 2, 1]),
    'Last lexicographic permutation',
  );
  _check(MonsterBowlProcessor.bowlCount == 6, 'Six fixed bowls');
  _check(MonsterBowlProcessor.visibleDropCount == 46, '46 visible drops');
  _check(MonsterBowlProcessor.postStirCount == 12, 'Twelve post-stirs');

  const offsets = <int>[-12, -2, -1, 0, 1, 2, 12];
  final foundation = MonsterWorkCounter.foundationDay;
  var feedCases = 0;
  var dropUpdates = 0;
  var postStirUpdates = 0;
  List<MonsterVisibleDrop>? firstDrops;
  List<BigInt>? firstDropSnapshot;
  MonsterBowlResult? firstResult;
  MonsterWorkCounts? firstCounts;

  for (final actionOffset in offsets) {
    for (final targetOffset in offsets) {
      final counts = counter.calculate(
        foundation + BigInt.from(actionOffset),
        foundation + BigInt.from(targetOffset),
      );
      final feeds = feeder.buildHiddenFeeds(counts, stones);
      final drops = visibleGenerator.buildVisibleDrops(
        counts: counts,
        hiddenFeeds: feeds,
        stones: stones,
      );
      if (firstDrops == null) {
        firstDrops = drops;
        firstDropSnapshot = drops.map((drop) => drop.value).toList();
        firstCounts = counts;
      }

      final actual = processor.process(
        counts: counts,
        visibleDrops: drops,
        stones: stones,
      );
      final expected = _referenceBowlProcess(counts, referenceStones, drops);
      final repeated = processor.process(
        counts: counts,
        visibleDrops: drops,
        stones: stones,
      );
      _compareBowlResult(actual, expected, repeated: repeated);

      if (firstResult == null) {
        firstResult = actual;
      }
      feedCases++;
      dropUpdates += actual.dropStages.length * 6;
      postStirUpdates += actual.postStirs.length * 6;
    }
  }

  final foundationCounts = counter.calculate(foundation, foundation);
  final foundationFeeds = feeder.buildHiddenFeeds(foundationCounts, stones);
  final foundationDrops = visibleGenerator.buildVisibleDrops(
    counts: foundationCounts,
    hiddenFeeds: foundationFeeds,
    stones: stones,
  );
  final foundationResult = processor.process(
    counts: foundationCounts,
    visibleDrops: foundationDrops,
    stones: stones,
  );
  _check(
    _sameInts(foundationResult.orderAt46, <int>[4, 5, 2, 3, 6, 1]),
    'Canonical orderAt46 checkpoint',
  );
  const expectedFinalBowls = <String>[
    '65286679584284972964194865805379907599',
    '127720283375330263615328810127751035299',
    '54364069496183805843611594721403108554',
    '93072329024469476118876155742008280619',
    '54867842942953573450868747713087920246',
    '111207247632761530752404582123499651367',
  ];
  for (var bowlIndex = 0; bowlIndex < 6; bowlIndex++) {
    _check(
      foundationResult.finalBowls[bowlIndex] ==
          BigInt.parse(expectedFinalBowls[bowlIndex]),
      'Canonical final bowl checkpoint',
    );
  }

  final wide = (BigInt.one << 127) + BigInt.from(19);
  final wideCounts = counter.calculate(foundation - wide, foundation + wide);
  final wideFeeds = feeder.buildHiddenFeeds(wideCounts, stones);
  final wideDrops = visibleGenerator.buildVisibleDrops(
    counts: wideCounts,
    hiddenFeeds: wideFeeds,
    stones: stones,
  );
  final wideActual = processor.process(
    counts: wideCounts,
    visibleDrops: wideDrops,
    stones: stones,
  );
  final wideExpected = _referenceBowlProcess(
    wideCounts,
    referenceStones,
    wideDrops,
  );
  _compareBowlResult(wideActual, wideExpected);

  final validDrops = firstDrops!;
  final dropSnapshot = firstDropSnapshot!;
  final validCounts = firstCounts!;
  final validResult = firstResult!;
  _expectArgumentError(
    () => processor.process(
      counts: validCounts,
      visibleDrops: validDrops.take(45).toList(),
      stones: stones,
    ),
    'Reject 45 visible drops',
  );
  _expectArgumentError(
    () => processor.process(
      counts: validCounts,
      visibleDrops: validDrops.reversed.toList(),
      stones: stones,
    ),
    'Reject reordered visible drops',
  );
  _expectArgumentError(
    () => processor.process(
      counts: validCounts,
      visibleDrops: validDrops,
      stones: stones.take(45).toList(),
    ),
    'Reject incomplete stone table',
  );
  _expectArgumentError(
    () => processor.process(
      counts: MonsterWorkCounts(
        action: BigInt.zero,
        target: BigInt.one,
        distance: BigInt.one,
        connection: BigInt.one,
        direction: 2,
      ),
      visibleDrops: validDrops,
      stones: stones,
    ),
    'Reject invalid work counts',
  );

  _expectImmutable(
    () {
      validResult.initial.add(BigInt.one);
    },
    'Initial bowl vector immutable',
  );
  _expectImmutable(
    () {
      validResult.dropStages.add(validResult.dropStages.first);
    },
    'Drop stages immutable',
  );
  _expectImmutable(
    () {
      validResult.dropStages.first.order.add(1);
    },
    'Drop order immutable',
  );
  _expectImmutable(
    () {
      validResult.dropStages.first.updates.add(
        validResult.dropStages.first.updates.first,
      );
    },
    'Drop updates immutable',
  );
  _expectImmutable(
    () {
      validResult.orderAt46.add(1);
    },
    'Saved orderAt46 immutable',
  );
  _expectImmutable(
    () {
      validResult.postStirs.add(validResult.postStirs.first);
    },
    'Post-stir stages immutable',
  );
  _expectImmutable(
    () {
      validResult.finalBowls.add(BigInt.one);
    },
    'Final bowl vector immutable',
  );

  for (var index = 0; index < validDrops.length; index++) {
    _check(validDrops[index].value == dropSnapshot[index],
        'Visible-drop input preserved');
  }
  for (var stoneIndex = 0; stoneIndex < stones.length; stoneIndex++) {
    for (var lane = 0; lane < 5; lane++) {
      _check(
        stones[stoneIndex].lane(lane) == referenceStones[stoneIndex][lane],
        'Stone table input preserved',
      );
    }
  }

  _check(feedCases == 49, 'Exactly 49 input cases');
  _check(dropUpdates == 13524, 'Exactly 13524 visible-drop bowl updates');
  _check(postStirUpdates == 3528, 'Exactly 3528 post-stir bowl updates');
  _check(_checks >= 100000, 'Minimum 100000 real assertions');
  stdout.writeln(
    'PRODUCTION05_BOWLS_PASS; checks=$_checks; '
    'feed_cases=$feedCases; drop_updates=$dropUpdates; '
    'post_stir_updates=$postStirUpdates; visible_drops=46; '
    'post_stirs=12; order_at_46=4,5,2,3,6,1; '
    'five_component_calendar_ready=false',
  );
}
