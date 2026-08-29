'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const production = require('../src');
const reference = require('./normative-reference');

const F = production.FOUNDATION_DAY_OLD;
const M = production.M_OLD;
let auditChecks = 0;

function audit(label, fn) {
  fn();
  auditChecks += 1;
  console.log('AUDIT PASS — ' + label);
}

function sameArray(left, right, label) {
  assert.deepEqual(left, right, label);
}

function binomial(n, k, memo) {
  if (!Number.isInteger(n) || !Number.isInteger(k) || k < 0 || k > n) return 0n;
  let q = Math.min(k, n - k);
  const key = n + ':' + q;
  if (memo.has(key)) return memo.get(key);
  let value = 1n;
  for (let j = 1; j <= q; j += 1) value = value * BigInt(n - q + j) / BigInt(j);
  memo.set(key, value);
  return value;
}

class FastAuditBoundedComposition {
  constructor(total, slots, lo = 4, hi = 123) {
    this.total = total; this.slots = slots; this.lo = lo; this.hi = hi;
    this.dp = Array.from({ length: slots + 1 }, () => Array(total + 1).fill(0n));
    this.dp[0][0] = 1n;
    for (let k = 1; k <= slots; k += 1) {
      let window = 0n;
      for (let sum = 0; sum <= total; sum += 1) {
        const add = sum - lo;
        const remove = sum - hi - 1;
        if (add >= 0) window += this.dp[k - 1][add];
        if (remove >= 0) window -= this.dp[k - 1][remove];
        this.dp[k][sum] = window;
      }
    }
  }
  count() { return this.dp[this.slots][this.total]; }
  unrank1(rank1) {
    if (rank1 < 1n || rank1 > this.count()) throw new RangeError('Li rank fast-audit de composition es extra li familie.');
    let rank = rank1, remaining = this.total; const out = [];
    for (let position = 0; position < this.slots; position += 1) {
      const slotsAfter = this.slots - position - 1;
      let selected = false;
      for (let value = this.lo; value <= this.hi; value += 1) {
        const next = remaining - value;
        const block = next >= 0 && next <= this.total ? this.dp[slotsAfter][next] : 0n;
        if (rank > block) rank -= block;
        else { out.push(value); remaining = next; selected = true; break; }
      }
      if (!selected) throw new Error('Li fast-audit ne trova un composition lexicografic.');
    }
    return out;
  }
}

class FastAuditWeaving {
  constructor(lengths) {
    this.lengths = lengths.slice();
    this.monthCount = lengths.length;
    this.totalDays = lengths.reduce((sum, value) => sum + value, 0);
    this.binomialMemo = new Map();
    this.future = this._buildFuture();
  }

  _buildFuture() {
    const table = Array.from({ length: this.monthCount + 1 }, () => Array(this.totalDays + 1).fill(0n));
    for (let x = 0; x <= this.totalDays; x += 1) table[this.monthCount][x] = 1n;
    for (let opened = this.monthCount - 1; opened >= 1; opened -= 1) {
      const quantity = this.lengths[opened];
      const current = table[opened];
      const next = table[opened + 1];
      if (quantity === 1) {
        for (let x = 0; x <= this.totalDays; x += 1) current[x] = next[0];
        continue;
      }
      let prefix = 0n;
      for (let x = 0; x <= this.totalDays; x += 1) {
        const y = x + quantity - 1;
        if (y <= this.totalDays) prefix += binomial(y - 1, quantity - 2, this.binomialMemo) * next[y];
        current[x] = prefix;
      }
    }
    return table;
  }

  _legal(remaining, openedUpTo, closedUpTo, monthId) {
    if (remaining[monthId - 1] === 0) return false;
    const alreadyOpened = remaining[monthId - 1] < this.lengths[monthId - 1];
    if (!alreadyOpened && monthId !== openedUpTo + 1) return false;
    if (remaining[monthId - 1] === 1 && monthId !== closedUpTo + 1) return false;
    return true;
  }

