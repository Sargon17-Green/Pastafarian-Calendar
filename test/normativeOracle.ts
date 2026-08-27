import { cutletNameByCanonicalIndex, monthNameByCanonicalIndex } from "../src/sourceLanguageCatalog.ts";

export const TABLETS_DAY = -278522n;
export const FOUNDATION_DAY = -15055671n;
export const M = (1n << 127n) - 1n;
export const GATE_GAP_MIN = 42n;
export const GATE_GAP_MAX = 963n;
export const YEAR_MIN_DAYS = 252n;
export const YEAR_MAX_DAYS = 5778n;
export const MIN_GATE_GAPS_PER_YEAR = 6n;
export const MIN_CUTLETS = 6;
export const MAX_CUTLETS = 17;
export const MIN_MONTHS = 3;
export const MAX_MONTHS = 47;
export const MIN_MONTH_DAYS = 4n;
export const MAX_MONTH_DAYS = 123n;

const SEAL_GATE_GAP = 1n;
const SEAL_YEAR_5000 = 10n;
const SEAL_NEXT_YEAR = 11n;
const SEAL_PREVIOUS_YEAR = 12n;
const SEAL_CUTLET_COUNT = 20n;
const SEAL_CUTLET_PARTITION = 21n;
const SEAL_CUTLET_NAMES = 22n;
const SEAL_MONTH_COUNT = 30n;
const SEAL_MONTH_LENGTHS = 31n;
const SEAL_MONTH_WEAVING = 32n;
const SEAL_MONTH_NAMES = 33n;

const WHEAT = 0;
const BARLEY = 1;
const SALT = 2;
const BITTER = 3;
const RED = 4;

type Stone = readonly [bigint, bigint, bigint, bigint, bigint];
type Bowls = [bigint, bigint, bigint, bigint, bigint, bigint];

export type WorkCounts = Readonly<{
  action: bigint;
  target: bigint;
  distance: bigint;
  connection: bigint;
  direction: bigint;
}>;

export type SauceResult = Readonly<{
  bowls: readonly bigint[];
  orderAtDrop46: readonly number[];
}>;

export type AnswerStream = Readonly<{
  first: bigint;
  directionStep: 1n | -1n;
}>;

export type Year = Readonly<{
  number: bigint;
  openGateIndex: bigint;
  closeGateIndex: bigint;
  openGateDay: bigint;
  closeGateDay: bigint;
}>;

export type Cutlet = Readonly<{
  canonicalIndex: number;
  openGateIndex: bigint;
  closeGateIndex: bigint;
  firstDay: bigint;
  lastDay: bigint;
}>;

export type YearStructure = Readonly<{
  cutletCount: number;
  cutletPartition: readonly bigint[];
  cutletCanonicalIndices: readonly number[];
  cutlets: readonly Cutlet[];
  monthCount: number;
  monthLengths: readonly bigint[];
  monthWeaving: readonly number[];
  monthCanonicalIndices: readonly number[];
}>;

export type NormativeDate = readonly [bigint, string, bigint, string, bigint];

export function floorDiv(a: bigint, b: bigint): bigint {
  if (b <= 0n) throw new RangeError("भाजक धन पूर्णांक असला पाहिजे");
  const q = a / b;
  const r = a % b;
  return r < 0n ? q - 1n : q;
}

export function regularMod(x: bigint, d: bigint): bigint {
  if (d < 1n) throw new RangeError("मोड्युलस किमान एक असला पाहिजे");
  return x - floorDiv(x, d) * d;
}

export function SAVE(x: bigint): bigint {
  return 1n + regularMod(x - 1n, M);
}

export function ceilDiv(a: bigint, b: bigint): bigint {
  if (a < 0n || b < 1n) throw new RangeError("सीलिंग भागाकारासाठी अवैध पूर्णांक");
  return floorDiv(a + b - 1n, b);
}

export function wrap1(position: number, size: number): number {
  if (size < 1) throw new RangeError("आकार किमान एक असला पाहिजे");
  const p = BigInt(position);
  const s = BigInt(size);
  return Number(regularMod(p - 1n, s) + 1n);
}

export function dayCount(day: bigint): bigint {
  if (day === FOUNDATION_DAY) return 1n;
  if (day > FOUNDATION_DAY) return 2n * (day - FOUNDATION_DAY) + 1n;
  return 2n * (FOUNDATION_DAY - day);
}

export function workCounts(calculationDay: bigint, targetDay: bigint): WorkCounts {
  const action = dayCount(calculationDay);
  const target = dayCount(targetDay);
  const distance = (targetDay >= calculationDay ? targetDay - calculationDay : calculationDay - targetDay) + 1n;
  const connection = action + target;
  const direction = targetDay < calculationDay ? 1n : targetDay === calculationDay ? 2n : 3n;
  return Object.freeze({ action, target, distance, connection, direction });
}

