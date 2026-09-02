'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const BROWSER = path.join(ROOT, 'browser');
const DIST = path.join(BROWSER, 'dist');
const STANDALONE = path.join(BROWSER, 'standalone');

const MAIN_PARTS = Object.freeze([
  'result-normalizer.js',
  'date-axis.js',
  'calendar-memory.js',
  'engine-client.js',
  'calendar-service.js',
  path.join('i18n', 'runtime.js'),
  'pastafari-date.js',
]);

function read(relativePath) {
  return fs.readFileSync(path.join(ROOT, relativePath), 'utf8');
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

function workerBundle() {
  return [
    coreWrapper(),
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

function standardConfig() {
  return [
    '(function (root) {',
    "  const script = typeof document === 'object' ? document.currentScript : null;",
    "  const base = script && script.src ? script.src : (typeof location === 'object' ? location.href : '');",
    "  root.PastafariBrowserConfig = Object.freeze({ workerUrl: new URL('pastafari-worker.js', base).href });",
    "})(typeof globalThis === 'object' ? globalThis : this);",
  ].join('\n');
}

function standaloneConfig(workerSource) {
  return [
    '(function (root) {',
    '  root.PastafariBrowserConfig = Object.freeze({ workerSource: ' + JSON.stringify(workerSource) + ' });',
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

function main() {
  fs.mkdirSync(DIST, { recursive: true });
  fs.mkdirSync(STANDALONE, { recursive: true });

  const worker = workerBundle();
  const standard = mainBundle(standardConfig());
  const standalone = mainBundle(standaloneConfig(worker)) + standaloneSuffix();

  fs.writeFileSync(path.join(DIST, 'pastafari-worker.js'), worker, 'utf8');
  fs.writeFileSync(path.join(DIST, 'pastafari-date.js'), standard, 'utf8');
  fs.writeFileSync(path.join(DIST, 'pastafari-date.mjs'), moduleFacade(), 'utf8');
  fs.writeFileSync(path.join(STANDALONE, 'pastafari-date.js'), standalone, 'utf8');
  fs.writeFileSync(path.join(STANDALONE, 'pastafari-date.min.js'), standalone, 'utf8');

  process.stdout.write('Construction del navigator: PASS.\n');
  process.stdout.write('Standard: browser/dist/pastafari-date.js + pastafari-worker.js + pastafari-date.mjs\n');
  process.stdout.write('Standalone: browser/standalone/pastafari-date.js\n');
}

try {
  main();
} catch (error) {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
}
