'use strict';

const { SourceLanguageCatalog, textByCanonicalIndex } = require('../src/source-language-catalog');

const M = (1n << 127n) - 1n;
const TABLETS_DAY = -278522n;
const FOUNDATION_DAY = -15055671n;
const GATE_GAP_MIN = 42n;
const GATE_GAP_MAX = 963n;
const YEAR_MIN_DAYS = 252n;
const YEAR_MAX_DAYS = 5778n;
const MIN_GATE_GAPS_PER_YEAR = 6n;
const MIN_CUTLETS = 6;
const MAX_CUTLETS = 17;
const MIN_MONTHS = 3;
const MAX_MONTHS = 47;
const MIN_MONTH_DAYS = 4;
const MAX_MONTH_DAYS = 123;

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

function absBigInt(x) {
  return x < 0n ? -x : x;
}

function regularMod(x, d) {
  if (d < 1n) throw new RangeError('Li divisor deve esser positiv.');
  const r = x % d;
  return r < 0n ? r + d : r;
}

function floorDiv(a, b) {
  if (b < 1n) throw new RangeError('Li divisor deve esser positiv.');
  let q = a / b;
  const r = a % b;
  if (r < 0n) q -= 1n;
  return q;
}

function SAVE(x) {
  return 1n + regularMod(x - 1n, M);
}

function square(x) {
  return x * x;
}

function ceilDiv(a, b) {
  if (a < 0n || b < 1n) throw new RangeError('ceilDiv exige un numerator non-negativ e un divisor positiv.');
  return floorDiv(a + b - 1n, b);
}

function wrap1(position, size) {
  const p = BigInt(position);
  const s = BigInt(size);
  if (s < 1n) throw new RangeError('Li grandore deve esser positiv.');
  return Number(regularMod(p - 1n, s) + 1n);
}

function dayCount(day) {
  if (day === FOUNDATION_DAY) return 1n;
  if (day > FOUNDATION_DAY) return 2n * (day - FOUNDATION_DAY) + 1n;
  return 2n * (FOUNDATION_DAY - day);
}

function workCounts(calculationDay, targetDay) {
  const action = dayCount(calculationDay);
  const target = dayCount(targetDay);
  const distance = absBigInt(targetDay - calculationDay) + 1n;
  const connection = action + target;
  const direction = targetDay < calculationDay ? 1n : targetDay === calculationDay ? 2n : 3n;
  return Object.freeze({ action, target, distance, connection, direction });
}

function buildStones() {
  const stone = [];
  stone.push(Object.freeze([17n, 29n, 43n, 71n, 101n]));
  for (let i = 2; i <= 46; i += 1) {
    const old = stone[i - 2];
    const bi = BigInt(i);
    const next = [
      SAVE(square(old[WHEAT]) + 3n * old[BARLEY] + bi),
      SAVE(square(old[BARLEY]) + 5n * old[SALT] + old[WHEAT]),
      SAVE(square(old[SALT]) + 7n * old[BITTER] + old[BARLEY]),
      SAVE(square(old[BITTER]) + 11n * old[RED] + old[SALT]),
      SAVE(square(old[RED]) + 13n * old[WHEAT] + old[BITTER])
    ];
    stone.push(Object.freeze(next));
  }
  return Object.freeze(stone);
}

const STONES = buildStones();

const HIDDEN_COEFF = Object.freeze([
  Object.freeze([3n, 4n, 6n, 8n]),
  Object.freeze([5n, 7n, 10n, 12n]),
  Object.freeze([7n, 10n, 14n, 16n]),
  Object.freeze([9n, 13n, 18n, 20n]),
  Object.freeze([11n, 16n, 22n, 24n]),
  Object.freeze([13n, 19n, 26n, 28n]),
  Object.freeze([15n, 22n, 30n, 32n])
]);

const HIDDEN_GRIND_STONE = Object.freeze([WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY]);

function buildHiddenDrops(counts, stones = STONES) {
  const hidden = [];
  for (let k = 1; k <= 7; k += 1) {
    const [a, b, c, d] = HIDDEN_COEFF[k - 1];
    const row = stones[k - 1];
    let x = counts.action
      + a * counts.target
      + b * counts.distance
      + c * counts.connection
      + d * counts.direction
      + row[WHEAT] + row[BARLEY] + row[SALT] + row[BITTER] + row[RED];
    x = SAVE(x);
    for (let grind = 1; grind <= 7; grind += 1) {
      const oldX = x;
      x = SAVE(square(oldX) + 3n * oldX + row[HIDDEN_GRIND_STONE[grind - 1]] + BigInt(grind));
    }
    hidden.push(x);
  }
  return hidden;
}

