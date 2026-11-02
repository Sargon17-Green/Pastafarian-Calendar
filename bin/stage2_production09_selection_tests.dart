import '../lib/src/monster_bowl_processor.dart';
import '../lib/src/monster_bowl_questions.dart';
import '../lib/src/monster_seed_feeder.dart';
import '../lib/src/monster_visible_droplets.dart';
import '../lib/src/monster_work_counts.dart';
import '../lib/src/monster_year_locator.dart';
import '../lib/src/monster_year_selection.dart';

var checks = 0;
var canonical = 0;
var shortCases = 0;
var wideCases = 0;
var rejectedCases = 0;
final BigInt m = (BigInt.one << 127) - BigInt.one;

void check(bool ok, String description) {
  checks++;
  if (!ok) {
    throw StateError('PRODUCTION09_SELECTION_CHECK_FAILED: ' + description);
  }
}

BigInt normalize(BigInt x) => ((x - BigInt.one) % m) + BigInt.one;

final class OracleChoice {
  final BigInt initial;
  final BigInt accepted;
  final BigInt rejected;
  final BigInt result;
  final int width;
  final String branch;
  const OracleChoice(this.initial, this.accepted, this.rejected, this.result,
      this.width, this.branch);
}

/// Independent §N scalar ring oracle; never uses production chooseEqual.
OracleChoice oracleChoice(BigInt first, int direction, BigInt count) {
  if (count <= BigInt.zero || (direction != 1 && direction != -1)) {
    throw ArgumentError('Invalid independent choice request');
  }
  var width = 1;
  var ring = m;
  var initial = first;
  if (count > m) {
    while (ring < count) {
      width++;
      ring *= m;
      if (width > 4) {
        throw ArgumentError('Test oracle width limit');
      }
    }
    initial = BigInt.one;
    var place = BigInt.one;
    for (var j = 0; j < width; j++) {
      final digit = normalize(first + BigInt.from(direction * j));
      initial += (digit - BigInt.one) * place;
      place *= m;
    }
  }
  final limit = (ring ~/ count) * count;
  var accepted = initial;
  var rejected = BigInt.zero;
  while (accepted > limit) {
    accepted += BigInt.from(direction);
    if (accepted > ring) {
      accepted = BigInt.one;
    } else if (accepted < BigInt.one) {
      accepted = ring;
    }
    rejected += BigInt.one;
    if (rejected > BigInt.from(20)) {
      throw StateError('Unexpectedly long rejection');
    }
  }
  return OracleChoice(
      initial,
      accepted,
      rejected,
      BigInt.one + ((accepted - BigInt.one) % count),
      width,
      width == 1 ? 'short' : 'wide');
}

void compareEqual(BigInt first, int direction, BigInt n) {
  final expected = oracleChoice(first, direction, n);
  final actual = const MonsterBowlQuestionEngine().chooseEqualFromStart(
    firstAnswer: first,
    direction: direction,
    modulus: n,
  );
  check(actual.initial == expected.initial, 'Initial ring value');
  check(actual.accepted == expected.accepted, 'Accepted ring value');
  check(actual.rejected == expected.rejected, 'Rejected steps');
  check(actual.result == expected.result, '1-based oracle index');
  check(actual.width == expected.width, 'Digit width');
  check(actual.branch == expected.branch, 'Selection branch');
  check(actual.result >= BigInt.one && actual.result <= n, 'Index range');
  if (expected.width == 1) {
    shortCases++;
  } else {
    wideCases++;
  }
  if (expected.rejected > BigInt.zero) {
    rejectedCases++;
  }
}

