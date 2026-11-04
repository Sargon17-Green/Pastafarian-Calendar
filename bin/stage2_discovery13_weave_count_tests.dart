import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_weave_counter.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;
var stateCases = 0;
var rankCases = 0;
var canonicalAnchors = 0;

void check(bool condition, String detail) {
  checks++;
  if (!condition) {
    throw StateError('DISCOVERY13_WEAVE_COUNT_FAILED: $detail');
  }
}

/// Independent suffix oracle. Recursively walks each legal next letter;
/// it does NOT reuse the production color-insertion recurrence.
BigInt bruteSuffix(List<int> remaining, int opened, int closed) {
  if (remaining.every((n) => n == 0)) {
    return BigInt.one;
  }
  var total = BigInt.zero;
  for (var index = 0; index < remaining.length; index++) {
    final id = index + 1;
    if (remaining[index] == 0 || id > opened + 1) {
      continue;
    }
    if (remaining[index] == 1 && id != closed + 1) {
      continue;
    }
    final after = List<int>.of(remaining);
    after[index]--;
    total += bruteSuffix(
      after,
      id == opened + 1 ? opened + 1 : opened,
      after[index] == 0 ? closed + 1 : closed,
    );
  }
  return total;
}

void bruteStates() {
  for (var months = 1; months <= 5; months++) {
    void visit(List<int> counts) {
      if (counts.length < months) {
        for (var k = 1; k <= 3; k++) {
          visit(<int>[...counts, k]);
        }
        return;
      }
      for (var opened = 0; opened <= months; opened++) {
        for (var closed = 0; closed <= opened; closed++) {
          if (opened == months && closed == months) {
            continue;
          }
          final suffix = <int>[
            for (var i = 0; i < months; i++)
              if (i < closed) 0 else counts[i],
          ];
          final days = suffix.fold<int>(
            0,
            (sum, k) => sum + k,
          );
          if (days > 11) {
            continue;
          }
          final actual = MonsterMonthWeaveCounter.countCompletions(
            suffix,
            openedUpTo: opened,
            closedUpTo: closed,
          );
          final expected = bruteSuffix(suffix, opened, closed);
          check(
            actual == expected,
            'Independent suffix enumeration months=$months '
            'opened=$opened closed=$closed lengths=$suffix',
          );
          stateCases++;
        }
      }
    }

    visit(<int>[]);
  }
}

void bruteRank(List<int> lengths) {
  final words = <List<int>>[];
  void visit(List<int> remaining, int opened, int closed, List<int> word) {
    if (remaining.every((n) => n == 0)) {
      words.add(word);
      return;
    }
    for (var index = 0; index < remaining.length; index++) {
      final id = index + 1;
      if (remaining[index] == 0 || id > opened + 1) {
        continue;
      }
      if (remaining[index] == 1 && id != closed + 1) {
        continue;
      }
      final after = List<int>.of(remaining);
      after[index]--;
      visit(
        after,
        id == opened + 1 ? opened + 1 : opened,
        after[index] == 0 ? closed + 1 : closed,
        <int>[...word, id],
      );
    }
  }

  visit(lengths, 0, 0, <int>[]);
  check(words.isNotEmpty, 'Independent rank domain nonempty');
  final total = MonsterMonthWeaveCounter.countWholeWeaves(lengths);
  check(total == BigInt.from(words.length), 'Complete brute count');
  for (var rank = 1; rank <= words.length; rank++) {
    final actual = MonsterMonthWeaveCounter.unrankDiscovery(
      lengths,
      BigInt.from(rank),
    );
    check(actual.join(',') == words[rank - 1].join(','),
        'Independent full lexicographic rank $rank for $lengths');
    rankCases++;
  }
}

void smallRankOracle() {
  for (final lengths in <List<int>>[
    <int>[1, 1],
    <int>[2, 2],
    <int>[2, 1, 2],
    <int>[3, 2, 2],
    <int>[1, 2, 3],
    <int>[2, 2, 2, 1],
    <int>[3, 1, 2, 2],
    <int>[2, 2, 2, 2],
  ]) {
    bruteRank(lengths);
  }
}

void refusalOracle() {
  var refused = false;
  try {
    MonsterMonthWeaveCounter.countCompletions(
      <int>[1, 0, 2],
      openedUpTo: 0,
      closedUpTo: 0,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Unopened month with zero remaining refuses');
  refused = false;
  try {
    MonsterMonthWeaveCounter.countCompletions(
      <int>[1, 2, 3],
      openedUpTo: 1,
      closedUpTo: 2,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Invalid opened/closed ordering refuses');
  refused = false;
  try {
    MonsterMonthWeaveCounter.unrankDiscovery(
      <int>[4, 4],
      BigInt.zero,
    );
  } on ArgumentError {
    refused = true;
  }
  check(refused, 'Zero lexicographic rank refuses');
  refused = false;
  try {
    MonsterMonthWeaveCounter.unrankDiscovery(
      <int>[13, 13],
      BigInt.one,
    );
  } on UnsupportedError {
    refused = true;
  }
  check(refused, 'More than 24 days cannot claim discovery unrank');
  check(
    MonsterMonthWeaveCounter.countWholeWeaves(
      List<int>.filled(47, 4),
    ) >
        (BigInt.one << 127),
    'Wide 47-month synthetic count remains exact BigInt',
  );
  check(
    MonsterMonthWeaveCounter.countCompletions(
      <int>[0, 0],
      openedUpTo: 2,
      closedUpTo: 2,
    ) ==
        BigInt.one,
    'Completed suffix has exactly one empty continuation',
  );
}

void canonicalCount(BigInt calculationDay) {
  final year = MonsterTraversedYear.from5000(
    MonsterYear5000Selector().select(calculationDay),
  );
  final plan = const MonsterMonthLengthPlanner().plan(
    calculationDay,
    year,
  );
  final possible = MonsterMonthWeaveCounter.countWholeWeaves(
    plan.lengths,
  );
  check(possible >= BigInt.one, 'Canonical §U vector has a §V weave');
  check(plan.monthCount == plan.lengths.length, 'Canonical month vector');
  canonicalAnchors++;
}

void main() {
  bruteStates();
  smallRankOracle();
  refusalOracle();
  final foundation = MonsterWorkCounter.foundationDay;
  for (final day in <BigInt>[
    foundation - BigInt.one,
    foundation,
    foundation + BigInt.one,
  ]) {
    canonicalCount(day);
  }
  check(stateCases == 5962, '5962 independent suffix states');
  check(rankCases >= 30, 'Independent lexicographic ranks');
  check(canonicalAnchors == 3, 'Three canonical count-only anchors');
  check(checks >= 6000, 'Adequate bounded independent checks');
  print('DISCOVERY13_WEAVE_COUNT_PASS; checks=$checks; '
      'suffix_states=$stateCases; rank_cases=$rankCases; '
      'canonical_anchors=$canonicalAnchors; '
      'count_only_ready=true; full_weave_ready=false; '
      'five_component_calendar_ready=false');
}
