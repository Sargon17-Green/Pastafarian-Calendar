import 'dart:convert';
import 'dart:io';

import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_weave_counter.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/monster_year_traversal.dart';
import '../lib/src/stage8_cost_attribution_metrics.dart';

Map<String, Object?> measure<T>(T Function() operation) {
  Stage8CostAttributionMetrics.reset();
  final stopwatch = Stopwatch()..start();
  final value = operation();
  stopwatch.stop();
  return <String, Object?>{
    'elapsedMicroseconds': stopwatch.elapsedMicroseconds,
    'metrics': Stage8CostAttributionMetrics.snapshot(),
    'value': value,
  };
}

void requireCondition(bool condition, String message) {
  if (!condition) {
    throw StateError('STAGE8_PROFILE_FAILED: $message');
  }
}

void validateWord(List<int> word, List<int> lengths, String label) {
  final expectedDays = lengths.fold<int>(0, (sum, value) => sum + value);
  requireCondition(word.length == expectedDays, '$label exact day count');
  final frequencies = List<int>.filled(lengths.length, 0);
  final first = List<int>.filled(lengths.length, -1);
  final last = List<int>.filled(lengths.length, -1);
  for (var day = 0; day < word.length; day++) {
    final id = word[day];
    requireCondition(id >= 1 && id <= lengths.length, '$label month ID range');
    final index = id - 1;
    frequencies[index]++;
    if (first[index] == -1) {
      first[index] = day;
    }
    last[index] = day;
  }
  for (var i = 0; i < lengths.length; i++) {
    requireCondition(
      frequencies[i] == lengths[i],
      '$label exact multiplicity for month ' + (i + 1).toString(),
    );
    if (i > 0) {
      requireCondition(
        first[i - 1] < first[i],
        '$label ascending first occurrences',
      );
      requireCondition(
        last[i - 1] < last[i],
        '$label ascending last occurrences',
      );
    }
  }
}

void main(List<String> args) {
  requireCondition(args.length == 1, 'One output JSON path is required');

  final foundation = BigInt.from(-15055671);
  final year = MonsterYearTraversal().resolve(
    foundation,
    foundation,
    maxTransitions: 0,
  );
  final lengths = const MonsterMonthLengthPlanner().plan(foundation, year);
  requireCondition(year.yearNumber == BigInt.from(5000), 'Canonical year 5000');
  requireCondition(lengths.yearLength == 4244, 'Canonical year length 4244');
  requireCondition(lengths.monthCount == 45, 'Canonical month count 45');

  final countRun = measure(
    () => MonsterMonthWeaveCounter.countWholeWeaves(lengths.lengths),
  );
  final count = countRun['value'] as BigInt;

  final firstRun = measure(
    () => MonsterMonthWeavePlanner.unrankFull(lengths.lengths, BigInt.one),
  );
  final first = firstRun['value'] as List<int>;

  final lastRun = measure(
    () => MonsterMonthWeavePlanner.unrankFull(lengths.lengths, count),
  );
  final last = lastRun['value'] as List<int>;

  final canonicalRun = measure(
    () => const MonsterMonthWeavePlanner().plan(foundation, year, lengths),
  );
  final canonical = canonicalRun['value'] as MonsterMonthWeavePlan;

  requireCondition(count > (BigInt.one << 127), 'Exact count exceeds 127 bits');
  requireCondition(canonical.weaveCount == count, 'Canonical count equality');
  requireCondition(
    canonical.weaveChoice.modulus == count,
    'Canonical rank modulus equality',
  );
  requireCondition(
    canonical.weaveChoice.result >= BigInt.one &&
        canonical.weaveChoice.result <= count,
    'Canonical rank lies within one-based domain',
  );

  validateWord(first, lengths.lengths, 'FIRST');
  validateWord(last, lengths.lengths, 'LAST');
  validateWord(canonical.monthIds, lengths.lengths, 'CANONICAL');

  final literalFirst = <int>[
    for (var i = 0; i < lengths.monthCount; i++)
      ...List<int>.filled(lengths.lengths[i], i + 1),
  ];
  requireCondition(
    first.join(',') == literalFirst.join(','),
    'FIRST is the literal lexicographic minimum',
  );

  final output = <String, Object?>{
    'yearNumber': year.yearNumber.toString(),
    'yearLength': lengths.yearLength,
    'monthCount': lengths.monthCount,
    'monthLengths': lengths.lengths,
    'count': count.toString(),
    'canonicalRank': canonical.weaveChoice.result.toString(),
    'canonicalModulus': canonical.weaveChoice.modulus.toString(),
    'phases': <String, Object?>{
      'COUNT': <String, Object?>{
        'elapsedMicroseconds': countRun['elapsedMicroseconds'],
        'metrics': countRun['metrics'],
        'result': count.toString(),
      },
      'FIRST': <String, Object?>{
        'elapsedMicroseconds': firstRun['elapsedMicroseconds'],
        'metrics': firstRun['metrics'],
        'result': first,
      },
      'LAST': <String, Object?>{
        'elapsedMicroseconds': lastRun['elapsedMicroseconds'],
        'metrics': lastRun['metrics'],
        'result': last,
      },
      'CANONICAL': <String, Object?>{
        'elapsedMicroseconds': canonicalRun['elapsedMicroseconds'],
        'metrics': canonicalRun['metrics'],
        'result': canonical.monthIds,
      },
    },
  };

  File(args.single).writeAsStringSync(jsonEncode(output), flush: true);
  print(
    'STAGE8_COST_ATTRIBUTION_PROFILE_PASS; year=5000; days=4244; '
    'months=45; phases=4; full_year_words=3; exact_outputs=true',
  );
}
