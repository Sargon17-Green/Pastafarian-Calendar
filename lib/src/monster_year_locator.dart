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
      positions[i] =
          positions[i - 1]! + _gates.gapFor(BigInt.from(i)).length;
    }
    for (var i = -1; i >= lowerOrdinal; i--) {
      positions[i] =
          positions[i + 1]! - _gates.gapFor(BigInt.from(i)).length;
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
      return lengthOrder != 0
          ? lengthOrder
          : a.openGate.compareTo(b.openGate);
    });

    // Strict outside sentinels certify every excluded ordinal is too far.
    final leftSafe = positions[lower]! < day - maximumLength;
    final rightSafe =
        positions[upper]! > day + maximumLength - BigInt.one;
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