export function buildStones(): readonly Stone[] {
  const table: Stone[] = [];
  table[1] = [17n, 29n, 43n, 71n, 101n];
  for (let i = 2; i <= 46; i += 1) {
    const old = table[i - 1]!;
    table[i] = [
      SAVE(old[WHEAT] * old[WHEAT] + 3n * old[BARLEY] + BigInt(i)),
      SAVE(old[BARLEY] * old[BARLEY] + 5n * old[SALT] + old[WHEAT]),
      SAVE(old[SALT] * old[SALT] + 7n * old[BITTER] + old[BARLEY]),
      SAVE(old[BITTER] * old[BITTER] + 11n * old[RED] + old[SALT]),
      SAVE(old[RED] * old[RED] + 13n * old[WHEAT] + old[BITTER])
    ];
  }
  return Object.freeze(table);
}

export const STONES = buildStones();

const HIDDEN_COEFF: readonly (readonly [bigint, bigint, bigint, bigint])[] = Object.freeze([
  [0n, 0n, 0n, 0n],
  [3n, 4n, 6n, 8n],
  [5n, 7n, 10n, 12n],
  [7n, 10n, 14n, 16n],
  [9n, 13n, 18n, 20n],
  [11n, 16n, 22n, 24n],
  [13n, 19n, 26n, 28n],
  [15n, 22n, 30n, 32n]
]);

const HIDDEN_GRIND_STONE = [WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY] as const;

export function buildHiddenDrops(counts: WorkCounts, stones: readonly Stone[] = STONES): readonly bigint[] {
  const hidden: bigint[] = [];
  for (let k = 1; k <= 7; k += 1) {
    const [a, b, c, d] = HIDDEN_COEFF[k]!;
    const stone = stones[k]!;
    let x = counts.action + a * counts.target + b * counts.distance + c * counts.connection + d * counts.direction
      + stone[WHEAT] + stone[BARLEY] + stone[SALT] + stone[BITTER] + stone[RED];
    x = SAVE(x);
    for (let grind = 1; grind <= 7; grind += 1) {
      const oldX = x;
      const kind = HIDDEN_GRIND_STONE[grind - 1]!;
      x = SAVE(oldX * oldX + 3n * oldX + stone[kind] + BigInt(grind));
    }
    hidden[k] = x;
  }
  return Object.freeze(hidden);
}

const VISIBLE_GRINDS = Object.freeze([
  [3n, 5n, 7n, 11n, WHEAT],
  [5n, 7n, 11n, 13n, BARLEY],
  [7n, 11n, 13n, 17n, SALT],
  [11n, 13n, 17n, 19n, BITTER],
  [13n, 17n, 19n, 23n, RED],
  [17n, 19n, 23n, 29n, WHEAT],
  [19n, 23n, 29n, 31n, BARLEY],
  [23n, 29n, 31n, 37n, SALT],
  [29n, 31n, 37n, 41n, BITTER],
  [31n, 37n, 41n, 43n, RED],
  [37n, 41n, 43n, 47n, WHEAT]
] as const);

export function buildVisibleDrops(counts: WorkCounts, stones: readonly Stone[], hidden: readonly bigint[]): readonly bigint[] {
  const timeline = new Map<number, bigint>();
  for (let k = 1; k <= 7; k += 1) timeline.set(1 - k, hidden[k]!);
  const visible: bigint[] = [];
  for (let i = 1; i <= 46; i += 1) {
    const prev1 = timeline.get(i - 1)!;
    const prev3 = timeline.get(i - 3)!;
    const prev7 = timeline.get(i - 7)!;
    const stone = stones[i]!;
    let x = SAVE(
      stone[WHEAT] * counts.action + stone[BARLEY] * counts.target + stone[SALT] * counts.distance
      + stone[BITTER] * counts.connection + stone[RED] * counts.direction
      + prev1 + 3n * prev3 + 5n * prev7 + BigInt(i)
    );
    for (const [a, b, c, d, kind] of VISIBLE_GRINDS) {
      const oldX = x;
      x = SAVE(oldX * oldX + a * oldX + b * prev1 + c * prev3 + d * prev7 + stone[kind]);
    }
    timeline.set(i, x);
    visible[i] = x;
  }
  return Object.freeze(visible);
}

function factorial(n: number): bigint {
  let out = 1n;
  for (let i = 2; i <= n; i += 1) out *= BigInt(i);
  return out;
}

export function permutationUnrank1(rank1: bigint, itemsAscending: readonly number[]): readonly number[] {
  const n = itemsAscending.length;
  if (rank1 < 1n || rank1 > factorial(n)) throw new RangeError("क्रमचयाचा दर्जा वैध नाही");
  let rank0 = rank1 - 1n;
  const remaining = [...itemsAscending];
  const result: number[] = [];
  for (let slotsLeft = n; slotsLeft >= 1; slotsLeft -= 1) {
    const block = factorial(slotsLeft - 1);
    const q = rank0 / block;
    rank0 = regularMod(rank0, block);
    result.push(remaining.splice(Number(q), 1)[0]!);
  }
  return Object.freeze(result);
}

