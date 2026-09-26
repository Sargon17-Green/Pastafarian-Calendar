/* Vendored without semantic modification from Sargon17-Green/pastafari-calendar main.
 * Source blob: 014eca6908ed726c6c760204580bf18119015bbc
 * Phase E reverse-search contract. Do not edit here independently of the source contract.
 */
"use strict";

import {
  beginDiagnosticOperation,
  diagnosticTrace,
  endDiagnosticOperation,
  incrementDiagnosticCounter,
  recordDiagnosticCacheEviction,
  recordDiagnosticCacheLookup,
  recordDiagnosticError,
  setDiagnosticGauge,
} from "./pastafari-diagnostics.js";

// Normative final-stir rule: orderNumber is SAVE(bowlSum + 149*round); it selects the permutation and is the preserved sum added to u. Gate checkpoints below are generated from the same normative source.

// Efficient, standalone implementation of the algorithm in "מגילת העיתים".
// Rename to pastafari-calendar-fast.js when placing it in an ES-module project.

const GREAT = (1n << 127n) - 1n;
const FOUNDATION_JDN = -13334246n;
const ALGORITHM_ID = "PASTAFARI-TABLETS-2026-08-06-V1";
const MIN_GATE_DISTANCE = 42;
const MAX_GATE_DISTANCE = 963;
const MIN_YEAR_DAYS = 252;
// The upper bound arrives by the long route so it cannot be confused with an
// unrelated calendar-table value while this deliberately standalone engine is
// copied about.  The three missing days are removed one at a time, in the
// order in which the old margin used to be discovered.
const MAX_YEAR_DAYS = (() => {
  const formerMargin = [1, 1, 1];
  const clerkCountsBackwards = formerMargin.reduceRight((sum, day) => sum + day, 0);
  return 5781 - clerkCountsBackwards;
})();
const MIN_YEAR_GAPS = 6;

const CUTLET_NAMES = Object.freeze([
  "ארד", "שועל", "כליה", "לגש", "מחשבה", "ארבעה חלקים מתשעה",
  "פַּלְגּוּרַשׁ", "גומא", "אשכול", "עקרב", "אפר", "חיטה", "נהר",
  "צחוק", "אכד", "קרן", "הכד הריק",
]);

const MONTH_NAMES = Object.freeze([
  "טין", "רימון", "מרפק", "קנאה", "ארידו", "משחת־שיניים",
  "שלושה חלקים מחמישה", "כַּרְשׁוּמַב", "נמר", "בדיל", "ערפל", "לבונה",
  "כישור", "צלע", "חרוב", "אורוק", "בושה", "גמל", "נחושת", "באר",
  "חלמון", "כוכב", "דבש", "טחול", "אבן־גיר", "שמחה", "תאנה", "נינוה",
  "צפרדע", "זפת", "נר", "הדלת הסגורה", "שומשום", "עורף", "כסף", "שושן",
  "סערה", "חמור", "קמח", "חרטה", "בבל", "לשון", "פשתן", "מלח", "אגס",
  "קשת", "חול",
]);

const GRIND_ROWS = Object.freeze([
  [3n, 5n, 7n, 11n, 0],
  [5n, 7n, 11n, 13n, 1],
  [7n, 11n, 13n, 17n, 2],
  [11n, 13n, 17n, 19n, 3],
  [13n, 17n, 19n, 23n, 4],
  [17n, 19n, 23n, 29n, 0],
  [19n, 23n, 29n, 31n, 1],
  [23n, 29n, 31n, 37n, 2],
  [29n, 31n, 37n, 41n, 3],
  [31n, 37n, 41n, 43n, 4],
  [37n, 41n, 43n, 47n, 0],
]);

const HIDDEN_COEFFICIENTS = Object.freeze([
  [3n, 4n, 6n, 8n],
  [5n, 7n, 10n, 12n],
  [7n, 10n, 14n, 16n],
  [9n, 13n, 18n, 20n],
  [11n, 16n, 22n, 24n],
  [13n, 19n, 26n, 28n],
  [15n, 22n, 30n, 32n],
]);

const HIDDEN_STONE_ORDER = Object.freeze([0, 1, 2, 3, 4, 0, 1]);
const BOWL_PRIMES = Object.freeze([17n, 19n, 23n, 29n, 31n, 37n]);
const DIRECT_MULTIPLIERS = Object.freeze([3n, 5n, 7n]);
const DIRECT_STONES = Object.freeze([0, 1, 2]);
const DROP_MIX_STONES = Object.freeze([0, 1, 2, 3, 4, 0]);

export const FAST_IMPLEMENTATION_INFO = Object.freeze({
  apiVersion: 1,
  implementation: "fast",
  algorithmId: ALGORITHM_ID,
});

function fail(Type, message, code) {
  const error = new Type(message);
  error.code = code;
  throw error;
}

function requireBigInt(value, name) {
  if (typeof value !== "bigint") {
    fail(TypeError, `${name} must be a bigint.`, "ERR_BIGINT_REQUIRED");
  }
  return value;
}

function normalizeYear(value) {
  if (typeof value === "bigint") return value;
  if (typeof value === "number") {
    if (!Number.isSafeInteger(value)) {
      fail(TypeError, "Gregorian year number must be a safe integer.", "ERR_GREGORIAN_YEAR");
    }
    return BigInt(value);
  }
  if (typeof value === "string" && /^[+-]?\d+$/.test(value)) return BigInt(value);
  fail(TypeError, "Gregorian year must be a bigint, safe integer, or decimal integer string.", "ERR_GREGORIAN_YEAR");
}

function floorDiv(a, b) {
  let q = a / b;
  const r = a % b;
  if (r !== 0n && ((r > 0n) !== (b > 0n))) q -= 1n;
  return q;
}

function positiveMod(a, m) {
  const r = a % m;
  return r < 0n ? r + m : r;
}

function keep(value) {
  return positiveMod(value - 1n, GREAT) + 1n;
}

function absBig(value) {
  return value < 0n ? -value : value;
}

function binomial(n, k) {
  if (!Number.isInteger(n) || !Number.isInteger(k) || k < 0 || n < 0 || k > n) return 0n;
  k = Math.min(k, n - k);
  let result = 1n;
  for (let i = 1; i <= k; i += 1) {
    result = (result * BigInt(n - k + i)) / BigInt(i);
  }
  return result;
}

function permutationsCount(n, k) {
  if (k < 0 || k > n) return 0n;
  let result = 1n;
  for (let i = 0; i < k; i += 1) result *= BigInt(n - i);
  return result;
}

function clonePlainDateJSON(value) {
  return {
    year: value.year,
    cutletName: value.cutletName,
    dayInCutlet: value.dayInCutlet,
    monthName: value.monthName,
    dayInMonth: value.dayInMonth,
  };
}

function freezePlainDateJSON(value) {
  return Object.freeze(clonePlainDateJSON(value));
}

class LruMap {
  constructor(limit, diagnosticName = null) {
    this.limit = limit;
    this.diagnosticName = diagnosticName;
    this.map = new Map();
  }

  get(key) {
    const value = this.map.get(key);
    if (this.diagnosticName) {
      recordDiagnosticCacheLookup(this.diagnosticName, value !== undefined);
      setDiagnosticGauge(`${this.diagnosticName}.size`, this.map.size);
    }
    if (value === undefined) return undefined;
    this.map.delete(key);
    this.map.set(key, value);
    return value;
  }

  set(key, value) {
    const replacing = this.map.has(key);
    if (replacing) this.map.delete(key);
    this.map.set(key, value);
    if (this.diagnosticName) {
      incrementDiagnosticCounter(`${this.diagnosticName}.${replacing ? "replacement" : "insertion"}`);
      setDiagnosticGauge(`${this.diagnosticName}.size`, this.map.size);
    }
    if (this.map.size > this.limit) {
      const oldest = this.map.keys().next().value;
      this.map.delete(oldest);
      if (this.diagnosticName) {
        recordDiagnosticCacheEviction(this.diagnosticName);
        setDiagnosticGauge(`${this.diagnosticName}.size`, this.map.size);
      }
    }
  }

  clear() {
    this.map.clear();
    if (this.diagnosticName) {
      incrementDiagnosticCounter(`${this.diagnosticName}.clear`);
      setDiagnosticGauge(`${this.diagnosticName}.size`, 0);
    }
  }

  get size() {
    return this.map.size;
  }
}

export class GregorianDate {
  constructor(year, month, day) {
    this.year = normalizeYear(year);
    if (!Number.isInteger(month)) {
      fail(TypeError, "Gregorian month must be an integer.", "ERR_GREGORIAN_MONTH");
    }
    if (!Number.isInteger(day)) {
      fail(TypeError, "Gregorian day must be an integer.", "ERR_GREGORIAN_DAY");
    }
    this.month = month;
    this.day = day;
    Object.freeze(this);
  }

  toJSON() {
    return { year: this.year.toString(), month: this.month, day: this.day };
  }
}

function isGregorianLeapYear(year) {
  return year % 4n === 0n && (year % 100n !== 0n || year % 400n === 0n);
}

function gregorianMonthLength(year, month) {
  if (month === 2) return isGregorianLeapYear(year) ? 29 : 28;
  return [4, 6, 9, 11].includes(month) ? 30 : 31;
}

export function validateGregorian(date) {
  if (!(date instanceof GregorianDate)) {
    fail(TypeError, "Expected a GregorianDate.", "ERR_GREGORIAN_TYPE");
  }
  if (date.month < 1 || date.month > 12) {
    fail(RangeError, "Gregorian month is outside 1..12.", "ERR_GREGORIAN_MONTH");
  }
  const maxDay = gregorianMonthLength(date.year, date.month);
  if (date.day < 1 || date.day > maxDay) {
    fail(RangeError, "Gregorian day is outside the valid range for the month.", "ERR_GREGORIAN_DAY");
  }
  return true;
}

