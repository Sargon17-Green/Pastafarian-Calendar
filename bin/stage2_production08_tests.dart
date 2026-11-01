import 'dart:io';

import '../lib/src/monster_meatball_gates.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_eligibility.dart';

var _checks = 0;

void _check(bool condition, String label) {
  _checks++;
  if (!condition) {
    throw StateError('PRODUCTION08_CHECK_FAILED: $label');
  }
}

void _rejectArgument(void Function() operation, String label) {
  var rejected = false;
  try {
    operation();
  } on ArgumentError {
    rejected = true;
  }
  _check(rejected, label);
}

void main() {
  final gates = MonsterMeatballGateCalculator();
  final years = MonsterYearEligibility(gates: gates);
  final foundation = MonsterWorkCounter.foundationDay;
  final gaps = <int, BigInt>{};
  final oraclePositions = <int, BigInt>{0: foundation};

  // Independent §P oracle: sum each accepted §O gap once rather than
  // invoking gatePosition or the production year eligibility code.
  for (var ordinal = -32; ordinal <= 32; ordinal++) {
    if (ordinal == 0) {
      continue;
    }
    final gap = gates.gapFor(BigInt.from(ordinal)).length;
    gaps[ordinal] = gap;
    _check(gap >= BigInt.from(42), 'Canonical minimum gap');
    _check(gap <= BigInt.from(963), 'Canonical maximum gap');
  }
  for (var i = 1; i <= 32; i++) {
    oraclePositions[i] = oraclePositions[i - 1]! + gaps[i]!;
    oraclePositions[-i] = oraclePositions[-i + 1]! - gaps[-i]!;
  }
  _check(oraclePositions[0] == foundation, 'Foundation at zero');

  var candidateCases = 0;
  var sixIntervalCases = 0;
  var extendedEligibleCases = 0;
  var longerThanMaximumCases = 0;
  var crossingZeroCases = 0;
  var shorterThanSixCases = 0;

  for (final start in <int>[-24, -16, -8, -3, 0, 5, 12]) {
    for (final span in <int>[1, 5, 6, 7, 8, 12, 20, 32, 40]) {
      final end = start + span;
      if (end > 32) {
        continue;
      }
      final actual = years.inspect(BigInt.from(start), BigInt.from(end));
      final expectedOpen = oraclePositions[start]!;
      final expectedClose = oraclePositions[end]!;
      final expectedLength = expectedClose - expectedOpen;
      final expectedEligible = span >= 6 &&
          expectedLength >= BigInt.from(252) &&
          expectedLength <= BigInt.from(5778);

      _check(actual.openOrdinal == BigInt.from(start), 'Open ordinal');
      _check(actual.closeOrdinal == BigInt.from(end), 'Close ordinal');
      _check(actual.openGate == expectedOpen, 'Independent open gate');
      _check(actual.closeGate == expectedClose, 'Independent close gate');
      _check(actual.length == expectedLength, 'Independent length');
      _check(actual.intervalCount == BigInt.from(span), 'Interval count');
      _check(actual.eligible == expectedEligible, 'Exact §P eligibility');
      _check(!actual.contains(expectedOpen), 'Left endpoint excluded');
      _check(actual.contains(expectedClose), 'Right endpoint included');
      _check(actual.contains(expectedOpen + BigInt.one), 'First day');
      _check(!actual.contains(expectedClose + BigInt.one), 'After close');
      _check(actual.length > BigInt.zero, 'Ordered distinct gates');

      candidateCases++;
      if (span < 6) {
        shorterThanSixCases++;
        _check(!actual.eligible, 'Less than six is invalid');
      }
      if (span == 6) {
        sixIntervalCases++;
        _check(actual.eligible, 'Six canonical gaps always fit');
      }
      if (span > 6 && actual.eligible) {
        extendedEligibleCases++;
      }
      if (actual.length > BigInt.from(5778)) {
        longerThanMaximumCases++;
        _check(!actual.eligible, 'Overlong interval rejected');
      }
      if (start < 0 && end > 0) {
        crossingZeroCases++;
      }
    }
  }

  _rejectArgument(
    () => years.inspect(BigInt.zero, BigInt.zero),
    'Equal ordinal input rejected',
  );
  _rejectArgument(
    () => years.inspect(BigInt.one, -BigInt.one),
    'Reversed ordinal input rejected',
  );
  _rejectArgument(
    () => years.inspect(BigInt.from(-33), BigInt.zero),
    'Lower prefix boundary enforced',
  );
  _rejectArgument(
    () => years.inspect(BigInt.zero, BigInt.from(33)),
    'Upper prefix boundary enforced',
  );
  _check(candidateCases >= 50, 'Broad candidate matrix');
  _check(sixIntervalCases >= 5, 'Six-gap coverage');
  _check(extendedEligibleCases > 0, 'More than six may qualify');
  _check(longerThanMaximumCases > 0, 'Real overlong case witnessed');
  _check(crossingZeroCases > 0, 'Both signed directions included');
  _check(shorterThanSixCases > 0, 'Short intervals tested');
  _check(_checks >= 700, 'Enough independent assertions');

  stdout.writeln(
    'PRODUCTION08_YEAR_ELIGIBILITY_PASS; checks=$_checks; '
    'candidates=$candidateCases; six=$sixIntervalCases; '
    'extended_eligible=$extendedEligibleCases; '
    'overlong=$longerThanMaximumCases; cross_zero=$crossingZeroCases; '
    'short=$shorterThanSixCases; '
    'prefix_limit=32; min_intervals=6; min_length=252; '
    'max_length=5778; year5000_ready=false; '
    'five_component_calendar_ready=false',
  );
}
