import '../lib/src/monster_meatball_gates.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_locator.dart';

var _checks = 0;
var _compared = 0;
var _complete = 0;
var _incomplete = 0;

void _check(bool condition, String message) {
  _checks++;
  if (!condition) {
    throw StateError('PRODUCTION09_PREVIEW_CHECK_FAILED: $message');
  }
}

void _reject(void Function() action, String message) {
  var rejected = false;
  try {
    action();
  } on ArgumentError {
    rejected = true;
  }
  _check(rejected, message);
}

/// Independent Oracle A: exhaustive pair enumeration followed by stable
/// insertion into a separately ordered list (not production sort).
List<List<BigInt>> _oracle(BigInt day, Map<int, BigInt> positions) {
  final keys = positions.keys.toList()..sort();
  final ordered = <List<BigInt>>[];
  for (final i in keys) {
    for (final j in keys) {
      if (j - i < 6) {
        continue;
      }
      final open = positions[i]!;
      final close = positions[j]!;
      final span = close - open;
      if (open >= day ||
          close < day ||
          span < BigInt.from(252) ||
          span > BigInt.from(5778)) {
        continue;
      }
      final record = <BigInt>[
        BigInt.from(i),
        BigInt.from(j),
        open,
        close,
        span,
      ];
      var insertion = 0;
      while (insertion < ordered.length) {
        final earlier = ordered[insertion];
        if (earlier[4] > span || (earlier[4] == span && earlier[2] > open)) {
          break;
        }
        insertion++;
      }
      ordered.insert(insertion, record);
    }
  }
  return ordered;
}

void _compare(BigInt day, Map<int, BigInt> positions) {
  final result = MonsterYearLocator.fromGateSnapshot(day, positions);
  final expected = _oracle(day, positions);
  _check(result.day == day, 'Day retained');
  _check(result.candidates.length == expected.length, 'Oracle pair count');
  _check(!result.year5000Ready, 'Preview does not select year 5000');
  for (var k = 0; k < expected.length; k++) {
    final actual = result.candidates[k];
    final oracle = expected[k];
    _check(actual.openOrdinal == oracle[0], 'Oracle open ordinal');
    _check(actual.closeOrdinal == oracle[1], 'Oracle close ordinal');
    _check(actual.openGate == oracle[2], 'Oracle open gate');
    _check(actual.closeGate == oracle[3], 'Oracle close gate');
    _check(actual.length == oracle[4], 'Oracle length');
    _check(actual.eligible && actual.contains(day), 'Oracle eligibility');
  }
  final leftSafe = positions[positions.keys.reduce((a, b) => a < b ? a : b)]! <
      day - BigInt.from(5778);
  final rightSafe = positions[positions.keys.reduce((a, b) => a > b ? a : b)]! >
      day + BigInt.from(5777);
  _check(result.complete == (leftSafe && rightSafe), 'Sentinel proof');
  _check(
    result.missingBoundaries.length == (leftSafe ? 0 : 1) + (rightSafe ? 0 : 1),
    'Missing proof directions',
  );
  if (result.complete) {
    _complete++;
    result.requireComplete();
  } else {
    _incomplete++;
    var caught = false;
    try {
      result.requireComplete();
    } on IncompleteMonsterYearDomain {
      caught = true;
    }
    _check(caught, 'Incomplete domain must refuse selection');
  }
  _compared += expected.length;
}

