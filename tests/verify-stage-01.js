'use strict';

const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const production = require('../src');
const o = require('./normative-reference');

let groupsPassed = 0;
let assertions = 0;

function eq(actual, expected, message) {
  assertions += 1;
  assert.equal(actual, expected, message);
}

function deepEq(actual, expected, message) {
  assertions += 1;
  assert.deepEqual(actual, expected, message);
}

function ok(value, message) {
  assertions += 1;
  assert.ok(value, message);
}

function throws(fn, expected, message) {
  assertions += 1;
  assert.throws(fn, expected, message);
}

function group(name, fn) {
  fn();
  groupsPassed += 1;
  console.log('PASS ' + name);
}

function listFiles(root) {
  const out = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const full = path.join(root, entry.name);
    if (entry.isDirectory()) out.push(...listFiles(full));
    else out.push(full);
  }
  return out;
}

function lexCompare(a, b) {
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; i += 1) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return a.length < b.length ? -1 : a.length > b.length ? 1 : 0;
}

function allPartialPermutations(n, k) {
  const out = [];
  const used = new Array(n + 1).fill(false);
  const row = [];
  function walk() {
    if (row.length === k) {
      out.push(row.slice());
      return;
    }
    for (let value = 1; value <= n; value += 1) {
      if (used[value]) continue;
      used[value] = true;
      row.push(value);
      walk();
      row.pop();
      used[value] = false;
    }
  }
  walk();
  return out;
}

function bruteBoundedCompositions(total, slots, lo, hi) {
  const out = [];
  const row = [];
  function walk(rem) {
    if (row.length === slots) {
      if (rem === 0) out.push(row.slice());
      return;
    }
    for (let x = lo; x <= hi; x += 1) {
      row.push(x);
      walk(rem - x);
      row.pop();
    }
  }
  walk(total);
  return out;
}

function brutePositiveCompositions(total, slots) {
  const out = [];
  const row = [];
  function walk(rem) {
    if (row.length === slots) {
      if (rem === 0) out.push(row.slice());
      return;
    }
    const left = slots - row.length - 1;
    for (let x = 1; x <= rem - left; x += 1) {
      row.push(x);
      walk(rem - x);
      row.pop();
    }
  }
  walk(total);
  return out;
}

function prefixContains(row, wanted) {
  let sum = 0;
  for (const x of row) {
    sum += x;
    if (sum === wanted) return true;
    if (sum > wanted) return false;
  }
  return false;
}

function bruteWeavings(lengths) {
  const total = lengths.reduce((a, b) => a + b, 0);
  const remaining = lengths.slice();
  const row = [];
  const out = [];

  function validFinal(candidate) {
    let previousFirst = -1;
    let previousLast = -1;
    for (let month = 1; month <= lengths.length; month += 1) {
      const first = candidate.indexOf(month);
      const last = candidate.lastIndexOf(month);
      if (first <= previousFirst || last <= previousLast) return false;
      previousFirst = first;
      previousLast = last;
    }
    return true;
  }

  function walk() {
    if (row.length === total) {
      if (validFinal(row)) out.push(row.slice());
      return;
    }
    for (let month = 1; month <= lengths.length; month += 1) {
      if (remaining[month - 1] === 0) continue;
      remaining[month - 1] -= 1;
      row.push(month);
      walk();
      row.pop();
      remaining[month - 1] += 1;
    }
  }

  walk();
  out.sort(lexCompare);
  return out;
}

