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
  const counters = Object.freeze({ action: '1', target: '2', distance: '2', connection: '3', direction: '1' });
  const stream = (first, directionStep) => Object.freeze({ first: String(first), directionStep: String(directionStep) });
  const selection = (sourceLabel, output, gateIndex = null) => Object.freeze({
    id: 'selection-' + sourceLabel + '-' + String(gateIndex),
    gateIndex,
    sourceLabel,
    mode: 'short',
    familySize: '922',
    stream: stream('17', '1'),
    places: null,
    space: null,
    digits: null,
    acceptanceLimit: '170141183460469231731687303715884105000',
    firstCandidate: '170141183460469231731687303715884105001',
    initialWide: null,
    rejectionSteps: '1',
    acceptedCandidate: '170141183460469231731687303715884105000',
    output: String(output),
    rejectionEncoding: Object.freeze({ kind: 'answer-ring-run', start: '170141183460469231731687303715884105001', directionStep: '-1', count: '1' }),
  });
  const initialBowls = Object.freeze([1, 2, 3, 4, 5, 6].map((bowlId) => Object.freeze({
    bowlId,
    prime: String([17, 19, 23, 29, 31, 37][bowlId - 1]),
    seed: String(100 + bowlId),
    rawBeforeSave: String(200 + bowlId),
    output: String(300 + bowlId),
  })));
  const hiddenDrops = Object.freeze([Object.freeze({
    ordinal: 1,
    value: '41',
    coefficients: Object.freeze({ a: '1', b: '2', c: '3' }),
    stoneRow: Object.freeze({ w: '17', b: '29', s: '43', m: '71', r: '101' }),
    rawBeforeSave: '42',
    initial: '43',
    grinds: Object.freeze([Object.freeze({ ordinal: 1, grind: 1, before: '43', stoneKind: 'w', stoneValue: '17', after: '44' })]),
  })]);
  const visibleDrops = Object.freeze([Object.freeze({
    ordinal: 1,
    value: '51',
    priors: Object.freeze({ prev1: '41', prev3: '42', prev7: '43' }),
    stoneRow: Object.freeze({ w: '17', b: '29', s: '43', m: '71', r: '101' }),
    rawBeforeSave: '52',
    initial: '53',
    grinds: Object.freeze([Object.freeze({ ordinal: 1, grind: 1, before: '53', rule: Object.freeze({ kind: 'visible', a: '1', b: '2', c: '3', d: '4' }), stoneValue: '29', after: '54' })]),
  })]);
  const bowlRounds = Object.freeze([Object.freeze({
    ordinal: 1,
    drop: '51',
    order: Object.freeze([1, 2, 3, 4, 5, 6]),
    poursByPosition: Object.freeze(['1', '2', '3', '4', '5', '6']),
    beforeBowls: Object.freeze(['301', '302', '303', '304', '305', '306']),
    stoneRow: Object.freeze({ w: '17', b: '29', s: '43', m: '71', r: '101' }),
    positions: Object.freeze([Object.freeze({ position: 1, bowlId: 1, prevId: 6, nextId: 2, stoneKind: 'w', mixed: '400', rawBeforeSave: '401', output: '402' })]),
    afterBowls: Object.freeze(['402', '302', '303', '304', '305', '306']),
  })]);
  const postStirs = Object.freeze([Object.freeze({
    ordinal: 1,
    beforeBowls: Object.freeze(['402', '302', '303', '304', '305', '306']),
    rawBowlSum: '1922',
    savedOrderNumber: '2071',
    order: Object.freeze([1, 2, 3, 4, 5, 6]),
    positions: Object.freeze([Object.freeze({ position: 1, bowlId: 1, prevId: 6, nextId: 2, oldBowl: '402', oldPrev: '306', oldNext: '302', u: '2200', rawBeforeSave: '4840000', output: '4999' })]),
    afterBowls: Object.freeze(['4999', '302', '303', '304', '305', '306']),
  })]);
  const sauceRun = (id, kind) => Object.freeze({
    id,
    role: Object.freeze({ kind }),
    inputs: Object.freeze({ calculationDay: '-15055671', targetDay: '-15055671' }),
    stoneTableRef: 'stone-table-1',
    counters,
    hiddenDrops,
    visibleDrops,
    initialBowls,
    bowlRounds,
    bowlsAfterDrops: Object.freeze(['402', '302', '303', '304', '305', '306']),
    orderAtDrop46: Object.freeze([1, 2, 3, 4, 5, 6]),
    postStirs,
    finalBowls: Object.freeze(['4999', '302', '303', '304', '305', '306']),
  });
  const year5000 = Object.freeze({ number: '5000', openDay: '-15059693', firstDay: '-15059692', closeDay: '-15055294', openGateIndex: '-6', closeGateIndex: '1' });
  const finalYear = Object.freeze({ number: '5001', openDay: '-15055294', firstDay: '-15055293', closeDay: '-15050000', openGateIndex: '1', closeGateIndex: '8' });
  return Object.freeze({
    schemaVersion: '0.4.0',
    semanticProfile: 'PASTAFARIAN_STAGE57_STAGE56_RAW_SUM',
    inputs: Object.freeze({ calculationDay: '-15055671', targetDay: '-15055671' }),
    finalResult: Object.freeze({
      year: '5001',
      cutlet: Object.freeze({ canonicalIndex: 4, sourceName: 'Lagash' }),
      dayInCutlet: '762',
      month: Object.freeze({ canonicalIndex: 12, sourceName: 'oliban' }),
      dayInMonth: '105',
    }),
    chapters: Object.freeze([
      'inputs', 'gates', 'year-5000', 'year-walk', 'structure-sauce', 'cutlets', 'months', 'position', 'result',
    ].map((id) => Object.freeze({ id, kind: id, refs: Object.freeze([]) }))),
    artifacts: Object.freeze({
      stoneTable: Object.freeze({ id: 'stone-table-1', rows: Object.freeze([Object.freeze({ ordinal: 1, values: Object.freeze({ w: '17', b: '29', s: '43', m: '71', r: '101' }), transition: null })]) }),
      sauceRuns: Object.freeze([sauceRun('sauce-y5000', 'year-5000'), sauceRun('sauce-transition', 'year-transition'), sauceRun('sauce-structure', 'year-structure')]),
      gateNetwork: Object.freeze({
        gates: Object.freeze([Object.freeze({ index: '-1', day: '-15055671' })]),
        gaps: Object.freeze([Object.freeze({
          signedIndex: '-1', gap: '553', sauceRunId: 'sauce-1', detailCoverage: 'compact-stream-option-available',
          sauceSummary: Object.freeze({ counters, finalBowls: Object.freeze(['1', '2', '3', '4', '5', '6']), orderAtDrop46: Object.freeze([1, 2, 3, 4, 5, 6]) }),
        })]),
      }),
      selections: Object.freeze([
        selection('gate-gap', '512', '-1'),
        selection('YEAR_5000-semantic', '5000'),
        selection('cutlet-count', '1'),
        selection('cutlet-partition-semantic', '1'),
        selection('cutlet-names-distinct-rank', '4'),
        selection('month-count', '1'),
        selection('month-lengths', '1'),
        selection('month-weaving', '1'),
        selection('month-names-distinct-rank', '12'),
      ]),
      yearWalk: Object.freeze({
        year5000,
        authoritativeYears: Object.freeze([Object.freeze({ lineage: 'patch18', year: year5000 }), Object.freeze({ lineage: 'patch18', year: finalYear })]),
        transitions: Object.freeze([Object.freeze({ direction: 'next', fromYear: year5000, toYear: finalYear, sharedDay: '-15055294', sauceRunId: 'sauce-transition' })]),
        finalYear,
        interval: '(open,close]',
      }),
      structure: Object.freeze({
        sauceRunId: 'sauce-structure',
        year: Object.freeze({ number: '5001', openDay: '-15055294', closeDay: '-15050000' }),
        cutlets: Object.freeze({
          count: 1,
          partition: Object.freeze([1]),
          nameCanonicalIndices: Object.freeze([4]),
          countStream: stream('20', '1'),
          partitionStream: stream('21', '1'),
          partitionSelection: Object.freeze({ familyCount: '11', selectedRank: '1', requiredInternalGateOffset: '0' }),
          nameStream: stream('22', '1'),
          nameSelection: Object.freeze({ familyCount: '17', selectedRank: '4' }),
          items: Object.freeze([Object.freeze({ sourceName: 'Lagash', nameCanonicalIndex: 4, openGateIndex: '-1', closeGateIndex: '1', firstDay: '-15055671', lastDay: '-15055294' })]),
        }),
        months: Object.freeze({
          count: 1,
          lengths: Object.freeze([100]),
          weaving: Object.freeze([1, 1, 1]),
          nameCanonicalIndices: Object.freeze([12]),
          countStream: stream('30', '1'),
          lengthStream: stream('31', '1'),
          lengthSelection: Object.freeze({ familyCount: '45', selectedRank: '1' }),
          weavingStream: stream('32', '1'),
          weavingSelection: Object.freeze({ familyCount: '100', selectedRank: '1' }),
          nameStream: stream('33', '1'),
          nameSelection: Object.freeze({ familyCount: '47', selectedRank: '12' }),
          items: Object.freeze([Object.freeze({ slot: 1, length: 100, nameCanonicalIndex: 12, sourceName: 'oliban' })]),
        }),
      }),
      positioning: Object.freeze({ targetDay: '-15055671', year: finalYear, targetPositionInYear: 4022, monthId: 38, dayInCutlet: '762', dayInMonth: '105', cutletCanonicalIndex: 4, monthCanonicalIndex: 12 }),
    }),
    archaeology: Object.freeze([
      Object.freeze({ kind: 'stage56-raw-bowl-sum-corrective', semanticRule: 'post-stir-u-uses-raw-bowl-sum', historicalScarExecuted: true, historicalValuesIncluded: false }),
      Object.freeze({ kind: 'stage57-patch26-round-trip-ghost', mismatch: true, legacyGuardExecuted: true, legacyGuardPassed: false, semanticYear: finalYear, ghostYear: year5000 }),
    ]),
    measurement: Object.freeze({ totalSauceCallsObserved: 22, gateSauceCallsObserved: 20, selectionCallsObserved: 9 }),
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

function treeText(node) {
  if (!node || typeof node !== 'object') return '';
  return [node.textContent || '', ...((node.children || []).map(treeText))].join(' ');
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}

async function flush() {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

(async () => {
  assert.strictEqual(customElements.get('pastafari-cooking'), PastafariCookingElement);
  assert.deepStrictEqual(Array.from(PastafariCookingElement.observedAttributes), ['date', 'calculation-date', 'lang', 'open', 'live']);

  const calls = [];
  sharedService = {
    async getCookingTrace(targetJdn, calculationJdn, options = null) {
      calls.push({ targetJdn: String(targetJdn), calculationJdn: String(calculationJdn), options });
      if (options && typeof options.onGateSauceDetail === 'function') options.onGateSauceDetail(gateChunk());
      if (options && typeof options.onProgress === 'function') {
        options.onProgress({ sequence: 1, kind: 'run-start', elapsedMs: 0, durationMs: 0, payload: {} });
        options.onProgress({ sequence: 2, kind: 'bowl-round', elapsedMs: 4, durationMs: 4, payload: {
          sauceId: 'sauce-1', ordinal: 1, drop: '51', afterBowls: ['1', '2', '3', '4', '5', '6'],
        } });
        options.onProgress({ sequence: 3, kind: 'final-result-ready', elapsedMs: 5, durationMs: 1, payload: {
          year: '5001', cutletName: 'Lagash', dayInCutlet: '762', monthName: 'oliban', dayInMonth: '105',
        } });
      }
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
  assert.strictEqual(lazy.trace.schemaVersion, '0.4.0');
  assert.strictEqual(lazy._els.shell.getAttribute('aria-busy'), 'false');
  assert.strictEqual(lazy._els.nav.children.length, 0, 'streamed log replaces the old chapter navigation');
  assert.strictEqual(lazy._liveEntries.length, 3);
  assert(treeText(lazy._els.pane).includes('sauce-1') || treeText(lazy._els.pane).includes('Sauce'));
  assert.strictEqual(lazy._locale.code, 'ie');
  const targetJdn = axis.gregorianToJdn(axis.parseIsoDate('2026-09-11'));
  assert.strictEqual(calls[0].targetJdn, String(targetJdn));
  assert.strictEqual(calls[0].calculationJdn, String(targetJdn));
  assert(lazy.shadowRoot.innerHTML.includes('<dialog class="shell"'));
  assert(lazy.shadowRoot.innerHTML.includes('aria-modal="true"'));
  assert(lazy.shadowRoot.innerHTML.includes('aria-labelledby="pastafari-cooking-title"'));
  assert.strictEqual(lazy._els.shell.hasAttribute('open'), true);
  assert.strictEqual(lazy._els.close.focused, true);

  // Reopening the same completed trace reuses component-local trace state and
  // does not schedule another expensive semantic execution.
  lazy.close();
  assert.strictEqual(lazy.hasAttribute('open'), false);
  assert.strictEqual(lazy._els.shell.hasAttribute('open'), false);
  lazy.setAttribute('open', '');
  await flush();
  assert.strictEqual(calls.length, 1);
  assert.strictEqual(lazy._els.shell.hasAttribute('open'), true);
  assert.strictEqual(lazy.trace.schemaVersion, '0.4.0');

  // Live mode is an inline accumulating trace while the calculation runs. Finishing
  // hides the inline shell but retains the same log/trace for the existing button.
  const live = new PastafariCookingElement();
  live.setAttribute('lang', 'he');
  live.setAttribute('date', '2026-09-11');
  live.setAttribute('calculation-date', '2026-09-11');
  live.connectedCallback();
  live.beginLiveTrace();
  assert.strictEqual(live.hasAttribute('live'), true);
  assert.strictEqual(live._els.shell.hasAttribute('open'), true);
  live.appendLiveProgress({ sequence: 1, kind: 'stone-transition', elapsedMs: 2, durationMs: 2, payload: { ordinal: 2, after: { w: '17' } } });
  live.appendLiveProgress({ sequence: 2, kind: 'bowl-round', elapsedMs: 7, durationMs: 5, payload: { sauceId: 'sauce-1', ordinal: 1, drop: '51', afterBowls: ['1', '2', '3', '4', '5', '6'] } });
  live.appendLiveProgress({ sequence: 3, kind: 'post-stir', elapsedMs: 10, durationMs: 3, payload: { sauceId: 'sauce-1', stirIndex: 1, afterBowls: ['7', '8', '9', '10', '11', '12'] } });
  await flush();
  assert.strictEqual(live._liveEntries.length, 3);
  assert(treeText(live._els.pane).includes('סבב קערות'));
  assert(treeText(live._els.pane).includes('+5.0 ms'));
  assert(live.shadowRoot.innerHTML.includes('monster-meatball'));
  assert(live.shadowRoot.innerHTML.includes('sauce-drip'));
  live.finishLiveTrace(sampleTrace());
  assert.strictEqual(live.hasAttribute('live'), false);
  assert.strictEqual(live.trace.schemaVersion, '0.4.0');
  assert.strictEqual(live._liveState, 'complete');
  const beforeLiveOpen = calls.length;
  live.setAttribute('open', '');
  await flush();
  assert.strictEqual(calls.length, beforeLiveOpen, 'opening retained live trace must not rerun semantics');
  assert.strictEqual(live._els.shell.hasAttribute('open'), true);
  assert.strictEqual(live._els.nav.children.length, 0);
  assert(treeText(live._els.pane).includes('אבן'));

  // Locale switching rerenders the component without a semantic rerun.
  lazy.setAttribute('lang', 'he');
  assert.strictEqual(lazy._locale.code, 'he');
  assert.strictEqual(lazy.getAttribute('dir'), 'rtl');
  assert.strictEqual(lazy._els.close.textContent, 'סגור');
  assert.strictEqual(lazy._term('gate'), 'שער');
  assert.strictEqual(lazy._term('bowlRound'), 'סבב קערות');
  assert.strictEqual(calls.length, 1);

  // Every chapter exposes the semantic material already captured by the trace,
  // without reconstructing arithmetic in the presentation component.
  const chapterExpectations = {
    inputs: ['schemaVersion', '0.4.0', 'coverage', 'sameSemanticExecutionAsFinalResult'],
    gates: ['מרווח שער', '-15055671', 'gate-gap', 'rejectionEncoding'],
    'year-5000': ['(open,close]', 'YEAR_5000-semantic', '5000'],
    'year-walk': ['שנת המקור', 'שנת היעד', 'sharedDay', '5001'],
    'structure-sauce': ['קערות התחלה', 'prime', 'bowlsAfterDrops', 'finalBowls', 'calculationDay', 'stoneTableRef'],
    cutlets: ['cutlet-partition-semantic', 'cutlet-names-distinct-rank', 'לגש', 'sourceName'],
    months: ['month-lengths', 'month-weaving', 'month-names-distinct-rank', 'לבונה', 'positionInYear', '1 / 3'],
    position: ['השנה הסופית', 'targetPositionInYear', '5001'],
    result: ['שנה', 'קציצה', 'יום בקציצה', 'חודש', 'יום בחודש', 'ארכאולוגיה היסטורית', 'stage57-patch26-round-trip-ghost'],
  };
  for (const [chapter, needles] of Object.entries(chapterExpectations)) {
    lazy._activeChapter = chapter;
    lazy._renderChapter();
    const text = treeText(lazy._els.pane);
    for (const needle of needles) assert(text.includes(needle), chapter + ' manca ' + needle);
  }

  // The nested Sauce inspector exposes captured operands and rule metadata.
  lazy._activeChapter = 'structure-sauce';
  for (const [phase, needles] of [
    ['hidden', ['coefficients', 'stoneRow', 'stoneKind']],
    ['visible', ['stoneRow', 'rule', 'stoneValue']],
    ['bowls', ['stoneRow', 'prevId', 'nextId', 'mixed']],
    ['postStirs', ['oldBowl', 'oldPrev', 'oldNext', 'u', 'rawBowlSum']],
  ]) {
    lazy._sauceState.set('sauce-structure', { phase, index: 0 });
    lazy._renderChapter();
    const text = treeText(lazy._els.pane);
    for (const needle of needles) assert(text.includes(needle), phase + ' manca ' + needle);
  }

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

  // A pending gate-detail request cannot leave the component stuck after
  // close/reopen. Its eventual result is stale and may not populate gate detail.
  const staleDetail = deferred();
  let staleDetailOptions = null;
  let staleDetailCalls = 0;
  sharedService = {
    getCookingTrace(targetJdn, calculationJdn, options = null) {
      staleDetailCalls += 1;
      if (!options || typeof options.onGateSauceDetail !== 'function') return Promise.resolve(sampleTrace());
      staleDetailOptions = options;
      return staleDetail.promise;
    },
  };
  const race = new PastafariCookingElement();
  race.setAttribute('date', '2026-09-11');
  race.setAttribute('calculation-date', '2026-09-11');
  race.connectedCallback();
  race.setAttribute('open', '');
  await flush();
  assert.strictEqual(staleDetailCalls, 1);
  race._activeChapter = 'gates';
  const stalePromise = race._loadGateDetail('-1').catch(() => null);
  assert.strictEqual(race._gateDetailLoading, '-1');
  assert.strictEqual(staleDetailCalls, 2);
  race.close();
  race.setAttribute('open', '');
  await flush();
  assert.strictEqual(race._gateDetailLoading, null);
  assert.strictEqual(staleDetailCalls, 2, 'reopen of cached base trace must not rerun');
  staleDetailOptions.onGateSauceDetail(gateChunk());
  staleDetail.resolve(sampleTrace());
  await stalePromise;
  assert.strictEqual(race._gateDetailLoading, null);
  assert.strictEqual(race._gateDetails.has('-1'), false, 'stale detail must not commit');

  // A current gate-detail failure preserves the already useful base trace and
  // reports the failure inline instead of replacing the whole pane.
  let failCalls = 0;
  sharedService = {
    getCookingTrace(targetJdn, calculationJdn, options = null) {
      failCalls += 1;
      if (!options || typeof options.onGateSauceDetail !== 'function') return Promise.resolve(sampleTrace());
      return Promise.reject(new Error('synthetic gate detail failure'));
    },
  };
  const failure = new PastafariCookingElement();
  failure.setAttribute('lang', 'he');
  failure.setAttribute('date', '2026-09-11');
  failure.setAttribute('calculation-date', '2026-09-11');
  failure.connectedCallback();
  failure.setAttribute('open', '');
  await flush();
  failure._activeChapter = 'gates';
  await failure._loadGateDetail('-1').catch(() => null);
  assert.strictEqual(failCalls, 2);
  assert.strictEqual(failure.trace.schemaVersion, '0.4.0');
  assert.strictEqual(failure._els.error.hidden, true);
  assert.strictEqual(failure._els.pane.hidden, false);
  assert.strictEqual(failure._gateDetailLoading, null);
  assert.strictEqual(failure._gateDetailError.signedIndex, '-1');
  assert(treeText(failure._els.pane).includes('לא ניתן לחשב את המעקב.'));

  // Locale changes during a pending gate-detail execution do not invalidate or
  // rerun the semantic work; the completed detail renders in the newest locale.
  const localePending = deferred();
  let localeOptions = null;
  let localeCalls = 0;
  sharedService = {
    getCookingTrace(targetJdn, calculationJdn, options = null) {
      localeCalls += 1;
      if (!options || typeof options.onGateSauceDetail !== 'function') return Promise.resolve(sampleTrace());
      localeOptions = options;
      return localePending.promise;
    },
  };
  const localeRace = new PastafariCookingElement();
  localeRace.setAttribute('date', '2026-09-11');
  localeRace.setAttribute('calculation-date', '2026-09-11');
  localeRace.connectedCallback();
  localeRace.setAttribute('open', '');
  await flush();
  localeRace._activeChapter = 'gates';
  const localePromise = localeRace._loadGateDetail('-1');
  localeRace.setAttribute('lang', 'he');
  assert.strictEqual(localeCalls, 2);
  localeOptions.onGateSauceDetail(gateChunk());
  localePending.resolve(sampleTrace());
  await localePromise;
  assert.strictEqual(localeCalls, 2);
  assert.strictEqual(localeRace._locale.code, 'he');
  assert.strictEqual(localeRace._gateDetails.has('-1'), true);
  assert(treeText(localeRace._els.pane).includes('פירוט מלא של השער'));

  // Rapid input replacement while a base trace is pending: only the newest
  // generation may commit to the component.
  const firstBase = deferred();
  let baseCalls = 0;
  sharedService = {
    getCookingTrace() {
      baseCalls += 1;
      if (baseCalls === 1) return firstBase.promise;
      return Promise.resolve(sampleTrace());
    },
  };
  const inputRace = new PastafariCookingElement();
  inputRace.setAttribute('date', '2026-09-11');
  inputRace.setAttribute('calculation-date', '2026-09-11');
  inputRace.connectedCallback();
  inputRace.setAttribute('open', '');
  await flush();
  assert.strictEqual(baseCalls, 1);
  inputRace.setAttribute('date', '2026-09-12');
  await flush();
  assert.strictEqual(baseCalls, 2);
  assert.strictEqual(inputRace.trace.schemaVersion, '0.4.0');
  const committedKey = inputRace._traceInputKey;
  firstBase.resolve(sampleTrace());
  await flush();
  assert.strictEqual(inputRace._traceInputKey, committedKey, 'stale base trace replaced newer generation');

  // Disconnect/reconnect invalidates a still-pending base execution. A later
  // completion from the disconnected epoch cannot publish over the reconnect.
  const disconnectedBase = deferred();
  let reconnectCalls = 0;
  sharedService = {
    getCookingTrace() {
      reconnectCalls += 1;
      if (reconnectCalls === 1) return disconnectedBase.promise;
      return Promise.resolve(sampleTrace());
    },
  };
  const reconnect = new PastafariCookingElement();
  reconnect.setAttribute('date', '2026-09-11');
  reconnect.setAttribute('calculation-date', '2026-09-11');
  reconnect.setAttribute('open', '');
  reconnect.connectedCallback();
  await flush();
  assert.strictEqual(reconnectCalls, 1);
  reconnect.disconnectedCallback();
  reconnect.connectedCallback();
  await flush();
  assert.strictEqual(reconnectCalls, 2);
  assert.strictEqual(reconnect.trace.schemaVersion, '0.4.0');
  const reconnectKey = reconnect._traceInputKey;
  disconnectedBase.resolve(sampleTrace());
  await flush();
  assert.strictEqual(reconnect._traceInputKey, reconnectKey, 'disconnected stale trace committed after reconnect');

  console.log('browser-cooking-component: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