export function bowlOrderFromNumber(orderNumber: bigint): readonly number[] {
  if (orderNumber < 1n || orderNumber > 720n) throw new RangeError("वाट्यांच्या क्रमाचा क्रमांक वैध नाही");
  return permutationUnrank1(orderNumber, [1, 2, 3, 4, 5, 6]);
}

export function bowlOrderFromDrop(dropValue: bigint): readonly number[] {
  return bowlOrderFromNumber(regularMod(dropValue - 1n, 720n) + 1n);
}

const BOWL_PRIME = [17n, 19n, 23n, 29n, 31n, 37n] as const;
const BOWL_STIR_STONE_BY_POSITION = [WHEAT, BARLEY, SALT, BITTER, RED, WHEAT] as const;

export function initialBowls(counts: WorkCounts): Bowls {
  const bowls: bigint[] = [];
  for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
    const s = counts.action + counts.target * BigInt(bowlId) + counts.distance + counts.connection + counts.direction
      + BOWL_PRIME[bowlId - 1]! * BOWL_PRIME[bowlId - 1]!;
    bowls[bowlId - 1] = SAVE(s * s + BigInt(bowlId));
  }
  return bowls as Bowls;
}

export function applyVisibleDropsToBowls(
  inputBowls: Bowls,
  visible: readonly bigint[],
  stones: readonly Stone[]
): Readonly<{ bowls: Bowls; orderAtDrop46: readonly number[] }> {
  let bowls: Bowls = [...inputBowls] as Bowls;
  let orderAtDrop46: readonly number[] | null = null;
  for (let i = 1; i <= 46; i += 1) {
    const drop = visible[i]!;
    const order = bowlOrderFromDrop(drop);
    const old: Bowls = [...bowls] as Bowls;
    const pour = [0n, 0n, 0n, 0n, 0n, 0n];
    const firstBowl = order[0]!;
    const secondBowl = order[1]!;
    const thirdBowl = order[2]!;
    pour[0] = SAVE(drop * drop + stones[i]![WHEAT] * old[firstBowl - 1]! + 3n * BigInt(i));
    pour[1] = SAVE(drop * drop + stones[i]![BARLEY] * old[secondBowl - 1]! + 5n * BigInt(i));
    pour[2] = SAVE(drop * drop + stones[i]![SALT] * old[thirdBowl - 1]! + 7n * BigInt(i));
    const nextBowls: bigint[] = [...old];
    for (let position = 1; position <= 6; position += 1) {
      const bowlId = order[position - 1]!;
      const prevId = order[wrap1(position - 1, 6) - 1]!;
      const nextId = order[wrap1(position + 1, 6) - 1]!;
      const stoneKind = BOWL_STIR_STONE_BY_POSITION[position - 1]!;
      const s = old[bowlId - 1]! + 2n * old[prevId - 1]! + 3n * old[nextId - 1]!
        + pour[position - 1]! + drop + stones[i]![stoneKind];
      nextBowls[bowlId - 1] = SAVE(s * s + 5n * old[prevId - 1]! * old[nextId - 1]! + BigInt(i * position));
    }
    bowls = nextBowls as Bowls;
    if (i === 46) orderAtDrop46 = Object.freeze([...order]);
  }
  if (orderAtDrop46 === null) throw new Error("छेचाळीसाव्या थेंबाचा क्रम सापडला नाही");
  return Object.freeze({ bowls, orderAtDrop46 });
}

export function postStir12(inputBowls: Bowls): Bowls {
  let bowls: Bowls = [...inputBowls] as Bowls;
  for (let stir = 1; stir <= 12; stir += 1) {
    const old: Bowls = [...bowls] as Bowls;
    const savedBowlSum = SAVE(old.reduce((a, b) => a + b, 0n) + 149n * BigInt(stir));
    const order = bowlOrderFromNumber(regularMod(savedBowlSum - 1n, 720n) + 1n);
    const nextBowls: bigint[] = [...old];
    for (let position = 1; position <= 6; position += 1) {
      const bowlId = order[position - 1]!;
      const prevId = order[wrap1(position - 1, 6) - 1]!;
      const nextId = order[wrap1(position + 1, 6) - 1]!;
      const s = old[bowlId - 1]! + 3n * old[prevId - 1]! + 5n * old[nextId - 1]! + savedBowlSum
        + BigInt(stir) + BigInt(position * position);
      nextBowls[bowlId - 1] = SAVE(s * s + 7n * old[prevId - 1]! * old[nextId - 1]!);
    }
    bowls = nextBowls as Bowls;
  }
  return bowls;
}

export function sauce(calculationDay: bigint, targetDay: bigint): SauceResult {
  const counts = workCounts(calculationDay, targetDay);
  const hidden = buildHiddenDrops(counts, STONES);
  const visible = buildVisibleDrops(counts, STONES, hidden);
  const firstBowls = initialBowls(counts);
  const afterDrops = applyVisibleDropsToBowls(firstBowls, visible, STONES);
  const finalBowls = postStir12(afterDrops.bowls);
  return Object.freeze({ bowls: Object.freeze([...finalBowls]), orderAtDrop46: afterDrops.orderAtDrop46 });
}