export function gregorianToJdn(date) {
  validateGregorian(date);
  const month = BigInt(date.month);
  const day = BigInt(date.day);
  const a = floorDiv(14n - month, 12n);
  const y = date.year + 4800n - a;
  const m = month + 12n * a - 3n;
  return day
    + floorDiv(153n * m + 2n, 5n)
    + 365n * y
    + floorDiv(y, 4n)
    - floorDiv(y, 100n)
    + floorDiv(y, 400n)
    - 32045n;
}

export function localToday() {
  const now = new Date();
  return new GregorianDate(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

export class PastafariDate {
  constructor(year, cutletName, dayInCutlet, monthName, dayInMonth) {
    this.year = typeof year === "bigint" ? year : BigInt(year);
    this.cutletName = String(cutletName);
    this.dayInCutlet = dayInCutlet;
    this.monthName = String(monthName);
    this.dayInMonth = dayInMonth;
    Object.freeze(this);
  }

  toJSON() {
    return {
      year: this.year.toString(),
      cutletName: this.cutletName,
      dayInCutlet: this.dayInCutlet,
      monthName: this.monthName,
      dayInMonth: this.dayInMonth,
    };
  }
}

let stoneTable = null;

function getStoneTable() {
  if (stoneTable !== null) return stoneTable;
  const rows = new Array(46);
  rows[0] = Object.freeze([17n, 29n, 43n, 71n, 101n]);
  for (let i = 1; i < 46; i += 1) {
    const old = rows[i - 1];
    const dropNumber = BigInt(i + 1);
    rows[i] = Object.freeze([
      keep(old[0] * old[0] + 3n * old[1] + dropNumber),
      keep(old[1] * old[1] + 5n * old[2] + old[0]),
      keep(old[2] * old[2] + 7n * old[3] + old[1]),
      keep(old[3] * old[3] + 11n * old[4] + old[2]),
      keep(old[4] * old[4] + 13n * old[0] + old[3]),
    ]);
  }
  stoneTable = Object.freeze(rows);
  return stoneTable;
}

function dayNumber(jdn) {
  const delta = jdn - FOUNDATION_JDN;
  if (delta === 0n) return 1n;
  return delta > 0n ? 2n * delta + 1n : -2n * delta;
}

function bowlPermutation(rank1) {
  let rank = Number(rank1 - 1n);
  const available = [0, 1, 2, 3, 4, 5];
  const result = new Array(6);
  const factorial = [1, 1, 2, 6, 24, 120, 720];
  for (let pos = 0; pos < 6; pos += 1) {
    const block = factorial[5 - pos];
    const index = Math.floor(rank / block);
    rank %= block;
    result[pos] = available.splice(index, 1)[0];
  }
  return result;
}

function sauce(calculationJdn, targetJdn) {
  const stones = getStoneTable();
  const calculation = dayNumber(calculationJdn);
  const target = dayNumber(targetJdn);
  const distance = absBig(targetJdn - calculationJdn) + 1n;
  const sum = calculation + target;
  const direction = targetJdn < calculationJdn ? 1n : targetJdn === calculationJdn ? 2n : 3n;

  const hidden = new Array(7);
  for (let i = 0; i < 7; i += 1) {
    const coeff = HIDDEN_COEFFICIENTS[i];
    const s = stones[i];
    let x = calculation
      + coeff[0] * target
      + coeff[1] * distance
      + coeff[2] * sum
      + coeff[3] * direction
      + s[0] + s[1] + s[2] + s[3] + s[4];
    x = keep(x);
    for (let round = 0; round < 7; round += 1) {
      const before = x;
      x = keep(before * before + 3n * before + s[HIDDEN_STONE_ORDER[round]] + BigInt(round + 1));
    }
    hidden[i] = x;
  }

  const drops = new Array(46);
  const prior = (dropIndex1, back) => {
    const wanted = dropIndex1 - back;
    if (wanted >= 1) return drops[wanted - 1];
    return hidden[back - dropIndex1];
  };

  let bowls = new Array(6);
  for (let i = 0; i < 6; i += 1) {
    const bowlNumber = BigInt(i + 1);
    const x = calculation + target * bowlNumber + distance + sum + direction + BOWL_PRIMES[i] ** 2n;
    bowls[i] = keep(x * x + bowlNumber);
  }

  let lastDropPermutation = null;
  for (let i0 = 0; i0 < 46; i0 += 1) {
    const i = i0 + 1;
    const ib = BigInt(i);
    const s = stones[i0];
    const p1 = prior(i, 1);
    const p3 = prior(i, 3);
    const p7 = prior(i, 7);
    let x = keep(
      s[0] * calculation
      + s[1] * target
      + s[2] * distance
      + s[3] * sum
      + s[4] * direction
      + p1 + 3n * p3 + 5n * p7 + ib,
    );
    for (const row of GRIND_ROWS) {
      const before = x;
      x = keep(
        before * before
        + row[0] * before
        + row[1] * p1
        + row[2] * p3
        + row[3] * p7
        + s[row[4]],
      );
    }
    drops[i0] = x;

    const permutationRank = 1n + ((x - 1n) % 720n);
    const order = bowlPermutation(permutationRank);
    if (i === 46) lastDropPermutation = order.slice();

    const direct = new Array(6).fill(0n);
    for (let place = 0; place < 3; place += 1) {
      const bowlId = order[place];
      direct[bowlId] = keep(
        x * x + s[DIRECT_STONES[place]] * bowls[bowlId] + DIRECT_MULTIPLIERS[place] * ib,
      );
    }

    const old = bowls;
    const nextBowls = new Array(6);
    for (let place = 0; place < 6; place += 1) {
      const bowlId = order[place];
      const previousId = order[(place + 5) % 6];
      const nextId = order[(place + 1) % 6];
      const u = old[bowlId]
        + 2n * old[previousId]
        + 3n * old[nextId]
        + direct[bowlId]
        + x
        + s[DROP_MIX_STONES[place]];
      nextBowls[bowlId] = keep(
        u * u + 5n * old[previousId] * old[nextId] + ib * BigInt(place + 1),
      );
    }
    bowls = nextBowls;
  }

  for (let round = 1; round <= 12; round += 1) {
    const roundBig = BigInt(round);
    let bowlSum = 0n;
    for (const value of bowls) bowlSum += value;
    const orderNumber = keep(bowlSum + 149n * roundBig);
    const order = bowlPermutation(1n + ((orderNumber - 1n) % 720n));
    const old = bowls;
    const nextBowls = new Array(6);
    for (let place = 0; place < 6; place += 1) {
      const bowlId = order[place];
      const previousId = order[(place + 5) % 6];
      const nextId = order[(place + 1) % 6];
      const u = old[bowlId]
        + 3n * old[previousId]
        + 5n * old[nextId]
        + orderNumber
        + roundBig
        + BigInt((place + 1) * (place + 1));
      nextBowls[bowlId] = keep(u * u + 7n * old[previousId] * old[nextId]);
    }
    bowls = nextBowls;
  }

  return Object.freeze({ bowls: Object.freeze(bowls), lastDropPermutation: Object.freeze(lastDropPermutation) });
}

function responseDescriptor(sauceResult, bowlId, sealNumber) {
  const seal = BigInt(sealNumber);
  const nextPlace = (sauceResult.lastDropPermutation.indexOf(bowlId) + 1) % 6;
  const nextBowlId = sauceResult.lastDropPermutation[nextPlace];
  const firstBase = sauceResult.bowls[bowlId] + seal + 181n;
  const first = keep(
    firstBase * firstBase + 179n * sauceResult.bowls[nextBowlId] + seal,
  );
  const directionBase = first + seal + 1n + 193n;
  const directionNumber = keep(
    directionBase * directionBase + 193n * first + 197n * sauceResult.bowls[5],
  );
  return Object.freeze({ first, step: (directionNumber & 1n) === 1n ? 1n : -1n });
}

function responseAt(descriptor, offset) {
  return positiveMod(descriptor.first - 1n + descriptor.step * BigInt(offset), GREAT) + 1n;
}

function chooseUniform(sauceResult, bowlId, seal, count) {
  if (typeof count !== "bigint" || count < 1n) {
    fail(RangeError, "Choice count must be a positive bigint.", "ERR_CHOICE_COUNT");
  }
  const descriptor = responseDescriptor(sauceResult, bowlId, seal);
  if (count <= GREAT) {
    const limit = GREAT - (GREAT % count);
    let accepted = descriptor.first;
    if (accepted > limit) accepted = descriptor.step > 0n ? 1n : limit;
    return ((accepted - 1n) % count) + 1n;
  }

  let width = 1;
  let space = GREAT;
  while (space < count) {
    space *= GREAT;
    width += 1;
  }
  let value = 1n;
  let weight = 1n;
  for (let i = 0; i < width; i += 1) {
    value += (responseAt(descriptor, i) - 1n) * weight;
    weight *= GREAT;
  }
  const limit = space - (space % count);
  let accepted = value;
  if (accepted > limit) accepted = descriptor.step > 0n ? 1n : limit;
  return ((accepted - 1n) % count) + 1n;
}

const gateDistanceCache = new LruMap(4096, "fast.cache.gate-distance");
const dynamicGatePositions = new LruMap(4096, "fast.cache.gate-position");
dynamicGatePositions.set(0n, FOUNDATION_JDN);
let gateTraversalCursorIndex = 0n;
let gateTraversalCursorPosition = FOUNDATION_JDN;

// Build-time generated checkpoints are inserted here. The zero checkpoint alone is
// correct; the generated table only reduces the cold-start cost for distant epochs.
const GATE_CHECKPOINTS = Object.freeze([
  Object.freeze([-32768, -29780582n]), Object.freeze([-31744, -29275011n]),
  Object.freeze([-30720, -28759536n]), Object.freeze([-29696, -28231334n]),
  Object.freeze([-28672, -27724269n]), Object.freeze([-27648, -27204151n]),
  Object.freeze([-26624, -26696050n]), Object.freeze([-25600, -26184520n]),
  Object.freeze([-24576, -25649224n]), Object.freeze([-23552, -25126420n]),
  Object.freeze([-22528, -24592746n]), Object.freeze([-21504, -24077763n]),
  Object.freeze([-20480, -23568941n]), Object.freeze([-19456, -23056607n]),
  Object.freeze([-18432, -22547059n]), Object.freeze([-17408, -22028964n]),
  Object.freeze([-16384, -21524216n]), Object.freeze([-15360, -21021341n]),
  Object.freeze([-14336, -20503094n]), Object.freeze([-13312, -19986054n]),
  Object.freeze([-12288, -19477387n]), Object.freeze([-11264, -18959976n]),
  Object.freeze([-10240, -18453214n]), Object.freeze([-9216, -17930941n]),
  Object.freeze([-8192, -17421559n]), Object.freeze([-7168, -16901500n]),
  Object.freeze([-6144, -16391773n]), Object.freeze([-5120, -15892677n]),
  Object.freeze([-4096, -15374389n]), Object.freeze([-3072, -14869256n]),
  Object.freeze([-2048, -14360710n]), Object.freeze([-1024, -13845543n]),
  Object.freeze([0, -13334246n]), Object.freeze([1024, -12809003n]),
  Object.freeze([2048, -12289556n]), Object.freeze([3072, -11790578n]),
  Object.freeze([4096, -11286642n]), Object.freeze([5120, -10764244n]),
  Object.freeze([6144, -10233818n]), Object.freeze([7168, -9727528n]),
  Object.freeze([8192, -9214186n]), Object.freeze([9216, -8692730n]),
  Object.freeze([10240, -8173976n]), Object.freeze([11264, -7657486n]),
  Object.freeze([12288, -7145425n]), Object.freeze([13312, -6630698n]),
  Object.freeze([14336, -6127086n]), Object.freeze([15360, -5610968n]),
  Object.freeze([16384, -5103400n]), Object.freeze([17408, -4587432n]),
  Object.freeze([18432, -4069417n]), Object.freeze([19456, -3557452n]),
  Object.freeze([20480, -3038147n]), Object.freeze([21504, -2527530n]),
  Object.freeze([22528, -2008636n]), Object.freeze([23552, -1489691n]),
  Object.freeze([24576, -975725n]), Object.freeze([25600, -476208n]),
  Object.freeze([26624, 32147n]), Object.freeze([27648, 532296n]),
  Object.freeze([28672, 1047264n]), Object.freeze([29696, 1552344n]),
  Object.freeze([30720, 2076748n]), Object.freeze([31744, 2600784n]),
  Object.freeze([32768, 3111357n]),
]);

function gateDistance(index) {
  if (typeof index !== "bigint" || index === 0n) {
    fail(TypeError, "Gate distance index must be a non-zero bigint.", "ERR_GATE_INDEX");
  }
  const cached = gateDistanceCache.get(index);
  if (cached !== undefined) return cached;
  const target = FOUNDATION_JDN + index;
  const result = sauce(FOUNDATION_JDN, target);
  const picked = chooseUniform(result, 0, 1, 922n);
  const distance = Number(picked) + 41;
  gateDistanceCache.set(index, distance);
  return distance;
}

function nearestCheckpoint(index) {
  let lo = 0;
  let hi = GATE_CHECKPOINTS.length - 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    const value = BigInt(GATE_CHECKPOINTS[mid][0]);
    if (value === index) return GATE_CHECKPOINTS[mid];
    if (value < index) lo = mid + 1;
    else hi = mid - 1;
  }
  const left = hi >= 0 ? GATE_CHECKPOINTS[hi] : null;
  const right = lo < GATE_CHECKPOINTS.length ? GATE_CHECKPOINTS[lo] : null;
  if (left === null) return right;
  if (right === null) return left;
  const leftDistance = index - BigInt(left[0]);
  const rightDistance = BigInt(right[0]) - index;
  return leftDistance <= rightDistance ? left : right;
}

function gatePosition(index) {
  if (typeof index !== "bigint") {
    fail(TypeError, "Gate index must be a bigint.", "ERR_GATE_INDEX");
  }
  const cached = dynamicGatePositions.get(index);
  if (cached !== undefined) {
    gateTraversalCursorIndex = index;
    gateTraversalCursorPosition = cached;
    return cached;
  }
  const checkpoint = nearestCheckpoint(index);
  const checkpointIndex = BigInt(checkpoint[0]);
  const checkpointDistance = absBig(index - checkpointIndex);
  const cursorDistance = absBig(index - gateTraversalCursorIndex);
  let currentIndex;
  let position;
  let checkpointSource;
  incrementDiagnosticCounter("fast.checkpoint.lookups");
  if (cursorDistance < checkpointDistance) {
    currentIndex = gateTraversalCursorIndex;
    position = gateTraversalCursorPosition;
    checkpointSource = "traversal-cursor";
    incrementDiagnosticCounter("fast.checkpoint.cursor-starts");
  } else {
    currentIndex = checkpointIndex;
    position = checkpoint[1];
    checkpointSource = "static-precomputed";
    incrementDiagnosticCounter("fast.checkpoint.static-starts");
  }
  const selectedStartIndex = currentIndex;
  const selectedDistance = absBig(index - selectedStartIndex);
  let steps = 0;
  setDiagnosticGauge("fast.checkpoint.last.static-index", checkpointIndex);
  setDiagnosticGauge("fast.checkpoint.last.selected-index", currentIndex);
  setDiagnosticGauge("fast.checkpoint.last.target-index", index);
  setDiagnosticGauge("fast.checkpoint.last.static-distance", checkpointDistance);
  setDiagnosticGauge("fast.checkpoint.last.distance", selectedDistance);
  setDiagnosticGauge("fast.checkpoint.last.source", checkpointSource);
  setDiagnosticGauge("fast.checkpoint.last.direction", currentIndex < index ? "forward" : currentIndex > index ? "backward" : "exact");
  if (currentIndex < index) {
    while (currentIndex < index) {
      if (currentIndex < 0n) position += BigInt(gateDistance(currentIndex));
      else position += BigInt(gateDistance(currentIndex + 1n));
      currentIndex += 1n;
      steps += 1;
      dynamicGatePositions.set(currentIndex, position);
    }
  } else {
    while (currentIndex > index) {
      if (currentIndex > 0n) position -= BigInt(gateDistance(currentIndex));
      else position -= BigInt(gateDistance(currentIndex - 1n));
      currentIndex -= 1n;
      steps += 1;
      dynamicGatePositions.set(currentIndex, position);
    }
  }
  dynamicGatePositions.set(index, position);
  gateTraversalCursorIndex = index;
  gateTraversalCursorPosition = position;
  incrementDiagnosticCounter("fast.checkpoint.steps", steps);
  diagnosticTrace("fast", "checkpoint-traversal", {
    targetIndex: index,
    checkpointIndex,
    selectedIndex: selectedStartIndex,
    staticDistance: checkpointDistance,
    distance: selectedDistance,
    direction: selectedStartIndex < index ? "forward" : selectedStartIndex > index ? "backward" : "exact",
    steps,
    checkpointSource,
  });
  return position;
}

function checkpointBracketForDay(jdn) {
  let lo = 0;
  let hi = GATE_CHECKPOINTS.length;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (GATE_CHECKPOINTS[mid][1] < jdn) lo = mid + 1;
    else hi = mid;
  }
  if (lo === 0) return BigInt(GATE_CHECKPOINTS[0][0]);
  if (lo === GATE_CHECKPOINTS.length) return BigInt(GATE_CHECKPOINTS.at(-1)[0]);
  return BigInt(GATE_CHECKPOINTS[lo - 1][0]);
}