  _move(remaining, openedUpTo, closedUpTo, monthId) {
    const next = remaining.slice();
    let opened = openedUpTo;
    let closed = closedUpTo;
    if (next[monthId - 1] === this.lengths[monthId - 1]) opened = monthId;
    next[monthId - 1] -= 1;
    if (next[monthId - 1] === 0) closed = monthId;
    return { remaining: next, openedUpTo: opened, closedUpTo: closed };
  }

  _activeWays(remaining, openedUpTo, closedUpTo) {
    let firstActive = -1;
    for (let monthId = closedUpTo + 1; monthId <= openedUpTo; monthId += 1) {
      if (remaining[monthId - 1] > 0) {
        firstActive = monthId;
        break;
      }
    }
    if (firstActive < 0) return 1n;
    let prefix = remaining[firstActive - 1];
    let ways = 1n;
    for (let monthId = firstActive + 1; monthId <= openedUpTo; monthId += 1) {
      const quantity = remaining[monthId - 1];
      ways *= binomial(prefix + quantity - 1, quantity - 1, this.binomialMemo);
      prefix += quantity;
    }
    return ways;
  }

  _countState(remaining, openedUpTo, closedUpTo) {
    let activeDays = 0;
    for (let monthId = closedUpTo + 1; monthId <= openedUpTo; monthId += 1) activeDays += remaining[monthId - 1];
    return this._activeWays(remaining, openedUpTo, closedUpTo) * this.future[openedUpTo][activeDays];
  }

  count() {
    const first = this._move(this.lengths.slice(), 0, 0, 1);
    return this._countState(first.remaining, first.openedUpTo, first.closedUpTo);
  }

  unrank1(rank1) {
    const total = this.count();
    if (rank1 < 1n || rank1 > total) throw new RangeError('Li rank fast-audit del intertexe es extra li familie.');
    let rank = rank1;
    let remaining = this.lengths.slice();
    let openedUpTo = 0;
    let closedUpTo = 0;
    const out = [];
    while (out.length < this.totalDays) {
      let selected = false;
      for (let monthId = 1; monthId <= this.monthCount; monthId += 1) {
        if (!this._legal(remaining, openedUpTo, closedUpTo, monthId)) continue;
        const next = this._move(remaining, openedUpTo, closedUpTo, monthId);
        const block = this._countState(next.remaining, next.openedUpTo, next.closedUpTo);
        if (rank > block) rank -= block;
        else {
          out.push(monthId);
          remaining = next.remaining;
          openedUpTo = next.openedUpTo;
          closedUpTo = next.closedUpTo;
          selected = true;
          break;
        }
      }
      if (!selected) throw new Error('Li fast-audit ne trova un move legal de intertexe.');
    }
    return out;
  }
}

class FastAuditOracle {
  constructor() {
    this.engine = reference.createGateEngine();
    this.structureCache = new Map();
  }

  _structureKey(calculationDay, year) {
    return calculationDay.toString() + ':' + year.number.toString() + ':' + year.openGateDay.toString();
  }

  structure(calculationDay, year) {
    const key = this._structureKey(calculationDay, year);
    if (this.structureCache.has(key)) return this.structureCache.get(key);
    const structureSauce = reference.sauce(calculationDay, year.openGateDay + 1n);
    const cutletCount = reference.chooseCutletCount(structureSauce, year);
    const cutletPartition = reference.chooseCutletPartition(calculationDay, structureSauce, year, cutletCount, this.engine);
    const cutletNameIndices = reference.chooseCutletNames(structureSauce, cutletCount);
    const cutlets = reference.materializeCutlets(year, cutletPartition, cutletNameIndices, this.engine);
    const monthCount = reference.chooseMonthCount(structureSauce, year);
    const monthLengthFamily = new FastAuditBoundedComposition(Number(year.closeGateDay - year.openGateDay), monthCount);
    const monthLengthRank = reference.chooseRank(reference.askBowl(structureSauce, 3, 31n), monthLengthFamily.count());
    const monthLengths = monthLengthFamily.unrank1(monthLengthRank);
    const weavingFamily = new FastAuditWeaving(monthLengths);
    const weavingRank = reference.chooseRank(reference.askBowl(structureSauce, 4, 32n), weavingFamily.count());
    const monthWeaving = weavingFamily.unrank1(weavingRank);
    const monthNameIndices = reference.chooseMonthNames(structureSauce, monthCount);
    const structure = Object.freeze({
      structureSauce, cutletCount, cutletPartition, cutletNameIndices, cutlets,
      monthCount, monthLengths, weavingFamily, weavingRank, monthWeaving, monthNameIndices
    });
    this.structureCache.set(key, structure);
    return structure;
  }

