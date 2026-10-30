module LegacyRemainder {
  use BigInteger;
  use ExactMath only M, regularMod;

  // Історичний дефект 01: звичайна остача від кратних M дорівнює нулю.
  // На відміну від SAVE, тут навмисно не замінюємо 0 на M.
  proc oldRemainder(const ref x: bigint): bigint {
    return regularMod(x, M);
  }
}
