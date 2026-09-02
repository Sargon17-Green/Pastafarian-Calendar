'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');

class FakeStyle {
  constructor() { this.values = new Map(); }
  setProperty(name, value) { this.values.set(name, String(value)); }
}

class FakeElement {
  constructor(tagName = 'div') {
    this.tagName = String(tagName).toUpperCase();
    this.attributes = new Map();
    this.listeners = new Map();
    this.children = [];
    this.dataset = Object.create(null);
    this.style = new FakeStyle();
    this.hidden = false;
    this.selected = false;
    this.textContent = '';
    this.className = '';
    this.scrollTop = 0;
    this.scrollHeight = 1000;
    this.clientHeight = 500;
  }
  setAttribute(name, value) { this.attributes.set(String(name), String(value)); }
  getAttribute(name) { return this.attributes.has(String(name)) ? this.attributes.get(String(name)) : null; }
  hasAttribute(name) { return this.attributes.has(String(name)); }
  removeAttribute(name) { this.attributes.delete(String(name)); }
  addEventListener(type, fn) { this.listeners.set(type, fn); }
  append(...items) { this.children.push(...items); }
  replaceChildren(...items) { this.children = items; }
  querySelector() { return null; }
  querySelectorAll() { return []; }
  getBoundingClientRect() { return { top: 0, left: 0, width: 100, height: 20 }; }
  scrollIntoView() {}
  closest() { return null; }
  showModal() { this.setAttribute('open', ''); }
  close() { this.removeAttribute('open'); }
}

class FakeShadowRoot extends FakeElement {
  constructor() {
    super('#shadow-root');
    this._html = '';
    this.nodes = new Map();
  }
  set innerHTML(value) { this._html = String(value); }
  get innerHTML() { return this._html; }
  querySelector(selector) {
    if (!this.nodes.has(selector)) this.nodes.set(selector, new FakeElement(selector));
    return this.nodes.get(selector);
  }
}

class FakeHTMLElement extends FakeElement {
  constructor() {
    super('pastafari-date');
    this.shadowRoot = null;
    this.dispatched = [];
  }
  attachShadow() {
    this.shadowRoot = new FakeShadowRoot();
    return this.shadowRoot;
  }
  setAttribute(name, value) {
    const key = String(name);
    const oldValue = this.getAttribute(key);
    super.setAttribute(key, value);
    const observed = this.constructor.observedAttributes || [];
    if (observed.includes(key) && oldValue !== String(value) && typeof this.attributeChangedCallback === 'function') {
      this.attributeChangedCallback(key, oldValue, String(value));
    }
  }
  removeAttribute(name) {
    const key = String(name);
    const oldValue = this.getAttribute(key);
    const existed = this.hasAttribute(key);
    super.removeAttribute(key);
    const observed = this.constructor.observedAttributes || [];
    if (existed && observed.includes(key) && typeof this.attributeChangedCallback === 'function') {
      this.attributeChangedCallback(key, oldValue, null);
    }
  }
  dispatchEvent(event) {
    this.dispatched.push(event);
    return true;
  }
}

class FakeCustomEvent {
  constructor(type, init = {}) {
    this.type = type;
    this.bubbles = init.bubbles === true;
    this.composed = init.composed === true;
    this.detail = init.detail;
  }
}

const document = {
  createDocumentFragment() { return new FakeElement('#fragment'); },
  createElement(tagName) { return new FakeElement(tagName); },
};
const registry = new Map();
const customElements = {
  define(name, ctor) { registry.set(name, ctor); },
  get(name) { return registry.get(name); },
};

let sharedService = null;
const sandbox = {
  console: { log() {}, error() {} },
  Intl,
  Date,
  Promise,
  Map,
  Set,
  BigInt,
  Object,
  Array,
  String,
  Number,
  RegExp,
  Error,
  TypeError,
  RangeError,
  HTMLElement: FakeHTMLElement,
  CustomEvent: FakeCustomEvent,
  document,
  customElements,
  navigator: { languages: ['ie'] },
  CSS: { escape(value) { return String(value); } },
  queueMicrotask,
  setTimeout,
  clearTimeout,
  globalThis: null,
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);

function load(relativePath) {
  vm.runInContext(fs.readFileSync(path.join(ROOT, relativePath), 'utf8'), sandbox, { filename: relativePath });
}

