import 'monster_meatball_gates.dart';

/// A candidate interval under README §P, not a selected or numbered year.
final class MonsterYearCandidate {
  final BigInt openOrdinal;
  final BigInt closeOrdinal;
  final BigInt openGate;
  final BigInt closeGate;
  final BigInt intervalCount;
  final BigInt length;
  final bool eligible;

  const MonsterYearCandidate({
    required this.openOrdinal,
    required this.closeOrdinal,
    required this.openGate,
    required this.closeGate,
    required this.intervalCount,
    required this.length,
    required this.eligible,
  });

  /// Geometric membership in (openGate, closeGate], even for an ineligible pair.
  bool contains(BigInt day) => openGate < day && day <= closeGate;
}

/// Bounded §P eligibility, deliberately without §Q year selection.
final class MonsterYearEligibility {
  static final BigInt minimumIntervals = BigInt.from(6);
  static final BigInt minimumLength = BigInt.from(252);
  static final BigInt maximumLength = BigInt.from(5778);
  static final BigInt prefixLimit = BigInt.from(32);

  final MonsterMeatballGateCalculator _gates;
  final Map<BigInt, BigInt> _positions = <BigInt, BigInt>{};

  MonsterYearEligibility({MonsterMeatballGateCalculator? gates})
      : _gates = gates ?? MonsterMeatballGateCalculator();

  MonsterYearCandidate inspect(BigInt openOrdinal, BigInt closeOrdinal) {
    if (openOrdinal >= closeOrdinal) {
      throw ArgumentError('Open gate ordinal must precede close ordinal.');
    }
    if (openOrdinal.abs() > prefixLimit ||
        closeOrdinal.abs() > prefixLimit) {
      throw RangeError('Year inspection requires gate ordinals -32..32.');
    }

    final open = _positions.putIfAbsent(
      openOrdinal,
      () => _gates.gatePosition(openOrdinal),
    );
    final close = _positions.putIfAbsent(
      closeOrdinal,
      () => _gates.gatePosition(closeOrdinal),
    );
    final intervals = closeOrdinal - openOrdinal;
    final length = close - open;
    return MonsterYearCandidate(
      openOrdinal: openOrdinal,
      closeOrdinal: closeOrdinal,
      openGate: open,
      closeGate: close,
      intervalCount: intervals,
      length: length,
      eligible: intervals >= minimumIntervals &&
          length >= minimumLength &&
          length <= maximumLength,
    );
  }
}
