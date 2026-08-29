'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const counts = normative.workCounts(f, f);
const stones = production.getStoneTableThroughLegacyBuilder();
const expectedByNearness = normative.buildHiddenDrops(counts, normative.STONES);
const execution = production.discovery05LegacyHiddenStorageThroughMonsterPath(f, f, counts, stones);
const storedSlots = execution.result.slice(1);

assert.deepEqual(
  storedSlots,
  expectedByNearness,
  'DISCOVERY 05 EXPECTED RED: li storage legacy es inversat e un access direct per k interpreta hidden7 quam hidden1.'
);
