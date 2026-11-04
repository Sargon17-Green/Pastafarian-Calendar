import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;
var bruteDomains = 0;
var canonicalAnchors = 0;
var boundaryCases = 0;

void check(bool condition, String detail) {
  checks++;
  if (!condition) {
    throw StateError('PRODUCTION12_MONTH_LENGTHS_FAILED: $detail');
  }
}

/// Independent oracle: enumerate bounded positive month vectors recursively.
/// This deliberately does not use production DP or any normative fixture.
List<List<int>> bruteLengths(int total, int months) {
  final results = <List<int>>[];
  void visit(int remaining, List<int> prefix) {
    if (prefix.length == months) {
      if (remaining == 0) {
        results.add(prefix);
      }
      return;
    }
    final slots = months - prefix.length - 1;
    for (var length = 4; length <= 123; length++) {
      if (length + slots * 4 > remaining) {
        break;
      }
      if (length + slots * 123 < remaining) {
        continue;
      }
      visit(remaining - length, <int>[...prefix, length]);
    }
  }

  visit(total, <int>[]);
  return results;
}

void bruteOracle() {
  for (var months = 3; months <= 5; months++) {
    for (var surplus = 0; surplus < 10; surplus++) {
      final days = months * 4 + surplus;
      final enumerated = bruteLengths(days, months);
      final count = MonsterMonthLengthPlanner.countLengthVectors(
        days,
        months,
      );
      check(enumerated.isNotEmpty, 'Brute domain is nonempty');
      check(count == BigInt.from(enumerated.length), 'Brute exact count');
      final probes = <int>{
        1,
        (enumerated.length + 1) ~/ 2,
        enumerated.length,
      };
      for (final rank in probes) {
        final actual = MonsterMonthLengthPlanner.unrankLengthVector(
          days,
          months,
          BigInt.from(rank),
        );
        check(
          actual.join(',') == enumerated[rank - 1].join(','),
          'Independent lexicographic rank',
        );
        check(actual.length == months, 'Exactly m months');
        check(
          actual.every((length) => length >= 4 && length <= 123),
          'Each length is within 4..123',
        );
        check(
          actual.fold<int>(0, (sum, length) => sum + length) == days,
          'Exactly full year length',
        );
      }
      bruteDomains++;
    }
  }
}

void boundaryOracle() {
  check(
    MonsterMonthLengthPlanner.countLengthVectors(369, 3) == BigInt.one,
    'Only [123,123,123] sums to 369 in three months',
  );
  check(
    MonsterMonthLengthPlanner.unrankLengthVector(369, 3, BigInt.one).join(',') ==
        '123,123,123',
    'Maximum-length extreme vector',
  );
  check(
    MonsterMonthLengthPlanner.countLengthVectors(368, 3) == BigInt.from(3),
    'One-day deficit among three maximum-length months',
  );
  check(
    MonsterMonthLengthPlanner.countLengthVectors(5778, 47) ==
        BigInt.from(18424),
    'Forty-seven months, deficit three, C(49,3)',
  );
  boundaryCases += 4;
  check(
    MonsterMonthLengthPlanner.countLengthVectors(5778, 46) == BigInt.zero,
    'Infeasible 46-month year',
  );
  check(
    MonsterMonthLengthPlanner.minimumMonthCount(5778) == 47 &&
        MonsterMonthLengthPlanner.maximumMonthCount(5778) == 47,
    'Canonical high-end month count',
  );
  check(
    MonsterMonthLengthPlanner.minimumMonthCount(252) == 3 &&
        MonsterMonthLengthPlanner.maximumMonthCount(252) == 47,
    'Canonical low-end month counts',
  );
  check(
    MonsterMonthLengthPlanner.countLengthVectors(0, 3) == BigInt.zero,
    'Infeasible empty synthetic domain',
  );

  var refused = false;
  try {
    MonsterMonthLengthPlanner.unrankLengthVector(20, 3, BigInt.zero);
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Rank zero rejected');
  refused = false;
  try {
    MonsterMonthLengthPlanner.unrankLengthVector(
      20,
      3,
      MonsterMonthLengthPlanner.countLengthVectors(20, 3) + BigInt.one,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Rank above domain rejected');
  refused = false;
  try {
    MonsterMonthLengthPlanner.countLengthVectors(252, 2);
  } on RangeError {
    refused = true;
  }
  check(refused, 'Month count below three rejected');
  refused = false;
  try {
    MonsterMonthLengthPlanner.countLengthVectors(5779, 47);
  } on RangeError {
    refused = true;
  }
  check(refused, 'Year length outside canonical cap rejected');
}

void canonicalCase(BigInt calculationDay) {
  final year = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(calculationDay),
  );
  final plan = const MonsterMonthLengthPlanner().plan(
    calculationDay,
    year,
  );
  final expectedDays =
      (year.candidate.closeGate - year.candidate.openGate).toInt();
  check(plan.yearLength == expectedDays, 'Verified year duration');
  check(plan.monthCount >= 3 && plan.monthCount <= 47, '3..47 months');
  check(plan.monthCount >= plan.minMonths, 'At least ceil(L/123)');
  check(plan.monthCount <= plan.maxMonths, 'At most floor(L/4) and 47');
  check(plan.lengths.length == plan.monthCount, 'One length per month');
  check(
    plan.lengths.every((length) => length >= 4 && length <= 123),
    'All canonical lengths bounded',
  );
  check(
    plan.lengths.fold<int>(0, (sum, length) => sum + length) ==
        plan.yearLength,
    'Length vector covers the year exactly',
  );
  check(
    plan.monthCountChoice.modulus ==
        BigInt.from(plan.maxMonths - plan.minMonths + 1),
    'Bowl3 seal30 chooses from full month-count domain',
  );
  check(
    plan.monthCount == plan.minMonths + plan.monthCountChoice.result.toInt() - 1,
    'Seal30 one-based rank mapping',
  );
  check(
    plan.lengthSequenceCount ==
        MonsterMonthLengthPlanner.countLengthVectors(
          plan.yearLength,
          plan.monthCount,
        ),
    'Exact chosen-length domain count',
  );
  check(
    plan.lengthChoice.modulus == plan.lengthSequenceCount,
    'Bowl3 seal31 uses exact vector count',
  );
  check(
    plan.lengths.join(',') ==
        MonsterMonthLengthPlanner.unrankLengthVector(
          plan.yearLength,
          plan.monthCount,
          plan.lengthChoice.result,
        ).join(','),
    'Chosen lexicographic length vector',
  );
  canonicalAnchors++;
}

void main() {
  bruteOracle();
  boundaryOracle();
  final foundation = MonsterWorkCounter.foundationDay;
  for (final calculationDay in <BigInt>[
    foundation - BigInt.one,
    foundation,
    foundation + BigInt.one,
  ]) {
    canonicalCase(calculationDay);
  }
  check(bruteDomains == 30, 'Thirty independent brute domains');
  check(boundaryCases == 4, 'Four high/low boundary cases');
  check(canonicalAnchors == 3, 'Three anchored calculation days');
  check(checks >= 400, 'Sufficient independent assertions');
  print('PRODUCTION12_MONTH_LENGTHS_PASS; checks=$checks; '
      'brute_domains=$bruteDomains; boundary_cases=$boundaryCases; '
      'canonical_anchors=$canonicalAnchors; month_lengths_ready=true; '
      'month_weave_ready=false; five_component_calendar_ready=false');
}
