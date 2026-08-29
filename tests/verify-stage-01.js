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

group('null textu hebreic o code posterior a Discovery 21 contamina production', () => {
  const root = path.join(__dirname, '..');
  const textFiles = listFiles(root).filter((file) => /\.(?:js|json|md)$/.test(file));
  for (const file of textFiles) {
    const source = fs.readFileSync(file, 'utf8');
    ok(!/[\u0590-\u05FF]/u.test(source), file);
  }
  const futureTokens = [
    'patchedCounts', 'bowlOrderWithRankBridge',
    'CutletPartitionPatchWrapper', 'filteredCutletCompositions', 'legacyNameRowWithRepeats', 'VirtualLegacyList',
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

group('Discovery 02 conserva li oldDayTag defectiv in un path real e isolat', () => {
  const f = production.FOUNDATION_DAY_OLD;
  eq(production.oldDayTag(f - 2n), 4n);
  eq(production.oldDayTag(f - 1n), 2n);
  eq(production.oldDayTag(f), 0n);
  eq(production.oldDayTag(f + 1n), 2n);
  eq(production.oldDayTag(f + 2n), 4n);

  const execution = production.discovery02LegacyDayTagThroughMonsterPath(f, f, f + 1n);
  eq(execution.result, 2n);
  eq(execution.context.legacyDayTagInput, f + 1n);
  eq(execution.context.legacyDayTagOutput, 2n);
  eq(execution.context.currentHandler, 'Discovery02DayTagHandler');
  eq(execution.context.phase, 'DISCOVERY_02_LEGACY_DAY_TAG');
  eq(execution.context.status, 'DISCOVERY_02_LEGACY_RESULT');
  deepEq(execution.context.branchTrace, ['BOOTSTRAP_VALIDATED', 'DISCOVERY_02_OLD_DAY_TAG']);
  eq(execution.context.metrics['discovery02.legacyDayTag.calls'], 1n);
});

group('Patch 02 conserva li scar oldDayTag e rende li dayCount normativ exact', () => {
  const f = production.FOUNDATION_DAY_OLD;
  for (let delta = -100n; delta <= 100n; delta += 1n) {
    const day = f + delta;
    eq(production.dayTagWithFoundationScar(day), o.dayCount(day));
  }
  eq(production.oldDayTag(f), 0n);
  eq(production.dayTagWithFoundationScar(f), 1n);
  eq(production.dayTagWithFoundationScar(f + 1n), 3n);

  const execution = production.historicDayTagThroughMonsterPath(f, f, f);
  eq(execution.context.legacyDayTagOutput, 0n);
  eq(execution.context.patch02Output, 1n);
  eq(execution.context.patch02AddedParityUnit, true);
  eq(execution.context.patch02FoundationGuardChecked, true);
  eq(execution.context.currentHandler, 'Patch02DayTagWrapper');
  eq(execution.context.phase, 'PATCH_02_DAY_TAG_FOUNDATION_SCAR');
  eq(execution.context.status, 'PATCH_02_RESULT');
  deepEq(execution.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_02_OLD_DAY_TAG',
    'PATCH_02_DAY_TAG_FOUNDATION_SCAR'
  ]);
  eq(execution.context.metrics['discovery02.legacyDayTag.calls'], 1n);
  eq(execution.context.metrics['patch02.dayTag.calls'], 1n);
});

group('Discovery 03 conserva li oldDistance defectiv in un path real e isolat', () => {
  const f = production.FOUNDATION_DAY_OLD;
  const cases = [
    [f, f],
    [f - 2n, f + 2n],
    [f - 1n, f],
    [f, f + 1n],
    [f + 1n, f + 3n],
    [f - 3n, f - 1n]
  ];
  const actual = cases.map(([c, t]) => production.oldDistance(c, t));
  deepEq(actual, [0n, 1n, 1n, 2n, 4n, 4n]);
  const normativeDistances = cases.map(([c, t]) => o.workCounts(c, t).distance);
  deepEq(normativeDistances, [1n, 5n, 2n, 2n, 3n, 3n]);
  ok(actual.some((value, index) => value !== normativeDistances[index]));

  const execution = production.discovery03LegacyDistanceThroughMonsterPath(f - 2n, f + 2n);
  eq(execution.result, 1n);
  eq(execution.context.legacyDistanceCalculationDay, f - 2n);
  eq(execution.context.legacyDistanceTargetDay, f + 2n);
  eq(execution.context.legacyDistanceCalculationTag, 4n);
  eq(execution.context.legacyDistanceTargetTag, 5n);
  eq(execution.context.legacyDistanceOutput, 1n);
  eq(execution.context.currentHandler, 'Discovery03DistanceHandler');
  eq(execution.context.phase, 'DISCOVERY_03_LEGACY_DISTANCE');
  eq(execution.context.status, 'DISCOVERY_03_LEGACY_RESULT');
  deepEq(execution.context.branchTrace, ['BOOTSTRAP_VALIDATED', 'DISCOVERY_03_OLD_DISTANCE']);
  eq(execution.context.metrics['discovery03.legacyDistance.calls'], 1n);
});

group('Patch 03 conserva oldDistance ma rende li distance inclusiv exact per un detour cronologic', () => {
  const f = production.FOUNDATION_DAY_OLD;
  for (let dc = -16n; dc <= 16n; dc += 1n) {
    for (let dt = -16n; dt <= 16n; dt += 1n) {
      const c = f + dc;
      const t = f + dt;
      eq(production.distanceWithChronologyDetour(c, t), o.workCounts(c, t).distance);
    }
  }
  const execution = production.historicDistanceThroughMonsterPath(f - 2n, f + 2n);
  eq(execution.context.legacyDistanceOutput, 1n);
  eq(execution.context.patch03ChronologicalDistance, 4n);
  eq(execution.context.patch03LegacyReplaced, true);
  eq(execution.context.patch03DistanceBeforeInclusive, 4n);
  eq(execution.result, 5n);
  eq(execution.context.currentHandler, 'Patch03DistanceWrapper');
  eq(execution.context.phase, 'PATCH_03_CHRONOLOGY_DETOUR');
  eq(execution.context.status, 'PATCH_03_RESULT');
  deepEq(execution.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_03_OLD_DISTANCE',
    'PATCH_03_CHRONOLOGY_DETOUR'
  ]);
  eq(execution.context.metrics['discovery03.legacyDistance.calls'], 1n);
  eq(execution.context.metrics['patch03.distance.calls'], 1n);
});

group('Discovery 04 conserva li mutation sequential in-place e su divergentie precis', () => {
  const start = { w: 17n, b: 29n, s: 43n, m: 71n, r: 101n };
  const direct = { ...start };
  const directResult = production.mutateStonesWrong(2n, direct);
  ok(directResult === direct);
  deepEq(
    [direct.w, direct.b, direct.s, direct.m, direct.r],
    [378n, 1434n, 3780n, 9932n, 25047n]
  );
  const normativeRow = o.STONES[1];
  eq(direct.w, normativeRow[0]);
  ok(direct.b !== normativeRow[1]);
  ok(direct.s !== normativeRow[2]);
  ok(direct.m !== normativeRow[3]);
  ok(direct.r !== normativeRow[4]);

  const execution = production.discovery04LegacyStoneMutationThroughMonsterPath(
    o.FOUNDATION_DAY, o.FOUNDATION_DAY, 2n, start
  );
  deepEq(execution.context.legacyStoneInputBefore, start);
  eq(execution.context.legacyStoneReturnedSameObject, true);
  eq(execution.context.currentHandler, 'Discovery04StoneMutationHandler');
  eq(execution.context.phase, 'DISCOVERY_04_SEQUENTIAL_STONE_MUTATION');
  eq(execution.context.status, 'DISCOVERY_04_LEGACY_RESULT');
  deepEq(execution.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_04_MUTATE_STONES_WRONG'
  ]);
  eq(execution.context.metrics['discovery04.legacyStoneMutation.calls'], 1n);
  deepEq(
    [execution.result.w, execution.result.b, execution.result.s, execution.result.m, execution.result.r],
    [378n, 1434n, 3780n, 9932n, 25047n]
  );
});

group('Patch 04 conserva li call legacy ma li builder usa snapshot simultan por omni 46 rows', () => {
  const f = o.FOUNDATION_DAY;
  const start = { w: 17n, b: 29n, s: 43n, m: 71n, r: 101n };
  const legacy = production.discovery04LegacyStoneMutationThroughMonsterPath(f, f, 2n, start);
  deepEq(
    [legacy.result.w, legacy.result.b, legacy.result.s, legacy.result.m, legacy.result.r],
    [378n, 1434n, 3780n, 9932n, 25047n]
  );
  const patched = production.historicStoneMutationThroughMonsterPath(f, f, 2n, start);
  deepEq(
    [patched.result.w, patched.result.b, patched.result.s, patched.result.m, patched.result.r],
    o.STONES[1]
  );
  deepEq(patched.context.patch04LegacyGarbageBeforeOverwrite, {
    w: 378n, b: 1434n, s: 3780n, m: 9932n, r: 25047n
  });
  eq(patched.context.patch04LegacyCallPreserved, true);
  eq(patched.context.currentHandler, 'Patch04StoneWrapper');
  eq(patched.context.status, 'PATCH_04_RESULT');
  const table = production.getStoneTableThroughLegacyBuilder();
  eq(table.length, 46);
  for (let i = 0; i < table.length; i += 1) {
    deepEq([table[i].w, table[i].b, table[i].s, table[i].m, table[i].r], o.STONES[i]);
  }
});