function containingGateInterval(jdn) {
  let index = checkpointBracketForDay(jdn);
  let position = gatePosition(index);
  if (position >= jdn) {
    while (position >= jdn) {
      index -= 1n;
      position = gatePosition(index);
    }
    return index;
  }
  while (gatePosition(index + 1n) < jdn) index += 1n;
  return index;
}

function enumerateYear5000Candidates(calculationJdn) {
  const interval = containingGateInterval(calculationJdn);
  const openings = [];
  for (let p = interval; ; p -= 1n) {
    const position = gatePosition(p);
    if (calculationJdn - position > BigInt(MAX_YEAR_DAYS)) break;
    openings.push([p, position]);
  }
  const closings = [];
  for (let q = interval + 1n; ; q += 1n) {
    const position = gatePosition(q);
    if (position - calculationJdn > BigInt(MAX_YEAR_DAYS)) break;
    closings.push([q, position]);
  }
  const candidates = [];
  for (const [p, opening] of openings) {
    for (const [q, closing] of closings) {
      const gaps = Number(q - p);
      if (gaps < MIN_YEAR_GAPS) continue;
      const length = Number(closing - opening);
      if (length < MIN_YEAR_DAYS || length > MAX_YEAR_DAYS) continue;
      candidates.push({ p, q, opening, closing, length });
    }
  }
  candidates.sort((a, b) => a.length - b.length || (a.p < b.p ? -1 : a.p > b.p ? 1 : 0));
  return candidates;
}

function yearObject(number, p, q) {
  const opening = gatePosition(p);
  const closing = gatePosition(q);
  return Object.freeze({
    number,
    p,
    q,
    startJdn: opening + 1n,
    endJdn: closing,
    length: Number(closing - opening),
    gaps: Number(q - p),
  });
}

function enumerateNextYears(openIndex) {
  const opening = gatePosition(openIndex);
  const candidates = [];
  for (let q = openIndex + BigInt(MIN_YEAR_GAPS); ; q += 1n) {
    const closing = gatePosition(q);
    const length = Number(closing - opening);
    if (length > MAX_YEAR_DAYS) break;
    if (length >= MIN_YEAR_DAYS) candidates.push({ q, length });
  }
  candidates.sort((a, b) => a.length - b.length || (a.q < b.q ? -1 : a.q > b.q ? 1 : 0));
  return candidates;
}

