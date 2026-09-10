'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');

class FakeElement {
  constructor(tagName = 'div') {
    this.tagName = String(tagName).toUpperCase();
    this.attributes = new Map();
    this.listeners = new Map();
    this.children = [];
    this.dataset = Object.create(null);
    this.hidden = false;
    this.disabled = false;
    this.textContent = '';
    this.className = '';
    this.focused = false;
  }
  setAttribute(name, value) { this.attributes.set(String(name), String(value)); }
  getAttribute(name) { return this.attributes.has(String(name)) ? this.attributes.get(String(name)) : null; }
  hasAttribute(name) { return this.attributes.has(String(name)); }
  removeAttribute(name) { this.attributes.delete(String(name)); }
  addEventListener(type, fn) { this.listeners.set(String(type), fn); }
  append(...items) {
    for (const item of items) {
      if (item && typeof item === 'object') item.parentElement = this;
      this.children.push(item);
    }
  }
  replaceChildren(...items) { this.children = []; this.append(...items); }
  focus() { this.focused = true; }
}

class FakeShadowRoot extends FakeElement {
  constructor() {
    super('#shadow-root');
    this.nodes = new Map();
    this._html = '';
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
    super('pastafari-cooking');
    this.shadowRoot = null;
    this.dispatched = [];
  }
  attachShadow() { this.shadowRoot = new FakeShadowRoot(); return this.shadowRoot; }
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
  dispatchEvent(event) { this.dispatched.push(event); return true; }
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
  createElement(tagName) { return new FakeElement(tagName); },
};
const registry = new Map();
const customElements = {
  define(name, ctor) { registry.set(name, ctor); },
  get(name) { return registry.get(name); },
};
const localStorage = {
  getItem() { return null; },
  setItem() {},
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
  localStorage,
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
};
load('browser/pastafari-cooking.js');

const { PastafariCookingElement } = sandbox.PastafariBrowserInternal.cookingComponent;
const axis = sandbox.PastafariBrowserInternal.dateAxis;

function sampleTrace() {
  return Object.freeze({
    schemaVersion: '0.3.0',
    semanticProfile: 'PASTAFARIAN_STAGE57_STAGE56_RAW_SUM',
    inputs: Object.freeze({ calculationDay: '-15055671', targetDay: '-15055671' }),
    finalResult: Object.freeze({
      year: '5000',
      cutlet: Object.freeze({ canonicalIndex: 4, sourceName: 'larice' }),
      dayInCutlet: '762',
      month: Object.freeze({ canonicalIndex: 12, sourceName: 'oliban' }),
      dayInMonth: '105',
    }),
    chapters: Object.freeze([
      'inputs', 'gates', 'year-5000', 'year-walk', 'structure-sauce', 'cutlets', 'months', 'position', 'result',
    ].map((id) => Object.freeze({ id, kind: id, refs: Object.freeze([]) }))),
    artifacts: Object.freeze({
      stoneTable: Object.freeze({ id: 'stone-table-1', rows: Object.freeze([]) }),
      sauceRuns: Object.freeze([]),
      gateNetwork: Object.freeze({
        gates: Object.freeze([]),
        gaps: Object.freeze([Object.freeze({
          signedIndex: '-1', gap: '553', sauceRunId: 'sauce-1', detailCoverage: 'compact-stream-option-available',
          sauceSummary: Object.freeze({
            counters: Object.freeze({ action: '1', target: '2', distance: '2', connection: '3', direction: '1' }),
            finalBowls: Object.freeze(['1', '2', '3', '4', '5', '6']),
            orderAtDrop46: Object.freeze([1, 2, 3, 4, 5, 6]),
          }),
        })]),
      }),
      yearWalk: Object.freeze({
        year5000: Object.freeze({ number: '5000', openDay: '-15059693', firstDay: '-15059692', closeDay: '-15055294', openGateIndex: '-6', closeGateIndex: '1' }),
        transitions: Object.freeze([]),
        finalYear: Object.freeze({ number: '5000', openDay: '-15059693', firstDay: '-15059692', closeDay: '-15055294', openGateIndex: '-6', closeGateIndex: '1' }),
      }),
      structure: Object.freeze({
        cutlets: Object.freeze({
          count: 1, partition: Object.freeze([1]), nameCanonicalIndices: Object.freeze([4]),
          items: Object.freeze([Object.freeze({ nameCanonicalIndex: 4, openGateIndex: '-1', closeGateIndex: '1', firstDay: '-15055671', lastDay: '-15055294' })]),
        }),
        months: Object.freeze({ count: 1, lengths: Object.freeze([100]), weaving: Object.freeze([1]), nameCanonicalIndices: Object.freeze([12]) }),
      }),
      positioning: Object.freeze({ targetDay: '-15055671', targetPositionInYear: 4022, monthId: 38, dayInCutlet: '762', dayInMonth: '105', cutletCanonicalIndex: 4, monthCanonicalIndex: 12 }),
    }),
    measurement: Object.freeze({ totalSauceCallsObserved: 22, gateSauceCallsObserved: 20 }),
    coverage: Object.freeze({ sameSemanticExecutionAsFinalResult: true, missingCoreCheckpoints: Object.freeze([]) }),
  });
}