  calendarDate(calculationDay, targetDay) {
    const year = reference.findTargetYear(calculationDay, targetDay, this.engine);
    const structure = this.structure(calculationDay, year);
    const cutlet = structure.cutlets.find((row) => row.firstDay <= targetDay && targetDay <= row.lastDay);
    assert.ok(cutlet, 'Li reference audit deve trovar un cutlet por li target-day.');
    const dayInCutlet = targetDay - cutlet.firstDay + 1n;
    const offset = Number(targetDay - (year.openGateDay + 1n));
    const monthId = structure.monthWeaving[offset];
    const monthNameIndex = structure.monthNameIndices[monthId - 1];
    let dayInMonth = 0n;
    for (let index = 0; index <= offset; index += 1) if (structure.monthWeaving[index] === monthId) dayInMonth += 1n;
    return Object.freeze({
      result: Object.freeze([
        year.number,
        reference.SourceLanguageCatalog.cutlets[cutlet.nameIndex - 1].text,
        dayInCutlet,
        reference.SourceLanguageCatalog.months[monthNameIndex - 1].text,
        dayInMonth
      ]),
      year,
      structure
    });
  }
}

const auditOracle = new FastAuditOracle();

// Un audit direct del backend fast contra li reference recursive sur families micri impede que li optimisation de test deven un oracle inventet.
audit('composition bounded fast independent concorda con li reference direct', () => {
  for (const [total, slots] of [[8, 2], [20, 4], [100, 5], [127, 2]]) {
    const direct = reference.makeBoundedCompositionCounter(total, slots, 4, 123);
    const fast = new FastAuditBoundedComposition(total, slots);
    assert.equal(fast.count(), direct.countAll());
    const count = fast.count();
    if (count > 0n) {
      for (const rank of new Set([1n, count, (count + 1n) / 2n])) sameArray(fast.unrank1(rank), direct.unrank1(rank));
    }
  }
});

audit('intertexe fast independent concorda con li reference recursive', () => {
  for (const lengths of [[1], [2], [2, 2], [3, 2], [2, 3, 2], [4, 4, 4]]) {
    const direct = reference.makeMonthWeavingFamily(lengths);
    const fast = new FastAuditWeaving(lengths);
    assert.equal(fast.count(), direct.count());
    const total = direct.count();
    const ranks = new Set([1n, total, total > 2n ? (total + 1n) / 2n : 1n]);
    for (const rank of ranks) sameArray(fast.unrank1(rank), direct.unrank1(rank), 'Ordre lexicografic fast/direct diverge.');
  }
});

audit('SAVE e modulo exact', () => {
  for (const value of [1n, M - 1n, M, M + 1n, 2n * M, -1n, -M, -M - 1n]) {
    assert.equal(production.savePatch(value), reference.SAVE(value));
    assert.equal(production.regularMod(value, M), reference.regularMod(value, M));
  }
});