export function nextBowlInDrop46Order(sauceResult: SauceResult, queriedBowlId: number): number {
  const p = sauceResult.orderAtDrop46.indexOf(queriedBowlId);
  if (p < 0) throw new RangeError("विचारलेली वाटी क्रमात नाही");
  return sauceResult.orderAtDrop46[(p + 1) % 6]!;
}

export function askBowl(sauceResult: SauceResult, queriedBowlId: number, seal: bigint): AnswerStream {
  const nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId);
  const queried = sauceResult.bowls[queriedBowlId - 1]!;
  const first = SAVE((queried + seal + 181n) ** 2n + 179n * sauceResult.bowls[nextId - 1]! + seal);
  const directionNumber = SAVE((first + seal + 1n + 193n) ** 2n + 193n * first + 197n * sauceResult.bowls[5]!);
  const directionStep: 1n | -1n = regularMod(directionNumber, 2n) === 1n ? 1n : -1n;
  return Object.freeze({ first, directionStep });
}

export function answerAt(stream: AnswerStream, k: bigint): bigint {
  return 1n + regularMod(stream.first - 1n + stream.directionStep * k, M);
}

export function chooseRankShort(stream: AnswerStream, N: bigint): bigint {
  if (N < 1n || N > M) throw new RangeError("लहान निवडीचा आकार वैध नाही");
  const acceptanceLimit = floorDiv(M, N) * N;
  let k = 0n;
  for (;;) {
    const x = answerAt(stream, k);
    if (x <= acceptanceLimit) return regularMod(x - 1n, N) + 1n;
    k += 1n;
  }
}

export function smallestPowerCount(base: bigint, N: bigint): readonly [number, bigint] {
  let k = 1;
  let space = base;
  while (space < N) {
    k += 1;
    space *= base;
  }
  return [k, space] as const;
}

export function chooseRankWide(stream: AnswerStream, N: bigint): bigint {
  if (N <= M) throw new RangeError("रुंद निवडीचा आकार मोठ्या मोजणीपेक्षा मोठा असला पाहिजे");
  const [k, space] = smallestPowerCount(M, N);
  let wide = 1n;
  let weight = 1n;
  for (let j = 0; j < k; j += 1) {
    wide += (answerAt(stream, BigInt(j)) - 1n) * weight;
    weight *= M;
  }
  const acceptanceLimit = floorDiv(space, N) * N;
  for (;;) {
    if (wide <= acceptanceLimit) return regularMod(wide - 1n, N) + 1n;
    wide = 1n + regularMod(wide - 1n + stream.directionStep, space);
  }
}

export function chooseRank(stream: AnswerStream, N: bigint): bigint {
  if (N < 1n) throw new RangeError("निवडीचा आकार किमान एक असला पाहिजे");
  return N <= M ? chooseRankShort(stream, N) : chooseRankWide(stream, N);
}

export function fallingFactorial(n: number, k: number): bigint {
  if (k < 0 || k > n) return 0n;
  let r = 1n;
  for (let j = 0; j < k; j += 1) r *= BigInt(n - j);
  return r;
}

export function unrankDistinctIndices(n: number, k: number, rank1: bigint): readonly number[] {
  const total = fallingFactorial(n, k);
  if (rank1 < 1n || rank1 > total) throw new RangeError("वेगळ्या नावांचा दर्जा वैध नाही");
  const remaining = Array.from({ length: n }, (_, i) => i + 1);
  const out: number[] = [];
  let r = rank1;
  for (let position = 1; position <= k; position += 1) {
    const suffixLength = k - position;
    const block = fallingFactorial(remaining.length - 1, suffixLength);
    for (let candidate = 0; candidate < remaining.length; candidate += 1) {
      if (r > block) {
        r -= block;
      } else {
        out.push(remaining.splice(candidate, 1)[0]!);
        break;
      }
    }
  }
  return Object.freeze(out);
}

export type OrderedFamily<T> = Readonly<{
  count: () => bigint;
  unrank1: (rank1: bigint) => T;
}>;

export function boundedCompositionFamily(total: bigint, slots: number, lo: bigint, hi: bigint): OrderedFamily<readonly bigint[]> {
  const memo = new Map<string, bigint>();
  const count = (rem: bigint, k: number): bigint => {
    if (k === 0) return rem === 0n ? 1n : 0n;
    if (rem < BigInt(k) * lo || rem > BigInt(k) * hi) return 0n;
    const key = `${rem}:${k}`;
    const hit = memo.get(key);
    if (hit !== undefined) return hit;
    let s = 0n;
    for (let x = lo; x <= hi; x += 1n) s += count(rem - x, k - 1);
    memo.set(key, s);
    return s;
  };
  const countAll = (): bigint => count(total, slots);
  const unrank1 = (rank1: bigint): readonly bigint[] => {
    if (rank1 < 1n || rank1 > countAll()) throw new RangeError("बंधित रचनेचा दर्जा वैध नाही");
    let r = rank1;
    let rem = total;
    const out: bigint[] = [];
    for (let position = 1; position <= slots; position += 1) {
      for (let x = lo; x <= hi; x += 1n) {
        const block = count(rem - x, slots - position);
        if (r > block) r -= block;
        else {
          out.push(x);
          rem -= x;
          break;
        }
      }
    }
    return Object.freeze(out);
  };
  return Object.freeze({ count: countAll, unrank1 });
}

