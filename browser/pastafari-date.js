'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const serviceApi = ns.calendarService;
  const axis = ns.dateAxis;
  const resultApi = ns.resultNormalizer;
  const i18n = ns.i18n;

  if (!serviceApi || !axis || !resultApi || !i18n) {
    throw new Error('Li browser-strate ne esset cargat in li necessi órdine.');
  }

  const MONTH_ACCENTS = Object.freeze([
    '#8a7132', '#3f7b68', '#8b5c4d', '#5d6f9b', '#8b6b8d',
    '#6e7d3c', '#9a6b2f', '#467487', '#7a5f47', '#6b6896',
  ]);
  const MAX_CACHED_CUTLETS = 5;

  function sameMonthRun(previous, current) {
    return previous && previous.monthName === current.monthName
      && current.dayInMonth === previous.dayInMonth + 1;
  }

  function monthAccent(name, palette) {
    if (!palette.has(name)) palette.set(name, MONTH_ACCENTS[palette.size % MONTH_ACCENTS.length]);
    return palette.get(name);
  }

  function escapeSelector(value) {
    if (root.CSS && typeof root.CSS.escape === 'function') return root.CSS.escape(String(value));
    return String(value).replace(/["\\]/g, '\\$&');
  }

  async function getPastafariDateAsync(targetDate, calculationDate) {
    const target = axis.normalizeDateInput(targetDate, 'Li date a examinar');
    const calculation = axis.normalizeDateInput(calculationDate, 'Li die de calculation');
    return resultApi.cloneCanonicalResult(await serviceApi.getSharedCalendarService().convert(
      axis.gregorianToJdn(target),
      axis.gregorianToJdn(calculation),
    ));
  }

  const HTMLElementBase = root.HTMLElement || class {};

  class PastafariDateElement extends HTMLElementBase {
    static get observedAttributes() {
      return ['date', 'calculation-date', 'headless', 'no-editor', 'lang'];
    }

    constructor() {
      super();
      this._connected = false;
      this._refreshQueued = false;
      this._generation = 0;
      this._navigationGeneration = 0;
      this._value = null;
      this._targetJdn = null;
      this._calculationJdn = null;
      this._cutlets = new Map();
      this._orderedStarts = [];
      this._activeStartJdn = null;
      this._loadingBefore = null;
      this._loadingAfter = null;
      this._cutletLoads = new Map();
      this._readySettled = false;
      this._locale = null;
      this.ready = new Promise((resolve) => { this._resolveReady = resolve; });

      if (typeof this.attachShadow !== 'function') return;
      this.attachShadow({ mode: 'open' });
      this.shadowRoot.innerHTML = `
        <style>
          :host {
            display: block;
            max-width: var(--pastafari-max-width, 64rem);
            color: var(--pastafari-color, #28301f);
            font-family: Arial, "Noto Sans Hebrew", sans-serif;
          }
          :host([headless]) { display: none !important; }
          *, *::before, *::after { box-sizing: border-box; }
          button, input, select { font: inherit; }
          .calendar {
            position: relative;
            min-height: 19rem;
            overflow: hidden;
            border: 1px solid var(--pastafari-border, #c9c1a8);
            border-radius: var(--pastafari-radius, 16px);
            background: var(--pastafari-background, #fffdf5);
            box-shadow: var(--pastafari-shadow, 0 10px 32px rgb(66 55 24 / 10%));
          }
          .toolbar {
            display: grid;
            grid-template-columns: 2.85rem minmax(0, 1fr) 2.85rem;
            align-items: center;
            gap: .65rem;
            padding: .85rem 1rem;
            border-bottom: 1px solid var(--pastafari-border, #c9c1a8);
            background: var(--pastafari-header-background, #f4eed8);
          }
          .toolbar-copy { min-width: 0; text-align: center; }
          .eyebrow { margin: 0 0 .2rem; color: #6c6551; font-size: .8rem; }
          .selected-summary {
            margin: 0;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            font-size: clamp(1rem, 2.2vw, 1.2rem);
            line-height: 1.45;
          }
          .nav-button {
            width: 2.65rem;
            height: 2.65rem;
            border: 1px solid transparent;
            border-radius: 50%;
            background: transparent;
            color: inherit;
            font-size: 1.6rem;
            cursor: pointer;
          }
          .nav-button:hover, .nav-button:focus-visible {
            border-color: var(--pastafari-border, #c9c1a8);
            background: #ece3c4;
            outline: none;
          }
          .viewport {
            position: relative;
            max-height: var(--pastafari-calendar-height, 34rem);
            overflow: auto;
            padding: .75rem;
            overscroll-behavior: contain;
            scrollbar-gutter: stable;
            background: var(--pastafari-grid-background, #fffdf8);
          }
          .edge-loader {
            min-height: 1.8rem;
            display: grid;
            place-items: center;
            color: #746d58;
            font-size: .78rem;
          }
          .cutlet { margin: 0 0 1.15rem; scroll-margin-block: .75rem; }
          .cutlet:last-of-type { margin-bottom: 0; }
          .cutlet-heading {
            position: sticky;
            top: -.75rem;
            z-index: 5;
            margin: 0 0 .65rem;
            padding: .72rem .85rem;
            border: 1px solid var(--pastafari-border, #c9c1a8);
            border-radius: .8rem;
            background: color-mix(in srgb, var(--pastafari-header-background, #f4eed8) 92%, white);
            box-shadow: 0 3px 10px rgb(66 55 24 / 8%);
            text-align: center;
            font-size: 1.05rem;
            font-weight: 500;
          }
          .month-run {
            margin: 0 0 .75rem;
            overflow: clip;
            border: 1px solid #ded6bd;
            border-inline-start: .38rem solid var(--month-accent);
            border-radius: .78rem;
            background: #fff;
          }
          .month-run:last-child { margin-bottom: 0; }
          .month-heading {
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            gap: .7rem;
            padding: .48rem .7rem;
            border-bottom: 1px solid #e5dec9;
            background: color-mix(in srgb, var(--month-accent) 10%, white);
          }
          .month-heading strong { font-size: .95rem; }
          .month-range { color: #706955; font-size: .75rem; white-space: nowrap; }
          .days {
            display: grid;
            grid-template-columns: repeat(7, minmax(0, 1fr));
            gap: .4rem;
            padding: .55rem;
          }
          .day {
            position: relative;
            min-height: 4.2rem;
            display: grid;
            align-content: center;
            justify-items: center;
            gap: .15rem;
            border: 1px solid #ded8c5;
            border-radius: .62rem;
            background: #fffefa;
            color: inherit;
            cursor: pointer;
          }
          .day:hover, .day:focus-visible {
            border-color: var(--month-accent);
            background: color-mix(in srgb, var(--month-accent) 7%, white);
            outline: none;
          }
          .day[aria-current="date"] {
            border: 2px solid var(--pastafari-accent, #675817);
            background: #f6ecc5;
            box-shadow: 0 0 0 2px rgb(103 88 23 / 12%);
          }
          .day-in-month { font-size: 1.15rem; font-weight: 850; }
          .day-in-cutlet { color: #756e5b; font-size: .7rem; }
          .footer {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: center;
            gap: .8rem;
            min-height: 2.8rem;
            padding: .55rem .85rem;
            border-top: 1px solid var(--pastafari-border, #c9c1a8);
            background: #fbf7e8;
          }
          .editor-link {
            border: 0;
            border-bottom: 1px dotted currentColor;
            padding: .15rem .05rem;
            background: transparent;
            color: #5f5948;
            font-size: .82rem;
            cursor: pointer;
          }
          :host([no-editor]) .editor-link { display: none; }
          .language-control {
            display: inline-flex;
            align-items: center;
            gap: .35rem;
            color: #5f5948;
            font-size: .78rem;
          }
          .language-control select {
            max-width: 12rem;
            border: 1px solid #c9c0a6;
            border-radius: .45rem;
            padding: .28rem .4rem;
            background: #fff;
            color: inherit;
          }
          .overlay {
            position: absolute;
            inset: 0;
            z-index: 20;
            display: grid;
            place-content: center;
            justify-items: center;
            gap: .75rem;
            min-height: 19rem;
            padding: 2rem;
            text-align: center;
            background: var(--pastafari-background, #fffdf5);
          }
          .overlay[hidden] { display: none; }
          .spinner {
            width: 3.1rem;
            height: 3.1rem;
            border: .32rem solid #ddd5bc;
            border-top-color: var(--pastafari-accent, #675817);
            border-radius: 50%;
            animation: spin .9s linear infinite;
          }
          .loading-title { margin: 0; font-weight: 850; }
          .loading-note, .error-message { margin: 0; color: #69624f; font-size: .84rem; }
          .retry-button {
            border: 1px solid #a99d78;
            border-radius: .65rem;
            padding: .55rem .9rem;
            background: #f4edd5;
            color: inherit;
            cursor: pointer;
          }
          @keyframes spin { to { transform: rotate(1turn); } }
          @media (prefers-reduced-motion: reduce) { .spinner { animation-duration: 3s; } }
          @media (max-width: 38rem) {
            .days { gap: .28rem; padding: .42rem; }
            .day { min-height: 3.55rem; }
            .day-in-month { font-size: 1rem; }
            .day-in-cutlet { font-size: .64rem; }
          }
          dialog {
            width: min(28rem, calc(100vw - 2rem));
            border: 1px solid #bbb092;
            border-radius: 1rem;
            padding: 0;
            color: inherit;
            background: #fffdf7;
            box-shadow: 0 24px 70px rgb(0 0 0 / 28%);
          }
          dialog::backdrop { background: rgb(27 24 16 / 40%); }
          .dialog-form { display: grid; gap: 1rem; padding: 1.1rem; }
          .dialog-form h2 { margin: 0; font-size: 1.2rem; }
          .field { display: grid; gap: .35rem; }
          .field span { font-size: .86rem; font-weight: 750; }
          .field input {
            width: 100%;
            direction: ltr;
            border: 1px solid #c9c0a6;
            border-radius: .55rem;
            padding: .58rem .68rem;
            background: white;
          }
          details { border-top: 1px solid #e0d8c0; padding-top: .75rem; }
          summary { color: #625c4a; font-size: .82rem; cursor: pointer; }
          details .field { margin-top: .75rem; }
          .dialog-error { min-height: 1.1rem; margin: 0; color: #922; font-size: .8rem; }
          .dialog-actions { display: flex; justify-content: flex-start; gap: .55rem; }
          .dialog-actions button {
            border: 1px solid #b9ae8d;
            border-radius: .58rem;
            padding: .55rem .85rem;
            background: #f4edd5;
            cursor: pointer;
          }
          .dialog-actions .primary { background: #675817; color: white; border-color: #675817; }
        </style>

        <section class="calendar" part="calendar" aria-busy="true">
          <header class="toolbar" part="toolbar">
            <button class="nav-button previous" type="button"></button>
            <div class="toolbar-copy">
              <p class="eyebrow"></p>
              <p class="selected-summary" aria-live="polite"></p>
            </div>
            <button class="nav-button next" type="button"></button>
          </header>

          <div class="viewport" part="viewport" tabindex="0">
            <div class="edge-loader before" aria-hidden="true"></div>
            <div class="cutlet-list"></div>
            <div class="edge-loader after" aria-hidden="true"></div>
          </div>

          <footer class="footer" part="footer">
            <button class="editor-link" type="button"></button>
            <label class="language-control">
              <span class="language-label"></span>
              <select class="language-selector"></select>
            </label>
          </footer>

          <div class="overlay loading" part="loading">
            <div class="spinner" aria-hidden="true"></div>
            <p class="loading-title"></p>
            <p class="loading-note"></p>
          </div>

          <div class="overlay error" part="error" hidden>
            <p class="loading-title error-title"></p>
            <p class="error-message"></p>
            <button class="retry-button" type="button"></button>
          </div>
        </section>

        <dialog>
          <form class="dialog-form" method="dialog" novalidate>
            <h2></h2>
            <label class="field target-field">
              <span></span>
              <input name="target" inputmode="numeric" autocomplete="off" placeholder="YYYY-MM-DD" required>
            </label>
            <details>
              <summary></summary>
              <label class="field calculation-field">
                <span></span>
                <input name="calculation" inputmode="numeric" autocomplete="off" placeholder="YYYY-MM-DD">
              </label>
            </details>
            <p class="dialog-error" role="alert"></p>
            <div class="dialog-actions">
              <button class="primary" value="apply" type="submit"></button>
              <button value="cancel" type="button"></button>
            </div>
          </form>
        </dialog>
      `;

      this._els = {
        calendar: this.shadowRoot.querySelector('.calendar'),
        toolbar: this.shadowRoot.querySelector('.toolbar'),
        previous: this.shadowRoot.querySelector('.previous'),
        next: this.shadowRoot.querySelector('.next'),
        eyebrow: this.shadowRoot.querySelector('.eyebrow'),
        summary: this.shadowRoot.querySelector('.selected-summary'),
        viewport: this.shadowRoot.querySelector('.viewport'),
        list: this.shadowRoot.querySelector('.cutlet-list'),
        beforeLoader: this.shadowRoot.querySelector('.edge-loader.before'),
        afterLoader: this.shadowRoot.querySelector('.edge-loader.after'),
        editorLink: this.shadowRoot.querySelector('.editor-link'),
        languageLabel: this.shadowRoot.querySelector('.language-label'),
        languageSelector: this.shadowRoot.querySelector('.language-selector'),
        loading: this.shadowRoot.querySelector('.overlay.loading'),
        loadingTitle: this.shadowRoot.querySelector('.overlay.loading .loading-title'),
        loadingNote: this.shadowRoot.querySelector('.loading-note'),
        error: this.shadowRoot.querySelector('.overlay.error'),
        errorTitle: this.shadowRoot.querySelector('.error-title'),
        errorMessage: this.shadowRoot.querySelector('.error-message'),
        retryButton: this.shadowRoot.querySelector('.retry-button'),
        dialog: this.shadowRoot.querySelector('dialog'),
        form: this.shadowRoot.querySelector('form'),
        dialogHeading: this.shadowRoot.querySelector('.dialog-form h2'),
        targetLabel: this.shadowRoot.querySelector('.target-field span'),
        calculationSummary: this.shadowRoot.querySelector('details summary'),
        calculationLabel: this.shadowRoot.querySelector('.calculation-field span'),
        targetInput: this.shadowRoot.querySelector('input[name="target"]'),
        calculationInput: this.shadowRoot.querySelector('input[name="calculation"]'),
        dialogError: this.shadowRoot.querySelector('.dialog-error'),
        applyButton: this.shadowRoot.querySelector('.dialog-actions .primary'),
        cancelButton: this.shadowRoot.querySelector('.dialog-actions button[value="cancel"]'),
      };

      this._els.previous.addEventListener('click', () => this._scrollAdjacent(-1));
      this._els.next.addEventListener('click', () => this._scrollAdjacent(1));
      this._els.editorLink.addEventListener('click', () => this._openDialog());
      this._els.retryButton.addEventListener('click', () => this._retry());
      this._els.cancelButton.addEventListener('click', () => this._closeDialog());
      this._els.form.addEventListener('submit', (event) => this._applyDialog(event));
      this._els.viewport.addEventListener('scroll', () => this._onScroll(), { passive: true });
      this._els.list.addEventListener('click', (event) => this._selectDay(event));
      this._els.languageSelector.addEventListener('change', () => {
        this.setAttribute('lang', this._els.languageSelector.value);
      });
      this._applyLocale();
    }

    connectedCallback() {
      this._connected = true;
      this._applyLocale();
      this._queueRefresh();
    }

    disconnectedCallback() {
      this._connected = false;
      this._generation += 1;
      this._navigationGeneration += 1;
      this._cutletLoads.clear();
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === newValue || !this._connected) return;
      if (name === 'no-editor') return;
      if (name === 'lang') {
        this._applyLocale();
        if (this._value) {
          this._renderSummary();
          this._renderCutlets();
        }
        return;
      }
      this._queueRefresh();
    }

    get value() {
      return this._value;
    }

    _t(key, values) {
      return i18n.translate(this._locale, key, values);
    }

    _localCalendarName(group, sourceName) {
      return i18n.calendarName(this._locale, group, sourceName);
    }

    _applyLocale() {
      const explicit = this.getAttribute && this.getAttribute('lang');
      const browserLanguages = root.navigator && Array.isArray(root.navigator.languages)
        ? root.navigator.languages : [];
      this._locale = i18n.resolveLocale(explicit, browserLanguages);
      if (!this._els) return;
      this.setAttribute('dir', this._locale.dir);
      this._els.calendar.setAttribute('dir', this._locale.dir);
      this._els.toolbar.setAttribute('aria-label', this._t('calendar.toolbarAria'));
      this._els.previous.setAttribute('aria-label', this._t('calendar.previous'));
      this._els.next.setAttribute('aria-label', this._t('calendar.next'));
      this._els.previous.textContent = this._locale.dir === 'rtl' ? '›' : '‹';
      this._els.next.textContent = this._locale.dir === 'rtl' ? '‹' : '›';
      this._els.eyebrow.textContent = this._t('app.title');
      if (!this._value) this._els.summary.textContent = this._t('loading.title');
      this._els.editorLink.textContent = this._t('search.kicker');
      this._els.languageLabel.textContent = this._t('language.label');
      this._els.loadingTitle.textContent = this._t('loading.title');
      this._els.loadingNote.textContent = this._t('loading.kicker');
      this._els.errorTitle.textContent = this._t('error.kicker');
      this._els.retryButton.textContent = this._t('error.reload');
      this._els.dialogHeading.textContent = this._t('search.heading');
      this._els.targetLabel.textContent = this._t('search.kicker');
      this._els.calculationSummary.textContent = this._t('settings.summary');
      this._els.calculationLabel.textContent = this._t('settings.heading');
      this._els.applyButton.textContent = this._t('search.submit');
      this._els.cancelButton.textContent = this._t('reverse.action.cancel');

      const locales = i18n.supportedLocales();
      const current = this._locale.code;
      const fragment = document.createDocumentFragment();
      for (const locale of locales) {
        const option = document.createElement('option');
        option.value = locale.code;
        option.textContent = locale.displayName;
        if (locale.code === current) option.selected = true;
        fragment.append(option);
      }
      this._els.languageSelector.replaceChildren(fragment);
      this._els.languageSelector.setAttribute('aria-label', this._t('language.label'));
    }

    async refresh() {
      const generation = ++this._generation;
      const targetDate = axis.normalizeDateInput(this.getAttribute('date'), 'Li date a examinar');
      const calculationDate = axis.normalizeDateInput(this.getAttribute('calculation-date'), 'Li die de calculation');
      const targetJdn = axis.gregorianToJdn(targetDate);
      const calculationJdn = axis.gregorianToJdn(calculationDate);
      const headless = this.hasAttribute('headless');
      const service = serviceApi.getSharedCalendarService();

      this._targetJdn = targetJdn;
      this._calculationJdn = calculationJdn;
      this._cutlets.clear();
      this._orderedStarts = [];
      this._activeStartJdn = null;
      this._loadingBefore = null;
      this._loadingAfter = null;
      this._cutletLoads.clear();
      this._navigationGeneration += 1;

      if (headless) {
        if (this._els && this._els.list) this._els.list.replaceChildren();
        if (this._els && this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'true');
      } else {
        this._showLoading();
      }

      try {
        if (headless) {
          const value = await service.convert(targetJdn, calculationJdn);
          if (generation !== this._generation) return null;
          this._value = resultApi.cloneCanonicalResult(value);
          this._hideOverlays();
          if (this._els && this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'false');
          this._publishValue();
          return this._value;
        }

        const values = await Promise.all([
          service.convert(targetJdn, calculationJdn),
          service.getCutletView(targetJdn, calculationJdn),
        ]);
        if (generation !== this._generation) return null;
        this._value = resultApi.cloneCanonicalResult(values[0]);
        const currentView = values[1];
        this._storeCutlet(currentView);
        this._activeStartJdn = BigInt(currentView.startJdn);
        this._renderSummary();
        this._renderCutlets();
        this._hideOverlays();
        this._els.calendar.setAttribute('aria-busy', 'false');
        queueMicrotask(() => this._scrollSelectedIntoView());
        this._publishValue();
        this._primeAdjacent(currentView, generation);
        return this._value;
      } catch (error) {
        if (generation !== this._generation) return null;
        if (!headless) this._showError(error);
        else if (this._els && this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'false');
        throw error;
      }
    }

    _publishValue() {
      if (!this._readySettled) {
        this._readySettled = true;
        this._resolveReady(this._value);
      }
      this.dispatchEvent(new CustomEvent('pastafari-change', {
        bubbles: true,
        composed: true,
        detail: this._value,
      }));
    }

    _queueRefresh() {
      if (this._refreshQueued) return;
      this._refreshQueued = true;
      queueMicrotask(() => {
        this._refreshQueued = false;
        if (this._connected) this.refresh().catch(() => {});
      });
    }

    _storeCutlet(view) {
      const start = BigInt(view.startJdn);
      if (this._cutlets.has(start)) return false;
      this._cutlets.set(start, view);
      this._orderedStarts = Array.from(this._cutlets.keys()).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
      return true;
    }

    _primeAdjacent(currentView, generation) {
      Promise.allSettled([
        this._loadCutletAt(currentView.previousCutletJdn, 'before', generation),
        this._loadCutletAt(currentView.nextCutletJdn, 'after', generation),
      ]).catch(() => {});
    }

    _loadCutletAt(targetJdn, direction, generation) {
      const generationValue = generation == null ? this._generation : generation;
      const target = BigInt(targetJdn);
      const key = generationValue + ':' + target;
      if (this._cutletLoads.has(key)) return this._cutletLoads.get(key);
      const task = this._loadCutletAtOnce(target, direction, generationValue);
      this._cutletLoads.set(key, task);
      task.finally(() => {
        if (this._cutletLoads.get(key) === task) this._cutletLoads.delete(key);
      }).catch(() => {});
      return task;
    }

    async _loadCutletAtOnce(targetJdn, direction, generation) {
      const flag = direction === 'before' ? '_loadingBefore' : '_loadingAfter';
      if (this[flag] === generation) return null;
      this[flag] = generation;
      this._updateEdgeLoaders();
      try {
        const view = await serviceApi.getSharedCalendarService().getCutletView(targetJdn, this._calculationJdn);
        if (generation !== this._generation) return null;
        if (!this._storeCutlet(view)) return view;
        const anchor = this._captureScrollAnchor();
        this._trimCutlets(view.startJdn);
        this._renderCutlets();
        this._restoreScrollAnchor(anchor);
        return view;
      } finally {
        if (this[flag] === generation) {
          this[flag] = null;
          this._updateEdgeLoaders();
        }
      }
    }

    _trimCutlets(fallbackStartJdn) {
      if (this._orderedStarts.length <= MAX_CACHED_CUTLETS) return;
      const preferred = this._activeStartJdn != null && this._cutlets.has(this._activeStartJdn)
        ? this._activeStartJdn : BigInt(fallbackStartJdn);
      const preferredIndex = Math.max(0, this._orderedStarts.findIndex((start) => start === preferred));
      const firstKeep = Math.max(0, Math.min(
        preferredIndex - Math.floor(MAX_CACHED_CUTLETS / 2),
        this._orderedStarts.length - MAX_CACHED_CUTLETS,
      ));
      const keep = new Set(this._orderedStarts.slice(firstKeep, firstKeep + MAX_CACHED_CUTLETS));
      for (const start of this._orderedStarts) if (!keep.has(start)) this._cutlets.delete(start);
      this._orderedStarts = this._orderedStarts.filter((start) => keep.has(start));
    }

    _captureScrollAnchor() {
      const viewport = this._els.viewport;
      const sections = Array.from(this._els.list.querySelectorAll('.cutlet'));
      if (sections.length === 0) return null;
      const viewportTop = viewport.getBoundingClientRect().top;
      let anchor = sections[0];
      for (const section of sections) {
        if (section.getBoundingClientRect().top <= viewportTop + 1) anchor = section;
        else break;
      }
      return {
        startJdn: anchor.dataset.startJdn,
        offset: anchor.getBoundingClientRect().top - viewportTop,
      };
    }

    _restoreScrollAnchor(anchor) {
      if (!anchor) return;
      const viewport = this._els.viewport;
      const section = this._els.list.querySelector('[data-start-jdn="' + escapeSelector(anchor.startJdn) + '"]');
      if (!section) return;
      const newOffset = section.getBoundingClientRect().top - viewport.getBoundingClientRect().top;
      viewport.scrollTop += newOffset - anchor.offset;
    }

    _renderSummary() {
      if (!this._value) return;
      const cutletName = this._localCalendarName('cutlet', this._value.cutletName);
      const monthName = this._localCalendarName('month', this._value.monthName);
      this._els.summary.textContent = this._t('date.cutletLine', {
        dayInCutlet: this._value.dayInCutlet,
        cutletName,
      }) + ' · ' + this._t('date.monthLine', {
        dayInMonth: this._value.dayInMonth,
        monthName,
      });
    }

    _renderCutlets() {
      const fragment = document.createDocumentFragment();
      for (const startJdn of this._orderedStarts) {
        fragment.append(this._renderCutlet(this._cutlets.get(startJdn)));
      }
      this._els.list.replaceChildren(fragment);
    }

    _renderCutlet(view) {
      const section = document.createElement('section');
      const localCutlet = this._localCalendarName('cutlet', view.cutletName);
      section.className = 'cutlet';
      section.dataset.startJdn = String(view.startJdn);
      section.dataset.endJdn = String(view.endJdn);
      section.setAttribute('aria-label', this._t('calendar.daysAria', { cutletName: localCutlet }));

      const heading = document.createElement('h2');
      heading.className = 'cutlet-heading';
      heading.textContent = this._t('calendar.currentCutlet', { year: view.year }) + ' ' + localCutlet;
      section.append(heading);

      const palette = new Map();
      let run = [];
      for (const day of view.days) {
        if (run.length > 0 && !sameMonthRun(run[run.length - 1], day)) {
          section.append(this._renderMonthRun(run, palette));
          run = [];
        }
        run.push(day);
      }
      if (run.length > 0) section.append(this._renderMonthRun(run, palette));
      return section;
    }

    _renderMonthRun(days, palette) {
      const first = days[0];
      const last = days[days.length - 1];
      const localMonth = this._localCalendarName('month', first.monthName);
      const group = document.createElement('section');
      group.className = 'month-run';
      group.style.setProperty('--month-accent', monthAccent(first.monthName, palette));

      const heading = document.createElement('header');
      heading.className = 'month-heading';
      const title = document.createElement('strong');
      title.textContent = localMonth;
      const range = document.createElement('span');
      range.className = 'month-range';
      range.textContent = this._t('field.day') + ' ' + (
        first.dayInMonth === last.dayInMonth
          ? String(first.dayInMonth)
          : String(first.dayInMonth) + '–' + String(last.dayInMonth)
      );
      heading.append(title, range);

      const grid = document.createElement('div');
      grid.className = 'days';
      for (const day of days) {
        const localDayCutlet = this._localCalendarName('cutlet', day.cutletName);
        const localDayMonth = this._localCalendarName('month', day.monthName);
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'day';
        button.dataset.jdn = String(day.jdn);
        button.style.setProperty('--month-accent', monthAccent(day.monthName, palette));
        button.setAttribute('aria-label', this._t('date.aria', {
          year: day.year,
          dayInCutlet: day.dayInCutlet,
          cutletName: localDayCutlet,
          dayInMonth: day.dayInMonth,
          monthName: localDayMonth,
        }));
        if (BigInt(day.jdn) === this._targetJdn) button.setAttribute('aria-current', 'date');

        const monthDay = document.createElement('span');
        monthDay.className = 'day-in-month';
        monthDay.textContent = String(day.dayInMonth);
        const cutletDay = document.createElement('span');
        cutletDay.className = 'day-in-cutlet';
        cutletDay.textContent = this._t('field.day') + ' ' + String(day.dayInCutlet);
        button.append(monthDay, cutletDay);
        grid.append(button);
      }
      group.append(heading, grid);
      return group;
    }

    _selectDay(event) {
      const button = event.target.closest('button.day[data-jdn]');
      if (!button) return;
      this.setAttribute('date', axis.toIsoDate(axis.jdnToGregorian(BigInt(button.dataset.jdn))));
    }

    _scrollSelectedIntoView() {
      const selected = this._els.list.querySelector('[aria-current="date"]');
      if (selected) selected.scrollIntoView({ block: 'center', inline: 'nearest' });
      const section = selected && selected.closest('.cutlet');
      if (section) this._activeStartJdn = BigInt(section.dataset.startJdn);
    }

    async _scrollAdjacent(direction) {
      if (this._orderedStarts.length === 0) return false;
      const generation = this._generation;
      const navigationGeneration = ++this._navigationGeneration;
      const currentIndex = this._activeStartJdn == null
        ? this._orderedStarts.findIndex((start) => (
          this._targetJdn >= start && this._targetJdn <= BigInt(this._cutlets.get(start).endJdn)
        ))
        : this._orderedStarts.findIndex((start) => start === this._activeStartJdn);
      if (currentIndex < 0) return false;

      let start = this._orderedStarts[currentIndex + direction];
      if (start === undefined) {
        const current = this._cutlets.get(this._orderedStarts[currentIndex]);
        if (!current) return false;
        const requested = direction < 0 ? current.previousCutletJdn : current.nextCutletJdn;
        let loaded;
        try {
          loaded = await this._loadCutletAt(requested, direction < 0 ? 'before' : 'after', generation);
        } catch (_) {
          return false;
        }
        if (!loaded || !this._connected || generation !== this._generation
            || navigationGeneration !== this._navigationGeneration) return false;
        start = BigInt(loaded.startJdn);
      }

      if (!this._connected || generation !== this._generation
          || navigationGeneration !== this._navigationGeneration) return false;
      const section = this._els.list.querySelector('[data-start-jdn="' + escapeSelector(String(start)) + '"]');
      if (!section) return false;
      section.scrollIntoView({ behavior: 'auto', block: 'start' });
      this._activeStartJdn = start;

      const resolvedIndex = this._orderedStarts.findIndex((candidate) => candidate === start);
      if (direction < 0 && resolvedIndex === 0) {
        const first = this._cutlets.get(start);
        if (first) this._loadCutletAt(first.previousCutletJdn, 'before', generation).catch(() => {});
      } else if (direction > 0 && resolvedIndex === this._orderedStarts.length - 1) {
        const last = this._cutlets.get(start);
        if (last) this._loadCutletAt(last.nextCutletJdn, 'after', generation).catch(() => {});
      }
      return true;
    }

    _onScroll() {
      const viewport = this._els.viewport;
      const sections = Array.from(this._els.list.querySelectorAll('.cutlet'));
      if (sections.length > 0) {
        const top = viewport.getBoundingClientRect().top + 18;
        let active = sections[0];
        for (const section of sections) {
          if (section.getBoundingClientRect().top <= top) active = section;
          else break;
        }
        this._activeStartJdn = BigInt(active.dataset.startJdn);
      }

      if (viewport.scrollTop < 180 && this._orderedStarts.length > 0) {
        const first = this._cutlets.get(this._orderedStarts[0]);
        this._loadCutletAt(first.previousCutletJdn, 'before').catch(() => {});
      }
      if (viewport.scrollHeight - viewport.scrollTop - viewport.clientHeight < 180
          && this._orderedStarts.length > 0) {
        const last = this._cutlets.get(this._orderedStarts[this._orderedStarts.length - 1]);
        this._loadCutletAt(last.nextCutletJdn, 'after').catch(() => {});
      }
    }

    _updateEdgeLoaders() {
      this._els.beforeLoader.textContent = this._loadingBefore !== null ? '…' : '';
      this._els.afterLoader.textContent = this._loadingAfter !== null ? '…' : '';
    }

    _openDialog() {
      this._els.dialogError.textContent = '';
      this._els.targetInput.value = axis.toIsoDate(axis.jdnToGregorian(
        this._targetJdn == null ? axis.gregorianToJdn(axis.localToday()) : this._targetJdn,
      ));
      this._els.calculationInput.value = this.hasAttribute('calculation-date')
        ? this.getAttribute('calculation-date') : axis.toIsoDate(axis.localToday());
      if (typeof this._els.dialog.showModal === 'function') this._els.dialog.showModal();
      else this._els.dialog.setAttribute('open', '');
    }

    _closeDialog() {
      if (typeof this._els.dialog.close === 'function') this._els.dialog.close();
      else this._els.dialog.removeAttribute('open');
    }

    _applyDialog(event) {
      event.preventDefault();
      try {
        const target = axis.parseIsoDate(this._els.targetInput.value, 'Li date a examinar');
        const calculationText = this._els.calculationInput.value.trim();
        const calculation = calculationText === ''
          ? axis.localToday()
          : axis.parseIsoDate(calculationText, 'Li die de calculation');
        this._els.dialogError.textContent = '';
        this.setAttribute('date', axis.toIsoDate(target));
        const todayIso = axis.toIsoDate(axis.localToday());
        const calculationIso = axis.toIsoDate(calculation);
        if (calculationIso === todayIso) this.removeAttribute('calculation-date');
        else this.setAttribute('calculation-date', calculationIso);
        this._closeDialog();
      } catch (_) {
        this._els.dialogError.textContent = this._t('search.invalid');
      }
    }

    async _retry() {
      try {
        await serviceApi.getSharedCalendarService().retry(this._calculationJdn);
      } finally {
        this.refresh().catch(() => {});
      }
    }

    _showLoading() {
      if (this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'true');
      if (this._els.loading) this._els.loading.hidden = false;
      if (this._els.error) this._els.error.hidden = true;
    }

    _hideOverlays() {
      if (this._els.loading) this._els.loading.hidden = true;
      if (this._els.error) this._els.error.hidden = true;
    }

    _showError(error) {
      if (this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'false');
      if (this._els.loading) this._els.loading.hidden = true;
      if (this._els.error) this._els.error.hidden = false;
      if (root.console && typeof root.console.error === 'function') root.console.error(error);
      if (this._els.errorMessage) this._els.errorMessage.textContent = this._t('error.engineFailed');
    }
  }

  const api = Object.freeze({
    getPastafariDateAsync,
    getPastafariDate: getPastafariDateAsync,
    PastafariDateElement,
    installSharedCalendarService: serviceApi.installSharedCalendarService,
    installSharedCalendarMemory: serviceApi.installSharedCalendarMemory,
  });

  root.PastafariCalendarBrowser = api;
  if (root.customElements && !root.customElements.get('pastafari-date')) {
    root.customElements.define('pastafari-date', PastafariDateElement);
  }
})(typeof globalThis === 'object' ? globalThis : this);