audit('day tag e distance inclusiv concorda con Appendix A', () => {
  for (const day of [F - 2n, F - 1n, F, F + 1n, F + 2n]) {
    assert.equal(production.dayTagWithFoundationScar(day), reference.dayCount(day));
  }
  for (const [c, t] of [[F, F], [F - 2n, F + 3n], [F + 7n, F - 5n]]) {
    assert.equal(production.distanceWithChronologyDetour(c, t), reference.workCounts(c, t).distance);
  }
});

audit('permutation ranks 1 e 720 es exact', () => {
  sameArray(production.orderPatchFromValue(1n), reference.bowlOrderFromNumber(1n));
  sameArray(production.orderPatchFromValue(720n), reference.bowlOrderFromNumber(720n));
  sameArray(production.orderPatchFromValue(721n), reference.bowlOrderFromNumber(1n));
});

audit('selection curt, rejection e wide concorda con reference', () => {
  const shortCases = [
    [{ first: 1n, directionStep: 1n }, 1n],
    [{ first: M, directionStep: -1n }, M],
    [{ first: M, directionStep: -1n }, 10n],
    [{ first: M - 2n, directionStep: 1n }, 13n]
  ];
  for (const [stream, n] of shortCases) {
    assert.equal(production.selectionDispatcherWithWideDetour(stream, n).output, reference.chooseRank(stream, n));
  }
  for (const n of [M + 1n, M * M, M * M + 1n]) {
    const stream = { first: 17n, directionStep: -1n };
    const actual = production.selectionDispatcherWithWideDetour(stream, n);
    assert.equal(actual.output, reference.chooseRank(stream, n));
    assert.equal(actual.digitReadCount, actual.places);
  }
});

audit('sauce final concorda con sauce reference e latch order', () => {
  for (const [c, t] of [[F, F], [F + 17n, F - 9n], [F - 31n, F + 23n]]) {
    const expected = reference.sauce(c, t);
    const actual = production.sauceWithScars(c, t);
    sameArray(actual.bowls.slice(1), expected.bowls);
    sameArray(actual.orderAt46Latch, expected.orderAtDrop46);
    assert.equal(actual.orderAt46LatchWriteCount, 1);
  }
});

audit('answer streams, successor circular e directions du-paritá', () => {
  const sauceExpected = reference.sauce(F, F);
  const sauceActual = production.sauceWithScars(F, F);
  let oddSeen = false;
  let evenSeen = false;
  for (let seal = 1n; seal <= 64n; seal += 1n) {
    for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
      const nextId = production.nextBowlFromOrderAt46Latch(sauceActual.orderAt46Latch, bowlId);
      const actual = production.answerRingFromCurrentState(sauceActual.bowls, bowlId, nextId, seal);
      const expected = reference.askBowl(sauceExpected, bowlId, seal);
      assert.equal(actual.first, expected.first);
      assert.equal(actual.directionStep, expected.directionStep);
      if (actual.directionStep === 1n) oddSeen = true;
      if (actual.directionStep === -1n) evenSeen = true;
    }
  }
  assert.equal(oddSeen, true);
  assert.equal(evenSeen, true);
  const last = sauceActual.orderAt46Latch[5];
  assert.equal(production.nextBowlFromOrderAt46Latch(sauceActual.orderAt46Latch, last), sauceActual.orderAt46Latch[0]);
});

audit('gate questions ±1/±2 e null forced symmetry', () => {
  assert.equal(production.gateQuestionWithSignedStep(1n), F + 1n);
  assert.equal(production.gateQuestionWithSignedStep(-1n), F - 1n);
  assert.equal(production.gateQuestionWithSignedStep(2n), F + 2n);
  assert.equal(production.gateQuestionWithSignedStep(-2n), F - 2n);
  const registry = new production.Stage54GateRegistry();
  for (const index of [-2n, -1n, 0n, 1n, 2n]) assert.equal(registry.ensureIndex(index), auditOracle.engine.ensureGateIndex(index));
  const positiveGap = registry.ensureIndex(1n) - registry.ensureIndex(0n);
  const negativeGap = registry.ensureIndex(0n) - registry.ensureIndex(-1n);
  assert.notEqual(positiveGap, negativeGap);
});