function hiddenValidationCopy(counts) {
  const coeff = [
    [3n, 4n, 6n, 8n],
    [5n, 7n, 10n, 12n],
    [7n, 10n, 14n, 16n],
    [9n, 13n, 18n, 20n],
    [11n, 16n, 22n, 24n],
    [13n, 19n, 26n, 28n],
    [15n, 22n, 30n, 32n]
  ];
  const kinds = [0, 1, 2, 3, 4, 0, 1];
  const out = [];
  for (let k = 0; k < 7; k += 1) {
    const [a, b, c, d] = coeff[k];
    const stone = o.STONES[k];
    let x = counts.action + a * counts.target + b * counts.distance + c * counts.connection + d * counts.direction;
    for (const value of stone) x += value;
    x = o.SAVE(x);
    for (let grind = 0; grind < 7; grind += 1) {
      const old = x;
      x = o.SAVE(old * old + 3n * old + stone[kinds[grind]] + BigInt(grind + 1));
    }
    out.push(x);
  }
  return out;
}

function visibleValidationCopy(counts, hidden) {
  const grinds = [
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
    [37n, 41n, 43n, 47n, 0]
  ];
  const timeline = new Map();
  for (let k = 1; k <= 7; k += 1) timeline.set(1 - k, hidden[k - 1]);
  const out = [];
  for (let i = 1; i <= 46; i += 1) {
    const p1 = timeline.get(i - 1);
    const p3 = timeline.get(i - 3);
    const p7 = timeline.get(i - 7);
    const stone = o.STONES[i - 1];
    let x = o.SAVE(
      stone[0] * counts.action + stone[1] * counts.target + stone[2] * counts.distance
      + stone[3] * counts.connection + stone[4] * counts.direction
      + p1 + 3n * p3 + 5n * p7 + BigInt(i)
    );
    for (const [a, b, c, d, kind] of grinds) {
      const old = x;
      x = o.SAVE(old * old + a * old + b * p1 + c * p3 + d * p7 + stone[kind]);
    }
    timeline.set(i, x);
    out.push(x);
  }
  return out;
}

function bowlsValidationCopy(counts, visible) {
  const primes = [17n, 19n, 23n, 29n, 31n, 37n];
  const stoneByPosition = [0, 1, 2, 3, 4, 0];
  let bowls = [];
  for (let id = 1; id <= 6; id += 1) {
    const s = counts.action + counts.target * BigInt(id) + counts.distance + counts.connection + counts.direction + primes[id - 1] ** 2n;
    bowls.push(o.SAVE(s * s + BigInt(id)));
  }
  let latch = null;
  for (let i = 1; i <= 46; i += 1) {
    const drop = visible[i - 1];
    const order = o.bowlOrderFromDrop(drop);
    const old = bowls.slice();
    const pour = [0n, 0n, 0n, 0n, 0n, 0n];
    pour[0] = o.SAVE(drop * drop + o.STONES[i - 1][0] * old[order[0] - 1] + 3n * BigInt(i));
    pour[1] = o.SAVE(drop * drop + o.STONES[i - 1][1] * old[order[1] - 1] + 5n * BigInt(i));
    pour[2] = o.SAVE(drop * drop + o.STONES[i - 1][2] * old[order[2] - 1] + 7n * BigInt(i));
    const next = new Array(6);
    for (let pos = 1; pos <= 6; pos += 1) {
      const id = order[pos - 1];
      const prev = order[(pos + 4) % 6];
      const following = order[pos % 6];
      const s = old[id - 1] + 2n * old[prev - 1] + 3n * old[following - 1] + pour[pos - 1] + drop + o.STONES[i - 1][stoneByPosition[pos - 1]];
      next[id - 1] = o.SAVE(s * s + 5n * old[prev - 1] * old[following - 1] + BigInt(i * pos));
    }
    bowls = next;
    if (i === 46) latch = order.slice();
  }
  const latchBeforePost = latch.slice();
  for (let stir = 1; stir <= 12; stir += 1) {
    const old = bowls.slice();
    const saved = o.SAVE(old.reduce((sum, value) => sum + value, 0n) + 149n * BigInt(stir));
    const order = o.bowlOrderFromNumber(o.regularMod(saved - 1n, 720n) + 1n);
    const next = new Array(6);
    for (let pos = 1; pos <= 6; pos += 1) {
      const id = order[pos - 1];
      const prev = order[(pos + 4) % 6];
      const following = order[pos % 6];
      const s = old[id - 1] + 3n * old[prev - 1] + 5n * old[following - 1] + saved + BigInt(stir) + BigInt(pos * pos);
      next[id - 1] = o.SAVE(s * s + 7n * old[prev - 1] * old[following - 1]);
    }
    bowls = next;
  }
  return { bowls, orderAtDrop46: latchBeforePost };
}

