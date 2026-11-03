import '../lib/src/monster_bowl_processor.dart';
import '../lib/src/monster_meatball_gates.dart';
import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_selection.dart';
import '../lib/src/monster_year_traversal.dart';

var checks = 0;
var anchors = 0;
var forwardCases = 0;
var backwardCases = 0;
var oracleCases = 0;
final m = (BigInt.one << 127) - BigInt.one;

void check(bool condition, String detail) {
  checks++;
  if (!condition) {
    throw StateError('PRODUCTION10_YEAR_WALK_FAILED: $detail');
  }
}

BigInt ring(BigInt value) => BigInt.one + ((value - BigInt.one) % m);

/// Test-only brute force from the shared §O gap definition. This does not
/// call production neighbor enumeration, sorting or equal-choice APIs.
void independentNeighbor(
  BigInt calculationDay,
  MonsterTraversedYear current,
  bool forward,
  MonsterTraversedYear actual,
) {
  final startOrdinal =
      forward ? current.candidate.closeOrdinal : current.candidate.openOrdinal;
  final startGate =
      forward ? current.candidate.closeGate : current.candidate.openGate;
  final options = <List<BigInt>>[];
  final calculator = MonsterMeatballGateCalculator();
  var edge = startGate;
  for (var n = 1; n <= 137; n++) {
    final number = BigInt.from(n);
    final right =
        forward ? startOrdinal + number : startOrdinal - number + BigInt.one;
    // Independently use §O's two sign-dependent recurrences.
    final gapIndex = right > BigInt.zero ? right : right - BigInt.one;
    final gapLength = calculator.gapFor(gapIndex).length;
    edge += forward ? gapLength : -gapLength;
    final distance = (edge - startGate).abs();
    if (distance > BigInt.from(5778)) {
      break;
    }
    if (n >= 6 && distance >= BigInt.from(252)) {
      options.add(<BigInt>[
        forward ? startOrdinal : startOrdinal - number,
        forward ? startOrdinal + number : startOrdinal,
        forward ? startGate : edge,
        forward ? edge : startGate,
        distance,
      ]);
    }
  }
  options.sort((a, b) {
    final lengthComparison = a[4].compareTo(b[4]);
    return lengthComparison == 0 ? a[2].compareTo(b[2]) : lengthComparison;
  });
  check(options.isNotEmpty, 'Nonempty brute force choices');
  final work = const MonsterWorkCounter().calculate(
    calculationDay,
    startGate,
  );
  final feeder = const MonsterSeedFeeder();
  final stones = feeder.buildStones();
  final hidden = feeder.buildHiddenFeeds(work, stones);
  final drops = const MonsterVisibleDropGenerator().buildVisibleDrops(
    counts: work,
    hiddenFeeds: hidden,
    stones: stones,
  );
  final bowls = const MonsterBowlProcessor().process(
    counts: work,
    visibleDrops: drops,
    stones: stones,
  );
  final following = bowls.orderAt46[(bowls.orderAt46.indexOf(1) + 1) % 6];
  final seal = BigInt.from(forward ? 11 : 12);
  final first = ring(
    (bowls.finalBowls[0] + seal + BigInt.from(181)).pow(2) +
        BigInt.from(179) * bowls.finalBowls[following - 1] +
        seal,
  );
  final directionRaw = ring(
    (first + seal + BigInt.from(194)).pow(2) +
        BigInt.from(193) * first +
        BigInt.from(197) * bowls.finalBowls[5],
  );
  final direction = directionRaw.isOdd ? BigInt.one : -BigInt.one;
  final size = BigInt.from(options.length);
  final limit = (m ~/ size) * size;
  var accepted = first;
  var attempts = 0;
  while (accepted > limit) {
    accepted = ring(accepted + direction);
    attempts++;
    if (attempts > 1000) {
      throw StateError('Unexpected test oracle rejection count');
    }
  }
  final index = BigInt.one + ((accepted - BigInt.one) % size);
  final chosen = options[(index - BigInt.one).toInt()];
  check(actual.questionGate == startGate, 'Boundary sauce day');
  check(actual.questionSeal == (forward ? 11 : 12), 'Correct seal');
  check(actual.candidateCount == size, 'Independent count');
  check(actual.choiceIndex == index, 'Independent §N index');
  check(actual.candidate.openOrdinal == chosen[0], 'Open ordinal oracle');
  check(actual.candidate.closeOrdinal == chosen[1], 'Close ordinal oracle');
  check(actual.candidate.openGate == chosen[2], 'Open gate oracle');
  check(actual.candidate.closeGate == chosen[3], 'Close gate oracle');
  check(actual.candidate.length == chosen[4], 'Year length oracle');
  check(actual.candidate.eligible, 'Selected year eligible');
  oracleCases++;
}