load('browser/result-normalizer.js');
load('browser/date-axis.js');
load('browser/i18n/locales.js');
load('browser/i18n/runtime.js');

sandbox.PastafariBrowserInternal.calendarService = {
  getSharedCalendarService() { return sharedService; },
  installSharedCalendarService(service) { sharedService = service; return service; },
  installSharedCalendarMemory() { throw new Error('not used'); },
};
load('browser/pastafari-date.js');

const { PastafariDateElement } = sandbox.PastafariCalendarBrowser;
const axis = sandbox.PastafariBrowserInternal.dateAxis;

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}

function valueFor(targetJdn) {
  const even = BigInt(targetJdn) % 2n === 0n;
  return Object.freeze({
    year: '5000',
    cutletName: even ? 'larice' : 'bronze',
    dayInCutlet: 1,
    monthName: even ? 'leopard' : 'argile',
    dayInMonth: 1,
  });
}

function viewFor(targetJdn) {
  const jdn = BigInt(targetJdn);
  const value = valueFor(jdn);
  return Object.freeze({
    selectedJdn: jdn,
    selectedIndex: 0,
    startJdn: jdn,
    endJdn: jdn,
    previousCutletJdn: jdn - 1n,
    nextCutletJdn: jdn + 1n,
    year: value.year,
    cutletName: value.cutletName,
    days: Object.freeze([Object.freeze({ jdn, ...value })]),
  });
}

async function flush() {
  await Promise.resolve();
  await Promise.resolve();
}

