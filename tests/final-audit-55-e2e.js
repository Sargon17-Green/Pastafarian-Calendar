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

if (require.main === module) {
  audit('composition bounded fast concorda con li reference direct', () => {
    for (const [total, slots] of [[8, 2], [20, 4], [100, 5], [127, 2]]) {
      const direct = reference.makeBoundedCompositionCounter(total, slots, 4, 123);
      const fast = new FastAuditBoundedComposition(total, slots);
      assert.equal(fast.count(), direct.countAll());
      if (fast.count() > 0n) for (const rank of new Set([1n, fast.count(), (fast.count() + 1n) / 2n])) sameArray(fast.unrank1(rank), direct.unrank1(rank));
    }
  });

  audit('intertexe fast concorda con li reference recursive', () => {
    for (const lengths of [[1], [2, 2], [3, 2], [4, 4, 4]]) {
      const direct = reference.makeMonthWeavingFamily(lengths);
      const fast = new FastAuditWeaving(lengths);
      assert.equal(fast.count(), direct.count());
      for (const rank of new Set([1n, direct.count(), (direct.count() + 1n) / 2n])) sameArray(fast.unrank1(rank), direct.unrank1(rank));
    }
  });

  let foundationExpected = null;
  let foundationActual = null;
  for (const [c, t, label] of [[F, F, 'Foundation'], [F, F - 1n, 'ante Foundation'], [F, F + 1n, 'pos Foundation']]) {
    audit('differential end-to-end — ' + label, () => {
      const expected = auditOracle.calendarDate(c, t);
      const actual = production.calendarDateSpaghettiStage55HistoricalWithContext(c, t);
      sameArray(actual.result, expected.result, 'Divergentie end-to-end: ' + label);
      assert.equal(actual.result.length, 5);
      if (label === 'Foundation') { foundationExpected = expected; foundationActual = actual; }
    });
  }

  audit('structure Foundation complet concorda con reference independent', () => {
    const e = foundationExpected.structure; const a = foundationActual.context.structure;
    assert.equal(a.cutletCount, e.cutletCount); assert.equal(a.monthCount, e.monthCount);
    sameArray(a.cutletPartition, e.cutletPartition); sameArray(a.cutletNameIndices, e.cutletNameIndices);
    sameArray(a.monthLengths, e.monthLengths); sameArray(a.monthWeaving, e.monthWeaving); sameArray(a.monthNameIndices, e.monthNameIndices);
    assert.ok(e.weavingFamily.count() > M);
  });

  console.log('STAGE 55 E2E BASE AUDIT PASS — ' + auditChecks + ' gruppes differential independent.');
}

module.exports = Object.freeze({ FastAuditBoundedComposition, FastAuditWeaving, FastAuditOracle });
