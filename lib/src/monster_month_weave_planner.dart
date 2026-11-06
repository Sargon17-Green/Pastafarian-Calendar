import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_month_lengths.dart';
import 'monster_month_weave_counter.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';
import 'monster_year_traversal.dart';

/// A full §V weave; §W names and §X final date are not implemented here.
final class MonsterMonthWeavePlan {
  final BigInt weaveCount;
  final MonsterEqualChoice weaveChoice;
  final List<int> monthIds;

  MonsterMonthWeavePlan._({
    required this.weaveCount,
    required this.weaveChoice,
    required List<int> monthIds,
  }) : monthIds = List<int>.unmodifiable(monthIds);
}

/// Full-year lexicographic unranking with a factored active-month counter.
///
/// Active suffix words have ascending last occurrences. For a fixed active
/// word, inserting all still-unopened colors has the same multiplicity,
/// depending only on the active word length. All candidate active children
/// therefore share one expensive unopened-color factor per day.
final class MonsterMonthWeavePlanner {
  final MonsterBowlQuestionEngine questions;

  const MonsterMonthWeavePlanner({
    this.questions = const MonsterBowlQuestionEngine(),
  });

  static BigInt _choose(int n, int k) {
    if (k < 0 || k > n) {
      return BigInt.zero;
    }
    final smaller = k < n - k ? k : n - k;
    var value = BigInt.one;
    for (var i = 1; i <= smaller; i++) {
      value = (value * BigInt.from(n - smaller + i)) ~/ BigInt.from(i);
    }
    return value;
  }

  /// Return active-only completion counts after each legal active token.
  /// The first active color may close; any later color with one copy left
  /// cannot close before it. Prefix-sum binomial ratios avoid re-counting.
  static List<BigInt> _activeChildren(List<int> counts, BigInt base) {
    final size = counts.length;
    final sums = <int>[];
    var sum = 0;
    for (final count in counts) {
      sum += count;
      sums.add(sum);
    }
    final suffixNumerator = List<BigInt>.filled(size, BigInt.one);
    final suffixDenominator = List<BigInt>.filled(size, BigInt.one);
    for (var j = size - 2; j >= 0; j--) {
      suffixNumerator[j] = suffixNumerator[j + 1] * BigInt.from(sums[j]);
      suffixDenominator[j] =
          suffixDenominator[j + 1] * BigInt.from(sums[j + 1] - 1);
    }
    final result = List<BigInt>.filled(size, BigInt.zero);
    for (var j = 0; j < size; j++) {
      if (j > 0 && counts[j] == 1) {
        continue;
      }
      if (j == 0) {
        result[j] = (base * suffixNumerator[j]) ~/ suffixDenominator[j];
      } else {
        result[j] = (base * BigInt.from(counts[j] - 1) * suffixNumerator[j]) ~/
            (BigInt.from(sums[j] - 1) * suffixDenominator[j]);
      }
    }
    return result;
  }

  static BigInt _unopenedFactor(
    List<int> remaining,
    int opened,
    int nextActiveLength,
  ) {
    if (opened == remaining.length) {
      return BigInt.one;
    }
    final unopened = remaining.sublist(opened);
    if (nextActiveLength == 0) {
      return MonsterMonthWeaveCounter.countWholeWeaves(unopened);
    }
    return MonsterMonthWeaveCounter.countCompletions(
      <int>[nextActiveLength, ...unopened],
      openedUpTo: 1,
      closedUpTo: 0,
    );
  }

  /// One-based exact unrank for up to 47 colors and 5778 days.
  ///
  /// Unlike Discovery13, this method does not enforce a 24-day cap.
  /// A single unopened-color factor is computed per consumed active token.
  static List<int> unrankFull(List<int> monthLengths, BigInt rank) {
    final total = MonsterMonthWeaveCounter.countWholeWeaves(monthLengths);
    if (rank < BigInt.one || rank > total) {
      throw ArgumentError.value(rank, 'rank', 'Outside weave domain.');
    }

    final remaining = List<int>.of(monthLengths);
    final result = <int>[];
    var opened = 0;
    var closed = 0;
    var activeBase = BigInt.one;
    var ordinal = rank;
    final totalDays = remaining.fold<int>(0, (sum, n) => sum + n);

    for (var day = 0; day < totalDays; day++) {
      final active = remaining.sublist(closed, opened);
      final activeLength = active.fold<int>(0, (sum, n) => sum + n);
      var chosen = -1;
      BigInt? nextBase;
      if (active.isNotEmpty) {
        final childBases = _activeChildren(active, activeBase);
        // For rank 1, the first active token is necessarily lexicographically
        // minimal. Avoid a full unopened-factor calculation in this case.
        final factor = ordinal == BigInt.one
            ? BigInt.one
            : _unopenedFactor(remaining, opened, activeLength - 1);
        for (var i = 0; i < active.length; i++) {
          if (childBases[i] == BigInt.zero) {
            continue;
          }
          final block = childBases[i] * factor;
          if (ordinal > block) {
            ordinal -= block;
          } else {
            chosen = closed + i;
            nextBase = childBases[i];
            break;
          }
        }
      }
      if (chosen == -1) {
        if (opened >= remaining.length ||
            (remaining[opened] == 1 && activeLength > 0)) {
          throw StateError('§V lexicographic rank exhausted.');
        }
        chosen = opened;
        final newCopies = remaining[opened] - 1;
        nextBase = newCopies == 0
            ? activeBase
            : activeBase * _choose(activeLength + newCopies - 1, activeLength);
        opened++;
      }
      remaining[chosen]--;
      if (remaining[chosen] == 0) {
        if (chosen != closed) {
          throw StateError('§V out-of-order last occurrence.');
        }
        closed++;
      }
      activeBase = nextBase!;
      result.add(chosen + 1);
    }
    if (opened != monthLengths.length ||
        closed != monthLengths.length ||
        ordinal != BigInt.one) {
      throw StateError('§V rank did not exhaust the complete weave.');
    }
    return List<int>.unmodifiable(result);
  }

  /// Canonical §V selection: bowl 4, seal 32, on the same year sauce as §U.
  MonsterMonthWeavePlan plan(
    BigInt calculationDay,
    MonsterTraversedYear year,
    MonsterMonthLengthPlan lengths,
  ) {
    if (lengths.yearLength !=
        (year.candidate.closeGate - year.candidate.openGate).toInt()) {
      throw ArgumentError('§V requires the accepted §U year-length vector.');
    }
    final firstDay = year.candidate.openGate + BigInt.one;
    final work = const MonsterWorkCounter().calculate(
      calculationDay,
      firstDay,
    );
    final feeder = const MonsterSeedFeeder();
    final stones = feeder.buildStones();
    final feeds = feeder.buildHiddenFeeds(work, stones);
    final drops = const MonsterVisibleDropGenerator().buildVisibleDrops(
      counts: work,
      hiddenFeeds: feeds,
      stones: stones,
    );
    final bowls = const MonsterBowlProcessor().process(
      counts: work,
      visibleDrops: drops,
      stones: stones,
    );
    final count = MonsterMonthWeaveCounter.countWholeWeaves(lengths.lengths);
    final choice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 4,
        seal: 32,
      ),
      modulus: count,
    );
    return MonsterMonthWeavePlan._(
      weaveCount: count,
      weaveChoice: choice,
      monthIds: unrankFull(lengths.lengths, choice.result),
    );
  }
}
