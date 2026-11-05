/// §V discovery: exact counts of admissible suffix weaves, not a completed
/// canonical month weave. This is an independent color-insertion algorithm.
///
/// A suffix has a contiguous active block of previously opened month IDs
/// (closedUpTo+1 .. openedUpTo), followed by unopened IDs. The last occurrence
/// of all remaining IDs must respect ascending canonical order.
final class MonsterMonthWeaveCounter {
  static const int maximumMonths = 47;
  static const int maximumDays = 5778;
  static const int discoveryUnrankLimit = 24;

  const MonsterMonthWeaveCounter();

  static BigInt _choose(int n, int k) {
    if (k < 0 || k > n) {
      return BigInt.zero;
    }
    final count = k < n - k ? k : n - k;
    var result = BigInt.one;
    for (var i = 1; i <= count; i++) {
      result = (result * BigInt.from(n - count + i)) ~/ BigInt.from(i);
    }
    return result;
  }

  /// Insert k indistinguishable new letters after r of the N old letters.
  /// The final gap must contain a new letter to preserve last-occurrence order.
  /// weight[d] = C(k+d-2,d), where d=N-r. For k=1 only d=0 is possible.
  static List<BigInt> _insertionWeights(int previousLength, int k) {
    final result = List<BigInt>.filled(previousLength + 1, BigInt.zero);
    result[0] = BigInt.one;
    if (k == 1) {
      return result;
    }
    for (var d = 1; d <= previousLength; d++) {
      result[d] = (result[d - 1] * BigInt.from(k + d - 2)) ~/ BigInt.from(d);
    }
    return result;
  }

  static void _checkPrefixState(
    List<int> remaining,
    int openedUpTo,
    int closedUpTo,
  ) {
    final months = remaining.length;
    if (months < 1 || months > maximumMonths) {
      throw RangeError.range(months, 1, maximumMonths, 'months');
    }
    if (closedUpTo < 0 || openedUpTo < closedUpTo || openedUpTo > months) {
      throw ArgumentError('Invalid opened/closed prefix counters.');
    }
    var days = 0;
    for (var i = 0; i < months; i++) {
      final count = remaining[i];
      if (i < closedUpTo && count != 0) {
        throw ArgumentError('Completed month still has remaining days.');
      }
      if (i >= closedUpTo && count <= 0) {
        throw ArgumentError('Unclosed month has no remaining days.');
      }
      days += count;
    }
    if (days > maximumDays) {
      throw RangeError.range(days, 0, maximumDays, 'remainingDays');
    }
  }

  /// Count valid suffixes without enumerating words or vector-valued states.
  ///
  /// Base active months are unrestricted by first occurrence (they were
  /// opened in the consumed prefix), but must finish in ascending order.
  /// Each unopened month is inserted later than the first occurrence of the
  /// previous unopened month, and its last occurrence is the final token.
  ///
  /// The only DP dimension is the first position of the highest added ID.
  /// Each insertion step is O(current remaining length), with BigInt counts.
  static BigInt countCompletions(
    List<int> remaining, {
    required int openedUpTo,
    required int closedUpTo,
  }) {
    _checkPrefixState(remaining, openedUpTo, closedUpTo);
    final months = remaining.length;
    if (closedUpTo == months) {
      return BigInt.one;
    }

    var length = 0;
    var firstUnopened = openedUpTo;
    var base = BigInt.one;
    List<BigInt> distribution;

    if (openedUpTo > closedUpTo) {
      // Count active-only words with ascending last occurrences.
      length = remaining[closedUpTo];
      for (var i = closedUpTo + 1; i < openedUpTo; i++) {
        final k = remaining[i];
        base *= _choose(length + k - 1, length);
        length += k;
      }
      if (openedUpTo == months) {
        return base;
      }

      // First unopened month has no first-order restriction against an
      // active month, whose first occurrence was in the earlier prefix.
      final k = remaining[openedUpTo];
      final weights = _insertionWeights(length, k);
      distribution = List<BigInt>.filled(length + k + 1, BigInt.zero);
      for (var oldPosition = 0; oldPosition <= length; oldPosition++) {
        distribution[oldPosition + 1] = base * weights[length - oldPosition];
      }
      length += k;
      firstUnopened++;
    } else {
      // There is no active month; the first unopened month begins the suffix.
      length = remaining[openedUpTo];
      distribution = List<BigInt>.filled(length + 1, BigInt.zero);
      distribution[1] = BigInt.one;
      firstUnopened++;
    }

    for (var i = firstUnopened; i < months; i++) {
      final k = remaining[i];
      final weights = _insertionWeights(length, k);
      final next = List<BigInt>.filled(length + k + 1, BigInt.zero);
      var prefixCount = BigInt.zero;
      for (var oldPosition = 0; oldPosition <= length; oldPosition++) {
        prefixCount += distribution[oldPosition];
        next[oldPosition + 1] = prefixCount * weights[length - oldPosition];
      }
      distribution = next;
      length += k;
    }

    var total = BigInt.zero;
    for (final count in distribution) {
      total += count;
    }
    return total;
  }

  static BigInt countWholeWeaves(List<int> monthLengths) {
    return countCompletions(
      monthLengths,
      openedUpTo: 0,
      closedUpTo: 0,
    );
  }

  /// Research-only lexicographic unranking. Production-scale §V unranking is
  /// deliberately NOT claimed: canonical years exceed this bounded contract.
  static List<int> unrankDiscovery(
    List<int> monthLengths,
    BigInt rank,
  ) {
    final totalDays = monthLengths.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (totalDays > discoveryUnrankLimit) {
      throw UnsupportedError(
        '§V full-year unranking is not yet accepted; discovery cap is 24.',
      );
    }
    final total = countWholeWeaves(monthLengths);
    if (rank < BigInt.one || rank > total) {
      throw ArgumentError.value(rank, 'rank', 'Outside weave domain.');
    }

    final remaining = List<int>.of(monthLengths);
    final result = <int>[];
    var opened = 0;
    var closed = 0;
    var current = rank;
    for (var day = 0; day < totalDays; day++) {
      var selected = false;
      for (var index = 0; index < remaining.length; index++) {
        final id = index + 1;
        if (remaining[index] == 0 || id > opened + 1) {
          continue;
        }
        if (remaining[index] == 1 && id != closed + 1) {
          continue;
        }
        remaining[index]--;
        final nextOpened = id == opened + 1 ? opened + 1 : opened;
        final nextClosed = remaining[index] == 0 ? closed + 1 : closed;
        final suffixCount = countCompletions(
          remaining,
          openedUpTo: nextOpened,
          closedUpTo: nextClosed,
        );
        if (current > suffixCount) {
          current -= suffixCount;
          remaining[index]++;
          continue;
        }
        result.add(id);
        opened = nextOpened;
        closed = nextClosed;
        selected = true;
        break;
      }
      if (!selected) {
        throw StateError('§V discovery rank exhausted.');
      }
    }
    if (closed != monthLengths.length || current != BigInt.one) {
      throw StateError('§V discovery rank did not terminate.');
    }
    return List<int>.unmodifiable(result);
  }
}