function independentSmallPick(stream, n) {
  const limit = o.floorDiv(o.M, n) * n;
  for (let k = 0n; k < 5000n; k += 1n) {
    const x = o.answerAt(stream, k);
    if (x <= limit) return o.regularMod(x - 1n, n) + 1n;
  }
  throw new Error('Li prova independent ne atinge un valore acceptat in su limite de securitá.');
}

group('syntax de omni JavaScript es valid con li runtime local', () => {
  const root = path.join(__dirname, '..');
  const files = listFiles(root).filter((file) => file.endsWith('.js'));
  ok(files.length >= 6);
  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    new vm.Script(source, { filename: file });
    assertions += 1;
  }
});

group('li linea ne declara null dependentie extern e usa solmen Node por scripts', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8'));
  ok(!pkg.dependencies);
  ok(!pkg.devDependencies);
  for (const command of Object.values(pkg.scripts)) ok(/^node\s/.test(command), command);
});

group('production resta isolat del reference test-only', () => {
  const srcRoot = path.join(__dirname, '..', 'src');
  for (const file of listFiles(srcRoot).filter((item) => item.endsWith('.js'))) {
    const source = fs.readFileSync(file, 'utf8');
    ok(!source.includes('normative-reference'));
    ok(!source.includes('../tests'));
    ok(!source.includes('/tests/'));
  }
});

group('null textu hebreic o code posterior a Discovery 01 contamina production', () => {
  const root = path.join(__dirname, '..');
  const textFiles = listFiles(root).filter((file) => /\.(?:js|json|md)$/.test(file));
  for (const file of textFiles) {
    const source = fs.readFileSync(file, 'utf8');
    ok(!/[\u0590-\u05FF]/u.test(source), file);
  }
  const futureTokens = [
    'savePatch', 'oldDayTag', 'oldDistance', 'mutateStonesWrong',
    'hiddenByNearness', 'legacyPrior', 'GRIND_TABLE_WITH_SENTINEL', 'oldPermutationUnrank0',
    'bowlAlias', 'vaultOld', 'orderAt46Latch', 'oldNextBowlFixedName', 'biasedLegacyPick',
    'wideDetour', 'oldGateQuestionDay', 'LEGACY_YEAR_MAX', 'REAL_YEAR_MAX_PATCH',
    'oldJumpGuess', 'LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER', 'oldStructureSauce',
    'legacyPositiveCompositions', 'legacyNameRowWithRepeats', 'VirtualLegacyList',
    'legacyChooseEachDaySeparately', 'oldContiguousMonthDayGuess'
  ];
  const productionText = listFiles(path.join(root, 'src')).map((file) => fs.readFileSync(file, 'utf8')).join('\n');
  for (const token of futureTokens) ok(!productionText.includes(token), token);
});

group('regularMod e floorDiv satisfá lor identities exact in un gril exhaustiv', () => {
  for (let d = 1n; d <= 31n; d += 1n) {
    for (let x = -200n; x <= 200n; x += 1n) {
      const r = o.regularMod(x, d);
      const q = o.floorDiv(x, d);
      ok(0n <= r && r < d);
      eq(q * d + r, x);
      ok(q * d <= x && x < (q + 1n) * d);
    }
  }
});