group('Discovery 05 conserva li hidden values exact ma li stores in ordine retrograd', () => {
  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = o.buildHiddenDrops(counts, o.STONES);
  const legacy = production.buildHiddenWithBackwardStorage(counts, stones);
  eq(legacy.length, 8);
  eq(legacy[0], null);
  deepEq(legacy.slice(1), expected.slice().reverse());
  eq(legacy[1], expected[6]);
  eq(legacy[7], expected[0]);
  ok(legacy[1] !== expected[0]);
  ok(legacy[7] !== expected[6]);
  const expectedCoeff = [
    [3n, 4n, 6n, 8n],
    [5n, 7n, 10n, 12n],
    [7n, 10n, 14n, 16n],
    [9n, 13n, 18n, 20n],
    [11n, 16n, 22n, 24n],
    [13n, 19n, 26n, 28n],
    [15n, 22n, 30n, 32n]
  ];
  for (let k = 1; k <= 7; k += 1) deepEq(production.coeffForHidden(k), expectedCoeff[k - 1]);
  const execution = production.discovery05LegacyHiddenStorageThroughMonsterPath(f, f, counts, stones);
  deepEq(execution.result.slice(1), expected.slice().reverse());
  eq(execution.context.currentHandler, 'Discovery05HiddenStorageHandler');
  eq(execution.context.phase, 'DISCOVERY_05_HIDDEN_BACKWARD_STORAGE');
  eq(execution.context.status, 'DISCOVERY_05_LEGACY_RESULT');
  deepEq(execution.context.branchTrace, ['BOOTSTRAP_VALIDATED', 'DISCOVERY_05_HIDDEN_BACKWARD_STORAGE']);
  eq(execution.context.legacyHiddenNearestReadAsSlotOne, expected[6]);
  eq(execution.context.legacyHiddenFarthestReadAsSlotSeven, expected[0]);
  eq(execution.context.metrics['discovery05.hiddenBackward.calls'], 1n);
});

group('Patch 05 traducte access per proximity sin reversar li storage retrograd', () => {
  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = o.buildHiddenDrops(counts, o.STONES);
  const legacy = production.buildHiddenWithBackwardStorage(counts, stones);
  const snapshot = legacy.slice();
  for (let k = 1; k <= 7; k += 1) {
    eq(production.hiddenByNearness(legacy, k), expected[k - 1]);
  }
  deepEq(legacy, snapshot);
  const routed = production.historicHiddenByNearnessThroughMonsterPath(f, f, counts, stones, 7);
  eq(routed.result, expected[6]);
  eq(routed.context.patch05PhysicalSlot, 1);
  eq(routed.context.patch05StoragePreserved, true);
  eq(routed.context.currentHandler, 'Patch05HiddenNearnessWrapper');
  eq(routed.context.metrics['patch05.hiddenNearness.calls'], 1n);
});

group('Discovery 06 conserva legacyPrior limitat al storage de visible drops', () => {
  const f = o.FOUNDATION_DAY;
  const dropStore = [];
  dropStore[1] = 101n;
  dropStore[2] = 202n;
  dropStore[3] = 303n;
  eq(production.legacyPrior(dropStore, 3, 1), 202n);
  eq(production.legacyPrior(dropStore, 1, 1), undefined);
  eq(production.legacyPrior(dropStore, 1, 3), undefined);
  eq(production.legacyPrior(dropStore, 1, 7), undefined);
  const routed = production.discovery06LegacyPriorThroughMonsterPath(f, f, dropStore, 2, 3);
  eq(routed.result, undefined);
  eq(routed.context.legacyPriorSlot, -1);
  eq(routed.context.legacyPriorSlotIsVisible, false);
  eq(routed.context.currentHandler, 'Discovery06PriorHandler');
  eq(routed.context.status, 'DISCOVERY_06_LEGACY_RESULT');
  deepEq(routed.context.branchTrace, ['BOOTSTRAP_VALIDATED', 'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY']);
  eq(routed.context.metrics['discovery06.legacyPrior.calls'], 1n);
});

group('Patch 06 traducte slots hidden e conserva legacyPrior por history visibil', () => {
  const f = o.FOUNDATION_DAY;
  const dropStore = [];
  dropStore[1] = 101n;
  dropStore[2] = 202n;
  dropStore[3] = 303n;
  const hidden = [null, 7007n, 6006n, 5005n, 4004n, 3003n, 2002n, 1001n];
  const snapshot = hidden.slice();
  for (let back = 1; back <= 7; back += 1) {
    eq(production.priorPatch(dropStore, hidden, 1, back), production.hiddenByNearness(hidden, back));
  }
  eq(production.priorPatch(dropStore, hidden, 3, 1), 202n);
  deepEq(hidden, snapshot);
  const hiddenRoute = production.historicPriorThroughMonsterPath(f, f, dropStore, hidden, 1, 7);
  eq(hiddenRoute.result, 7007n);
  eq(hiddenRoute.context.legacyPriorOutput, undefined);
  eq(hiddenRoute.context.patch06PriorSlot, -6);
  eq(hiddenRoute.context.patch06HiddenNearness, 7);
  eq(hiddenRoute.context.patch06LegacyVisibleCallUsed, false);
  eq(hiddenRoute.context.currentHandler, 'Patch06PriorWrapper');
  eq(hiddenRoute.context.status, 'PATCH_06_RESULT');
  eq(hiddenRoute.context.metrics['patch06.prior.calls'], 1n);
  const visibleRoute = production.historicPriorThroughMonsterPath(f, f, dropStore, hidden, 3, 1);
  eq(visibleRoute.result, 202n);
  eq(visibleRoute.context.patch06PriorSlot, 2);
  eq(visibleRoute.context.patch06HiddenNearness, null);
  eq(visibleRoute.context.patch06LegacyVisibleCallUsed, true);
});

group('Discovery 07 conserva li table zero-based e expone li indexing legacy 1..11', () => {
  const expected = [
    ['w', 3n, 5n, 7n, 11n],
    ['b', 5n, 7n, 11n, 13n],
    ['s', 7n, 11n, 13n, 17n],
    ['m', 11n, 13n, 17n, 19n],
    ['r', 13n, 17n, 19n, 23n],
    ['w', 17n, 19n, 23n, 29n],
    ['b', 19n, 23n, 29n, 31n],
    ['s', 23n, 29n, 31n, 37n],
    ['m', 29n, 31n, 37n, 41n],
    ['r', 31n, 37n, 41n, 43n],
    ['w', 37n, 41n, 43n, 47n]
  ];
  const shape = (row) => row === undefined ? undefined : [row.kind, row.a, row.b, row.c, row.d];
  deepEq(production.LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED.map(shape), expected);
  deepEq(shape(production.legacyGrindRow(1)), expected[1]);
  deepEq(shape(production.legacyGrindRow(10)), expected[10]);
  eq(production.legacyGrindRow(11), undefined);
  const routed = production.discovery07LegacyGrindRowThroughMonsterPath(1n, 1n, 11);
  eq(routed.context.currentHandler, 'Discovery07GrindIndexHandler');
  eq(routed.context.phase, 'DISCOVERY_07_LEGACY_GRIND_INDEX');
  eq(routed.context.legacyGrindRequestedIndex, 11);
  eq(routed.context.legacyGrindPhysicalIndex, 11);
  eq(routed.context.legacyGrindMissing, true);
  eq(routed.context.metrics['discovery07.legacyGrindIndex.calls'], 1n);
});

group('Patch 07 conserva li legacy indexing e adjunte un sentinel permanent por ordinals 1..11', () => {
  const expected = [
    ['w', 3n, 5n, 7n, 11n],
    ['b', 5n, 7n, 11n, 13n],
    ['s', 7n, 11n, 13n, 17n],
    ['m', 11n, 13n, 17n, 19n],
    ['r', 13n, 17n, 19n, 23n],
    ['w', 17n, 19n, 23n, 29n],
    ['b', 19n, 23n, 29n, 31n],
    ['s', 23n, 29n, 31n, 37n],
    ['m', 29n, 31n, 37n, 41n],
    ['r', 31n, 37n, 41n, 43n],
    ['w', 37n, 41n, 43n, 47n]
  ];
  const shape = (row) => row === undefined || row === null ? row : [row.kind, row.a, row.b, row.c, row.d];
  eq(production.GRIND_TABLE_WITH_SENTINEL.length, 12);
  eq(production.GRIND_TABLE_WITH_SENTINEL[0], null);
  ok(Object.isFrozen(production.GRIND_TABLE_WITH_SENTINEL));
  deepEq(production.GRIND_TABLE_WITH_SENTINEL.slice(1).map(shape), expected);
  deepEq(shape(production.legacyGrindRow(1)), expected[1]);
  eq(production.legacyGrindRow(11), undefined);
  for (let grind = 1; grind <= 11; grind += 1) {
    deepEq(shape(production.grindRowWithSentinel(grind)), expected[grind - 1]);
  }
  const routed = production.historicGrindRowThroughMonsterPath(1n, 1n, 11);
  eq(routed.context.legacyGrindMissing, true);
  eq(routed.context.patch07SentinelPreserved, true);
  eq(routed.context.currentHandler, 'Patch07GrindSentinelWrapper');
  eq(routed.context.status, 'PATCH_07_RESULT');
  deepEq(shape(routed.result), expected[10]);
  eq(routed.context.metrics['patch07.grindSentinel.calls'], 1n);
});

group('Discovery 08 conserva oldPermutationUnrank0 zero-based e passa li ordinal one-based directmen quam rank0', () => {
  deepEq(production.oldPermutationUnrank0(0n), [1, 2, 3, 4, 5, 6]);
  deepEq(production.oldPermutationUnrank0(1n), [1, 2, 3, 4, 6, 5]);
  deepEq(production.oldPermutationUnrank0(719n), [6, 5, 4, 3, 2, 1]);
  throws(() => production.oldPermutationUnrank0(-1n), RangeError);
  throws(() => production.oldPermutationUnrank0(720n), RangeError);
  deepEq(production.legacyBowlOrderFromDrop(1n), [1, 2, 3, 4, 6, 5]);
  const routed = production.discovery08LegacyBowlOrderThroughMonsterPath(1n, 1n, 1n);
  eq(routed.context.currentHandler, 'Discovery08PermutationRankHandler');
  eq(routed.context.phase, 'DISCOVERY_08_LEGACY_PERMUTATION_RANK');
  eq(routed.context.status, 'DISCOVERY_08_LEGACY_RESULT');
  eq(routed.context.legacyPermutationDrop, 1n);
  eq(routed.context.legacyPermutationOneBased, 1n);
  eq(routed.context.legacyPermutationRankPassedToUnrank0, 1n);
  deepEq(routed.result, [1, 2, 3, 4, 6, 5]);
  eq(routed.context.metrics['discovery08.legacyPermutationRank.calls'], 1n);
});