audit('year ceiling legacy 5781 e filter tardiv 5778', () => {
  for (const length of [252n, 5778n, 5779n, 5780n, 5781n]) {
    const gates = { 0: 0n, 6: length };
    const legacy = production.legacyYearCandidateAllowed(gates, 0, 6);
    const semantic = production.yearCandidateAfterFootnotePatch(gates, 0, 6);
    assert.equal(legacy, length >= 252n && length <= 5781n);
    assert.equal(semantic, length >= 252n && length <= 5778n);
  }
});

audit('sequential year walk couvre 5001, 5000, 4999, 1, 0 e -1', () => {
  function year(number) {
    const openDay = (number - 5000n) * 10n;
    return { number, openDay, firstDay: openDay + 1n, closeDay: openDay + 10n };
  }
  const next = (current) => year(current.number + 1n);
  const previous = (current) => year(current.number - 1n);
  for (const number of [5001n, 5000n, 4999n, 1n, 0n, -1n]) {
    const target = year(number).openDay + 1n;
    const resolved = production.findYearByWalkPatch(year(5000n), target, next, previous);
    assert.equal(resolved.year.number, number);
  }
});

audit('membership annual exact (open,close] al opening/first/internal/closing', () => {
  function year(number) { const openDay = number * 10n; return { number, openDay, firstDay: openDay + 1n, closeDay: openDay + 10n }; }
  const next = (current) => year(current.number + 1n);
  const previous = (current) => year(current.number - 1n);
  assert.equal(production.correctOpeningGateInterval(year(0n), 0n, next, previous).year.number, -1n);
  assert.equal(production.correctOpeningGateInterval(year(0n), 1n, next, previous).year.number, 0n);
  assert.equal(production.correctOpeningGateInterval(year(0n), 5n, next, previous).year.number, 0n);
  assert.equal(production.correctOpeningGateInterval(year(0n), 10n, next, previous).year.number, 0n);
});

audit('cutlet filtered family conserva exactmen li subsequence lexicografic', () => {
  const expected = reference.makeCutletPartitionFamily(10, 8, 4);
  const actual = production.filteredCutletCompositions(10, 8, 4);
  assert.equal(actual.count(), expected.count());
  assert.equal(actual.count(), 28n);
  for (let rank = 1n; rank <= actual.count(); rank += 1n) sameArray(actual.unrank1(rank), expected.unrank1(rank));
  const unfiltered = production.legacyPositiveCompositions(10, 8);
  assert.equal(unfiltered.count(), 36n);
});

audit('partial permutations distinct de cutlet e mensu conserva rank canonical', () => {
  for (const [n, k] of [[17, 6], [17, 17], [47, 3], [47, 47]]) {
    const total = reference.fallingFactorial(n, k);
    const ranks = [1n, total, total > 3n ? (total + 1n) / 2n : 1n];
    for (const rank of ranks) sameArray(production.partialPermutationUnrank(n, k, rank), reference.unrankDistinctIndices(n, k, rank));
  }
});

audit('VirtualLegacyList count/unrank e limites 4/123 es exact', () => {
  for (const [total, slots] of [[8, 2], [127, 2], [20, 4], [100, 5]]) {
    const expected = reference.makeBoundedCompositionCounter(total, slots, 4, 123);
    const actual = new production.VirtualLegacyList(total, slots);
    assert.equal(actual.count(), expected.countAll());
    const count = actual.count();
    if (count > 0n) {
      const ranks = new Set([1n, count, (count + 1n) / 2n]);
      for (const rank of ranks) sameArray(actual.itemAt1(rank), expected.unrank1(rank));
    }
  }
  sameArray(new production.VirtualLegacyList(127, 2).itemAt1(1n), [4, 123]);
});

