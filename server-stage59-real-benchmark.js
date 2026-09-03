'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { FileCacheStore } = require('../server/cache-store');
const { ServerCalendarEngine } = require('../server/calendar-engine');

async function timed(label, fn) {
  const start = process.hrtime.bigint();
  const value = await fn();
  const elapsedMs = Number(process.hrtime.bigint() - start) / 1e6;
  console.log(JSON.stringify({ label, elapsedMs, cache: value.cache, result: value.result.map(String) }));
  return value;
}

async function main() {
  if (!process.argv.includes('--run-heavy')) {
    console.log('server-stage59-real-benchmark: SKIP (use --run-heavy)');
    return;
  }
  const corePath = path.resolve(__dirname, '..', 'src', 'index.js');
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'pastafari-stage59-real-'));
  const cacheFile = path.join(tmp, 'cache.json');
  try {
    const first = new ServerCalendarEngine({ store: new FileCacheStore(cacheFile), corePath });
    const cold = await timed('cold-exact', () => first.convert('739862', '739862'));
    assert.deepEqual(cold.result, [5000n, 'bronze', 677n, 'sand', 32n]);
    const warm = await timed('warm-final-hit', () => first.convert('739862', '739862'));
    assert.equal(warm.cache, 'HIT');
    await first.close();

    const restarted = new ServerCalendarEngine({ store: new FileCacheStore(cacheFile), corePath });
    const restartHit = await timed('restart-final-hit', () => restarted.convert('739862', '739862'));
    assert.equal(restartHit.cache, 'HIT');
    const nearby = await timed('restart-nearby-with-stage58-hydration', () => restarted.convert('739862', '739863'));
    console.log(JSON.stringify({ metrics: restarted.snapshotMetrics() }));
    await restarted.close();

    const directCore = require(corePath);
    const directStart = process.hrtime.bigint();
    const directNearby = directCore.calendarDateSpaghetti(739862n, 739863n);
    const directMs = Number(process.hrtime.bigint() - directStart) / 1e6;
    console.log(JSON.stringify({ label: 'fresh-direct-nearby-control', elapsedMs: directMs, result: directNearby.map(String) }));
    assert.deepEqual(nearby.result, directNearby, 'hydrated intermediate cache must preserve exact semantics');
  } finally {
    await fs.rm(tmp, { recursive: true, force: true });
  }
  console.log('server-stage59-real-benchmark: PASS');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