function enumeratePreviousYears(closeIndex) {
  const closing = gatePosition(closeIndex);
  const candidates = [];
  for (let p = closeIndex - BigInt(MIN_YEAR_GAPS); ; p -= 1n) {
    const opening = gatePosition(p);
    const length = Number(closing - opening);
    if (length > MAX_YEAR_DAYS) break;
    if (length >= MIN_YEAR_DAYS) candidates.push({ p, length });
  }
  candidates.sort((a, b) => a.length - b.length || (a.p < b.p ? -1 : a.p > b.p ? 1 : 0));
  return candidates;
}

function unrankPermutationNames(names, count, rank1) {
  const available = names.slice();
  const result = new Array(count);
  let rank = rank1 - 1n;
  for (let pos = 0; pos < count; pos += 1) {
    const block = permutationsCount(available.length - 1, count - pos - 1);
    const index = block === 0n ? 0 : Number(rank / block);
    rank = block === 0n ? 0n : rank % block;
    result[pos] = available.splice(index, 1)[0];
  }
  return result;
}

function compositionSuffixCount(remaining, parts, mandatoryOffset) {
  if (parts === 0) return remaining === 0 && (mandatoryOffset === null || mandatoryOffset === 0) ? 1n : 0n;
  if (remaining < parts) return 0n;
  if (mandatoryOffset === null || mandatoryOffset === 0) return binomial(remaining - 1, parts - 1);
  if (mandatoryOffset <= 0 || mandatoryOffset >= remaining || parts < 2) return 0n;
  return binomial(remaining - 2, parts - 2);
}

function unrankComposition(total, parts, mandatoryCut, rank1) {
  const result = [];
  let remaining = total;
  let cumulative = 0;
  let rank = rank1;
  let hit = mandatoryCut === null;
  for (let pos = 0; pos < parts; pos += 1) {
    const left = parts - pos - 1;
    const maxValue = remaining - left;
    for (let value = 1; value <= maxValue; value += 1) {
      const after = remaining - value;
      const newCumulative = cumulative + value;
      const newHit = hit || newCumulative === mandatoryCut;
      let mandatoryOffset = null;
      if (!newHit) {
        if (mandatoryCut < newCumulative) continue;
        mandatoryOffset = mandatoryCut - newCumulative;
      }
      const block = compositionSuffixCount(after, left, newHit ? null : mandatoryOffset);
      if (rank > block) {
        rank -= block;
        continue;
      }
      result.push(value);
      remaining = after;
      cumulative = newCumulative;
      hit = newHit;
      break;
    }
  }
  return result;
}

function boundedMonthLengthCount(total, parts) {
  const shifted = total - 4 * parts;
  if (shifted < 0 || shifted > 119 * parts) return 0n;
  let answer = 0n;
  const maxJ = Math.min(parts, Math.floor(shifted / 120));
  for (let j = 0; j <= maxJ; j += 1) {
    const ways = binomial(parts, j) * binomial(shifted - 120 * j + parts - 1, parts - 1);
    answer += (j & 1) === 0 ? ways : -ways;
  }
  return answer;
}

function unrankMonthLengths(total, parts, rank1) {
  const result = [];
  let remaining = total;
  let rank = rank1;
  const memo = new Map();
  const count = (sum, n) => {
    const key = `${sum}:${n}`;
    let value = memo.get(key);
    if (value === undefined) {
      value = boundedMonthLengthCount(sum, n);
      memo.set(key, value);
    }
    return value;
  };
  for (let pos = 0; pos < parts; pos += 1) {
    const left = parts - pos - 1;
    const low = 4;
    const high = Math.min(123, remaining - 4 * left);
    for (let value = low; value <= high; value += 1) {
      const after = remaining - value;
      const block = left === 0 ? (after === 0 ? 1n : 0n) : count(after, left);
      if (rank > block) {
        rank -= block;
        continue;
      }
      result.push(value);
      remaining = after;
      break;
    }
  }
  return result;
}

function interleaveWeight(n, r) {
  return binomial(n + r - 2, r);
}

class InterleavingCounter {
  constructor(lengths) {
    this.lengths = lengths;
    this.cache = new Map();
  }

  get(lastSeen, q) {
    const last = this.lengths.length - 1;
    if (lastSeen >= last) return 1n;
    const cached = this.cache.get(lastSeen);
    if (cached !== undefined && cached.length > q) return cached[q];
    this.rebuild(lastSeen, q);
    return this.cache.get(lastSeen)[q];
  }

  rebuild(start, qStart) {
    const m = this.lengths.length;
    const needed = new Array(m).fill(0);
    needed[start] = qStart;
    for (let i = start; i < m - 1; i += 1) {
      needed[i + 1] = needed[i] + this.lengths[i + 1] - 1;
    }

    let next = null;
    this.cache.clear();
    for (let i = m - 1; i >= start; i -= 1) {
      const qMax = needed[i];
      let current;
      if (i === m - 1) {
        current = new Array(qMax + 1).fill(1n);
      } else {
        current = new Array(qMax + 1);
        current[0] = 0n;
        const n = this.lengths[i + 1];
        let cumulative = 0n;
        let weight = 1n;
        for (let q = 1; q <= qMax; q += 1) {
          const r = q - 1;
          cumulative += weight * next[n + r];
          current[q] = cumulative;
          weight = (weight * BigInt(n + r - 1)) / BigInt(r + 1);
        }
      }
      next = current;
      // Keep a small look-ahead window. This avoids most rebuilds while bounding
      // the transient BigInt table used only during one year's unranking.
      if (i <= start + 7) this.cache.set(i, current);
    }
  }
}

function unrankMonthInterleaving(lengths, rank1) {
  const m = lengths.length;
  const totalLength = lengths.reduce((a, b) => a + b, 0);
  const counter = new InterleavingCounter(lengths);
  const weave = new Uint8Array(totalLength);
  const rem = lengths.slice();
  weave[0] = 0;
  rem[0] -= 1;
  let low = 0;
  let high = 0;
  let activeTotal = rem[0];
  let baseCount = 1n;
  let rank = rank1;

  const expectedTotal = counter.get(0, activeTotal + 1);
  if (rank < 1n || rank > expectedTotal) {
    fail(RangeError, "Interleaving rank is outside the valid range.", "ERR_INTERLEAVING_RANK");
  }

  for (let pos = 1; pos < totalLength; pos += 1) {
    const prefix = new Array(Math.max(0, high - low + 1));
    let running = 0;
    for (let i = low; i <= high; i += 1) {
      running += rem[i];
      prefix[i - low] = running;
    }
    const span = prefix.length;
    const suffixP = new Array(span + 1).fill(1n);
    const suffixPm1 = new Array(span + 1).fill(1n);
    for (let off = span - 1; off >= 0; off -= 1) {
      suffixP[off] = suffixP[off + 1] * BigInt(prefix[off]);
      suffixPm1[off] = suffixPm1[off + 1] * BigInt(prefix[off] - 1);
    }

    const futureSame = high < m - 1 ? counter.get(high, activeTotal) : 1n;
    let selected = false;
    for (let k = low; k <= high; k += 1) {
      const remainingForK = rem[k];
      if (remainingForK === 1 && k !== low) continue;
      const off = k - low;
      let numerator;
      let denominator;
      if (remainingForK > 1) {
        numerator = BigInt(remainingForK - 1) * suffixP[off];
        denominator = BigInt(activeTotal) * suffixPm1[off];
      } else {
        numerator = suffixP[off + 1];
        denominator = BigInt(activeTotal) * suffixPm1[off + 1];
      }
      const nextBaseCount = (baseCount * numerator) / denominator;
      const block = nextBaseCount * futureSame;
      if (rank > block) {
        rank -= block;
        continue;
      }
      weave[pos] = k;
      rem[k] -= 1;
      activeTotal -= 1;
      baseCount = nextBaseCount;
      if (rem[k] === 0) low += 1;
      selected = true;
      break;
    }
    if (selected) continue;

    if (high + 1 >= m) {
      fail(Error, "Interleaving unranking exhausted all valid branches.", "ERR_INTERLEAVING_INTERNAL");
    }
    const k = high + 1;
    const newRemaining = lengths[k] - 1;
    const nextBaseCount = baseCount * binomial(activeTotal + newRemaining - 1, newRemaining - 1);
    const nextActiveTotal = activeTotal + newRemaining;
    const future = k < m - 1 ? counter.get(k, nextActiveTotal + 1) : 1n;
    const block = nextBaseCount * future;
    if (rank > block) {
      fail(Error, "Interleaving rank exceeded the final lexicographic branch.", "ERR_INTERLEAVING_INTERNAL");
    }
    weave[pos] = k;
    high = k;
    rem[k] -= 1;
    if (low > k - 1) low = k;
    activeTotal = nextActiveTotal;
    baseCount = nextBaseCount;
  }
  return weave;
}

function interleavingCount(lengths) {
  const counter = new InterleavingCounter(lengths);
  return counter.get(0, lengths[0]);
}

class CalculationState {
  constructor(calculationJdn) {
    this.calculationJdn = calculationJdn;
    this.sauceCache = new LruMap(64, "fast.cache.sauce");
    this.structureCache = new LruMap(8, "fast.cache.structure");
    this.yearsByNumber = new Map();
    this.year5000 = null;
  }

  getSauce(targetJdn) {
    const key = targetJdn.toString();
    const cached = this.sauceCache.get(key);
    if (cached !== undefined) return cached;
    const result = sauce(this.calculationJdn, targetJdn);
    this.sauceCache.set(key, result);
    return result;
  }

