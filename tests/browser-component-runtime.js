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
  append(...items) {
    for (const item of items) {
      if (item && typeof item === 'object') item.parentElement = this;
      this.children.push(item);
    }
  }
  replaceChildren(...items) {
    this.children = [];
    this.append(...items);
  }
  _matches(selector) {
    if (selector === '.day') return String(this.className).split(/\s+/).includes('day');
    if (selector === 'section.cutlet-section') return this.tagName === 'SECTION' && String(this.className).split(/\s+/).includes('cutlet-section');
    if (selector === '[aria-current="date"]') return this.getAttribute('aria-current') === 'date';
    const start = selector.match(/^\[data-start-jdn="(.*)"\]$/);
    if (start) return String(this.dataset.startJdn) === start[1];
    return false;
  }
  querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
  querySelectorAll(selector) {
    const found = [];
    const visit = (node) => {
      if (!node || typeof node !== 'object') return;
      if (typeof node._matches === 'function' && node._matches(selector)) found.push(node);
      for (const child of node.children || []) visit(child);
    };
    for (const child of this.children) visit(child);
    return found;
  }
  getBoundingClientRect() { return { top: 0, left: 0, width: 100, height: 20 }; }
  closest(selector) {
    let node = this;
    while (node) {
      if (typeof node._matches === 'function' && node._matches(selector)) return node;
      node = node.parentElement || null;
    }
    return null;
  }
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

const storedValues = new Map();
const localStorage = {
  getItem(key) { return storedValues.has(String(key)) ? storedValues.get(String(key)) : null; },
  setItem(key, value) { storedValues.set(String(key), String(value)); },
  removeItem(key) { storedValues.delete(String(key)); },
  clear() { storedValues.clear(); },
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
  await Promise.resolve();
  await Promise.resolve();
}

