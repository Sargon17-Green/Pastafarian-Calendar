'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.legacyFindYearClosedOpeningInterval, 'function');
assert.equal(typeof production.LegacyOpeningGateIntervalAdapter, 'function');
assert.equal(typeof production.Discovery26OpeningGateIntervalHandler, 'function');
assert.equal(typeof production.discovery26LegacyOpeningGateIntervalThroughMonsterPath, 'function');
assert.equal(typeof production.correctOpeningGateInterval, 'function');
assert.equal(typeof production.OpeningGateIntervalPatchWrapper, 'function');
assert.equal(typeof production.historicOpeningGateIntervalThroughMonsterPath, 'function');

const helperSource = production.legacyFindYearClosedOpeningInterval.toString();
assert.match(helperSource, /targetDay < current\.openDay/);
assert.match(helperSource, /current\.openDay <= targetDay/);
assert.doesNotMatch(helperSource, /targetDay <= current\.openDay/);

function adjacentSource() {
  return {
    nextYear(year) {
      return {
        number: year.number + 1n,
        openDay: year.closeDay,
        firstDay: year.closeDay + 1n,
        closeDay: year.closeDay + 100n
      };
    },
    previousYear(year) {
      return {
        number: year.number - 1n,
        openDay: year.openDay - 100n,
        firstDay: year.openDay - 99n,
        closeDay: year.openDay
      };
    }
  };
}

for (const witness of [
  { number: 5001n, openDay: 100n, closeDay: 200n },
  { number: -12n, openDay: -1000n, closeDay: -500n },
  { number: 9000n, openDay: 123456n, closeDay: 124000n }
]) {
  const anchor = {
    number: witness.number,
    openDay: witness.openDay,
    firstDay: witness.openDay + 1n,
    closeDay: witness.closeDay
  };
  const source = adjacentSource();
  const legacy = production.legacyFindYearClosedOpeningInterval(
    anchor,
    anchor.openDay,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  assert.equal(legacy.year.number, witness.number);
  assert.equal(legacy.stepCount, 0n);
  assert.equal(legacy.openingBoundaryAccepted, true);
  assert.equal(legacy.year.number - 1n, witness.number - 1n);
}

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 102n;
const gates = {
  10: f + 10n, 14: calculationDay, 20: f + 1010n,
  30: f + 20n, 40: f + 1020n, 50: f + 30n, 60: f + 1030n
};
const candidatePairs = [
  { openIndex: 50, closeIndex: 60 },
  { openIndex: 10, closeIndex: 20 },
  { openIndex: 30, closeIndex: 40 }
];
const selectionStream = { first: 1n, directionStep: 1n };
const targetDay = f + 1010n;
let nextCalls = 0;
let previousCalls = 0;
const yearWalkSource = {
  nextYear(year) {
    nextCalls += 1;
    assert.equal(year.number, 5000n);
    assert.equal(year.closeDay, targetDay);
    return {
      number: 5001n,
      openDay: targetDay,
      firstDay: targetDay + 1n,
      closeDay: targetDay + 1000n
    };
  },
  previousYear(year) {
    previousCalls += 1;
    return {
      number: year.number - 1n,
      openDay: year.openDay - 1000n,
      firstDay: year.openDay - 999n,
      closeDay: year.openDay
    };
  }
};

const routed = production.discovery26LegacyOpeningGateIntervalThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, targetDay, -1n,
  gates, candidatePairs, selectionStream, yearWalkSource
);

assert.equal(routed.context.status, 'DISCOVERY_26_LEGACY_RESULT');
assert.equal(routed.context.patch25SemanticMonthDay, routed.context.legacyMonthDaySemantic);
assert.equal(routed.context.patch18ResolvedYear.number, 5000n);
assert.equal(routed.context.patch18ResolvedYear.closeDay, targetDay);
assert.equal(routed.result.authoritativeYear.number, 5000n);
assert.equal(routed.result.ownershipAnchor.number, 5001n);
assert.equal(routed.result.ownershipAnchor.openDay, targetDay);
assert.equal(routed.result.legacyYear.number, 5001n);
assert.equal(routed.result.semanticYearNumber, 5001n);
assert.equal(routed.result.reanchoredToOpeningYear, true);
assert.equal(routed.result.openingBoundaryAccepted, true);
assert.equal(routed.result.stepCount, 0n);
assert.equal(nextCalls, 1);
assert.equal(previousCalls, 0);
assert.equal(routed.context.legacyOpeningGateBackwardUsesStrictLess, true);
assert.equal(routed.context.legacyOpeningGateClosedOpeningInterval, true);
assert.equal(routed.context.metrics['discovery26.legacyClosedOpeningInterval.calls'], 1n);
assert.equal(routed.context.metrics['discovery26.openingOwnershipReanchor.calls'], 1n);
assert.equal(routed.context.metrics['discovery26.openingBoundaryAccepted.calls'], 1n);
assert.deepEqual(routed.context.branchTrace.slice(-3), [
  'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS',
  'PATCH_25_MONTH_DAY_OCCURRENCE_COUNT',
  'DISCOVERY_26_OPENING_GATE_WRONG_YEAR'
]);

const expectedYearNumber = routed.result.authoritativeYear.number;
console.log('DISCOVERY 26 DIAGNOSTIC: li interval legacy [open,close] atribui li opening gate al year quel comensa ta.');
console.log('target opening gate: ' + routed.result.ownershipAnchor.openDay);
console.log('legacy semantic year: ' + routed.result.semanticYearNumber);
console.log('normativ year per (open,close]: ' + expectedYearNumber);
console.log('legacy backward steps: ' + routed.result.stepCount);

assert.notEqual(
  routed.result.semanticYearNumber,
  expectedYearNumber,
  'Li scar de Discovery 26 deve continuar demonstrar li ownership historic errat pos Patch 26.'
);