  getYear5000() {
    if (this.year5000 !== null) {
      recordDiagnosticCacheLookup("fast.cache.year-5000", true);
      return this.year5000;
    }
    recordDiagnosticCacheLookup("fast.cache.year-5000", false);
    const candidates = enumerateYear5000Candidates(this.calculationJdn);
    incrementDiagnosticCounter("fast.year-5000.candidates", candidates.length);
    if (candidates.length === 0) {
      fail(Error, "No valid year-5000 candidate was found.", "ERR_YEAR_5000");
    }
    const choice = chooseUniform(this.getSauce(this.calculationJdn), 0, 10, BigInt(candidates.length));
    const selected = candidates[Number(choice - 1n)];
    const year = yearObject(5000n, selected.p, selected.q);
    this.year5000 = year;
    incrementDiagnosticCounter("fast.cache.year-5000.insertion");
    this.yearsByNumber.set("5000", year);
    incrementDiagnosticCounter("fast.cache.year-by-number.insertion");
    setDiagnosticGauge("fast.cache.year-by-number.size", this.yearsByNumber.size);
    return year;
  }

  nextYear(year) {
    const number = year.number + 1n;
    const key = number.toString();
    const cached = this.yearsByNumber.get(key);
    recordDiagnosticCacheLookup("fast.cache.year-by-number", cached !== undefined);
    setDiagnosticGauge("fast.cache.year-by-number.size", this.yearsByNumber.size);
    if (cached !== undefined) return cached;
    const candidates = enumerateNextYears(year.q);
    incrementDiagnosticCounter("fast.year.candidates.next", candidates.length);
    const s = this.getSauce(gatePosition(year.q));
    const choice = chooseUniform(s, 0, 11, BigInt(candidates.length));
    const selected = candidates[Number(choice - 1n)];
    const result = yearObject(number, year.q, selected.q);
    this.yearsByNumber.set(key, result);
    incrementDiagnosticCounter("fast.cache.year-by-number.insertion");
    setDiagnosticGauge("fast.cache.year-by-number.size", this.yearsByNumber.size);
    return result;
  }

  previousYear(year) {
    const number = year.number - 1n;
    const key = number.toString();
    const cached = this.yearsByNumber.get(key);
    recordDiagnosticCacheLookup("fast.cache.year-by-number", cached !== undefined);
    setDiagnosticGauge("fast.cache.year-by-number.size", this.yearsByNumber.size);
    if (cached !== undefined) return cached;
    const candidates = enumeratePreviousYears(year.p);
    incrementDiagnosticCounter("fast.year.candidates.previous", candidates.length);
    const s = this.getSauce(gatePosition(year.p));
    const choice = chooseUniform(s, 0, 12, BigInt(candidates.length));
    const selected = candidates[Number(choice - 1n)];
    const result = yearObject(number, selected.p, year.p);
    this.yearsByNumber.set(key, result);
    incrementDiagnosticCounter("fast.cache.year-by-number.insertion");
    setDiagnosticGauge("fast.cache.year-by-number.size", this.yearsByNumber.size);
    return result;
  }

  findYear(targetJdn) {
    const token = beginDiagnosticOperation("fast", "find-year", {
      targetDistanceFromCalculation: targetJdn - this.calculationJdn,
    });
    let steps = 0;
    let direction = "anchor";
    try {
      let year = this.getYear5000();
      if (targetJdn < year.startJdn) {
        direction = "previous";
        while (targetJdn < year.startJdn) {
          year = this.previousYear(year);
          steps += 1;
        }
      } else if (targetJdn > year.endJdn) {
        direction = "next";
        while (targetJdn > year.endJdn) {
          year = this.nextYear(year);
          steps += 1;
        }
      }
      incrementDiagnosticCounter("fast.year-traversal.steps", steps);
      incrementDiagnosticCounter(`fast.year-traversal.direction.${direction}`);
      setDiagnosticGauge("fast.year-traversal.last.start-year", 5000);
      setDiagnosticGauge("fast.year-traversal.last.resolved-year", year.number);
      setDiagnosticGauge("fast.year-traversal.last.steps", steps);
      setDiagnosticGauge("fast.year-traversal.last.direction", direction);
      endDiagnosticOperation(token, "ok", {
        startYear: 5000,
        resolvedYear: year.number,
        targetJdn,
        steps,
        direction,
      });
      return year;
    } catch (error) {
      recordDiagnosticError("fast", error, token?.id, { phase: "find-year", steps, direction });
      endDiagnosticOperation(token, "error", { steps, direction });
      throw error;
    }
  }

  getStructure(year) {
    const key = `${year.p}:${year.q}`;
    const cached = this.structureCache.get(key);
    if (cached !== undefined) return cached;
    const result = buildYearStructure(this, year);
    this.structureCache.set(key, result);
    return result;
  }

  materialize(targetJdn) {
    const year = this.findYear(targetJdn);
    const structure = this.getStructure(year);
    const token = beginDiagnosticOperation("fast", "resolve-date", { year: year.number });
    try {
      const result = materializeFromStructure(year, structure, targetJdn);
      endDiagnosticOperation(token, "ok");
      return result;
    } catch (error) {
      recordDiagnosticError("fast", error, token?.id, { phase: "resolve-date" });
      endDiagnosticOperation(token, "error");
      throw error;
    }
  }
}

function buildYearStructure(state, year) {
  const token = beginDiagnosticOperation("fast", "build-year-structure", {
    length: year.length,
    gaps: year.gaps,
  });
  let activePhaseToken = null;
  let activePhase = "initialize";
  try {
  const s = state.getSauce(year.startJdn);
  const gapCount = year.gaps;
  activePhase = "construct-cutlets";
  activePhaseToken = beginDiagnosticOperation("fast", activePhase, { gapCount });
  const cutletCounts = [];
  for (let n = 6; n <= 17 && n <= gapCount; n += 1) cutletCounts.push(n);
  const cutletCountChoice = chooseUniform(s, 1, 20, BigInt(cutletCounts.length));
  const cutletCount = cutletCounts[Number(cutletCountChoice - 1n)];

  let mandatoryCut = null;
  if (state.calculationJdn >= year.startJdn && state.calculationJdn <= year.endJdn) {
    for (let k = year.p + 1n; k < year.q; k += 1n) {
      if (gatePosition(k) === state.calculationJdn) {
        mandatoryCut = Number(k - year.p);
        break;
      }
    }
  }
  const partitionCount = mandatoryCut === null
    ? binomial(gapCount - 1, cutletCount - 1)
    : binomial(gapCount - 2, cutletCount - 2);
  const partitionChoice = chooseUniform(s, 1, 21, partitionCount);
  const cutletGaps = unrankComposition(gapCount, cutletCount, mandatoryCut, partitionChoice);

  const cutletNameCount = permutationsCount(CUTLET_NAMES.length, cutletCount);
  const cutletNameChoice = chooseUniform(s, 4, 22, cutletNameCount);
  const cutletNames = unrankPermutationNames(CUTLET_NAMES, cutletCount, cutletNameChoice);
  endDiagnosticOperation(activePhaseToken, "ok", { cutletCount, mandatoryCut: mandatoryCut !== null });
  activePhaseToken = null;

  activePhase = "construct-months";
  activePhaseToken = beginDiagnosticOperation("fast", activePhase, { yearLength: year.length });
  const minMonths = Math.ceil(year.length / 123);
  const maxMonths = Math.min(47, Math.floor(year.length / 4));
  const monthCountOptions = maxMonths - minMonths + 1;
  const monthCountChoice = chooseUniform(s, 2, 30, BigInt(monthCountOptions));
  const monthCount = minMonths + Number(monthCountChoice - 1n);

  const monthLengthWays = boundedMonthLengthCount(year.length, monthCount);
  const monthLengthChoice = chooseUniform(s, 2, 31, monthLengthWays);
  const monthLengths = unrankMonthLengths(year.length, monthCount, monthLengthChoice);

  const weaveWays = interleavingCount(monthLengths);
  const weaveChoice = chooseUniform(s, 3, 32, weaveWays);
  const monthWeave = unrankMonthInterleaving(monthLengths, weaveChoice);

  const monthNameWays = permutationsCount(MONTH_NAMES.length, monthCount);
  const monthNameChoice = chooseUniform(s, 4, 33, monthNameWays);
  const monthNames = unrankPermutationNames(MONTH_NAMES, monthCount, monthNameChoice);

  const dayInMonth = new Uint8Array(year.length);
  const seen = new Uint16Array(monthCount);
  for (let i = 0; i < monthWeave.length; i += 1) {
    const month = monthWeave[i];
    seen[month] += 1;
    dayInMonth[i] = seen[month];
  }
  endDiagnosticOperation(activePhaseToken, "ok", { monthCount, weaveLength: monthWeave.length });
  activePhaseToken = null;

  activePhase = "resolve-cutlet-boundaries";
  activePhaseToken = beginDiagnosticOperation("fast", activePhase, { cutletCount });
  const cutletStartOffsets = new Uint16Array(cutletCount);
  const cutletEndOffsets = new Uint16Array(cutletCount);
  let gapOffset = 0;
  let dayOffset = 0;
  for (let i = 0; i < cutletCount; i += 1) {
    cutletStartOffsets[i] = dayOffset;
    gapOffset += cutletGaps[i];
    const endJdn = gatePosition(year.p + BigInt(gapOffset));
    dayOffset = Number(endJdn - year.startJdn + 1n);
    cutletEndOffsets[i] = dayOffset - 1;
  }
  endDiagnosticOperation(activePhaseToken, "ok", { cutletCount });
  activePhaseToken = null;

  const result = Object.freeze({
    cutletCount,
    cutletGaps: Object.freeze(cutletGaps.slice()),
    cutletNames: Object.freeze(cutletNames.slice()),
    cutletStartOffsets,
    cutletEndOffsets,
    monthCount,
    monthLengths: Object.freeze(monthLengths.slice()),
    monthNames: Object.freeze(monthNames.slice()),
    monthWeave,
    dayInMonth,
  });
  endDiagnosticOperation(token, "ok", { cutletCount, monthCount });
  return result;
  } catch (error) {
    if (activePhaseToken) endDiagnosticOperation(activePhaseToken, "error", { phase: activePhase });
    recordDiagnosticError("fast", error, token?.id, { phase: activePhase });
    endDiagnosticOperation(token, "error", { phase: activePhase });
    throw error;
  }
}