group('SAVE es exact circum multipplicás positiv e negativ de M', () => {
  for (let k = -20n; k <= 20n; k += 1n) {
    for (let delta = -3n; delta <= 3n; delta += 1n) {
      const x = k * o.M + delta;
      const y = o.SAVE(x);
      ok(1n <= y && y <= o.M);
      eq(o.regularMod(y - x, o.M), 0n);
      if (delta === 0n) eq(y, o.M);
    }
  }
});

group('dayCount e workCounts satisfá exhaustivmen li reguli circum Foundation', () => {
  for (let delta = -1000n; delta <= 1000n; delta += 1n) {
    const day = o.FOUNDATION_DAY + delta;
    const value = o.dayCount(day);
    ok(value >= 1n);
    if (delta < 0n) {
      eq(value, -2n * delta);
      eq(value % 2n, 0n);
    } else if (delta === 0n) eq(value, 1n);
    else {
      eq(value, 2n * delta + 1n);
      eq(value % 2n, 1n);
    }
  }
  for (let dc = -20n; dc <= 20n; dc += 1n) {
    for (let dt = -20n; dt <= 20n; dt += 1n) {
      const c = o.FOUNDATION_DAY + dc;
      const t = o.FOUNDATION_DAY + dt;
      const counts = o.workCounts(c, t);
      eq(counts.action, o.dayCount(c));
      eq(counts.target, o.dayCount(t));
      eq(counts.distance, (t >= c ? t - c : c - t) + 1n);
      eq(counts.connection, counts.action + counts.target);
      eq(counts.direction, t < c ? 1n : t === c ? 2n : 3n);
    }
  }
});

group('omni 46 rows de stones veni del sam snapshot precedent', () => {
  eq(o.STONES.length, 46);
  deepEq(o.STONES[0], [17n, 29n, 43n, 71n, 101n]);
  for (let i = 2; i <= 46; i += 1) {
    const old = o.STONES[i - 2];
    const expected = [
      o.SAVE(old[0] * old[0] + 3n * old[1] + BigInt(i)),
      o.SAVE(old[1] * old[1] + 5n * old[2] + old[0]),
      o.SAVE(old[2] * old[2] + 7n * old[3] + old[1]),
      o.SAVE(old[3] * old[3] + 11n * old[4] + old[2]),
      o.SAVE(old[4] * old[4] + 13n * old[0] + old[3])
    ];
    deepEq(o.STONES[i - 1], expected);
    for (const value of o.STONES[i - 1]) ok(1n <= value && value <= o.M);
  }
});

group('hidden drops e visible drops concorda con un copy de validation independent', () => {
  const pairs = [
    [o.FOUNDATION_DAY, o.FOUNDATION_DAY],
    [o.FOUNDATION_DAY - 7n, o.FOUNDATION_DAY + 11n],
    [o.FOUNDATION_DAY + 17n, o.FOUNDATION_DAY - 13n],
    [0n, 0n],
    [123456789n, -987654321n]
  ];
  for (const [c, t] of pairs) {
    const counts = o.workCounts(c, t);
    const hidden = o.buildHiddenDrops(counts);
    const hiddenCopy = hiddenValidationCopy(counts);
    deepEq(hidden, hiddenCopy);
    eq(hidden.length, 7);
    for (const value of hidden) ok(1n <= value && value <= o.M);
    const visible = o.buildVisibleDrops(counts, o.STONES, hidden);
    const visibleCopy = visibleValidationCopy(counts, hiddenCopy);
    deepEq(visible, visibleCopy);
    eq(visible.length, 46);
    for (const value of visible) ok(1n <= value && value <= o.M);
  }
});