group('Patch 08 conserva oldPermutationUnrank0 e traducte li ordinal one-based a rank0 per -1', () => {
  deepEq(production.legacyBowlOrderFromDrop(1n), [1, 2, 3, 4, 6, 5]);
  deepEq(production.orderPatchFromValue(1n), [1, 2, 3, 4, 5, 6]);
  deepEq(production.orderPatchFromValue(720n), [6, 5, 4, 3, 2, 1]);
  const source = production.orderPatchFromValue.toString();
  ok(source.includes('oneBased = regularMod(value - 1n, 720n) + 1n'));
  ok(source.includes('legacyRank0 = oneBased - 1n'));
  ok(source.includes('oldPermutationUnrank0(legacyRank0)'));
  const routed = production.historicBowlOrderThroughMonsterPath(1n, 1n, 1n);
  eq(routed.context.currentHandler, 'Patch08PermutationWrapper');
  eq(routed.context.previousHandler, 'Discovery08PermutationRankHandler');
  eq(routed.context.patch08OneBased, 1n);
  eq(routed.context.patch08LegacyRank0, 0n);
  deepEq(routed.result, [1, 2, 3, 4, 5, 6]);
  eq(routed.context.metrics['patch08.permutationRank.calls'], 1n);
});

group('Discovery 09 conserva pours ligat a bowl IDs fix 1,2,3 in vice de positions in order', () => {
  const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
  const stoneRow = { w: 2n, b: 3n, s: 5n };
  const legacy = production.legacyPoursToFixedBowlIds(127n, 4n, oldBowls, stoneRow);
  deepEq(legacy.order, [2, 1, 4, 3, 5, 6]);
  deepEq(legacy.pours.slice(1, 4), [16163n, 16188n, 16242n]);
  const expected = [16167n, 16182n, 16252n];
  ok(legacy.pours.slice(1, 4).some((value, index) => value !== expected[index]));
  const source = production.legacyPoursToFixedBowlIds.toString();
  ok(source.includes('oldBowls[1]'));
  ok(source.includes('oldBowls[2]'));
  ok(source.includes('oldBowls[3]'));
  ok(source.includes('orderPatchFromValue(drop)'));
  const routed = production.discovery09LegacyFixedPoursThroughMonsterPath(1n, 1n, 127n, 4n, oldBowls, stoneRow);
  eq(routed.context.currentHandler, 'Discovery09FixedPourHandler');
  eq(routed.context.phase, 'DISCOVERY_09_FIXED_BOWL_POURS');
  eq(routed.context.status, 'DISCOVERY_09_LEGACY_RESULT');
  deepEq(routed.context.legacyPourOrder, [2, 1, 4, 3, 5, 6]);
  deepEq(routed.context.legacyPourFixedBowlIds, [1, 2, 3]);
  deepEq(routed.result.pours.slice(1, 4), [16163n, 16188n, 16242n]);
  eq(routed.context.metrics['discovery09.fixedPour.calls'], 1n);
});

group('Patch 09 conserva li scar fixed-bowl ma passa omni read semantic per bowlAlias', () => {
  const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
  const stoneRow = { w: 2n, b: 3n, s: 5n };
  const legacy = production.legacyPoursToFixedBowlIds(127n, 4n, oldBowls, stoneRow);
  deepEq(legacy.pours.slice(1, 4), [16163n, 16188n, 16242n]);
  const alias = production.installBowlAlias([2, 1, 4, 3, 5, 6]);
  deepEq(alias, [null, 2, 1, 4, 3, 5, 6]);
  eq(production.bowlAtLegacyPosition(oldBowls, alias, 1), 13n);
  eq(production.bowlAtLegacyPosition(oldBowls, alias, 2), 11n);
  eq(production.bowlAtLegacyPosition(oldBowls, alias, 3), 19n);
  const patched = production.poursThroughBowlAlias(127n, 4n, oldBowls, stoneRow);
  deepEq(patched.bowlAlias, [null, 2, 1, 4, 3, 5, 6]);
  deepEq(patched.pours.slice(1, 4), [16167n, 16182n, 16252n]);
  const source = production.poursThroughBowlAlias.toString();
  ok(source.includes('legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow)'));
  ok(source.includes('installBowlAlias(order)'));
  ok(source.includes('bowlAtLegacyPosition(oldBowls, bowlAlias, 1)'));
  ok(source.includes('bowlAtLegacyPosition(oldBowls, bowlAlias, 2)'));
  ok(source.includes('bowlAtLegacyPosition(oldBowls, bowlAlias, 3)'));
  const routed = production.historicPoursThroughMonsterPath(1n, 1n, 127n, 4n, oldBowls, stoneRow);
  eq(routed.context.currentHandler, 'Patch09BowlAliasWrapper');
  eq(routed.context.previousHandler, 'Discovery09FixedPourHandler');
  deepEq(routed.context.patch09BowlAlias, [null, 2, 1, 4, 3, 5, 6]);
  deepEq(routed.context.patch09AliasedBowlIds, [2, 1, 4]);
  eq(routed.context.patch09LegacyCallPreserved, true);
  deepEq(routed.result.pours.slice(1, 4), [16167n, 16182n, 16252n]);
  eq(routed.context.metrics['patch09.bowlAlias.calls'], 1n);
});

group('Discovery 10 conserva li contamination sequential in-place del six bowls', () => {
  const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
  const stoneRow = { w: 2n, b: 3n, s: 5n, m: 7n, r: 11n };
  const mutable = oldBowls.slice();
  const legacy = production.legacyStirOneDropInPlace(1n, 4n, mutable, stoneRow);
  eq(legacy.bowls, mutable);
  deepEq(legacy.order, [1, 2, 3, 4, 5, 6]);
  deepEq(legacy.bowls.slice(1), [23205n, 2167757877n, 18796698741299337031n, 52134066600902479800271676581807921729n, 49276137518158613509478075707571518903n, 122328037836810514334452521434516846956n]);
  const expected = [null, 23205n, 23443n, 49647n, 18871n, 28375n, 13610n];
  eq(legacy.bowls[1], expected[1]);
  for (let id = 2; id <= 6; id += 1) ok(legacy.bowls[id] !== expected[id]);
  const source = production.legacyStirOneDropInPlace.toString();
  ok(source.includes('poursThroughBowlAlias(drop, index, bowls, stoneRow)'));
  ok(source.includes('bowls[bowlId] = savePatch('));
  ok(source.includes('2n * bowls[prevId]'));
  ok(source.includes('3n * bowls[nextId]'));
  ok(!source.includes('vaultOld'));
  ok(!source.includes('pending'));
  const routed = production.discovery10LegacyInPlaceBowlsThroughMonsterPath(1n, 1n, 1n, 4n, oldBowls, stoneRow);
  eq(routed.context.currentHandler, 'Discovery10InPlaceBowlHandler');
  eq(routed.context.phase, 'DISCOVERY_10_IN_PLACE_BOWL_CONTAMINATION');
  eq(routed.context.status, 'DISCOVERY_10_LEGACY_RESULT');
  eq(routed.context.legacyBowlRoundReturnedSameObject, true);
  deepEq(routed.context.legacyBowlRoundInputBefore, oldBowls);
  deepEq(routed.result.bowls.slice(1), legacy.bowls.slice(1));
  deepEq(oldBowls, [null, 11n, 13n, 17n, 19n, 23n, 29n]);
  eq(routed.context.metrics['discovery10.inPlaceBowl.calls'], 1n);
});

group('Patch 10 conserva li scar in-place ma usa vaultOld, pending e commit tardiv', () => {
  const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
  const stoneRow = { w: 2n, b: 3n, s: 5n, m: 7n, r: 11n };
  const legacyMutable = oldBowls.slice();
  const legacy = production.legacyStirOneDropInPlace(1n, 4n, legacyMutable, stoneRow);
  const patched = production.stirOneDropViaShadow(1n, 4n, oldBowls, stoneRow);
  deepEq(legacy.bowls.slice(1), [23205n, 2167757877n, 18796698741299337031n, 52134066600902479800271676581807921729n, 49276137518158613509478075707571518903n, 122328037836810514334452521434516846956n]);
  deepEq(patched.vaultOld, oldBowls);
  deepEq(patched.pending.slice(1), [23205n, 23443n, 49647n, 18871n, 28375n, 13610n]);
  deepEq(patched.bowls, patched.pending);
  deepEq(patched.legacyGarbage.bowls, legacy.bowls);
  const source = production.stirOneDropViaShadow.toString();
  ok(source.includes('legacyStirOneDropInPlace(drop, index, bowls.slice(), stoneRow)'));
  ok(source.includes('const vaultOld = bowls.slice()'));
  ok(source.includes('const pending = new Array(7).fill(null)'));
  ok(source.includes('vaultOld[bowlId]'));
  ok(source.includes('2n * vaultOld[prevId]'));
  ok(source.includes('3n * vaultOld[nextId]'));
  ok(source.includes('pending[bowlId] = savePatch('));
  ok(source.indexOf('const committed = pending.slice()') > source.indexOf('pending[bowlId] = savePatch('));
  const routed = production.historicBowlRoundThroughMonsterPath(1n, 1n, 1n, 4n, oldBowls, stoneRow);
  eq(routed.context.currentHandler, 'Patch10ShadowBowlWrapper');
  eq(routed.context.previousHandler, 'Discovery10InPlaceBowlHandler');
  eq(routed.context.status, 'PATCH_10_RESULT');
  eq(routed.context.patch10LegacyCallPreserved, true);
  deepEq(routed.context.patch10VaultOld, oldBowls);
  deepEq(routed.context.patch10Pending, patched.pending);
  eq(routed.context.patch10CommitAfterAllSix, true);
  deepEq(routed.result.bowls, patched.bowls);
  eq(routed.context.metrics['patch10.shadowBowl.calls'], 1n);
});

