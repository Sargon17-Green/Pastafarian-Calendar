'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const helperSource = production.oldJumpGuess.toString();
assert.match(helperSource, /targetDay - anchor\.firstDay/);
assert.match(helperSource, /floorDiv\(targetDay - anchor\.firstDay, 365n\)/);
assert.doesNotMatch(helperSource, /nextYear|previousYear|findYearByWalkPatch|ignoredGuess/);

const directAnchor = { number: 5000n, openDay: 99n, firstDay: 100n, closeDay: 1099n };
assert.equal(production.oldJumpGuess(directAnchor, 100n), 5000n);
assert.equal(production.oldJumpGuess(directAnchor, 464n), 5000n);
assert.equal(production.oldJumpGuess(directAnchor, 465n), 5001n);
assert.equal(production.oldJumpGuess(directAnchor, 99n), 4999n);
assert.equal(production.oldJumpGuess(directAnchor, -266n), 4998n);
assert.throws(() => production.oldJumpGuess(null, 1n), TypeError);
assert.throws(() => production.oldJumpGuess({ number: 5000n, firstDay: 1 }, 1n), TypeError);

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

const anchorProbe = production.historicYear5000TieThroughMonsterPath(
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream
);
assert.equal(anchorProbe.context.status, 'PATCH_17_RESULT');
assert.equal(anchorProbe.context.patch17Selected.openGate, f + 10n);
assert.equal(anchorProbe.context.patch17Selected.closeGate, f + 1010n);
assert.equal(anchorProbe.context.patch17Selected.candidateLength, 1000n);

const anchor = {
  number: 5000n,
  openDay: anchorProbe.context.patch17Selected.openGate,
  firstDay: anchorProbe.context.patch17Selected.openGate + 1n,
  closeDay: anchorProbe.context.patch17Selected.closeGate
};
const targets = [anchor.firstDay + 365n, anchor.closeDay, anchor.closeDay + 1n];
const expectedYearNumbers = [5000n, 5000n, 5001n];
const legacyYearNumbers = [];

for (let index = 0; index < targets.length; index += 1) {
  const targetDay = targets[index];
  const routed = production.discovery18LegacyYearJumpThroughMonsterPath(
    calculationDay,
    targetDay,
    -1n,
    gates,
    candidatePairs,
    selectionStream
  );
  const expected = expectedYearNumbers[index];
  legacyYearNumbers.push(routed.result.semanticYearNumber);
  assert.equal(routed.context.currentHandler, 'Discovery18YearJumpHandler');
  assert.equal(routed.context.previousHandler, 'Year5000TiePatchWrapper');
  assert.equal(routed.context.phase, 'DISCOVERY_18_OLD_JUMP_GUESS_365');
  assert.equal(routed.context.status, 'DISCOVERY_18_LEGACY_RESULT');
  assert.equal(routed.context.legacyJumpAnchorNumber, 5000n);
  assert.equal(routed.context.legacyJumpAnchorOpenDay, anchor.openDay);
  assert.equal(routed.context.legacyJumpAnchorFirstDay, anchor.firstDay);
  assert.equal(routed.context.legacyJumpAnchorCloseDay, anchor.closeDay);
  assert.equal(routed.context.legacyJumpTargetDay, targetDay);
  assert.equal(routed.context.legacyJumpDeltaFromFirstDay, targetDay - anchor.firstDay);
  assert.equal(routed.context.legacyJumpGuess, production.oldJumpGuess(anchor, targetDay));
  assert.equal(routed.context.legacyJumpSemanticYearNumber, routed.context.legacyJumpGuess);
  assert.equal(routed.context.legacyJumpGuessUsedAsSemantic, true);
  assert.equal(routed.context.metrics['discovery18.oldJumpGuess.calls'], 1n);
  assert.equal(routed.context.metrics['discovery18.guessUsedAsSemantic.calls'], 1n);
  assert.deepEqual(routed.context.branchTrace.slice(-5), [
    'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR',
    'PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT',
    'DISCOVERY_17_YEAR_5000_EQUAL_LENGTH_TIE',
    'PATCH_17_EQUAL_LENGTH_RUN_OPENING_GATE',
    'DISCOVERY_18_OLD_JUMP_GUESS_365'
  ]);
  if (targetDay <= anchor.closeDay) {
    assert.equal(expected, 5000n);
    assert.ok(anchor.openDay < targetDay && targetDay <= anchor.closeDay);
  } else {
    assert.equal(targetDay, anchor.closeDay + 1n);
    assert.equal(expected, 5001n);
  }
}

assert.deepEqual(legacyYearNumbers, [5001n, 5002n, 5002n]);
assert.notDeepEqual(legacyYearNumbers, expectedYearNumbers);
assert.doesNotMatch(
  production.Discovery18YearJumpHandler.prototype.handle.toString(),
  /findYearByWalkPatch|patchedNextYear|patchedPreviousYear/
);

const nextYear5001 = {
  number: 5001n,
  openDay: anchor.closeDay,
  firstDay: anchor.closeDay + 1n,
  closeDay: anchor.closeDay + 700n
};
const previousYear4999 = {
  number: 4999n,
  openDay: anchor.openDay - 700n,
  firstDay: anchor.openDay - 699n,
  closeDay: anchor.openDay
};
const walkSource = {
  nextYear(year) {
    if (year.number === 5000n) return { ...nextYear5001 };
    throw new RangeError('Null altri nextYear es necessi por li witness de Discovery 18.');
  },
  previousYear(year) {
    if (year.number === 5000n) return { ...previousYear4999 };
    throw new RangeError('Null altri previousYear es necessi por li witness de Discovery 18.');
  }
};
const patchedYearNumbers = targets.map((targetDay) => production.historicYearJumpThroughMonsterPath(
  calculationDay,
  targetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  walkSource
).result.semanticYearNumber);

console.log('DISCOVERY 18 DIAGNOSTIC: oldJumpGuess resta incorrect quam scar, ma Patch 18 ignora su guess por li semantics.');
console.log('anchor:   ' + [anchor.number, anchor.openDay, anchor.firstDay, anchor.closeDay].map(String).join(', '));
console.log('targets:  ' + targets.map(String).join(', '));
console.log('legacy:   ' + legacyYearNumbers.map(String).join(', '));
console.log('patched:  ' + patchedYearNumbers.map(String).join(', '));
console.log('normativ: ' + expectedYearNumbers.map(String).join(', '));

assert.deepEqual(
  patchedYearNumbers,
  expectedYearNumbers,
  'Discovery 18 resta observabil quam scar, durante que Patch 18 deve caminar un year a un vez por li resultate semantic.'
);
