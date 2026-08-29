'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.LegalMonthWeavingDP, 'function');
assert.equal(typeof production.compatibleMonthWeavingRank, 'function');
assert.equal(typeof production.DPUnrankLegalWeaving, 'function');
assert.equal(typeof production.MonthWeavingPatchWrapper, 'function');
assert.equal(typeof production.historicMonthWeavingThroughMonsterPath, 'function');
assert.equal(typeof production.legacyChooseEachDaySeparately, 'function');
assert.equal('oldContiguousMonthDayGuess' in production, false);

const legacySource = production.legacyChooseEachDaySeparately.toString();
assert.match(legacySource, /ringAnswerAt/);
assert.match(legacySource, /wrapMonth/);
assert.doesNotMatch(legacySource, /DPUnrank|wantedRank|MonthWeavingPatchWrapper/);
const discoverySource = production.Discovery24MonthWeavingHandler.prototype.handle.toString();
assert.doesNotMatch(discoverySource, /LegalMonthWeavingDP|DPUnrankLegalWeaving|MonthWeavingPatchWrapper/);
const patchSource = production.MonthWeavingPatchWrapper.prototype.repair.toString();
assert.match(patchSource, /compatibleMonthWeavingRank/);
assert.match(patchSource, /DPUnrankLegalWeaving/);
assert.match(patchSource, /legacyMonthWeavingGhost/);

function positionsAreOrdered(word, monthCount, useLast) {
  const positions = [];
  for (let monthId = 1; monthId <= monthCount; monthId += 1) {
    positions.push(useLast ? word.lastIndexOf(monthId) : word.indexOf(monthId));
  }
  for (let index = 1; index < positions.length; index += 1) {
    if (!(positions[index - 1] < positions[index])) return false;
  }
  return true;
}

const auditFamilies = [
  [1], [2], [1,1], [2,1], [2,2], [3,2], [2,2,1], [3,2,2], [1,2,3,2], [4,4,4]
];
let auditedMembers = 0;
for (const lengths of auditFamilies) {
  const actual = new production.LegalMonthWeavingDP(lengths);
  const expected = normative.makeMonthWeavingFamily(lengths);
  assert.equal(actual.count(), expected.count());
  for (let rank = 1n; rank <= expected.count(); rank += 1n) {
    assert.deepEqual(actual.unrank1(rank), expected.unrank1(rank));
    assert.deepEqual(production.DPUnrankLegalWeaving(lengths, rank), expected.unrank1(rank));
    auditedMembers += 1;
  }
}
assert.ok(auditedMembers > 1300);

const f = normative.FOUNDATION_DAY;
const smallLengths = [4,4,4];
const smallSauce = production.sauceWithCurrentScars(f, f - 120n);
const smallStream = production.monthWeavingAnswerRingFromSauce(smallSauce);
const smallGhost = production.legacyChooseEachDaySeparately(smallLengths, smallStream);
const smallFamily = new production.LegalMonthWeavingDP(smallLengths);
assert.equal(smallFamily.count(), 1301n);
const smallWantedRank = production.compatibleMonthWeavingRank(smallStream, smallFamily.count());
assert.equal(smallWantedRank, 216n);
const smallCorrect = production.DPUnrankLegalWeaving(smallLengths, smallWantedRank, smallFamily);
assert.deepEqual(smallGhost, [3,1,2,3,1,2,3,1,2,3,1,2]);
assert.deepEqual(smallCorrect, [1,1,2,1,3,3,1,2,2,2,3,3]);
assert.notDeepEqual(smallGhost, smallCorrect);

function makePatchContext(lengths, ghost, stream, metricsSeed) {
  const context = new production.BaseMonsterContext(1n, 1n);
  context.status = 'DISCOVERY_24_LEGACY_RESULT';
  context.legacyMonthWeavingLengths = lengths.slice();
  context.legacyMonthWeavingGhost = ghost;
  context.legacyMonthWeavingAnswerStream = { ...stream };
  context.legacyMonthWeavingSemantic = ghost;
  if (metricsSeed !== undefined) context.metrics['observability.seed'] = BigInt(metricsSeed);
  return context;
}

const wrapper = new production.MonthWeavingPatchWrapper(
  new production.BaseValidationManager(), new production.BaseMetricsManager()
);
const correctionContext = makePatchContext(smallLengths, smallGhost.slice(), smallStream, 7);
const correction = wrapper.repair(correctionContext);
assert.equal(correctionContext.status, 'PATCH_24_RESULT');
assert.equal(correction.familyCount, 1301n);
assert.equal(correction.wantedRank, 216n);
assert.deepEqual(correction.ghost, smallGhost);
assert.deepEqual(correction.correct, smallCorrect);
assert.deepEqual(correction.monthWeaving, smallCorrect);
assert.equal(correction.ghostEqualsCorrect, false);
assert.equal(correctionContext.patch24ReturnedLegacyGhost, false);
assert.deepEqual(correctionContext.patch24SemanticMonthWeaving, smallCorrect);
assert.deepEqual(correctionContext.legacyMonthWeavingGhost, smallGhost);
assert.equal(correctionContext.metrics['observability.seed'], 7n);

