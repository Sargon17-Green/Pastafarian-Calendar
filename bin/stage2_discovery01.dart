import 'dart:io';

import '../lib/src/monster_base.dart';
import '../test_support/normative_reference.dart';

var _checks = 0;

void _expect(bool condition, String description) {
  _checks += 1;
  if (!condition) {
    throw StateError('DISCOVERY01_CHECK_FAILED: $description');
  }
}

void _expectUnbuilt(BigInt actionDay, BigInt targetDay) {
  var observed = false;
  try {
    calendarDateSpaghetti(actionDay, targetDay);
  } on StateError catch (error) {
    observed = true;
    _expect(
      error.message == 'המסלול הספגטי טרם נבנה בשלב האתחול.',
      'Unexpected production StateError on ($actionDay, $targetDay)',
    );
  }
  _expect(
    observed,
    'Production unexpectedly returned a result on ($actionDay, $targetDay)',
  );
}

void main() {
  final foundation = NormativeReference.foundationDay;

  // Independent enumeration: enumerate ranks by visiting the foundation,
  // then alternating negative and positive offsets. Do not call dayCount
  // to construct the expected rank.
  final orderedDays = <BigInt>[foundation];
  for (var distance = 1; distance <= 12; distance++) {
    final delta = BigInt.from(distance);
    orderedDays.add(foundation - delta);
    orderedDays.add(foundation + delta);
  }

  for (var rank = 0; rank < orderedDays.length; rank++) {
    _expect(
      NormativeReference.dayCount(orderedDays[rank]) == BigInt.from(rank + 1),
      'Normative day count differs from independent enumeration at rank '
      '${rank + 1}',
    );
  }

  // Seven offsets in each direction give 49 directed input pairs.
  // This exercises the five work-count components and the Stage 1
  // production sentinel, not a hypothetical legacy implementation.
  const offsets = <int>[-12, -2, -1, 0, 1, 2, 12];
  var sentinelCases = 0;
  for (final actionOffset in offsets) {
    for (final targetOffset in offsets) {
      final actionDay = foundation + BigInt.from(actionOffset);
      final targetDay = foundation + BigInt.from(targetOffset);
      final actionRank = BigInt.from(orderedDays.indexOf(actionDay) + 1);
      final targetRank = BigInt.from(orderedDays.indexOf(targetDay) + 1);
      final expectedDirection = targetDay < actionDay
          ? 1
          : targetDay == actionDay
              ? 2
              : 3;
      final work = NormativeReference.workCounts(actionDay, targetDay);
      _expect(work.action == actionRank, 'Action rank mismatch');
      _expect(work.target == targetRank, 'Target rank mismatch');
      _expect(
        work.distance == (targetDay - actionDay).abs() + BigInt.one,
        'Inclusive distance mismatch',
      );
      _expect(
        work.connection == actionRank + targetRank,
        'Connection mismatch',
      );
      _expect(work.direction == expectedDirection, 'Direction mismatch');
      _expectUnbuilt(actionDay, targetDay);
      sentinelCases += 1;
    }
  }

  // Large-number boundary: exact parity and positivity, no Int conversion.
  final wideOffset = (BigInt.one << 127) + BigInt.from(19);
  final leftCount = NormativeReference.dayCount(foundation - wideOffset);
  final rightCount = NormativeReference.dayCount(foundation + wideOffset);
  _expect(leftCount == wideOffset * BigInt.from(2), 'Wide left rank');
  _expect(
    rightCount == wideOffset * BigInt.from(2) + BigInt.one,
    'Wide right rank',
  );
  _expect(leftCount.isEven && rightCount.isOdd, 'Wide rank parity');

  stdout.writeln(
    'DISCOVERY01_BASELINE_PASS; checks=$_checks; '
    'production_stub_cases=$sentinelCases; verified_legacy_witnesses=0',
  );
}