/// Independent §M answer from an upstream §K snapshot of the (c,c) sauce.
void verifyCanonical(BigInt c) {
  final locator = MonsterYearLocator();
  final preview = locator.sentinelSearch(c);
  check(preview.complete && preview.candidates.isNotEmpty, 'Real complete §Q');
  preview.requireComplete();
  final actual = MonsterYear5000Selector(locator: locator).select(c);
  final n = BigInt.from(preview.candidates.length);
  check(actual.calculationDay == c, 'Calculation day retained');
  check(actual.yearNumber == BigInt.from(5000), 'Year number constant');
  check(actual.sauceFirst == c && actual.sauceSecond == c, 'Sauce (c,c)');
  check(actual.bowlId == 1 && actual.seal == 10, 'Question parameters');
  check(actual.candidateCount == n, 'Candidate count');

  final counts = const MonsterWorkCounter().calculate(c, c);
  check(counts.direction == 2, 'Zero displacement');
  final feeder = const MonsterSeedFeeder();
  final stones = feeder.buildStones();
  final feeds = feeder.buildHiddenFeeds(counts, stones);
  final drops = const MonsterVisibleDropGenerator().buildVisibleDrops(
    counts: counts,
    hiddenFeeds: feeds,
    stones: stones,
  );
  final bowls = const MonsterBowlProcessor().process(
    counts: counts,
    visibleDrops: drops,
    stones: stones,
  );
  final following = bowls.orderAt46[(bowls.orderAt46.indexOf(1) + 1) % 6];
  final z = BigInt.from(10);
  final first = normalize(
    (bowls.finalBowls[0] + z + BigInt.from(181)).pow(2) +
        BigInt.from(179) * bowls.finalBowls[following - 1] +
        z,
  );
  final d = normalize(
    (first + z + BigInt.from(194)).pow(2) +
        BigInt.from(193) * first +
        BigInt.from(197) * bowls.finalBowls[5],
  );
  final expected = oracleChoice(first, d.isOdd ? 1 : -1, n);
  check(actual.choice.initial == expected.initial, '§M initial answer');
  check(actual.choice.accepted == expected.accepted, '§N accepted value');
  check(actual.choice.rejected == expected.rejected, '§N rejection count');
  check(actual.choiceIndex == expected.result, '§N selected ordinal');
  check(actual.choice.result == actual.choiceIndex, '1-based choice');
  check(actual.choice.branch == 'short', 'Actual §Q uses short choice');
  final chosen = preview.candidates[(expected.result - BigInt.one).toInt()];
  check(actual.selectedYear.openOrdinal == chosen.openOrdinal, 'Open ordinal');
  check(
      actual.selectedYear.closeOrdinal == chosen.closeOrdinal, 'Close ordinal');
  check(actual.selectedYear.contains(c), 'Geometric containment');
  shortCases++;
  canonical++;
}

void main() {
  final f = MonsterWorkCounter.foundationDay;
  for (final c in <BigInt>[f, f - BigInt.one, f + BigInt.one]) {
    verifyCanonical(c);
  }
  compareEqual(m, 1, m - BigInt.one);
  compareEqual(m, -1, m - BigInt.one);
  compareEqual(BigInt.one, -1, BigInt.from(13));
  compareEqual(BigInt.from(42), 1, BigInt.one);
  compareEqual(m - BigInt.one, 1, m * m - BigInt.from(10));
  compareEqual(BigInt.one, -1, m + BigInt.one);
  compareEqual(m, 1, m + BigInt.one);
  var refused = false;
  try {
    MonsterYear5000Selector().select(f + (BigInt.one << 190));
  } on IncompleteMonsterYearDomain {
    refused = true;
  }
  check(refused, 'Unproven distant domain rejected');
  check(canonical == 3, 'Three canonical comparisons');
  check(shortCases >= 6 && wideCases >= 3, 'Short and wide covered');
  check(rejectedCases >= 2, 'Rejection logic covered');
  check(checks >= 90, 'Substantial independent checks');
  print('PRODUCTION09_SELECTION_PASS; checks=' +
      checks.toString() +
      '; canonical=' +
      canonical.toString() +
      '; short=' +
      shortCases.toString() +
      '; wide=' +
      wideCases.toString() +
      '; rejections=' +
      rejectedCases.toString() +
      '; year5000_selection_ready=true; five_component_calendar_ready=false');
}
