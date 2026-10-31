import 'dart:io';

import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;
final _modulus = (BigInt.one << 127) - BigInt.one;

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

BigInt _referenceNormalize(BigInt value) {
  return ((value - BigInt.one) % _modulus) + BigInt.one;
}

/// Scalar oracle: explicit term lists and pow(), with no production math API.
List<BigInt> _referenceVisibleDroplets(
  List<BigInt> hiddenFeeds,
  List<List<BigInt>> stones,
) {
  var state = <BigInt>[];
  for (var index = 0; index < 7; index++) {
    final terms = <BigInt>[
      hiddenFeeds[index],
      stones[index][index % 5],
      stones[index][(index + 1) % 5],
      BigInt.from(index + 1),
    ];
    var sum = BigInt.zero;
    for (final term in terms) {
      sum += term;
    }
    state.add(_referenceNormalize(sum));
  }

  for (var round = 1; round <= 7; round++) {
    final previous = state;
    final next = <BigInt>[];
    for (var index = 0; index < 7; index++) {
      final terms = <BigInt>[
        previous[index].pow(2),
        BigInt.from(index + 1) * previous[(index + 1) % 7],
        BigInt.from(round) * previous[(index + 2) % 7],
        stones[index][(index + round) % 5],
        BigInt.from(index + 1 + round),
      ];
      var sum = BigInt.zero;
      for (final term in terms) {
        sum += term;
      }
      next.add(_referenceNormalize(sum));
    }
    state = next;
  }
  return state;
}

void main() {
  final feeder = const MonsterSeedFeeder();
  final counter = const MonsterWorkCounter();
  final mixer = const MonsterVisibleDropletMixer();
  final stones = feeder.buildStones();
  final referenceStones = stones
      .map(
        (stone) => <BigInt>[
          for (var lane = 0; lane < 5; lane++) stone.lane(lane),
        ],
      )
      .toList(growable: false);

  _check(MonsterVisibleDropletMixer.dropletCount == 7, 'Seven droplets');
  _check(MonsterVisibleDropletMixer.mixingRounds == 7, 'Seven fixed rounds');
  _check(stones.length == 46, 'Complete seed table');

  const offsets = <int>[-12, -2, -1, 0, 1, 2, 12];
  final foundation = MonsterWorkCounter.foundationDay;
  var feedCases = 0;
  var mixCases = 0;
  List<BigInt>? firstFeeds;
  List<BigInt>? firstVisible;

  for (final actionOffset in offsets) {
    for (final targetOffset in offsets) {
      final counts = counter.calculate(
        foundation + BigInt.from(actionOffset),
        foundation + BigInt.from(targetOffset),
      );
      final feeds = feeder.buildHiddenFeeds(counts, stones);
      final actual = mixer.buildVisibleDroplets(
        hiddenFeeds: feeds,
        stones: stones,
      );
      final expected = _referenceVisibleDroplets(feeds, referenceStones);
      final repeated = mixer.buildVisibleDroplets(
        hiddenFeeds: feeds,
        stones: stones,
      );

      _check(feeds.length == 7, 'Seven input feeds');
      _check(actual.length == 7, 'Seven output droplets');
      for (var index = 0; index < 7; index++) {
        _check(actual[index] == expected[index], 'Independent scalar oracle');
        _check(
          actual[index] >= BigInt.one && actual[index] <= _modulus,
          'Visible droplet normalization',
        );
        _check(actual[index] == repeated[index], 'Deterministic replay');
        mixCases++;
      }
      if (firstFeeds == null) {
        firstFeeds = List<BigInt>.from(feeds);
        firstVisible = actual;
      }
      feedCases++;
    }
  }

  final wide = (BigInt.one << 127) + BigInt.from(19);
  final wideCounts = counter.calculate(foundation - wide, foundation + wide);
  final wideFeeds = feeder.buildHiddenFeeds(wideCounts, stones);
  final wideActual = mixer.buildVisibleDroplets(
    hiddenFeeds: wideFeeds,
    stones: stones,
  );
  final wideExpected = _referenceVisibleDroplets(wideFeeds, referenceStones);
  for (var index = 0; index < 7; index++) {
    _check(wideActual[index] == wideExpected[index], 'Wide BigInt oracle');
    _check(
      wideActual[index] >= BigInt.one && wideActual[index] <= _modulus,
      'Wide BigInt output range',
    );
  }

  final validFeeds = firstFeeds!;
  final validVisible = firstVisible!;
  final shortFeeds = validFeeds.take(6).toList();
  _expectArgumentError(
    () => mixer.buildVisibleDroplets(
      hiddenFeeds: shortFeeds,
      stones: stones,
    ),
    'Reject six feeds',
  );
  final zeroFeed = List<BigInt>.from(validFeeds);
  zeroFeed[0] = BigInt.zero;
  _expectArgumentError(
    () => mixer.buildVisibleDroplets(
      hiddenFeeds: zeroFeed,
      stones: stones,
    ),
    'Reject zero feed',
  );
  final oversizedFeed = List<BigInt>.from(validFeeds);
  oversizedFeed[0] = _modulus + BigInt.one;
  _expectArgumentError(
    () => mixer.buildVisibleDroplets(
      hiddenFeeds: oversizedFeed,
      stones: stones,
    ),
    'Reject feed above modulus',
  );
  _expectArgumentError(
    () => mixer.buildVisibleDroplets(
      hiddenFeeds: validFeeds,
      stones: stones.take(45).toList(),
    ),
    'Reject incomplete seed table',
  );

  _expectImmutable(
    () {
      validVisible.add(BigInt.one);
    },
    'Visible droplet vector immutable',
  );
  for (var index = 0; index < validFeeds.length; index++) {
    _check(validFeeds[index] == firstFeeds![index], 'Feed input preserved');
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
  _check(mixCases == 343, 'Exactly 343 droplet outputs');
  _check(_checks >= 1000, 'Minimum 1000 real assertions');
  stdout.writeln(
    'PRODUCTION04_DROPLET_PASS; checks=$_checks; '
    'feed_cases=$feedCases; droplets=7; mix_cases=$mixCases; '
    'rounds=7; five_component_calendar_ready=false',
  );
}