group('Discovery 11 superscri li unic memorie de order durant 46 drops e 12 post-stirs', () => {
  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = o.sauce(f, f);
  const direct = production.legacySauceWithOverwritableOrderMemory(counts, stones);
  deepEq(direct.bowls.slice(1), expected.bowls);
  deepEq(direct.drop46OrderDiagnostic, expected.orderAtDrop46);
  eq(direct.orderWriteCount, 58);
  deepEq(direct.lastSource, { kind: 'post-stir', ordinal: 12 });
  deepEq(direct.legacyOrderMemory, direct.lastPostStirOrder);
  deepEq(direct.queryOrder, direct.lastPostStirOrder);
  ok(direct.queryOrder.some((id, index) => id !== expected.orderAtDrop46[index]));
  const source = production.legacySauceWithOverwritableOrderMemory.toString();
  ok(source.includes("lastSource = { kind: 'drop', ordinal: index }"));
  ok(source.includes("lastSource = { kind: 'post-stir', ordinal: stir }"));
  ok(source.includes('legacyOrderMemory = round.order.slice()'));
  const routed = production.discovery11LegacyOverwrittenOrderThroughMonsterPath(f, f, counts, stones);
  eq(routed.context.currentHandler, 'Discovery11OverwrittenOrderHandler');
  eq(routed.context.phase, 'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY');
  eq(routed.context.status, 'DISCOVERY_11_LEGACY_RESULT');
  eq(routed.context.legacyOrderMemoryWriteCount, 58);
  deepEq(routed.context.legacyOrderMemoryLastSource, { kind: 'post-stir', ordinal: 12 });
  deepEq(routed.context.legacyDrop46OrderDiagnostic, expected.orderAtDrop46);
  deepEq(routed.context.legacyQueryOrder, routed.result.lastPostStirOrder);
  eq(routed.context.metrics['discovery11.overwritableOrder.calls'], 1n);
});

group('Patch 11 conserva li memorie superscribil ma query usa un latch single-write de drop 46', () => {
  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = o.sauce(f, f);
  const legacy = production.legacySauceWithOverwritableOrderMemory(counts, stones);
  const patched = production.sauceWithOrderAt46Latch(counts, stones);
  eq(legacy.orderWriteCount, 58);
  deepEq(legacy.queryOrder, legacy.lastPostStirOrder);
  ok(legacy.queryOrder.some((id, index) => id !== expected.orderAtDrop46[index]));
  eq(patched.legacyGarbage.orderWriteCount, 58);
  deepEq(patched.legacyGarbage.queryOrder, legacy.queryOrder);
  deepEq(patched.orderAt46Latch, expected.orderAtDrop46);
  eq(patched.orderAt46LatchWriteCount, 1);
  deepEq(patched.orderAt46LatchSource, { kind: 'drop', ordinal: 46 });
  eq(patched.orderWriteCount, 58);
  deepEq(patched.legacyOrderMemory, patched.lastPostStirOrder);
  deepEq(patched.queryOrder, expected.orderAtDrop46);
  deepEq(patched.bowls.slice(1), expected.bowls);
  const source = production.sauceWithOrderAt46Latch.toString();
  ok(source.includes('legacySauceWithOverwritableOrderMemory(counts, stones)'));
  ok(source.includes('writeOrderAt46LatchOnce(latchState, round.order)'));
  ok(source.includes('queryOrder: readOrderAt46Latch(latchState)'));
  ok(source.indexOf('writeOrderAt46LatchOnce(latchState, round.order)') < source.indexOf('for (let stir = 1; stir <= 12; stir += 1)'));
  const latch = production.createOrderAt46LatchState();
  production.writeOrderAt46LatchOnce(latch, [1, 2, 3, 4, 5, 6]);
  throws(() => production.writeOrderAt46LatchOnce(latch, [6, 5, 4, 3, 2, 1]), production.BootstrapStageError);
  const routed = production.historicOrderAt46ThroughMonsterPath(f, f, counts, stones);
  eq(routed.context.currentHandler, 'Patch11OrderAt46LatchWrapper');
  eq(routed.context.previousHandler, 'Discovery11OverwrittenOrderHandler');
  eq(routed.context.status, 'PATCH_11_RESULT');
  eq(routed.context.patch11LegacyCallPreserved, true);
  eq(routed.context.patch11OrderAt46LatchWriteCount, 1);
  deepEq(routed.context.patch11OrderAt46Latch, expected.orderAtDrop46);
  deepEq(routed.context.patch11QueryOrder, expected.orderAtDrop46);
  eq(routed.context.metrics['patch11.orderAt46Latch.calls'], 1n);
});

group('Discovery 12 conserva li successor numeric fix de bowl ID pos li latch de Patch 11', () => {
  const fixtureLatch = [1, 2, 3, 4, 6, 5];
  deepEq([4, 5, 6].map((id) => production.oldNextBowlFixedName(id)), [5, 6, 1]);
  const normativeFixture = [4, 5, 6].map((id) => o.nextBowlInDrop46Order({ orderAtDrop46: fixtureLatch }, id));
  deepEq(normativeFixture, [6, 1, 5]);
  ok([4, 5, 6].some((id, index) => production.oldNextBowlFixedName(id) !== normativeFixture[index]));
  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = o.sauce(f, f);
  const queriedId = expected.orderAtDrop46[3];
  const routed = production.discovery12LegacyNextBowlThroughMonsterPath(f, f, counts, stones, queriedId);
  eq(routed.context.currentHandler, 'Discovery12NextBowlHandler');
  eq(routed.context.previousHandler, 'Patch11OrderAt46LatchWrapper');
  eq(routed.context.phase, 'DISCOVERY_12_FIXED_ID_NEXT_BOWL');
  eq(routed.context.status, 'DISCOVERY_12_LEGACY_RESULT');
  deepEq(routed.context.legacyNextBowlOrderAt46Latch, expected.orderAtDrop46);
  eq(routed.context.legacyNextBowlQueriedId, queriedId);
  eq(routed.result, production.oldNextBowlFixedName(queriedId));
  ok(routed.result !== o.nextBowlInDrop46Order(expected, queriedId));
  eq(routed.context.metrics['discovery12.fixedIdNextBowl.calls'], 1n);
  const source = production.oldNextBowlFixedName.toString();
  ok(source.includes('return id === 6 ? 1 : id + 1;'));
  ok(!source.includes('indexOf'));
});

group('Patch 12 conserva li scar fixed-ID e rende li successor circular del latch', () => {
  const fixtureLatch = [1, 2, 3, 4, 6, 5];
  deepEq([4, 5, 6].map((id) => production.oldNextBowlFixedName(id)), [5, 6, 1]);
  deepEq([4, 5, 6].map((id) => production.nextBowlFromOrderAt46Latch(fixtureLatch, id)), [6, 1, 5]);
  for (let rank0 = 0n; rank0 < 720n; rank0 += 1n) {
    const order = production.oldPermutationUnrank0(rank0);
    for (let id = 1; id <= 6; id += 1) {
      eq(
        production.nextBowlFromOrderAt46Latch(order, id),
        o.nextBowlInDrop46Order({ orderAtDrop46: order }, id)
      );
    }
  }
  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = o.sauce(f, f);
  const queriedId = expected.orderAtDrop46[3];
  const routed = production.historicNextBowlThroughMonsterPath(f, f, counts, stones, queriedId);
  eq(routed.context.currentHandler, 'NextBowlPatchWrapper');
  eq(routed.context.previousHandler, 'Discovery12NextBowlHandler');
  eq(routed.context.phase, 'PATCH_12_LATCH_CIRCULAR_SUCCESSOR');
  eq(routed.context.status, 'PATCH_12_RESULT');
  eq(routed.context.patch12LegacyDiagnosticPreserved, true);
  eq(routed.context.patch12LegacyDiagnostic, production.oldNextBowlFixedName(queriedId));
  eq(routed.result, o.nextBowlInDrop46Order(expected, queriedId));
  eq(routed.context.metrics['patch12.nextBowl.calls'], 1n);
  const legacySource = production.oldNextBowlFixedName.toString();
  ok(legacySource.includes('return id === 6 ? 1 : id + 1;'));
  ok(!legacySource.includes('indexOf'));
  const patchSource = production.nextBowlFromOrderAt46Latch.toString();
  ok(patchSource.includes('orderAt46Latch.indexOf(queriedBowlId)'));
  ok(patchSource.includes('(position + 1) % orderAt46Latch.length'));
});

group('Discovery 13 expone li modulo bias ante rejection e conserva li patches precedent in li route real', () => {
  eq(production.biasedLegacyPick(production.M_OLD, 10n), 7n);
  const synthetic = { first: production.M_OLD, directionStep: 1n };
  eq(production.ringAnswerAt(synthetic, 0n), production.M_OLD);
  eq(production.ringAnswerAt(synthetic, 1n), 1n);
  ok(production.biasedLegacyPick(production.M_OLD, 10n) !== o.chooseRankShort(synthetic, 10n));

  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const sauce = production.sauceWithOrderAt46Latch(counts, stones);
  const queriedId = 1;
  const seal = 1n;
  const nextId = production.nextBowlFromOrderAt46Latch(sauce.orderAt46Latch, queriedId);
  const stream = production.answerRingFromCurrentState(sauce.bowls, queriedId, nextId, seal);
  ok(stream.first * 2n > production.M_OLD);
  eq(stream.directionStep, -1n);
  const N = stream.first - 1n;
  eq(production.ringAnswerAt(stream, 0n), N + 1n);
  eq(production.ringAnswerAt(stream, 1n), N);
  const routed = production.discovery13LegacyBiasedSelectionThroughMonsterPath(
    f, f, counts, stones, queriedId, seal, N
  );
  eq(routed.context.currentHandler, 'Discovery13BiasedSelectionHandler');
  eq(routed.context.previousHandler, 'NextBowlPatchWrapper');
  eq(routed.context.phase, 'DISCOVERY_13_BIASED_MODULO_SELECTION');
  eq(routed.context.status, 'DISCOVERY_13_LEGACY_RESULT');
  eq(routed.context.legacySelectionInitialAnswer, N + 1n);
  eq(routed.result, 1n);
  eq(o.chooseRankShort(routed.stream, N), N);
  eq(routed.context.metrics['discovery13.biasedModulo.calls'], 1n);
  const legacySource = production.biasedLegacyPick.toString();
  ok(legacySource.includes('return regularMod(x - 1n, N) + 1n;'));
  const adapterSource = production.LegacyBiasedSelectionAdapter.prototype.call.toString();
  ok(adapterSource.includes('ringAnswerAt(stream, 0n)'));
  ok(adapterSource.includes('biasedLegacyPick(x, N)'));
  ok(!adapterSource.includes('while'));
});