audit('LegalMonthWeavingDP es exact sur intertexes micri e pesant', () => {
  for (const lengths of [[2, 2], [3, 2], [4, 4, 4]]) {
    const expected = reference.makeMonthWeavingFamily(lengths);
    const actual = new production.LegalMonthWeavingDP(lengths);
    assert.equal(actual.count(), expected.count());
    const ranks = new Set([1n, actual.count(), (actual.count() + 1n) / 2n]);
    for (const rank of ranks) sameArray(actual.unrank1(rank), expected.unrank1(rank));
  }
});

audit('day-in-month es occurrence count inclusiv con occurrences separat', () => {
  const weaving = [1, 2, 1, 3, 1, 2, 1, 3];
  assert.equal(production.oldContiguousMonthDayGuess(weaving, 7), 7);
  assert.equal(production.countMonthOccurrencesThroughTarget(weaving, 7), 4);
});

audit('catalog congelat e canonicalIndex complet', () => {
  assert.equal(production.SourceLanguageCatalog.version, '1.0.0-stage-01');
  assert.equal(Object.isFrozen(production.SourceLanguageCatalog), true);
  assert.equal(Object.isFrozen(production.SourceLanguageCatalog.cutlets), true);
  assert.equal(Object.isFrozen(production.SourceLanguageCatalog.months), true);
  sameArray(production.SourceLanguageCatalog.cutlets.map((row) => row.canonicalIndex), Array.from({ length: 17 }, (_, i) => i + 1));
  sameArray(production.SourceLanguageCatalog.months.map((row) => row.canonicalIndex), Array.from({ length: 47 }, (_, i) => i + 1));
  sameArray(production.SourceLanguageCatalog.cutlets, reference.SourceLanguageCatalog.cutlets);
  sameArray(production.SourceLanguageCatalog.months, reference.SourceLanguageCatalog.months);
});

audit('ordre semantic de nomes ne depende del collation del textu', () => {
  const canonical = production.SourceLanguageCatalog.months.map((row) => row.text);
  const lexical = canonical.slice().sort((a, b) => a < b ? -1 : a > b ? 1 : 0);
  assert.notDeepEqual(lexical, canonical);
  sameArray(production.SourceLanguageCatalog.months.map((row) => row.canonicalIndex), Array.from({ length: 47 }, (_, i) => i + 1));
});

audit('26 scars historic e 26 patches resta fisicmen present', () => {
  const scars = [
    'oldRemainder', 'oldDayTag', 'oldDistance', 'mutateStonesWrong', 'buildHiddenWithBackwardStorage', 'legacyPrior',
    'legacyGrindRow', 'oldPermutationUnrank0', 'legacyPoursToFixedBowlIds', 'legacyStirOneDropInPlace',
    'legacySauceWithOverwritableOrderMemory', 'oldNextBowlFixedName', 'biasedLegacyPick', 'legacySelectionAssumingNLeM',
    'oldGateQuestionDay', 'legacyYearCandidateAllowed', 'legacyStableLengthOnlyYearCandidates', 'oldJumpGuess',
    'legacyYearNumberOnlyLookup', 'oldStructureSauce', 'legacyPositiveCompositions', 'legacyNameRowWithRepeats',
    'legacyMaterializeMonthLengthWays', 'legacyChooseEachDaySeparately', 'oldContiguousMonthDayGuess',
    'legacyFindYearClosedOpeningInterval'
  ];
  const patches = [
    'savePatch', 'dayTagWithFoundationScar', 'distanceWithChronologyDetour', 'stonePatch', 'hiddenByNearness', 'priorPatch',
    'grindRowWithSentinel', 'orderPatchFromValue', 'poursThroughBowlAlias', 'stirOneDropViaShadow', 'sauceWithOrderAt46Latch',
    'nextBowlFromOrderAt46Latch', 'patchedSmallPick', 'wideDetour', 'gateQuestionWithSignedStep', 'yearCandidateAfterFootnotePatch',
    'sortEqualLengthRunsByOpeningGate', 'findYearByWalkPatch', 'cacheGetWithActionGuard', 'structureSaucePatch',
    'filteredCutletCompositions', 'partialPermutationUnrank', 'VirtualLegacyList', 'LegalMonthWeavingDP',
    'countMonthOccurrencesThroughTarget', 'correctOpeningGateInterval'
  ];
  assert.equal(scars.length, 26);
  assert.equal(patches.length, 26);
  for (const name of scars.concat(patches)) assert.notEqual(typeof production[name], 'undefined', 'Manca layer fisic: ' + name);
});

