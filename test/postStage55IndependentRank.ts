/**
 * Test-only inverse lexicographic oracle for legally woven months.
 *
 * This deliberately DOES NOT call the production ScalableLegalWeavingUnrank,
 * ScalableLegalWeavingCounter or any production suffix distribution.
 * It ranks a supplied complete word via an insertion DP on positions of the
 * last appearance of the first month in every unopened suffix. Its proof is
 * independent of the production lastFirst(reverse)/factor/unrank algorithm.
 *
 * Bounds: <=47 months, <=5778 days, no exponential remaining-vector memo.
 */
function ensure(condition: boolean, message: string): void {
  if (!condition) throw new Error("INDEPENDENT_RANK: " + message);
}

function choose(n: number, k: number): bigint {
  if (k < 0 || k > n) return 0n;
  const z = Math.min(k, n - k);
  let result = 1n;
  for (let i = 1; i <= z; i++) {
    result = result * BigInt(n - z + i) / BigInt(i);
  }
  return result;
}

export class IndependentLegalWeavingRank {
  private readonly sizes: readonly number[];
  private readonly last: readonly (readonly bigint[])[];
  private readonly factors = new Map<string, bigint>();
  private readonly n: number;
  readonly totalDays: number;
  private suffixQueries = 0;
  private factorTerms = 0;

  constructor(monthLengths: readonly bigint[]) {
    ensure(monthLengths.length >= 2 && monthLengths.length <= 47,
      "month-count bound");
    ensure(monthLengths.every(x => typeof x === "bigint" && x >= 1n && x <= 123n),
      "positive month lengths <=123");
    const sizes = monthLengths.map(Number);
    const total = sizes.reduce((a, b) => a + b, 0);
    ensure(total <= 5778, "year-days bound");
    this.sizes = sizes;
    this.n = sizes.length;
    this.totalDays = total;

    // P[a][k] counts valid legal words over unopened IDs a..n-1
    // whose first ID a has its FINAL appearance at 1-based position k.
    // Construct by inserting smaller IDs at the front of larger-ID words,
    // *not* by reversing the production last-first distribution.
    const p: bigint[][] = Array.from({length: this.n}, () => []);
    let tailLength = sizes[this.n - 1]!;
    p[this.n - 1] = Array<bigint>(tailLength + 1).fill(0n);
    p[this.n - 1]![tailLength] = 1n;
    for (let a = this.n - 2; a >= 0; a--) {
      const h = sizes[a]!;
      const tail = p[a + 1]!;
      const sums = Array<bigint>(tailLength + 2).fill(0n);
      for (let k = tailLength; k >= 1; k--) {
        sums[k] = sums[k + 1]! + (tail[k] ?? 0n);
      }
      const out = Array<bigint>(tailLength + h + 1).fill(0n);
      // Insert h copies of a into gaps BEFORE the last copy of a+1.
      // First a must precede first a+1. If final a lies in gap g>0,
      // allocating copies among g+1 gaps with first/last nonempty gives
      // C(h+g-2,g) possibilities; g=0 gives exactly one possibility.
      let coefficient = 1n;
      for (let g = 0; g < tailLength; g++) {
        if (g > 0) coefficient = coefficient * BigInt(h + g - 2) / BigInt(g);
        out[h + g] = coefficient * sums[g + 1]!;
      }
      p[a] = out;
      tailLength += h;
    }
    this.last = p;
  }

  // H(a,S): number of shuffles of S already-open copies with a valid
  // unopened suffix a..n-1; the active block must finish before the final
  // occurrence of a. Stars-and-bars inserts the S copies into k gaps.
  private tailFactor(a: number, activeCopies: number): bigint {
    if (a === this.n) return 1n;
    const key = a + ":" + activeCopies;
    const cached = this.factors.get(key);
    if (cached !== undefined) return cached;
    const distribution = this.last[a]!;
    let bin = 1n;
    let sum = 0n;
    for (let k = 1; k < distribution.length; k++) {
      sum += distribution[k]! * bin;
      this.factorTerms++;
      // Next k: C(S+k,S) = C(S+k-1,S)*(S+k)/k.
      bin = bin * BigInt(activeCopies + k) / BigInt(k);
    }
    this.factors.set(key, sum);
    return sum;
  }