void main() {
  // Synthetic gate maps are not canonical §O, but prove §Q boundaries/ties.
  final synthetic = <int, BigInt>{
    for (var i = -60; i <= 60; i++) i: BigInt.from(i * 100),
  };
  for (final day in <BigInt>[
    BigInt.zero,
    BigInt.one,
    -BigInt.one,
    BigInt.from(100),
    BigInt.from(200),
    BigInt.from(1000),
  ]) {
    _compare(day, synthetic);
  }
  final atZero = MonsterYearLocator.fromGateSnapshot(
    BigInt.zero,
    synthetic,
  );
  _check(atZero.complete, 'Synthetic two-sided sentinel complete');
  _check(atZero.candidates.isNotEmpty, 'Nonempty synthetic candidate set');
  _check(
    atZero.candidates.every((c) => c.openGate < BigInt.zero),
    'Left endpoint is open',
  );
  _check(
    atZero.candidates.any((c) => c.closeGate == BigInt.zero),
    'Right endpoint is closed',
  );
  _check(
    atZero.candidates.first.length == BigInt.from(600),
    'Six 100-day gates are shortest',
  );
  _check(
    atZero.candidates.first.openGate < atZero.candidates[1].openGate,
    'Equal-length years sorted by earlier opening',
  );

  _compare(
    BigInt.zero,
    <int, BigInt>{
      for (var i = -10; i <= 10; i++) i: BigInt.from(i * 100),
    },
  );
  _compare(
    BigInt.zero,
    <int, BigInt>{
      for (var i = -60; i <= 10; i++) i: BigInt.from(i * 100),
    },
  );
  _compare(
    BigInt.zero,
    <int, BigInt>{
      for (var i = -10; i <= 60; i++) i: BigInt.from(i * 100),
    },
  );
  final huge = BigInt.one << 190;
  final shifted = <int, BigInt>{
    for (var i = -60; i <= 60; i++) i: huge + BigInt.from(i * 100),
  };
  _compare(huge, shifted);
  _compare(-huge, <int, BigInt>{
    for (var i = -60; i <= 60; i++) i: -huge + BigInt.from(i * 100),
  });

  _reject(
    () => MonsterYearLocator.fromGateSnapshot(
      BigInt.zero,
      <int, BigInt>{0: BigInt.zero, 2: BigInt.from(100)},
    ),
    'Missing ordinal rejected',
  );
  _reject(
    () => MonsterYearLocator.fromGateSnapshot(
      BigInt.zero,
      <int, BigInt>{0: BigInt.zero, 1: BigInt.zero},
    ),
    'Non-increasing gates rejected',
  );
  _reject(
    () => MonsterYearLocator().boundedPreview(
      BigInt.zero,
      lowerOrdinal: -33,
    ),
    'Lower prefix bound rejected',
  );
  _reject(
    () => MonsterYearLocator().boundedPreview(
      BigInt.zero,
      upperOrdinal: 33,
    ),
    'Upper prefix bound rejected',
  );

  // Actual §O gaps: independently sum signed gaps as Oracle A input.
  final gates = MonsterMeatballGateCalculator();
  final foundation = MonsterWorkCounter.foundationDay;
  final real = <int, BigInt>{0: foundation};
  for (var i = 1; i <= 6; i++) {
    real[i] = real[i - 1]! + gates.gapFor(BigInt.from(i)).length;
    real[-i] = real[-i + 1]! - gates.gapFor(BigInt.from(-i)).length;
  }
  for (final day in <BigInt>[
    foundation,
    foundation + BigInt.one,
    foundation - BigInt.one,
  ]) {
    final preview = MonsterYearLocator(gates: gates).boundedPreview(
      day,
      lowerOrdinal: -6,
      upperOrdinal: 6,
    );
    final expected = _oracle(day, real);
    _check(
      preview.candidates.length == expected.length,
      'Canonical snapshot count',
    );
    for (var k = 0; k < expected.length; k++) {
      final actual = preview.candidates[k];
      _check(actual.openOrdinal == expected[k][0], 'Canonical open');
      _check(actual.closeOrdinal == expected[k][1], 'Canonical close');
      _check(actual.length == expected[k][4], 'Canonical length');
    }
    _check(!preview.year5000Ready, 'Canonical selection unimplemented');
    _check(!preview.complete, 'Six-gate preview remains incomplete');
  }
  _check(_complete >= 5, 'Complete synthetic sentinel cases');
  _check(_incomplete >= 4, 'Explicit incomplete-domain cases');
  _check(_compared > 100, 'Oracle A compared eligible candidates');
  _check(_checks > 300, 'Substantial assertions executed');
  print(
    'PRODUCTION09_PREVIEW_PASS; checks=$_checks; '
    'oracle_candidates=$_compared; synthetic_complete=$_complete; '
    'incomplete=$_incomplete; canonical_preview=bounded; '
    'year5000_ready=false; five_component_calendar_ready=false',
  );
}