const VISIBLE_GRINDS = Object.freeze([
  Object.freeze([3n, 5n, 7n, 11n, WHEAT]),
  Object.freeze([5n, 7n, 11n, 13n, BARLEY]),
  Object.freeze([7n, 11n, 13n, 17n, SALT]),
  Object.freeze([11n, 13n, 17n, 19n, BITTER]),
  Object.freeze([13n, 17n, 19n, 23n, RED]),
  Object.freeze([17n, 19n, 23n, 29n, WHEAT]),
  Object.freeze([19n, 23n, 29n, 31n, BARLEY]),
  Object.freeze([23n, 29n, 31n, 37n, SALT]),
  Object.freeze([29n, 31n, 37n, 41n, BITTER]),
  Object.freeze([31n, 37n, 41n, 43n, RED]),
  Object.freeze([37n, 41n, 43n, 47n, WHEAT])
]);

function buildVisibleDrops(counts, stones = STONES, hidden = buildHiddenDrops(counts, stones)) {
  const timeline = new Map();
  for (let k = 1; k <= 7; k += 1) timeline.set(1 - k, hidden[k - 1]);
  const visible = [];
  for (let i = 1; i <= 46; i += 1) {
    const prev1 = timeline.get(i - 1);
    const prev3 = timeline.get(i - 3);
    const prev7 = timeline.get(i - 7);
    const row = stones[i - 1];
    let x = SAVE(
      row[WHEAT] * counts.action
      + row[BARLEY] * counts.target
      + row[SALT] * counts.distance
      + row[BITTER] * counts.connection
      + row[RED] * counts.direction
      + prev1 + 3n * prev3 + 5n * prev7 + BigInt(i)
    );
    for (const [a, b, c, d, kind] of VISIBLE_GRINDS) {
      const oldX = x;
      x = SAVE(square(oldX) + a * oldX + b * prev1 + c * prev3 + d * prev7 + row[kind]);
    }
    timeline.set(i, x);
    visible.push(x);
  }
  return visible;
}

function factorial(n) {
  let r = 1n;
  for (let i = 2n; i <= BigInt(n); i += 1n) r *= i;
  return r;
}

function permutationUnrank1(rank1, itemsAscending) {
  const n = itemsAscending.length;
  if (rank1 < 1n || rank1 > factorial(n)) throw new RangeError('Rang de permutation éxter li limites.');
  let rank0 = rank1 - 1n;
  const remaining = itemsAscending.slice();
  const result = [];
  for (let slotsLeft = remaining.length; slotsLeft >= 1; slotsLeft -= 1) {
    const block = factorial(slotsLeft - 1);
    const q = rank0 / block;
    rank0 = regularMod(rank0, block);
    result.push(remaining.splice(Number(q), 1)[0]);
  }
  return result;
}

function bowlOrderFromNumber(orderNumber) {
  const n = BigInt(orderNumber);
  if (n < 1n || n > 720n) throw new RangeError('Li númere de órdine de bole deve esser inter 1 e 720.');
  return permutationUnrank1(n, [1, 2, 3, 4, 5, 6]);
}

function bowlOrderFromDrop(dropValue) {
  return bowlOrderFromNumber(regularMod(dropValue - 1n, 720n) + 1n);
}

const BOWL_PRIME = Object.freeze([17n, 19n, 23n, 29n, 31n, 37n]);
const BOWL_STIR_STONE_BY_POSITION = Object.freeze([WHEAT, BARLEY, SALT, BITTER, RED, WHEAT]);

function initialBowls(counts) {
  const bowls = [];
  for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
    const s = counts.action
      + counts.target * BigInt(bowlId)
      + counts.distance
      + counts.connection
      + counts.direction
      + square(BOWL_PRIME[bowlId - 1]);
    bowls.push(SAVE(square(s) + BigInt(bowlId)));
  }
  return bowls;
}

