final class MonsterWorkCounts {
  final BigInt action;
  final BigInt target;
  final BigInt distance;
  final BigInt connection;
  final int direction;

  const MonsterWorkCounts({
    required this.action,
    required this.target,
    required this.distance,
    required this.connection,
    required this.direction,
  });
}

/// Independent production implementation of Stage 2 work counts.
/// This module does not depend on the normative test oracle.
final class MonsterWorkCounter {
  static final BigInt foundationDay = BigInt.from(-15055671);

  const MonsterWorkCounter();

  /// One-based enumeration: foundation, yesterday, tomorrow, and so on.
  BigInt dayRank(BigInt day) {
    final displacement = day - foundationDay;
    final pairRank = displacement.abs() << 1;
    return displacement.isNegative ? pairRank : pairRank + BigInt.one;
  }

  MonsterWorkCounts calculate(BigInt calculationDay, BigInt targetDay) {
    final actionRank = dayRank(calculationDay);
    final targetRank = dayRank(targetDay);
    final displacement = targetDay - calculationDay;
    final comparison = targetDay.compareTo(calculationDay);
    return MonsterWorkCounts(
      action: actionRank,
      target: targetRank,
      distance: displacement.abs() + BigInt.one,
      connection: actionRank + targetRank,
      direction: comparison + 2,
    );
  }
}