function cutletPartitionFamily(G: bigint, K: number, requiredBoundary: bigint | null): OrderedFamily<readonly bigint[]> {
  const memo = new Map<string, bigint>();
  const count = (rem: bigint, slots: number, cumulative: bigint, hitBoundary: boolean): bigint => {
    if (slots === 0) {
      if (rem !== 0n) return 0n;
      return requiredBoundary === null || hitBoundary ? 1n : 0n;
    }
    if (rem < BigInt(slots)) return 0n;
    const key = `${rem}:${slots}:${cumulative}:${hitBoundary ? 1 : 0}`;
    const found = memo.get(key);
    if (found !== undefined) return found;
    let total = 0n;
    const maxX = rem - BigInt(slots - 1);
    for (let x = 1n; x <= maxX; x += 1n) {
      const nextCumulative = cumulative + x;
      let nextHit = hitBoundary;
      if (requiredBoundary !== null && !hitBoundary) {
        if (nextCumulative === requiredBoundary) nextHit = true;
        else if (nextCumulative > requiredBoundary) continue;
      }
      total += count(rem - x, slots - 1, nextCumulative, nextHit);
    }
    memo.set(key, total);
    return total;
  };
  const countAll = (): bigint => count(G, K, 0n, false);
  const unrank1 = (rank1: bigint): readonly bigint[] => {
    if (rank1 < 1n || rank1 > countAll()) throw new RangeError("कटलेट विभागणीचा दर्जा वैध नाही");
    let r = rank1;
    let rem = G;
    let slots = K;
    let cumulative = 0n;
    let hit = false;
    const out: bigint[] = [];
    while (slots > 0) {
      const maxX = rem - BigInt(slots - 1);
      let chosen = false;
      for (let x = 1n; x <= maxX; x += 1n) {
        const nextCumulative = cumulative + x;
        let nextHit: boolean = hit;
        if (requiredBoundary !== null && !hit) {
          if (nextCumulative === requiredBoundary) nextHit = true;
          else if (nextCumulative > requiredBoundary) continue;
        }
        const block = count(rem - x, slots - 1, nextCumulative, nextHit);
        if (r > block) r -= block;
        else {
          out.push(x);
          rem -= x;
          slots -= 1;
          cumulative = nextCumulative;
          hit = nextHit;
          chosen = true;
          break;
        }
      }
      if (!chosen) throw new Error("कटलेट विभागणी उघडता आली नाही");
    }
    return Object.freeze(out);
  };
  return Object.freeze({ count: countAll, unrank1 });
}

type WeaveState = Readonly<{
  remaining: readonly number[];
  openedUpTo: number;
  closedUpTo: number;
}>;

function legalWeaveMove(state: WeaveState, j: number, originalLengths: readonly number[]): boolean {
  if (state.remaining[j - 1] === 0) return false;
  const alreadyOpened = state.remaining[j - 1]! < originalLengths[j - 1]!;
  if (!alreadyOpened && j !== state.openedUpTo + 1) return false;
  const willClose = state.remaining[j - 1] === 1;
  if (willClose && j !== state.closedUpTo + 1) return false;
  return true;
}

function applyWeaveMove(state: WeaveState, j: number, originalLengths: readonly number[]): WeaveState {
  const remaining = [...state.remaining];
  let openedUpTo = state.openedUpTo;
  let closedUpTo = state.closedUpTo;
  if (remaining[j - 1] === originalLengths[j - 1]) openedUpTo = j;
  remaining[j - 1]!--;
  if (remaining[j - 1] === 0) closedUpTo = j;
  return Object.freeze({ remaining: Object.freeze(remaining), openedUpTo, closedUpTo });
}