function applyVisibleDropsToBowls(bowls, visible, stones = STONES) {
  let current = bowls.slice();
  let orderAtDrop46 = null;
  for (let i = 1; i <= 46; i += 1) {
    const drop = visible[i - 1];
    const order = bowlOrderFromDrop(drop);
    const old = current.slice();
    const pour = [0n, 0n, 0n, 0n, 0n, 0n];
    pour[0] = SAVE(square(drop) + stones[i - 1][WHEAT] * old[order[0] - 1] + 3n * BigInt(i));
    pour[1] = SAVE(square(drop) + stones[i - 1][BARLEY] * old[order[1] - 1] + 5n * BigInt(i));
    pour[2] = SAVE(square(drop) + stones[i - 1][SALT] * old[order[2] - 1] + 7n * BigInt(i));
    const nextBowls = new Array(6);
    for (let position = 1; position <= 6; position += 1) {
      const bowlId = order[position - 1];
      const prevId = order[wrap1(position - 1, 6) - 1];
      const nextId = order[wrap1(position + 1, 6) - 1];
      const stoneKind = BOWL_STIR_STONE_BY_POSITION[position - 1];
      const s = old[bowlId - 1]
        + 2n * old[prevId - 1]
        + 3n * old[nextId - 1]
        + pour[position - 1]
        + drop
        + stones[i - 1][stoneKind];
      nextBowls[bowlId - 1] = SAVE(square(s) + 5n * old[prevId - 1] * old[nextId - 1] + BigInt(i * position));
    }
    current = nextBowls;
    if (i === 46) orderAtDrop46 = order.slice();
  }
  return Object.freeze({ bowls: current, orderAtDrop46 });
}

function postStir12(bowls) {
  let current = bowls.slice();
  for (let stir = 1; stir <= 12; stir += 1) {
    const old = current.slice();
    const savedBowlSum = SAVE(old.reduce((a, b) => a + b, 0n) + 149n * BigInt(stir));
    const orderNumber = regularMod(savedBowlSum - 1n, 720n) + 1n;
    const order = bowlOrderFromNumber(orderNumber);
    const nextBowls = new Array(6);
    for (let position = 1; position <= 6; position += 1) {
      const bowlId = order[position - 1];
      const prevId = order[wrap1(position - 1, 6) - 1];
      const nextId = order[wrap1(position + 1, 6) - 1];
      const s = old[bowlId - 1]
        + 3n * old[prevId - 1]
        + 5n * old[nextId - 1]
        + savedBowlSum
        + BigInt(stir)
        + BigInt(position * position);
      nextBowls[bowlId - 1] = SAVE(square(s) + 7n * old[prevId - 1] * old[nextId - 1]);
    }
    current = nextBowls;
  }
  return current;
}

function sauce(calculationDay, targetDay) {
  const counts = workCounts(calculationDay, targetDay);
  const hidden = buildHiddenDrops(counts, STONES);
  const visible = buildVisibleDrops(counts, STONES, hidden);
  const afterDrops = applyVisibleDropsToBowls(initialBowls(counts), visible, STONES);
  const bowls = postStir12(afterDrops.bowls);
  return Object.freeze({ bowls, orderAtDrop46: afterDrops.orderAtDrop46.slice() });
}

function nextBowlInDrop46Order(sauceResult, queriedBowlId) {
  const p = sauceResult.orderAtDrop46.indexOf(queriedBowlId);
  if (p < 0) throw new RangeError('Li bole questionat ne existe in li órdine latchet.');
  return sauceResult.orderAtDrop46[(p + 1) % 6];
}

function askBowl(sauceResult, queriedBowlId, seal) {
  const nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId);
  const first = SAVE(
    square(sauceResult.bowls[queriedBowlId - 1] + seal + 181n)
    + 179n * sauceResult.bowls[nextId - 1]
    + seal
  );
  const directionNumber = SAVE(
    square(first + seal + 1n + 193n)
    + 193n * first
    + 197n * sauceResult.bowls[5]
  );
  const directionStep = regularMod(directionNumber, 2n) === 1n ? 1n : -1n;
  return Object.freeze({ first, directionStep });
}

function answerAt(stream, k) {
  return 1n + regularMod(stream.first - 1n + stream.directionStep * BigInt(k), M);
}

function chooseRankShort(stream, N) {
  const n = BigInt(N);
  if (n < 1n || n > M) throw new RangeError('Li familie curt deve haver un grandore inter 1 e M.');
  const acceptanceLimit = floorDiv(M, n) * n;
  let k = 0n;
  for (;;) {
    const x = answerAt(stream, k);
    if (x <= acceptanceLimit) return regularMod(x - 1n, n) + 1n;
    k += 1n;
  }
}

function smallestPowerCount(base, N) {
  let k = 1;
  let space = base;
  while (space < N) {
    k += 1;
    space *= base;
  }
  return Object.freeze({ k, space });
}

function chooseRankWide(stream, N) {
  const n = BigInt(N);
  if (n <= M) throw new RangeError('Li familie larg deve esser plu grand quam M.');
  const { k, space } = smallestPowerCount(M, n);
  let wide = 1n;
  let weight = 1n;
  for (let j = 0; j < k; j += 1) {
    wide += (answerAt(stream, BigInt(j)) - 1n) * weight;
    weight *= M;
  }
  const acceptanceLimit = floorDiv(space, n) * n;
  while (wide > acceptanceLimit) wide = 1n + regularMod(wide - 1n + stream.directionStep, space);
  return regularMod(wide - 1n, n) + 1n;
}

