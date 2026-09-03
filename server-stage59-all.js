'use strict';

const { spawnSync } = require('node:child_process');
const path = require('node:path');

for (const file of ['server-stage59-cache.js', 'server-stage59-http.js']) {
  const result = spawnSync(process.execPath, [path.join(__dirname, file)], { stdio: 'inherit' });
  if (result.status !== 0) process.exit(result.status == null ? 1 : result.status);
}
console.log('server-stage59-all: PASS');