(async () => {
  // Rapid attribute changes: only the newest generation may commit or publish.
  const pending = new Map();
  sharedService = {
    convert(targetJdn) {
      const key = String(targetJdn);
      const item = deferred();
      pending.set(key, item);
      return item.promise;
    },
    async getCutletView(targetJdn) { return viewFor(targetJdn); },
    async retry() {},
  };
  const race = new PastafariDateElement();
  race._primeAdjacent = () => {};
  race.setAttribute('date', '2026-09-02');
  race.connectedCallback();
  await flush();
  const firstJdn = axis.gregorianToJdn(axis.parseIsoDate('2026-09-02'));
  assert(pending.has(String(firstJdn)));

  race.setAttribute('date', '2026-09-03');
  await flush();
  const secondJdn = axis.gregorianToJdn(axis.parseIsoDate('2026-09-03'));
  assert(pending.has(String(secondJdn)));

  pending.get(String(secondJdn)).resolve(valueFor(secondJdn));
  await flush();
  const readyValue = await race.ready;
  assert.strictEqual(race.value.cutletName, valueFor(secondJdn).cutletName);
  assert.strictEqual(readyValue.cutletName, valueFor(secondJdn).cutletName);
  assert.strictEqual(race.dispatched.length, 1);
  assert.strictEqual(race.dispatched[0].type, 'pastafari-change');
  assert.strictEqual(race.dispatched[0].bubbles, true);
  assert.strictEqual(race.dispatched[0].composed, true);
  assert.strictEqual(race.dispatched[0].detail.cutletName, valueFor(secondJdn).cutletName);

  pending.get(String(firstJdn)).resolve(valueFor(firstJdn));
  await flush();
  assert.strictEqual(race.value.cutletName, valueFor(secondJdn).cutletName, 'stale result replaced current value');
  assert.strictEqual(race.dispatched.length, 1, 'stale result published an event');

  // Disconnect invalidates a pending generation. Reconnect can safely start anew.
  const disconnectPending = deferred();
  let disconnectCalls = 0;
  sharedService = {
    convert(targetJdn) {
      disconnectCalls += 1;
      if (disconnectCalls === 1) return disconnectPending.promise;
      return Promise.resolve(valueFor(targetJdn));
    },
    async getCutletView(targetJdn) { return viewFor(targetJdn); },
    async retry() {},
  };
  const reconnect = new PastafariDateElement();
  reconnect._primeAdjacent = () => {};
  reconnect.setAttribute('date', '2026-09-04');
  reconnect.connectedCallback();
  await flush();
  reconnect.disconnectedCallback();
  disconnectPending.resolve(valueFor(axis.gregorianToJdn(axis.parseIsoDate('2026-09-04'))));
  await flush();
  assert.strictEqual(reconnect.dispatched.length, 0);
  reconnect.connectedCallback();
  await flush();
  await flush();
  assert.strictEqual(reconnect.dispatched.length, 1);

  // Headless conversion is data-only and does not ask for a cutlet view.
  let headlessViews = 0;
  sharedService = {
    async convert(targetJdn) { return valueFor(targetJdn); },
    async getCutletView() { headlessViews += 1; throw new Error('headless must not request a view'); },
    async retry() {},
  };
  const headless = new PastafariDateElement();
  headless.setAttribute('date', '2026-09-05');
  headless.setAttribute('headless', '');
  const headlessValue = await headless.refresh();
  assert(headlessValue);
  assert.strictEqual(headlessViews, 0);
  assert.strictEqual(headless.dispatched.length, 1);

  // Invalid external date attributes reach the visible error state, while ready
  // remains usable and resolves after a later successful refresh.
  sharedService = {
    async convert(targetJdn) { return valueFor(targetJdn); },
    async getCutletView(targetJdn) { return viewFor(targetJdn); },
    async retry() {},
  };
  const recover = new PastafariDateElement();
  recover._primeAdjacent = () => {};
  recover.setAttribute('date', 'not-a-date');
  await assert.rejects(() => recover.refresh());
  assert.strictEqual(recover._els.error.hidden, false);
  assert.strictEqual(recover._els.calendar.getAttribute('aria-busy'), 'false');
  assert.strictEqual(recover._els.errorMessage.textContent, recover._t('search.invalid'));
  recover.setAttribute('date', '2026-09-06');
  const recovered = await recover.refresh();
  const recoveredReady = await recover.ready;
  assert.strictEqual(recoveredReady.cutletName, recovered.cutletName);

  // Language changes rerender presentation only. Raw public value remains the
  // exact Interlingue semantic result from the core.
  const language = new PastafariDateElement();
  language._primeAdjacent = () => {};
  language.setAttribute('date', '2026-09-06');
  await language.refresh();
  const rawName = language.value.cutletName;
  language._connected = true;
  language.setAttribute('lang', 'he-IL');
  assert.strictEqual(language.getAttribute('dir'), 'rtl');
  assert.strictEqual(language.value.cutletName, rawName);
  if (rawName === 'larice') assert(language._els.summary.textContent.includes('ארזית'));

  // Back to today resets both externally visible date inputs and coalesces the
  // resulting refresh through the connection epoch queue.
  language.setAttribute('calculation-date', '2026-09-01');
  language._goToday();
  assert.strictEqual(language.hasAttribute('date'), false);
  assert.strictEqual(language.hasAttribute('calculation-date'), false);

  // Presentation-suppression attributes close any already-open editor. This
  // prevents a modal from surviving after no-editor/headless makes that UI
  // unavailable. Removing no-editor itself is presentation-only.
  const suppression = new PastafariDateElement();
  suppression._primeAdjacent = () => {};
  suppression._connected = true;
  suppression._els.dialog.showModal();
  assert.strictEqual(suppression._els.dialog.hasAttribute('open'), true);
  suppression.setAttribute('no-editor', '');
  assert.strictEqual(suppression._els.dialog.hasAttribute('open'), false);
  suppression.removeAttribute('no-editor');
  suppression._els.dialog.showModal();
  suppression.setAttribute('headless', '');
  assert.strictEqual(suppression._els.dialog.hasAttribute('open'), false);

  // Month appearance is deterministic from the current semantic source name,
  // independent of locale and rendering order. Day cards keep the original
  // editorial seven-position visual rhythm while remaining non-interactive.
  const themed = new PastafariDateElement();
  themed._locale = sandbox.PastafariBrowserInternal.i18n.resolveLocale('en', []);
  themed._targetJdn = 100n;
  const themeDay = Object.freeze({
    jdn: 100n, year: '5000', cutletName: 'larice', dayInCutlet: 8, monthName: 'leopard', dayInMonth: 3,
  });
  const runA = themed._renderMonthRun([themeDay]);
  const runB = themed._renderMonthRun([themeDay]);
  assert.strictEqual(runA.style.values.get('--month-edge'), runB.style.values.get('--month-edge'));
  assert.strictEqual(runA.style.values.get('--month-bg'), runB.style.values.get('--month-bg'));
  const grid = runA.children[1];
  const card = grid.children[0];
  assert.strictEqual(card.tagName, 'ARTICLE');
  assert(card.className.includes('mod1'));
  assert.strictEqual(card.style.values.get('--month-edge'), runA.style.values.get('--month-edge'));

  console.log('browser-component-runtime: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
