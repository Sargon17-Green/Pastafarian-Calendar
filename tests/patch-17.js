'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const stableSource = production.stableLengthOnlyPatchedYearCandidates.toString();
assert.match(stableSource, /candidateLength < right\.candidateLength/);
assert.match(stableSource, /candidateLength > right\.candidateLength/);
assert.doesNotMatch(stableSource, /sortEqualLengthRunsByOpeningGate|openGate.*sort|opening.*gate/i);

const tieSource = production.sortEqualLengthRunsByOpeningGate.toString();
assert.match(tieSource, /while \(start < list\.length\)/);
assert.match(tieSource, /list\[end\]\.candidateLength === length/);
assert.match(tieSource, /const run = list\.slice\(start, end\)/);
assert.match(tieSource, /run\.sort/);
assert.match(tieSource, /left\.openGate < right\.openGate/);
assert.doesNotMatch(tieSource, /list\.sort/);
assert.doesNotMatch(tieSource, /candidateLength.*openGate|openGate.*candidateLength/);

const discontiguous = [
  { candidateLength: 300n, openGate: 30n, tag: 'a' },
  { candidateLength: 200n, openGate: 10n, tag: 'b' },
  { candidateLength: 300n, openGate: 20n, tag: 'c' }
];
const discontiguousBefore = discontiguous.map((item) => item.tag);
production.sortEqualLengthRunsByOpeningGate(discontiguous);
assert.deepEqual(
  discontiguous.map((item) => item.tag),
  discontiguousBefore,
  'Li helper de Patch 17 ne deve transformar se in un global sort du-clave.'
);

const mixed = [
  { candidateLength: 300n, openGate: 30n, tag: 'a' },
  { candidateLength: 300n, openGate: 10n, tag: 'b' },
  { candidateLength: 400n, openGate: 50n, tag: 'c' },
  { candidateLength: 400n, openGate: 20n, tag: 'd' },
  { candidateLength: 500n, openGate: 5n, tag: 'e' }
];
const mixedResult = production.sortEqualLengthRunsByOpeningGate(mixed);
assert.equal(mixedResult, mixed);
assert.deepEqual(mixed.map((item) => item.tag), ['b', 'a', 'd', 'c', 'e']);
assert.deepEqual(mixed.map((item) => item.candidateLength), [300n, 300n, 400n, 400n, 500n]);

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const gates = {
  10: f + 10n,
  16: f + 500n,
  20: f + 20n,
  26: f + 510n,
  30: f + 30n,
  36: f + 520n
};
const candidatePairs = [
  { openIndex: 30, closeIndex: 36 },
  { openIndex: 10, closeIndex: 16 },
  { openIndex: 20, closeIndex: 26 }
];
const selectionStream = { first: 1n, directionStep: 1n };

const legacy = production.discovery17LegacyYear5000TieThroughMonsterPath(
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream
);
const legacyOrder = legacy.result.preparedForSelection.map((candidate) => candidate.openGate);
assert.deepEqual(legacyOrder, [f + 30n, f + 10n, f + 20n]);
assert.equal(legacy.result.selected.openGate, f + 30n);
assert.equal(legacy.context.discovery17StableLengthOnlyScarPreserved, true);
assert.equal(legacy.context.metrics['patch17.equalLengthRunRepair.calls'], undefined);

const patched = production.historicYear5000TieThroughMonsterPath(
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream
);
const repairedOrder = patched.result.preparedForSelection.map((candidate) => candidate.openGate);
assert.deepEqual(repairedOrder, [f + 10n, f + 20n, f + 30n]);
assert.equal(patched.result.selectedOrdinal, 1n);
assert.equal(patched.result.selected.openGate, f + 10n);
assert.deepEqual(
  patched.result.legacyPreparedForSelection.map((candidate) => candidate.openGate),
  legacyOrder
);
assert.equal(patched.context.currentHandler, 'Year5000TiePatchWrapper');
assert.equal(patched.context.previousHandler, 'Discovery17Year5000TieHandler');
assert.equal(patched.context.phase, 'PATCH_17_EQUAL_LENGTH_RUN_OPENING_GATE');
assert.equal(patched.context.status, 'PATCH_17_RESULT');
assert.deepEqual(patched.context.patch17LegacyLengthSortedFamily.map((candidate) => candidate.openGate), legacyOrder);
assert.equal(patched.context.patch17LegacySelectedDiagnostic.openGate, f + 30n);
assert.equal(patched.context.patch17LegacyDiagnosticPreserved, true);
assert.equal(patched.context.patch17EqualLengthRunCount, 1);
assert.deepEqual(patched.context.patch17RepairedFamily.map((candidate) => candidate.openGate), repairedOrder);
assert.equal(patched.context.patch17SelectionFamilySize, 3);
assert.deepEqual(patched.context.patch17SelectionStream, selectionStream);
assert.equal(patched.context.patch17SelectedOrdinal, 1n);
assert.equal(patched.context.patch17Selected.openGate, f + 10n);
assert.deepEqual(patched.context.branchTrace.slice(-5), [
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE',
  'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR',
  'PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT',
  'DISCOVERY_17_YEAR_5000_EQUAL_LENGTH_TIE',
  'PATCH_17_EQUAL_LENGTH_RUN_OPENING_GATE'
]);
assert.equal(patched.context.metrics['patch17.equalLengthRunRepair.calls'], 1n);
assert.equal(patched.context.metrics['patch17.equalLengthRuns.reordered'], 1n);

const secondRank = production.historicYear5000TieThroughMonsterPath(
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  { first: 2n, directionStep: 1n }
);
assert.equal(secondRank.result.selectedOrdinal, 2n);
assert.equal(secondRank.result.selected.openGate, f + 20n);

const discoverySource = production.Discovery17Year5000TieHandler.prototype.handle.toString();
assert.doesNotMatch(discoverySource, /\.sort\(|sortEqualLengthRunsByOpeningGate/);
const wrapperSource = production.Year5000TiePatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /discovery17PreparedForSelection/);
assert.match(wrapperSource, /sortEqualLengthRunsByOpeningGate/);
assert.match(wrapperSource, /legacyAdapter\.select\(repaired, selectionStream\)/);
assert.ok(
  wrapperSource.indexOf('discovery17PreparedForSelection') < wrapperSource.indexOf('sortEqualLengthRunsByOpeningGate'),
  'Li stable family legacy deve esser materialisat e conservat ante li tie repair.'
);
assert.doesNotMatch(production.Year5000TiePatchWrapper.prototype.repair.toString(), /oldJumpGuess/);

console.log('PATCH 17: PASS — li stable sort per longore resta intact; solmen runs contigui egal es reordinat per opening gate tempran ante selection.');
