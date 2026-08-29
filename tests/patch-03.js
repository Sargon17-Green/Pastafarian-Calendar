'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;

for (let dc = -64n; dc <= 64n; dc += 1n) {
  for (let dt = -64n; dt <= 64n; dt += 1n) {
    const calculationDay = f + dc;
    const targetDay = f + dt;
    assert.equal(
      production.distanceWithChronologyDetour(calculationDay, targetDay),
      normative.workCounts(calculationDay, targetDay).distance,
      'Patch 03 deve esser exact por omni pare del gril circum li Foundation.'
    );
  }
}

const farCases = [
  [f - 1000000n, f + 1000000n],
  [f + 999999n, f + 1000123n],
  [f - 2000123n, f - 2000000n],
  [f, f]
];
for (const [calculationDay, targetDay] of farCases) {
  assert.equal(
    production.distanceWithChronologyDetour(calculationDay, targetDay),
    normative.workCounts(calculationDay, targetDay).distance
  );
}

assert.equal(production.oldDistance(f - 2n, f + 2n), 1n);
assert.equal(production.distanceWithChronologyDetour(f - 2n, f + 2n), 5n);

const replaced = production.historicDistanceThroughMonsterPath(f - 2n, f + 2n);
assert.deepEqual(replaced.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_03_OLD_DISTANCE',
  'PATCH_03_CHRONOLOGY_DETOUR'
]);
assert.equal(replaced.context.legacyDistanceOutput, 1n);
assert.equal(replaced.context.patch03ChronologicalDistance, 4n);
assert.equal(replaced.context.patch03LegacyReplaced, true);
assert.equal(replaced.context.patch03DistanceBeforeInclusive, 4n);
assert.equal(replaced.context.patch03Output, 5n);
assert.equal(replaced.context.metrics['discovery03.legacyDistance.calls'], 1n);
assert.equal(replaced.context.metrics['patch03.distance.calls'], 1n);

const sameDay = production.historicDistanceThroughMonsterPath(f, f);
assert.equal(sameDay.context.legacyDistanceOutput, 0n);
assert.equal(sameDay.context.patch03ChronologicalDistance, 0n);
assert.equal(sameDay.context.patch03LegacyReplaced, false);
assert.equal(sameDay.context.patch03DistanceBeforeInclusive, 0n);
assert.equal(sameDay.result, 1n);

const alreadyChronological = production.historicDistanceThroughMonsterPath(f - 1n, f);
assert.equal(alreadyChronological.context.legacyDistanceOutput, 1n);
assert.equal(alreadyChronological.context.patch03ChronologicalDistance, 1n);
assert.equal(alreadyChronological.context.patch03LegacyReplaced, false);
assert.equal(alreadyChronological.result, 2n);

const source = production.distanceWithChronologyDetour.toString();
assert.match(source, /let legacy = oldDistance\(calculationDay, targetDay\)/);
assert.match(source, /if \(legacy !== chronological\)/);
assert.match(source, /const distance = legacy \+ 1n/);

console.log('PATCH 03: PASS — oldDistance resta intact; li detour cronologic substitue solmen si necessi e adjunte li unit inclusiv.');