const identityGhost = [1,2];
const identityContext = makePatchContext([1,1], identityGhost, { first: 1n, directionStep: 1n });
const identity = wrapper.repair(identityContext);
assert.equal(identity.familyCount, 1n);
assert.equal(identity.wantedRank, 1n);
assert.deepEqual(identity.correct, [1,2]);
assert.equal(identity.ghostEqualsCorrect, true);
assert.equal(identity.monthWeaving, identityGhost);
assert.equal(identityContext.patch24SemanticMonthWeaving, identityGhost);
assert.equal(identityContext.patch24ReturnedLegacyGhost, true);

const wideCount = production.M_OLD + 123456789n;
const wideStream = { first: production.M_OLD - 17n, directionStep: 1n };
assert.equal(
  production.compatibleMonthWeavingRank(wideStream, wideCount),
  production.selectionDispatcherWithWideDetour(wideStream, wideCount).output
);

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
const noWalkExpected = {
  nextYear() { throw new Error('Patch 24 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Patch 24 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const manager = new production.BaseMonsterManager();
const routed = production.historicMonthWeavingThroughMonsterPath(
  manager, calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.equal(routed.context.status, 'PATCH_24_RESULT');
assert.equal(routed.context.legacyMonthWeavingHelperExecuted, true);
assert.equal(routed.context.patch24Ghost, routed.context.legacyMonthWeavingGhost);
assert.ok(routed.result.familyCount > production.M_OLD);
assert.equal(
  routed.result.wantedRank,
  production.selectionDispatcherWithWideDetour(routed.context.legacyMonthWeavingAnswerStream, routed.result.familyCount).output
);
assert.deepEqual(
  routed.result.monthWeaving,
  production.DPUnrankLegalWeaving(routed.result.monthLengths, routed.result.wantedRank)
);
assert.deepEqual(routed.result.monthWeaving, routed.context.patch24SemanticMonthWeaving);
assert.equal(positionsAreOrdered(routed.result.monthWeaving, routed.result.monthLengths.length, false), true);
assert.equal(positionsAreOrdered(routed.result.monthWeaving, routed.result.monthLengths.length, true), true);
for (let monthId = 1; monthId <= routed.result.monthLengths.length; monthId += 1) {
  assert.equal(
    routed.result.monthWeaving.filter((value) => value === monthId).length,
    routed.result.monthLengths[monthId - 1]
  );
}
assert.deepEqual(routed.context.branchTrace.slice(-4), [
  'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS',
  'PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS',
  'DISCOVERY_24_LEGACY_MONTH_CHOSEN_EACH_DAY',
  'PATCH_24_LEGAL_WHOLE_MONTH_WEAVING'
]);
assert.equal(routed.context.metrics['discovery24.legacyChooseEachDaySeparately.calls'], 1n);
assert.equal(routed.context.metrics['patch24.legacyGhostPreserved.calls'], 1n);
assert.equal(routed.context.metrics['patch24.legalFamilyCount.calls'], 1n);
assert.equal(routed.context.metrics['patch24.wantedRank.calls'], 1n);
assert.equal(routed.context.metrics['patch24.DPUnrankLegalWeaving.calls'], 1n);

const second = production.historicMonthWeavingThroughMonsterPath(
  manager, calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.notEqual(second.context, routed.context);
assert.deepEqual(second.result.monthWeaving, routed.result.monthWeaving);
assert.equal(second.result.familyCount, routed.result.familyCount);
assert.equal(second.result.wantedRank, routed.result.wantedRank);
assert.notEqual(second.context.patch24LegalFamily, routed.context.patch24LegalFamily);

const observabilityA = makePatchContext(smallLengths, smallGhost.slice(), smallStream, 1);
const observabilityB = makePatchContext(smallLengths, smallGhost.slice(), smallStream, 999);
const obsA = wrapper.repair(observabilityA);
const obsB = wrapper.repair(observabilityB);
assert.deepEqual(obsA.monthWeaving, obsB.monthWeaving);
assert.equal(obsA.wantedRank, obsB.wantedRank);
assert.equal(obsA.familyCount, obsB.familyCount);

console.log('PATCH 24 PASS: small-family members audited=' + auditedMembers +
  ' witness-family=1301 rank=216 real-family-digits=' + String(routed.result.familyCount).length);