group('omni 720 permutationes es unic, complete e strictmen lexicografic', () => {
  const seen = new Set();
  let previous = null;
  for (let rank = 1n; rank <= 720n; rank += 1n) {
    const row = o.bowlOrderFromNumber(rank);
    deepEq(row.slice().sort((a, b) => a - b), [1, 2, 3, 4, 5, 6]);
    const key = row.join(',');
    ok(!seen.has(key));
    seen.add(key);
    if (previous !== null) ok(lexCompare(previous, row) < 0);
    previous = row;
  }
  eq(seen.size, 720);
  deepEq(o.bowlOrderFromDrop(1n), o.bowlOrderFromNumber(1n));
  deepEq(o.bowlOrderFromDrop(720n), o.bowlOrderFromNumber(720n));
  deepEq(o.bowlOrderFromDrop(721n), o.bowlOrderFromNumber(1n));
  deepEq(o.bowlOrderFromDrop(1440n), o.bowlOrderFromNumber(720n));
});

group('li sauce complet concorda con un copy validation por pluri pares e conserva li latch 46', () => {
  const pairs = [
    [o.FOUNDATION_DAY, o.FOUNDATION_DAY],
    [o.FOUNDATION_DAY - 1n, o.FOUNDATION_DAY],
    [o.FOUNDATION_DAY, o.FOUNDATION_DAY + 1n],
    [o.FOUNDATION_DAY + 9n, o.FOUNDATION_DAY - 4n],
    [123n, -456n]
  ];
  for (const [c, t] of pairs) {
    const counts = o.workCounts(c, t);
    const hidden = hiddenValidationCopy(counts);
    const visible = visibleValidationCopy(counts, hidden);
    const copy = bowlsValidationCopy(counts, visible);
    const actual = o.sauce(c, t);
    deepEq(actual.bowls, copy.bowls);
    deepEq(actual.orderAtDrop46, copy.orderAtDrop46);
    deepEq(o.sauce(c, t), actual);
    eq(actual.orderAtDrop46.length, 6);
    for (const value of actual.bowls) ok(1n <= value && value <= o.M);
  }
});

group('question de bole usa sempre li successor del latch 46, includet li ultim bole', () => {
  const s = o.sauce(o.FOUNDATION_DAY, o.FOUNDATION_DAY);
  for (let p = 0; p < 6; p += 1) {
    const id = s.orderAtDrop46[p];
    const wanted = s.orderAtDrop46[(p + 1) % 6];
    eq(o.nextBowlInDrop46Order(s, id), wanted);
    const stream = o.askBowl(s, id, 33n);
    ok(stream.directionStep === 1n || stream.directionStep === -1n);
    for (let k = 0n; k < 20n; k += 1n) {
      const x = o.answerAt(stream, k);
      ok(1n <= x && x <= o.M);
    }
  }
});

group('selection curt concorda con rejection independent por limites e divisores divers', () => {
  const sizes = [1n, 2n, 3n, 5n, 7n, 10n, 17n, 720n, 922n, o.M];
  const streams = [
    { first: 1n, directionStep: 1n },
    { first: o.M, directionStep: -1n },
    { first: o.M, directionStep: 1n },
    { first: o.M - 1000n, directionStep: 1n }
  ];
  for (const n of sizes) {
    for (const stream of streams) {
      const actual = o.chooseRankShort(stream, n);
      const expected = independentSmallPick(stream, n);
      eq(actual, expected);
      ok(1n <= actual && actual <= n);
    }
  }
});

group('selection larg tracta M+1, M^2 e un rejection de un sol pass exact', () => {
  const m2 = o.M * o.M;
  const a = o.chooseRankWide({ first: 1n, directionStep: 1n }, o.M + 1n);
  ok(1n <= a && a <= o.M + 1n);
  const streamExact = { first: o.M, directionStep: -1n };
  const expectedWide = 1n + (o.M - 1n) + (o.M - 2n) * o.M;
  eq(o.chooseRankWide(streamExact, m2), expectedWide);
  const rejectionN = expectedWide - 1n;
  eq(o.floorDiv(m2, rejectionN), 1n);
  eq(o.chooseRankWide(streamExact, rejectionN), rejectionN);
  const c = o.chooseRankWide({ first: 1n, directionStep: 1n }, m2 + 1n);
  ok(1n <= c && c <= m2 + 1n);
});