void examine(BigInt c) {
  final selector = MonsterYear5000Selector();
  final baseSelection = selector.select(c);
  final start = MonsterTraversedYear.from5000(baseSelection);
  final walker = MonsterYearTraversal();
  final after = walker.next(c, start);
  final before = walker.previous(c, start);
  independentNeighbor(c, start, true, after);
  independentNeighbor(c, start, false, before);
  check(start.yearNumber == BigInt.from(5000), 'Structural year 5000');
  check(after.yearNumber == BigInt.from(5001), 'Next year label');
  check(before.yearNumber == BigInt.from(4999), 'Previous year label');
  check(after.candidate.openGate == start.candidate.closeGate,
      'Forward shared gate');
  check(before.candidate.closeGate == start.candidate.openGate,
      'Backward shared gate');
  check(start.contains(start.candidate.openGate + BigInt.one),
      'Open gate exclusive');
  check(start.contains(start.candidate.closeGate), 'Close gate inclusive');
  check(!start.contains(start.candidate.openGate), 'Open gate not contained');
  check(
      walker.resolve(c, start.candidate.closeGate).yearNumber ==
          BigInt.from(5000),
      'Right boundary belongs to base');
  check(
      walker.resolve(c, start.candidate.openGate + BigInt.one).yearNumber ==
          BigInt.from(5000),
      'First day belongs to base');
  check(
      walker
              .resolve(c, start.candidate.closeGate + BigInt.one,
                  maxTransitions: 1)
              .yearNumber ==
          BigInt.from(5001),
      'First day after base');
  check(
      walker
              .resolve(c, start.candidate.openGate, maxTransitions: 1)
              .yearNumber ==
          BigInt.from(4999),
      'Left boundary belongs to predecessor');
  var refused = false;
  try {
    walker.resolve(c, after.candidate.closeGate + BigInt.one,
        maxTransitions: 1);
  } on IncompleteMonsterYearTraversal {
    refused = true;
  }
  check(refused, 'No unproven second transition');
  refused = false;
  try {
    walker.resolve(c, start.candidate.closeGate + BigInt.one,
        maxTransitions: 0);
  } on IncompleteMonsterYearTraversal {
    refused = true;
  }
  check(refused, 'No fabricated zero-transition success');
  forwardCases++;
  backwardCases++;
  anchors++;
}

void main() {
  final f = MonsterWorkCounter.foundationDay;
  for (final c in <BigInt>[f, f - BigInt.one, f + BigInt.one]) {
    examine(c);
  }
  final walk = MonsterYearTraversal();
  check(MonsterYearTraversal.signedGapOrdinal(BigInt.one) == BigInt.one,
      'Positive gap convention');
  check(MonsterYearTraversal.signedGapOrdinal(BigInt.zero) == -BigInt.one,
      'Crossing Foundation convention');
  check(MonsterYearTraversal.signedGapOrdinal(-BigInt.one) == -BigInt.from(2),
      'Negative gap convention');
  var invalid = false;
  try {
    walk.resolve(f, f, maxTransitions: -1);
  } on RangeError {
    invalid = true;
  }
  check(invalid, 'Negative step budget rejected');
  check(anchors == 3 && forwardCases == 3 && backwardCases == 3,
      'Both directions for three anchors');
  check(oracleCases == 6, 'Independent oracle over six transitions');
  check(checks >= 85, 'Numerical and boundary assertion threshold');
  print('PRODUCTION10_YEAR_WALK_PASS; checks=$checks; anchors=$anchors; '
      'forward=$forwardCases; backward=$backwardCases; oracle=$oracleCases; '
      'year_component_ready=true; five_component_calendar_ready=false');
}
