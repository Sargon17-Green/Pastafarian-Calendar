'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const codec = require('../server/cache-codec');
const { MemoryCacheStore, FileCacheStore } = require('../server/cache-store');
const { ServerCalendarEngine } = require('../server/calendar-engine');

const fakeCore = path.resolve(__dirname, 'server-stage59-fake-core.js');

async function main() {
  const sample = { big: 12345678901234567890n, list: [1n, 'x'], map: new Map([['k', 9n]]) };
  const decoded = codec.decode(codec.encode(sample));
  assert.equal(decoded.big, sample.big);
  assert.equal(decoded.list[0], 1n);
  assert.equal(decoded.map.get('k'), 9n);

  const memory = new MemoryCacheStore();
  const engine = new ServerCalendarEngine({ store: memory, corePath: fakeCore, fingerprint: 'test-semantic-v1' });
  const concurrent = await Promise.all([
    engine.convert('100', '105'),
    engine.convert('100', '105'),
    engine.convert('100', '105'),
  ]);
  assert.equal(engine.snapshotMetrics().workerComputations, 1);
  assert.equal(concurrent.filter((value) => value.cache === 'MISS').length, 1);
  assert.equal(concurrent.filter((value) => value.cache === 'COALESCED').length, 2);
  assert.deepEqual(concurrent[0].result, [5000n, 'bronze', 6n, 'sand', 32n]);

  const hit = await engine.convert('100', '105');
  assert.equal(hit.cache, 'HIT');
  assert.equal(engine.snapshotMetrics().workerComputations, 1);
  await engine.close();

  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'pastafari-stage59-'));
  const cacheFile = path.join(tmp, 'cache.json');
  const first = new ServerCalendarEngine({
    store: new FileCacheStore(cacheFile), corePath: fakeCore, fingerprint: 'restart-semantic-v1',
  });
  const firstResult = await first.convert('200', '203');
  assert.equal(firstResult.cache, 'MISS');
  assert.ok(firstResult.bridgeStatus && firstResult.bridgeStatus.scopes['gate-days'].entries >= 1);
  await first.close();

  const second = new ServerCalendarEngine({
    store: new FileCacheStore(cacheFile), corePath: fakeCore, fingerprint: 'restart-semantic-v1',
  });
  await second.initialize();
  assert.ok(second.snapshotMetrics().intermediateSnapshotsLoaded >= 6, 'Stage 58 snapshots must hydrate after restart');
  const restartHit = await second.convert('200', '203');
  assert.equal(restartHit.cache, 'HIT');
  assert.equal(second.snapshotMetrics().workerComputations, 0);
  const nearbyMiss = await second.convert('200', '204');
  assert.equal(nearbyMiss.cache, 'MISS');
  assert.ok(nearbyMiss.bridgeStatus.hydratedEntries > 0, 'worker must begin with persisted intermediate entries');
  assert.ok(nearbyMiss.bridgeStatus.scopes['selection-results'].entries >= 1, 'selection cache must persist');
  assert.ok(nearbyMiss.bridgeStatus.scopes['sauce-stage56'].entries >= 1, 'Stage 56 sauce cache must persist');
  await second.close();

  const isolated = new ServerCalendarEngine({
    store: new FileCacheStore(cacheFile), corePath: fakeCore, fingerprint: 'restart-semantic-v2',
  });
  const isolatedResult = await isolated.convert('200', '203');
  assert.equal(isolatedResult.cache, 'MISS', 'semantic fingerprint must isolate stale cache namespaces');
  await isolated.close();

  const failures = new ServerCalendarEngine({ store: new MemoryCacheStore(), corePath: fakeCore, fingerprint: 'fail-v1' });
  await assert.rejects(() => failures.convert('1', '-999'), /FAKE_FAILURE/);
  await assert.rejects(() => failures.convert('1', '-999'), /FAKE_FAILURE/);
  assert.equal(failures.snapshotMetrics().workerComputations, 2, 'failed calls must never populate final cache');
  assert.equal(failures.snapshotMetrics().finalHits, 0);
  await failures.convert('1', '2');
  for (const raw of failures.store.values.values()) {
    assert.ok(!String(raw).includes('-999'), 'failed-call intermediate state must be rolled back before later snapshots');
  }
  await failures.close();

  await fs.rm(tmp, { recursive: true, force: true });
  console.log('server-stage59-cache: PASS');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
