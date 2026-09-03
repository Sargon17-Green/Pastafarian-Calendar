'use strict';

const path = require('node:path');
const { createCacheStoreFromEnv } = require('./cache-store');
const { ServerCalendarEngine } = require('./calendar-engine');
const { createHttpServer } = require('./http-server');

async function main() {
  const root = path.resolve(__dirname, '..');
  const store = createCacheStoreFromEnv(process.env, root);
  const engine = new ServerCalendarEngine({
    store,
    fingerprint: process.env.PASTAFARI_SEMANTIC_FINGERPRINT || null,
  });
  await engine.initialize();

  const host = process.env.HOST || '0.0.0.0';
  const port = Number(process.env.PORT || 8080);
  const server = createHttpServer(engine, {
    corsOrigin: process.env.PASTAFARI_CORS_ORIGIN == null ? '*' : process.env.PASTAFARI_CORS_ORIGIN,
  });

  server.requestTimeout = Number(process.env.PASTAFARI_REQUEST_TIMEOUT_MS || 300000);
  server.listen(port, host, () => {
    process.stdout.write('Pastafari Stage 59 server listening on http://' + host + ':' + port + '\n');
    process.stdout.write('semantic fingerprint: ' + engine.fingerprint + '\n');
  });

  let closing = false;
  async function close(signal) {
    if (closing) return;
    closing = true;
    process.stdout.write('Closing after ' + signal + '...\n');
    await new Promise((resolve) => server.close(resolve));
    await engine.close();
  }
  process.on('SIGINT', () => close('SIGINT').then(() => process.exit(0)));
  process.on('SIGTERM', () => close('SIGTERM').then(() => process.exit(0)));
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write((error && error.stack) || String(error));
    process.stderr.write('\n');
    process.exitCode = 1;
  });
}

module.exports = Object.freeze({ main });