function chooseRank(stream, N) {
  const n = BigInt(N);
  if (n < 1n) throw new RangeError('Li familie deve esser non-vacui.');
  return n <= M ? chooseRankShort(stream, n) : chooseRankWide(stream, n);
}

function fallingFactorial(n, k) {
  let r = 1n;
  for (let j = 0; j < k; j += 1) r *= BigInt(n - j);
  return r;
}

function unrankDistinctIndices(n, k, rank1) {
  const total = fallingFactorial(n, k);
  if (rank1 < 1n || rank1 > total) throw new RangeError('Rang de nomes distinct es éxter li familie.');
  const remaining = Array.from({ length: n }, (_, i) => i + 1);
  const out = [];
  let r = rank1;
  for (let position = 1; position <= k; position += 1) {
    const suffixLength = k - position;
    const block = fallingFactorial(remaining.length - 1, suffixLength);
    for (let candidate = 0; candidate < remaining.length; candidate += 1) {
      if (r > block) r -= block;
      else {
        out.push(remaining.splice(candidate, 1)[0]);
        break;
      }
    }
  }
  return out;
}

function makeBoundedCompositionCounter(total, slots, lo, hi) {
  const memo = new Map();
  function count(rem, k) {
    if (k === 0) return rem === 0 ? 1n : 0n;
    if (rem < k * lo || rem > k * hi) return 0n;
    const key = rem + ':' + k;
    if (memo.has(key)) return memo.get(key);
    let s = 0n;
    for (let x = lo; x <= hi; x += 1) s += count(rem - x, k - 1);
    memo.set(key, s);
    return s;
  }
  function unrank1(rank1) {
    const totalCount = count(total, slots);
    if (rank1 < 1n || rank1 > totalCount) throw new RangeError('Rang de composition éxter li familie.');
    let r = rank1;
    let rem = total;
    const out = [];
    for (let position = 1; position <= slots; position += 1) {
      for (let x = lo; x <= hi; x += 1) {
        const block = count(rem - x, slots - position);
        if (r > block) r -= block;
        else {
          out.push(x);
          rem -= x;
          break;
        }
      }
    }
    return out;
  }
  return Object.freeze({ countAll: () => count(total, slots), unrank1 });
}

function createGateEngine() {
  const gate = new Map([[0n, FOUNDATION_DAY]]);
  let minKnownGateIndex = 0n;
  let maxKnownGateIndex = 0n;

  function positiveGateGap(n) {
    const r = sauce(FOUNDATION_DAY, FOUNDATION_DAY + n);
    return 41n + chooseRank(askBowl(r, 1, SEAL_GATE_GAP), 922n);
  }

  function negativeGateGap(n) {
    const r = sauce(FOUNDATION_DAY, FOUNDATION_DAY - n);
    return 41n + chooseRank(askBowl(r, 1, SEAL_GATE_GAP), 922n);
  }

  function ensureGateIndex(k) {
    if (k > maxKnownGateIndex) {
      for (let n = maxKnownGateIndex + 1n; n <= k; n += 1n) {
        gate.set(n, gate.get(n - 1n) + positiveGateGap(n));
        maxKnownGateIndex = n;
      }
    }
    if (k < minKnownGateIndex) {
      let n = minKnownGateIndex - 1n;
      while (n >= k) {
        gate.set(n, gate.get(n + 1n) - negativeGateGap(absBigInt(n)));
        minKnownGateIndex = n;
        n -= 1n;
      }
    }
    return gate.get(k);
  }

  function ensureGatesCover(lowDay, highDay) {
    if (lowDay > highDay) throw new RangeError('Li interval de portes es invers.');
    while (gate.get(minKnownGateIndex) > lowDay) ensureGateIndex(minKnownGateIndex - 1n);
    while (gate.get(maxKnownGateIndex) < highDay) ensureGateIndex(maxKnownGateIndex + 1n);
  }

  function gateIndexAtOrBefore(day) {
    ensureGatesCover(day, day);
    let lo = minKnownGateIndex;
    let hi = maxKnownGateIndex;
    while (lo < hi) {
      const mid = lo + floorDiv(hi - lo + 1n, 2n);
      if (gate.get(mid) <= day) lo = mid;
      else hi = mid - 1n;
    }
    return lo;
  }

  function gateIndexAtOrAfter(day) {
    const i = gateIndexAtOrBefore(day);
    if (gate.get(i) === day) return i;
    ensureGateIndex(i + 1n);
    return i + 1n;
  }

  function exactGateIndex(day) {
    const i = gateIndexAtOrBefore(day);
    return gate.get(i) === day ? i : null;
  }

  function ensureGatesForwardThroughDay(day) {
    ensureGatesCover(gate.get(minKnownGateIndex), day);
  }

  function ensureGatesBackwardThroughDay(day) {
    ensureGatesCover(day, gate.get(maxKnownGateIndex));
  }

  return Object.freeze({
    gate,
    ensureGateIndex,
    ensureGatesCover,
    ensureGatesForwardThroughDay,
    ensureGatesBackwardThroughDay,
    gateIndexAtOrBefore,
    gateIndexAtOrAfter,
    exactGateIndex,
    bounds: () => Object.freeze({ minKnownGateIndex, maxKnownGateIndex })
  });
}