export function weavingFamily(lengthsBig: readonly bigint[]): OrderedFamily<readonly number[]> {
  const lengths = lengthsBig.map((x) => {
    if (x < 0n || x > BigInt(Number.MAX_SAFE_INTEGER)) throw new RangeError("शजवणीची लांबी स्थानिक निर्देशांकासाठी खूप मोठी आहे");
    return Number(x);
  });
  const initial: WeaveState = Object.freeze({ remaining: Object.freeze([...lengths]), openedUpTo: 0, closedUpTo: 0 });
  const memo = new Map<string, bigint>();
  const keyOf = (state: WeaveState): string => `${state.remaining.join(",")}|${state.openedUpTo}|${state.closedUpTo}`;
  const countState = (state: WeaveState): bigint => {
    if (state.remaining.every((x) => x === 0)) return 1n;
    const key = keyOf(state);
    const hit = memo.get(key);
    if (hit !== undefined) return hit;
    let total = 0n;
    for (let j = 1; j <= lengths.length; j += 1) {
      if (legalWeaveMove(state, j, lengths)) total += countState(applyWeaveMove(state, j, lengths));
    }
    memo.set(key, total);
    return total;
  };
  const countAll = (): bigint => countState(initial);
  const unrank1 = (rank1: bigint): readonly number[] => {
    if (rank1 < 1n || rank1 > countAll()) throw new RangeError("महिना-शजवणीचा दर्जा वैध नाही");
    let state = initial;
    let r = rank1;
    const out: number[] = [];
    const totalLength = lengths.reduce((a, b) => a + b, 0);
    while (out.length < totalLength) {
      let chosen = false;
      for (let j = 1; j <= lengths.length; j += 1) {
        if (!legalWeaveMove(state, j, lengths)) continue;
        const next = applyWeaveMove(state, j, lengths);
        const block = countState(next);
        if (r > block) r -= block;
        else {
          out.push(j);
          state = next;
          chosen = true;
          break;
        }
      }
      if (!chosen) throw new Error("महिना-शजवण उघडता आली नाही");
    }
    return Object.freeze(out);
  };
  return Object.freeze({ count: countAll, unrank1 });
}

export class NormativeOracle {
  private readonly gate = new Map<bigint, bigint>([[0n, FOUNDATION_DAY]]);
  private minKnownGateIndex = 0n;
  private maxKnownGateIndex = 0n;

  gateDay(index: bigint): bigint {
    this.ensureGateIndex(index);
    return this.gate.get(index)!;
  }

  positiveGateGap(n: bigint): bigint {
    if (n < 1n) throw new RangeError("धन द्वार-अंतरासाठी निर्देशांक किमान एक असला पाहिजे");
    const r = sauce(FOUNDATION_DAY, FOUNDATION_DAY + n);
    return 41n + chooseRank(askBowl(r, 1, SEAL_GATE_GAP), 922n);
  }

  negativeGateGap(n: bigint): bigint {
    if (n < 1n) throw new RangeError("ऋण द्वार-अंतरासाठी परिमाण किमान एक असले पाहिजे");
    const r = sauce(FOUNDATION_DAY, FOUNDATION_DAY - n);
    return 41n + chooseRank(askBowl(r, 1, SEAL_GATE_GAP), 922n);
  }

  ensureGateIndex(k: bigint): bigint {
    if (k > this.maxKnownGateIndex) {
      for (let n = this.maxKnownGateIndex + 1n; n <= k; n += 1n) {
        this.gate.set(n, this.gate.get(n - 1n)! + this.positiveGateGap(n));
        this.maxKnownGateIndex = n;
      }
    }
    if (k < this.minKnownGateIndex) {
      for (let n = this.minKnownGateIndex - 1n; n >= k; n -= 1n) {
        this.gate.set(n, this.gate.get(n + 1n)! - this.negativeGateGap(-n));
        this.minKnownGateIndex = n;
      }
    }
    return this.gate.get(k)!;
  }

  ensureGatesCover(lowDay: bigint, highDay: bigint): void {
    if (lowDay > highDay) throw new RangeError("दिवसांचा आवाका उलटा आहे");
    while (this.gate.get(this.minKnownGateIndex)! > lowDay) this.ensureGateIndex(this.minKnownGateIndex - 1n);
    while (this.gate.get(this.maxKnownGateIndex)! < highDay) this.ensureGateIndex(this.maxKnownGateIndex + 1n);
  }

  gateIndexAtOrBefore(day: bigint): bigint {
    this.ensureGatesCover(day, day);
    let lo = this.minKnownGateIndex;
    let hi = this.maxKnownGateIndex;
    while (lo < hi) {
      const mid = lo + floorDiv(hi - lo + 1n, 2n);
      if (this.gate.get(mid)! <= day) lo = mid;
      else hi = mid - 1n;
    }
    return lo;
  }

  exactGateIndex(day: bigint): bigint | null {
    const i = this.gateIndexAtOrBefore(day);
    return this.gate.get(i) === day ? i : null;
  }

  private validYearPair(openIndex: bigint, closeIndex: bigint): boolean {
    if (closeIndex - openIndex < MIN_GATE_GAPS_PER_YEAR) return false;
    const length = this.gateDay(closeIndex) - this.gateDay(openIndex);
    return YEAR_MIN_DAYS <= length && length <= YEAR_MAX_DAYS;
  }

