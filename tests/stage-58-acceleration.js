'use strict';

const assert = require('assert/strict');
const production = require('../src');

function metric(snapshot, key) {
  return snapshot.metrics[key] || 0n;
}

production.resetStage58AccelerationMetrics();

// Li scars historic resta exportat e executable; Stage 58 es un layer paralel, ne un replacement.
assert.equal(typeof production.sauceWithOrderAt46Latch, 'function');
assert.equal(typeof production.sauceWithOrderAt46LatchStage58RememberedReplay, 'function');
assert.notEqual(production.sauceWithOrderAt46Latch, production.sauceWithOrderAt46LatchStage58RememberedReplay);
assert.equal(typeof production.selectionDispatcherWithWideDetour, 'function');
assert.equal(typeof production.stage58SelectionDispatcherRemembered, 'function');
assert.notEqual(production.selectionDispatcherWithWideDetour, production.stage58SelectionDispatcherRemembered);
assert.equal(typeof production.LegalMonthWeavingDP.prototype.unrank1, 'function');
assert.equal(typeof production.LegalMonthWeavingDP.prototype.unrank1Stage58RememberedTraversal, 'function');

// Patch 11 historic complet contra li replay Stage 58: resultate semantic e scars observabil deve concordar.
const f = production.FOUNDATION_DAY_OLD;
const counts = production.structureSauceCountsFromDays(f + 17n, f - 9n);
const stones = production.getStoneTableThroughLegacyBuilder();
const fullHistoricalSauce = production.sauceWithOrderAt46Latch(counts, stones);
const rememberedSauce = production.sauceWithOrderAt46LatchStage58RememberedReplay(counts, stones);
assert.deepEqual(rememberedSauce.bowls, fullHistoricalSauce.bowls);
assert.deepEqual(rememberedSauce.orderAt46Latch, fullHistoricalSauce.orderAt46Latch);
assert.deepEqual(rememberedSauce.queryOrder, fullHistoricalSauce.queryOrder);
assert.deepEqual(rememberedSauce.lastPostStirOrder, fullHistoricalSauce.lastPostStirOrder);
assert.equal(rememberedSauce.lastPostStirSavedSum, fullHistoricalSauce.lastPostStirSavedSum);
assert.equal(rememberedSauce.stage58RememberedSemanticTraversal, true);

// Sauce generations es separat. Un live weak value deve esser replayet solmen intra su generation.
const sauce54a = production.sauceWithScars(f, f + 31n);
const sauce54b = production.sauceWithScars(f, f + 31n);
const sauce56a = production.sauceWithScarsStage56(f, f + 31n);
const sauce56b = production.sauceWithScarsStage56(f, f + 31n);
assert.equal(sauce54a.stage58SauceGeneration, 'STAGE54');
assert.equal(sauce54b.stage58SauceGeneration, 'STAGE54');
assert.equal(sauce54b.stage58MemoryReplay, true);
assert.equal(sauce56a.stage58SauceGeneration, 'STAGE56');
assert.equal(sauce56b.stage58SauceGeneration, 'STAGE56');
assert.equal(sauce56b.stage58MemoryReplay, true);
assert.deepEqual(sauce54a.bowls, sauce54b.bowls);
assert.deepEqual(sauce56a.bowls, sauce56b.bowls);

// Exact selection memo conserva bit-per-bit li dispatcher old por short e wide paths.
const shortStream = { first: production.M_OLD - 13n, directionStep: 1n };
const shortN = 922n;
const shortOld = production.selectionDispatcherWithWideDetour(shortStream, shortN);
const shortFirst = production.stage58SelectionDispatcherRemembered(shortStream, shortN, null, 'stage58-test-short');
const shortSecond = production.stage58SelectionDispatcherRemembered(shortStream, shortN, null, 'stage58-test-short');
assert.deepEqual(shortFirst, shortOld);
assert.deepEqual(shortSecond, shortOld);

const rejectingStream = { first: production.M_OLD, directionStep: 1n };
const rejectingN = (production.M_OLD / 2n) + 1n;
const rejectingOld = production.selectionDispatcherWithWideDetour(rejectingStream, rejectingN);
const rejectingFirst = production.stage58SelectionDispatcherRemembered(rejectingStream, rejectingN, null, 'stage58-test-rejection');
const rejectingSecond = production.stage58SelectionDispatcherRemembered(rejectingStream, rejectingN, null, 'stage58-test-rejection');
assert.deepEqual(rejectingFirst, rejectingOld);
assert.deepEqual(rejectingSecond, rejectingOld);

