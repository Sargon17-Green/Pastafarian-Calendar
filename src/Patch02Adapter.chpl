module Patch02Adapter {
  use BigInteger;
  use ExactMath only FOUNDATION_DAY;

  // Латка 02 відновлює непарний тег після дня заснування.
  // Історичний oldDayTag та Discovery 02 не змінюються.
  proc applyPatch02(const ref legacyDayTag: bigint,
                    const ref candidateDay: bigint): bigint {
    if legacyDayTag < 0 then
      halt("Латка 02 отримала від'ємний історичний тег.");
    if candidateDay >= FOUNDATION_DAY then return legacyDayTag + 1;
    return legacyDayTag;
  }
}
