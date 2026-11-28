import 'monster_meatball_gates.dart';
import 'monster_work_counts.dart';
import 'monster_year_eligibility.dart';

/// A §Q preview is never itself the canonical year-5000 selection.
final class MonsterYearPreview {
  final BigInt day;
  final List<MonsterYearCandidate> candidates;
  final bool complete;
  final List<String> missingBoundaries;

  const MonsterYearPreview._({
    required this.day,
    required this.candidates,
    required this.complete,
    required this.missingBoundaries,
  });

  bool get year5000Ready => false;

  /// Refuse to select from an unproven finite domain.
  void requireComplete() {
    if (!complete) {
      throw IncompleteMonsterYearDomain(missingBoundaries);
    }
  }
}

final class IncompleteMonsterYearDomain implements Exception {
  final List<String> missingBoundaries;

  const IncompleteMonsterYearDomain(this.missingBoundaries);

  @override
  String toString() => 'Incomplete §Q domain: ${missingBoundaries.join(", ")}';
}

/// Enumerates §Q independently of the §N bowl-selection operation.
final class MonsterYearLocator {
  static const int prefixLimit = MonsterMeatballGateCalculator.maxPrefixSteps;
  static final BigInt maximumLength = BigInt.from(5778);
  static final BigInt minimumLength = BigInt.from(252);

  final MonsterMeatballGateCalculator _gates;

  MonsterYearLocator({MonsterMeatballGateCalculator? gates})
      : _gates = gates ?? MonsterMeatballGateCalculator();

  /// Bounded real §O traversal. Strict external sentinels, not the step budget,
  /// decide completeness. gapFor is not constrained by gatePosition's prefix.
  /// With minimum gap 42 and maximum year length 5778, 138 intervals
  /// suffice to cross a 5778-day window when starting at its edge.
  MonsterYearPreview sentinelSearch(
    BigInt day, {
    int maximumIntervalsPerSide = 138,
  }) {
    if (maximumIntervalsPerSide < 1 || maximumIntervalsPerSide > 138) {
      throw RangeError.range(
        maximumIntervalsPerSide,
        1,
        138,
        'maximumIntervalsPerSide',
      );
    }
    final foundation = MonsterWorkCounter.foundationDay;
    final positions = <int, BigInt>{0: foundation};
    var left = foundation;
    var right = foundation;
    final leftCutoff = day - maximumLength;
    final rightCutoff = day + maximumLength - BigInt.one;
    for (var step = 1; step <= maximumIntervalsPerSide; step++) {
      if (left >= leftCutoff) {
        left -= _gates.gapFor(BigInt.from(-step)).length;
        positions[-step] = left;
      }
      if (right <= rightCutoff) {
        right += _gates.gapFor(BigInt.from(step)).length;
        positions[step] = right;
      }
      if (left < leftCutoff && right > rightCutoff) {
        break;
      }
    }
    return fromGateSnapshot(day, positions);
  }

  /// Exact bounded-memory traversal for production §Q.
  MonsterYearPreview streamingPreview(
    BigInt day, {
    int maximumGapCalls = 400000,
  }) =>
      fromGateSnapshot(
        day,
        streamGateWindow(
          day,
          MonsterWorkCounter.foundationDay,
          (ordinal) => _gates.gapFor(ordinal).length,
          maximumGapCalls: maximumGapCalls,
        ),
      );

  /// Only the nearest strict outside gates and intervening gates are retained.
  /// The callback supplies the actual signed §O gap, never ordinal zero.
  static Map<int, BigInt> streamGateWindow(
    BigInt day,
    BigInt foundation,
    BigInt Function(BigInt) gapFor, {
    required int maximumGapCalls,
  }) {
    if (maximumGapCalls < 1 || maximumGapCalls > 400000) {
      throw RangeError.range(maximumGapCalls, 1, 400000, 'maximumGapCalls');
    }
    final lower = day - maximumLength;
    final upper = day + maximumLength - BigInt.one;
    final minGap = BigInt.from(42);
    final maxGap = BigInt.from(963);
    const budgetFailure = IncompleteMonsterYearDomain(
      <String>['GAP_BUDGET_EXHAUSTED'],
    );
    // Even the largest possible gaps cannot reach the far strict sentinel.
    final reach = maxGap * BigInt.from(maximumGapCalls);
    if (foundation <= lower && foundation + reach <= upper ||
        foundation >= upper && foundation - reach >= lower) {
      throw budgetFailure;
    }

    var calls = 0;
    BigInt gap(int ordinal) {
      if (calls == maximumGapCalls) {
        throw budgetFailure;
      }
      calls++;
      final length = gapFor(BigInt.from(ordinal));
      if (length < minGap || length > maxGap) {
        throw StateError('§O gap outside 42..963.');
      }
      return length;
    }

    var index = 0;
    var position = foundation;
    final positions = <int, BigInt>{};
    if (foundation < lower) {
      // Approach from the left; discard only gates strictly before the
      // nearest left sentinel. Never evaluate a gap twice.
      while (position < lower) {
        final previous = position;
        position += gap(index + 1);
        index++;
        if (position >= lower) {
          positions[index - 1] = previous;
        }
      }
      positions[index] = position;
      while (position <= upper) {
        position += gap(index + 1);
        index++;
        positions[index] = position;
      }
    } else if (foundation > upper) {
      // Symmetric approach from the right. Backward gaps have negative
      // ordinals, and their lengths are subtracted.
      while (position > upper) {
        final previous = position;
        position -= gap(index - 1);
        index--;
        if (position <= upper) {
          positions[index + 1] = previous;
        }
      }
      positions[index] = position;
      while (position >= lower) {
        position -= gap(index - 1);
        index--;
        positions[index] = position;
      }
    } else {
      positions[0] = foundation;
      while (position >= lower) {
        position -= gap(index - 1);
        index--;
        positions[index] = position;
      }
      index = 0;
      position = foundation;
      while (position <= upper) {
        position += gap(index + 1);
        index++;
        positions[index] = position;
      }
    }
    if (positions.length > 278) {
      throw StateError('§Q streaming window exceeded the proven bound.');
    }
    return Map<int, BigInt>.unmodifiable(positions);
  }

