'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const legacySource = production.oldJumpGuess.toString();
assert.match(legacySource, /return anchor\.number \+ floorDiv\(targetDay - anchor\.firstDay, 365n\);/);
assert.doesNotMatch(legacySource, /patchedNextYear|patchedPreviousYear|findYearByWalkPatch|telemetry/);

const years = new Map([
  [4997n, { number: 4997n, openDay: -3000n, firstDay: -2999n, closeDay: -2000n }],
  [4998n, { number: 4998n, openDay: -2000n, firstDay: -1999n, closeDay: -1000n }],
  [4999n, { number: 4999n, openDay: -1000n, firstDay: -999n, closeDay: 0n }],
  [5000n, { number: 5000n, openDay: 0n, firstDay: 1n, closeDay: 1000n }],
  [5001n, { number: 5001n, openDay: 1000n, firstDay: 1001n, closeDay: 1700n }],
  [5002n, { number: 5002n, openDay: 1700n, firstDay: 1701n, closeDay: 2600n }],
  [5003n, { number: 5003n, openDay: 2600n, firstDay: 2601n, closeDay: 4000n }]
]);
const source = {
  nextYear(year) {
    const found = years.get(year.number + 1n);
    if (!found) throw new RangeError('Null next year existe in li fixture de Patch 18.');
    return { ...found };
  },
  previousYear(year) {
    const found = years.get(year.number - 1n);
    if (!found) throw new RangeError('Null previous year existe in li fixture de Patch 18.');
    return { ...found };
  }
};
const anchor = { ...years.get(5000n) };

assert.deepEqual(production.patchedNextYear(anchor, source.nextYear), years.get(5001n));
assert.deepEqual(production.patchedPreviousYear(anchor, source.previousYear), years.get(4999n));

for (const [targetDay, expectedNumber, expectedSteps, expectedDirection] of [
  [1n, 5000n, 0n, 'anchor'],
  [365n, 5000n, 0n, 'anchor'],
  [1000n, 5000n, 0n, 'anchor'],
  [1001n, 5001n, 1n, 'next'],
  [1700n, 5001n, 1n, 'next'],
  [1701n, 5002n, 2n, 'next'],
  [3000n, 5003n, 3n, 'next'],
  [0n, 4999n, 1n, 'previous'],
  [-1n, 4999n, 1n, 'previous'],
  [-1000n, 4998n, 2n, 'previous'],
  [-2500n, 4997n, 3n, 'previous']
]) {
  const walked = production.findYearByWalkPatch(anchor, targetDay, source.nextYear, source.previousYear);
  assert.equal(walked.year.number, expectedNumber);
  assert.equal(walked.stepCount, expectedSteps);
  assert.equal(walked.direction, expectedDirection);
  assert.ok(walked.year.openDay < targetDay && targetDay <= walked.year.closeDay);
  assert.equal(BigInt(walked.trace.length), expectedSteps);
}

assert.throws(() => production.patchedNextYear(anchor, () => ({ ...years.get(5002n) })), production.BootstrapStageError);
assert.throws(() => production.patchedNextYear(anchor, () => ({
  number: 5001n, openDay: 999n, firstDay: 1000n, closeDay: 1700n
})), production.BootstrapStageError);
assert.throws(() => production.patchedPreviousYear(anchor, () => ({ ...years.get(4998n) })), production.BootstrapStageError);
assert.throws(() => production.patchedPreviousYear(anchor, () => ({
  number: 4999n, openDay: -1000n, firstDay: -999n, closeDay: -1n
})), production.BootstrapStageError);
assert.throws(() => production.findYearByWalkPatch(anchor, 1, source.nextYear, source.previousYear), TypeError);

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const gates = {
  10: f + 10n,
  16: f + 1010n,
  20: f + 20n,
  26: f + 1020n,
  30: f + 30n,
  36: f + 1030n
};
const candidatePairs = [
  { openIndex: 30, closeIndex: 36 },
  { openIndex: 10, closeIndex: 16 },
  { openIndex: 20, closeIndex: 26 }
];
const selectionStream = { first: 1n, directionStep: 1n };
const patchAnchor = {
  number: 5000n,
  openDay: f + 10n,
  firstDay: f + 11n,
  closeDay: f + 1010n
};
const next5001 = {
  number: 5001n,
  openDay: patchAnchor.closeDay,
  firstDay: patchAnchor.closeDay + 1n,
  closeDay: patchAnchor.closeDay + 700n
};
const previous4999 = {
  number: 4999n,
  openDay: patchAnchor.openDay - 600n,
  firstDay: patchAnchor.openDay - 599n,
  closeDay: patchAnchor.openDay
};
let nextCalls = 0;
let previousCalls = 0;
const witnessSource = {
  nextYear(year) {
    nextCalls += 1;
    assert.equal(year.number, 5000n);
    return { ...next5001 };
  },
  previousYear(year) {
    previousCalls += 1;
    assert.equal(year.number, 5000n);
    return { ...previous4999 };
  }
};

