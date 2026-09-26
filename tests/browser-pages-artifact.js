'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { preparePagesSite } = require('../scripts/prepare-pages-site');

const ROOT = path.resolve(__dirname, '..');
const DIST = path.join(ROOT, 'browser', 'dist');

function filesUnder(root) {
  const result = [];
  function walk(current, prefix) {
    const entries = fs.readdirSync(current, { withFileTypes: true })
      .slice()
      .sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      const full = path.join(current, entry.name);
      const relative = prefix ? prefix + '/' + entry.name : entry.name;
      if (entry.isDirectory()) walk(full, relative);
      else if (entry.isFile()) result.push(relative);
    }
  }
  walk(root, '');
  return result;
}

function sameBytes(left, right, label) {
  assert(
    fs.readFileSync(left).equals(fs.readFileSync(right)),
    'Li Pages artefact diverge del browser dist: ' + label,
  );
}

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pastafari-pages-'));

try {
  const site = preparePagesSite(tempRoot);
  const expectedDistFiles = filesUnder(DIST).filter((name) => name !== 'index.html');
  const actualDistFiles = filesUnder(path.join(site, 'dist'));

  assert.deepStrictEqual(
    actualDistFiles,
    expectedDistFiles,
    'Li Pages artefact deve mirrorar omni non-index file de browser/dist.',
  );

  sameBytes(
    path.join(DIST, 'index.html'),
    path.join(site, 'index.html'),
    'index.html',
  );

  for (const relative of expectedDistFiles) {
    sameBytes(
      path.join(DIST, ...relative.split('/')),
      path.join(site, 'dist', ...relative.split('/')),
      relative,
    );
  }

  assert(fs.existsSync(path.join(site, '.nojekyll')), 'Manca .nojekyll in li Pages artefact.');
  assert(!fs.existsSync(path.join(site, 'dist', 'index.html')), 'index.html ne deve duplicar se sub /dist/.');

  for (const relative of [
    'reverse-engine/pastafari-diagnostics.js',
    'reverse-engine/pastafari-calendar-fast.js',
    'reverse-engine/pastafari-constraints.js',
    'reverse-engine/pastafari-reverse-worker.js',
    'reverse-engine/pastafari-constraints-client.js',
  ]) {
    assert(
      actualDistFiles.includes(relative),
      'Manca li reverse-search artefact in Pages: ' + relative,
    );
  }

  process.stdout.write(
    'browser-pages-artifact: PASS (' + String(expectedDistFiles.length) + ' dist files mirrored exactmen)\n',
  );
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true });
}
