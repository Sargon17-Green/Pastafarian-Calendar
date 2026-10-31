/// Exact modular arithmetic for the bounded Stage 2 production pipeline.
/// This code uses Dart BigInt primitives, never the normative test oracle.
final class MonsterModularMath {
  static final BigInt modulus = (BigInt.one << 127) - BigInt.one;

  const MonsterModularMath();

  /// The mathematical floor of a / b, including negative divisors.
  BigInt floorDiv(BigInt dividend, BigInt divisor) {
    if (divisor == BigInt.zero) {
      throw ArgumentError('Division by zero.');
    }
    final numerator = divisor.isNegative ? -dividend : dividend;
    final positiveDivisor = divisor.abs();
    final residue = numerator % positiveDivisor;
    return (numerator - residue) ~/ positiveDivisor;
  }

  /// The Euclidean residue in [0, divisor), for positive divisor.
  BigInt regularMod(BigInt value, BigInt divisor) {
    if (divisor <= BigInt.zero) {
      throw ArgumentError('Modulus must be positive.');
    }
    return value % divisor;
  }

  /// The canonical representative in [1, 2^127 - 1].
  BigInt save(BigInt value) {
    return regularMod(value - BigInt.one, modulus) + BigInt.one;
  }

  BigInt square(BigInt value) => value * value;

  /// The mathematical ceiling for a nonnegative dividend and positive b.
  BigInt ceilDiv(BigInt dividend, BigInt divisor) {
    if (dividend.isNegative || divisor <= BigInt.zero) {
      throw ArgumentError('Ceiling division requires a >= 0 and b > 0.');
    }
    return -floorDiv(-dividend, divisor);
  }
}