group('unranking de nomes distinct concorda exhaustivmen con permutationes partial', () => {
  for (let n = 1; n <= 5; n += 1) {
    for (let k = 0; k <= n; k += 1) {
      const brute = allPartialPermutations(n, k);
      eq(o.fallingFactorial(n, k), BigInt(brute.length));
      for (let i = 0; i < brute.length; i += 1) deepEq(o.unrankDistinctIndices(n, k, BigInt(i + 1)), brute[i]);
    }
  }
});

group('DP de compositiones limitat concorda exhaustivmen con enumeration micri', () => {
  for (let slots = 1; slots <= 4; slots += 1) {
    for (let lo = 1; lo <= 3; lo += 1) {
      for (let hi = lo; hi <= 5; hi += 1) {
        for (let total = slots * lo; total <= slots * hi; total += 1) {
          const brute = bruteBoundedCompositions(total, slots, lo, hi);
          const family = o.makeBoundedCompositionCounter(total, slots, lo, hi);
          eq(family.countAll(), BigInt(brute.length));
          for (let i = 0; i < brute.length; i += 1) deepEq(family.unrank1(BigInt(i + 1)), brute[i]);
        }
      }
    }
  }
});

group('DP de partition de cutlettes concorda con li familie legacy filtrat in órdine lexicografic', () => {
  for (let total = 2; total <= 10; total += 1) {
    for (let slots = 1; slots <= Math.min(4, total); slots += 1) {
      const all = brutePositiveCompositions(total, slots);
      const requiredValues = [null];
      for (let required = 1; required < total; required += 1) requiredValues.push(required);
      for (const required of requiredValues) {
        const brute = required === null ? all : all.filter((row) => prefixContains(row, required));
        const family = o.makeCutletPartitionFamily(total, slots, required);
        eq(family.count(), BigInt(brute.length));
        for (let i = 0; i < brute.length; i += 1) deepEq(family.unrank1(BigInt(i + 1)), brute[i]);
      }
    }
  }
});

group('DP de intertexe de mensus concorda con enumeration complet por spaces micri', () => {
  const cases = [
    [1], [2], [3], [1, 1], [2, 1], [1, 2], [2, 2], [3, 1], [1, 3],
    [2, 1, 1], [1, 2, 1], [2, 2, 1], [2, 1, 2], [2, 2, 2], [3, 2, 1]
  ];
  for (const lengths of cases) {
    const brute = bruteWeavings(lengths);
    const family = o.makeMonthWeavingFamily(lengths);
    eq(family.count(), BigInt(brute.length), lengths.join(','));
    for (let i = 0; i < brute.length; i += 1) deepEq(family.unrank1(BigInt(i + 1)), brute[i]);
  }
});

group('portes cresce strictmen, have gaps 42..963 e li du directiones es questionat independentmen', () => {
  const engine = o.createGateEngine();
  for (let index = -12n; index <= 12n; index += 1n) engine.ensureGateIndex(index);
  for (let index = -12n; index < 12n; index += 1n) {
    const gap = engine.ensureGateIndex(index + 1n) - engine.ensureGateIndex(index);
    ok(o.GATE_GAP_MIN <= gap && gap <= o.GATE_GAP_MAX);
  }
  for (let n = 1n; n <= 5n; n += 1n) {
    const positiveExpected = 41n + o.chooseRank(o.askBowl(o.sauce(o.FOUNDATION_DAY, o.FOUNDATION_DAY + n), 1, 1n), 922n);
    const negativeExpected = 41n + o.chooseRank(o.askBowl(o.sauce(o.FOUNDATION_DAY, o.FOUNDATION_DAY - n), 1, 1n), 922n);
    eq(engine.ensureGateIndex(n) - engine.ensureGateIndex(n - 1n), positiveExpected);
    eq(engine.ensureGateIndex(-(n - 1n)) - engine.ensureGateIndex(-n), negativeExpected);
  }
  for (let index = -10n; index <= 10n; index += 1n) {
    const day = engine.ensureGateIndex(index);
    eq(engine.exactGateIndex(day), index);
    eq(engine.gateIndexAtOrBefore(day), index);
    eq(engine.gateIndexAtOrAfter(day), index);
    if (index < 10n) {
      const next = engine.ensureGateIndex(index + 1n);
      const middle = day + (next - day) / 2n;
      if (middle > day && middle < next) {
        eq(engine.gateIndexAtOrBefore(middle), index);
        eq(engine.gateIndexAtOrAfter(middle), index + 1n);
      }
    }
  }
});