function findCutletByOffset(structure, offset) {
  let lo = 0;
  let hi = structure.cutletCount - 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (offset < structure.cutletStartOffsets[mid]) hi = mid - 1;
    else if (offset > structure.cutletEndOffsets[mid]) lo = mid + 1;
    else return mid;
  }
  fail(Error, "Day offset was not contained in a cutlet.", "ERR_CUTLET_INTERNAL");
}

function materializeFromStructure(year, structure, targetJdn) {
  const offset = Number(targetJdn - year.startJdn);
  const cutlet = findCutletByOffset(structure, offset);
  const month = structure.monthWeave[offset];
  return new PastafariDate(
    year.number,
    structure.cutletNames[cutlet],
    offset - structure.cutletStartOffsets[cutlet] + 1,
    structure.monthNames[month],
    structure.dayInMonth[offset],
  );
}

const calculationStates = new LruMap(4, "fast.cache.calculation-state");
const resultCache = new LruMap(1024, "fast.cache.result");
let cacheHits = 0;
let cacheMisses = 0;

function getCalculationState(calculationJdn) {
  const key = calculationJdn.toString();
  let state = calculationStates.get(key);
  if (state === undefined) {
    state = new CalculationState(calculationJdn);
    calculationStates.set(key, state);
  }
  return state;
}

function convertWithGlobalCache(targetJdn, calculationJdn) {
  const token = beginDiagnosticOperation("fast", "convert", {
    targetDistanceFromCalculation: targetJdn - calculationJdn,
  });
  const key = `${ALGORITHM_ID}|${calculationJdn}|${targetJdn}`;
  try {
    const cached = resultCache.get(key);
    if (cached !== undefined) {
      cacheHits += 1;
      endDiagnosticOperation(token, "cache-hit");
      return new PastafariDate(
        BigInt(cached.year), cached.cutletName, cached.dayInCutlet, cached.monthName, cached.dayInMonth,
      );
    }
    cacheMisses += 1;
    const result = getCalculationState(calculationJdn).materialize(targetJdn);
    resultCache.set(key, freezePlainDateJSON(result.toJSON()));
    endDiagnosticOperation(token, "cache-miss");
    return result;
  } catch (error) {
    recordDiagnosticError("fast", error, token?.id, { phase: "convert" });
    endDiagnosticOperation(token, "error");
    throw error;
  }
}

export class PastafariCalendar {
  constructor(options = {}) {
    if (options === null || typeof options !== "object") {
      fail(TypeError, "PastafariCalendar options must be an object.", "ERR_OPTIONS");
    }
    if (options.todayProvider !== undefined && typeof options.todayProvider !== "function") {
      fail(TypeError, "todayProvider must be a function.", "ERR_TODAY_PROVIDER");
    }
    this._todayProvider = options.todayProvider ?? localToday;
  }

  _defaultCalculationJdn() {
    const value = this._todayProvider();
    if (!(value instanceof GregorianDate)) {
      fail(TypeError, "todayProvider must return a GregorianDate.", "ERR_TODAY_PROVIDER");
    }
    return gregorianToJdn(value);
  }

  convertJdn(targetJdn, options = {}) {
    requireBigInt(targetJdn, "targetJdn");
    if (options === null || typeof options !== "object") {
      fail(TypeError, "convertJdn options must be an object.", "ERR_OPTIONS");
    }
    const calculationJdn = options.calculationJdn === undefined
      ? this._defaultCalculationJdn()
      : requireBigInt(options.calculationJdn, "calculationJdn");
    return convertWithGlobalCache(targetJdn, calculationJdn);
  }

  convert(targetDate, options = {}) {
    if (!(targetDate instanceof GregorianDate)) {
      fail(TypeError, "Fast minimal interface currently accepts GregorianDate targets.", "ERR_TARGET_DATE");
    }
    if (options === null || typeof options !== "object") {
      fail(TypeError, "convert options must be an object.", "ERR_OPTIONS");
    }
    if (options.calculationDate !== undefined && options.calculationJdn !== undefined) {
      fail(TypeError, "Provide either calculationDate or calculationJdn, not both.", "ERR_CALCULATION_CONFLICT");
    }
    let calculationJdn;
    if (options.calculationJdn !== undefined) {
      calculationJdn = requireBigInt(options.calculationJdn, "calculationJdn");
    } else if (options.calculationDate !== undefined) {
      if (!(options.calculationDate instanceof GregorianDate)) {
        fail(TypeError, "calculationDate must be a GregorianDate.", "ERR_CALCULATION_DATE");
      }
      calculationJdn = gregorianToJdn(options.calculationDate);
    } else {
      calculationJdn = this._defaultCalculationJdn();
    }
    return convertWithGlobalCache(gregorianToJdn(targetDate), calculationJdn);
  }
}

export function getCutletView(targetJdn, options) {
  const token = beginDiagnosticOperation("fast", "get-cutlet-view");
  requireBigInt(targetJdn, "targetJdn");
  if (options === null || typeof options !== "object") {
    fail(TypeError, "getCutletView options must be an object.", "ERR_OPTIONS");
  }
  const calculationJdn = requireBigInt(options.calculationJdn, "calculationJdn");
  const state = getCalculationState(calculationJdn);
  const year = state.findYear(targetJdn);
  const structure = state.getStructure(year);
  const offset = Number(targetJdn - year.startJdn);
  const cutlet = findCutletByOffset(structure, offset);
  const startOffset = structure.cutletStartOffsets[cutlet];
  const endOffset = structure.cutletEndOffsets[cutlet];
  const startJdn = year.startJdn + BigInt(startOffset);
  const endJdn = year.startJdn + BigInt(endOffset);
  const days = new Array(endOffset - startOffset + 1);
  for (let i = startOffset; i <= endOffset; i += 1) {
    const jdn = year.startJdn + BigInt(i);
    const value = materializeFromStructure(year, structure, jdn).toJSON();
    days[i - startOffset] = Object.freeze({
      jdn,
      year: value.year,
      cutletName: value.cutletName,
      dayInCutlet: value.dayInCutlet,
      monthName: value.monthName,
      dayInMonth: value.dayInMonth,
    });
  }
  Object.freeze(days);
  const result = Object.freeze({
    selectedJdn: targetJdn,
    selectedIndex: Number(targetJdn - startJdn),
    startJdn,
    endJdn,
    previousCutletJdn: startJdn - 1n,
    nextCutletJdn: endJdn + 1n,
    year: year.number.toString(),
    cutletName: structure.cutletNames[cutlet],
    days,
  });
  incrementDiagnosticCounter("fast.cutlet-view.days", days.length);
  endDiagnosticOperation(token, "ok", { days: days.length });
  return result;
}

export function convertJdnRange(startJdn, count, options) {
  const token = beginDiagnosticOperation("fast", "convert-range", { count });
  requireBigInt(startJdn, "startJdn");
  if (!Number.isSafeInteger(count) || count < 0) {
    fail(RangeError, "count must be a non-negative safe integer.", "ERR_RANGE_COUNT");
  }
  if (options === null || typeof options !== "object") {
    fail(TypeError, "convertJdnRange options must be an object.", "ERR_OPTIONS");
  }
  const calculationJdn = requireBigInt(options.calculationJdn, "calculationJdn");
  const state = getCalculationState(calculationJdn);
  const result = new Array(count);
  let jdn = startJdn;
  for (let i = 0; i < count; i += 1, jdn += 1n) {
    result[i] = freezePlainDateJSON(state.materialize(jdn).toJSON());
  }
  incrementDiagnosticCounter("fast.range.days", count);
  endDiagnosticOperation(token, "ok", { count });
  return Object.freeze(result);
}

export function clearFastCache() {
  incrementDiagnosticCounter("fast.cache.clear");
  calculationStates.clear();
  resultCache.clear();
  gateDistanceCache.clear();
  dynamicGatePositions.clear();
  dynamicGatePositions.set(0n, FOUNDATION_JDN);
  gateTraversalCursorIndex = 0n;
  gateTraversalCursorPosition = FOUNDATION_JDN;
  cacheHits = 0;
  cacheMisses = 0;
}

export function getFastCacheStats() {
  return Object.freeze({ entries: resultCache.size, hits: cacheHits, misses: cacheMisses });
}

/*
 * Reverse lookup archaeology
 * ===========================
 *
 * This part is intentionally kept as the sequence of repairs by which the
 * reverse operation grew.  Do not rewrite it as one elegant constraint
 * solver: the detours are part of the implementation's documented history.
 *
 * R0  We first assumed that the calculation JDN was already known.  Under
 *     that assumption year + unique cutlet name + day-in-cutlet identifies
 *     one target day; month data is checked afterwards.
 * R1  Calls arrived without a calculation day.  A snapshot of "today" was
 *     taken once at the entrance and fed back into R0.
 * R2  A calculation day arrived in another calendar.  Instead of teaching
 *     the fast engine every calendar again, a side door was added: the
 *     authoritative browser module is imported lazily only for that detour.
 * R3  Then a Pastafari date was supplied as the calculation day.  That is not
 *     an absolute day at all, so the reverse lookup now calls itself to find
 *     the calculation day and sends each result back through R0.
 * R4  R3 immediately ate its own tail when c=t was requested.  The explicit
 *     SAME_AS_TARGET marker therefore jumps around the recursive path and
 *     performs a bounded diagonal search instead.
 * R5  The diagonal escape was needlessly expensive because most candidates
 *     fail before month weaving.  A deliberately duplicated cutlet-only
 *     probe was bolted in front of the full conversion.  The year==5000 test
 *     remains even though c=t makes it redundant; it predates that
 *     observation and is harmless.
 * R6  R3 can return several possible calculation days.  R0 still accepts one
 *     day, so a fan-out/fan-in adapter now repeatedly invokes the old path and
 *     flattens the results afterwards.
 * R7  Mutual Pastafari calculation references make a different sort of
 *     cycle.  Object-identity breadcrumbs reject those cycles.  R4 remains
 *     the one deliberately supported cycle.
 * R8  Every route, however tortuous, must finish by computing F(c,t) again
 *     and comparing all five fields.  No shortcut is authoritative.
 */

