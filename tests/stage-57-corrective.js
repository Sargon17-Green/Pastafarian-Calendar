'use strict';

const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const production = require('../src');

assert.equal(typeof production.legacyStage54Patch26RoundTripGuard, 'function');
assert.equal(typeof production.stage57PreserveSequentialYearAfterPatch26Ghost, 'function');
assert.equal(typeof production.Stage57MonsterIntegrationManager, 'function');
assert.equal(typeof production.calendarDateSpaghettiStage56Historical, 'function');
assert.equal(typeof production.calendarDateSpaghettiStage56HistoricalWithContext, 'function');

const legacyGuardSource = production.legacyStage54Patch26RoundTripGuard.toString();
assert.match(legacyGuardSource, /Patch 26 final diverge del year resoluet per li sequential walk/);
assert.match(legacyGuardSource, /roundTrip\.openDay !== authoritative\.openDay/);
const walkSource = production.findYearByWalkPatch.toString();
assert.match(walkSource, /targetDay <= current\.openDay/);
const patch26Source = production.correctOpeningGateInterval.toString();
assert.match(patch26Source, /targetDay <= current\.openDay/);

const authoritative = { number: 5000n, openDay: 100n, firstDay: 101n, closeDay: 200n, openGateIndex: 10n, closeGateIndex: 20n };
const roundTrip = { number: 5000n, openDay: 90n, firstDay: 91n, closeDay: 200n, openGateIndex: 9n, closeGateIndex: 20n };
let guardError = null;
try {
  production.legacyStage54Patch26RoundTripGuard(authoritative, roundTrip);
} catch (error) {
  guardError = error;
}
assert(guardError instanceof production.BootstrapStageError);

const context = {
  stage57Patch26RoundTripDetourEnabled: true,
  diagnostics: []
};
const preserved = production.stage57PreserveSequentialYearAfterPatch26Ghost(context, authoritative, roundTrip, guardError);
assert.deepEqual(preserved, authoritative);
assert.equal(context.stage57Patch26RoundTripMismatch, true);
assert.equal(context.stage57LegacyGuardExecuted, true);
assert.equal(context.stage57LegacyGuardPassed, false);
assert.equal(context.stage57LegacyGuardError.name, 'BootstrapStageError');
assert.equal(context.stage57SemanticYearPreservedFromPatch18, true);
assert.deepEqual(context.stage57Patch26RoundTripGhost, roundTrip);
assert.deepEqual(context.stage57SemanticYear, authoritative);
assert.equal(context.diagnostics.at(-1).label, 'stage57-patch26-round-trip-ghost');

const disabled = { stage57Patch26RoundTripDetourEnabled: false, diagnostics: [] };
assert.throws(
  () => production.stage57PreserveSequentialYearAfterPatch26Ghost(disabled, authoritative, roundTrip, guardError),
  /Patch 26 final diverge del year resoluet per li sequential walk/
);

const src = fs.readFileSync(path.join(__dirname, '..', 'src', 'index.js'), 'utf8');
assert.match(src, /class Stage57MonsterIntegrationManager extends Stage56MonsterIntegrationManager/);
assert.match(src, /calendarDateSpaghettiStage56HistoricalWithContext/);
assert.doesNotMatch(src, /require\(['"]\.\.\/tests\//);

console.log('STAGE 57 CORE PASS: li guard historic resta real; li detour conserva Patch 18 semantic e li round-trip Patch 26 quam ghost.');