const wideStream = { first: production.M_OLD - 17n, directionStep: -1n };
const wideN = production.M_OLD + 123456789n;
const wideOld = production.selectionDispatcherWithWideDetour(wideStream, wideN);
const wideFirst = production.stage58SelectionDispatcherRemembered(wideStream, wideN, null, 'stage58-test-wide');
const wideSecond = production.stage58SelectionDispatcherRemembered(wideStream, wideN, null, 'stage58-test-wide');
assert.deepEqual(wideFirst, wideOld);
assert.deepEqual(wideSecond, wideOld);

// Li du constructors historic resta real. Li duesim constructor usa li sam backend remembered.
const virtualA = new production.VirtualLegacyList(24, 4);
const virtualB = new production.VirtualLegacyList(24, 4);
assert.equal(virtualA.stage58BackendRemembered, false);
assert.equal(virtualB.stage58BackendRemembered, true);
assert.equal(virtualA.count(), virtualB.count());
for (const rank of [1n, virtualA.count()]) {
  assert.deepEqual(virtualA.itemAt1(rank), virtualB.itemAt1(rank));
}

const weavingA = new production.LegalMonthWeavingDP([4, 4, 4]);
const weavingB = new production.LegalMonthWeavingDP([4, 4, 4]);
assert.equal(weavingA.stage58BackendRemembered, false);
assert.equal(weavingB.stage58BackendRemembered, true);
assert.equal(weavingA.count(), 1301n);
assert.equal(weavingB.count(), 1301n);
for (let rank = 1n; rank <= weavingA.count(); rank += 1n) {
  assert.deepEqual(weavingB.unrank1Stage58RememberedTraversal(rank), weavingA.unrank1(rank));
}

// Shared gate checkpoints ne elimina li registry historic: un registry nov materialisa su Map proprium,
// ma li gaps/gates ja patit per un registry anterior es replayet ex li scar commun del sam provider.
const gateRegistryA = new production.Stage54GateRegistry(production.sauceWithScarsStage56);
const gateRegistryB = new production.Stage54GateRegistry(production.sauceWithScarsStage56);
assert.equal(gateRegistryA.ensureIndex(3n), gateRegistryB.ensureIndex(3n));
assert.equal(gateRegistryA.gapCalls, 3n);
assert.equal(gateRegistryB.gapCalls, 0n);
assert.equal(gateRegistryB.stage58GateCheckpointHits, 3n);
assert.equal(gateRegistryB.gates.size, 4);

// Year anchors es direction-tagged; un checkpoint next ne posse esser usat quam anchor previous.
const fakeProvider = () => { throw new Error('Li unit test de year memory ne deve vocar sauce.'); };
const yearMemory = new production.Stage58RememberedYearDetourManager(fakeProvider);
const origin = { number: 5000n, openGateIndex: 0n, closeGateIndex: 1n, openDay: 0n, closeDay: 100n };
const next = { number: 5001n, openGateIndex: 1n, closeGateIndex: 2n, openDay: 100n, closeDay: 200n };
const previous = { number: 4999n, openGateIndex: -1n, closeGateIndex: 0n, openDay: -100n, closeDay: 0n };
yearMemory.rememberYear5000(17n, origin);
yearMemory.rememberAuthoritative(17n, next, 'next');
yearMemory.rememberAuthoritative(17n, previous, 'previous');
assert.equal(yearMemory.nearestAuthoritative(17n, 150n, 'next').number, 5001n);
assert.equal(yearMemory.nearestAuthoritative(17n, -50n, 'previous').number, 4999n);
assert.notEqual(yearMemory.nearestAuthoritative(17n, -50n, 'previous').number, 5001n);

const snapshot = production.stage58AccelerationSnapshot();
assert.ok(metric(snapshot, 'stage58.sauce54.hits') >= 1n);
assert.ok(metric(snapshot, 'stage58.sauce56.hits') >= 1n);
assert.ok(metric(snapshot, 'stage58.selection.hits') >= 3n);
assert.ok(metric(snapshot, 'stage58.selection.rejectionIterations') >= 1n);
assert.ok(metric(snapshot, 'stage58.selection.rejectionIterationsAvoided') >= 1n);
assert.ok(metric(snapshot, 'stage58.virtualDp.backendHits') >= 1n);
assert.ok(metric(snapshot, 'stage58.weavingDp.backendHits') >= 1n);
assert.ok(metric(snapshot, 'stage58.weavingDp.fastUnrankCalls') >= 1301n);
assert.ok(metric(snapshot, 'stage58.gates.checkpointHits') >= 3n);
assert.equal(metric(snapshot, 'stage58.sauce54.generationMismatch'), 0n);
assert.equal(metric(snapshot, 'stage58.sauce56.generationMismatch'), 0n);
assert.equal(snapshot.cacheSizes.weakRefSupported, typeof WeakRef === 'function');

console.log('STAGE 58 ACCELERATION PASS — legacy scars resta executable; sauce/gate/year/DP/rejection memories es bounded o weak e li fast weaving concorda exhaustivemen sur 1301 ranks.');