export const SAME_AS_TARGET = "same-as-target";

const OTHER_CALENDAR_SIDE_DOOR = new URL("./pastafari-calendar-core.js", import.meta.url);
let otherCalendarConverterPromise = null;

function normalizePastafariLookup(value, fieldName = "pastafariDate") {
  const source = typeof value?.toJSON === "function" ? value.toJSON() : value;
  if (source === null || typeof source !== "object") {
    fail(TypeError, `${fieldName} must be a Pastafari date object.`, "ERR_PASTAFARI_LOOKUP");
  }

  let year;
  try {
    year = normalizeYear(source.year);
  } catch {
    fail(TypeError, `${fieldName}.year must be an integer.`, "ERR_PASTAFARI_LOOKUP");
  }
  const dayInCutlet = Number(source.dayInCutlet);
  const dayInMonth = Number(source.dayInMonth);
  if (!Number.isSafeInteger(dayInCutlet) || dayInCutlet < 1) {
    fail(RangeError, `${fieldName}.dayInCutlet must be a positive safe integer.`, "ERR_PASTAFARI_LOOKUP");
  }
  if (!Number.isSafeInteger(dayInMonth) || dayInMonth < 1) {
    fail(RangeError, `${fieldName}.dayInMonth must be a positive safe integer.`, "ERR_PASTAFARI_LOOKUP");
  }
  if (typeof source.cutletName !== "string" || typeof source.monthName !== "string") {
    fail(TypeError, `${fieldName} must contain string cutletName and monthName fields.`, "ERR_PASTAFARI_LOOKUP");
  }

  return Object.freeze({
    year,
    cutletName: source.cutletName,
    dayInCutlet,
    monthName: source.monthName,
    dayInMonth,
  });
}

function samePastafariValue(actual, wanted) {
  const source = typeof actual?.toJSON === "function" ? actual.toJSON() : actual;
  return source !== null
    && typeof source === "object"
    && BigInt(source.year) === wanted.year
    && source.cutletName === wanted.cutletName
    && Number(source.dayInCutlet) === wanted.dayInCutlet
    && source.monthName === wanted.monthName
    && Number(source.dayInMonth) === wanted.dayInMonth;
}

function jdnToGregorianForReverse(jdn) {
  const a = jdn + 32044n;
  const b = floorDiv(4n * a + 3n, 146097n);
  const c = a - floorDiv(146097n * b, 4n);
  const d = floorDiv(4n * c + 3n, 1461n);
  const e = c - floorDiv(1461n * d, 4n);
  const m = floorDiv(5n * e + 2n, 153n);
  const day = e - floorDiv(153n * m + 2n, 5n) + 1n;
  const month = m + 3n - 12n * floorDiv(m, 10n);
  const year = 100n * b + d - 4800n + floorDiv(m, 10n);
  return new GregorianDate(year, Number(month), Number(day));
}

function inverseCandidate(targetJdn, calculationJdn) {
  return Object.freeze({
    targetJdn,
    targetDate: jdnToGregorianForReverse(targetJdn),
    calculationJdn,
    calculationDate: jdnToGregorianForReverse(calculationJdn),
  });
}

// R0: the original reverse path.  It deliberately knows nothing about
// recursion, "today", calendar conversion or c=t.
function reverseWithKnownCalculation(wanted, calculationJdn) {
  incrementDiagnosticCounter("reverse.known-calculation.calls");
  const state = getCalculationState(calculationJdn);
  let year = state.getYear5000();
  while (year.number < wanted.year) year = state.nextYear(year);
  while (year.number > wanted.year) year = state.previousYear(year);

  const structure = state.getStructure(year);
  const cutlet = structure.cutletNames.indexOf(wanted.cutletName);
  if (cutlet < 0) return [];

  const startOffset = structure.cutletStartOffsets[cutlet];
  const endOffset = structure.cutletEndOffsets[cutlet];
  const offset = startOffset + wanted.dayInCutlet - 1;
  if (offset < startOffset || offset > endOffset) return [];

  const targetJdn = year.startJdn + BigInt(offset);

  // R8: even R0 has to pass through the forward calculation.  In particular,
  // this rejects a tempting year/cutlet/day match whose month fields disagree.
  const forward = convertWithGlobalCache(targetJdn, calculationJdn);
  return samePastafariValue(forward, wanted)
    ? [inverseCandidate(targetJdn, calculationJdn)]
    : [];
}

function isPastafariLike(value) {
  if (value === null || typeof value !== "object") return false;
  if (value.calendar === "pastafari") return true;
  const source = value.date ?? value;
  return source !== null
    && typeof source === "object"
    && "year" in source
    && "cutletName" in source
    && "dayInCutlet" in source
    && "monthName" in source
    && "dayInMonth" in source;
}

function parseReverseIsoGregorian(value, fieldName) {
  const match = /^([+-]?\d+)-(\d{2})-(\d{2})$/.exec(value.trim());
  if (!match) {
    fail(RangeError, `${fieldName} must be an ISO Gregorian date (YYYY-MM-DD).`, "ERR_REVERSE_DATE");
  }
  const date = new GregorianDate(match[1], Number(match[2]), Number(match[3]));
  validateGregorian(date);
  return gregorianToJdn(date);
}

async function loadOtherCalendarConverter() {
  if (otherCalendarConverterPromise === null) {
    otherCalendarConverterPromise = import(OTHER_CALENDAR_SIDE_DOOR.href).then((moduleNamespace) => {
      if (typeof moduleNamespace.calendarDateToJdn !== "function") {
        fail(Error, "The authoritative calendar side door has no calendarDateToJdn().", "ERR_CALENDAR_SIDE_DOOR");
      }
      return moduleNamespace.calendarDateToJdn;
    });
  }
  return otherCalendarConverterPromise;
}

// R2 side door.  Pastafari values are intentionally refused here; accepting
// one would conceal the exact ambiguity for which R3 exists.
async function absoluteDayThroughSideDoors(value, fieldName) {
  if (typeof value === "bigint") return value;
  if (value instanceof GregorianDate) return gregorianToJdn(value);
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      fail(RangeError, `${fieldName} is an invalid Date.`, "ERR_REVERSE_DATE");
    }
    return gregorianToJdn(new GregorianDate(value.getFullYear(), value.getMonth() + 1, value.getDate()));
  }
  if (typeof value === "string") return parseReverseIsoGregorian(value, fieldName);
  if (value === null || typeof value !== "object") {
    fail(TypeError, `${fieldName} is not a supported absolute calendar date.`, "ERR_REVERSE_DATE");
  }
  if (isPastafariLike(value)) {
    fail(TypeError, `${fieldName} is Pastafari and must be resolved recursively.`, "ERR_REVERSE_PASTAFARI_AS_ABSOLUTE");
  }
  if (Object.hasOwn(value, "jdn")) {
    const jdn = value.jdn;
    if (typeof jdn === "bigint") return jdn;
    if (typeof jdn === "string" && /^[+-]?\d+$/.test(jdn)) return BigInt(jdn);
    fail(TypeError, `${fieldName}.jdn must be a bigint or decimal integer string.`, "ERR_REVERSE_DATE");
  }
  if (!Object.hasOwn(value, "calendar") && "year" in value && "month" in value && "day" in value) {
    const date = new GregorianDate(value.year, Number(value.month), Number(value.day));
    validateGregorian(date);
    return gregorianToJdn(date);
  }

  const converter = await loadOtherCalendarConverter();
  try {
    return BigInt(converter(value));
  } catch (error) {
    if (error && typeof error === "object" && !error.code) error.code = "ERR_REVERSE_DATE";
    throw error;
  }
}

// R5: this duplicates the cutlet half of buildYearStructure on purpose.  It
// was attached later as a sieve, and the subsequent full conversion remains
// responsible for the answer.
function diagonalCutletSieve(jdn) {
  const state = getCalculationState(jdn);
  const year = state.getYear5000();
  const s = state.getSauce(year.startJdn);
  const gapCount = year.gaps;
  const cutletCounts = [];
  for (let n = 6; n <= 17 && n <= gapCount; n += 1) cutletCounts.push(n);
  const cutletCountChoice = chooseUniform(s, 1, 20, BigInt(cutletCounts.length));
  const cutletCount = cutletCounts[Number(cutletCountChoice - 1n)];

  let mandatoryCut = null;
  if (jdn >= year.startJdn && jdn <= year.endJdn) {
    for (let k = year.p + 1n; k < year.q; k += 1n) {
      if (gatePosition(k) === jdn) {
        mandatoryCut = Number(k - year.p);
        break;
      }
    }
  }
  const partitionCount = mandatoryCut === null
    ? binomial(gapCount - 1, cutletCount - 1)
    : binomial(gapCount - 2, cutletCount - 2);
  const partitionChoice = chooseUniform(s, 1, 21, partitionCount);
  const cutletGaps = unrankComposition(gapCount, cutletCount, mandatoryCut, partitionChoice);
  const cutletNameCount = permutationsCount(CUTLET_NAMES.length, cutletCount);
  const cutletNameChoice = chooseUniform(s, 4, 22, cutletNameCount);
  const cutletNames = unrankPermutationNames(CUTLET_NAMES, cutletCount, cutletNameChoice);

  let gapOffset = 0;
  let startOffset = 0;
  const targetOffset = Number(jdn - year.startJdn);
  for (let i = 0; i < cutletCount; i += 1) {
    gapOffset += cutletGaps[i];
    const endJdn = gatePosition(year.p + BigInt(gapOffset));
    const endOffset = Number(endJdn - year.startJdn);
    if (targetOffset >= startOffset && targetOffset <= endOffset) {
      return Object.freeze({
        year: year.number,
        cutletName: cutletNames[i],
        dayInCutlet: targetOffset - startOffset + 1,
      });
    }
    startOffset = endOffset + 1;
  }
  fail(Error, "The diagonal cutlet sieve lost its target day.", "ERR_REVERSE_SIEVE");
}