function yearLength(engine, openIndex, closeIndex) {
  return engine.ensureGateIndex(closeIndex) - engine.ensureGateIndex(openIndex);
}

function validYearPair(engine, openIndex, closeIndex) {
  if (closeIndex - openIndex < MIN_GATE_GAPS_PER_YEAR) return false;
  const L = yearLength(engine, openIndex, closeIndex);
  return YEAR_MIN_DAYS <= L && L <= YEAR_MAX_DAYS;
}

function makeYear(engine, number, openGateIndex, closeGateIndex) {
  return Object.freeze({
    number,
    openGateIndex,
    closeGateIndex,
    openGateDay: engine.ensureGateIndex(openGateIndex),
    closeGateDay: engine.ensureGateIndex(closeGateIndex)
  });
}

function year5000(calculationDay, engine) {
  engine.ensureGatesCover(calculationDay - YEAR_MAX_DAYS, calculationDay + YEAR_MAX_DAYS);
  const { minKnownGateIndex, maxKnownGateIndex } = engine.bounds();
  const candidates = [];
  for (let i = minKnownGateIndex; i < maxKnownGateIndex; i += 1n) {
    const open = engine.ensureGateIndex(i);
    if (open >= calculationDay) continue;
    for (let j = i + MIN_GATE_GAPS_PER_YEAR; j <= maxKnownGateIndex; j += 1n) {
      const close = engine.ensureGateIndex(j);
      const length = close - open;
      if (length > YEAR_MAX_DAYS) break;
      if (length < YEAR_MIN_DAYS) continue;
      if (calculationDay <= close) candidates.push([i, j]);
    }
  }
  candidates.sort((a, b) => {
    const la = engine.ensureGateIndex(a[1]) - engine.ensureGateIndex(a[0]);
    const lb = engine.ensureGateIndex(b[1]) - engine.ensureGateIndex(b[0]);
    if (la < lb) return -1;
    if (la > lb) return 1;
    const oa = engine.ensureGateIndex(a[0]);
    const ob = engine.ensureGateIndex(b[0]);
    return oa < ob ? -1 : oa > ob ? 1 : 0;
  });
  if (candidates.length === 0) throw new Error('Null candidat existe por li annu 5000.');
  const r = sauce(calculationDay, calculationDay);
  const rank = chooseRank(askBowl(r, 1, SEAL_YEAR_5000), BigInt(candidates.length));
  const [i, j] = candidates[Number(rank - 1n)];
  return makeYear(engine, 5000n, i, j);
}

function nextYear(calculationDay, knownYear, engine) {
  const openIndex = knownYear.closeGateIndex;
  engine.ensureGatesForwardThroughDay(engine.ensureGateIndex(openIndex) + YEAR_MAX_DAYS);
  const candidates = [];
  for (let closeIndex = openIndex + 1n;; closeIndex += 1n) {
    const L = engine.ensureGateIndex(closeIndex) - engine.ensureGateIndex(openIndex);
    if (L > YEAR_MAX_DAYS) break;
    if (validYearPair(engine, openIndex, closeIndex)) candidates.push(closeIndex);
  }
  candidates.sort((a, b) => {
    const la = engine.ensureGateIndex(a) - engine.ensureGateIndex(openIndex);
    const lb = engine.ensureGateIndex(b) - engine.ensureGateIndex(openIndex);
    return la < lb ? -1 : la > lb ? 1 : 0;
  });
  const r = sauce(calculationDay, engine.ensureGateIndex(openIndex));
  const rank = chooseRank(askBowl(r, 1, SEAL_NEXT_YEAR), BigInt(candidates.length));
  return makeYear(engine, knownYear.number + 1n, openIndex, candidates[Number(rank - 1n)]);
}