  year5000(calculationDay: bigint): Year {
    this.ensureGatesCover(calculationDay - YEAR_MAX_DAYS, calculationDay + YEAR_MAX_DAYS);
    const candidates: Array<readonly [bigint, bigint]> = [];
    for (let i = this.minKnownGateIndex; i < this.maxKnownGateIndex; i += 1n) {
      for (let j = i + 1n; j <= this.maxKnownGateIndex; j += 1n) {
        if (!this.validYearPair(i, j)) continue;
        const open = this.gate.get(i)!;
        const close = this.gate.get(j)!;
        if (open < calculationDay && calculationDay <= close) candidates.push([i, j]);
      }
    }
    candidates.sort((a, b) => {
      const la = this.gate.get(a[1])! - this.gate.get(a[0])!;
      const lb = this.gate.get(b[1])! - this.gate.get(b[0])!;
      if (la < lb) return -1;
      if (la > lb) return 1;
      const oa = this.gate.get(a[0])!;
      const ob = this.gate.get(b[0])!;
      return oa < ob ? -1 : oa > ob ? 1 : 0;
    });
    if (candidates.length === 0) throw new Error("पाचहजाराव्या वर्षासाठी उमेदवार नाही");
    const rank = chooseRank(askBowl(sauce(calculationDay, calculationDay), 1, SEAL_YEAR_5000), BigInt(candidates.length));
    const [i, j] = candidates[Number(rank - 1n)]!;
    return Object.freeze({ number: 5000n, openGateIndex: i, closeGateIndex: j, openGateDay: this.gate.get(i)!, closeGateDay: this.gate.get(j)! });
  }

  nextYear(calculationDay: bigint, knownYear: Year): Year {
    const openIndex = knownYear.closeGateIndex;
    const candidates: bigint[] = [];
    for (let closeIndex = openIndex + 1n;; closeIndex += 1n) {
      this.ensureGateIndex(closeIndex);
      if (this.gate.get(closeIndex)! - this.gate.get(openIndex)! > YEAR_MAX_DAYS) break;
      if (this.validYearPair(openIndex, closeIndex)) candidates.push(closeIndex);
    }
    candidates.sort((a, b) => {
      const la = this.gate.get(a)! - this.gate.get(openIndex)!;
      const lb = this.gate.get(b)! - this.gate.get(openIndex)!;
      return la < lb ? -1 : la > lb ? 1 : 0;
    });
    const rank = chooseRank(askBowl(sauce(calculationDay, this.gate.get(openIndex)!), 1, SEAL_NEXT_YEAR), BigInt(candidates.length));
    const closeIndex = candidates[Number(rank - 1n)]!;
    return Object.freeze({
      number: knownYear.number + 1n,
      openGateIndex: openIndex,
      closeGateIndex: closeIndex,
      openGateDay: this.gate.get(openIndex)!,
      closeGateDay: this.gate.get(closeIndex)!
    });
  }

  previousYear(calculationDay: bigint, knownYear: Year): Year {
    const closeIndex = knownYear.openGateIndex;
    const candidates: bigint[] = [];
    for (let openIndex = closeIndex - 1n;; openIndex -= 1n) {
      this.ensureGateIndex(openIndex);
      if (this.gate.get(closeIndex)! - this.gate.get(openIndex)! > YEAR_MAX_DAYS) break;
      if (this.validYearPair(openIndex, closeIndex)) candidates.push(openIndex);
    }
    candidates.sort((a, b) => {
      const la = this.gate.get(closeIndex)! - this.gate.get(a)!;
      const lb = this.gate.get(closeIndex)! - this.gate.get(b)!;
      return la < lb ? -1 : la > lb ? 1 : 0;
    });
    const rank = chooseRank(askBowl(sauce(calculationDay, this.gate.get(closeIndex)!), 1, SEAL_PREVIOUS_YEAR), BigInt(candidates.length));
    const openIndex = candidates[Number(rank - 1n)]!;
    return Object.freeze({
      number: knownYear.number - 1n,
      openGateIndex: openIndex,
      closeGateIndex: closeIndex,
      openGateDay: this.gate.get(openIndex)!,
      closeGateDay: this.gate.get(closeIndex)!
    });
  }

  findTargetYear(calculationDay: bigint, targetDay: bigint): Year {
    let y = this.year5000(calculationDay);
    while (targetDay > y.closeGateDay) y = this.nextYear(calculationDay, y);
    while (targetDay <= y.openGateDay) y = this.previousYear(calculationDay, y);
    return y;
  }

  chooseCutletCount(structureSauce: SauceResult, year: Year): number {
    const gateGaps = year.closeGateIndex - year.openGateIndex;
    const candidates: number[] = [];
    for (let k = MIN_CUTLETS; k <= MAX_CUTLETS; k += 1) if (BigInt(k) <= gateGaps) candidates.push(k);
    const rank = chooseRank(askBowl(structureSauce, 2, SEAL_CUTLET_COUNT), BigInt(candidates.length));
    return candidates[Number(rank - 1n)]!;
  }

  chooseCutletPartition(calculationDay: bigint, structureSauce: SauceResult, year: Year, cutletCount: number): readonly bigint[] {
    const G = year.closeGateIndex - year.openGateIndex;
    const g = this.exactGateIndex(calculationDay);
    const required = g !== null && year.openGateIndex < g && g < year.closeGateIndex ? g - year.openGateIndex : null;
    const family = cutletPartitionFamily(G, cutletCount, required);
    const rank = chooseRank(askBowl(structureSauce, 2, SEAL_CUTLET_PARTITION), family.count());
    return family.unrank1(rank);
  }

