import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';
import 'monster_year_traversal.dart';

/// README §U only: month counts and bounded lengths, not the §V weave.
final class MonsterMonthLengthPlan {
  final int yearLength;
  final int minMonths;
  final int maxMonths;
  final int monthCount;
  final BigInt lengthSequenceCount;
  final MonsterEqualChoice monthCountChoice;
  final MonsterEqualChoice lengthChoice;
  final List<int> lengths;

  MonsterMonthLengthPlan._({
    required this.yearLength,
    required this.minMonths,
    required this.maxMonths,
    required this.monthCount,
    required this.lengthSequenceCount,
    required this.monthCountChoice,
    required this.lengthChoice,
    required List<int> lengths,
  }) : lengths = List<int>.unmodifiable(lengths);
}

/// Independent iterative sliding-window DP, with exact BigInt ranks.
final class MonsterMonthLengthPlanner {
  static const int minLength = 4;
  static const int maxLength = 123;
  static const int maxMonths = 47;
  static const int maxYearLength = 5778;

  final MonsterBowlQuestionEngine questions;

  const MonsterMonthLengthPlanner({
    this.questions = const MonsterBowlQuestionEngine(),
  });

  static int minimumMonthCount(int yearLength) {
    _validateDays(yearLength);
    final byLength = (yearLength + maxLength - 1) ~/ maxLength;
    return byLength > 3 ? byLength : 3;
  }

  static int maximumMonthCount(int yearLength) {
    _validateDays(yearLength);
    final byLength = yearLength ~/ minLength;
    return byLength < maxMonths ? byLength : maxMonths;
  }

  static void _validateDays(int yearLength) {
    if (yearLength < 0 || yearLength > maxYearLength) {
      throw RangeError.range(yearLength, 0, maxYearLength, 'yearLength');
    }
  }

  static void _validateDomain(int yearLength, int monthCount) {
    _validateDays(yearLength);
    if (monthCount < 3 || monthCount > maxMonths) {
      throw RangeError.range(monthCount, 3, maxMonths, 'monthCount');
    }
  }

  /// rows[k][s] counts ordered k-tuples in [4,123] summing to s.
  /// Each row uses a 120-wide rolling window, not exponential search.
  static List<List<BigInt>> _counts(int days, int months) {
    final rows = List<List<BigInt>>.generate(
      months + 1,
      (_) => List<BigInt>.filled(days + 1, BigInt.zero),
    );
    rows[0][0] = BigInt.one;
    for (var k = 1; k <= months; k++) {
      final previous = rows[k - 1];
      final current = rows[k];
      var window = BigInt.zero;
      for (var sum = 0; sum <= days; sum++) {
        if (sum >= minLength) {
          window += previous[sum - minLength];
        }
        if (sum > maxLength) {
          window -= previous[sum - maxLength - 1];
        }
        current[sum] = window;
      }
    }
    return rows;
  }

  static BigInt countLengthVectors(int yearLength, int monthCount) {
    _validateDomain(yearLength, monthCount);
    return _counts(yearLength, monthCount)[monthCount][yearLength];
  }

  /// Exact lexicographic one-based unrank by independent suffix block sizes.
  static List<int> unrankLengthVector(
    int yearLength,
    int monthCount,
    BigInt rank,
  ) {
    _validateDomain(yearLength, monthCount);
    final counts = _counts(yearLength, monthCount);
    return _unrank(yearLength, monthCount, rank, counts);
  }

  static List<int> _unrank(
    int yearLength,
    int monthCount,
    BigInt rank,
    List<List<BigInt>> counts,
  ) {
    final total = counts[monthCount][yearLength];
    if (rank < BigInt.one || rank > total) {
      throw ArgumentError.value(rank, 'rank', 'Outside month-length domain.');
    }
    final vector = <int>[];
    var remainingDays = yearLength;
    var remainingMonths = monthCount;
    var ordinal = rank;
    while (remainingMonths > 0) {
      var found = false;
      for (var candidate = minLength; candidate <= maxLength; candidate++) {
        if (candidate > remainingDays) {
          break;
        }
        final block = counts[remainingMonths - 1][remainingDays - candidate];
        if (ordinal > block) {
          ordinal -= block;
          continue;
        }
        vector.add(candidate);
        remainingDays -= candidate;
        remainingMonths--;
        found = true;
        break;
      }
      if (!found) {
        throw StateError('§U month-length unranking exhausted.');
      }
    }
    if (remainingDays != 0 || ordinal != BigInt.one) {
      throw StateError('§U month-length rank did not exhaust domain.');
    }
    return List<int>.unmodifiable(vector);
  }

  MonsterMonthLengthPlan plan(
    BigInt calculationDay,
    MonsterTraversedYear year,
  ) {
    final candidate = year.candidate;
    final length = candidate.closeGate - candidate.openGate;
    if (length < BigInt.from(252) || length > BigInt.from(maxYearLength)) {
      throw StateError('§U requires a proved 252..5778-day year.');
    }
    final days = length.toInt();
    final smallest = minimumMonthCount(days);
    final largest = maximumMonthCount(days);
    if (smallest > largest) {
      throw StateError('§U month-count domain is empty.');
    }
    final firstDay = candidate.openGate + BigInt.one;
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
    final monthCountChoice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 3,
        seal: 30,
      ),
      modulus: BigInt.from(largest - smallest + 1),
    );
    final monthCount = smallest + monthCountChoice.result.toInt() - 1;
    final counts = _counts(days, monthCount);
    final vectorCount = counts[monthCount][days];
    if (vectorCount <= BigInt.zero) {
      throw StateError('§U chosen month-count has no valid lengths.');
    }
    final lengthChoice = questions.chooseEqual(
      sequence: questions.createAnswerSequence(
        bowls: bowls,
        bowlId: 3,
        seal: 31,
      ),
      modulus: vectorCount,
    );
    return MonsterMonthLengthPlan._(
      yearLength: days,
      minMonths: smallest,
      maxMonths: largest,
      monthCount: monthCount,
      lengthSequenceCount: vectorCount,
      monthCountChoice: monthCountChoice,
      lengthChoice: lengthChoice,
      lengths: _unrank(days, monthCount, lengthChoice.result, counts),
    );
  }
}