function previousYear(calculationDay, knownYear, engine) {
  const closeIndex = knownYear.openGateIndex;
  engine.ensureGatesBackwardThroughDay(engine.ensureGateIndex(closeIndex) - YEAR_MAX_DAYS);
  const candidates = [];
  for (let openIndex = closeIndex - 1n;; openIndex -= 1n) {
    const L = engine.ensureGateIndex(closeIndex) - engine.ensureGateIndex(openIndex);
    if (L > YEAR_MAX_DAYS) break;
    if (validYearPair(engine, openIndex, closeIndex)) candidates.push(openIndex);
  }
  candidates.sort((a, b) => {
    const la = engine.ensureGateIndex(closeIndex) - engine.ensureGateIndex(a);
    const lb = engine.ensureGateIndex(closeIndex) - engine.ensureGateIndex(b);
    return la < lb ? -1 : la > lb ? 1 : 0;
  });
  const r = sauce(calculationDay, engine.ensureGateIndex(closeIndex));
  const rank = chooseRank(askBowl(r, 1, SEAL_PREVIOUS_YEAR), BigInt(candidates.length));
  return makeYear(engine, knownYear.number - 1n, candidates[Number(rank - 1n)], closeIndex);
}

function findTargetYear(calculationDay, targetDay, engine) {
  let y = year5000(calculationDay, engine);
  while (targetDay > y.closeGateDay) y = nextYear(calculationDay, y, engine);
  while (targetDay <= y.openGateDay) y = previousYear(calculationDay, y, engine);
  if (!(y.openGateDay < targetDay && targetDay <= y.closeGateDay)) throw new Error('Li die questionat ne apartene al annu trovat.');
  return y;
}

function chooseCutletCount(structureSauce, year) {
  const gateGaps = Number(year.closeGateIndex - year.openGateIndex);
  const candidates = [];
  for (let k = MIN_CUTLETS; k <= MAX_CUTLETS; k += 1) if (k <= gateGaps) candidates.push(k);
  const rank = chooseRank(askBowl(structureSauce, 2, SEAL_CUTLET_COUNT), BigInt(candidates.length));
  return candidates[Number(rank - 1n)];
}

function makeCutletPartitionFamily(G, K, requiredBoundaryOrNone) {
  const memo = new Map();
  function count(rem, slots, cumulative, hitBoundary) {
    if (slots === 0) {
      if (rem !== 0) return 0n;
      if (requiredBoundaryOrNone === null) return 1n;
      return hitBoundary ? 1n : 0n;
    }
    if (rem < slots) return 0n;
    const key = rem + ':' + slots + ':' + cumulative + ':' + (hitBoundary ? 1 : 0);
    if (memo.has(key)) return memo.get(key);
    let total = 0n;
    const maxX = rem - (slots - 1);
    for (let x = 1; x <= maxX; x += 1) {
      const nextCumulative = cumulative + x;
      let nextHit = hitBoundary;
      if (requiredBoundaryOrNone !== null && !hitBoundary) {
        if (nextCumulative === requiredBoundaryOrNone) nextHit = true;
        else if (nextCumulative > requiredBoundaryOrNone) continue;
      }
      total += count(rem - x, slots - 1, nextCumulative, nextHit);
    }
    memo.set(key, total);
    return total;
  }
  function countAll() {
    return count(G, K, 0, false);
  }
  function unrank1(rank1) {
    if (rank1 < 1n || rank1 > countAll()) throw new RangeError('Rang de partition éxter li familie.');
    let r = rank1;
    let rem = G;
    let slots = K;
    let cumulative = 0;
    let hit = false;
    const out = [];
    while (slots > 0) {
      const maxX = rem - (slots - 1);
      for (let x = 1; x <= maxX; x += 1) {
        const nextCumulative = cumulative + x;
        let nextHit = hit;
        if (requiredBoundaryOrNone !== null && !hit) {
          if (nextCumulative === requiredBoundaryOrNone) nextHit = true;
          else if (nextCumulative > requiredBoundaryOrNone) continue;
        }
        const block = count(rem - x, slots - 1, nextCumulative, nextHit);
        if (r > block) r -= block;
        else {
          out.push(x);
          rem -= x;
          slots -= 1;
          cumulative = nextCumulative;
          hit = nextHit;
          break;
        }
      }
    }
    return out;
  }
  return Object.freeze({ count: countAll, unrank1 });
}

function chooseCutletPartition(calculationDay, structureSauce, year, cutletCount, engine) {
  const G = Number(year.closeGateIndex - year.openGateIndex);
  const g = engine.exactGateIndex(calculationDay);
  const required = g !== null && year.openGateIndex < g && g < year.closeGateIndex ? Number(g - year.openGateIndex) : null;
  const family = makeCutletPartitionFamily(G, cutletCount, required);
  const rank = chooseRank(askBowl(structureSauce, 2, SEAL_CUTLET_PARTITION), family.count());
  return family.unrank1(rank);
}