audit('production ne importa ni fallback al oracle e ne usa fontes nondeterministic', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'src', 'index.js'), 'utf8');
  assert.equal(source.includes("require('../tests/normative-reference')"), false);
  assert.equal(/Math\.random|Date\.now|new Date\s*\(|process\.env|performance\.now|SharedArrayBuffer|Atomics\./.test(source), false);
  assert.equal(/if\s*\([^\n]*oracle[^\n]*\)[^\n]*return/i.test(source), false);
});

audit('prose canonic ne contene script hebreic e declara Interlingue quam fonte unic', () => {
  for (const file of ['README.md', 'SPAGHETTI_DEVELOPMENT_HISTORY.md', 'DEVELOPMENT_STAGE.md', 'src/index.js', 'src/source-language-catalog.js']) {
    const text = fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
    assert.equal(/[\u0590-\u05FF]/u.test(text), false, 'Textu hebreic trovat in ' + file);
  }
  const stage = fs.readFileSync(path.join(__dirname, '..', 'DEVELOPMENT_STAGE.md'), 'utf8');
  assert.match(stage, /NATURAL_LANGUAGE=Interlingue \/ Occidental/);
});


const foundationActual = production.calendarDateSpaghettiWithContext(F, F);
assert.equal(foundationActual.result.length, 5);

audit('cache cold/warm e calculationDay guards resta semanticmen neutri', () => {
  const first = production.calendarDateSpaghettiWithContext(F, F);
  const second = production.calendarDateSpaghettiWithContext(F, F);
  sameArray(first.result, second.result);
  const warmProbe = second.context.diagnostics.find((row) => row && row.label === 'pre-structure-cache-probe');
  assert.ok(warmProbe); assert.equal(warmProbe.hit, true);
  const guardedSame = production.cacheGetWithActionGuard(production.STAGE54_GLOBAL_MANAGER.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER, first.context.currentYear, F);
  const guardedOtherCalculation = production.cacheGetWithActionGuard(production.STAGE54_GLOBAL_MANAGER.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER, first.context.currentYear, F + 1n);
  assert.equal(guardedSame.hit, true);
  assert.equal(guardedOtherCalculation.hit, false);
  assert.equal(guardedOtherCalculation.reason, 'calculation-day');
});

audit('logs e metrics ne influe li output', () => {
  const manager = production.STAGE54_GLOBAL_MANAGER;
  const original = manager.prepareFinal;
  manager.prepareFinal = function (calculationDay, targetDay) {
    const context = original.call(this, calculationDay, targetDay);
    context.logs.push(Object.freeze({ event: 'AUDIT55_OBSERVATION' }));
    context.metrics['audit55.prepopulated'] = 987654321;
    return context;
  };
  try {
    sameArray(manager.executeCalendarDate(F, F).result, foundationActual.result);
  } finally {
    manager.prepareFinal = original;
  }
});