async function normalizeDiagonalRange(range, context) {
  const source = range ?? context.rootSearchRange;
  if (source === undefined || source === null) {
    fail(
      RangeError,
      "same-as-target requires searchRange; an unbounded reverse search is not allowed.",
      "ERR_SELF_RANGE_REQUIRED",
    );
  }
  let first;
  let last;
  if (Array.isArray(source) && source.length === 2) {
    [first, last] = source;
  } else if (typeof source === "object" && source !== null && "start" in source && "end" in source) {
    first = source.start;
    last = source.end;
  } else {
    fail(TypeError, "searchRange must be [start,end] or {start,end}.", "ERR_SELF_RANGE");
  }
  if (isPastafariLike(first) || isPastafariLike(last)) {
    fail(TypeError, "Pastafari search-range boundaries are not supported.", "ERR_SELF_RANGE_PASTAFARI");
  }
  const startJdn = await absoluteDayThroughSideDoors(first, "searchRange.start");
  const endJdn = await absoluteDayThroughSideDoors(last, "searchRange.end");
  if (endJdn < startJdn) {
    fail(RangeError, "searchRange.end precedes searchRange.start.", "ERR_SELF_RANGE");
  }
  return Object.freeze({ startJdn, endJdn });
}

function reverseAbortError() {
  const error = new Error("Pastafari reverse search was aborted.");
  error.name = "AbortError";
  error.code = "ERR_REVERSE_ABORTED";
  return error;
}

async function letTheEventLoopBreathe() {
  if (typeof setTimeout === "function") {
    await new Promise((resolve) => setTimeout(resolve, 0));
  } else {
    await Promise.resolve();
  }
}

// R4 diagonal escape, with the R5 sieve grafted onto it.
async function diagonalEscape(wanted, range, context) {
  incrementDiagnosticCounter("reverse.path.same-as-target");
  const { startJdn, endJdn } = await normalizeDiagonalRange(range, context);
  if (wanted.year !== 5000n) return Object.freeze([]);

  const results = [];
  const total = endJdn - startJdn + 1n;
  let scanned = 0n;
  for (let jdn = startJdn; jdn <= endJdn; jdn += 1n) {
    if (context.signal?.aborted) throw reverseAbortError();
    const cheap = diagonalCutletSieve(jdn);
    scanned += 1n;
    incrementDiagnosticCounter("reverse.diagonal.scanned");
    if (
      cheap.year === wanted.year
      && cheap.cutletName === wanted.cutletName
      && cheap.dayInCutlet === wanted.dayInCutlet
    ) {
      // R8 is intentionally a complete conversion, even though R5 already
      // repeated a substantial part of the work.
      const forward = convertWithGlobalCache(jdn, jdn);
      if (samePastafariValue(forward, wanted)) {
        results.push(inverseCandidate(jdn, jdn));
        incrementDiagnosticCounter("reverse.matches");
      }
    }

    if (context.onProgress && (scanned % BigInt(context.yieldEvery) === 0n || scanned === total)) {
      context.onProgress(Object.freeze({ scanned, total, matches: results.length }));
    }
    if (scanned % BigInt(context.yieldEvery) === 0n && scanned !== total) {
      await letTheEventLoopBreathe();
    }
  }
  return Object.freeze(results);
}

function unpackPastafariCalculation(spec) {
  if (spec && typeof spec === "object" && spec.calendar === "pastafari" && "date" in spec) {
    return {
      date: normalizePastafariLookup(spec.date, "calculationDate.date"),
      calculationDate: spec.calculationDate,
      searchRange: spec.searchRange,
    };
  }
  return {
    date: normalizePastafariLookup(spec, "calculationDate"),
    calculationDate: spec?.calculationDate,
    searchRange: spec?.searchRange,
  };
}

function deduplicateReverseCandidates(candidates) {
  const seen = new Set();
  const result = [];
  for (const candidate of candidates) {
    const key = `${candidate.targetJdn}:${candidate.calculationJdn}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(candidate);
  }
  return Object.freeze(result);
}

// R3/R6/R7 dispatcher.  Its shape intentionally reflects the order in which
// exceptions were discovered instead of reducing everything to one generic
// graph solver.
async function reverseThroughDetours(wanted, calculationSpec, localRange, context) {
  if (calculationSpec === SAME_AS_TARGET) {
    return diagonalEscape(wanted, localRange, context);
  }

  // R1: the old known-c path gets today's frozen snapshot when nobody said
  // what c was.  The snapshot belongs to the root call, not to this recursion.
  if (calculationSpec === undefined || calculationSpec === null || calculationSpec === "") {
    return reverseWithKnownCalculation(wanted, context.todayJdn);
  }

  if (isPastafariLike(calculationSpec)) {
    incrementDiagnosticCounter("reverse.path.nested-pastafari");
    // R7 breadcrumbs use identity, not equality of the five date fields: two
    // equal-looking dates in a finite nested chain are not themselves a cycle.
    if (typeof calculationSpec === "object" && calculationSpec !== null) {
      if (context.breadcrumbs.has(calculationSpec)) {
        fail(
          RangeError,
          "Mutually recursive Pastafari calculation dates are not supported; use same-as-target for c=t.",
          "ERR_UNSUPPORTED_CALCULATION_CYCLE",
        );
      }
      context.breadcrumbs.add(calculationSpec);
    }

    try {
      const unpacked = unpackPastafariCalculation(calculationSpec);
      const inner = await reverseThroughDetours(
        unpacked.date,
        unpacked.calculationDate,
        unpacked.searchRange,
        context,
      );

      // R6: the original R0 routine still receives only one c at a time.
      const calculationDaysSeen = new Set();
      const collected = [];
      for (const foundCalculationDay of inner) {
        const c = foundCalculationDay.targetJdn;
        const key = c.toString();
        if (calculationDaysSeen.has(key)) continue;
        calculationDaysSeen.add(key);
        collected.push(...reverseWithKnownCalculation(wanted, c));
      }
      return deduplicateReverseCandidates(collected);
    } finally {
      if (typeof calculationSpec === "object" && calculationSpec !== null) {
        context.breadcrumbs.delete(calculationSpec);
      }
    }
  }

  // R2, reached only after the Pastafari detour has declined the input.
  incrementDiagnosticCounter("reverse.path.absolute-side-door");
  const calculationJdn = await absoluteDayThroughSideDoors(calculationSpec, "calculationDate");
  return reverseWithKnownCalculation(wanted, calculationJdn);
}

/**
 * Find every absolute target compatible with a Pastafari date under the
 * supplied calculation-day rule.
 *
 * calculationDate:
 *   omitted                 -> one snapshot of today's local Gregorian day
 *   absolute calendar date  -> that day (other calendars are converted lazily)
 *   Pastafari date           -> recursively reverse it first
 *   SAME_AS_TARGET           -> c=t, requiring a bounded searchRange
 *
 * A nested Pastafari calculation descriptor may be written as:
 *   { calendar: "pastafari", date, calculationDate, searchRange }
 */
export async function findPastafariDate(pastafariDate, options = {}) {
  const token = beginDiagnosticOperation("reverse", "find");
  if (options === null || typeof options !== "object") {
    fail(TypeError, "findPastafariDate options must be an object.", "ERR_OPTIONS");
  }
  if (options.calculationDate !== undefined && options.calculationJdn !== undefined) {
    fail(TypeError, "Provide calculationDate or calculationJdn, not both.", "ERR_CALCULATION_CONFLICT");
  }
  if (options.todayProvider !== undefined && typeof options.todayProvider !== "function") {
    fail(TypeError, "todayProvider must be a function.", "ERR_TODAY_PROVIDER");
  }
  if (options.onProgress !== undefined && typeof options.onProgress !== "function") {
    fail(TypeError, "onProgress must be a function.", "ERR_REVERSE_PROGRESS");
  }
  const yieldEvery = options.yieldEvery === undefined ? 256 : Number(options.yieldEvery);
  if (!Number.isSafeInteger(yieldEvery) || yieldEvery < 1) {
    fail(RangeError, "yieldEvery must be a positive safe integer.", "ERR_REVERSE_YIELD");
  }

  const wanted = normalizePastafariLookup(pastafariDate);
  const snapshot = options.todayProvider === undefined ? localToday() : options.todayProvider();
  if (isPastafariLike(snapshot)) {
    fail(TypeError, "todayProvider must return an absolute calendar day, not a Pastafari date.", "ERR_TODAY_PROVIDER");
  }
  const todayJdn = await absoluteDayThroughSideDoors(snapshot, "todayProvider result");
  const context = {
    todayJdn,
    rootSearchRange: options.searchRange,
    breadcrumbs: new Set(),
    signal: options.signal,
    onProgress: options.onProgress,
    yieldEvery,
  };
  const calculationSpec = options.calculationJdn === undefined
    ? options.calculationDate
    : { jdn: options.calculationJdn };
  try {
    const result = deduplicateReverseCandidates(
      await reverseThroughDetours(wanted, calculationSpec, options.searchRange, context),
    );
    incrementDiagnosticCounter("reverse.results", result.length);
    endDiagnosticOperation(token, "ok", { matches: result.length });
    return result;
  } catch (error) {
    const outcome = error?.name === "AbortError" ? "cancelled" : "error";
    recordDiagnosticError("reverse", error, token?.id);
    endDiagnosticOperation(token, outcome);
    throw error;
  }
}