  /// Traverse each signed §O gap once; no repeated quadratic gatePosition calls.
  MonsterYearPreview boundedPreview(
    BigInt day, {
    int lowerOrdinal = -8,
    int upperOrdinal = 8,
  }) {
    if (lowerOrdinal >= 0 ||
        upperOrdinal <= 0 ||
        lowerOrdinal < -prefixLimit ||
        upperOrdinal > prefixLimit) {
      throw RangeError('The prefix must straddle zero inside -32..32.');
    }
    final positions = <int, BigInt>{
      0: MonsterWorkCounter.foundationDay,
    };
    for (var i = 1; i <= upperOrdinal; i++) {
      positions[i] = positions[i - 1]! + _gates.gapFor(BigInt.from(i)).length;
    }
    for (var i = -1; i >= lowerOrdinal; i--) {
      positions[i] = positions[i + 1]! - _gates.gapFor(BigInt.from(i)).length;
    }
    return fromGateSnapshot(day, positions);
  }

  /// Testable pure §Q enumeration. Snapshot gate provenance is caller-owned.
  /// Complete is true ONLY with strict external sentinel gates on both sides.
  static MonsterYearPreview fromGateSnapshot(
    BigInt day,
    Map<int, BigInt> positions,
  ) {
    if (positions.length < 2 || positions.length > 450) {
      throw ArgumentError('A contiguous bounded gate snapshot is required.');
    }
    final ordinals = positions.keys.toList()..sort();
    final lower = ordinals.first;
    final upper = ordinals.last;
    if (upper - lower + 1 != positions.length) {
      throw ArgumentError('Missing gate ordinal in snapshot.');
    }
    for (var i = lower + 1; i <= upper; i++) {
      if (positions[i]! <= positions[i - 1]!) {
        throw ArgumentError('Gate positions must increase strictly.');
      }
    }

    final candidates = <MonsterYearCandidate>[];
    for (var i = lower; i < upper; i++) {
      final open = positions[i]!;
      if (open >= day || open < day - maximumLength) {
        continue;
      }
      for (var j = i + 6; j <= upper; j++) {
        final close = positions[j]!;
        final length = close - open;
        if (length > maximumLength) {
          break;
        }
        if (length < minimumLength || close < day) {
          continue;
        }
        final candidate = MonsterYearCandidate(
          openOrdinal: BigInt.from(i),
          closeOrdinal: BigInt.from(j),
          openGate: open,
          closeGate: close,
          intervalCount: BigInt.from(j - i),
          length: length,
          eligible: true,
        );
        if (candidate.contains(day)) {
          candidates.add(candidate);
        }
      }
    }
    candidates.sort((a, b) {
      final lengthOrder = a.length.compareTo(b.length);
      return lengthOrder != 0 ? lengthOrder : a.openGate.compareTo(b.openGate);
    });

    // Strict outside sentinels certify every excluded ordinal is too far.
    final leftSafe = positions[lower]! < day - maximumLength;
    final rightSafe = positions[upper]! > day + maximumLength - BigInt.one;
    final missing = <String>[
      if (!leftSafe) 'LEFT_SENTINEL_NOT_PROVEN',
      if (!rightSafe) 'RIGHT_SENTINEL_NOT_PROVEN',
    ];
    return MonsterYearPreview._(
      day: day,
      candidates: List<MonsterYearCandidate>.unmodifiable(candidates),
      complete: missing.isEmpty,
      missingBoundaries: List<String>.unmodifiable(missing),
    );
  }
}
