module LegacyRemainder {
  use BigInteger;
  use ExactMath only M, regularMod;

  // Historical defect 01: ordinary modulo maps exact multiples of M to 0.
  // Unlike SAVE, this implementation deliberately does not lift 0 to M.
  proc oldRemainder(const ref x: bigint): bigint {
    return regularMod(x, M);
  }
}