group('limites de annu 252 e 5778 es acceptat, 5779 e gap-count 5 es rejectet', () => {
  function engineForLength(length) {
    return { ensureGateIndex(index) { return index === 0n ? 0n : index === 6n ? length : index * 42n; } };
  }
  ok(o.validYearPair(engineForLength(252n), 0n, 6n));
  ok(o.validYearPair(engineForLength(5778n), 0n, 6n));
  ok(!o.validYearPair(engineForLength(5779n), 0n, 6n));
  const engine = engineForLength(5778n);
  ok(!o.validYearPair(engine, 0n, 5n));
});

group('annu 5000 e adjacent annus respecta continuitá e proprietá del porte de apertura', () => {
  const engine = o.createGateEngine();
  const y = o.year5000(o.FOUNDATION_DAY, engine);
  const previous = o.previousYear(o.FOUNDATION_DAY, y, engine);
  const next = o.nextYear(o.FOUNDATION_DAY, y, engine);
  eq(y.number, 5000n);
  eq(previous.number, 4999n);
  eq(next.number, 5001n);
  eq(previous.closeGateIndex, y.openGateIndex);
  eq(next.openGateIndex, y.closeGateIndex);
  ok(o.validYearPair(engine, y.openGateIndex, y.closeGateIndex));
  ok(o.validYearPair(engine, previous.openGateIndex, previous.closeGateIndex));
  ok(o.validYearPair(engine, next.openGateIndex, next.closeGateIndex));
  eq(o.findTargetYear(o.FOUNDATION_DAY, y.openGateDay, engine).number, 4999n);
  eq(o.findTargetYear(o.FOUNDATION_DAY, y.openGateDay + 1n, engine).number, 5000n);
  eq(o.findTargetYear(o.FOUNDATION_DAY, y.closeGateDay, engine).number, 5000n);
  eq(o.findTargetYear(o.FOUNDATION_DAY, y.closeGateDay + 1n, engine).number, 5001n);
});

group('helpers de structura conserva limites, sumas e nomes distinct sin intertexe gigant', () => {
  const engine = o.createGateEngine();
  const y = o.year5000(o.FOUNDATION_DAY, engine);
  const r = o.sauce(o.FOUNDATION_DAY, y.openGateDay + 1n);
  const cutletCount = o.chooseCutletCount(r, y);
  ok(6 <= cutletCount && cutletCount <= 17);
  ok(cutletCount <= Number(y.closeGateIndex - y.openGateIndex));
  const partition = o.chooseCutletPartition(o.FOUNDATION_DAY, r, y, cutletCount, engine);
  eq(partition.reduce((a, b) => a + b, 0), Number(y.closeGateIndex - y.openGateIndex));
  const cutletNames = o.chooseCutletNames(r, cutletCount);
  eq(new Set(cutletNames).size, cutletCount);
  const monthCount = o.chooseMonthCount(r, y);
  ok(3 <= monthCount && monthCount <= 47);
  const monthLengths = o.chooseMonthLengths(r, y, monthCount);
  eq(monthLengths.length, monthCount);
  eq(monthLengths.reduce((a, b) => a + b, 0), Number(y.closeGateDay - y.openGateDay));
  for (const length of monthLengths) ok(4 <= length && length <= 123);
  const monthNames = o.chooseMonthNames(r, monthCount);
  eq(new Set(monthNames).size, monthCount);
});