function gateChunk() {
  return Object.freeze({
    id: 'sauce-1',
    role: Object.freeze({ kind: 'gate-gap', signedIndex: '-1' }),
    counters: Object.freeze({ action: '1', target: '2', distance: '2', connection: '3', direction: '1' }),
    hiddenDrops: Object.freeze([]),
    visibleDrops: Object.freeze([]),
    initialBowls: Object.freeze([]),
    bowlRounds: Object.freeze([]),
    postStirs: Object.freeze([]),
    finalBowls: Object.freeze(['1', '2', '3', '4', '5', '6']),
  });
}

async function flush() {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

(async () => {
  assert.strictEqual(customElements.get('pastafari-cooking'), PastafariCookingElement);
  assert.deepStrictEqual(Array.from(PastafariCookingElement.observedAttributes), ['date', 'calculation-date', 'lang', 'open']);

  const calls = [];
  sharedService = {
    async getCookingTrace(targetJdn, calculationJdn, options = null) {
      calls.push({ targetJdn: String(targetJdn), calculationJdn: String(calculationJdn), options });
      if (options && typeof options.onGateSauceDetail === 'function') options.onGateSauceDetail(gateChunk());
      return sampleTrace();
    },
  };

  // Closed is truly lazy: connecting it does not ask the Worker for a trace.
  const lazy = new PastafariCookingElement();
  lazy.setAttribute('date', '2026-09-11');
  lazy.setAttribute('calculation-date', '2026-09-11');
  lazy.connectedCallback();
  await flush();
  assert.strictEqual(calls.length, 0);

  lazy.setAttribute('open', '');
  await flush();
  assert.strictEqual(calls.length, 1);
  assert.strictEqual(lazy.trace.schemaVersion, '0.3.0');
  assert.strictEqual(lazy._els.shell.getAttribute('aria-busy'), 'false');
  assert.strictEqual(lazy._els.nav.children.length, 9);
  assert.strictEqual(lazy._locale.code, 'ie');
  const targetJdn = axis.gregorianToJdn(axis.parseIsoDate('2026-09-11'));
  assert.strictEqual(calls[0].targetJdn, String(targetJdn));
  assert.strictEqual(calls[0].calculationJdn, String(targetJdn));
  assert(lazy.shadowRoot.innerHTML.includes('role="region"'));
  assert(lazy.shadowRoot.innerHTML.includes('aria-labelledby="pastafari-cooking-title"'));

  // Reopening the same completed trace reuses component-local trace state and
  // does not schedule another expensive semantic execution.
  lazy.close();
  assert.strictEqual(lazy.hasAttribute('open'), false);
  lazy.setAttribute('open', '');
  await flush();
  assert.strictEqual(calls.length, 1);
  assert.strictEqual(lazy.trace.schemaVersion, '0.3.0');

  // Locale switching rerenders the component without a semantic rerun.
  lazy.setAttribute('lang', 'he');
  assert.strictEqual(lazy._locale.code, 'he');
  assert.strictEqual(lazy.getAttribute('dir'), 'rtl');
  assert.strictEqual(lazy._els.close.textContent, 'סגור');
  assert.strictEqual(lazy._term('gate'), 'שער');
  assert.strictEqual(lazy._term('bowlRound'), 'סבב קערות');
  assert.strictEqual(calls.length, 1);

  // Gate detail is a new semantic execution explicitly scoped to that gate;
  // its chunk and replacement final trace belong to the same execution.
  lazy._activeChapter = 'gates';
  lazy._renderChapter();
  const chunk = await lazy._loadGateDetail('-1');
  assert(chunk);
  assert.strictEqual(calls.length, 2);
  assert.deepStrictEqual(Array.from(calls[1].options.gateDetailGateIndices, String), ['-1']);
  assert.strictEqual(typeof calls[1].options.onGateSauceDetail, 'function');
  assert.strictEqual(lazy._gateDetails.get('-1').role.signedIndex, '-1');
  assert.strictEqual(lazy.trace.finalResult.month.sourceName, 'oliban');

  // Exact large integers are collapsed by default and expandable in place.
  const exact = lazy._exactNode('170141183460469231731687303715884105727');
  assert(exact.textContent.includes('…'));
  exact.listeners.get('click')();
  assert.strictEqual(exact.textContent, '170141183460469231731687303715884105727');
  exact.listeners.get('click')();
  assert(exact.textContent.includes('…'));

  // A changed input pair must not reuse the old trace.
  const beforeChangedInput = calls.length;
  lazy.close();
  lazy.setAttribute('date', '2026-09-12');
  lazy.setAttribute('open', '');
  await flush();
  assert.strictEqual(calls.length, beforeChangedInput + 1);

  let prevented = false;
  lazy.shadowRoot.listeners.get('keydown')({ key: 'Escape', preventDefault() { prevented = true; } });
  assert.strictEqual(prevented, true);
  assert.strictEqual(lazy.hasAttribute('open'), false);
  assert(lazy.dispatched.some((event) => event.type === 'pastafari-cooking-close'));

  console.log('browser-cooking-component: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
