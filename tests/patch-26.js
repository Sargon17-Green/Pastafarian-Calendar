'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.legacyFindYearClosedOpeningInterval, 'function');
assert.equal(typeof production.correctOpeningGateInterval, 'function');
assert.equal(typeof production.OpeningGateIntervalPatchWrapper, 'function');
assert.equal(typeof production.historicOpeningGateIntervalThroughMonsterPath, 'function');

const legacySource = production.legacyFindYearClosedOpeningInterval.toString();
assert.match(legacySource, /targetDay < current\.openDay/);
assert.match(legacySource, /current\.openDay <= targetDay/);
assert.doesNotMatch(legacySource, /targetDay <= current\.openDay/);
const correctSource = production.correctOpeningGateInterval.toString();
assert.match(correctSource, /targetDay <= current\.openDay/);
assert.match(correctSource, /current\.openDay < targetDay/);

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
    anchor, anchor.openDay,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  const correct = production.correctOpeningGateInterval(
    anchor, anchor.openDay,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  assert.equal(legacy.year.number, witness.number);
  assert.equal(legacy.stepCount, 0n);
  assert.equal(legacy.openingBoundaryAccepted, true);
  assert.equal(correct.year.number, witness.number - 1n);
  assert.equal(correct.stepCount, 1n);
  assert.equal(correct.trace[0].direction, 'previous');
  assert.equal(correct.openingBoundaryMovedBackward, true);
  assert.equal(correct.year.openDay < anchor.openDay, true);
  assert.equal(anchor.openDay <= correct.year.closeDay, true);
}

const source = adjacentSource();
const interiorAnchor = { number: 5001n, openDay: 100n, firstDay: 101n, closeDay: 200n };
for (const target of [101n, 150n, 200n]) {
  const correct = production.correctOpeningGateInterval(
    interiorAnchor, target,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  assert.equal(correct.year.number, 5001n);
  assert.equal(correct.stepCount, 0n);
  assert.equal(correct.year.openDay < target && target <= correct.year.closeDay, true);
}

const unitContext = new production.BaseMonsterContext(1n, 100n);
unitContext.status = 'DISCOVERY_26_LEGACY_RESULT';
unitContext.currentHandler = 'Discovery26OpeningGateIntervalHandler';
unitContext.branchTrace.push('DISCOVERY_26_OPENING_GATE_WRONG_YEAR');
unitContext.legacyOpeningGateTargetDay = 100n;
unitContext.legacyOpeningGateOwnershipAnchor = { ...interiorAnchor };
unitContext.legacyOpeningGateResolvedYear = { ...interiorAnchor };
unitContext.legacyOpeningGateSemanticYearNumber = 5001n;
const wrapper = new production.OpeningGateIntervalPatchWrapper(
  new production.BaseValidationManager(),
  new production.BaseMetricsManager()
);
const unit = wrapper.repair(unitContext, source);
assert.equal(unit.legacySemanticYearNumber, 5001n);
assert.equal(unit.semanticYearNumber, 5000n);
assert.equal(unit.stepCount, 1n);
assert.equal(unit.openingBoundaryMovedBackward, true);
assert.equal(unit.authoritativeInterval, '(open,close]');
assert.equal(unitContext.patch26LegacySemanticYearNumber, 5001n);
assert.equal(unitContext.patch26LegacyDiagnosticPreserved, true);
assert.equal(unitContext.patch26BackwardUsesLessOrEqual, true);
assert.equal(unitContext.patch26SemanticYearNumber, 5000n);
assert.equal(unitContext.legacyOpeningGateSemanticYearNumber, 5000n);
assert.equal(unitContext.status, 'PATCH_26_RESULT');
assert.deepEqual(unitContext.branchTrace.slice(-2), [
  'DISCOVERY_26_OPENING_GATE_WRONG_YEAR',
  'PATCH_26_OPENING_GATE_PREVIOUS_YEAR'
]);
assert.equal(unitContext.metrics['patch26.legacyDiagnosticPreserved.calls'], 1n);
assert.equal(unitContext.metrics['patch26.correctOpeningGateInterval.calls'], 1n);
assert.equal(unitContext.metrics['patch26.semanticYearOverwrite.calls'], 1n);
assert.equal(unitContext.metrics['patch26.openingBoundaryMovedBackward.calls'], 1n);

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
    assert.equal(year.number, 5001n);
    assert.equal(year.openDay, targetDay);
    return {
      number: 5000n,
      openDay: targetDay - 1000n,
      firstDay: targetDay - 999n,
      closeDay: targetDay
    };
  }
};

const manager = new production.BaseMonsterManager();
const routed = production.historicOpeningGateIntervalThroughMonsterPath(
  manager, calculationDay, targetDay, -1n,
  gates, candidatePairs, selectionStream, yearWalkSource
);
assert.equal(routed.context.status, 'PATCH_26_RESULT');
assert.equal(routed.context.patch18ResolvedYear.number, 5000n);
assert.equal(routed.context.legacyOpeningGateResolvedYear.number, 5001n);
assert.equal(routed.context.patch26LegacySemanticYearNumber, 5001n);
assert.equal(routed.context.patch26SemanticYearNumber, 5000n);
assert.equal(routed.context.legacyOpeningGateSemanticYearNumber, 5000n);
assert.equal(routed.result.legacyYear.number, 5001n);
assert.equal(routed.result.legacySemanticYearNumber, 5001n);
assert.equal(routed.result.year.number, 5000n);
assert.equal(routed.result.semanticYearNumber, 5000n);
assert.equal(routed.result.stepCount, 1n);
assert.equal(routed.result.openingBoundaryMovedBackward, true);
assert.equal(routed.result.authoritativeInterval, '(open,close]');
assert.equal(nextCalls, 1);
assert.equal(previousCalls, 1);
assert.deepEqual(routed.context.branchTrace.slice(-4), [
  'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS',
  'PATCH_25_MONTH_DAY_OCCURRENCE_COUNT',
  'DISCOVERY_26_OPENING_GATE_WRONG_YEAR',
  'PATCH_26_OPENING_GATE_PREVIOUS_YEAR'
]);
assert.equal(routed.context.metrics['discovery26.legacyClosedOpeningInterval.calls'], 1n);
assert.equal(routed.context.metrics['discovery26.openingBoundaryAccepted.calls'], 1n);
assert.equal(routed.context.metrics['patch26.correctOpeningGateInterval.calls'], 1n);

const second = production.historicOpeningGateIntervalThroughMonsterPath(
  manager, calculationDay, targetDay, -1n,
  gates, candidatePairs, selectionStream, {
    nextYear(year) {
      return { number: year.number + 1n, openDay: year.closeDay, firstDay: year.closeDay + 1n, closeDay: year.closeDay + 1000n };
    },
    previousYear(year) {
      return { number: year.number - 1n, openDay: year.openDay - 1000n, firstDay: year.openDay - 999n, closeDay: year.openDay };
    }
  }
);
assert.notEqual(second.context, routed.context);
assert.equal(second.result.legacySemanticYearNumber, 5001n);
assert.equal(second.result.semanticYearNumber, 5000n);

console.log('PATCH 26 PASS: legacy-year=5001 correct-year=5000; interval (open,close] e equality-backstep verificat.');