  chooseCutletNames(structureSauce: SauceResult, cutletCount: number): readonly number[] {
    const N = fallingFactorial(17, cutletCount);
    const rank = chooseRank(askBowl(structureSauce, 5, SEAL_CUTLET_NAMES), N);
    return unrankDistinctIndices(17, cutletCount, rank);
  }

  materializeCutlets(year: Year, partition: readonly bigint[], names: readonly number[]): readonly Cutlet[] {
    let cursorGate = year.openGateIndex;
    const cutlets: Cutlet[] = [];
    for (let k = 0; k < partition.length; k += 1) {
      const openGateIndex = cursorGate;
      const closeGateIndex = cursorGate + partition[k]!;
      cutlets.push(Object.freeze({
        canonicalIndex: names[k]!,
        openGateIndex,
        closeGateIndex,
        firstDay: this.gateDay(openGateIndex) + 1n,
        lastDay: this.gateDay(closeGateIndex)
      }));
      cursorGate = closeGateIndex;
    }
    return Object.freeze(cutlets);
  }

  chooseMonthCount(structureSauce: SauceResult, year: Year): number {
    const L = year.closeGateDay - year.openGateDay;
    const minMonths = Number(ceilDiv(L, 123n));
    const maxMonths = Math.min(MAX_MONTHS, Number(floorDiv(L, 4n)));
    if (minMonths < MIN_MONTHS || minMonths > maxMonths) throw new Error("महिन्यांच्या संख्येची मर्यादा विसंगत आहे");
    const rank = chooseRank(askBowl(structureSauce, 3, SEAL_MONTH_COUNT), BigInt(maxMonths - minMonths + 1));
    return minMonths + Number(rank - 1n);
  }

  chooseMonthLengths(structureSauce: SauceResult, year: Year, monthCount: number): readonly bigint[] {
    const L = year.closeGateDay - year.openGateDay;
    const family = boundedCompositionFamily(L, monthCount, MIN_MONTH_DAYS, MAX_MONTH_DAYS);
    const rank = chooseRank(askBowl(structureSauce, 3, SEAL_MONTH_LENGTHS), family.count());
    return family.unrank1(rank);
  }

  chooseMonthWeaving(structureSauce: SauceResult, monthLengths: readonly bigint[]): readonly number[] {
    const family = weavingFamily(monthLengths);
    const rank = chooseRank(askBowl(structureSauce, 4, SEAL_MONTH_WEAVING), family.count());
    return family.unrank1(rank);
  }

  chooseMonthNames(structureSauce: SauceResult, monthCount: number): readonly number[] {
    const N = fallingFactorial(47, monthCount);
    const rank = chooseRank(askBowl(structureSauce, 5, SEAL_MONTH_NAMES), N);
    return unrankDistinctIndices(47, monthCount, rank);
  }

  buildYearStructure(calculationDay: bigint, year: Year): YearStructure {
    const firstDay = year.openGateDay + 1n;
    const r = sauce(calculationDay, firstDay);
    const cutletCount = this.chooseCutletCount(r, year);
    const cutletPartition = this.chooseCutletPartition(calculationDay, r, year, cutletCount);
    const cutletCanonicalIndices = this.chooseCutletNames(r, cutletCount);
    const cutlets = this.materializeCutlets(year, cutletPartition, cutletCanonicalIndices);
    const monthCount = this.chooseMonthCount(r, year);
    const monthLengths = this.chooseMonthLengths(r, year, monthCount);
    const monthWeaving = this.chooseMonthWeaving(r, monthLengths);
    const monthCanonicalIndices = this.chooseMonthNames(r, monthCount);
    return Object.freeze({
      cutletCount,
      cutletPartition,
      cutletCanonicalIndices,
      cutlets,
      monthCount,
      monthLengths,
      monthWeaving,
      monthCanonicalIndices
    });
  }

  calendarDate(calculationDay: bigint, targetDay: bigint): NormativeDate {
    const year = this.findTargetYear(calculationDay, targetDay);
    const structure = this.buildYearStructure(calculationDay, year);
    const chosenCutlet = structure.cutlets.find((c) => c.firstDay <= targetDay && targetDay <= c.lastDay);
    if (chosenCutlet === undefined) throw new Error("दिवसासाठी कटलेट सापडली नाही");
    const dayInCutlet = targetDay - chosenCutlet.firstDay + 1n;
    const yearOffset0 = targetDay - (year.openGateDay + 1n);
    const monthId = structure.monthWeaving[Number(yearOffset0)]!;
    const monthCanonicalIndex = structure.monthCanonicalIndices[monthId - 1]!;
    let dayInMonth = 0n;
    for (let p = 0; p <= Number(yearOffset0); p += 1) if (structure.monthWeaving[p] === monthId) dayInMonth += 1n;
    return Object.freeze([
      year.number,
      cutletNameByCanonicalIndex(chosenCutlet.canonicalIndex),
      dayInCutlet,
      monthNameByCanonicalIndex(monthCanonicalIndex),
      dayInMonth
    ] as const);
  }
}
