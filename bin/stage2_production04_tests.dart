import 'dart:io';

import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;
final _modulus = (BigInt.one << 127) - BigInt.one;
const _referenceGrindRows = <List<int>>[
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

void _check(bool condition, String label) {
  _checks++;
  if (!condition) {
    throw StateError('PRODUCTION04_CHECK_FAILED: $label');
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

BigInt _referenceNormalize(BigInt value) {
  return ((value - BigInt.one) % _modulus) + BigInt.one;
}

final class _ReferenceDropStep {
  final int number;
  final BigInt before;
  final List<int> coefficients;
  final BigInt stone;
  final BigInt after;

  const _ReferenceDropStep({
    required this.number,
    required this.before,
    required this.coefficients,
    required this.stone,
    required this.after,
  });
}

final class _ReferenceDrop {
  final int index;
  final BigInt dough;
  final List<BigInt> dependencies;
  final List<_ReferenceDropStep> steps;
  final BigInt value;

  const _ReferenceDrop({
    required this.index,
    required this.dough,
    required this.dependencies,
    required this.steps,
    required this.value,
  });
}

/// Independent scalar oracle for the seven hidden drops.
List<BigInt> _referenceHiddenFeeds(
  MonsterWorkCounts counts,
  List<List<BigInt>> stones,
) {
  final output = <BigInt>[];
  for (var k = 1; k <= 7; k++) {
    final stone = stones[k - 1];
    final terms = <BigInt>[
      counts.action,
      BigInt.from(2 * k + 1) * counts.target,
      BigInt.from(3 * k + 1) * counts.distance,
      BigInt.from(4 * k + 2) * counts.connection,
      BigInt.from(4 * k + 4) * BigInt.from(counts.direction),
      ...stone,
    ];
    var total = BigInt.zero;
    for (final term in terms) {
      total += term;
    }
    var state = _referenceNormalize(total);
    const stoneOrder = <int>[0, 1, 2, 3, 4, 0, 1];
    for (var grind = 1; grind <= 7; grind++) {
      final before = state;
      final grindTerms = <BigInt>[
        before.pow(2),
        BigInt.from(3) * before,
        stone[stoneOrder[grind - 1]],
        BigInt.from(grind),
      ];
      var grindTotal = BigInt.zero;
      for (final term in grindTerms) {
        grindTotal += term;
      }
      state = _referenceNormalize(grindTotal);
    }
    output.add(state);
  }
  return output;
}

/// Independent scalar oracle: explicit term lists, linear accumulation and pow().
List<_ReferenceDrop> _referenceVisibleDrops(
  MonsterWorkCounts counts,
  List<BigInt> hiddenFeeds,
  List<List<BigInt>> stones,
) {
  final output = <_ReferenceDrop>[];

  BigInt dropAt(int position) {
    if (position >= 1) {
      return output[position - 1].value;
    }
    return hiddenFeeds[-position];
  }

  for (var index = 1; index <= 46; index++) {
    final stone = stones[index - 1];
    final dependencies = <BigInt>[
      dropAt(index - 1),
      dropAt(index - 3),
      dropAt(index - 7),
    ];
    final doughTerms = <BigInt>[
      stone[0] * counts.action,
      stone[1] * counts.target,
      stone[2] * counts.distance,
      stone[3] * counts.connection,
      stone[4] * BigInt.from(counts.direction),
      dependencies[0],
      BigInt.from(3) * dependencies[1],
      BigInt.from(5) * dependencies[2],
      BigInt.from(index),
    ];
    var doughTotal = BigInt.zero;
    for (final term in doughTerms) {
      doughTotal += term;
    }
    final dough = _referenceNormalize(doughTotal);
    var state = dough;
    final steps = <_ReferenceDropStep>[];

    for (var round = 1; round <= 11; round++) {
      final coefficients = _referenceGrindRows[round - 1];
      final before = state;
      final stoneValue = stone[coefficients[4]];
      final grindTerms = <BigInt>[
        before.pow(2),
        BigInt.from(coefficients[0]) * before,
        BigInt.from(coefficients[1]) * dependencies[0],
        BigInt.from(coefficients[2]) * dependencies[1],
        BigInt.from(coefficients[3]) * dependencies[2],
        stoneValue,
      ];
      var grindTotal = BigInt.zero;
      for (final term in grindTerms) {
        grindTotal += term;
      }
      state = _referenceNormalize(grindTotal);
      steps.add(
        _ReferenceDropStep(
          number: round,
          before: before,
          coefficients: List<int>.unmodifiable(coefficients),
          stone: stoneValue,
          after: state,
        ),
      );
    }

    output.add(
      _ReferenceDrop(
        index: index,
        dough: dough,
        dependencies: List<BigInt>.unmodifiable(dependencies),
        steps: List<_ReferenceDropStep>.unmodifiable(steps),
        value: state,
      ),
    );
  }
  return output;
}

void _compareVisibleDrops(
  List<MonsterVisibleDrop> actual,
  List<_ReferenceDrop> expected, {
  List<MonsterVisibleDrop>? repeated,
}) {
  _check(actual.length == 46, 'Exactly 46 visible drops');
  _check(expected.length == 46, 'Independent oracle has 46 drops');
  if (repeated != null) {
    _check(repeated.length == 46, 'Deterministic replay length');
  }

  for (var dropIndex = 0; dropIndex < 46; dropIndex++) {
    final drop = actual[dropIndex];
    final oracle = expected[dropIndex];
    _check(drop.index == dropIndex + 1, 'Visible-drop order');
    _check(drop.index == oracle.index, 'Independent drop index');
    _check(drop.dough == oracle.dough, 'Independent dough oracle');
    _check(drop.dependencies.length == 3, 'Three visible-drop dependencies');
    _check(drop.steps.length == 11, 'Eleven grinds per visible drop');
    _check(drop.value == oracle.value, 'Independent final drop oracle');
    _check(
      drop.dough >= BigInt.one && drop.dough <= _modulus,
      'Dough normalization',
    );
    _check(
      drop.value >= BigInt.one && drop.value <= _modulus,
      'Visible-drop normalization',
    );
    _check(drop.value == drop.steps.last.after, 'Final grind is drop value');
    if (repeated != null) {
      _check(
        drop.value == repeated[dropIndex].value,
        'Deterministic visible-drop replay',
      );
    }

    for (var dependencyIndex = 0; dependencyIndex < 3; dependencyIndex++) {
      _check(
        drop.dependencies[dependencyIndex] ==
            oracle.dependencies[dependencyIndex],
        'Independent dependency oracle',
      );
      _check(
        drop.dependencies[dependencyIndex] >= BigInt.one &&
            drop.dependencies[dependencyIndex] <= _modulus,
        'Dependency normalization',
      );
    }

    for (var stepIndex = 0; stepIndex < 11; stepIndex++) {
      final step = drop.steps[stepIndex];
      final referenceStep = oracle.steps[stepIndex];
      _check(step.number == stepIndex + 1, 'Grind sequence');
      _check(step.number == referenceStep.number, 'Oracle grind number');
      _check(step.before == referenceStep.before, 'Oracle prior grind value');
      _check(
        _sameInts(step.coefficients, referenceStep.coefficients),
        'Oracle coefficient row',
      );
      _check(step.stone == referenceStep.stone, 'Oracle grind stone');
      _check(step.after == referenceStep.after, 'Oracle grind output');
      _check(
        step.before >= BigInt.one && step.before <= _modulus,
        'Grind input normalization',
      );
      _check(
        step.stone >= BigInt.one && step.stone <= _modulus,
        'Grind stone normalization',
      );
      _check(
        step.after >= BigInt.one && step.after <= _modulus,
        'Grind output normalization',
      );
      if (stepIndex == 0) {
        _check(step.before == drop.dough, 'First grind starts at dough');
      } else {
        _check(
          step.before == drop.steps[stepIndex - 1].after,
          'Grinds are sequential within one drop',
        );
      }
    }
  }
}

void main() {
  final feeder = const MonsterSeedFeeder();
  final counter = const MonsterWorkCounter();
  final generator = const MonsterVisibleDropGenerator();
  final stones = feeder.buildStones();
  final referenceStones = stones
      .map(
        (stone) => <BigInt>[
          for (var lane = 0; lane < 5; lane++) stone.lane(lane),
        ],
      )
      .toList(growable: false);

  _check(
      MonsterVisibleDropGenerator.visibleDropCount == 46, '46 visible drops');
  _check(
      MonsterVisibleDropGenerator.hiddenFeedCount == 7, 'Seven hidden drops');
  _check(
      MonsterVisibleDropGenerator.grindsPerDrop == 11, 'Eleven fixed grinds');
  _check(stones.length == 46, 'Complete 46-stone table');

  const offsets = <int>[-12, -2, -1, 0, 1, 2, 12];
  final foundation = MonsterWorkCounter.foundationDay;
  var feedCases = 0;
  var dropCases = 0;
  var grindSteps = 0;
  List<BigInt>? firstFeeds;
  List<BigInt>? firstFeedSnapshot;
  List<MonsterVisibleDrop>? firstVisible;

  for (final actionOffset in offsets) {
    for (final targetOffset in offsets) {
      final counts = counter.calculate(
        foundation + BigInt.from(actionOffset),
        foundation + BigInt.from(targetOffset),
      );
      final feeds = feeder.buildHiddenFeeds(counts, stones);
      final oracleFeeds = _referenceHiddenFeeds(counts, referenceStones);
      _check(feeds.length == 7, 'Seven production hidden drops');
      for (var index = 0; index < 7; index++) {
        _check(feeds[index] == oracleFeeds[index],
            'Independent hidden-drop oracle');
        _check(
          feeds[index] >= BigInt.one && feeds[index] <= _modulus,
          'Hidden-drop normalization',
        );
      }

      if (firstFeeds == null) {
        firstFeeds = feeds;
        firstFeedSnapshot = List<BigInt>.from(feeds);
      }

      final actual = generator.buildVisibleDrops(
        counts: counts,
        hiddenFeeds: feeds,
        stones: stones,
      );
      final expected = _referenceVisibleDrops(
        counts,
        oracleFeeds,
        referenceStones,
      );
      final repeated = generator.buildVisibleDrops(
        counts: counts,
        hiddenFeeds: feeds,
        stones: stones,
      );
      _compareVisibleDrops(actual, expected, repeated: repeated);

      if (firstVisible == null) {
        firstVisible = actual;
      }
      feedCases++;
      dropCases += actual.length;
      grindSteps += actual.length * MonsterVisibleDropGenerator.grindsPerDrop;
    }
  }

  final foundationCounts = counter.calculate(foundation, foundation);
  _check(foundationCounts.action == BigInt.one, 'Foundation action count');
  _check(foundationCounts.target == BigInt.one, 'Foundation target count');
  _check(foundationCounts.distance == BigInt.one, 'Foundation distance count');
  _check(foundationCounts.connection == BigInt.from(2), 'Foundation sum count');
  _check(foundationCounts.direction == 2, 'Foundation direction count');

  final foundationFeeds = feeder.buildHiddenFeeds(foundationCounts, stones);
  const expectedHidden = <String>[
    '119390830530032782664128530203002080344',
    '11877236279154673426874867061566696749',
    '24217814924229232987463457533828175476',
    '166629231917547214614573522551290204247',
    '81202913407267092008896220686064041568',
    '73551520026920072430116213847585486272',
    '6164285870955721082771365327359496898',
  ];
  for (var index = 0; index < 7; index++) {
    _check(
      foundationFeeds[index] == BigInt.parse(expectedHidden[index]),
      'Canonical hidden-drop checkpoint',
    );
  }
  final foundationVisible = generator.buildVisibleDrops(
    counts: foundationCounts,
    hiddenFeeds: foundationFeeds,
    stones: stones,
  );
  _check(
    foundationVisible.first.value ==
        BigInt.parse('56644603826892212324764499696091907135'),
    'Canonical visible drop 1 checkpoint',
  );
  _check(
    foundationVisible.last.value ==
        BigInt.parse('141872771689426650819909896585756512282'),
    'Canonical visible drop 46 checkpoint',
  );

  final wide = (BigInt.one << 127) + BigInt.from(19);
  final wideCounts = counter.calculate(foundation - wide, foundation + wide);
  final wideFeeds = feeder.buildHiddenFeeds(wideCounts, stones);
  final wideOracleFeeds = _referenceHiddenFeeds(wideCounts, referenceStones);
  for (var index = 0; index < 7; index++) {
    _check(
        wideFeeds[index] == wideOracleFeeds[index], 'Wide hidden-drop oracle');
  }
  final wideActual = generator.buildVisibleDrops(
    counts: wideCounts,
    hiddenFeeds: wideFeeds,
    stones: stones,
  );
  final wideExpected = _referenceVisibleDrops(
    wideCounts,
    wideOracleFeeds,
    referenceStones,
  );
  _compareVisibleDrops(wideActual, wideExpected);

  final validFeeds = firstFeeds!;
  final feedSnapshot = firstFeedSnapshot!;
  final validVisible = firstVisible!;
  _expectArgumentError(
    () => generator.buildVisibleDrops(
      counts: foundationCounts,
      hiddenFeeds: validFeeds.take(6).toList(),
      stones: stones,
    ),
    'Reject six hidden drops',
  );
  final zeroFeed = List<BigInt>.from(validFeeds);
  zeroFeed[0] = BigInt.zero;
  _expectArgumentError(
    () => generator.buildVisibleDrops(
      counts: foundationCounts,
      hiddenFeeds: zeroFeed,
      stones: stones,
    ),
    'Reject zero hidden drop',
  );
  final oversizedFeed = List<BigInt>.from(validFeeds);
  oversizedFeed[0] = _modulus + BigInt.one;
  _expectArgumentError(
    () => generator.buildVisibleDrops(
      counts: foundationCounts,
      hiddenFeeds: oversizedFeed,
      stones: stones,
    ),
    'Reject hidden drop above modulus',
  );
  _expectArgumentError(
    () => generator.buildVisibleDrops(
      counts: foundationCounts,
      hiddenFeeds: validFeeds,
      stones: stones.take(45).toList(),
    ),
    'Reject incomplete stone table',
  );
  _expectArgumentError(
    () => generator.buildVisibleDrops(
      counts: MonsterWorkCounts(
        action: BigInt.zero,
        target: BigInt.one,
        distance: BigInt.one,
        connection: BigInt.one,
        direction: 2,
      ),
      hiddenFeeds: validFeeds,
      stones: stones,
    ),
    'Reject invalid work counts',
  );
  _expectArgumentError(
    () => generator.buildVisibleDrops(
      counts: MonsterWorkCounts(
        action: BigInt.one,
        target: BigInt.one,
        distance: BigInt.one,
        connection: BigInt.from(2),
        direction: 4,
      ),
      hiddenFeeds: validFeeds,
      stones: stones,
    ),
    'Reject invalid direction',
  );

  _expectImmutable(
    () {
      validVisible.add(validVisible.first);
    },
    'Visible-drop list immutable',
  );
  _expectImmutable(
    () {
      validVisible.first.dependencies.add(BigInt.one);
    },
    'Visible-drop dependencies immutable',
  );
  _expectImmutable(
    () {
      validVisible.first.steps.add(validVisible.first.steps.first);
    },
    'Visible-drop grind trace immutable',
  );
  _expectImmutable(
    () {
      validVisible.first.steps.first.coefficients.add(0);
    },
    'Grind coefficients immutable',
  );

  for (var index = 0; index < validFeeds.length; index++) {
    _check(validFeeds[index] == feedSnapshot[index], 'Hidden input preserved');
  }
  for (var stoneIndex = 0; stoneIndex < stones.length; stoneIndex++) {
    for (var lane = 0; lane < 5; lane++) {
      _check(
        stones[stoneIndex].lane(lane) == referenceStones[stoneIndex][lane],
        'Seed table input preserved',
      );
    }
  }

  _check(feedCases == 49, 'Exactly 49 feed cases');
  _check(dropCases == 2254, 'Exactly 2254 visible-drop cases');
  _check(grindSteps == 24794, 'Exactly 24794 grind steps');
  _check(_checks >= 100000, 'Minimum 100000 real assertions');
  stdout.writeln(
    'PRODUCTION04_VISIBLE_DROPS_PASS; checks=$_checks; '
    'feed_cases=$feedCases; visible_drops=46; drop_cases=$dropCases; '
    'grind_steps=$grindSteps; grinds_per_drop=11; '
    'five_component_calendar_ready=false',
  );
}