  private activeTransition(
    left: readonly number[], j: number, opened: number,
    S: number, B: bigint, afterNumerator: readonly bigint[],
    afterDenominator: readonly bigint[], cumulative: readonly number[]
  ): bigint {
    if (j === opened) {
      const h = left[j]!;
      const Snext = S + h - 1;
      const Bnext = B * choose(Snext - 1, h - 2);
      return Bnext;
    }
    const r = left[j]!;
    const num = afterNumerator[j + 1]! * BigInt(r === 1 ? 1 : r - 1);
    const den = afterDenominator[j + 1]! * BigInt(r === 1 ? 1 : cumulative[j]! - 1);
    ensure(den !== 0n, "active transition positive denominator");
    const numerator = B * num;
    ensure(numerator % den === 0n, "active transition exact rational");
    const Bnext = numerator / den;
    return Bnext;
  }

  /** Rank a legal prefix; its completion ranks occupy [firstRank,firstRank+count). */
  rankPrefix(word: readonly number[], prefixLength: number = word.length): Readonly<{firstRank: bigint;count: bigint}> {
    ensure(word.length === this.totalDays && Number.isSafeInteger(prefixLength) &&
      prefixLength >= 1 && prefixLength <= this.totalDays, "full-year word/prefix length");
    const left = [...this.sizes];
    let opened = 0, closed = 0, S = 0;
    let B = 1n, rank = 1n;
    for (let day = 0; day < prefixLength; day++) {
      const chosen = word[day]!;
      ensure(Number.isSafeInteger(chosen) && chosen >= 1 && chosen <= this.n,
        "month ID range at day " + (day + 1));
      const cumulative = Array<number>(opened + 1).fill(0);
      let rolling = 0;
      for (let j = closed; j < opened; j++) {
        rolling += left[j]!;
        cumulative[j] = rolling;
      }
      ensure(rolling === S, "active copy count");
      const afterNumerator = Array<bigint>(opened + 1).fill(1n);
      const afterDenominator = Array<bigint>(opened + 1).fill(1n);
      for (let j = opened - 1; j > closed; j--) {
        afterNumerator[j] = afterNumerator[j + 1]! * BigInt(cumulative[j]! - left[j]!);
        afterDenominator[j] = afterDenominator[j + 1]! * BigInt(cumulative[j]! - 1);
      }
      let chosenTransition: bigint | null = null;
      for (let id = closed + 1; id <= chosen; id++) {
        const j = id - 1;
        const r = left[j]!;
        if (r === 0 || j > opened || (j === opened && r !== this.sizes[j]) ||
            (j < opened && r === this.sizes[j]) || (r === 1 && j !== closed)) continue;
        const transition = this.activeTransition(left,j,opened,S,B,
          afterNumerator,afterDenominator,cumulative);
        this.suffixQueries++;
        if (id < chosen) {
          const afterS = j === opened ? S + r - 1 : S - 1;
          const afterOpened = opened + (j === opened ? 1 : 0);
          rank += transition * this.tailFactor(afterOpened,afterS);
        } else chosenTransition = transition;
      }
      ensure(chosenTransition !== null,
        "first/last appearance order at day " + (day + 1));
      const j = chosen - 1;
      const r = left[j]!;
      B = chosenTransition!;
      left[j] = r - 1;
      if (j === opened) {opened++;S += r - 1;}
      else S--;
      if (r === 1) closed++;
    }
    const span = B * this.tailFactor(opened,S);
    if (prefixLength === this.totalDays) {
      ensure(opened === this.n && closed === this.n && left.every(x => x === 0),
        "all month counts and first/last appearances consumed");
      ensure(B === 1n && S === 0 && span === 1n, "terminal active count");
    }
    return {firstRank:rank,count:span};
  }

  rankWord(word: readonly number[]): bigint {
    return this.rankPrefix(word).firstRank;
  }

  count(): bigint {
    return this.tailFactor(0, 0);
  }

  statistics(): Readonly<{suffixQueries: number;cachedFactors: number;factorTerms: number}> {
    return Object.freeze({suffixQueries: this.suffixQueries,
      cachedFactors: this.factors.size, factorTerms: this.factorTerms});
  }
}
