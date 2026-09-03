'use strict';

const childProcess = require('child_process');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const tests = [
  'browser-stage01-compatibility.js',
  'browser-interface-service.js',
  'browser-consistency-cache.js',
  'browser-engine-client.js',
  'browser-worker-runtime.js',
  'browser-interface-contract.js',
  'browser-interface-black-box.js',
  'browser-i18n-locales.js',
  'browser-component-runtime.js',
];

for (const test of tests) {
  childProcess.execFileSync(process.execPath, [path.join(__dirname, test)], {
    cwd: ROOT,
    stdio: 'inherit',
  });
}

console.log('browser-interface-all: PASS');
