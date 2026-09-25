'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const childProcess = require('child_process');

const ROOT = path.resolve(__dirname, '..');

function list(directory) {
  const out = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) out.push(...list(full));
    else out.push(full);
  }
  return out;
}

const javascript = list(ROOT).filter((file) => file.endsWith('.js'));
assert(javascript.length >= 10);
for (const file of javascript) {
  const source = fs.readFileSync(file, 'utf8');
  const relative = path.relative(ROOT, file).replace(/\\/g, '/');
  if (relative.startsWith('browser/reverse-engine/')) {
    childProcess.execFileSync(process.execPath, ['--input-type=module', '--check'], {
      input: source,
      stdio: ['pipe', 'ignore', 'pipe'],
    });
  } else {
    new vm.Script(source, { filename: file });
  }
}

assert(!fs.existsSync(path.join(ROOT, 'DELTA_apply-package-json.mjs')));
assert(!fs.existsSync(path.join(ROOT, 'scripts', 'build-browser.mjs')));

console.log('browser-stage01-compatibility: PASS');