function chooseCutletNames(structureSauce, cutletCount) {
  const N = fallingFactorial(17, cutletCount);
  const rank = chooseRank(askBowl(structureSauce, 5, SEAL_CUTLET_NAMES), N);
  return unrankDistinctIndices(17, cutletCount, rank);
}

function materializeCutlets(year, partition, nameIndices, engine) {
  let cursorGate = year.openGateIndex;
  const cutlets = [];
  for (let k = 0; k < partition.length; k += 1) {
    const openGateIndex = cursorGate;
    const closeGateIndex = cursorGate + BigInt(partition[k]);
    cutlets.push(Object.freeze({
      nameIndex: nameIndices[k],
      openGateIndex,
      closeGateIndex,
      firstDay: engine.ensureGateIndex(openGateIndex) + 1n,
      lastDay: engine.ensureGateIndex(closeGateIndex)
    }));
    cursorGate = closeGateIndex;
  }
  return Object.freeze(cutlets);
}

function chooseMonthCount(structureSauce, year) {
  const L = year.closeGateDay - year.openGateDay;
  const minMonths = Number(ceilDiv(L, 123n));
  const maxMonths = Math.min(MAX_MONTHS, Number(floorDiv(L, 4n)));
  if (!(MIN_MONTHS <= minMonths && minMonths <= maxMonths && maxMonths <= MAX_MONTHS)) throw new Error('Li limites de númere de mensus es inconsistent.');
  const rank = chooseRank(askBowl(structureSauce, 3, SEAL_MONTH_COUNT), BigInt(maxMonths - minMonths + 1));
  return minMonths + Number(rank - 1n);
}

function chooseMonthLengths(structureSauce, year, monthCount) {
  const L = Number(year.closeGateDay - year.openGateDay);
  const family = makeBoundedCompositionCounter(L, monthCount, MIN_MONTH_DAYS, MAX_MONTH_DAYS);
  const rank = chooseRank(askBowl(structureSauce, 3, SEAL_MONTH_LENGTHS), family.countAll());
  return family.unrank1(rank);
}

function makeMonthWeavingFamily(lengths) {
  const m = lengths.length;
  const memo = new Map();
  function stateKey(remaining, openedUpTo, closedUpTo) {
    return remaining.join(',') + '|' + openedUpTo + '|' + closedUpTo;
  }
  function legalMove(remaining, openedUpTo, closedUpTo, j) {
    if (remaining[j - 1] === 0) return false;
    const alreadyOpened = remaining[j - 1] < lengths[j - 1];
    if (!alreadyOpened && j !== openedUpTo + 1) return false;
    const willClose = remaining[j - 1] === 1;
    if (willClose && j !== closedUpTo + 1) return false;
    return true;
  }
  function applyMove(remaining, openedUpTo, closedUpTo, j) {
    const next = remaining.slice();
    let a = openedUpTo;
    let b = closedUpTo;
    if (next[j - 1] === lengths[j - 1]) a = j;
    next[j - 1] -= 1;
    if (next[j - 1] === 0) b = j;
    return [next, a, b];
  }
  function count(remaining, openedUpTo, closedUpTo) {
    if (remaining.every((x) => x === 0)) return 1n;
    const key = stateKey(remaining, openedUpTo, closedUpTo);
    if (memo.has(key)) return memo.get(key);
    let total = 0n;
    for (let j = 1; j <= m; j += 1) {
      if (!legalMove(remaining, openedUpTo, closedUpTo, j)) continue;
      const [next, a, b] = applyMove(remaining, openedUpTo, closedUpTo, j);
      total += count(next, a, b);
    }
    memo.set(key, total);
    return total;
  }
  function countAll() {
    return count(lengths.slice(), 0, 0);
  }
  function unrank1(rank1) {
    const total = countAll();
    if (rank1 < 1n || rank1 > total) throw new RangeError('Rang de intertexe de mensus éxter li familie.');
    let remaining = lengths.slice();
    let openedUpTo = 0;
    let closedUpTo = 0;
    let r = rank1;
    const out = [];
    const wantedLength = lengths.reduce((a, b) => a + b, 0);
    while (out.length < wantedLength) {
      let moved = false;
      for (let j = 1; j <= m; j += 1) {
        if (!legalMove(remaining, openedUpTo, closedUpTo, j)) continue;
        const [next, a, b] = applyMove(remaining, openedUpTo, closedUpTo, j);
        const block = count(next, a, b);
        if (r > block) r -= block;
        else {
          out.push(j);
          remaining = next;
          openedUpTo = a;
          closedUpTo = b;
          moved = true;
          break;
        }
      }
      if (!moved) throw new Error('Li unranking de intertexe ne trova un move legal.');
    }
    return out;
  }
  return Object.freeze({ count: countAll, unrank1 });
}