group('SourceLanguageCatalog es profundmen congelat, complet, unic e index-stabil', () => {
  const catalog = production.SourceLanguageCatalog;
  ok(Object.isFrozen(catalog));
  ok(Object.isFrozen(catalog.cutlets));
  ok(Object.isFrozen(catalog.months));
  eq(catalog.cutlets.length, 17);
  eq(catalog.months.length, 47);
  eq(new Set(catalog.cutlets.map((row) => row.text)).size, 17);
  eq(new Set(catalog.months.map((row) => row.text)).size, 47);
  catalog.cutlets.forEach((row, index) => {
    ok(Object.isFrozen(row));
    eq(row.canonicalIndex, index + 1);
    eq(production.textByCanonicalIndex('cutlet', index + 1), row.text);
  });
  catalog.months.forEach((row, index) => {
    ok(Object.isFrozen(row));
    eq(row.canonicalIndex, index + 1);
    eq(production.textByCanonicalIndex('month', index + 1), row.text);
  });
  throws(() => { catalog.cutlets[0].text = 'mutat'; }, TypeError);
  throws(() => production.textByCanonicalIndex('cutlet', 0), RangeError);
  throws(() => production.textByCanonicalIndex('month', 48), RangeError);
  throws(() => production.textByCanonicalIndex('altri', 1), RangeError);
});

group('li infrastructura neutral conserva isolation, ownership e non-semantic metrics', () => {
  const contexts = [];
  for (let i = 0; i < 100; i += 1) contexts.push(production.createBootstrapContext(BigInt(i), BigInt(-i)));
  eq(new Set(contexts).size, 100);
  eq(new Set(contexts.map((ctx) => ctx.metrics)).size, 100);
  eq(new Set(contexts.map((ctx) => ctx.logs)).size, 100);
  eq(new Set(contexts.map((ctx) => ctx.diagnostics)).size, 100);
  for (const ctx of contexts) {
    eq(ctx.status, 'READY_FOR_HISTORIC_DEVELOPMENT');
    deepEq(ctx.branchTrace, ['BOOTSTRAP_VALIDATED']);
    eq(ctx.metrics['bootstrap.validations'], 1n);
  }

  const validator = new production.BaseValidationManager();
  const metrics = new production.BaseMetricsManager();
  const wrapper = new production.BaseErrorWrapper();
  const dispatcher = new production.BaseDispatcher(validator, metrics, wrapper);
  const a = new production.BaseMonsterContext(10n, 20n);
  a.metrics.preexistent = 999n;
  a.logs.push('observation');
  const b = new production.BaseMonsterContext(10n, 20n);
  dispatcher.dispatch(a);
  dispatcher.dispatch(b);
  eq(a.status, b.status);
  deepEq(a.branchTrace, b.branchTrace);
  eq(a.calculationDay, b.calculationDay);
  eq(a.targetDay, b.targetDay);
  eq(a.metrics.preexistent, 999n);

  const invalid = new production.BaseMonsterContext(1, 2n);
  throws(() => dispatcher.dispatch(invalid), TypeError);
  eq(invalid.status, 'NEW');
  eq(invalid.phase, 'BOOTSTRAP');
  deepEq(invalid.branchTrace, []);
});

group('errores de base es explicit e li final function resta absent durant Discovery 01', () => {
  let captured = null;
  try {
    production.createBootstrapContext(1, 2n);
  } catch (error) {
    captured = error;
  }
  ok(captured instanceof production.BootstrapStageError);
  ok(captured.cause instanceof TypeError);
  throws(() => production.calendarDateSpaghetti(1n, 1n), production.BootstrapStageError);
});

console.log('\n' + groupsPassed + ' gruppes regressiv passat; ' + assertions + ' assertions passat ante li regression expectat de Discovery 01.');