(async () => {
  const watchdog = setTimeout(() => { throw new Error('browser-component-runtime timeout'); }, 15000);
  // Public-page language resolution: explicit lang wins; without one, a saved
  // manual selection wins over navigator.languages, which wins over Interlingue.
  localStorage.clear();
  sandbox.navigator.languages = ['he-IL', 'en-US'];
  const autoHebrew = new PastafariDateElement();
  assert.strictEqual(autoHebrew._locale.code, 'he');
  assert.strictEqual(autoHebrew.getAttribute('lang'), 'he');
  assert.strictEqual(autoHebrew.getAttribute('dir'), 'rtl');

  localStorage.setItem('pastafari.browser.locale', 'fr');
  const storedFrench = new PastafariDateElement();
  assert.strictEqual(storedFrench._locale.code, 'fr');
  assert.strictEqual(storedFrench.getAttribute('lang'), 'fr');

  const explicitEnglish = new PastafariDateElement();
  explicitEnglish.setAttribute('lang', 'en');
  explicitEnglish._applyLocale();
  assert.strictEqual(explicitEnglish._locale.code, 'en');

  localStorage.clear();
  sandbox.navigator.languages = ['xx-ZZ'];
  const fallbackInterlingue = new PastafariDateElement();
  assert.strictEqual(fallbackInterlingue._locale.code, 'ie');

  const manualLanguage = new PastafariDateElement();
  manualLanguage._els.languageSelector.value = 'de';
  manualLanguage._els.languageSelector.listeners.get('change')();
  assert.strictEqual(localStorage.getItem('pastafari.browser.locale'), 'de');
  assert.strictEqual(manualLanguage.getAttribute('lang'), 'de');

  localStorage.clear();
  sandbox.navigator.languages = ['ie'];

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
  assert.strictEqual(recover._els.calendar.getAttribute('data-state'), 'error');
  assert.strictEqual(recover._els.errorMessage.textContent, recover._t('search.invalid'));
  recover.setAttribute('date', '2026-09-06');
  const recovered = await recover.refresh();
  const recoveredReady = await recover.ready;
  assert.strictEqual(recoveredReady.cutletName, recovered.cutletName);
  assert.strictEqual(recover._els.calendar.hasAttribute('data-state'), false);

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
  if (rawName === 'larice') assert(language._els.summary.textContent.includes('\u05D0\u05E8\u05D6\u05D9\u05EA'));

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
  // original flat-grid visual identity while remaining non-interactive.
  const themed = new PastafariDateElement();
  themed._locale = sandbox.PastafariBrowserInternal.i18n.resolveLocale('en', []);
  themed._targetJdn = 100n;
  const themeDay = Object.freeze({
    jdn: 100n, year: '5000', cutletName: 'larice', dayInCutlet: 8, monthName: 'leopard', dayInMonth: 3,
  });
  themed._value = Object.freeze({
    year: themeDay.year,
    cutletName: themeDay.cutletName,
    dayInCutlet: themeDay.dayInCutlet,
    monthName: themeDay.monthName,
    dayInMonth: themeDay.dayInMonth,
  });
  themed._scrollTarget = Object.freeze({
    jdn: themeDay.jdn,
    startJdn: themeDay.jdn - BigInt(themeDay.dayInCutlet - 1),
    year: themeDay.year,
    cutletName: themeDay.cutletName,
    dayInCutlet: themeDay.dayInCutlet,
    monthName: themeDay.monthName,
    dayInMonth: themeDay.dayInMonth,
  });
  const runA = themed._renderMonthRun([themeDay]);
  const runB = themed._renderMonthRun([themeDay]);
  assert.strictEqual(runA.style.values.get('--month-edge'), runB.style.values.get('--month-edge'));
  assert.strictEqual(runA.style.values.get('--month-bg'), runB.style.values.get('--month-bg'));
  const grid = runA.children[1];
  const card = grid.children[0];
  assert.strictEqual(card.tagName, 'ARTICLE');
  assert.strictEqual(card.className, 'day');
  assert.strictEqual(card.style.values.get('--month-edge'), runA.style.values.get('--month-edge'));
  assert.strictEqual(card.style.values.get('--month-ink'), '#111111');
  assert.strictEqual(card.getAttribute('aria-current'), 'date');
  assert.strictEqual(card.children[0].className, 'target-badge');
  assert.strictEqual(card.children[0].textContent, 'This is the date you searched for');

  // Every current semantic month gets a distinct, saturated background theme.
  const monthNames = Object.keys(themed._locale.calendar.months);
  const backgrounds = new Set();
  const edges = new Set();
  for (let index = 0; index < monthNames.length; index += 1) {
    const monthName = monthNames[index];
    const themedRun = themed._renderMonthRun([Object.freeze({
      jdn: BigInt(1000 + index), year: '5000', cutletName: 'larice', dayInCutlet: index + 1,
      monthName, dayInMonth: 1,
    })]);
    backgrounds.add(themedRun.style.values.get('--month-bg'));
    edges.add(themedRun.style.values.get('--month-edge'));
    assert(themedRun.style.values.get('--month-pattern-image').includes('repeating-linear-gradient'));
  }
  assert.strictEqual(backgrounds.size, monthNames.length);
  assert.strictEqual(edges.size, monthNames.length);

  // A JDN may appear at most once in the rendered card model. Exact duplicates
  // are deduplicated; semantic divergence for the same JDN fails closed.
  const duplicateGuard = new PastafariDateElement();
  duplicateGuard._targetJdn = 739862n;
  const correctDay = Object.freeze({
    jdn: 739862n, year: '5000', cutletName: 'bronze', dayInCutlet: 677, monthName: 'sand', dayInMonth: 32,
  });
  const exactDuplicate = Object.freeze({ ...correctDay });
  const wrongDuplicate = Object.freeze({
    ...correctDay, monthName: 'costa', dayInMonth: 12,
  });
  const firstView = Object.freeze({
    startJdn: 739800n, endJdn: 739862n, cutletName: 'bronze', year: '5000', days: Object.freeze([correctDay]),
  });
  const exactView = Object.freeze({
    startJdn: 739862n, endJdn: 739900n, cutletName: 'bronze', year: '5000', days: Object.freeze([exactDuplicate]),
  });
  duplicateGuard._cutlets = new Map([[739800n, firstView], [739862n, exactView]]);
  duplicateGuard._orderedStarts = [739800n, 739862n];
  const prepared = duplicateGuard._prepareRenderableCutlets();
  assert.strictEqual(prepared.length, 1);
  assert.strictEqual(prepared[0].days.length, 1);
  assert.strictEqual(prepared[0].days[0].monthName, 'sand');

  const wrongView = Object.freeze({
    startJdn: 739862n, endJdn: 739900n, cutletName: 'bronze', year: '5000', days: Object.freeze([wrongDuplicate]),
  });
  duplicateGuard._cutlets = new Map([[739800n, firstView], [739862n, wrongView]]);
  assert.throws(
    () => duplicateGuard._prepareRenderableCutlets(),
    (error) => error && error.code === 'ERR_CALENDAR_RENDER_INCONSISTENCY'
      && error.jdn === '739862' && /different cards/.test(error.message),
  );

  // The direct five-part Pastafarian result is authoritative for target
  // selection. A cutlet view that offers the searched JDN with another tuple
  // must fail closed even when there is no duplicate JDN card to compare it to.
  const targetTupleGuard = new PastafariDateElement();
  targetTupleGuard._targetJdn = 739862n;
  targetTupleGuard._value = Object.freeze({
    year: '5000', cutletName: 'bronze', dayInCutlet: 677, monthName: 'sand', dayInMonth: 32,
  });
  targetTupleGuard._scrollTarget = Object.freeze({
    jdn: 739862n, startJdn: 739186n,
    year: '5000', cutletName: 'bronze', dayInCutlet: 677, monthName: 'sand', dayInMonth: 32,
  });
  targetTupleGuard._cutlets = new Map([[739800n, Object.freeze({
    startJdn: 739800n,
    endJdn: 739862n,
    cutletName: 'bronze',
    year: '5000',
    days: Object.freeze([wrongDuplicate]),
  })]]);
  targetTupleGuard._orderedStarts = [739800n];
  assert.throws(
    () => targetTupleGuard._prepareRenderableCutlets(),
    (error) => error && error.code === 'ERR_CALENDAR_RENDER_INCONSISTENCY'
      && error.jdn === '739862'
      && error.first.monthName === 'sand'
      && error.second.monthName === 'costa',
  );

  // Target positioning has one owner and one scroll primitive. It resolves the
  // exact section and exact JDN+five-part card, then changes only viewport.scrollTop.
  const semanticScroller = new PastafariDateElement();
  const navigationTarget = Object.freeze({
    jdn: 739862n, startJdn: 739186n,
    year: '5000', cutletName: 'bronze', dayInCutlet: 677, monthName: 'sand', dayInMonth: 32,
  });
  semanticScroller._targetJdn = navigationTarget.jdn;
  semanticScroller._scrollTarget = navigationTarget;
  semanticScroller._els.viewport.scrollTop = 200;
  semanticScroller._els.viewport.clientHeight = 500;
  semanticScroller._els.viewport.scrollHeight = 4000;
  semanticScroller._els.viewport.getBoundingClientRect = () => ({ top: 100, left: 0, width: 800, height: 500 });

  const section = new FakeElement('section');
  section.className = 'cutlet-section';
  Object.assign(section.dataset, { startJdn: '739186', year: '5000', cutletName: 'bronze' });
  const wrongCard = new FakeElement('article');
  wrongCard.className = 'day';
  Object.assign(wrongCard.dataset, {
    jdn: '739862', year: '5000', cutletName: 'bronze', dayInCutlet: '677', monthName: 'costa', dayInMonth: '12',
  });
  wrongCard.getBoundingClientRect = () => ({ top: 300, left: 0, width: 100, height: 100 });
  wrongCard.closest = () => section;

  const correctCard = new FakeElement('article');
  correctCard.className = 'day';
  Object.assign(correctCard.dataset, {
    jdn: '739862', year: '5000', cutletName: 'bronze', dayInCutlet: '677', monthName: 'sand', dayInMonth: '32',
  });
  correctCard.getBoundingClientRect = () => ({ top: 700, left: 0, width: 100, height: 100 });
  correctCard.closest = () => section;
  semanticScroller._els.list = {
    querySelectorAll(selector) {
      if (selector === 'section.cutlet-section') return [section];
      if (selector === '.day') return [wrongCard, correctCard];
      return [];
    },
  };

  semanticScroller._positionTargetInViewport(navigationTarget);
  assert.strictEqual(wrongCard.getAttribute('aria-current'), null);
  assert.strictEqual(correctCard.getAttribute('aria-current'), 'date');
  assert.strictEqual(semanticScroller._activeStartJdn, 739186n);
  // 700 - 100 - ((500 - 100) / 2) = +400 from the original 200.
  assert.strictEqual(semanticScroller._els.viewport.scrollTop, 600);

  // A full re-render caused by adjacent preloading preserves an exact visible
  // day anchor, not merely a cutlet heading. This prevents post-target drift.
  const anchorScroller = new PastafariDateElement();
  anchorScroller._els.viewport.scrollTop = 500;
  anchorScroller._els.viewport.clientHeight = 500;
  anchorScroller._els.viewport.getBoundingClientRect = () => ({ top: 100, left: 0, width: 800, height: 500 });
  const anchorSection = new FakeElement('section');
  anchorSection.className = 'cutlet-section';
  anchorSection.dataset.startJdn = '739186';
  const beforeCard = new FakeElement('article');
  beforeCard.className = 'day';
  Object.assign(beforeCard.dataset, {
    jdn: '739500', year: '5000', cutletName: 'bronze', dayInCutlet: '315', monthName: 'sand', dayInMonth: '7',
  });
  beforeCard.closest = () => anchorSection;
  beforeCard.getBoundingClientRect = () => ({ top: 120, left: 0, width: 100, height: 100 });
  let renderedCards = [beforeCard];
  anchorScroller._els.list = {
    querySelectorAll(selector) {
      if (selector === '.day') return renderedCards;
      if (selector === 'section.cutlet-section') return [anchorSection];
      return [];
    },
  };
  const anchor = anchorScroller._captureViewportAnchor();
  const afterCard = new FakeElement('article');
  afterCard.className = 'day';
  Object.assign(afterCard.dataset, beforeCard.dataset);
  afterCard.closest = () => anchorSection;
  afterCard.getBoundingClientRect = () => ({ top: 170, left: 0, width: 100, height: 100 });
  renderedCards = [afterCard];
  assert.strictEqual(anchorScroller._restoreViewportAnchor(anchor), true);
  assert.strictEqual(anchorScroller._els.viewport.scrollTop, 550);

  // Structural cutlet selection must never confuse a day-line with a cutlet
  // container. This was the original class-name collision behind active-cutlet
  // drift: both used the class `cutlet`.
  const activeScroller = new PastafariDateElement();
  const structuralList = new FakeElement('div');
  const structuralSection = new FakeElement('section');
  structuralSection.className = 'cutlet-section';
  structuralSection.dataset.startJdn = '739186';
  structuralSection.getBoundingClientRect = () => ({ top: 90, left: 0, width: 800, height: 1200 });
  const internalLine = new FakeElement('span');
  internalLine.className = 'day-line cutlet-line';
  internalLine.getBoundingClientRect = () => ({ top: 130, left: 0, width: 200, height: 20 });
  structuralSection.append(internalLine);
  structuralList.append(structuralSection);
  activeScroller._els.list = structuralList;
  activeScroller._els.viewport.scrollTop = 400;
  activeScroller._els.viewport.scrollHeight = 2000;
  activeScroller._els.viewport.clientHeight = 500;
  activeScroller._els.viewport.getBoundingClientRect = () => ({ top: 100, left: 0, width: 800, height: 500 });
  activeScroller._orderedStarts = [];
  activeScroller._onScroll();
  assert.strictEqual(activeScroller._activeStartJdn, 739186n);
  assert.strictEqual(structuralList.querySelectorAll('section.cutlet-section').length, 1);

  await flush();

  // The initial cutlet request is derived from the authoritative direct tuple,
  // not by asking getCutletView() to choose a containing cutlet from target JDN.
  // dayInCutlet 677 fixes the only acceptable start at 739186.
  const witnessValue = Object.freeze({
    year: '5000', cutletName: 'bronze', dayInCutlet: 677, monthName: 'sand', dayInMonth: 32,
  });
  const witnessStart = 739186n;
  const witnessDays = [];
  for (let index = 0; index < 677; index += 1) {
    const jdn = witnessStart + BigInt(index);
    witnessDays.push(Object.freeze({
      jdn,
      year: '5000',
      cutletName: 'bronze',
      dayInCutlet: index + 1,
      monthName: index === 676 ? 'sand' : 'argile',
      dayInMonth: index === 676 ? 32 : index + 1,
    }));
  }
  const witnessView = Object.freeze({
    selectedJdn: witnessStart,
    selectedIndex: 0,
    startJdn: witnessStart,
    endJdn: 739862n,
    previousCutletJdn: witnessStart - 1n,
    nextCutletJdn: 739863n,
    year: '5000',
    cutletName: 'bronze',
    days: Object.freeze(witnessDays),
  });
  let requestedInitialView = null;
  sharedService = {
    async convert() { return witnessValue; },
    async getCutletView(targetJdn) { requestedInitialView = BigInt(targetJdn); return witnessView; },
    async retry() {},
  };
  const tupleLocated = new PastafariDateElement();
  tupleLocated._primeAdjacent = () => {};
  tupleLocated._renderCutlets = () => {};
  tupleLocated._positionTargetInViewport = (target) => { tupleLocated._activeStartJdn = target.startJdn; };
  tupleLocated._targetJdn = null;
  tupleLocated.setAttribute('date', '2026-09-06');
  const realAxisTarget = axis.gregorianToJdn(axis.parseIsoDate('2026-09-06'));
  // Rebase the synthetic witness to the real attribute JDN while preserving a
  // 677th-day cutlet shape; this checks the request arithmetic itself.
  const rebasedStart = realAxisTarget - 676n;
  const rebasedDays = witnessDays.map((day, index) => Object.freeze({
    ...day,
    jdn: rebasedStart + BigInt(index),
  }));
  const rebasedView = Object.freeze({
    ...witnessView,
    selectedJdn: rebasedStart,
    startJdn: rebasedStart,
    endJdn: realAxisTarget,
    previousCutletJdn: rebasedStart - 1n,
    nextCutletJdn: realAxisTarget + 1n,
    days: Object.freeze(rebasedDays),
  });
  sharedService.getCutletView = async (targetJdn) => { requestedInitialView = BigInt(targetJdn); return rebasedView; };
  await tupleLocated.refresh();
  assert.strictEqual(requestedInitialView, rebasedStart);
  assert.strictEqual(tupleLocated._activeStartJdn, rebasedStart);

  // A view whose section identity disagrees with the direct five-part result is
  // rejected before rendering/scrolling, even if it contains a target-like day.
  sharedService = {
    async convert() { return witnessValue; },
    async getCutletView() {
      return Object.freeze({ ...rebasedView, cutletName: 'larice' });
    },
    async retry() {},
  };
  const wrongCutletIdentity = new PastafariDateElement();
  wrongCutletIdentity._primeAdjacent = () => {};
  wrongCutletIdentity.setAttribute('date', '2026-09-06');
  await assert.rejects(
    () => wrongCutletIdentity.refresh(),
    (error) => error && error.code === 'ERR_TARGET_CUTLET_MISMATCH'
      && error.reason === 'wrong-cutlet-identity',
  );

  // A target can only be positioned inside the exact cutlet section owned by
  // the navigation target; there is no alternate section-scroll path.
  const wrongSectionScroller = new PastafariDateElement();
  const wrongSectionTarget = Object.freeze({
    jdn: 739862n, startJdn: 739186n,
    year: '5000', cutletName: 'bronze', dayInCutlet: 677, monthName: 'sand', dayInMonth: 32,
  });
  const wrongSection = new FakeElement('section');
  wrongSection.className = 'cutlet-section';
  Object.assign(wrongSection.dataset, { startJdn: '739800', year: '5000', cutletName: 'bronze' });
  const onlyCard = new FakeElement('article');
  onlyCard.className = 'day';
  Object.assign(onlyCard.dataset, {
    jdn: '739862', year: '5000', cutletName: 'bronze', dayInCutlet: '677', monthName: 'sand', dayInMonth: '32',
  });
  onlyCard.closest = () => wrongSection;
  wrongSectionScroller._els.list = {
    querySelectorAll(selector) {
      if (selector === 'section.cutlet-section') return [wrongSection];
      if (selector === '.day') return [onlyCard];
      return [];
    },
  };
  assert.throws(
    () => wrongSectionScroller._positionTargetInViewport(wrongSectionTarget),
    (error) => error && error.code === 'ERR_TARGET_CUTLET_MISMATCH'
      && error.reason === 'scroll-section-mismatch',
  );

  clearTimeout(watchdog);
  console.log('browser-component-runtime: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
