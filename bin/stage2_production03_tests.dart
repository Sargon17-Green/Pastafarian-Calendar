import 'dart:io';

import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;
final _modulus = (BigInt.one << 127) - BigInt.one;

void _check(bool ok, String label) {
  _checks++;
  if (!ok) {
    throw StateError('PRODUCTION03_CHECK_FAILED: $label');
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

/// Independent scalar oracle, without importing any production math class.
BigInt _referenceNormalize(BigInt value) {
  return ((value - BigInt.one) % _modulus) + BigInt.one;
}

List<List<BigInt>> _referenceStones() {
  var wheat = BigInt.from(17);
  var barley = BigInt.from(29);
  var salt = BigInt.from(43);
  var bitter = BigInt.from(71);
  var red = BigInt.from(101);
  final rows = <List<BigInt>>[];
  for (var index = 1; index <= 46; index++) {
    rows.add(<BigInt>[wheat, barley, salt, bitter, red]);
    final nextWheat = _referenceNormalize(
      wheat * wheat + BigInt.from(3) * barley + BigInt.from(index + 1),
    );
    final nextBarley = _referenceNormalize(
      barley * barley + BigInt.from(5) * salt + wheat,
    );
    final nextSalt = _referenceNormalize(
      salt * salt + BigInt.from(7) * bitter + barley,
    );
    final nextBitter = _referenceNormalize(
      bitter * bitter + BigInt.from(11) * red + salt,
    );
    final nextRed = _referenceNormalize(
      red * red + BigInt.from(13) * wheat + bitter,
    );
    wheat = nextWheat;
    barley = nextBarley;
    salt = nextSalt;
    bitter = nextBitter;
    red = nextRed;
  }
  return rows;
}

/// Independent scalar feed oracle with explicit term accumulation and pow.
List<BigInt> _referenceFeeds(
  MonsterWorkCounts counts,
  List<List<BigInt>> stones,
) {
  final result = <BigInt>[];
  for (var k = 1; k <= 7; k++) {
    final lane = stones[k - 1];
    final terms = <BigInt>[
      counts.action,
      BigInt.from(2 * k + 1) * counts.target,
      BigInt.from(3 * k + 1) * counts.distance,
      BigInt.from(4 * k + 2) * counts.connection,
      BigInt.from(4 * k + 4) * BigInt.from(counts.direction),
      ...lane,
    ];
    var accumulator = BigInt.zero;
    for (final term in terms) {
      accumulator += term;
    }
    var state = _referenceNormalize(accumulator);
    for (var grind = 1; grind <= 7; grind++) {
      state = _referenceNormalize(
        state.pow(2) +
            state * BigInt.from(3) +
            lane[(grind - 1) % 5] +
            BigInt.from(grind),
      );
    }
    result.add(state);
  }
  return result;
}

void main() {
  final feeder = const MonsterSeedFeeder();
  final stones = feeder.buildStones();
  final reference = _referenceStones();
  _check(stones.length == 46, 'Exactly 46 stones');
  _check(reference.length == 46, 'Independent oracle length');
  var stoneCases = 0;
  for (var i = 0; i < 46; i++) {
    for (var channel = 0; channel < 5; channel++) {
      final actual = stones[i].lane(channel);
      _check(
        actual >= BigInt.one && actual <= _modulus,
        'Stone normalization',
      );
      _check(actual == reference[i][channel], 'Scalar stone oracle');
      stoneCases++;
    }
  }
  _check(stones.first.lane(0) == BigInt.from(17), 'First seed anchor');
  _check(stones[1].lane(0) == BigInt.from(378), 'Second seed anchor');
  _check(
    stones.last.lane(4) ==
        BigInt.parse('137131922036975206684616468948804344042'),
    'Final seed anchor',
  );
  _expectImmutable(
    () {
      stones.add(stones.first);
    },
    'Seed table immutable',
  );
  _expectImmutable(
    () {
      stones.first.lanes[0] = BigInt.zero;
    },
    'Seed lane immutable',
  );
  _expectArgumentError(
    () {
      stones.first.lane(5);
    },
    'Seed lane bounds',
  );

  final counter = const MonsterWorkCounter();
  final foundation = MonsterWorkCounter.foundationDay;
  const offsets = <int>[-12, -2, -1, 0, 1, 2, 12];
  var feedCases = 0;
  for (final actionOffset in offsets) {
    for (final targetOffset in offsets) {
      final counts = counter.calculate(
        foundation + BigInt.from(actionOffset),
        foundation + BigInt.from(targetOffset),
      );
      final actual = feeder.buildHiddenFeeds(counts, stones);
      final oracle = _referenceFeeds(counts, reference);
      _check(actual.length == 7, 'Seven hidden feeds');
      for (var index = 0; index < 7; index++) {
        _check(actual[index] == oracle[index], 'Independent feed oracle');
        _check(
          actual[index] >= BigInt.one && actual[index] <= _modulus,
          'Feed range',
        );
        _check(
          actual[index] == feeder.buildHiddenFeeds(counts, stones)[index],
          'Deterministic feed replay',
        );
      }
      feedCases++;
    }
  }

  final wide = (BigInt.one << 127) + BigInt.from(19);
  final large = counter.calculate(foundation - wide, foundation + wide);
  final wideFeeds = feeder.buildHiddenFeeds(large, stones);
  final wideOracle = _referenceFeeds(large, reference);
  for (var index = 0; index < 7; index++) {
    _check(wideFeeds[index] == wideOracle[index], 'Wide BigInt feed');
    _check(
      wideFeeds[index] >= BigInt.one && wideFeeds[index] <= _modulus,
      'Wide BigInt interval',
    );
  }
  _expectArgumentError(
    () {
      feeder.buildHiddenFeeds(large, stones.take(45).toList());
    },
    'Reject incomplete seed table',
  );
  _expectArgumentError(
    () {
      feeder.buildHiddenFeeds(
        MonsterWorkCounts(
          action: BigInt.zero,
          target: BigInt.one,
          distance: BigInt.one,
          connection: BigInt.one,
          direction: 2,
        ),
        stones,
      );
    },
    'Reject invalid work counts',
  );
  _expectImmutable(
    () {
      wideFeeds.add(BigInt.one);
    },
    'Feed vector immutable',
  );
  _check(_checks >= 1500, 'Minimum 1500 real assertions');
  stdout.writeln(
    'PRODUCTION03_FEED_PASS; checks=$_checks; stones=46; '
    'stone_cases=$stoneCases; feed_cases=$feedCases; '
    'five_component_calendar_ready=false',
  );
}
