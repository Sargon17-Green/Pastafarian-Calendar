module Patch01Adapter {
  use BigInteger;
  use ExactMath only M;

  // Латка 01 піднімає нульовий залишок до M.
  // Історичний oldRemainder залишається незмінним.
  proc applyPatch01(const ref legacyRemainder: bigint): bigint {
    if legacyRemainder < 0 || legacyRemainder >= M then
      halt("Латка 01 отримала залишок поза межами [0, M).");
    if legacyRemainder == 0 then return M;
    return legacyRemainder;
  }
}
