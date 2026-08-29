'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;

for (let delta = -2000n; delta <= 2000n; delta += 1n) {
  const day = f + delta;
  assert.equal(
    production.dayTagWithFoundationScar(day),
    normative.dayCount(day),
    'Patch 02 deve esser exact por omni die del gril circum li Foundation.'
  );
}

assert.equal(production.oldDayTag(f - 1n), 2n);
assert.equal(production.oldDayTag(f), 0n);
assert.equal(production.oldDayTag(f + 1n), 2n);
assert.equal(production.dayTagWithFoundationScar(f - 1n), 2n);
assert.equal(production.dayTagWithFoundationScar(f), 1n);
assert.equal(production.dayTagWithFoundationScar(f + 1n), 3n);

const scarSource = production.dayTagWithFoundationScar.toString();
assert.match(scarSource, /day >= FOUNDATION_DAY_OLD/);
assert.match(scarSource, /day === FOUNDATION_DAY_OLD && n !== 1n/);

const atFoundation = production.historicDayTagThroughMonsterPath(f, f, f);
assert.deepEqual(atFoundation.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_02_OLD_DAY_TAG',
  'PATCH_02_DAY_TAG_FOUNDATION_SCAR'
]);
assert.equal(atFoundation.context.legacyDayTagOutput, 0n);
assert.equal(atFoundation.context.patch02AddedParityUnit, true);
assert.equal(atFoundation.context.patch02FoundationGuardChecked, true);
assert.equal(atFoundation.context.patch02Output, 1n);
assert.equal(atFoundation.context.metrics['discovery02.legacyDayTag.calls'], 1n);
assert.equal(atFoundation.context.metrics['patch02.dayTag.calls'], 1n);

const beforeFoundation = production.historicDayTagThroughMonsterPath(f, f, f - 1n);
assert.equal(beforeFoundation.context.patch02AddedParityUnit, false);
assert.equal(beforeFoundation.context.patch02FoundationGuardChecked, false);
assert.equal(beforeFoundation.result, 2n);

console.log('PATCH 02: PASS — oldDayTag resta intact, li unit posterior e li guard del Foundation rende dayCount exact.');
