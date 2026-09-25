'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const serviceApi = ns.calendarService;
  const axis = ns.dateAxis;
  const resultApi = ns.resultNormalizer;
  const i18n = ns.i18n;
  const reverseApi = ns.reverseBridge || null;

  if (!serviceApi || !axis || !resultApi || !i18n) {
    throw new Error('Li browser-strate ne esset cargat in li necessi órdine.');
  }

  // Current semantic month names, never old positional identifiers. Each month
  // keeps a deterministic hue identity, but the public calendar uses a light
  // paper-like wash so month coding supports the content instead of dominating it.
  const MONTH_THEME_NAMES = Object.freeze([
    'argile', 'granat', 'cubit', 'invidie', 'Eridu', 'dent-pasta',
    'tri partes de quin', 'Karshumav', 'leopard', 'stann', 'brume', 'oliban',
    'fus', 'costa', 'carob', 'Uruk', 'honte', 'camel', 'cupr', 'pute',
    'vitelle', 'stelle', 'mel', 'splen', 'calcari', 'joy', 'fig', 'Ninive',
    'ran', 'pech', 'lampe', 'li cludet porta', 'sesam', 'nuca', 'argent',
    'Susa', 'tempeste', 'asin', 'farine', 'regret', 'Babylon', 'lingue',
    'lin', 'sal', 'pir', 'arc', 'sand',
  ]);
  const MONTH_THEME_INDEX = new Map(MONTH_THEME_NAMES.map((name, index) => [name, index]));
  const MONTH_THEMES = Object.freeze(MONTH_THEME_NAMES.map((name, index) => {
    const hue = Math.round((index * 137.508) % 360);
    const secondaryHue = Math.round((hue + 151 + ((index % 3) * 17)) % 360);
    const angle = (index * 37) % 180;
    return Object.freeze({
      edge: `hsl(${hue} 58% 34%)`,
      bg: `hsl(${hue} 62% 88%)`,
      wash: `hsl(${secondaryHue} 64% 82%)`,
      pattern: `repeating-linear-gradient(${angle}deg, transparent 0 72%, hsl(${secondaryHue} 64% 70% / 28%) 72% 80%, transparent 80% 100%)`,
    });
  }));
  const MAX_CACHED_CUTLETS = 5;
  const MAX_RENDERED_DAYS = 28;
  const LOCALE_STORAGE_KEY = 'pastafari.browser.locale';
  const RENDER_CONSISTENCY_CODE = 'ERR_CALENDAR_RENDER_INCONSISTENCY';
  const TARGET_CUTLET_CODE = 'ERR_TARGET_CUTLET_MISMATCH';

  class CalendarRenderConsistencyError extends Error {
    constructor(jdn, first, second) {
      super('Li browser-view contene du semanticmen different cards por JDN ' + String(jdn) + '.');
      this.name = 'CalendarRenderConsistencyError';
      this.code = RENDER_CONSISTENCY_CODE;
      this.jdn = String(jdn);
      this.first = first;
      this.second = second;
    }
  }

  class CalendarTargetCutletError extends Error {
    constructor(jdn, expected, actual, reason) {
      super('Li cutlet selectet por li searched date ne concorda con su complet semantic date.');
      this.name = 'CalendarTargetCutletError';
      this.code = TARGET_CUTLET_CODE;
      this.jdn = String(jdn);
      this.expected = expected;
      this.actual = actual;
      this.reason = String(reason || 'target-cutlet-mismatch');
    }
  }

  function sameDaySemantics(first, second) {
    return String(first.year) === String(second.year)
      && String(first.cutletName) === String(second.cutletName)
      && Number(first.dayInCutlet) === Number(second.dayInCutlet)
      && String(first.monthName) === String(second.monthName)
      && Number(first.dayInMonth) === Number(second.dayInMonth);
  }

  function semanticDaySnapshot(day) {
    return Object.freeze({
      year: String(day.year),
      cutletName: String(day.cutletName),
      dayInCutlet: Number(day.dayInCutlet),
      monthName: String(day.monthName),
      dayInMonth: Number(day.dayInMonth),
    });
  }


  function createScrollTarget(targetJdn, value) {
    const semantic = semanticDaySnapshot(value);
    if (!Number.isSafeInteger(semantic.dayInCutlet) || semantic.dayInCutlet < 1) {
      throw new RangeError('Li dayInCutlet del searched date deve esser un positiv secur integer.');
    }
    if (!Number.isSafeInteger(semantic.dayInMonth) || semantic.dayInMonth < 1) {
      throw new RangeError('Li dayInMonth del searched date deve esser un positiv secur integer.');
    }
    const jdn = BigInt(targetJdn);
    return Object.freeze({
      jdn,
      startJdn: jdn - BigInt(semantic.dayInCutlet - 1),
      ...semantic,
    });
  }

  function sameScrollTargetDay(day, target) {
    return !!day && !!target
      && BigInt(day.jdn) === BigInt(target.jdn)
      && sameDaySemantics(day, target);
  }

  function resolveTargetCutletView(view, target) {
    const actualMeta = Object.freeze({
      startJdn: view && view.startJdn != null ? String(view.startJdn) : null,
      selectedJdn: view && view.selectedJdn != null ? String(view.selectedJdn) : null,
      selectedIndex: view && view.selectedIndex != null ? Number(view.selectedIndex) : null,
      year: view && view.year != null ? String(view.year) : null,
      cutletName: view && view.cutletName != null ? String(view.cutletName) : null,
    });
    if (!view || typeof view !== 'object' || !Array.isArray(view.days)) {
      throw new CalendarTargetCutletError(target.jdn, target, actualMeta, 'invalid-view');
    }
    if (BigInt(view.startJdn) !== target.startJdn) {
      throw new CalendarTargetCutletError(target.jdn, target, actualMeta, 'wrong-start');
    }
    if (String(view.year) !== target.year || String(view.cutletName) !== target.cutletName) {
      throw new CalendarTargetCutletError(target.jdn, target, actualMeta, 'wrong-cutlet-identity');
    }
    if (BigInt(view.selectedJdn) !== target.startJdn || Number(view.selectedIndex) !== 0) {
      throw new CalendarTargetCutletError(target.jdn, target, actualMeta, 'view-not-selected-at-start');
    }

    const targetIndex = target.dayInCutlet - 1;
    const first = view.days[0];
    const targetDay = view.days[targetIndex];
    if (!first || BigInt(first.jdn) !== target.startJdn
        || String(first.year) !== target.year || String(first.cutletName) !== target.cutletName
        || Number(first.dayInCutlet) !== 1) {
      throw new CalendarTargetCutletError(
        target.jdn,
        target,
        first ? semanticDaySnapshot(first) : Object.freeze({ missingFirstDay: true }),
        'invalid-cutlet-start',
      );
    }
    if (!sameScrollTargetDay(targetDay, target)) {
      throw new CalendarTargetCutletError(
        target.jdn,
        target,
        targetDay ? semanticDaySnapshot(targetDay) : Object.freeze({ missingTargetIndex: targetIndex }),
        'target-not-in-expected-cutlet-position',
      );
    }
    return view;
  }

  const doc = root.document || null;
  const enqueueMicrotask = typeof root.queueMicrotask === 'function'
    ? root.queueMicrotask.bind(root)
    : (callback) => Promise.resolve().then(callback);

  function nextLayoutFrame() {
    return new Promise((resolve) => {
      if (typeof root.requestAnimationFrame === 'function') {
        root.requestAnimationFrame(() => resolve());
      } else {
        enqueueMicrotask(resolve);
      }
    });
  }

  function sameMonthRun(previous, current) {
    return previous && previous.monthName === current.monthName
      && current.dayInMonth === previous.dayInMonth + 1;
  }

  function semanticHash(value) {
    let hash = 2166136261;
    const text = String(value);
    for (let index = 0; index < text.length; index += 1) {
      hash ^= text.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
  }

  function monthTheme(name) {
    const exactIndex = MONTH_THEME_INDEX.get(String(name));
    if (exactIndex !== undefined) return MONTH_THEMES[exactIndex];
    return MONTH_THEMES[semanticHash(name) % MONTH_THEMES.length];
  }

  function applyMonthTheme(element, name) {
    const theme = monthTheme(name);
    element.style.setProperty('--month-edge', theme.edge);
    element.style.setProperty('--month-bg', theme.bg);
    element.style.setProperty('--month-wash', theme.wash);
    element.style.setProperty('--month-pattern-image', theme.pattern);
    element.style.setProperty('--month-ink', '#111111');
    element.style.setProperty('--month-text-bg', '#fffdf8');
    return theme;
  }

  function readStoredLocale() {
    try {
      if (!root.localStorage || typeof root.localStorage.getItem !== 'function') return null;
      const value = root.localStorage.getItem(LOCALE_STORAGE_KEY);
      return typeof value === 'string' && value.trim() !== '' ? value.trim() : null;
    } catch (_) {
      return null;
    }
  }

  function writeStoredLocale(value) {
    try {
      if (root.localStorage && typeof root.localStorage.setItem === 'function') {
        root.localStorage.setItem(LOCALE_STORAGE_KEY, String(value));
      }
    } catch (_) {
      // Language selection must remain usable when storage is disabled.
    }
  }

  async function getPastafariDateAsync(targetDate, calculationDate) {
    const target = axis.normalizeDateInput(targetDate, 'Li date a examinar');
    const calculation = axis.normalizeDateInput(calculationDate, 'Li die de calculation');
    return resultApi.cloneCanonicalResult(await serviceApi.getSharedCalendarService().convert(
      axis.gregorianToJdn(target),
      axis.gregorianToJdn(calculation),
    ));
  }

  async function getPastafariCookingTraceAsync(targetDate, calculationDate, options = null) {
    const target = axis.normalizeDateInput(targetDate, 'Li date a examinar');
    const calculation = axis.normalizeDateInput(calculationDate, 'Li die de calculation');
    const service = serviceApi.getSharedCalendarService();
    if (!service || typeof service.getCookingTrace !== 'function') {
      throw new TypeError('Li shared CalendarService ne supporta cooking trace.');
    }
    return service.getCookingTrace(
      axis.gregorianToJdn(target),
      axis.gregorianToJdn(calculation),
      options,
    );
  }

  const HTMLElementBase = root.HTMLElement || class {};

  class PastafariDateElement extends HTMLElementBase {
    static get observedAttributes() {
      return ['date', 'calculation-date', 'headless', 'no-editor', 'lang'];
    }

    constructor() {
      super();
      this._connected = false;
      this._connectionEpoch = 0;
      this._refreshQueuedEpoch = null;
      this._generation = 0;
      this._navigationGeneration = 0;
      this._value = null;
      this._targetJdn = null;
      this._calculationJdn = null;
      this._scrollTarget = null;
      this._cutlets = new Map();
      this._orderedStarts = [];
      this._activeStartJdn = null;
      this._windowStart = 0;
      this._loadingBefore = null;
      this._loadingAfter = null;
      this._cutletLoads = new Map();
      this._cookingPagePosition = null;
      this._reverseController = null;
      this._reverseGeneration = 0;
      this._reverseCalculationIso = null;
      this._reverseSolutions = [];
      this._readySettled = false;
      this._locale = null;
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
            width: min(100% - 2rem, var(--pastafari-max-width, 94rem));
            margin-inline: auto;
            padding-block: clamp(1.25rem, 4vw, 4rem) 2rem;
            color: var(--pastafari-color, var(--ink));
            font-family: Arial, "Noto Sans Hebrew", "Segoe UI", sans-serif;
            line-height: 1.55;
          }
          :host([headless]) { display: none !important; }
          :host([no-editor]) .search-panel { display: none !important; }
          *, *::before, *::after { box-sizing: border-box; }
          [hidden] { display: none !important; }
          button, input, select { font: inherit; }
          button { min-height: 44px; }
          button:focus-visible,
          input:focus-visible,
          select:focus-visible,
          summary:focus-visible,
          [tabindex]:focus-visible {
            outline: 4px solid var(--focus);
            outline-offset: 3px;
          }

          .masthead {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 1.5rem 2rem;
            align-items: start;
            padding: clamp(.75rem, 1.5vw, 1.35rem) 0 clamp(1.25rem, 3vw, 2.25rem);
            border-bottom: 1px solid var(--line);
          }
          .brand,
          .eyebrow,
          .status-kicker {
            margin: 0 0 .5rem;
            color: var(--accent-dark);
            font-size: .76rem;
            font-weight: 800;
            letter-spacing: .11em;
            text-transform: uppercase;
          }
          .app-title {
            max-width: 20ch;
            margin: 0;
            overflow-wrap: anywhere;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: clamp(2.5rem, 5.6vw, 5.2rem);
            font-weight: 700;
            letter-spacing: -.055em;
            line-height: .92;
          }
          .language-control {
            display: grid;
            min-width: min(11.5rem, 100%);
            gap: .35rem;
            color: var(--muted);
            font-size: .82rem;
            font-weight: 800;
          }
          .language-control select {
            min-height: 46px;
            width: 100%;
            min-width: 0;
            padding: .55rem .75rem;
            border: 1px solid #8e8272;
            border-radius: .7rem;
            background: var(--panel);
            color: var(--ink);
            cursor: pointer;
          }

          .search-panel {
            display: flex;
            width: min(100%, 68rem);
            margin: clamp(1.25rem, 3vw, 2.4rem) auto;
            padding: clamp(1rem, 2.4vw, 1.6rem);
            align-items: center;
            justify-content: space-between;
            gap: 1rem 1.5rem;
            border: 1px solid var(--line);
            border-radius: 1.25rem;
            background: rgb(255 253 248 / 92%);
            box-shadow: 0 18px 55px rgb(54 36 20 / 9%);
          }
          .search-heading {
            max-width: 22ch;
            margin: 0;
            overflow-wrap: anywhere;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: clamp(1.75rem, 3.6vw, 3rem);
            letter-spacing: -.035em;
            line-height: 1;
          }
          .editor-link,
          .reverse-open,
          .cooking-open,
          .nav-button,
          .today-button,
          .retry-button,
          .dialog-actions button {
            min-height: 46px;
            padding: .65rem 1rem;
            border: 1px solid #8e8272;
            border-radius: .7rem;
            background: #fffdf8;
            color: var(--ink);
            font-weight: 800;
            cursor: pointer;
          }
          .search-actions {
            display: flex;
            flex: 0 0 auto;
            flex-wrap: wrap;
            gap: .6rem;
            justify-content: end;
          }
          .editor-link {
            flex: 0 0 auto;
            border-color: var(--accent-dark);
            background: var(--accent-dark);
            color: white;
          }
          .reverse-open {
            flex: 0 0 auto;
            border-color: var(--accent-dark);
            background: #fffdf8;
            color: var(--accent-dark);
          }
          .reverse-open:hover { background: #fff0e9; }
          .cooking-open {
            width: fit-content;
            max-width: 100%;
            border-color: #000;
            background: #17130e;
            color: #fff;
          }
          .cooking-open:hover,
          .cooking-open[aria-expanded="true"] { background: #9d3825; color: white; }
          .editor-link:hover,
          .today-button:hover { background: #49160e; color: white; }
          .nav-button:hover,
          .retry-button:hover,
          .dialog-actions button:hover { background: #fff4ee; }

          .calendar {
            position: relative;
            min-height: 0;
          }
          .calendar[data-state="loading"] > .target-beacon,
          .calendar[data-state="loading"] > .toolbar,
          .calendar[data-state="loading"] > .viewport,
          .calendar[data-state="error"] > .target-beacon,
          .calendar[data-state="error"] > .toolbar,
          .calendar[data-state="error"] > .viewport {
            display: none;
          }

          .target-beacon {
            position: relative;
            display: grid;
            gap: .65rem;
            margin-bottom: clamp(1.4rem, 3vw, 2.5rem);
            padding: clamp(1rem, 2.4vw, 1.6rem);
            overflow: hidden;
            border: 1px solid #d8cdb9;
            border-inline-start: .5rem solid var(--accent);
            border-radius: 1rem;
            background: #fff7e3;
            color: var(--ink);
            box-shadow: 0 10px 28px rgb(54 36 20 / 10%);
          }
          .beacon-label {
            width: fit-content;
            padding: .35rem .75rem;
            border-radius: 999px;
            background: var(--accent-dark);
            color: white;
            font-size: .86rem;
            font-weight: 900;
            letter-spacing: .035em;
          }
          .beacon-date {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: .7rem;
          }
          .beacon-line {
            display: block;
            min-width: 0;
            padding: .35rem .45rem;
            overflow-wrap: anywhere;
            border: 0;
            border-radius: .45rem;
            background: rgb(255 253 248 / 72%);
            font-size: clamp(.98rem, 1.6vw, 1.2rem);
            font-weight: 700;
            line-height: 1.35;
          }
          .beacon-context {
            margin: 0;
            color: var(--muted);
            font-weight: 700;
          }
          .iso-date {
            direction: ltr;
            unicode-bidi: isolate;
            white-space: nowrap;
            font-variant-numeric: tabular-nums;
          }

          .toolbar {
            display: flex;
            gap: 1.5rem;
            align-items: end;
            justify-content: space-between;
            margin-bottom: 1.25rem;
          }
          .toolbar-copy { min-width: 0; }
          .selected-summary {
            margin: 0;
            overflow-wrap: anywhere;
            color: var(--muted);
            font-size: 1rem;
            font-weight: 700;
          }
          .toolbar-actions {
            display: grid;
            gap: .55rem;
            justify-items: end;
          }
          .cutlet-nav,
          .reset-nav {
            display: flex;
            flex-wrap: wrap;
            gap: .55rem;
            justify-content: end;
          }
          .target-button {
            border-color: #8e8272;
            background: #fffdf8;
            color: var(--ink);
          }
          .today-button {
            border-color: var(--accent-dark);
            background: var(--accent-dark);
            color: white;
          }

          .viewport {
            position: relative;
            max-height: none;
            overflow: visible;
            padding: 0;
          }
          .window-controls {
            display: flex;
            min-height: 3rem;
            gap: .7rem;
            align-items: center;
            justify-content: space-between;
            margin-block: .35rem .8rem;
          }
          .window-controls.after {
            justify-content: end;
            margin-block: .8rem 0;
          }
          .window-button {
            min-height: 44px;
            padding: .55rem .9rem;
            border: 1px solid #8e8272;
            border-radius: .7rem;
            background: #fffdf8;
            color: var(--ink);
            font-weight: 800;
            cursor: pointer;
          }
          .window-button:hover { background: #fff4ee; }
          .window-status {
            color: var(--muted);
            font-size: .88rem;
            font-weight: 750;
            text-align: center;
          }
          .cutlet-section {
            margin: 0 0 2.25rem;
            scroll-margin-block: .75rem;
          }
          .cutlet-section:last-of-type { margin-bottom: 0; }
          .cutlet-heading {
            position: static;
            z-index: 5;
            margin: 0 0 1rem;
            padding: .6rem .75rem;
            overflow-wrap: anywhere;
            border: 0;
            border-block-end: 1px solid var(--line);
            border-inline-start: .35rem solid var(--accent);
            border-radius: 0;
            background: transparent;
            box-shadow: none;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: clamp(1.35rem, 3vw, 2rem);
            line-height: 1.05;
          }
          /*
           * Keep month-run semantic groups in the DOM, but let their cards take
           * part in one flat cutlet grid. This matches the original public site:
           * rows/columns are presentation, not weeks or month subdivisions.
           */
          .cutlet-grid {
            position: relative;
            display: grid;
            grid-template-columns: repeat(7, minmax(7.5rem, 1fr));
            gap: clamp(.65rem, 1.2vw, 1rem);
            min-width: 58rem;
            padding-block: .5rem 1.5rem;
            align-items: stretch;
          }
          .month-run,
          .days { display: contents; }
          .month-heading {
            position: absolute;
            width: 1px;
            height: 1px;
            margin: -1px;
            padding: 0;
            overflow: hidden;
            clip: rect(0 0 0 0);
            clip-path: inset(50%);
            border: 0;
            white-space: nowrap;
          }
          .day {
            position: relative;
            display: grid;
            min-width: 0;
            min-height: 6.4rem;
            padding: .7rem;
            grid-template-rows: auto auto;
            align-content: start;
            gap: .28rem;
            overflow: hidden;
            border: 1px solid var(--month-edge, var(--line));
            border-radius: .8rem;
            background-color: var(--month-bg, var(--panel));
            background-image: var(--month-pattern-image, none);
            background-size: var(--month-pattern-size, auto);
            background-repeat: repeat;
            color: var(--month-ink, var(--ink));
            box-shadow: 0 2px 9px rgb(54 36 20 / 7%);
          }
          .day[aria-current="date"] {
            z-index: 4;
            grid-template-rows: auto auto auto;
            border: 3px solid var(--accent-dark);
            outline: 0;
            transform: none;
            box-shadow: 0 8px 20px rgb(54 36 20 / 20%);
          }
          .target-badge {
            position: relative;
            z-index: 2;
            display: block;
            width: fit-content;
            max-width: 100%;
            margin-bottom: .15rem;
            padding: .3rem .55rem;
            overflow-wrap: anywhere;
            border: 0;
            border-radius: 999px;
            background: var(--accent-dark);
            color: #ffffff;
            box-shadow: none;
            font-size: .76rem;
            font-weight: 850;
            line-height: 1.25;
          }
          .day-line {
            display: block;
            min-width: 0;
            margin: 0;
            padding: .12rem .15rem;
            overflow-wrap: anywhere;
            border: 0;
            border-radius: 0;
            background: transparent;
            color: var(--month-ink, var(--ink));
            box-shadow: none;
            font-size: clamp(.76rem, 1.1vw, .9rem);
            font-weight: 600;
            line-height: 1.32;
          }
          .day-line.cutlet-line {
            color: #514940;
            font-size: clamp(.74rem, 1vw, .86rem);
            font-weight: 750;
          }
          .day-line.month {
            margin-top: .15rem;
            padding-top: .42rem;
            border-top: 1px solid color-mix(in srgb, var(--month-edge, var(--line)) 55%, transparent);
            font-size: clamp(.82rem, 1.2vw, .96rem);
            font-weight: 800;
          }
          .day-line strong {
            font-family: Georgia, "Times New Roman", serif;
            font-weight: 850;
            font-variant-numeric: tabular-nums;
          }

          .overlay {
            position: relative;
            z-index: 20;
            display: grid;
            width: min(100%, 42rem);
            min-height: 0;
            margin: clamp(1rem, 3vw, 2rem) auto;
            padding: clamp(1rem, 2.5vw, 1.6rem);
            gap: .45rem .9rem;
            border: 1px solid var(--line);
            border-radius: 1.05rem;
            background: var(--panel);
            box-shadow: 0 12px 34px rgb(54 36 20 / 10%);
          }
          .overlay.loading {
            grid-template-columns: auto minmax(0, 1fr);
            grid-template-areas:
              "spinner title"
              "spinner note";
            align-items: center;
            text-align: start;
          }
          .overlay.error {
            grid-template-columns: minmax(0, 1fr);
            grid-auto-flow: row;
            gap: .7rem;
            justify-items: start;
            text-align: start;
          }
          .overlay.error .loading-title,
          .overlay.error .error-message,
          .overlay.error .retry-button {
            grid-area: auto;
          }
          .overlay.error .retry-button {
            justify-self: start;
          }
          .spinner {
            grid-area: spinner;
            width: 2.25rem;
            height: 2.25rem;
            border: 4px solid #d7cfc1;
            border-top-color: var(--accent);
            border-radius: 50%;
            animation: spin .8s linear infinite;
          }
          .loading-title {
            grid-area: title;
            margin: 0;
            overflow-wrap: anywhere;
            font-size: clamp(1.1rem, 2.2vw, 1.55rem);
            font-weight: 850;
            line-height: 1.2;
          }
          .loading-note {
            grid-area: note;
          }
          .loading-note,
          .error-message { margin: 0; color: var(--muted); font-size: .88rem; }
          @keyframes spin { to { transform: rotate(1turn); } }
          @media (prefers-reduced-motion: reduce) {
            .spinner { animation-duration: 3s; }
          }

          dialog {
            width: min(34rem, calc(100vw - 2rem));
            border: 1px solid #bbb092;
            border-radius: 1rem;
            padding: 0;
            color: var(--ink);
            background: var(--panel);
            box-shadow: 0 24px 70px rgb(0 0 0 / 28%);
          }
          dialog::backdrop { background: rgb(27 24 16 / 40%); }
          .dialog-form { display: grid; gap: 1rem; padding: 1.25rem; }
          .dialog-form h2 {
            margin: 0;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: 1.6rem;
          }
          .field { display: grid; gap: .35rem; }
          .field span { font-size: .86rem; font-weight: 750; }
          .field input,
          .field select {
            width: 100%;
            min-height: 46px;
            border: 1px solid #8e8272;
            border-radius: .7rem;
            padding: .58rem .68rem;
            background: white;
            color: var(--ink);
          }
          .field input { direction: ltr; }
          .reverse-dialog { width: min(48rem, calc(100vw - 2rem)); }
          .reverse-form {
            display: grid;
            gap: 1rem;
            padding: 1.25rem;
          }
          .reverse-form h2 {
            margin: 0;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: 1.6rem;
          }
          .reverse-fields {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: .8rem 1rem;
          }
          .reverse-status {
            min-height: 1.35rem;
            margin: 0;
            color: var(--muted);
            font-size: .88rem;
            font-weight: 700;
          }
          .reverse-status[data-kind="error"] { color: #76180e; }
          .reverse-results {
            display: grid;
            gap: .55rem;
          }
          .reverse-result {
            display: flex;
            min-height: 46px;
            width: 100%;
            padding: .65rem .8rem;
            align-items: center;
            justify-content: space-between;
            gap: .75rem;
            border: 1px solid #8e8272;
            border-radius: .7rem;
            background: #fffdf8;
            color: var(--ink);
            font-weight: 800;
            cursor: pointer;
          }
          .reverse-result:hover { background: #fff4ee; }
          .reverse-result bdi {
            direction: ltr;
            unicode-bidi: isolate;
            white-space: nowrap;
            font-variant-numeric: tabular-nums;
          }
          details { border-top: 1px solid #e0d8c0; padding-top: .75rem; }
          summary { color: var(--accent-dark); font-size: .86rem; font-weight: 800; cursor: pointer; }
          details .field { margin-top: .75rem; }
          .dialog-error { min-height: 1.1rem; margin: 0; color: #76180e; font-size: .82rem; font-weight: 750; }
          .dialog-actions { display: flex; flex-wrap: wrap; gap: .55rem; }
          .dialog-actions .primary {
            border-color: var(--accent-dark);
            background: var(--accent-dark);
            color: white;
          }

          @media (max-width: 74rem) {
            .cutlet-grid {
              grid-template-columns: repeat(auto-fit, minmax(min(100%, 11rem), 1fr));
              min-width: 0;
            }
          }

          @media (max-width: 48rem) {
            .overlay.loading {
              grid-template-columns: 1fr;
              grid-template-areas: "spinner" "title" "note";
              justify-items: center;
              text-align: center;
            }
            :host {
              width: min(100% - 1rem, var(--pastafari-max-width, 94rem));
              padding-block-start: .5rem;
            }
            .masthead { grid-template-columns: 1fr; }
            .app-title { font-size: clamp(2.4rem, 12vw, 4rem); }
            .language-control {
              width: min(100%, 12rem);
              justify-self: end;
            }
            .search-panel {
              display: grid;
              align-items: stretch;
            }
            .search-actions {
              display: grid;
              grid-template-columns: 1fr;
              width: 100%;
            }
            .editor-link,
            .reverse-open { width: 100%; }
            .reverse-fields { grid-template-columns: 1fr; }
            .beacon-date { grid-template-columns: 1fr; }
            .toolbar { align-items: stretch; flex-direction: column; }
            .toolbar-actions { justify-items: stretch; }
            .cutlet-nav,
            .reset-nav { justify-content: stretch; }
            .cutlet-nav button,
            .reset-nav button { flex: 1 1 9rem; }
            .window-controls {
              align-items: stretch;
              flex-direction: column;
            }
            .window-controls.after { align-items: stretch; }
            .window-button { width: 100%; }
            .cutlet-grid {
              grid-template-columns: repeat(auto-fit, minmax(min(100%, 13rem), 1fr));
              min-width: 0;
            }
            .day-line.cutlet-line { font-size: .82rem; }
            .day-line.month { font-size: .92rem; }
          }
          @media (max-width: 26.25rem) {
            .cutlet-grid { grid-template-columns: 1fr; }
          }
          @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after {
              animation-duration: .01ms !important;
              animation-iteration-count: 1 !important;
              transition-duration: .01ms !important;
            }
          }
          @media (forced-colors: active) {
            .day, .target-beacon {
              border: 2px solid CanvasText;
              background: Canvas;
              color: CanvasText;
            }
            .day-line, .beacon-line {
              border: 2px solid CanvasText;
              background: Canvas;
              color: CanvasText;
              box-shadow: none;
            }
            .day[aria-current="date"] {
              border: 6px solid Highlight;
              outline: 4px solid Highlight;
            }
          }
          @media print {
            :host { width: 100%; padding: 0; }
            .masthead { grid-template-columns: 1fr; padding-block: 0 1rem; }
            .language-control, .search-panel, .toolbar-actions, .cooking-open { display: none; }
            .viewport { max-height: none; overflow: visible; }
            .cutlet-heading { position: static; box-shadow: none; }
            .cutlet-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); min-width: 0; gap: .2rem; }
            .day { min-height: 0; break-inside: avoid; border: 1px solid #111; background: white; color: black; box-shadow: none; }
            .day[aria-current="date"] { border: 3px solid #111; outline: none; box-shadow: none; }
            .day-line { border: 1px solid #111; background: white; color: black; box-shadow: none; font-size: .72rem; }
          }
        </style>

        <header class="masthead" part="masthead">
          <div class="masthead-copy">
            <p class="brand">PASTAFARI</p>
            <h1 class="app-title"></h1>
          </div>
          <label class="language-control">
            <span class="language-label"></span>
            <select class="language-selector"></select>
          </label>
        </header>

        <section class="search-panel" part="editor">
          <div>
            <p class="eyebrow search-kicker"></p>
            <h2 class="search-heading"></h2>
          </div>
          <div class="search-actions">
            <button class="editor-link" type="button"></button>
            <button class="reverse-open" type="button"></button>
          </div>
        </section>

        <section class="calendar" part="calendar" aria-busy="true" data-state="loading">
          <section class="target-beacon" part="target">
            <span class="beacon-label"></span>
            <div class="beacon-date">
              <span class="beacon-line year-line"></span>
              <span class="beacon-line cutlet-line"></span>
              <span class="beacon-line month-line"></span>
            </div>
            <p class="beacon-context"></p>
            <button class="cooking-open" type="button" aria-expanded="false" aria-controls="pastafari-cooking-panel"></button>
          </section>

          <pastafari-cooking id="pastafari-cooking-panel" class="cooking-panel"></pastafari-cooking>

          <header class="toolbar" part="toolbar">
            <div class="toolbar-copy">
              <p class="eyebrow cutlet-kicker"></p>
              <p class="selected-summary" aria-live="polite"></p>
            </div>
            <div class="toolbar-actions">
              <div class="cutlet-nav">
                <button class="nav-button previous" type="button"></button>
                <button class="nav-button next" type="button"></button>
              </div>
              <div class="reset-nav">
                <button class="target-button" type="button" hidden></button>
                <button class="today-button" type="button"></button>
              </div>
            </div>
          </header>

          <div class="viewport" part="viewport">
            <div class="window-controls before">
              <button class="window-button earlier" type="button" hidden></button>
              <span class="window-status" aria-live="polite"></span>
            </div>
            <div class="cutlet-list"></div>
            <div class="window-controls after">
              <button class="window-button later" type="button" hidden></button>
            </div>
          </div>

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

        <dialog class="reverse-dialog">
          <form class="reverse-form" novalidate>
            <h2 class="reverse-heading"></h2>
            <div class="reverse-fields">
              <label class="field reverse-year-field">
                <span></span>
                <input name="reverse-year" inputmode="numeric" autocomplete="off" required>
              </label>
              <label class="field reverse-cutlet-field">
                <span></span>
                <select name="reverse-cutlet" required></select>
              </label>
              <label class="field reverse-day-cutlet-field">
                <span></span>
                <input name="reverse-day-cutlet" inputmode="numeric" autocomplete="off" required>
              </label>
              <label class="field reverse-month-field">
                <span></span>
                <select name="reverse-month" required></select>
              </label>
              <label class="field reverse-day-month-field">
                <span></span>
                <input name="reverse-day-month" inputmode="numeric" autocomplete="off" required>
              </label>
              <label class="field reverse-calculation-field">
                <span></span>
                <input name="reverse-calculation" inputmode="numeric" autocomplete="off" placeholder="YYYY-MM-DD" required>
              </label>
            </div>
            <p class="reverse-status" role="status" aria-live="polite"></p>
            <div class="reverse-results"></div>
            <div class="dialog-actions reverse-actions">
              <button class="primary reverse-submit" type="submit"></button>
              <button class="reverse-cancel" type="button"></button>
            </div>
          </form>
        </dialog>
      `;

      this._els = {
        calendar: this.shadowRoot.querySelector('.calendar'),
        toolbar: this.shadowRoot.querySelector('.toolbar'),
        appTitle: this.shadowRoot.querySelector('.app-title'),
        previous: this.shadowRoot.querySelector('.previous'),
        today: this.shadowRoot.querySelector('.today-button'),
        targetButton: this.shadowRoot.querySelector('.target-button'),
        next: this.shadowRoot.querySelector('.next'),
        cutletKicker: this.shadowRoot.querySelector('.cutlet-kicker'),
        summary: this.shadowRoot.querySelector('.selected-summary'),
        beaconLabel: this.shadowRoot.querySelector('.beacon-label'),
        beaconYear: this.shadowRoot.querySelector('.beacon-line.year-line'),
        beaconCutlet: this.shadowRoot.querySelector('.beacon-line.cutlet-line'),
        beaconMonth: this.shadowRoot.querySelector('.beacon-line.month-line'),
        beaconContext: this.shadowRoot.querySelector('.beacon-context'),
        cookingOpen: this.shadowRoot.querySelector('.cooking-open'),
        cookingPanel: this.shadowRoot.querySelector('pastafari-cooking'),
        viewport: this.shadowRoot.querySelector('.viewport'),
        list: this.shadowRoot.querySelector('.cutlet-list'),
        windowEarlier: this.shadowRoot.querySelector('.window-button.earlier'),
        windowLater: this.shadowRoot.querySelector('.window-button.later'),
        windowStatus: this.shadowRoot.querySelector('.window-status'),
        searchKicker: this.shadowRoot.querySelector('.search-kicker'),
        searchHeading: this.shadowRoot.querySelector('.search-heading'),
        editorLink: this.shadowRoot.querySelector('.editor-link'),
        reverseOpen: this.shadowRoot.querySelector('.reverse-open'),
        reverseDialog: this.shadowRoot.querySelector('.reverse-dialog'),
        reverseForm: this.shadowRoot.querySelector('.reverse-form'),
        reverseHeading: this.shadowRoot.querySelector('.reverse-heading'),
        reverseYearLabel: this.shadowRoot.querySelector('.reverse-year-field span'),
        reverseCutletLabel: this.shadowRoot.querySelector('.reverse-cutlet-field span'),
        reverseDayCutletLabel: this.shadowRoot.querySelector('.reverse-day-cutlet-field span'),
        reverseMonthLabel: this.shadowRoot.querySelector('.reverse-month-field span'),
        reverseDayMonthLabel: this.shadowRoot.querySelector('.reverse-day-month-field span'),
        reverseCalculationLabel: this.shadowRoot.querySelector('.reverse-calculation-field span'),
        reverseYear: this.shadowRoot.querySelector('input[name="reverse-year"]'),
        reverseCutlet: this.shadowRoot.querySelector('select[name="reverse-cutlet"]'),
        reverseDayCutlet: this.shadowRoot.querySelector('input[name="reverse-day-cutlet"]'),
        reverseMonth: this.shadowRoot.querySelector('select[name="reverse-month"]'),
        reverseDayMonth: this.shadowRoot.querySelector('input[name="reverse-day-month"]'),
        reverseCalculation: this.shadowRoot.querySelector('input[name="reverse-calculation"]'),
        reverseStatus: this.shadowRoot.querySelector('.reverse-status'),
        reverseResults: this.shadowRoot.querySelector('.reverse-results'),
        reverseSubmit: this.shadowRoot.querySelector('.reverse-submit'),
        reverseCancel: this.shadowRoot.querySelector('.reverse-cancel'),
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
      this._els.targetButton.addEventListener('click', () => this._returnToTarget());
      this._els.today.addEventListener('click', () => this._goToday());
      this._els.windowEarlier.addEventListener('click', () => this._shiftWindow(-1));
      this._els.windowLater.addEventListener('click', () => this._shiftWindow(1));
      this._els.editorLink.addEventListener('click', () => this._openDialog());
      this._els.reverseOpen.addEventListener('click', () => this._openReverseDialog());
      this._els.reverseCancel.addEventListener('click', () => this._closeReverseDialog(true));
      this._els.reverseForm.addEventListener('submit', (event) => this._applyReverseDialog(event));
      this._els.reverseDialog.addEventListener('cancel', (event) => {
        if (typeof event.preventDefault === 'function') event.preventDefault();
        this._closeReverseDialog(true);
      });
      this._els.cookingOpen.addEventListener('click', () => this._toggleCooking());
      this._els.cookingPanel.addEventListener('pastafari-cooking-close', () => {
        this._els.cookingOpen.setAttribute('aria-expanded', 'false');
        if (typeof this._els.cookingOpen.focus === 'function') {
          try { this._els.cookingOpen.focus({ preventScroll: true }); }
          catch (_) { this._els.cookingOpen.focus(); }
        }
        const position = this._cookingPagePosition;
        this._cookingPagePosition = null;
        if (position && typeof root.scrollTo === 'function') {
          enqueueMicrotask(() => {
            try { root.scrollTo({ left: position.x, top: position.y, behavior: 'auto' }); }
            catch (_) { root.scrollTo(position.x, position.y); }
          });
        }
      });
      this._els.retryButton.addEventListener('click', () => this._retry());
      this._els.cancelButton.addEventListener('click', () => this._closeDialog());
      this._els.form.addEventListener('submit', (event) => this._applyDialog(event));
      this._els.languageSelector.addEventListener('change', () => {
        const selected = this._els.languageSelector.value;
        writeStoredLocale(selected);
        this.setAttribute('lang', selected);
      });
      this._applyLocale();
    }

    connectedCallback() {
      if (this._connected) return;
      this._connected = true;
      this._connectionEpoch += 1;
      this._applyLocale();
      this._queueRefresh();
    }

    disconnectedCallback() {
      if (!this._connected) return;
      this._connected = false;
      this._connectionEpoch += 1;
      this._generation += 1;
      this._navigationGeneration += 1;
      this._refreshQueuedEpoch = null;
      this._cutletLoads.clear();
      this._abortReverseSearch();
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === newValue || !this._connected) return;
      if (name === 'no-editor') {
        if (newValue !== null) {
          this._closeDialog();
          this._closeReverseDialog(true);
        }
        return;
      }
      if (name === 'headless' && newValue !== null) {
        this._closeDialog();
        this._closeReverseDialog(true);
      }
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
      const stored = explicit ? null : readStoredLocale();
      const browserLanguages = root.navigator && Array.isArray(root.navigator.languages)
        ? root.navigator.languages : [];
      this._locale = i18n.resolveLocale(explicit || stored, browserLanguages);
      if (this.getAttribute && this.getAttribute('lang') !== this._locale.code) {
        this.setAttribute('lang', this._locale.code);
      }
      if (!this._els) return;

      this.setAttribute('dir', this._locale.dir);
      this._els.calendar.setAttribute('dir', this._locale.dir);
      this._els.toolbar.setAttribute('aria-label', this._t('calendar.toolbarAria'));
      this._els.appTitle.textContent = this._t('app.title');
      this._els.previous.textContent = this._t('calendar.previous');
      this._els.next.textContent = this._t('calendar.next');
      this._els.targetButton.textContent = this._t('calendar.target');
      this._els.today.textContent = this._t('calendar.today');
      this._els.windowEarlier.textContent = this._t('calendar.earlierDays');
      this._els.windowLater.textContent = this._t('calendar.laterDays');
      this._els.previous.setAttribute('aria-label', this._t('calendar.previous'));
      this._els.next.setAttribute('aria-label', this._t('calendar.next'));
      this._els.targetButton.setAttribute('aria-label', this._t('calendar.target'));
      this._els.today.setAttribute('aria-label', this._t('calendar.today'));
      this._els.windowEarlier.setAttribute('aria-label', this._t('calendar.earlierDays'));
      this._els.windowLater.setAttribute('aria-label', this._t('calendar.laterDays'));
      this._els.cutletKicker.textContent = this._t('calendar.toolbarAria');
      this._els.searchKicker.textContent = this._t('search.kicker');
      this._els.searchHeading.textContent = this._t('search.heading');
      this._els.editorLink.textContent = this._t('search.submit');
      this._els.reverseOpen.textContent = this._t('reverse.open');
      this._els.reverseOpen.hidden = !(reverseApi && typeof reverseApi.isAvailable === 'function' && reverseApi.isAvailable());
      this._els.reverseHeading.textContent = this._t('reverse.heading');
      this._els.reverseYearLabel.textContent = this._t('reverse.year');
      this._els.reverseCutletLabel.textContent = this._t('reverse.cutlet');
      this._els.reverseDayCutletLabel.textContent = this._t('reverse.dayInCutlet');
      this._els.reverseMonthLabel.textContent = this._t('reverse.month');
      this._els.reverseDayMonthLabel.textContent = this._t('reverse.dayInMonth');
      this._els.reverseCalculationLabel.textContent = this._t('reverse.calculation');
      this._els.reverseSubmit.textContent = this._t('reverse.submit');
      this._els.reverseCancel.textContent = this._t('reverse.action.cancel');
      this._populateReverseSelectors();
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
      this._els.cookingOpen.textContent = this._t('cooking.open');
      this._els.cookingPanel.setAttribute('lang', this._locale.code);
      if (!this._value) {
        this._els.summary.textContent = this._t('loading.title');
        this._els.beaconLabel.textContent = this._t('target.searched');
        this._els.beaconYear.textContent = '…';
        this._els.beaconCutlet.textContent = '…';
        this._els.beaconMonth.textContent = '…';
        this._els.beaconContext.textContent = '';
      }

      const locales = i18n.supportedLocales();
      const current = this._locale.code;
      const fragment = doc.createDocumentFragment();
      for (const locale of locales) {
        const option = doc.createElement('option');
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
      const headless = this.hasAttribute('headless');
      let inputValid = false;

      try {
        const targetDate = axis.normalizeDateInput(this.getAttribute('date'), 'Li date a examinar');
        const calculationDate = axis.normalizeDateInput(this.getAttribute('calculation-date'), 'Li die de calculation');
        const targetJdn = axis.gregorianToJdn(targetDate);
        const calculationJdn = axis.gregorianToJdn(calculationDate);
        inputValid = true;

        this._targetJdn = targetJdn;
        this._calculationJdn = calculationJdn;
        this._syncCookingPanel();
        this._scrollTarget = null;
        this._cutlets.clear();
        this._orderedStarts = [];
        this._activeStartJdn = null;
        this._windowStart = 0;
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

        const service = serviceApi.getSharedCalendarService();
        if (headless) {
          const value = await service.convert(targetJdn, calculationJdn);
          if (generation !== this._generation) return null;
          this._value = resultApi.cloneCanonicalResult(value);
          this._hideOverlays();
          if (this._els && this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'false');
          this._publishValue();
          return this._value;
        }

        const directValue = await service.convert(targetJdn, calculationJdn);
        if (generation !== this._generation) return null;
        this._value = resultApi.cloneCanonicalResult(directValue);
        this._scrollTarget = createScrollTarget(targetJdn, this._value);

        // Navigation has one owner: the complete direct target. It determines
        // which cutlet is loaded, which card is current, and where the viewport
        // is positioned. No JDN-only scroll path runs in parallel with it.
        const currentView = await service.getCutletView(this._scrollTarget.startJdn, calculationJdn);
        if (generation !== this._generation) return null;
        resolveTargetCutletView(currentView, this._scrollTarget);

        this._storeCutlet(currentView);
        this._activeStartJdn = BigInt(currentView.startJdn);
        this._setWindowAroundIndex(currentView, this._scrollTarget.dayInCutlet - 1);
        this._renderSummary();
        this._renderCutlets();
        // Loading state hides the viewport with display:none. Reveal it first,
        // then wait for one layout frame before measuring and positioning.
        this._hideOverlays();
        await nextLayoutFrame();
        if (generation !== this._generation) return null;
        this._positionTargetInViewport(this._scrollTarget);
        this._els.calendar.setAttribute('aria-busy', 'false');
        this._publishValue();
        // Adjacent work starts only after the target has been positioned. Any
        // later full re-render preserves an exact visible-card anchor.
        this._primeAdjacent(currentView, generation);
        return this._value;
      } catch (error) {
        if (generation !== this._generation) return null;
        if (!headless) this._showError(error, inputValid ? 'error.engineFailed' : 'search.invalid');
        else if (this._els && this._els.calendar) this._els.calendar.setAttribute('aria-busy', 'false');
        throw error;
      }
    }

    _publishValue() {
      if (!this._readySettled) {
        this._readySettled = true;
        this._resolveReady(this._value);
      }
      const EventCtor = root.CustomEvent;
      if (typeof EventCtor !== 'function') {
        throw new Error('Ti navigator ne supporta CustomEvent.');
      }
      this.dispatchEvent(new EventCtor('pastafari-change', {
        bubbles: true,
        composed: true,
        detail: this._value,
      }));
    }

    _queueRefresh() {
      if (!this._connected) return;
      const epoch = this._connectionEpoch;
      if (this._refreshQueuedEpoch === epoch) return;
      this._refreshQueuedEpoch = epoch;
      enqueueMicrotask(() => {
        if (this._refreshQueuedEpoch === epoch) this._refreshQueuedEpoch = null;
        if (!this._connected || this._connectionEpoch !== epoch) return;
        this.refresh().catch(() => {});
      });
    }

    _goToday() {
      if (this.hasAttribute('date')) this.removeAttribute('date');
      if (this.hasAttribute('calculation-date')) this.removeAttribute('calculation-date');
      this._queueRefresh();
    }

    _storeCutlet(view) {
      const start = BigInt(view.startJdn);
      if (this._cutlets.has(start)) return false;
      this._cutlets.set(start, view);
      this._orderedStarts = Array.from(this._cutlets.keys()).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
      return true;
    }

    _cachedCutletContaining(targetJdn) {
      const target = BigInt(targetJdn);
      for (const view of this._cutlets.values()) {
        if (target >= BigInt(view.startJdn) && target <= BigInt(view.endJdn)) return view;
      }
      return null;
    }

    _activeView() {
      if (this._activeStartJdn != null && this._cutlets.has(this._activeStartJdn)) {
        return this._cutlets.get(this._activeStartJdn);
      }
      if (this._scrollTarget && this._cutlets.has(BigInt(this._scrollTarget.startJdn))) {
        return this._cutlets.get(BigInt(this._scrollTarget.startJdn));
      }
      const first = this._orderedStarts[0];
      return first == null ? null : this._cutlets.get(first);
    }

    _windowBounds(view) {
      const length = view && Array.isArray(view.days) ? view.days.length : 0;
      const maxStart = Math.max(0, length - 1);
      const start = Math.max(0, Math.min(Number(this._windowStart || 0), maxStart));
      const end = Math.min(length, start + MAX_RENDERED_DAYS);
      return Object.freeze({ start, end, length });
    }

    _setWindowStart(view, start) {
      const length = view && Array.isArray(view.days) ? view.days.length : 0;
      const maxStart = Math.max(0, length - 1);
      this._windowStart = Math.max(0, Math.min(Number(start) || 0, maxStart));
      return this._windowStart;
    }

    _setWindowAroundIndex(view, index) {
      const length = view && Array.isArray(view.days) ? view.days.length : 0;
      if (length === 0) {
        this._windowStart = 0;
        return 0;
      }
      const safeIndex = Math.max(0, Math.min(Number(index) || 0, length - 1));
      const centered = safeIndex - Math.floor(MAX_RENDERED_DAYS / 2);
      const fullWindowMax = Math.max(0, length - MAX_RENDERED_DAYS);
      return this._setWindowStart(view, Math.min(centered, fullWindowMax));
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
      const cached = this._cachedCutletContaining(target);
      if (cached) return Promise.resolve(cached);
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
      try {
        const view = await serviceApi.getSharedCalendarService().getCutletView(targetJdn, this._calculationJdn);
        if (generation !== this._generation) return null;
        this._storeCutlet(view);
        // The requested view must survive trimming. This is essential when a
        // return-to-target action reloads a cutlet that was evicted far behind
        // the currently active browsing position.
        this._trimCutlets(view.startJdn, view.startJdn);
        return view;
      } catch (error) {
        if (generation === this._generation && error && error.code === RENDER_CONSISTENCY_CODE) {
          this._showError(error, 'error.engineFailed');
        }
        throw error;
      } finally {
        if (this[flag] === generation) this[flag] = null;
      }
    }

    _trimCutlets(fallbackStartJdn, preserveStartJdn) {
      if (this._orderedStarts.length <= MAX_CACHED_CUTLETS) return;
      const explicitPreserve = preserveStartJdn != null ? BigInt(preserveStartJdn) : null;
      const preferred = explicitPreserve != null && this._cutlets.has(explicitPreserve)
        ? explicitPreserve
        : (this._activeStartJdn != null && this._cutlets.has(this._activeStartJdn)
          ? this._activeStartJdn : BigInt(fallbackStartJdn));
      const preferredIndex = Math.max(0, this._orderedStarts.findIndex((start) => start === preferred));
      const firstKeep = Math.max(0, Math.min(
        preferredIndex - Math.floor(MAX_CACHED_CUTLETS / 2),
        this._orderedStarts.length - MAX_CACHED_CUTLETS,
      ));
      const keep = new Set(this._orderedStarts.slice(firstKeep, firstKeep + MAX_CACHED_CUTLETS));
      for (const start of this._orderedStarts) if (!keep.has(start)) this._cutlets.delete(start);
      this._orderedStarts = this._orderedStarts.filter((start) => keep.has(start));
    }

    _findCutletSection(startJdn) {
      const expected = String(BigInt(startJdn));
      return Array.from(this._els.list.querySelectorAll('section.cutlet-section'))
        .find((section) => String(section.dataset.startJdn) === expected) || null;
    }

    _findRenderedDay(identity, section) {
      const cards = Array.from(this._els.list.querySelectorAll('.day'));
      return cards.find((card) => {
        if (section && card.closest('section.cutlet-section') !== section) return false;
        if (identity.jdn != null && String(card.dataset.jdn) !== String(identity.jdn)) return false;
        return sameDaySemantics({
          year: card.dataset.year,
          cutletName: card.dataset.cutletName,
          dayInCutlet: card.dataset.dayInCutlet,
          monthName: card.dataset.monthName,
          dayInMonth: card.dataset.dayInMonth,
        }, identity);
      }) || null;
    }

    _renderTargetContext(targetDate, actionDate) {
      const targetMarker = '__PASTAFARI_TARGET_ISO__';
      const actionMarker = '__PASTAFARI_ACTION_ISO__';
      const text = this._t('target.context', {
        targetDate: targetMarker,
        actionDate: actionMarker,
      });
      const parts = String(text).split(new RegExp('(' + targetMarker + '|' + actionMarker + ')', 'g'));
      const fragment = doc.createDocumentFragment();
      for (const part of parts) {
        if (part === targetMarker || part === actionMarker) {
          const iso = doc.createElement('bdi');
          iso.className = 'iso-date';
          iso.setAttribute('dir', 'ltr');
          iso.textContent = part === targetMarker ? targetDate : actionDate;
          fragment.append(iso);
        } else if (part) {
          const text = doc.createElement('span');
          text.textContent = part;
          fragment.append(text);
        }
      }
      this._els.beaconContext.replaceChildren(fragment);
    }

    _renderSummary() {
      if (!this._value) return;
      const cutletName = this._localCalendarName('cutlet', this._value.cutletName);
      const monthName = this._localCalendarName('month', this._value.monthName);
      const targetDate = this._targetJdn == null
        ? ''
        : axis.toIsoDate(axis.jdnToGregorian(this._targetJdn));
      const actionDate = this._calculationJdn == null
        ? ''
        : axis.toIsoDate(axis.jdnToGregorian(this._calculationJdn));

      const yearLine = this._t('date.yearLine', { year: this._value.year });
      const cutletLine = this._t('date.cutletLine', {
        dayInCutlet: this._value.dayInCutlet,
        cutletName,
      });
      const monthLine = this._t('date.monthLine', {
        dayInMonth: this._value.dayInMonth,
        monthName,
      });

      // The target beacon already carries the complete five-part context.
      // Keep only the cutlet position here so the browsing toolbar does not
      // repeat the month line immediately above the cutlet heading.
      this._els.summary.textContent = cutletLine;
      this._els.beaconLabel.textContent = this._t('target.searched');
      this._els.beaconYear.textContent = yearLine;
      this._els.beaconCutlet.textContent = cutletLine;
      this._els.beaconMonth.textContent = monthLine;
      this._renderTargetContext(targetDate, actionDate);
      this._els.cookingOpen.textContent = this._t('cooking.open');
      this._syncCookingPanel();
    }

    _syncCookingPanel() {
      if (!this._els || !this._els.cookingPanel || this._targetJdn == null || this._calculationJdn == null) return;
      this._els.cookingPanel.setAttribute('lang', this._locale ? this._locale.code : 'ie');
      this._els.cookingPanel.setAttribute('date', axis.toIsoDate(axis.jdnToGregorian(this._targetJdn)));
      this._els.cookingPanel.setAttribute('calculation-date', axis.toIsoDate(axis.jdnToGregorian(this._calculationJdn)));
    }

    _toggleCooking() {
      const panel = this._els && this._els.cookingPanel;
      if (!panel) return;
      if (panel.hasAttribute('open')) {
        if (typeof panel.close === 'function') panel.close();
        else {
          panel.removeAttribute('open');
          this._els.cookingOpen.setAttribute('aria-expanded', 'false');
        }
        return;
      }
      this._syncCookingPanel();
      this._cookingPagePosition = Object.freeze({
        x: Number.isFinite(Number(root.scrollX)) ? Number(root.scrollX) : 0,
        y: Number.isFinite(Number(root.scrollY)) ? Number(root.scrollY) : 0,
      });
      if (typeof panel.show === 'function') panel.show();
      else panel.setAttribute('open', '');
      this._els.cookingOpen.setAttribute('aria-expanded', 'true');
    }

    _prepareRenderableCutlets() {
      const view = this._activeView();
      if (!view) return [];
      const bounds = this._windowBounds(view);
      const days = view.days.slice(bounds.start, bounds.end);
      for (const day of days) {
        if (this._scrollTarget && BigInt(day.jdn) === this._scrollTarget.jdn
            && !sameScrollTargetDay(day, this._scrollTarget)) {
          throw new CalendarRenderConsistencyError(
            day.jdn,
            semanticDaySnapshot(this._scrollTarget),
            semanticDaySnapshot(day),
          );
        }
      }
      return days.length > 0 ? [{ view, days }] : [];
    }

    _renderCutlets() {
      const prepared = this._prepareRenderableCutlets();
      const fragment = doc.createDocumentFragment();
      for (const item of prepared) fragment.append(this._renderCutlet(item.view, item.days));
      this._els.list.replaceChildren(fragment);
      const selected = this._els.list.querySelectorAll('[aria-current="date"]');
      if (selected.length > 1) {
        throw new CalendarRenderConsistencyError(
          this._targetJdn == null ? 'unknown' : this._targetJdn,
          Object.freeze({ ariaCurrentCount: selected.length }),
          Object.freeze({ ariaCurrentCount: selected.length }),
        );
      }
      this._updateWindowControls();
    }

    _updateWindowControls() {
      const view = this._activeView();
      if (!view) {
        this._els.windowEarlier.hidden = true;
        this._els.windowLater.hidden = true;
        this._els.targetButton.hidden = true;
        this._els.windowStatus.textContent = '';
        return;
      }
      const bounds = this._windowBounds(view);
      this._els.windowEarlier.hidden = bounds.start === 0;
      this._els.windowLater.hidden = bounds.end >= bounds.length;
      this._els.windowEarlier.disabled = bounds.start === 0;
      this._els.windowLater.disabled = bounds.end >= bounds.length;
      this._els.windowStatus.textContent = this._t('calendar.windowStatus', {
        start: bounds.length === 0 ? 0 : bounds.start + 1,
        end: bounds.end,
        total: bounds.length,
      });
      const targetVisible = this._scrollTarget != null
        && BigInt(view.startJdn) === BigInt(this._scrollTarget.startJdn)
        && this._scrollTarget.dayInCutlet - 1 >= bounds.start
        && this._scrollTarget.dayInCutlet - 1 < bounds.end;
      this._els.targetButton.hidden = targetVisible || this._scrollTarget == null;
    }

    _scrollCalendarStart() {
      const section = this._els.list.querySelector('section.cutlet-section');
      if (section && typeof section.scrollIntoView === 'function') {
        section.scrollIntoView({ block: 'start', inline: 'nearest' });
      }
    }

    _shiftWindow(direction) {
      const view = this._activeView();
      if (!view) return false;
      const bounds = this._windowBounds(view);
      const wanted = bounds.start + (direction < 0 ? -MAX_RENDERED_DAYS : MAX_RENDERED_DAYS);
      const next = this._setWindowStart(view, wanted);
      if (next === bounds.start) return false;
      this._renderCutlets();
      this._scrollCalendarStart();
      return true;
    }

    _renderCutlet(view, preparedDays) {
      const section = doc.createElement('section');
      const localCutlet = this._localCalendarName('cutlet', view.cutletName);
      section.className = 'cutlet-section';
      section.dataset.startJdn = String(view.startJdn);
      section.dataset.endJdn = String(view.endJdn);
      section.dataset.year = String(view.year);
      section.dataset.cutletName = String(view.cutletName);
      section.setAttribute('aria-label', this._t('calendar.daysAria', { cutletName: localCutlet }));

      const heading = doc.createElement('h2');
      heading.className = 'cutlet-heading';
      heading.textContent = this._t('calendar.currentCutlet', { year: view.year }) + ' ' + localCutlet;
      section.append(heading);

      const flatGrid = doc.createElement('div');
      flatGrid.className = 'cutlet-grid';
      flatGrid.setAttribute('role', 'list');
      let run = [];
      const renderDays = Array.isArray(preparedDays) ? preparedDays : view.days;
      for (const day of renderDays) {
        if (run.length > 0 && !sameMonthRun(run[run.length - 1], day)) {
          flatGrid.append(this._renderMonthRun(run));
          run = [];
        }
        run.push(day);
      }
      if (run.length > 0) flatGrid.append(this._renderMonthRun(run));
      section.append(flatGrid);
      return section;
    }

    _renderMonthRun(days) {
      const first = days[0];
      const last = days[days.length - 1];
      const localMonth = this._localCalendarName('month', first.monthName);
      const group = doc.createElement('section');
      group.className = 'month-run';
      group.setAttribute('role', 'group');
      applyMonthTheme(group, first.monthName);

      const heading = doc.createElement('header');
      heading.className = 'month-heading';
      const title = doc.createElement('strong');
      title.textContent = localMonth;
      const range = doc.createElement('span');
      range.className = 'month-range';
      range.textContent = this._t('field.day') + ' ' + (
        first.dayInMonth === last.dayInMonth
          ? String(first.dayInMonth)
          : String(first.dayInMonth) + '–' + String(last.dayInMonth)
      );
      heading.append(title, range);
      group.setAttribute('aria-label', localMonth + ' · ' + range.textContent);

      const grid = doc.createElement('div');
      grid.className = 'days';
      for (const day of days) {
        const localDayCutlet = this._localCalendarName('cutlet', day.cutletName);
        const localDayMonth = this._localCalendarName('month', day.monthName);
        const card = doc.createElement('article');
        card.className = 'day';
        card.dataset.jdn = String(day.jdn);
        card.dataset.year = String(day.year);
        card.dataset.cutletName = String(day.cutletName);
        card.dataset.dayInCutlet = String(day.dayInCutlet);
        card.dataset.monthName = String(day.monthName);
        card.dataset.dayInMonth = String(day.dayInMonth);
        applyMonthTheme(card, day.monthName);
        card.setAttribute('role', 'listitem');
        card.setAttribute('aria-label', this._t('date.aria', {
          year: day.year,
          dayInCutlet: day.dayInCutlet,
          cutletName: localDayCutlet,
          dayInMonth: day.dayInMonth,
          monthName: localDayMonth,
        }));
        const isTarget = this._scrollTarget != null && sameScrollTargetDay(day, this._scrollTarget);
        if (isTarget) card.setAttribute('aria-current', 'date');

        if (isTarget) {
          const targetBadge = doc.createElement('span');
          targetBadge.className = 'target-badge';
          targetBadge.setAttribute('aria-hidden', 'true');
          targetBadge.textContent = this._t('target.searched');
          card.append(targetBadge);
        }

        const cutletLine = doc.createElement('span');
        cutletLine.className = 'day-line cutlet-line';
        cutletLine.textContent = this._t('field.day') + ' ' + String(day.dayInCutlet);
        cutletLine.title = this._t('date.cutletLine', {
          dayInCutlet: day.dayInCutlet,
          cutletName: localDayCutlet,
        });

        const monthLine = doc.createElement('span');
        monthLine.className = 'day-line month';
        monthLine.textContent = this._t('date.monthLine', {
          dayInMonth: day.dayInMonth,
          monthName: localDayMonth,
        });

        card.append(cutletLine, monthLine);
        grid.append(card);
      }
      group.append(heading, grid);
      return group;
    }

    _positionTargetInViewport(target) {
      if (!target || target.jdn == null || target.startJdn == null) {
        throw new TypeError('Li target de scrolling deve esser un complet navigation target.');
      }
      const section = this._findCutletSection(target.startJdn);
      if (!section || String(section.dataset.year) !== target.year
          || String(section.dataset.cutletName) !== target.cutletName) {
        throw new CalendarTargetCutletError(
          target.jdn,
          target,
          section ? Object.freeze({
            startJdn: String(section.dataset.startJdn),
            year: String(section.dataset.year),
            cutletName: String(section.dataset.cutletName),
          }) : Object.freeze({ missingSection: true }),
          'scroll-section-mismatch',
        );
      }

      const selected = this._findRenderedDay(target, section);
      if (!selected) {
        throw new CalendarRenderConsistencyError(
          target.jdn,
          target,
          Object.freeze({ exactTargetMatchCount: 0 }),
        );
      }
      const cards = Array.from(this._els.list.querySelectorAll('.day'));
      const duplicateCount = cards.filter((card) => sameScrollTargetDay({
        jdn: card.dataset.jdn,
        year: card.dataset.year,
        cutletName: card.dataset.cutletName,
        dayInCutlet: card.dataset.dayInCutlet,
        monthName: card.dataset.monthName,
        dayInMonth: card.dataset.dayInMonth,
      }, target)).length;
      if (duplicateCount !== 1) {
        throw new CalendarRenderConsistencyError(
          target.jdn,
          target,
          Object.freeze({ exactTargetMatchCount: duplicateCount }),
        );
      }

      for (const card of cards) {
        if (card === selected) card.setAttribute('aria-current', 'date');
        else card.removeAttribute('aria-current');
      }
      this._activeStartJdn = BigInt(target.startJdn);
      this._updateWindowControls();
      return selected;
    }

    _assertTargetInView(view, target) {
      if (!view || BigInt(view.startJdn) !== BigInt(target.startJdn)
          || String(view.year) !== String(target.year)
          || String(view.cutletName) !== String(target.cutletName)) {
        throw new CalendarTargetCutletError(
          target.jdn,
          target,
          view ? Object.freeze({
            startJdn: String(view.startJdn),
            year: String(view.year),
            cutletName: String(view.cutletName),
          }) : Object.freeze({ missingView: true }),
          'wrong-cutlet-identity',
        );
      }
      const targetDay = view.days[target.dayInCutlet - 1];
      if (!sameScrollTargetDay(targetDay, target)) {
        throw new CalendarTargetCutletError(
          target.jdn,
          target,
          targetDay ? semanticDaySnapshot(targetDay) : Object.freeze({ missingTargetDay: true }),
          'target-not-in-expected-cutlet-position',
        );
      }
      return view;
    }

    async _returnToTarget() {
      if (!this._scrollTarget) return false;
      const generation = this._generation;
      const navigationGeneration = ++this._navigationGeneration;
      let view = this._cutlets.get(BigInt(this._scrollTarget.startJdn));
      if (!view) {
        try {
          view = await this._loadCutletAt(this._scrollTarget.startJdn, 'after', generation);
        } catch (_) {
          return false;
        }
      }
      if (!view || !this._connected || generation !== this._generation
          || navigationGeneration !== this._navigationGeneration) return false;
      this._assertTargetInView(view, this._scrollTarget);
      this._activeStartJdn = BigInt(view.startJdn);
      this._setWindowAroundIndex(view, this._scrollTarget.dayInCutlet - 1);
      this._renderCutlets();
      await nextLayoutFrame();
      if (!this._connected || generation !== this._generation
          || navigationGeneration !== this._navigationGeneration) return false;
      const selected = this._positionTargetInViewport(this._scrollTarget);
      if (selected && typeof selected.scrollIntoView === 'function') {
        selected.scrollIntoView({ block: 'center', inline: 'nearest' });
      }
      this._primeAdjacent(view, generation);
      return true;
    }

    async _scrollAdjacent(direction) {
      const current = this._activeView();
      if (!current) return false;
      const generation = this._generation;
      const navigationGeneration = ++this._navigationGeneration;
      const requested = direction < 0 ? current.previousCutletJdn : current.nextCutletJdn;
      let loaded;
      try {
        loaded = await this._loadCutletAt(requested, direction < 0 ? 'before' : 'after', generation);
      } catch (_) {
        return false;
      }
      if (!loaded || !this._connected || generation !== this._generation
          || navigationGeneration !== this._navigationGeneration) return false;

      this._activeStartJdn = BigInt(loaded.startJdn);
      this._setWindowStart(loaded, 0);
      this._renderCutlets();
      this._scrollCalendarStart();
      this._primeAdjacent(loaded, generation);
      return true;
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
      if (this._els.calendar) {
        this._els.calendar.setAttribute('aria-busy', 'true');
        this._els.calendar.setAttribute('data-state', 'loading');
      }
      if (this._els.loading) this._els.loading.hidden = false;
      if (this._els.error) this._els.error.hidden = true;
    }

    _hideOverlays() {
      if (this._els.calendar) this._els.calendar.removeAttribute('data-state');
      if (this._els.loading) this._els.loading.hidden = true;
      if (this._els.error) this._els.error.hidden = true;
    }

    _showError(error, messageKey) {
      if (this._els.calendar) {
        this._els.calendar.setAttribute('aria-busy', 'false');
        this._els.calendar.setAttribute('data-state', 'error');
      }
      if (this._els.loading) this._els.loading.hidden = true;
      if (this._els.error) this._els.error.hidden = false;
      if (root.console && typeof root.console.error === 'function') root.console.error(error);
      if (this._els.errorMessage) {
        this._els.errorMessage.textContent = this._t(messageKey || 'error.engineFailed');
      }
    }
  }

  const api = Object.freeze({
    buildId: root.PastafariBrowserConfig && root.PastafariBrowserConfig.buildId != null
      ? String(root.PastafariBrowserConfig.buildId) : null,
    getPastafariDateAsync,
    getPastafariDate: getPastafariDateAsync,
    getPastafariCookingTraceAsync,
    PastafariDateElement,
    PastafariCookingElement: ns.cookingComponent ? ns.cookingComponent.PastafariCookingElement : null,
    installSharedCalendarService: serviceApi.installSharedCalendarService,
    installSharedCalendarMemory: serviceApi.installSharedCalendarMemory,
  });

  root.PastafariCalendarBrowser = api;
  if (root.customElements && !root.customElements.get('pastafari-date')) {
    root.customElements.define('pastafari-date', PastafariDateElement);
  }
})(typeof globalThis === 'object' ? globalThis : this);
