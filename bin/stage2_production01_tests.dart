import 'dart:io';

import '../lib/src/monster_base.dart';
import '../lib/src/monster_work_counts.dart';

var _checks = 0;

void _check(bool condition, String description) {
  _checks += 1;
  if (!condition) {
    throw StateError('PRODUCTION01_CHECK_FAILED: $description');
  }
}

void main() {
  final counter = const MonsterWorkCounter();
  final foundation = MonsterWorkCounter.foundationDay;
  final orderedDays = <BigInt>[foundation];

  // Independent expected ranks: direct alternating enumeration, not
  // MonsterWorkCounter.dayRank or the normative reference's formula.
  for (var step = 1; step <= 12; step++) {
    final delta = BigInt.from(step);
    orderedDays.add(foundation - delta);
    orderedDays.add(foundation + delta);
  }
  final expectedRanks = <BigInt, BigInt>{};
  for (var index = 0; index < orderedDays.length; index++) {
    expectedRanks[orderedDays[index]] = BigInt.from(index + 1);
    _check(
      counter.dayRank(orderedDays[index]) == BigInt.from(index + 1),
      'Independent enumeration rank',
    );
  }

  const offsets = <int>[-12, -2, -1, 0, 1, 2, 12];
  var productionStubCases = 0;
  for (final actionOffset in offsets) {
    for (final targetOffset in offsets) {
      final actionDay = foundation + BigInt.from(actionOffset);
      final targetDay = foundation + BigInt.from(targetOffset);
      final actionRank = expectedRanks[actionDay]!;
      final targetRank = expectedRanks[targetDay]!;
      final expectedDistance = (targetDay - actionDay).abs() + BigInt.one;
      final expectedDirection = targetDay < actionDay
          ? 1
          : targetDay == actionDay
              ? 2
              : 3;
      final counts = counter.calculate(actionDay, targetDay);
      _check(counts.action == actionRank, 'Action day rank');
      _check(counts.target == targetRank, 'Target day rank');
      _check(counts.distance == expectedDistance, 'Inclusive distance');
      _check(
        counts.connection == actionRank + targetRank,
        'Independent rank sum',
      );
      _check(counts.direction == expectedDirection, 'Direction');

      // The working slice is integrated, but the five-part calendar
      // output must still reject execution in Stage 2 / Production01.
      final context = MonsterContext(
        calculationDay: actionDay,
        targetDay: targetDay,
      );
      var rejected = false;
      try {
        const MonsterManager().executeUnbuilt(context);
      } on StateError catch (error) {
        rejected = true;
        _check(
          error.message == 'המסלול הספגטי טרם נבנה בשלב האתחול.',
          'Unbuilt calendar sentinel message',
        );
      }
      _check(rejected, 'Unbuilt calendar must reject');
      _check(
        context.metrics['bootstrap.calls'] == BigInt.one,
        'Bootstrap metric',
      );
      _check(context.metrics['work.action'] == actionRank, 'Action metric');
      _check(context.metrics['work.target'] == targetRank, 'Target metric');
      _check(
        context.metrics['work.distance'] == expectedDistance,
        'Distance metric',
      );
      _check(
        context.metrics['work.connection'] == actionRank + targetRank,
        'Connection metric',
      );
      _check(
        context.metrics['work.direction'] == BigInt.from(expectedDirection),
        'Direction metric',
      );
      _check(
        context.branchTrace.join('|') == 'WORK_COUNTS_READY|STAGE_NOT_BUILT',
        'Production dispatcher trace',
      );
      productionStubCases += 1;
    }
  }

  // Exact arithmetic above a fixed 64-bit or 128-bit signed integer.
  final wide = (BigInt.one << 127) + BigInt.from(19);
  final leftRank = counter.dayRank(foundation - wide);
  final rightRank = counter.dayRank(foundation + wide);
  _check(leftRank == wide * BigInt.from(2), 'Wide negative rank');
  _check(
    rightRank == wide * BigInt.from(2) + BigInt.one,
    'Wide positive rank',
  );
  _check(leftRank.isEven && rightRank.isOdd, 'Wide rank parity');

  final extreme = counter.calculate(foundation - wide, foundation + wide);
  _check(
    extreme.distance == wide * BigInt.from(2) + BigInt.one,
    'Wide inclusive distance',
  );
  _check(
    extreme.connection == wide * BigInt.from(4) + BigInt.one,
    'Wide connection',
  );
  _check(extreme.direction == 3, 'Wide direction');

  stdout.writeln(
    'PRODUCTION01_COUNTS_PASS; checks=$_checks; '
    'production_stub_cases=$productionStubCases; '
    'five_component_calendar_ready=false',
  );
}