function chooseMonthWeaving(structureSauce, monthLengths) {
  const family = makeMonthWeavingFamily(monthLengths);
  const rank = chooseRank(askBowl(structureSauce, 4, SEAL_MONTH_WEAVING), family.count());
  return family.unrank1(rank);
}

function chooseMonthNames(structureSauce, monthCount) {
  const N = fallingFactorial(47, monthCount);
  const rank = chooseRank(askBowl(structureSauce, 5, SEAL_MONTH_NAMES), N);
  return unrankDistinctIndices(47, monthCount, rank);
}

function buildYearStructure(calculationDay, year, engine) {
  const firstDay = year.openGateDay + 1n;
  const r = sauce(calculationDay, firstDay);
  const cutletCount = chooseCutletCount(r, year);
  const cutletPartition = chooseCutletPartition(calculationDay, r, year, cutletCount, engine);
  const cutletNameIndices = chooseCutletNames(r, cutletCount);
  const cutlets = materializeCutlets(year, cutletPartition, cutletNameIndices, engine);
  const monthCount = chooseMonthCount(r, year);
  const monthLengths = chooseMonthLengths(r, year, monthCount);
  const monthWeaving = chooseMonthWeaving(r, monthLengths);
  const monthNameIndices = chooseMonthNames(r, monthCount);
  return Object.freeze({
    cutletCount,
    cutletPartition,
    cutletNameIndices,
    cutlets,
    monthCount,
    monthLengths,
    monthWeaving,
    monthNameIndices
  });
}

function calendarDate(calculationDay, targetDay) {
  if (typeof calculationDay !== 'bigint' || typeof targetDay !== 'bigint') throw new TypeError('Li dies del calendare deve esser BigInt exact.');
  const engine = createGateEngine();
  const year = findTargetYear(calculationDay, targetDay, engine);
  const structure = buildYearStructure(calculationDay, year, engine);
  let chosenCutlet = null;
  for (const c of structure.cutlets) {
    if (c.firstDay <= targetDay && targetDay <= c.lastDay) {
      chosenCutlet = c;
      break;
    }
  }
  if (chosenCutlet === null) throw new Error('Null cutlette contene li die questionat.');
  const dayInCutlet = targetDay - chosenCutlet.firstDay + 1n;
  const yearOffset0 = Number(targetDay - (year.openGateDay + 1n));
  const monthId = structure.monthWeaving[yearOffset0];
  const monthNameIndex = structure.monthNameIndices[monthId - 1];
  let dayInMonth = 0n;
  for (let p = 0; p <= yearOffset0; p += 1) if (structure.monthWeaving[p] === monthId) dayInMonth += 1n;
  return Object.freeze([
    year.number,
    textByCanonicalIndex('cutlet', chosenCutlet.nameIndex),
    dayInCutlet,
    textByCanonicalIndex('month', monthNameIndex),
    dayInMonth
  ]);
}

module.exports = Object.freeze({
  M,
  TABLETS_DAY,
  FOUNDATION_DAY,
  GATE_GAP_MIN,
  GATE_GAP_MAX,
  YEAR_MIN_DAYS,
  YEAR_MAX_DAYS,
  MIN_GATE_GAPS_PER_YEAR,
  SourceLanguageCatalog,
  regularMod,
  floorDiv,
  SAVE,
  square,
  ceilDiv,
  wrap1,
  dayCount,
  workCounts,
  STONES,
  buildStones,
  buildHiddenDrops,
  buildVisibleDrops,
  factorial,
  permutationUnrank1,
  bowlOrderFromNumber,
  bowlOrderFromDrop,
  initialBowls,
  applyVisibleDropsToBowls,
  postStir12,
  sauce,
  nextBowlInDrop46Order,
  askBowl,
  answerAt,
  chooseRankShort,
  smallestPowerCount,
  chooseRankWide,
  chooseRank,
  fallingFactorial,
  unrankDistinctIndices,
  makeBoundedCompositionCounter,
  createGateEngine,
  yearLength,
  validYearPair,
  year5000,
  nextYear,
  previousYear,
  findTargetYear,
  makeCutletPartitionFamily,
  chooseCutletCount,
  chooseCutletPartition,
  chooseCutletNames,
  materializeCutlets,
  chooseMonthCount,
  chooseMonthLengths,
  makeMonthWeavingFamily,
  chooseMonthWeaving,
  chooseMonthNames,
  buildYearStructure,
  calendarDate
});