const insideTarget = patchAnchor.firstDay + 365n;
const legacyInside = production.discovery18LegacyYearJumpThroughMonsterPath(
  calculationDay, insideTarget, -1n, gates, candidatePairs, selectionStream
);
assert.equal(legacyInside.result.semanticYearNumber, 5001n);
const patchedInside = production.historicYearJumpThroughMonsterPath(
  calculationDay, insideTarget, -1n, gates, candidatePairs, selectionStream, witnessSource
);
assert.equal(patchedInside.result.semanticYearNumber, 5000n);
assert.equal(patchedInside.result.telemetryGuess, 5001n);
assert.equal(patchedInside.context.currentHandler, 'SequentialYearWalkPatchWrapper');
assert.equal(patchedInside.context.previousHandler, 'Discovery18YearJumpHandler');
assert.equal(patchedInside.context.phase, 'PATCH_18_SEQUENTIAL_YEAR_WALK');
assert.equal(patchedInside.context.status, 'PATCH_18_RESULT');
assert.equal(patchedInside.context.legacyJumpGuess, 5001n);
assert.equal(patchedInside.context.legacyJumpGuessUsedAsSemantic, true);
assert.equal(patchedInside.context.patch18LegacyGuessDiagnostic, 5001n);
assert.equal(patchedInside.context.patch18LegacyDiagnosticPreserved, true);
assert.equal(patchedInside.context.patch18GuessIgnoredForSemantics, true);
assert.equal(patchedInside.context.patch18WalkDirection, 'anchor');
assert.equal(patchedInside.context.patch18WalkStepCount, 0n);
assert.deepEqual(patchedInside.context.patch18WalkTrace, []);
assert.equal(patchedInside.context.patch18ResolvedYear.number, 5000n);
assert.equal(patchedInside.context.patch18SemanticYearNumber, 5000n);
assert.equal(patchedInside.context.metrics['discovery18.oldJumpGuess.calls'], 1n);
assert.equal(patchedInside.context.metrics['patch18.sequentialYearWalk.calls'], 1n);
assert.equal(patchedInside.context.metrics['patch18.anchorAlreadyContainsTarget.calls'], 1n);
assert.equal(patchedInside.context.metrics['patch18.singleYearTransitions.calls'], undefined);
assert.equal(nextCalls, 0);
assert.equal(previousCalls, 0);
assert.deepEqual(patchedInside.context.branchTrace.slice(-3), [
  'PATCH_17_EQUAL_LENGTH_RUN_OPENING_GATE',
  'DISCOVERY_18_OLD_JUMP_GUESS_365',
  'PATCH_18_SEQUENTIAL_YEAR_WALK'
]);

const forwardTarget = patchAnchor.closeDay + 1n;
const legacyForward = production.discovery18LegacyYearJumpThroughMonsterPath(
  calculationDay, forwardTarget, -1n, gates, candidatePairs, selectionStream
);
assert.equal(legacyForward.result.semanticYearNumber, 5002n);
const patchedForward = production.historicYearJumpThroughMonsterPath(
  calculationDay, forwardTarget, -1n, gates, candidatePairs, selectionStream, witnessSource
);
assert.equal(patchedForward.result.semanticYearNumber, 5001n);
assert.equal(patchedForward.result.telemetryGuess, 5002n);
assert.equal(patchedForward.context.patch18WalkDirection, 'next');
assert.equal(patchedForward.context.patch18WalkStepCount, 1n);
assert.deepEqual(patchedForward.context.patch18WalkTrace, [{
  direction: 'next',
  fromNumber: 5000n,
  toNumber: 5001n,
  sharedGate: patchAnchor.closeDay
}]);
assert.equal(patchedForward.context.metrics['patch18.singleYearTransitions.calls'], 1n);
assert.equal(patchedForward.context.metrics['patch18.nextYearWalk.calls'], 1n);
assert.equal(nextCalls, 1);
assert.equal(previousCalls, 0);

const backwardTarget = patchAnchor.openDay;
const patchedBackward = production.historicYearJumpThroughMonsterPath(
  calculationDay, backwardTarget, -1n, gates, candidatePairs, selectionStream, witnessSource
);
assert.equal(patchedBackward.result.semanticYearNumber, 4999n);
assert.equal(patchedBackward.context.patch18WalkDirection, 'previous');
assert.equal(patchedBackward.context.patch18WalkStepCount, 1n);
assert.equal(patchedBackward.context.metrics['patch18.previousYearWalk.calls'], 1n);
assert.equal(previousCalls, 1);

const first = production.historicYearJumpThroughMonsterPath(
  calculationDay, insideTarget, -1n, gates, candidatePairs, selectionStream, witnessSource
);
const second = production.historicYearJumpThroughMonsterPath(
  calculationDay, insideTarget, -1n, gates, candidatePairs, selectionStream, witnessSource
);
assert.notEqual(first.context, second.context);
assert.deepEqual(first.result, second.result);
assert.notEqual(first.context.patch18ResolvedYear, second.context.patch18ResolvedYear);

const wrapperSource = production.SequentialYearWalkPatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /requireDiscovery18Result\(context\)/);
assert.match(wrapperSource, /context\.patch18LegacyGuessDiagnostic = context\.legacyJumpGuess;/);
assert.match(wrapperSource, /findYearByWalkPatch/);
assert.ok(
  wrapperSource.indexOf('context.patch18LegacyGuessDiagnostic = context.legacyJumpGuess') <
    wrapperSource.indexOf('findYearByWalkPatch'),
  'Li telemetry legacy deve esser conservat ante li caminada semantic.'
);
assert.doesNotMatch(wrapperSource, /LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER|calculationDayFingerprint|oldStructureSauce/);
assert.equal('LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER' in production, false);

console.log('PATCH 18: PASS — oldJumpGuess resta telemetry real; li semantics camina nextYear/previousYear exactmen un year per transition.');
