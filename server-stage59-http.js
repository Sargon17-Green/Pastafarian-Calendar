'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const { MemoryCacheStore } = require('../server/cache-store');
const { ServerCalendarEngine } = require('../server/calendar-engine');
const { createHttpServer } = require('../server/http-server');

const fakeCore = path.resolve(__dirname, 'server-stage59-fake-core.js');

function request(port, method, requestPath, body) {
  return new Promise((resolve, reject) => {
    const http = require('node:http');
    const data = body == null ? null : JSON.stringify(body);
    const req = http.request({
      host: '127.0.0.1', port, method, path: requestPath,
      headers: data ? { 'content-type': 'application/json', 'content-length': Buffer.byteLength(data) } : {},
    }, (res) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => resolve({
        status: res.statusCode,
        headers: res.headers,
        body: JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}'),
      }));
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function main() {
  const engine = new ServerCalendarEngine({
    store: new MemoryCacheStore(), corePath: fakeCore, fingerprint: 'http-semantic-v1',
  });
  const server = createHttpServer(engine);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  try {
    const health = await request(port, 'GET', '/healthz');
    assert.equal(health.status, 200);
    assert.equal(health.body.fingerprint, 'http-semantic-v1');

    const first = await request(port, 'GET', '/v1/calendar?calculationDay=100&targetDay=105');
    assert.equal(first.status, 200);
    assert.equal(first.headers['x-pastafari-cache'], 'MISS');
    assert.deepEqual(first.body.tuple, ['5000', 'bronze', '6', 'sand', '32']);

    const second = await request(port, 'POST', '/v1/calendar', { calculationDay: '100', targetDay: '105' });
    assert.equal(second.status, 200);
    assert.equal(second.headers['x-pastafari-cache'], 'HIT');

    const invalid = await request(port, 'POST', '/v1/calendar', { calculationDay: '1.5', targetDay: '2' });
    assert.equal(invalid.status, 400);

    const metrics = await request(port, 'GET', '/metrics');
    assert.equal(metrics.status, 200);
    assert.equal(metrics.body.workerComputations, 1);
    assert.equal(metrics.body.finalHits, 1);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await engine.close();
  }
  console.log('server-stage59-http: PASS');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
