'use strict';

const production = require('../src');

if (typeof global.gc !== 'function') {
  throw new Error('Stage 58 memory probe exige node --expose-gc.');
}

function nextTurn() {
  return new Promise((resolve) => setImmediate(resolve));
}

function memory() {
  const current = process.memoryUsage();
  return {
    rss: current.rss,
    heapTotal: current.heapTotal,
    heapUsed: current.heapUsed,
    external: current.external,
    arrayBuffers: current.arrayBuffers,
    maxRSSKB: process.resourceUsage().maxRSS
  };
}

(async () => {
  global.gc();
  await nextTurn();
  global.gc();
  await nextTurn();
  const before = memory();
  const calculationDay = -15048173n;
  const registry = new production.Stage54GateRegistry(production.sauceWithScarsStage56);
  const manager = new production.Stage57MonsterIntegrationManager(registry);
  let routed = manager.executeCalendarDate(calculationDay, calculationDay);
  const result = routed.result.map((value) => typeof value === 'bigint' ? value.toString() : value);
  const afterCall = memory();
  routed = null;
  // WeakRef targets es guaranteed vivant til li fine del current job; passa un turn ante demandar collection.
  await nextTurn();
  global.gc();
  await nextTurn();
  global.gc();
  await nextTurn();
  const afterGC = memory();
  const cacheSizes = production.stage58AccelerationSnapshot().cacheSizes;
  console.log(JSON.stringify({ before, afterCall, afterGC, result, cacheSizes }, (key, value) =>
    typeof value === 'bigint' ? value.toString() : value, 2));
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