group('Patch 13 rejecte sur li sam answer ring ante li unic call semantic al selector legacy', () => {
  const oldSource = production.biasedLegacyPick.toString();
  ok(oldSource.includes('return regularMod(x - 1n, N) + 1n;'));
  ok(!oldSource.includes('while'));
  const patchSource = production.patchedSmallPick.toString();
  ok(patchSource.includes('const limit = (M_OLD / N) * N;'));
  ok(patchSource.includes('while (x > limit)'));
  ok(patchSource.includes('offset += 1n'));
  ok(patchSource.indexOf('while (x > limit)') < patchSource.indexOf('return biasedLegacyPick(x, N);'));

  const synthetic = { first: production.M_OLD, directionStep: 1n };
  eq(production.patchedSmallPick(synthetic, 10n), o.chooseRankShort(synthetic, 10n));

  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const sauce = production.sauceWithOrderAt46Latch(counts, stones);
  const queriedId = 1;
  const seal = 1n;
  const nextId = production.nextBowlFromOrderAt46Latch(sauce.orderAt46Latch, queriedId);
  const stream = production.answerRingFromCurrentState(sauce.bowls, queriedId, nextId, seal);
  const N = stream.first - 1n;
  const routed = production.historicSmallSelectionThroughMonsterPath(
    f, f, counts, stones, queriedId, seal, N
  );
  eq(routed.result, o.chooseRankShort(stream, N));
  eq(routed.context.currentHandler, 'SelectionRejectionPatchWrapper');
  eq(routed.context.previousHandler, 'NextBowlPatchWrapper');
  eq(routed.context.phase, 'PATCH_13_REJECTION_BEFORE_LEGACY_PICK');
  eq(routed.context.status, 'PATCH_13_RESULT');
  eq(routed.context.patch13AcceptanceLimit, N);
  eq(routed.context.patch13AcceptedOffset, 1n);
  eq(routed.context.patch13AcceptedAnswer, N);
  eq(routed.context.patch13LegacyCallPreserved, true);
  eq(routed.context.metrics['patch13.selectionRejection.calls'], 1n);
  eq(routed.context.metrics['discovery13.biasedModulo.calls'], undefined);
  ok(!routed.context.branchTrace.includes('DISCOVERY_13_BIASED_MODULO_SELECTION'));
});

group('Discovery 14 expone li assumption N<=M ante li detour wide', () => {
  const N = production.M_OLD + 1n;
  const synthetic = { first: production.M_OLD, directionStep: 1n };
  throws(() => production.legacySelectionAssumingNLeM(synthetic, N), RangeError);
  eq(o.chooseRankWide(synthetic, N), production.M_OLD);
  const legacySource = production.legacySelectionAssumingNLeM.toString();
  ok(legacySource.includes('return patchedSmallPick(stream, N);'));
  ok(!legacySource.includes('wideDetour'));

  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const routed = production.discovery14LegacyWideSelectionThroughMonsterPath(
    f, f, counts, stones, 1, 1n, N
  );
  eq(routed.context.currentHandler, 'Discovery14WideSelectionHandler');
  eq(routed.context.previousHandler, 'NextBowlPatchWrapper');
  eq(routed.context.status, 'DISCOVERY_14_LEGACY_RESULT');
  eq(routed.context.legacyWideSelectionAssumedShort, true);
  eq(routed.context.legacyWideSelectionFailed, true);
  eq(routed.context.legacyWideSelectionErrorName, 'RangeError');
  eq(routed.result.output, null);
  eq(o.chooseRankWide(routed.stream, N), 2n);
  eq(routed.context.metrics['discovery14.shortOnlyAssumption.calls'], 1n);
  eq(routed.context.metrics['patch13.selectionRejection.calls'], undefined);
  ok(!production.Discovery14WideSelectionHandler.prototype.handle.toString().includes('wideDetour'));
});

group('Patch 14 conserva li failure curt legacy ma dispatcha familie wide al detour exact', () => {
  const M = production.M_OLD;
  const legacySource = production.legacySelectionAssumingNLeM.toString();
  ok(legacySource.includes('return patchedSmallPick(stream, N);'));
  ok(!legacySource.includes('wideDetour'));
  const wideSource = production.wideDetour.toString();
  ok(wideSource.includes('while (space < N)'));
  ok(wideSource.includes('const digit = ringAnswerAt(stream, BigInt(j)) - 1n;'));
  ok(wideSource.includes('wide += digit * weight;'));
  ok(wideSource.includes('weight *= M_OLD;'));
  ok(wideSource.includes('const acceptanceLimit = (space / N) * N;'));
  ok(wideSource.includes('while (wide > acceptanceLimit)'));
  const tail = wideSource.slice(wideSource.indexOf('const acceptanceLimit'));
  ok(!tail.includes('ringAnswerAt'));

  const synthetic = { first: M / 2n + 10n, directionStep: -1n };
  const d0 = production.ringAnswerAt(synthetic, 0n) - 1n;
  const d1 = production.ringAnswerAt(synthetic, 1n) - 1n;
  const initialWide = 1n + d0 + d1 * M;
  const rejectionN = initialWide - 1n;
  const detail = production.wideDetour(synthetic, rejectionN);
  eq(detail.places, 2);
  deepEq(detail.digits, [d0, d1]);
  eq(detail.digitReadCount, 2);
  eq(detail.rejectionSteps, 1n);
  eq(detail.acceptedWide, rejectionN);
  eq(detail.output, o.chooseRankWide(synthetic, rejectionN));

  const f = o.FOUNDATION_DAY;
  const counts = o.workCounts(f, f);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const N = M + 1n;
  const legacy = production.discovery14LegacyWideSelectionThroughMonsterPath(f, f, counts, stones, 1, 1n, N);
  const patched = production.historicSelectionThroughMonsterPath(f, f, counts, stones, 1, 1n, N);
  eq(legacy.result.output, null);
  eq(legacy.result.failed, true);
  eq(patched.result, o.chooseRankWide(patched.stream, N));
  eq(patched.result, 2n);
  eq(patched.context.currentHandler, 'WideSelectionPatchWrapper');
  eq(patched.context.previousHandler, 'Discovery14WideSelectionHandler');
  eq(patched.context.phase, 'PATCH_14_SHORT_WIDE_DISPATCH');
  eq(patched.context.status, 'PATCH_14_RESULT');
  eq(patched.context.patch14Mode, 'wide');
  eq(patched.context.patch14LegacyDiagnosticPreserved, true);
  eq(patched.context.patch14LegacyDiagnosticFailed, true);
  eq(patched.context.patch14Places, 2);
  eq(patched.context.patch14DigitReadCount, 2);
  eq(patched.context.patch14Output, 2n);
  eq(patched.context.metrics['patch14.wideDispatcher.calls'], 1n);
  eq(patched.context.metrics['patch14.wideDetour.calls'], 1n);

  const short = production.historicSelectionThroughMonsterPath(f, f, counts, stones, 1, 1n, 10n);
  eq(short.context.patch14Mode, 'short');
  eq(short.result, o.chooseRankShort(short.stream, 10n));
  eq(short.context.patch14DigitReadCount, 0);
  eq(short.context.metrics['patch14.shortCompatibility.calls'], 1n);
  eq(short.context.metrics['patch14.wideDetour.calls'], undefined);
});

group('Discovery 15 conserva li question historic del latere positiv por passus negativ', () => {
  const legacySource = production.oldGateQuestionDay.toString();
  ok(legacySource.includes('return FOUNDATION_DAY_OLD + n;'));
  ok(!legacySource.includes('FOUNDATION_DAY_OLD -'));
  ok(!legacySource.includes('signedStep'));
  eq(production.oldGateQuestionDay(0n), production.FOUNDATION_DAY_OLD);
  eq(production.oldGateQuestionDay(1n), production.FOUNDATION_DAY_OLD + 1n);
  eq(production.oldGateQuestionDay(10n), production.FOUNDATION_DAY_OLD + 10n);
  throws(() => production.oldGateQuestionDay(-1n), RangeError);
  throws(() => production.oldGateQuestionDay(1), TypeError);

  const routed = production.discovery15LegacyGateQuestionThroughMonsterPath(
    o.FOUNDATION_DAY, o.FOUNDATION_DAY, -10n
  );
  eq(routed.result, o.FOUNDATION_DAY + 10n);
  eq(routed.context.currentHandler, 'Discovery15NegativeGateQuestionHandler');
  eq(routed.context.previousHandler, null);
  eq(routed.context.phase, 'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE');
  eq(routed.context.status, 'DISCOVERY_15_LEGACY_RESULT');
  eq(routed.context.legacyGateSignedStep, -10n);
  eq(routed.context.legacyGateMagnitude, 10n);
  eq(routed.context.legacyGateQuestionDay, o.FOUNDATION_DAY + 10n);
  eq(routed.context.legacyGateQuestionAskedPositiveSide, true);
  deepEq(routed.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE'
  ]);
  eq(routed.context.metrics['discovery15.negativeGatePositiveSide.calls'], 1n);

  const handlerSource = production.Discovery15NegativeGateQuestionHandler.prototype.handle.toString();
  ok(!handlerSource.includes('FOUNDATION_DAY_OLD -'));
  ok(!handlerSource.includes('gateQuestionWithSignedStep'));
  ok(!handlerSource.includes('NegativeGateQuestionPatchWrapper'));
});

