'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const BROWSER = path.join(ROOT, 'browser');
const DIST = path.join(BROWSER, 'dist');
const STANDALONE = path.join(BROWSER, 'standalone');
const BUILD_ID_PLACEHOLDER = '__PASTAFARI_BROWSER_BUILD_ID__';

const MAIN_PARTS = Object.freeze([
  'result-normalizer.js',
  'date-axis.js',
  'calendar-memory.js',
  'engine-client.js',
  'calendar-service.js',
  path.join('i18n', 'runtime.js'),
  'pastafari-date.js',
]);

const BUILD_INPUTS = Object.freeze([
  path.join('src', 'source-language-catalog.js'),
  path.join('src', 'index.js'),
  path.join('browser', 'result-normalizer.js'),
  path.join('browser', 'black-box-cutlet.js'),
  path.join('browser', 'pastafari-worker-entry.js'),
  path.join('browser', 'date-axis.js'),
  path.join('browser', 'calendar-memory.js'),
  path.join('browser', 'engine-client.js'),
  path.join('browser', 'calendar-service.js'),
  path.join('browser', 'i18n', 'locales.js'),
  path.join('browser', 'i18n', 'runtime.js'),
  path.join('browser', 'pastafari-date.js'),
  path.join('scripts', 'build-browser.js'),
]);

function read(relativePath) {
  return fs.readFileSync(path.join(ROOT, relativePath), 'utf8');
}

function fingerprintInputs(paths) {
  const hash = crypto.createHash('sha256');
  for (const relativePath of paths) {
    hash.update(relativePath.replace(/\\/g, '/'), 'utf8');
    hash.update('\0', 'utf8');
    hash.update(read(relativePath), 'utf8');
    hash.update('\0', 'utf8');
  }
  return hash.digest('hex').slice(0, 24);
}

function coreFingerprint() {
  const hash = crypto.createHash('sha256');
  hash.update(read(path.join('src', 'source-language-catalog.js')), 'utf8');
  hash.update('\0', 'utf8');
  hash.update(read(path.join('src', 'index.js')), 'utf8');
  return hash.digest('hex').slice(0, 24);
}

function buildFingerprint() {
  return fingerprintInputs(BUILD_INPUTS);
}

function coreWrapper() {
  const catalog = read(path.join('src', 'source-language-catalog.js'));
  const index = read(path.join('src', 'index.js'));
  const requires = Array.from(index.matchAll(/\brequire\(\s*['"]([^'"]+)['"]\s*\)/g), (match) => match[1]);
  const foreign = Array.from(new Set(requires.filter((name) => name !== './source-language-catalog')));
  if (foreign.length > 0) {
    throw new Error('Li browser-worker builder ne conosse ti additional core require(s): ' + foreign.join(', '));
  }

  return [
    "'use strict';",
    '(function (root) {',
    '  const modules = Object.create(null);',
    "  modules['./source-language-catalog'] = function (module, exports, require) {",
    catalog,
    '  };',
    "  modules['./index'] = function (module, exports, require) {",
    index,
    '  };',
    '  const cache = Object.create(null);',
    '  function localRequire(id) {',
    '    if (cache[id]) return cache[id].exports;',
    '    const factory = modules[id];',
    "    if (!factory) throw new Error('Ínconosset bundled core module: ' + id);",
    '    const module = { exports: {} };',
    '    cache[id] = module;',
    '    factory(module, module.exports, localRequire);',
    '    return module.exports;',
    '  }',
    "  root.PastafariBrowserCore = localRequire('./index');",
    "})(typeof globalThis === 'object' ? globalThis : self);",
    '',
  ].join('\n');
}

function workerConfig(buildId) {
  return [
    '(function (root) {',
    '  root.PastafariBrowserWorkerConfig = Object.freeze({',
    '    buildId: ' + JSON.stringify(buildId),
    '  });',
    "})(typeof globalThis === 'object' ? globalThis : self);",
  ].join('\n');
}

function workerBundle(buildId) {
  return [
    coreWrapper(),
    workerConfig(buildId),
    read(path.join('browser', 'result-normalizer.js')),
    read(path.join('browser', 'black-box-cutlet.js')),
    read(path.join('browser', 'pastafari-worker-entry.js')),
  ].join('\n\n');
}