audit('retry 0/1/2 resta deterministic e exhaustion jetta explicitmen', () => {
  const manager = production.STAGE54_GLOBAL_MANAGER;
  const original = manager.validationManager.requireDiscreteDay;
  function runWithFailures(failures) {
    let remaining = failures;
    let calls = 0;
    manager.validationManager.requireDiscreteDay = function (value) {
      calls += 1;
      if (calls > 2 && remaining > 0) {
        remaining -= 1;
        const error = new Error('AUDIT55_RECOVERABLE');
        error.recoverableStage54 = true;
        throw error;
      }
      return original.call(this, value);
    };
    try {
      return manager.executeCalendarDate(F, F);
    } finally {
      manager.validationManager.requireDiscreteDay = original;
    }
  }
  for (const failures of [0, 1, 2]) sameArray(runWithFailures(failures).result, foundationActual.result);

  let captured = null;
  const originalPrepare = manager.prepareFinal;
  manager.prepareFinal = function (calculationDay, targetDay) {
    captured = originalPrepare.call(this, calculationDay, targetDay);
    return captured;
  };
  let exhaustionCalls = 0;
  manager.validationManager.requireDiscreteDay = function (value) {
    exhaustionCalls += 1;
    if (exhaustionCalls <= 2) return original.call(this, value);
    const error = new Error('AUDIT55_EXHAUSTION');
    error.recoverableStage54 = true;
    throw error;
  };
  const cacheSizeBefore = manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size;
  try {
    assert.throws(() => manager.executeCalendarDate(F, F), /AUDIT55_EXHAUSTION/);
    assert.ok(captured);
    assert.equal(captured.status, 'FAILED');
    assert.equal(captured.pendingSnapshot, null);
    assert.equal(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, cacheSizeBefore);
  } finally {
    manager.prepareFinal = originalPrepare;
    manager.validationManager.requireDiscreteDay = original;
  }
});

audit('du instances e calls repetit resta history-independent', () => {
  production.calendarDateSpaghettiWithContext(F, F);
  const validatedCache = new Map(production.STAGE54_GLOBAL_MANAGER.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER);
  const left = new production.Stage54MonsterIntegrationManager(production.STAGE54_GLOBAL_GATE_REGISTRY);
  const right = new production.Stage54MonsterIntegrationManager(production.STAGE54_GLOBAL_GATE_REGISTRY);
  left.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER = new Map(validatedCache);
  right.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER = new Map(validatedCache);
  const a1 = left.executeCalendarDate(F, F).result;
  const b1 = right.executeCalendarDate(F, F).result;
  const a2 = left.executeCalendarDate(F, F).result;
  sameArray(a1, b1);
  sameArray(a1, a2);
  sameArray(a1, foundationActual.result);
});

audit('ordre insertion del registry ne cambia gates', () => {
  const left = new production.Stage54GateRegistry();
  const right = new production.Stage54GateRegistry();
  left.ensureIndex(4n); left.ensureIndex(-4n);
  right.ensureIndex(-4n); right.ensureIndex(4n);
  for (let index = -4n; index <= 4n; index += 1n) assert.equal(left.ensureIndex(index), right.ensureIndex(index));
});

audit('compatibility flags authoritative es fix e deterministic', () => {
  const manager = new production.Stage54MonsterIntegrationManager(production.STAGE54_GLOBAL_GATE_REGISTRY);
  const a = manager.prepareFinal(F, F).compatibilityFlags;
  const b = manager.prepareFinal(F, F).compatibilityFlags;
  assert.deepEqual(a, b);
  assert.equal(Object.isFrozen(a), true);
  for (const value of Object.values(a)) assert.equal(value, true);
});

audit('semantic ownership, commits e observabilitá resta separat', () => {
  const context = production.calendarDateSpaghettiWithContext(F, F).context;
  assert.equal(context.status, 'SUCCESS');
  assert.equal(context.pendingSnapshot, null);
  assert.equal(context.commitToken, 'STAGE54_RESULT_VALIDATED');
  assert.ok(Array.isArray(context.logs));
  assert.ok(context.metrics && typeof context.metrics === 'object');
  assert.ok(Array.isArray(context.diagnostics));
  assert.equal(context.resultFive.length, 5);
});


console.log('STAGE 55 CORE AUDIT PASS — ' + auditChecks + ' gruppes de helpers, scars e fiabilitá.');