group('Patch 15 conserva li scar positiv e devia exclusivmen signedStep negativ', () => {
  const legacySource = production.oldGateQuestionDay.toString();
  ok(legacySource.includes('return FOUNDATION_DAY_OLD + n;'));
  ok(!legacySource.includes('FOUNDATION_DAY_OLD -'));
  ok(!legacySource.includes('signedStep'));
  const patchSource = production.gateQuestionWithSignedStep.toString();
  ok(patchSource.includes('let q = oldGateQuestionDay(magnitude);'));
  ok(patchSource.includes('if (signedStep < 0n)'));
  ok(patchSource.includes('q = FOUNDATION_DAY_OLD - magnitude;'));
  ok(patchSource.indexOf('oldGateQuestionDay(magnitude)') < patchSource.indexOf('if (signedStep < 0n)'));

  for (const signedStep of [-1n, -2n, -10n, -101n]) {
    const magnitude = -signedStep;
    eq(production.oldGateQuestionDay(magnitude), o.FOUNDATION_DAY + magnitude);
    eq(production.gateQuestionWithSignedStep(signedStep), o.FOUNDATION_DAY - magnitude);
  }
  for (const signedStep of [0n, 1n, 10n, 101n]) {
    eq(production.gateQuestionWithSignedStep(signedStep), production.oldGateQuestionDay(signedStep));
  }

  const routed = production.historicGateQuestionThroughMonsterPath(
    o.FOUNDATION_DAY, o.FOUNDATION_DAY, -10n
  );
  eq(routed.result, o.FOUNDATION_DAY - 10n);
  eq(routed.context.currentHandler, 'NegativeGateQuestionPatchWrapper');
  eq(routed.context.previousHandler, 'Discovery15NegativeGateQuestionHandler');
  eq(routed.context.phase, 'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR');
  eq(routed.context.status, 'PATCH_15_RESULT');
  eq(routed.context.patch15SignedStep, -10n);
  eq(routed.context.patch15Magnitude, 10n);
  eq(routed.context.patch15LegacyDiagnostic, o.FOUNDATION_DAY + 10n);
  eq(routed.context.patch15LegacyDiagnosticPreserved, true);
  eq(routed.context.patch15NegativeDetourUsed, true);
  eq(routed.context.patch15Output, o.FOUNDATION_DAY - 10n);
  deepEq(routed.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE',
    'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR'
  ]);
  eq(routed.context.metrics['patch15.negativeGateDetour.calls'], 1n);
  eq(routed.context.metrics['patch15.negativeGateDetour.used'], 1n);

  const zero = production.historicGateQuestionThroughMonsterPath(o.FOUNDATION_DAY, o.FOUNDATION_DAY, 0n);
  eq(zero.result, o.FOUNDATION_DAY);
  eq(zero.context.patch15NegativeDetourUsed, false);
  eq(zero.context.metrics['patch15.legacySidePreserved.calls'], 1n);
  ok(!production.NegativeGateQuestionPatchWrapper.prototype.repair.toString().includes('LEGACY_YEAR_MAX'));
});

group('Discovery 16 resta observabil quam scar 5781 separat', () => {
  eq(production.LEGACY_YEAR_MAX, 5781n);
  const source = production.legacyYearCandidateAllowed.toString();
  ok(source.includes('candidateLength <= LEGACY_YEAR_MAX'));
  ok(!source.includes('REAL_YEAR_MAX_PATCH'));
  const f = o.FOUNDATION_DAY;
  const gates = { 0: f, 6: f + 5778n, 7: f + 5779n, 8: f + 5780n, 9: f + 5781n };
  const pairs = [
    { openIndex: 0, closeIndex: 9 },
    { openIndex: 0, closeIndex: 7 },
    { openIndex: 0, closeIndex: 6 },
    { openIndex: 0, closeIndex: 8 }
  ];
  const prepared = production.legacyStableLengthOnlyYearCandidates(gates, pairs);
  deepEq(prepared.map((candidate) => candidate.candidateLength), [5778n, 5779n, 5780n, 5781n]);
  const routed = production.discovery16LegacyYearCandidatesThroughMonsterPath(
    f, f, -1n, gates, pairs, { first: 1n, directionStep: 1n }
  );
  eq(routed.context.currentHandler, 'Discovery16LegacyYearCandidateHandler');
  eq(routed.context.status, 'DISCOVERY_16_LEGACY_RESULT');
  eq(routed.context.legacyYearCandidateSelectionFamilySize, 4);
  deepEq(routed.context.legacyYearCandidateOverlongLengths, [5779n, 5780n, 5781n]);
  eq(routed.context.metrics['discovery16.selectionReached.calls'], 1n);
  ok(!production.legacyStableLengthOnlyYearCandidates.toString().includes('REAL_YEAR_MAX_PATCH'));
});

group('Patch 16 filtra 5779..5781 ante sort e selection semantic', () => {
  eq(production.REAL_YEAR_MAX_PATCH, 5778n);
  const patchSource = production.yearCandidateAfterFootnotePatch.toString();
  ok(patchSource.includes('legacyYearCandidateAllowed(gates, openIndex, closeIndex)'));
  ok(patchSource.includes('candidateLength > REAL_YEAR_MAX_PATCH'));
  ok(patchSource.indexOf('legacyYearCandidateAllowed') < patchSource.indexOf('candidateLength > REAL_YEAR_MAX_PATCH'));
  const f = o.FOUNDATION_DAY;
  const gates = { 0: f, 6: f + 5778n, 7: f + 5779n, 8: f + 5780n, 9: f + 5781n };
  const pairs = [
    { openIndex: 0, closeIndex: 9 },
    { openIndex: 0, closeIndex: 7 },
    { openIndex: 0, closeIndex: 6 },
    { openIndex: 0, closeIndex: 8 }
  ];
  const beforeSort = production.yearCandidatesAfterFootnotePatchBeforeSort(gates, pairs);
  deepEq(beforeSort.map((candidate) => candidate.candidateLength), [5778n]);
  ok(!production.yearCandidatesAfterFootnotePatchBeforeSort.toString().includes('.sort('));
  const sorted = production.stableLengthOnlyPatchedYearCandidates(gates, pairs);
  deepEq(sorted.map((candidate) => candidate.candidateLength), [5778n]);
  ok(!production.stableLengthOnlyPatchedYearCandidates.toString().includes('sortEqualLengthRunsByOpeningGate'));
  const routed = production.historicYearCandidatesThroughMonsterPath(
    f, f, -1n, gates, pairs, { first: 1n, directionStep: 1n }
  );
  eq(routed.context.currentHandler, 'YearCandidateCeilingPatchWrapper');
  eq(routed.context.previousHandler, 'NegativeGateQuestionPatchWrapper');
  eq(routed.context.status, 'PATCH_16_RESULT');
  deepEq(routed.context.patch16RejectedOverlongLengths, [5781n, 5779n, 5780n]);
  deepEq(routed.context.patch16SortedFamily.map((candidate) => candidate.candidateLength), [5778n]);
  eq(routed.context.patch16SelectionFamilySize, 1);
  eq(routed.context.metrics['patch16.overlongRejected.beforeSort'], 3n);
  eq(routed.context.metrics['discovery16.selectionReached.calls'], undefined);
});