function mainBundle(configSource) {
  const parts = [
    "'use strict';",
    configSource,
    read(path.join('browser', 'i18n', 'locales.js')),
  ];
  for (const relative of MAIN_PARTS) parts.push(read(path.join('browser', relative)));
  return parts.join('\n\n');
}

function standardConfig(cacheNamespace, buildId) {
  return [
    '(function (root) {',
    "  const script = typeof document === 'object' ? document.currentScript : null;",
    "  const base = script && script.src ? script.src : (typeof location === 'object' ? location.href : '');",
    '  const buildId = ' + JSON.stringify(buildId) + ';',
    '  root.PastafariBrowserConfig = Object.freeze({',
    "    workerUrl: new URL('pastafari-worker.js?v=' + encodeURIComponent(buildId), base).href,",
    '    cacheNamespace: ' + JSON.stringify(cacheNamespace) + ',',
    '    buildId,',
    '  });',
    "})(typeof globalThis === 'object' ? globalThis : this);",
  ].join('\n');
}

function standaloneConfig(workerSource, cacheNamespace, buildId) {
  return [
    '(function (root) {',
    '  root.PastafariBrowserConfig = Object.freeze({',
    '    workerSource: ' + JSON.stringify(workerSource) + ',',
    '    cacheNamespace: ' + JSON.stringify(cacheNamespace) + ',',
    '    buildId: ' + JSON.stringify(buildId) + ',',
    '  });',
    "})(typeof globalThis === 'object' ? globalThis : this);",
  ].join('\n');
}

function moduleFacade() {
  return [
    "import './pastafari-date.js';",
    'const api = globalThis.PastafariCalendarBrowser;',
    'export const getPastafariDateAsync = api.getPastafariDateAsync;',
    'export const getPastafariDate = api.getPastafariDate;',
    'export const PastafariDateElement = api.PastafariDateElement;',
    'export const installSharedCalendarService = api.installSharedCalendarService;',
    'export const installSharedCalendarMemory = api.installSharedCalendarMemory;',
    'export const buildId = api.buildId;',
    'export default api;',
    '',
  ].join('\n');
}

function standaloneSuffix() {
  return [
    '',
    '(function (root) {',
    '  root.PastafariCalendarStandalone = root.PastafariCalendarBrowser;',
    "})(typeof globalThis === 'object' ? globalThis : this);",
    '',
  ].join('\n');
}

function builtIndex(buildId) {
  const template = read('index.html');
  const occurrences = template.split(BUILD_ID_PLACEHOLDER).length - 1;
  if (occurrences !== 1) {
    throw new Error('index.html deve contener exactmen un build-ID placeholder.');
  }
  return template.replace(BUILD_ID_PLACEHOLDER, encodeURIComponent(buildId));
}

function main() {
  fs.mkdirSync(DIST, { recursive: true });
  fs.mkdirSync(STANDALONE, { recursive: true });

  const cacheNamespace = 'pc-browser-core-' + coreFingerprint();
  const buildId = buildFingerprint();
  const worker = workerBundle(buildId);
  const standard = mainBundle(standardConfig(cacheNamespace, buildId));
  const standalone = mainBundle(standaloneConfig(worker, cacheNamespace, buildId)) + standaloneSuffix();

  fs.writeFileSync(path.join(DIST, 'pastafari-worker.js'), worker, 'utf8');
  fs.writeFileSync(path.join(DIST, 'pastafari-date.js'), standard, 'utf8');
  fs.writeFileSync(path.join(DIST, 'pastafari-date.mjs'), moduleFacade(), 'utf8');
  fs.writeFileSync(path.join(DIST, 'index.html'), builtIndex(buildId), 'utf8');
  fs.writeFileSync(path.join(DIST, 'build-id.txt'), buildId + '\n', 'utf8');
  fs.writeFileSync(path.join(STANDALONE, 'pastafari-date.js'), standalone, 'utf8');
  fs.writeFileSync(path.join(STANDALONE, 'pastafari-date.min.js'), standalone, 'utf8');

  process.stdout.write('Construction del navigator: PASS.\n');
  process.stdout.write('Cache namespace: ' + cacheNamespace + '\n');
  process.stdout.write('Browser build ID: ' + buildId + '\n');
  process.stdout.write('Standard: browser/dist/index.html + pastafari-date.js + pastafari-worker.js + pastafari-date.mjs\n');
  process.stdout.write('Standalone: browser/standalone/pastafari-date.js\n');
}

try {
  main();
} catch (error) {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
}
