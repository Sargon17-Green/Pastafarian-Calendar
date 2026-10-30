module LegacyDayTag {
  use BigInteger;
  use ExactMath only FOUNDATION_DAY, absBig;

  // Етап 4: історичний дефект. Для F і днів після F
  // ця функція втрачає непарну компоненту; виправлення не тут.
  proc oldDayTag(const ref candidateDay: bigint): bigint {
    return 2 * absBig(candidateDay - FOUNDATION_DAY);
  }
}
