'use strict';

class FakeBoundedScar {
  constructor(limit, label) {
    this.limit = limit;
    this.label = label;
    this.map = new Map();
  }
  get(key) {
    if (!this.map.has(key)) return null;
    const value = this.map.get(key);
    this.map.delete(key);
    this.map.set(key, value);
    return value;
  }
  set(key, value) {
    if (this.map.has(key)) this.map.delete(key);
    this.map.set(key, value);
    while (this.map.size > this.limit) this.map.delete(this.map.keys().next().value);
    return value;
  }
}

class FakeWeakScar extends FakeBoundedScar {}

const selectionMemory = new FakeBoundedScar(4096, 'INTEGRATED_SELECTION_REJECTION');
const sauceMemory = new FakeWeakScar(128, 'SAUCE_STAGE56_WEAK');

const gateDays = new FakeBoundedScar(4096, 'SHARED_GATE_DAYS');
const gateGaps = new FakeBoundedScar(4096, 'SHARED_GATE_GAPS');
const year5000 = new FakeBoundedScar(64, 'YEAR5000_BY_CALCULATION_DAY');
const transitions = new FakeBoundedScar(1024, 'ADJACENT_YEAR_TRANSITIONS');
const histories = new FakeBoundedScar(16, 'AUTHORITATIVE_YEAR_HISTORIES');
const structures = new FakeBoundedScar(32, 'SEMANTIC_STRUCTURE_BY_FULL_FINGERPRINT');

const STAGE57_GLOBAL_GATE_REGISTRY = {
  stage58GateMemoryScar: { gates: gateDays, gaps: gateGaps },
};
const STAGE57_GLOBAL_MANAGER = {
  stage58YearMemoryScar: {
    year5000ByCalculationDay: year5000,
    transitions,
    authoritativeHistories: histories,
  },
  STAGE58_SEMANTIC_STRUCTURE_CACHE: structures,
};

function sleepMs(ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {}
}

function calendarDateSpaghetti(calculationDay, targetDay) {
  sleepMs(60);
  const c = calculationDay.toString();
  const key = c + ':' + targetDay.toString();
  if (gateDays.get(c) === null) gateDays.set(c, calculationDay - 7n);
  if (gateGaps.get(c) === null) gateGaps.set(c, 13n);
  if (year5000.get(c) === null) year5000.set(c, { number: 5000n, openDay: calculationDay - 500n, closeDay: calculationDay + 500n });
  if (transitions.get(key) === null) transitions.set(key, { direction: targetDay >= calculationDay ? 'forward' : 'backward', day: targetDay });
  histories.set(c, [{ year: 5000n, target: targetDay }]);
  structures.set(key, { cutlets: [4n, 5n], months: new Map([['sand', 32n]]) });
  if (targetDay === -999n) {
    selectionMemory.set(key, { result: 99n, observedRejectionIterations: 9n });
    sauceMemory.set(key, { stage58SauceGeneration: 'STAGE56', bowls: [9n, 9n, 9n] });
    throw new Error('FAKE_FAILURE');
  }
  if (selectionMemory.get(key) === null) selectionMemory.set(key, { result: 17n, observedRejectionIterations: 2n });
  if (sauceMemory.get(key) === null) sauceMemory.set(key, { stage58SauceGeneration: 'STAGE56', bowls: [1n, 2n, 3n] });
  return [5000n, 'bronze', targetDay - calculationDay + 1n, 'sand', 32n];
}

module.exports = Object.freeze({
  calendarDateSpaghetti,
  STAGE57_GLOBAL_GATE_REGISTRY,
  STAGE57_GLOBAL_MANAGER,
  Stage58BoundedRememberingScar: FakeBoundedScar,
  Stage58WeakRememberingScar: FakeWeakScar,
});