group('Discovery 17 expone li tie de Year 5000 sin reorder per opening gate', () => {
  const f = o.FOUNDATION_DAY;
  const calculationDay = f + 100n;
  const gates = {
    10: f + 10n, 16: f + 500n,
    20: f + 20n, 26: f + 510n,
    30: f + 30n, 36: f + 520n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const routed = production.discovery17LegacyYear5000TieThroughMonsterPath(
    calculationDay, calculationDay, -1n, gates, pairs, { first: 1n, directionStep: 1n }
  );
  eq(routed.context.currentHandler, 'Discovery17Year5000TieHandler');
  eq(routed.context.previousHandler, 'YearCandidateCeilingPatchWrapper');
  eq(routed.context.status, 'DISCOVERY_17_LEGACY_TIE_RESULT');
  deepEq(routed.context.patch16RejectedOverlongLengths, []);
  deepEq(routed.context.discovery17OpeningOrder, [f + 30n, f + 10n, f + 20n]);
  eq(routed.context.discovery17WitnessCandidateLength, 490n);
  eq(routed.context.discovery17WitnessFamilySize, 3);
  eq(routed.context.discovery17SelectedOrdinal, 1n);
  eq(routed.context.discovery17Selected.openGate, f + 30n);
  eq(routed.context.discovery17StableLengthOnlyScarPreserved, true);
  eq(routed.context.metrics['discovery17.year5000Tie.calls'], 1n);
  eq(routed.context.metrics['discovery17.equalLengthRuns.observed'], undefined);
  ok(!production.Discovery17Year5000TieHandler.prototype.handle.toString().includes('.sort('));
  ok(!production.stableLengthOnlyPatchedYearCandidates.toString().includes('sortEqualLengthRunsByOpeningGate'));
});

group('Patch 17 reordena solmen runs contigui egal per opening gate tempran', () => {
  const helperSource = production.sortEqualLengthRunsByOpeningGate.toString();
  ok(helperSource.includes('while (start < list.length)'));
  ok(helperSource.includes('list[end].candidateLength === length'));
  ok(helperSource.includes('const run = list.slice(start, end);'));
  ok(helperSource.includes('run.sort'));
  ok(!helperSource.includes('list.sort'));

  const discontiguous = [
    { candidateLength: 300n, openGate: 30n, tag: 'a' },
    { candidateLength: 200n, openGate: 10n, tag: 'b' },
    { candidateLength: 300n, openGate: 20n, tag: 'c' }
  ];
  production.sortEqualLengthRunsByOpeningGate(discontiguous);
  deepEq(discontiguous.map((item) => item.tag), ['a', 'b', 'c']);

  const f = o.FOUNDATION_DAY;
  const calculationDay = f + 100n;
  const gates = {
    10: f + 10n, 16: f + 500n,
    20: f + 20n, 26: f + 510n,
    30: f + 30n, 36: f + 520n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const routed = production.historicYear5000TieThroughMonsterPath(
    calculationDay, calculationDay, -1n, gates, pairs, { first: 1n, directionStep: 1n }
  );
  eq(routed.context.currentHandler, 'Year5000TiePatchWrapper');
  eq(routed.context.previousHandler, 'Discovery17Year5000TieHandler');
  eq(routed.context.status, 'PATCH_17_RESULT');
  deepEq(routed.context.patch17LegacyLengthSortedFamily.map((candidate) => candidate.openGate), [f + 30n, f + 10n, f + 20n]);
  deepEq(routed.context.patch17RepairedFamily.map((candidate) => candidate.openGate), [f + 10n, f + 20n, f + 30n]);
  eq(routed.context.patch17LegacySelectedDiagnostic.openGate, f + 30n);
  eq(routed.context.patch17LegacyDiagnosticPreserved, true);
  eq(routed.context.patch17EqualLengthRunCount, 1);
  eq(routed.context.patch17SelectedOrdinal, 1n);
  eq(routed.context.patch17Selected.openGate, f + 10n);
  eq(routed.context.metrics['patch17.equalLengthRunRepair.calls'], 1n);
  eq(routed.context.metrics['patch17.equalLengthRuns.reordered'], 1n);
  ok(!production.Year5000TiePatchWrapper.prototype.repair.toString().includes('oldJumpGuess'));
});

group('Discovery 18 conserva oldJumpGuess /365 quam scar semantic direct', () => {
  const helperSource = production.oldJumpGuess.toString();
  ok(helperSource.includes('targetDay - anchor.firstDay'));
  ok(helperSource.includes('floorDiv(targetDay - anchor.firstDay, 365n)'));
  ok(!helperSource.includes('nextYear'));
  ok(!helperSource.includes('previousYear'));

  const f = o.FOUNDATION_DAY;
  const calculationDay = f + 100n;
  const gates = {
    10: f + 10n, 16: f + 1010n,
    20: f + 20n, 26: f + 1020n,
    30: f + 30n, 36: f + 1030n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const targetDay = f + 376n;
  const routed = production.discovery18LegacyYearJumpThroughMonsterPath(
    calculationDay, targetDay, -1n, gates, pairs, { first: 1n, directionStep: 1n }
  );
  eq(routed.context.currentHandler, 'Discovery18YearJumpHandler');
  eq(routed.context.previousHandler, 'Year5000TiePatchWrapper');
  eq(routed.context.status, 'DISCOVERY_18_LEGACY_RESULT');
  eq(routed.context.legacyJumpAnchorNumber, 5000n);
  eq(routed.context.legacyJumpAnchorFirstDay, f + 11n);
  eq(routed.context.legacyJumpAnchorCloseDay, f + 1010n);
  eq(routed.context.legacyJumpTargetDay, targetDay);
  eq(routed.context.legacyJumpDeltaFromFirstDay, 365n);
  eq(routed.context.legacyJumpGuess, 5001n);
  eq(routed.context.legacyJumpSemanticYearNumber, 5001n);
  eq(routed.context.legacyJumpGuessUsedAsSemantic, true);
  ok(routed.context.legacyJumpAnchorOpenDay < targetDay && targetDay <= routed.context.legacyJumpAnchorCloseDay);
  eq(routed.context.metrics['discovery18.oldJumpGuess.calls'], 1n);
  eq(routed.context.metrics['discovery18.guessUsedAsSemantic.calls'], 1n);
  ok(!production.Discovery18YearJumpHandler.prototype.handle.toString().includes('findYearByWalkPatch'));
  ok(!production.Discovery18YearJumpHandler.prototype.handle.toString().includes('patchedNextYear'));
  ok(!production.Discovery18YearJumpHandler.prototype.handle.toString().includes('patchedPreviousYear'));
});

group('Patch 18 conserva li guess quam telemetry e camina un year a un vez', () => {
  const anchor = { number: 5000n, openDay: 0n, firstDay: 1n, closeDay: 1000n };
  const years = new Map([
    [4999n, { number: 4999n, openDay: -700n, firstDay: -699n, closeDay: 0n }],
    [5000n, anchor],
    [5001n, { number: 5001n, openDay: 1000n, firstDay: 1001n, closeDay: 1700n }],
    [5002n, { number: 5002n, openDay: 1700n, firstDay: 1701n, closeDay: 2500n }]
  ]);
  const nextYear = (year) => ({ ...years.get(year.number + 1n) });
  const previousYear = (year) => ({ ...years.get(year.number - 1n) });
  let walked = production.findYearByWalkPatch(anchor, 365n, nextYear, previousYear);
  eq(walked.year.number, 5000n);
  eq(walked.stepCount, 0n);
  eq(walked.direction, 'anchor');
  walked = production.findYearByWalkPatch(anchor, 1701n, nextYear, previousYear);
  eq(walked.year.number, 5002n);
  eq(walked.stepCount, 2n);
  eq(walked.trace[0].toNumber, 5001n);
  eq(walked.trace[1].toNumber, 5002n);
  walked = production.findYearByWalkPatch(anchor, 0n, nextYear, previousYear);
  eq(walked.year.number, 4999n);
  eq(walked.stepCount, 1n);
  eq(walked.direction, 'previous');
  ok(production.SequentialYearWalkPatchWrapper.prototype.repair.toString().includes('context.patch18LegacyGuessDiagnostic = context.legacyJumpGuess'));
  ok(production.SequentialYearWalkPatchWrapper.prototype.repair.toString().includes('findYearByWalkPatch'));
  ok(!production.SequentialYearWalkPatchWrapper.prototype.repair.toString().includes('LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER'));
});

group('Discovery 19 conserva li bad cache key year.number e expone stale hit sin guards', () => {
  const lookupSource = production.legacyYearNumberOnlyLookup.toString();
  ok(lookupSource.includes('cacheMap.has(yearNumber)'));
  ok(lookupSource.includes('cacheMap.get(yearNumber)'));
  ok(!lookupSource.includes('calculationDayFingerprint'));
  ok(!lookupSource.includes('openingDay'));
  ok(!lookupSource.includes('closingDay'));
  const manager = new production.BaseMonsterManager();
  ok(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER instanceof Map);
  eq(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 0);
  const f = o.FOUNDATION_DAY;
  const gates = {
    10: f + 10n, 16: f + 1010n,
    20: f + 20n, 26: f + 1020n,
    30: f + 30n, 36: f + 1030n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const stream = { first: 1n, directionStep: 1n };
  const noWalk = {
    nextYear() { throw new Error('Null next-year expectat in li probe de cache.'); },
    previousYear() { throw new Error('Null previous-year expectat in li probe de cache.'); }
  };
  const first = manager.executeDiscovery19YearCache(f + 100n, f + 100n, -1n, gates, pairs, stream, noWalk);
  const second = manager.executeDiscovery19YearCache(f + 101n, f + 101n, -1n, gates, pairs, stream, noWalk);
  eq(first.result.hit, false);
  eq(second.result.hit, true);
  eq(first.result.key, 5000n);
  eq(second.result.key, 5000n);
  eq(first.result.value.actionDay, f + 100n);
  eq(second.result.freshValue.actionDay, f + 101n);
  eq(second.result.value.actionDay, f + 100n);
  ok(second.context.legacyYearCacheOnlyNumberKeyPreserved);
  eq(second.context.status, 'DISCOVERY_19_LEGACY_CACHE_RESULT');
  ok(!production.Discovery19YearNumberCacheHandler.prototype.handle.toString().includes('calculationDayFingerprint'));
  ok(!production.Discovery19YearNumberCacheHandler.prototype.handle.toString().includes('cacheGetWithActionGuard'));
  ok(!production.Discovery19YearNumberCacheHandler.prototype.handle.toString().includes('oldStructureSauce'));
});

group('Patch 19 conserva li bad key ma accepta HIT solmen con tri guards exact', () => {
  const legacyLookupSource = production.legacyYearNumberOnlyLookup.toString();
  ok(legacyLookupSource.includes('cacheMap.has(yearNumber)'));
  ok(legacyLookupSource.includes('cacheMap.get(yearNumber)'));
  ok(!legacyLookupSource.includes('calculationDayFingerprint'));
  const getSource = production.cacheGetWithActionGuard.toString();
  ok(getSource.indexOf('legacyYearNumberOnlyLookup(cacheMap, year.number)') < getSource.indexOf('entry.calculationDayFingerprint'));
  ok(getSource.includes('entry.openGate !== year.openDay'));
  ok(getSource.includes('entry.closeGate !== year.closeDay'));
  const putSource = production.cachePutWithGuard.toString();
  ok(putSource.includes('legacyYearNumberOnlyPut(cacheMap, year.number, entry)'));
  ok(putSource.includes('calculationDayFingerprint: calculationDayFingerprint(calculationDay)'));
  ok(putSource.includes('openGate: year.openDay'));
  ok(putSource.includes('closeGate: year.closeDay'));
  eq(production.calculationDayFingerprint(123n), 123n);

  const f = o.FOUNDATION_DAY;
  const year = { number: 5000n, openDay: f + 10n, closeDay: f + 1010n };
  const cache = new Map();
  const value = { yearNumber: 5000n, actionDay: f + 100n, openingDay: f + 10n, closingDay: f + 1010n };
  const entry = production.cachePutWithGuard(cache, year, f + 100n, value);
  eq(cache.size, 1);
  ok(cache.has(5000n));
  eq(entry.calculationDayFingerprint, f + 100n);
  eq(entry.openGate, year.openDay);
  eq(entry.closeGate, year.closeDay);
  let got = production.cacheGetWithActionGuard(cache, year, f + 100n);
  ok(got.hit);
  eq(got.reason, null);
  got = production.cacheGetWithActionGuard(cache, year, f + 101n);
  ok(!got.hit);
  eq(got.reason, 'calculation-day');
  got = production.cacheGetWithActionGuard(cache, { ...year, openDay: f + 11n }, f + 100n);
  ok(!got.hit);
  eq(got.reason, 'open-gate');
  got = production.cacheGetWithActionGuard(cache, { ...year, closeDay: f + 1011n }, f + 100n);
  ok(!got.hit);
  eq(got.reason, 'close-gate');

  const manager = new production.BaseMonsterManager();
  const gates = {
    10: f + 10n, 16: f + 1010n,
    20: f + 20n, 26: f + 1020n,
    30: f + 30n, 36: f + 1030n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const stream = { first: 1n, directionStep: 1n };
  const noWalk = {
    nextYear() { throw new Error('Null next-year expectat in Patch 19.'); },
    previousYear() { throw new Error('Null previous-year expectat in Patch 19.'); }
  };
  const first = manager.executePatch19YearCache(f + 100n, f + 100n, -1n, gates, pairs, stream, noWalk);
  const second = manager.executePatch19YearCache(f + 101n, f + 101n, -1n, gates, pairs, stream, noWalk);
  const third = manager.executePatch19YearCache(f + 101n, f + 101n, -1n, gates, pairs, stream, noWalk);
  ok(!first.result.hit);
  ok(!second.result.hit);
  eq(second.result.reason, 'calculation-day');
  eq(second.result.value.actionDay, f + 101n);
  ok(third.result.hit);
  eq(third.result.value.actionDay, f + 101n);
  eq(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1);
  ok(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.has(5000n));
  eq(second.context.currentHandler, 'YearCacheActionGuardPatchWrapper');
  eq(second.context.previousHandler, 'SequentialYearWalkPatchWrapper');
  eq(second.context.status, 'PATCH_19_RESULT');
  ok(second.context.patch19LegacyDiagnosticPreserved);
  ok(second.context.patch19OnlyNumberKeyPreserved);
  ok(!production.YearCacheActionGuardPatchWrapper.prototype.repair.toString().includes('oldStructureSauce'));
});

group('Discovery 20 usa realmente oldStructureSauce con li target original e envia ti sauce al selector', () => {
  const oldSource = production.oldStructureSauce.toString();
  ok(oldSource.includes('sauceWithCurrentScars(cDay, originalTargetDay)'));
  ok(!oldSource.includes('yearFirstDay'));
  ok(!oldSource.includes('structureSaucePatch'));
  const handlerSource = production.Discovery20StructureSauceHandler.prototype.handle.toString();
  ok(handlerSource.includes('this.sauceAdapter.call(calculationDay, originalTargetDay)'));
  ok(handlerSource.includes('this.selectorAdapter.select(legacySauce)'));
  ok(handlerSource.indexOf('this.sauceAdapter.call(calculationDay, originalTargetDay)') < handlerSource.indexOf('this.selectorAdapter.select(legacySauce)'));
  ok(!handlerSource.includes('sauceWithCurrentScars(calculationDay, yearFirstDay)'));

  const f = o.FOUNDATION_DAY;
  const calculationDay = f + 100n;
  const originalTargetDay = f + 100n;
  const yearFirstDay = f + 11n;
  const old = production.oldStructureSauce(calculationDay, originalTargetDay);
  const oldExpected = o.sauce(calculationDay, originalTargetDay);
  const authoritative = o.sauce(calculationDay, yearFirstDay);
  eq(old.bowls[2], oldExpected.bowls[1]);
  deepEq(old.orderAt46Latch, oldExpected.orderAtDrop46);
  ok(old.bowls[2] !== authoritative.bowls[1]);

  const manager = new production.BaseMonsterManager();
  const gates = {
    10: f + 10n, 16: f + 1010n,
    20: f + 20n, 26: f + 1020n,
    30: f + 30n, 36: f + 1030n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const stream = { first: 1n, directionStep: 1n };
  const noWalk = {
    nextYear() { throw new Error('Null next-year expectat in Discovery 20.'); },
    previousYear() { throw new Error('Null previous-year expectat in Discovery 20.'); }
  };
  const routed = manager.executeDiscovery20StructureSauce(
    calculationDay, originalTargetDay, -1n, gates, pairs, stream, noWalk
  );
  eq(routed.context.status, 'DISCOVERY_20_LEGACY_RESULT');
  eq(routed.context.previousHandler, 'YearCacheActionGuardPatchWrapper');
  ok(routed.context.legacyStructureSauceTargetsDiffer);
  ok(routed.context.legacyStructureSelectorUsedOriginalTargetSauce);
  eq(routed.result.sauceTargetDay, originalTargetDay);
  eq(routed.result.yearFirstDay, yearFirstDay);
  eq(routed.result.selectorToken.bowl2, oldExpected.bowls[1]);
  deepEq(routed.result.selectorToken.orderAt46Latch, oldExpected.orderAtDrop46);
  ok(routed.result.selectorToken.bowl2 !== authoritative.bowls[1]);
  ok(!production.Discovery20StructureSauceHandler.prototype.handle.toString().includes('structureSaucePatch'));
});

group('Patch 20 executa oldStructureSauce quam ghost ma alimenta li selector solmen con year.firstDay', () => {
  const oldSource = production.oldStructureSauce.toString();
  ok(oldSource.includes('sauceWithCurrentScars(cDay, originalTargetDay)'));
  ok(!oldSource.includes('yearFirstDay'));
  const patchSource = production.structureSaucePatch.toString();
  ok(patchSource.includes('const ghost = oldStructureSauce(cDay, originalTargetDay)'));
  ok(patchSource.includes('const semanticSauce = sauceWithCurrentScars(cDay, yearFirstDay)'));
  ok(patchSource.indexOf('oldStructureSauce(cDay, originalTargetDay)') < patchSource.indexOf('sauceWithCurrentScars(cDay, yearFirstDay)'));
  ok(!patchSource.includes('legacyStructureSelectorToken'));
  const wrapperSource = production.StructureSaucePatchWrapper.prototype.repair.toString();
  ok(wrapperSource.includes('this.selectorAdapter.select(patched.semanticSauce)'));
  ok(!wrapperSource.includes('select(patched.ghost)'));

  const f = o.FOUNDATION_DAY;
  const calculationDay = f + 100n;
  const originalTargetDay = f + 365n;
  const yearFirstDay = f + 11n;
  const direct = production.structureSaucePatch(calculationDay, originalTargetDay, yearFirstDay);
  const oldExpected = o.sauce(calculationDay, originalTargetDay);
  const authoritative = o.sauce(calculationDay, yearFirstDay);
  ok(direct.targetsDiffer);
  eq(direct.ghost.bowls[2], oldExpected.bowls[1]);
  deepEq(direct.ghost.orderAt46Latch, oldExpected.orderAtDrop46);
  eq(direct.semanticSauce.bowls[2], authoritative.bowls[1]);
  deepEq(direct.semanticSauce.orderAt46Latch, authoritative.orderAtDrop46);
  ok(direct.ghost.bowls[2] !== direct.semanticSauce.bowls[2]);

  const manager = new production.BaseMonsterManager();
  const gates = {
    10: f + 10n, 16: f + 1010n,
    20: f + 20n, 26: f + 1020n,
    30: f + 30n, 36: f + 1030n
  };
  const pairs = [
    { openIndex: 30, closeIndex: 36 },
    { openIndex: 10, closeIndex: 16 },
    { openIndex: 20, closeIndex: 26 }
  ];
  const stream = { first: 1n, directionStep: 1n };
  const noWalk = {
    nextYear() { throw new Error('Null next-year expectat in Patch 20.'); },
    previousYear() { throw new Error('Null previous-year expectat in Patch 20.'); }
  };
  const routed = manager.executePatch20StructureSauce(
    calculationDay, originalTargetDay, -1n, gates, pairs, stream, noWalk
  );
  eq(routed.context.status, 'PATCH_20_RESULT');
  eq(routed.context.previousHandler, 'YearCacheActionGuardPatchWrapper');
  ok(routed.context.patch20GhostExecuted);
  ok(routed.context.patch20GhostIgnoredForSelector);
  ok(routed.context.patch20SelectorUsedYearFirstDaySauce);
  eq(routed.result.ghostTargetDay, originalTargetDay);
  eq(routed.result.semanticTargetDay, yearFirstDay);
  eq(routed.result.ghostSauce.bowls[2], oldExpected.bowls[1]);
  eq(routed.result.selectorToken.bowl2, authoritative.bowls[1]);
  deepEq(routed.result.selectorToken.orderAt46Latch, authoritative.orderAtDrop46);
  eq(routed.context.metrics['patch20.oldStructureSauce.ghost.calls'], 1n);
  eq(routed.context.metrics['patch20.semanticSelector.calls'], 1n);
  ok(routed.context.metrics['discovery20.legacySelector.calls'] === undefined);
  ok(!wrapperSource.includes('legacyPositiveCompositions'));
});

group('Discovery 21 selecte ex omni positive compositions e ignora li gate intern del calculation-day', () => {
  const familySource = production.legacyPositiveCompositions.toString();
  ok(familySource.includes('positiveCompositionCountExact'));
  ok(!/internalGate|internal_gate|prefix|boundary|required/.test(familySource));
  const small = production.legacyPositiveCompositions(5, 3);
  eq(small.count(), 6n);
  deepEq([1n,2n,3n,4n,5n,6n].map((rank) => small.unrank1(rank)), [
    [1,1,3],[1,2,2],[1,3,1],[2,1,2],[2,2,1],[3,1,1]
  ]);

  const f = o.FOUNDATION_DAY;
  const calculationDay = f + 100n;
  const gates = {
    10: f + 10n, 14: calculationDay, 20: f + 1010n,
    30: f + 20n, 40: f + 1020n, 50: f + 30n, 60: f + 1030n
  };
  const pairs = [
    { openIndex: 50, closeIndex: 60 },
    { openIndex: 10, closeIndex: 20 },
    { openIndex: 30, closeIndex: 40 }
  ];
  const stream = { first: 1n, directionStep: 1n };
  const noWalk = {
    nextYear() { throw new Error('Null next-year expectat in Discovery 21.'); },
    previousYear() { throw new Error('Null previous-year expectat in Discovery 21.'); }
  };
  const routed = new production.BaseMonsterManager().executeDiscovery21CutletPartition(
    calculationDay, calculationDay, -1n, gates, pairs, stream, noWalk
  );
  eq(routed.context.status, 'DISCOVERY_21_LEGACY_RESULT');
  eq(routed.context.previousHandler, 'StructureSaucePatchWrapper');
  eq(routed.context.legacyCutletGapCount, 10);
  deepEq(routed.context.legacyCutletCountCandidates, [6,7,8,9,10]);
  eq(routed.context.legacyCutletCount, 8);
  eq(routed.context.legacyCutletInternalGateIndex, 14);
  eq(routed.context.legacyCutletInternalGateOffset, 4);
  eq(routed.context.legacyCutletFamilyCount, 36n);
  eq(routed.context.legacyCutletSelectedRank, 15n);
  deepEq(routed.result.partition, [1,1,1,3,1,1,1,1]);
  deepEq(routed.result.prefixSums, [1,2,3,6,7,8,9,10]);
  ok(!routed.result.internalBoundaryHit);
  ok(routed.context.legacyCutletIgnoredInternalGate);
  eq(routed.context.metrics['discovery21.internalGateIgnored.calls'], 1n);

  const authoritativeSauce = o.sauce(calculationDay, f + 11n);
  const filtered = o.makeCutletPartitionFamily(10, 8, 4);
  const expectedRank = o.chooseRank(o.askBowl(authoritativeSauce, 2, 21n), filtered.count());
  const expected = filtered.unrank1(expectedRank);
  eq(filtered.count(), 28n);
  eq(expectedRank, 3n);
  deepEq(expected, [1,1,1,1,1,1,3,1]);
  ok(JSON.stringify(expected) !== JSON.stringify(routed.result.partition));
  ok(!('CutletPartitionPatchWrapper' in production));
  ok(!('legacyNameRowWithRepeats' in production));
});

group('errores de base es explicit e li final function resta absent durant Discovery 21', () => {
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

console.log('\n' + groupsPassed + ' gruppes regressiv passat; ' + assertions + ' assertions passa durant Discovery 21.');
