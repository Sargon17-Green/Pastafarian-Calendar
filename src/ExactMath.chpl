module ExactMath {
  use BigInteger;

  const M: bigint = (new bigint(1) << 127) - 1;
  const TABLETS_DAY: bigint = new bigint(-278522);
  const FOUNDATION_DAY: bigint = new bigint(-15055671);

  proc absBig(const ref x: bigint): bigint {
    if x < 0 then return -x;
    return x;
  }

  proc floorDiv(const ref a: bigint, const ref b: bigint): bigint {
    if b == 0 then halt("Ділення на нуль заборонене.");
    var q = a / b;
    const r = a % b;
    if r != 0 && ((r < 0) != (b < 0)) then q -= 1;
    return q;
  }

  proc regularMod(const ref x: bigint, const ref d: bigint): bigint {
    if d < 1 then halt("Модуль має бути додатним.");
    var r = x % d;
    if r < 0 then r += d;
    return r;
  }

  proc regularMod(const ref x: bigint, d: int): bigint {
    return regularMod(x, new bigint(d));
  }

  proc save(const ref x: bigint): bigint {
    return 1 + regularMod(x - 1, M);
  }

  proc square(const ref x: bigint): bigint {
    return x * x;
  }

  proc ceilDivNonNegative(const ref a: bigint, const ref b: bigint): bigint {
    if a < 0 || b < 1 then halt("ceilDiv вимагає невід’ємний чисельник і додатний знаменник.");
    return floorDiv(a + b - 1, b);
  }

  proc wrap1(position: int, size: int): int {
    if size < 1 then halt("Розмір циклу має бути додатним.");
    var r = (position - 1) % size;
    if r < 0 then r += size;
    return r + 1;
  }

  proc factorialBig(n: int): bigint {
    if n < 0 then halt("Факторіал від’ємного числа не визначено.");
    var out = new bigint(1);
    for i in 2..n do out *= i;
    return out;
  }

  proc fallingFactorialBig(n: int, k: int): bigint {
    if k < 0 || k > n then return new bigint(0);
    var out = new bigint(1);
    for j in 0..<k do out *= (n - j);
    return out;
  }
}
