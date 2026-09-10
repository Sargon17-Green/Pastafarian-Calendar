'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const serviceApi = ns.calendarService;
  const axis = ns.dateAxis;
  const i18n = ns.i18n;

  if (!serviceApi || !axis || !i18n) {
    throw new Error('Li cooking component ne esset cargat pos su browser dependencies.');
  }

  const LOCALE_STORAGE_KEY = 'pastafari.browser.locale';
  const CHAPTER_KEYS = Object.freeze({
    inputs: 'cooking.chapter.inputs',
    gates: 'cooking.chapter.gates',
    'year-5000': 'cooking.chapter.year5000',
    'year-walk': 'cooking.chapter.yearWalk',
    'structure-sauce': 'cooking.chapter.structureSauce',
    cutlets: 'cooking.chapter.cutlets',
    months: 'cooking.chapter.months',
    position: 'cooking.chapter.position',
    result: 'cooking.chapter.result',
  });
  const SAUCE_PHASE_KEYS = Object.freeze({
    stones: 'cooking.phase.stones',
    hidden: 'cooking.phase.hidden',
    visible: 'cooking.phase.visible',
    bowls: 'cooking.phase.bowls',
    postStirs: 'cooking.phase.postStirs',
  });

  const doc = root.document || null;
  const enqueueMicrotask = typeof root.queueMicrotask === 'function'
    ? root.queueMicrotask.bind(root)
    : (callback) => Promise.resolve().then(callback);

  function readStoredLocale() {
    try {
      if (!root.localStorage || typeof root.localStorage.getItem !== 'function') return null;
      const value = root.localStorage.getItem(LOCALE_STORAGE_KEY);
      return typeof value === 'string' && value.trim() !== '' ? value.trim() : null;
    } catch (_) {
      return null;
    }
  }

  function compareIntegerStrings(a, b) {
    const left = BigInt(a);
    const right = BigInt(b);
    return left < right ? -1 : left > right ? 1 : 0;
  }

  function plainClone(value) {
    if (value === null || typeof value !== 'object') return value;
    if (Array.isArray(value)) return value.map(plainClone);
    const out = {};
    for (const [key, item] of Object.entries(value)) out[key] = plainClone(item);
    return out;
  }

  function exactDisplay(value) {
    const text = String(value);
    if (!/^-?\d{25,}$/.test(text)) return text;
    const sign = text.startsWith('-') ? '-' : '';
    const digits = sign ? text.slice(1) : text;
    return sign + digits.slice(0, 10) + '…' + digits.slice(-8);
  }

  function safeArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function integerArrayText(values) {
    return safeArray(values).map((value) => String(value)).join(', ');
  }

  function findSauce(trace, id) {
    if (!trace || !trace.artifacts) return null;
    return safeArray(trace.artifacts.sauceRuns).find((run) => run.id === id) || null;
  }

  function finalTupleKey(trace) {
    if (!trace || !trace.finalResult) return '';
    const value = trace.finalResult;
    return [
      value.year,
      value.cutlet && value.cutlet.canonicalIndex,
      value.dayInCutlet,
      value.month && value.month.canonicalIndex,
      value.dayInMonth,
    ].join('|');
  }

  const HTMLElementBase = root.HTMLElement || class {};

  class PastafariCookingElement extends HTMLElementBase {
    static get observedAttributes() {
      return ['date', 'calculation-date', 'lang', 'open'];
    }

    constructor() {
      super();
      this._connected = false;
      this._generation = 0;
      this._queuedEpoch = null;
      this._trace = null;
      this._traceInputKey = null;
      this._locale = null;
      this._activeChapter = 'inputs';
      this._chapterCursor = Object.create(null);
      this._sauceState = new Map();
      this._gateDetails = new Map();
      this._gateDetailLoading = null;
      this._readySettled = false;
      this.ready = new Promise((resolve) => { this._resolveReady = resolve; });

      if (typeof this.attachShadow !== 'function') return;
      this.attachShadow({ mode: 'open' });
      this.shadowRoot.innerHTML = `
        <style>
          :host {
            --ink: #17130e;
            --muted: #665f56;
            --paper: #f4f0e7;
            --panel: #fffdf8;
            --line: #cfc6b7;
            --accent: #9d3825;
            --accent-dark: #672013;
            --focus: #0068c9;
            display: block;
            width: 100%;
            margin-block: clamp(1.25rem, 3vw, 2.5rem);
            color: var(--pastafari-color, var(--ink));
            font-family: Arial, "Noto Sans Hebrew", "Segoe UI", sans-serif;
            line-height: 1.5;
          }
          :host(:not([open])) { display: none !important; }
          *, *::before, *::after { box-sizing: border-box; }
          [hidden] { display: none !important; }
          button { font: inherit; min-height: 44px; }
          button:focus-visible,
          [tabindex]:focus-visible {
            outline: 4px solid var(--focus);
            outline-offset: 3px;
          }
          .shell {
            overflow: hidden;
            border: 2px solid var(--ink);
            border-radius: 1.2rem;
            background: var(--panel);
            box-shadow: 0 20px 55px rgb(54 36 20 / 12%);
          }
          .head {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 1rem;
            align-items: start;
            padding: clamp(1rem, 3vw, 2rem);
            border-bottom: 1px solid var(--line);
            background: linear-gradient(135deg, #fff7e8 0%, #fffdf8 70%);
          }
          .kicker {
            margin: 0 0 .45rem;
            color: var(--accent-dark);
            font-size: .75rem;
            font-weight: 900;
            letter-spacing: .09em;
            text-transform: uppercase;
          }
          h2, h3, h4 { font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif; }
          h2 {
            margin: 0;
            font-size: clamp(1.8rem, 4vw, 3.5rem);
            letter-spacing: -.035em;
            line-height: 1;
          }
          .subtitle {
            max-width: 72ch;
            margin: .75rem 0 0;
            color: var(--muted);
          }
          .close,
          .nav button,
          .step-controls button,
          .phase-tabs button,
          .gate-detail-button {
            border: 1px solid #8e8272;
            border-radius: .65rem;
            background: #fffdf8;
            color: var(--ink);
            font-weight: 800;
            cursor: pointer;
          }
          .close { padding: .55rem .8rem; }
          .close:hover,
          .nav button:hover,
          .step-controls button:hover,
          .phase-tabs button:hover,
          .gate-detail-button:hover { background: #fff1e8; }
          .nav {
            display: flex;
            gap: .45rem;
            padding: .75rem clamp(1rem, 3vw, 2rem);
            overflow-x: auto;
            border-bottom: 1px solid var(--line);
            scrollbar-gutter: stable;
          }
          .nav button,
          .phase-tabs button {
            flex: 0 0 auto;
            min-height: 40px;
            padding: .45rem .7rem;
          }
          .nav button[aria-current="page"],
          .phase-tabs button[aria-pressed="true"] {
            border-color: var(--accent-dark);
            background: var(--accent-dark);
            color: white;
          }
          .status {
            min-height: 10rem;
            display: grid;
            place-items: center;
            gap: .65rem;
            padding: 2rem;
            text-align: center;
          }
          .status p { margin: 0; }
          .status button { padding: .55rem .9rem; }
          .pane {
            min-width: 0;
            padding: clamp(1rem, 3vw, 2rem);
          }
          .chapter-heading {
            margin: 0 0 1rem;
            font-size: clamp(1.45rem, 3vw, 2.25rem);
            line-height: 1.1;
          }
          .same-execution {
            margin: 0 0 1.4rem;
            padding: .7rem .85rem;
            border-inline-start: .35rem solid var(--accent);
            background: #fff4ee;
            color: #39271f;
            font-size: .9rem;
            font-weight: 700;
          }
          .kv {
            display: grid;
            grid-template-columns: minmax(9rem, 13rem) minmax(0, 1fr);
            gap: .45rem 1rem;
            margin: 0;
          }
          .kv dt {
            color: var(--muted);
            font-family: ui-monospace, "SFMono-Regular", Consolas, monospace;
            font-size: .86em;
            font-weight: 800;
          }
          .kv dd {
            min-width: 0;
            margin: 0;
            overflow-wrap: anywhere;
          }
          .exact-number {
            min-height: 0;
            max-width: 100%;
            padding: .12rem .35rem;
            border: 1px dashed #a99d8f;
            border-radius: .35rem;
            background: #f8f2e8;
            color: #17130e;
            font-family: ui-monospace, "SFMono-Regular", Consolas, monospace;
            font-size: .88em;
            text-align: start;
            overflow-wrap: anywhere;
            cursor: zoom-in;
          }
          .exact-number[data-expanded="true"] { cursor: zoom-out; }
          code {
            font-family: ui-monospace, "SFMono-Regular", Consolas, monospace;
            overflow-wrap: anywhere;
          }
          .step-card,
          .sauce {
            min-width: 0;
            margin-top: 1rem;
            padding: 1rem;
            border: 1px solid var(--line);
            border-radius: .9rem;
            background: #fff;
          }
          .step-card h4,
          .sauce h4 { margin: 0 0 .8rem; font-size: 1.15rem; }
          .step-controls {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: .55rem;
            margin-block: 1rem;
          }
          .step-controls button { padding: .45rem .75rem; }
          .step-index {
            min-width: 7ch;
            color: var(--muted);
            font-variant-numeric: tabular-nums;
            font-weight: 800;
            text-align: center;
          }
          .phase-tabs {
            display: flex;
            gap: .4rem;
            overflow-x: auto;
            margin-bottom: 1rem;
            padding-bottom: .25rem;
          }
          .mini-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(min(100%, 13rem), 1fr));
            gap: .65rem;
            margin-top: .8rem;
          }
          .mini {
            min-width: 0;
            padding: .65rem;
            border: 1px solid #ddd4c8;
            border-radius: .65rem;
            background: #faf7f1;
          }
          .mini strong { display: block; margin-bottom: .35rem; }
          .sequence {
            display: grid;
            gap: .45rem;
            margin: .75rem 0 0;
            padding: 0;
            list-style: none;
          }
          .sequence li {
            min-width: 0;
            padding: .55rem .65rem;
            border: 1px solid #e0d8cc;
            border-radius: .55rem;
            background: #fcfaf6;
          }
          .empty { color: var(--muted); font-style: italic; }
          .gate-detail-button {
            margin-top: 1rem;
            padding: .55rem .85rem;
          }
          .gate-detail-button[disabled] { opacity: .65; cursor: wait; }
          .result-five {
            display: grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: .65rem;
          }
          .result-five > div {
            min-width: 0;
            padding: .8rem;
            border: 1px solid var(--line);
            border-radius: .7rem;
            background: #fff7e8;
            overflow-wrap: anywhere;
          }
          .result-five strong { display: block; color: var(--muted); font-size: .78rem; }
          .result-five span { display: block; margin-top: .25rem; font-weight: 900; }
          @media (max-width: 700px) {
            .head { grid-template-columns: 1fr; }
            .close { justify-self: start; }
            .kv { grid-template-columns: 1fr; gap: .15rem; }
            .kv dd { margin-bottom: .55rem; }
            .result-five { grid-template-columns: 1fr 1fr; }
          }
          @media (max-width: 420px) {
            .result-five { grid-template-columns: 1fr; }
          }
          @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after { scroll-behavior: auto !important; transition: none !important; }
          }
          @media (forced-colors: active) {
            .shell, .step-card, .sauce, .mini, .result-five > div { border: 2px solid CanvasText; }
          }
          @media print {
            :host(:not([open])) { display: none !important; }
            .shell { box-shadow: none; }
            .close, .nav, .step-controls, .phase-tabs, .gate-detail-button { display: none !important; }
          }
        </style>
        <section class="shell" part="shell" role="region" aria-labelledby="pastafari-cooking-title" aria-busy="false">
          <header class="head">
            <div>
              <p class="kicker">PASTAFARI · TRACE</p>
              <h2 class="title" id="pastafari-cooking-title"></h2>
              <p class="subtitle"></p>
            </div>
            <button class="close" type="button"></button>
          </header>
          <nav class="nav" aria-label="Trace chapters"></nav>
          <div class="status loading" hidden role="status" aria-live="polite">
            <p class="loading-text"></p>
          </div>
          <div class="status error" hidden role="alert">
            <p class="error-text"></p>
            <button class="retry" type="button"></button>
          </div>
          <section class="pane" tabindex="-1"></section>
        </section>
      `;

      this._els = {
        shell: this.shadowRoot.querySelector('.shell'),
        title: this.shadowRoot.querySelector('.title'),
        subtitle: this.shadowRoot.querySelector('.subtitle'),
        close: this.shadowRoot.querySelector('.close'),
        nav: this.shadowRoot.querySelector('.nav'),
        loading: this.shadowRoot.querySelector('.status.loading'),
        loadingText: this.shadowRoot.querySelector('.loading-text'),
        error: this.shadowRoot.querySelector('.status.error'),
        errorText: this.shadowRoot.querySelector('.error-text'),
        retry: this.shadowRoot.querySelector('.retry'),
        pane: this.shadowRoot.querySelector('.pane'),
      };
      this._els.close.addEventListener('click', () => this.close());
      this.shadowRoot.addEventListener('keydown', (event) => {
        if (!event || event.key !== 'Escape' || !this.hasAttribute('open')) return;
        if (typeof event.preventDefault === 'function') event.preventDefault();
        this.close();
      });
      this._els.retry.addEventListener('click', () => this.load().catch(() => {}));
      this._applyLocale();
      this._renderState();
    }

    connectedCallback() {
      if (this._connected) return;
      this._connected = true;
      this._applyLocale();
      if (this.hasAttribute('open')) this._queueLoad();
    }

    disconnectedCallback() {
      if (!this._connected) return;
      this._connected = false;
      this._generation += 1;
      this._queuedEpoch = null;
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === newValue) return;
      if (name === 'lang') {
        this._applyLocale();
        this._renderState();
        return;
      }
      if (name === 'open') {
        if (newValue !== null && this._connected) this._queueLoad();
        else this._generation += 1;
        return;
      }
      if (this._connected && this.hasAttribute('open')) this._queueLoad();
    }

    get trace() { return this._trace; }

    get open() { return this.hasAttribute('open'); }
    set open(value) {
      if (value) this.setAttribute('open', '');
      else this.removeAttribute('open');
    }

    show() { this.open = true; }

    close() {
      this.open = false;
      const EventCtor = root.CustomEvent;
      if (typeof EventCtor === 'function') {
        this.dispatchEvent(new EventCtor('pastafari-cooking-close', { bubbles: true, composed: true }));
      }
    }

    _queueLoad() {
      if (!this._connected || !this.hasAttribute('open')) return;
      const epoch = ++this._generation;
      this._queuedEpoch = epoch;
      enqueueMicrotask(() => {
        if (!this._connected || !this.hasAttribute('open') || this._queuedEpoch !== epoch) return;
        this._queuedEpoch = null;
        this.load(epoch).catch(() => {});
      });
    }

    _resolveLocale() {
      const explicit = this.getAttribute('lang');
      const stored = explicit ? null : readStoredLocale();
      const browserLanguages = root.navigator && Array.isArray(root.navigator.languages)
        ? root.navigator.languages : [];
      return i18n.resolveLocale(explicit || stored, browserLanguages);
    }

    _applyLocale() {
      this._locale = this._resolveLocale();
      if (typeof this.setAttribute === 'function') {
        if (!this.getAttribute('lang')) this.setAttribute('lang', this._locale.code);
        this.setAttribute('dir', this._locale.dir);
      }
      if (!this._els) return;
      this._els.title.textContent = this._t('cooking.title');
      this._els.subtitle.textContent = this._t('cooking.subtitle');
      this._els.close.textContent = this._t('cooking.close');
      this._els.loadingText.textContent = this._t('cooking.loading');
      this._els.errorText.textContent = this._t('cooking.error');
      this._els.retry.textContent = this._t('cooking.retry');
      this._els.nav.setAttribute('aria-label', this._t('cooking.title'));
    }

    _t(key, values) { return i18n.translate(this._locale, key, values); }
    _term(key) { return this._t('cooking.term.' + key); }

    async load(expectedGeneration) {
      if (!this.hasAttribute('open')) return null;
      const generation = expectedGeneration === undefined ? ++this._generation : expectedGeneration;
      const targetDate = axis.normalizeDateInput(this.getAttribute('date'), 'Li date a examinar');
      const calculationDate = axis.normalizeDateInput(this.getAttribute('calculation-date'), 'Li die de calculation');
      const targetJdn = axis.gregorianToJdn(targetDate);
      const calculationJdn = axis.gregorianToJdn(calculationDate);
      const inputKey = String(calculationJdn) + ':' + String(targetJdn);
      if (this._trace && this._traceInputKey === inputKey) {
        if (generation !== this._generation || !this._connected || !this.hasAttribute('open')) return null;
        this._hideStatus();
        this._renderState();
        return this._trace;
      }
      const service = serviceApi.getSharedCalendarService();
      if (!service || typeof service.getCookingTrace !== 'function') {
        throw new TypeError('Li shared CalendarService ne supporta cooking trace.');
      }

      this._showLoading();
      try {
        const trace = await service.getCookingTrace(targetJdn, calculationJdn);
        if (generation !== this._generation || !this._connected || !this.hasAttribute('open')) return null;
        this._trace = trace;
        this._traceInputKey = inputKey;
        this._gateDetails.clear();
        this._gateDetailLoading = null;
        this._activeChapter = safeArray(trace.chapters).some((row) => row.id === this._activeChapter)
          ? this._activeChapter : 'inputs';
        this._hideStatus();
        this._renderState();
        if (!this._readySettled) {
          this._readySettled = true;
          this._resolveReady(trace);
        }
        const EventCtor = root.CustomEvent;
        if (typeof EventCtor === 'function') {
          this.dispatchEvent(new EventCtor('pastafari-cooking-change', {
            bubbles: true,
            composed: true,
            detail: trace,
          }));
        }
        return trace;
      } catch (error) {
        if (generation !== this._generation) return null;
        this._showError(error);
        throw error;
      }
    }

    _showLoading() {
      if (!this._els) return;
      this._els.shell.setAttribute('aria-busy', 'true');
      this._els.loading.hidden = false;
      this._els.error.hidden = true;
      this._els.pane.hidden = true;
    }

    _hideStatus() {
      if (!this._els) return;
      this._els.shell.setAttribute('aria-busy', 'false');
      this._els.loading.hidden = true;
      this._els.error.hidden = true;
      this._els.pane.hidden = false;
    }

    _showError(error) {
      if (!this._els) return;
      this._els.shell.setAttribute('aria-busy', 'false');
      this._els.loading.hidden = true;
      this._els.error.hidden = false;
      this._els.pane.hidden = true;
      this._els.errorText.textContent = this._t('cooking.error');
      if (root.console && typeof root.console.error === 'function') root.console.error(error);
    }

    _renderState() {
      if (!this._els) return;
      this._applyLocaleLabelsOnly();
      if (!this._trace) {
        this._els.nav.replaceChildren();
        if (!this._els.loading.hidden || !this._els.error.hidden) return;
        this._els.pane.replaceChildren();
        return;
      }
      this._renderNav();
      this._renderChapter();
    }

    _applyLocaleLabelsOnly() {
      if (!this._locale || !this._els) return;
      this._els.title.textContent = this._t('cooking.title');
      this._els.subtitle.textContent = this._t('cooking.subtitle');
      this._els.close.textContent = this._t('cooking.close');
      this._els.loadingText.textContent = this._t('cooking.loading');
      this._els.retry.textContent = this._t('cooking.retry');
    }

    _renderNav() {
      this._els.nav.replaceChildren();
      for (const chapter of safeArray(this._trace.chapters)) {
        const button = doc.createElement('button');
        button.type = 'button';
        button.textContent = this._chapterTitle(chapter.id);
        button.dataset.chapter = chapter.id;
        if (chapter.id === this._activeChapter) button.setAttribute('aria-current', 'page');
        button.addEventListener('click', () => {
          this._activeChapter = chapter.id;
          this._renderNav();
          this._renderChapter();
          if (typeof this._els.pane.focus === 'function') this._els.pane.focus();
        });
        this._els.nav.append(button);
      }
    }

    _chapterTitle(id) {
      const key = CHAPTER_KEYS[id];
      return key ? this._t(key) : String(id);
    }

    _heading(container, text, level = 3) {
      const node = doc.createElement(level === 4 ? 'h4' : 'h3');
      node.className = level === 4 ? '' : 'chapter-heading';
      node.textContent = text;
      container.append(node);
      return node;
    }

    _exactNode(value) {
      const text = String(value);
      if (!/^-?\d{25,}$/.test(text)) {
        const code = doc.createElement('code');
        code.textContent = text;
        code.setAttribute('dir', 'ltr');
        return code;
      }
      const button = doc.createElement('button');
      button.type = 'button';
      button.className = 'exact-number';
      button.dataset.exact = text;
      button.dataset.expanded = 'false';
      button.textContent = exactDisplay(text);
      button.setAttribute('dir', 'ltr');
      button.setAttribute('aria-label', this._t('cooking.exactShow'));
      button.addEventListener('click', () => {
        const expanded = button.dataset.expanded === 'true';
        button.dataset.expanded = expanded ? 'false' : 'true';
        button.textContent = expanded ? exactDisplay(text) : text;
        button.setAttribute('aria-label', this._t(expanded ? 'cooking.exactShow' : 'cooking.exactHide'));
      });
      return button;
    }

    _kv(container, rows) {
      const dl = doc.createElement('dl');
      dl.className = 'kv';
      for (const row of rows) {
        if (!row || row.value === undefined || row.value === null) continue;
        const dt = doc.createElement('dt');
        dt.textContent = String(row.label);
        const dd = doc.createElement('dd');
        if (row.node) dd.append(row.node);
        else if (row.exact) dd.append(this._exactNode(row.value));
        else dd.textContent = String(row.value);
        dl.append(dt, dd);
      }
      container.append(dl);
      return dl;
    }

    _arrayValue(values, exact = false) {
      const wrap = doc.createElement('span');
      const list = safeArray(values);
      if (list.length === 0) {
        wrap.textContent = '—';
        return wrap;
      }
      list.forEach((value, index) => {
        const item = exact ? this._exactNode(value) : doc.createElement('code');
        if (!exact) item.textContent = String(value);
        wrap.append(item);
        if (index + 1 < list.length) {
          const comma = doc.createElement('span');
          comma.textContent = ', ';
          wrap.append(comma);
        }
      });
      return wrap;
    }

    _renderChapter() {
      const pane = this._els.pane;
      pane.replaceChildren();
      this._heading(pane, this._chapterTitle(this._activeChapter));
      const note = doc.createElement('p');
      note.className = 'same-execution';
      note.textContent = this._t('cooking.sameExecution');
      pane.append(note);

      switch (this._activeChapter) {
        case 'inputs': this._renderInputs(pane); break;
        case 'gates': this._renderGates(pane); break;
        case 'year-5000': this._renderYear5000(pane); break;
        case 'year-walk': this._renderYearWalk(pane); break;
        case 'structure-sauce': this._renderStructureSauce(pane); break;
        case 'cutlets': this._renderCutlets(pane); break;
        case 'months': this._renderMonths(pane); break;
        case 'position': this._renderPosition(pane); break;
        case 'result': this._renderResult(pane); break;
        default: this._empty(pane); break;
      }
    }

    _renderInputs(pane) {
      const targetDate = axis.normalizeDateInput(this.getAttribute('date'), 'Li date a examinar');
      const calculationDate = axis.normalizeDateInput(this.getAttribute('calculation-date'), 'Li die de calculation');
      this._kv(pane, [
        { label: 'targetDate', value: axis.toIsoDate(targetDate) },
        { label: 'calculationDate', value: axis.toIsoDate(calculationDate) },
        { label: 'targetDay', value: this._trace.inputs.targetDay, exact: true },
        { label: 'calculationDay', value: this._trace.inputs.calculationDay, exact: true },
        { label: 'schemaVersion', value: this._trace.schemaVersion },
        { label: 'semanticProfile', value: this._trace.semanticProfile },
      ]);
    }

    _cursor(key, length) {
      if (!Number.isInteger(this._chapterCursor[key])) this._chapterCursor[key] = 0;
      if (length <= 0) return 0;
      this._chapterCursor[key] = Math.max(0, Math.min(length - 1, this._chapterCursor[key]));
      return this._chapterCursor[key];
    }

    _stepControls(container, key, length, rerender) {
      if (length <= 1) return;
      const index = this._cursor(key, length);
      const controls = doc.createElement('div');
      controls.className = 'step-controls';
      const previous = doc.createElement('button');
      previous.type = 'button';
      previous.textContent = this._t('cooking.previous');
      previous.disabled = index <= 0;
      previous.addEventListener('click', () => {
        this._chapterCursor[key] = Math.max(0, this._cursor(key, length) - 1);
        rerender();
      });
      const marker = doc.createElement('span');
      marker.className = 'step-index';
      marker.textContent = String(index + 1) + ' / ' + String(length);
      const next = doc.createElement('button');
      next.type = 'button';
      next.textContent = this._t('cooking.next');
      next.disabled = index >= length - 1;
      next.addEventListener('click', () => {
        this._chapterCursor[key] = Math.min(length - 1, this._cursor(key, length) + 1);
        rerender();
      });
      controls.append(previous, marker, next);
      container.append(controls);
    }

    _renderGates(pane) {
      const gaps = safeArray(this._trace.artifacts && this._trace.artifacts.gateNetwork
        && this._trace.artifacts.gateNetwork.gaps);
      if (!gaps.length) return this._empty(pane);
      const key = 'gates';
      const index = this._cursor(key, gaps.length);
      this._stepControls(pane, key, gaps.length, () => this._renderChapter());
      const gap = gaps[index];
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, this._term('gate') + ' ' + String(gap.signedIndex), 4);
      this._kv(card, [
        { label: 'signedIndex', value: gap.signedIndex, exact: true },
        { label: 'gap', value: gap.gap, exact: true },
        { label: 'sauceRunId', value: gap.sauceRunId || '—' },
        { label: 'detailCoverage', value: gap.detailCoverage || '—' },
      ]);
      if (gap.sauceSummary) {
        this._heading(card, this._term('compactSauce'), 4);
        this._renderCounters(card, gap.sauceSummary.counters);
        this._kv(card, [
          { label: 'orderAtDrop46', node: this._arrayValue(gap.sauceSummary.orderAtDrop46) },
          { label: 'finalBowls', node: this._arrayValue(gap.sauceSummary.finalBowls, true) },
        ]);
      }
      const detail = this._gateDetails.get(String(gap.signedIndex));
      if (detail) {
        this._heading(card, this._t('cooking.gateDetailReady'), 4);
        this._renderSauceInspector(card, detail, 'gate:' + String(gap.signedIndex));
      } else {
        const button = doc.createElement('button');
        button.type = 'button';
        button.className = 'gate-detail-button';
        button.textContent = this._gateDetailLoading === String(gap.signedIndex)
          ? this._t('cooking.captureGateBusy') : this._t('cooking.captureGate');
        button.disabled = this._gateDetailLoading !== null;
        button.addEventListener('click', () => this._loadGateDetail(String(gap.signedIndex)).catch(() => {}));
        card.append(button);
      }
      pane.append(card);
    }

    async _loadGateDetail(signedIndex) {
      if (this._gateDetailLoading !== null) return null;
      const generation = ++this._generation;
      const oldTuple = finalTupleKey(this._trace);
      const targetDate = axis.normalizeDateInput(this.getAttribute('date'), 'Li date a examinar');
      const calculationDate = axis.normalizeDateInput(this.getAttribute('calculation-date'), 'Li die de calculation');
      const targetJdn = axis.gregorianToJdn(targetDate);
      const calculationJdn = axis.gregorianToJdn(calculationDate);
      const service = serviceApi.getSharedCalendarService();
      let chunk = null;
      this._gateDetailLoading = signedIndex;
      this._renderChapter();
      try {
        const nextTrace = await service.getCookingTrace(targetJdn, calculationJdn, {
          gateDetailGateIndices: [BigInt(signedIndex)],
          onGateSauceDetail(value) { chunk = plainClone(value); },
        });
        if (generation !== this._generation || !this._connected || !this.hasAttribute('open')) return null;
        if (!chunk) throw new Error('Li selected gate ne productet su detail chunk.');
        if (finalTupleKey(nextTrace) !== oldTuple) {
          throw new Error('Li final resultate diverget durant li gate-detail execution.');
        }
        this._trace = nextTrace;
        this._traceInputKey = String(calculationJdn) + ':' + String(targetJdn);
        this._gateDetails.clear();
        this._gateDetails.set(signedIndex, chunk);
        this._gateDetailLoading = null;
        this._renderNav();
        this._renderChapter();
        return chunk;
      } catch (error) {
        if (generation === this._generation) {
          this._gateDetailLoading = null;
          this._showError(error);
        }
        throw error;
      }
    }

    _renderYear5000(pane) {
      const year = this._trace.artifacts && this._trace.artifacts.yearWalk
        ? this._trace.artifacts.yearWalk.year5000 : null;
      if (!year) return this._empty(pane);
      this._renderYearCard(pane, year, this._t('cooking.chapter.year5000'));
      const run = safeArray(this._trace.artifacts.sauceRuns).find((item) => item.role && item.role.kind === 'year-5000');
      if (run) this._renderSauceInspector(pane, run, run.id);
    }

    _renderYearCard(container, year, title) {
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, title, 4);
      this._kv(card, [
        { label: 'number', value: year.number },
        { label: 'openDay', value: year.openDay, exact: true },
        { label: 'firstDay', value: year.firstDay, exact: true },
        { label: 'closeDay', value: year.closeDay, exact: true },
        { label: 'openGateIndex', value: year.openGateIndex, exact: true },
        { label: 'closeGateIndex', value: year.closeGateIndex, exact: true },
      ]);
      container.append(card);
    }

    _renderYearWalk(pane) {
      const transitions = safeArray(this._trace.artifacts && this._trace.artifacts.yearWalk
        && this._trace.artifacts.yearWalk.transitions);
      if (!transitions.length) {
        const finalYear = this._trace.artifacts && this._trace.artifacts.yearWalk
          ? this._trace.artifacts.yearWalk.finalYear : null;
        if (finalYear) this._renderYearCard(pane, finalYear, this._t('cooking.noYearWalk'));
        return;
      }
      const key = 'yearWalk';
      const index = this._cursor(key, transitions.length);
      this._stepControls(pane, key, transitions.length, () => this._renderChapter());
      const transition = transitions[index];
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, String(transition.direction) + ' · ' + String(transition.fromYear.number)
        + ' → ' + String(transition.toYear.number), 4);
      this._kv(card, [
        { label: 'sharedDay', value: transition.sharedDay, exact: true },
        { label: 'sauceRunId', value: transition.sauceRunId || '—' },
      ]);
      pane.append(card);
      const run = findSauce(this._trace, transition.sauceRunId);
      if (run) this._renderSauceInspector(pane, run, run.id);
    }

    _renderStructureSauce(pane) {
      const run = safeArray(this._trace.artifacts && this._trace.artifacts.sauceRuns)
        .find((item) => item.role && item.role.kind === 'year-structure');
      if (!run) return this._empty(pane);
      this._renderSauceInspector(pane, run, run.id);
    }

    _renderCounters(container, counters) {
      if (!counters) return;
      this._kv(container, ['action', 'target', 'distance', 'connection', 'direction'].map((key) => ({
        label: key,
        value: counters[key],
        exact: true,
      })));
    }

    _sauceStateFor(scope, phases) {
      const existing = this._sauceState.get(scope) || { phase: phases[0], index: 0 };
      if (!phases.includes(existing.phase)) existing.phase = phases[0];
      this._sauceState.set(scope, existing);
      return existing;
    }

    _renderSauceInspector(container, run, scope) {
      const sauce = doc.createElement('section');
      sauce.className = 'sauce';
      const role = run.role && run.role.kind ? String(run.role.kind) : 'Sauce';
      this._heading(sauce, this._term('sauce') + ' · ' + role, 4);
      this._renderCounters(sauce, run.counters);

      const phases = ['stones', 'hidden', 'visible', 'bowls', 'postStirs'];
      const state = this._sauceStateFor(scope, phases);
      const tabs = doc.createElement('div');
      tabs.className = 'phase-tabs';
      for (const phase of phases) {
        const button = doc.createElement('button');
        button.type = 'button';
        button.textContent = this._t(SAUCE_PHASE_KEYS[phase]);
        button.setAttribute('aria-pressed', phase === state.phase ? 'true' : 'false');
        button.addEventListener('click', () => {
          state.phase = phase;
          state.index = 0;
          this._renderChapter();
        });
        tabs.append(button);
      }
      sauce.append(tabs);

      const data = state.phase === 'stones'
        ? safeArray(this._trace.artifacts && this._trace.artifacts.stoneTable && this._trace.artifacts.stoneTable.rows)
        : state.phase === 'hidden' ? safeArray(run.hiddenDrops)
          : state.phase === 'visible' ? safeArray(run.visibleDrops)
            : state.phase === 'bowls' ? safeArray(run.bowlRounds)
              : safeArray(run.postStirs);
      if (!data.length) {
        this._empty(sauce);
        container.append(sauce);
        return;
      }
      state.index = Math.max(0, Math.min(data.length - 1, state.index));
      const controls = doc.createElement('div');
      controls.className = 'step-controls';
      const previous = doc.createElement('button');
      previous.type = 'button';
      previous.textContent = this._t('cooking.previous');
      previous.disabled = state.index <= 0;
      previous.addEventListener('click', () => { state.index = Math.max(0, state.index - 1); this._renderChapter(); });
      const marker = doc.createElement('span');
      marker.className = 'step-index';
      marker.textContent = String(state.index + 1) + ' / ' + String(data.length);
      const next = doc.createElement('button');
      next.type = 'button';
      next.textContent = this._t('cooking.next');
      next.disabled = state.index >= data.length - 1;
      next.addEventListener('click', () => { state.index = Math.min(data.length - 1, state.index + 1); this._renderChapter(); });
      controls.append(previous, marker, next);
      sauce.append(controls);

      const item = data[state.index];
      if (state.phase === 'stones') this._renderStone(sauce, item);
      else if (state.phase === 'hidden') this._renderHidden(sauce, item);
      else if (state.phase === 'visible') this._renderVisible(sauce, item);
      else if (state.phase === 'bowls') this._renderBowlRound(sauce, item);
      else this._renderPostStir(sauce, item);
      container.append(sauce);
    }

    _renderStone(container, row) {
      this._heading(container, this._term('stone') + ' ' + String(row.ordinal), 4);
      this._kv(container, Object.entries(row.values || {}).map(([key, value]) => ({ label: key, value, exact: true })));
      if (row.transition) {
        const grid = doc.createElement('div');
        grid.className = 'mini-grid';
        for (const [label, values] of [
          ['before', row.transition.before],
          ['raw before SAVE', row.transition.rawBeforeSave],
          ['after', row.transition.after],
        ]) {
          const mini = doc.createElement('section');
          mini.className = 'mini';
          const strong = doc.createElement('strong');
          strong.textContent = label;
          mini.append(strong);
          this._kv(mini, Object.entries(values || {}).map(([key, value]) => ({ label: key, value, exact: true })));
          grid.append(mini);
        }
        container.append(grid);
      }
    }

    _renderHidden(container, row) {
      this._heading(container, this._term('hiddenDrop') + ' ' + String(row.ordinal), 4);
      this._kv(container, [
        { label: 'value', value: row.value, exact: true },
        { label: 'rawBeforeSave', value: row.rawBeforeSave, exact: true },
        { label: 'initial', value: row.initial, exact: true },
      ]);
      this._renderGrinds(container, row.grinds);
    }

    _renderVisible(container, row) {
      this._heading(container, this._term('visibleDrop') + ' ' + String(row.ordinal), 4);
      this._kv(container, [
        { label: 'value', value: row.value, exact: true },
        { label: 'prev1', value: row.priors && row.priors.prev1, exact: true },
        { label: 'prev3', value: row.priors && row.priors.prev3, exact: true },
        { label: 'prev7', value: row.priors && row.priors.prev7, exact: true },
        { label: 'rawBeforeSave', value: row.rawBeforeSave, exact: true },
        { label: 'initial', value: row.initial, exact: true },
      ]);
      this._renderGrinds(container, row.grinds);
    }

    _renderGrinds(container, grinds) {
      const list = doc.createElement('ol');
      list.className = 'sequence';
      for (const grind of safeArray(grinds)) {
        const li = doc.createElement('li');
        const title = doc.createElement('strong');
        title.textContent = this._term('grind') + ' ' + String(grind.grind);
        li.append(title);
        this._kv(li, [
          { label: 'before', value: grind.before, exact: true },
          { label: 'stoneValue', value: grind.stoneValue, exact: true },
          { label: 'after', value: grind.after, exact: true },
        ]);
        list.append(li);
      }
      container.append(list);
    }

    _renderBowlRound(container, row) {
      this._heading(container, this._term('bowlRound') + ' ' + String(row.ordinal), 4);
      this._kv(container, [
        { label: 'drop', value: row.drop, exact: true },
        { label: 'order', node: this._arrayValue(row.order) },
        { label: 'poursByPosition', node: this._arrayValue(row.poursByPosition, true) },
        { label: 'beforeBowls', node: this._arrayValue(row.beforeBowls, true) },
        { label: 'afterBowls', node: this._arrayValue(row.afterBowls, true) },
      ]);
      const list = doc.createElement('ol');
      list.className = 'sequence';
      for (const position of safeArray(row.positions)) {
        const li = doc.createElement('li');
        const strong = doc.createElement('strong');
        strong.textContent = this._term('position') + ' ' + String(position.position) + ' · ' + this._term('bowl') + ' ' + String(position.bowlId);
        li.append(strong);
        this._kv(li, [
          { label: 'prevId / nextId', value: String(position.prevId) + ' / ' + String(position.nextId) },
          { label: 'stoneKind', value: position.stoneKind },
          { label: 'mixed', value: position.mixed, exact: true },
          { label: 'rawBeforeSave', value: position.rawBeforeSave, exact: true },
          { label: 'output', value: position.output, exact: true },
        ]);
        list.append(li);
      }
      container.append(list);
    }

    _renderPostStir(container, row) {
      this._heading(container, this._term('postStir') + ' ' + String(row.ordinal), 4);
      this._kv(container, [
        { label: 'rawBowlSum', value: row.rawBowlSum, exact: true },
        { label: 'savedOrderNumber', value: row.savedOrderNumber, exact: true },
        { label: 'order', node: this._arrayValue(row.order) },
        { label: 'beforeBowls', node: this._arrayValue(row.beforeBowls, true) },
        { label: 'afterBowls', node: this._arrayValue(row.afterBowls, true) },
      ]);
      const list = doc.createElement('ol');
      list.className = 'sequence';
      for (const position of safeArray(row.positions)) {
        const li = doc.createElement('li');
        const strong = doc.createElement('strong');
        strong.textContent = this._term('position') + ' ' + String(position.position) + ' · ' + this._term('bowl') + ' ' + String(position.bowlId);
        li.append(strong);
        this._kv(li, [
          { label: 'u', value: position.u, exact: true },
          { label: 'rawBeforeSave', value: position.rawBeforeSave, exact: true },
          { label: 'output', value: position.output, exact: true },
        ]);
        list.append(li);
      }
      container.append(list);
    }

    _renderCutlets(pane) {
      const cutlets = this._trace.artifacts && this._trace.artifacts.structure
        ? this._trace.artifacts.structure.cutlets : null;
      if (!cutlets) return this._empty(pane);
      this._kv(pane, [
        { label: 'count', value: cutlets.count },
        { label: 'partition', node: this._arrayValue(cutlets.partition) },
        { label: 'nameCanonicalIndices', node: this._arrayValue(cutlets.nameCanonicalIndices) },
      ]);
      const items = safeArray(cutlets.items);
      if (!items.length) return;
      const key = 'cutlets';
      const index = this._cursor(key, items.length);
      this._stepControls(pane, key, items.length, () => this._renderChapter());
      const item = items[index];
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, this._term('cutlet') + ' ' + String(index + 1), 4);
      this._kv(card, [
        { label: 'nameCanonicalIndex', value: item.nameCanonicalIndex },
        { label: 'openGateIndex', value: item.openGateIndex, exact: true },
        { label: 'closeGateIndex', value: item.closeGateIndex, exact: true },
        { label: 'firstDay', value: item.firstDay, exact: true },
        { label: 'lastDay', value: item.lastDay, exact: true },
      ]);
      pane.append(card);
    }

    _renderMonths(pane) {
      const months = this._trace.artifacts && this._trace.artifacts.structure
        ? this._trace.artifacts.structure.months : null;
      if (!months) return this._empty(pane);
      this._kv(pane, [
        { label: 'count', value: months.count },
        { label: 'nameCanonicalIndices', node: this._arrayValue(months.nameCanonicalIndices) },
      ]);
      const count = Math.max(safeArray(months.lengths).length, safeArray(months.weaving).length);
      if (!count) return;
      const key = 'months';
      const index = this._cursor(key, count);
      this._stepControls(pane, key, count, () => this._renderChapter());
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, this._term('monthSlot') + ' ' + String(index + 1), 4);
      this._kv(card, [
        { label: 'length', value: months.lengths[index] },
        { label: 'weaving', value: months.weaving[index] },
        { label: 'nameCanonicalIndex', value: months.nameCanonicalIndices[index] },
      ]);
      pane.append(card);
    }

    _renderPosition(pane) {
      const position = this._trace.artifacts && this._trace.artifacts.positioning;
      if (!position) return this._empty(pane);
      this._kv(pane, [
        { label: 'targetDay', value: position.targetDay, exact: true },
        { label: 'targetPositionInYear', value: position.targetPositionInYear },
        { label: 'monthId', value: position.monthId },
        { label: 'dayInCutlet', value: position.dayInCutlet },
        { label: 'dayInMonth', value: position.dayInMonth },
        { label: 'cutletCanonicalIndex', value: position.cutletCanonicalIndex },
        { label: 'monthCanonicalIndex', value: position.monthCanonicalIndex },
      ]);
    }

    _renderResult(pane) {
      const result = this._trace.finalResult;
      if (!result) return this._empty(pane);
      const cutletName = i18n.calendarName(this._locale, 'cutlet', result.cutlet.sourceName);
      const monthName = i18n.calendarName(this._locale, 'month', result.month.sourceName);
      const grid = doc.createElement('div');
      grid.className = 'result-five';
      const values = [
        ['year', result.year],
        ['cutlet', cutletName],
        ['day', result.dayInCutlet],
        ['month', monthName],
        ['day', result.dayInMonth],
      ];
      for (const [label, value] of values) {
        const box = doc.createElement('div');
        const strong = doc.createElement('strong');
        strong.textContent = label;
        const span = doc.createElement('span');
        span.textContent = String(value);
        box.append(strong, span);
        grid.append(box);
      }
      pane.append(grid);
      if (this._trace.measurement) {
        const card = doc.createElement('section');
        card.className = 'step-card';
        this._heading(card, this._term('measurement'), 4);
        this._kv(card, Object.entries(this._trace.measurement).map(([key, value]) => ({
          label: key,
          value,
          exact: /^-?\d+$/.test(String(value)),
        })));
        pane.append(card);
      }
    }

    _empty(container) {
      const p = doc.createElement('p');
      p.className = 'empty';
      p.textContent = this._t('cooking.empty');
      container.append(p);
    }
  }

  ns.cookingComponent = Object.freeze({ PastafariCookingElement });
  if (root.customElements && !root.customElements.get('pastafari-cooking')) {
    root.customElements.define('pastafari-cooking', PastafariCookingElement);
  }
})(typeof globalThis === 'object' ? globalThis : this);
