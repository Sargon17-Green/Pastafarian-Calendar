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

  // Current semantic month names, never old positional identifiers. Each month
  // receives its own saturated theme. The golden-angle hue spacing makes
  // neighbouring indices diverge sharply instead of collapsing into pastels.
  const MONTH_THEME_NAMES = Object.freeze([
    'argile', 'granat', 'cubit', 'invidie', 'Eridu', 'dent-pasta',
    'tri partes de quin', 'Karshumb', 'leopard', 'stann', 'brume', 'oliban',
    'fus', 'costa', 'carob', 'Uruk', 'honte', 'camel', 'cupr', 'pute',
    'vitelle', 'stelle', 'mel', 'splen', 'calcari', 'joy', 'fig', 'Ninive',
    'ran', 'gudron', 'candel', 'li cludet porta', 'sesam', 'nuca', 'argent',
    'lilie', 'tempeste', 'asin', 'farine', 'regret', 'Babylon', 'lingue',
    'lin', 'sal', 'pir', 'arc', 'sand',
  ]);
  const MONTH_THEME_INDEX = new Map(MONTH_THEME_NAMES.map((name, index) => [name, index]));
  const MONTH_THEMES = Object.freeze(MONTH_THEME_NAMES.map((name, index) => {
    const hue = Math.round((index * 137.508) % 360);
    const secondaryHue = Math.round((hue + 151 + ((index % 3) * 17)) % 360);
    const angle = (index * 37) % 180;
    return Object.freeze({
      edge: `hsl(${hue} 100% 22%)`,
      bg: `hsl(${hue} 88% 49%)`,
      wash: `hsl(${secondaryHue} 96% 52%)`,
      pattern: `repeating-linear-gradient(${angle}deg, transparent 0 66%, hsl(${secondaryHue} 96% 52%) 66% 78%, transparent 78% 100%)`,
    });
  }));
  const MAX_CACHED_CUTLETS = 5;
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


  function targetCutletStartJdn(targetJdn, value) {
    const dayInCutlet = Number(value && value.dayInCutlet);
    if (!Number.isSafeInteger(dayInCutlet) || dayInCutlet < 1) {
      throw new RangeError('Li dayInCutlet del searched date deve esser un positiv secur integer.');
    }
    return BigInt(targetJdn) - BigInt(dayInCutlet - 1);
  }

  function assertTargetCutletView(view, targetJdn, value, expectedStartJdn) {
    const expected = semanticDaySnapshot(value);
    const actualMeta = Object.freeze({
      startJdn: view && view.startJdn != null ? String(view.startJdn) : null,
      selectedJdn: view && view.selectedJdn != null ? String(view.selectedJdn) : null,
      selectedIndex: view && view.selectedIndex != null ? Number(view.selectedIndex) : null,
      year: view && view.year != null ? String(view.year) : null,
      cutletName: view && view.cutletName != null ? String(view.cutletName) : null,
    });
    if (!view || typeof view !== 'object' || !Array.isArray(view.days)) {
      throw new CalendarTargetCutletError(targetJdn, expected, actualMeta, 'invalid-view');
    }
    if (BigInt(view.startJdn) !== BigInt(expectedStartJdn)) {
      throw new CalendarTargetCutletError(targetJdn, expected, actualMeta, 'wrong-start');
    }
    if (String(view.year) !== expected.year || String(view.cutletName) !== expected.cutletName) {
      throw new CalendarTargetCutletError(targetJdn, expected, actualMeta, 'wrong-cutlet-identity');
    }
    if (BigInt(view.selectedJdn) !== BigInt(expectedStartJdn) || Number(view.selectedIndex) !== 0) {
      throw new CalendarTargetCutletError(targetJdn, expected, actualMeta, 'view-not-selected-at-start');
    }

    const targetIndex = expected.dayInCutlet - 1;
    const first = view.days[0];
    const targetDay = view.days[targetIndex];
    if (!first || BigInt(first.jdn) !== BigInt(expectedStartJdn)
        || String(first.year) !== expected.year || String(first.cutletName) !== expected.cutletName
        || Number(first.dayInCutlet) !== 1) {
      throw new CalendarTargetCutletError(
        targetJdn,
        expected,
        first ? semanticDaySnapshot(first) : Object.freeze({ missingFirstDay: true }),
        'invalid-cutlet-start',
      );
    }
    if (!targetDay || BigInt(targetDay.jdn) !== BigInt(targetJdn) || !sameDaySemantics(targetDay, expected)) {
      throw new CalendarTargetCutletError(
        targetJdn,
        expected,
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

  function escapeSelector(value) {
    if (root.CSS && typeof root.CSS.escape === 'function') return root.CSS.escape(String(value));
    return String(value).replace(/["\\]/g, '\\$&');
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
            padding: clamp(1rem, 2vw, 2rem) 0 clamp(2rem, 5vw, 4rem);
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
            max-width: 14ch;
            margin: 0;
            overflow-wrap: anywhere;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: clamp(2.8rem, 8vw, 7rem);
            font-weight: 700;
            letter-spacing: -.055em;
            line-height: .92;
          }
          .language-control {
            display: grid;
            min-width: min(14rem, 100%);
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
            margin-block: clamp(2rem, 5vw, 4rem);
            padding: clamp(1.2rem, 3.5vw, 2.5rem);
            align-items: end;
            justify-content: space-between;
            gap: 1.25rem;
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
            font-size: clamp(2rem, 5vw, 4rem);
            letter-spacing: -.035em;
            line-height: 1;
          }
          .editor-link,
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
          .editor-link {
            flex: 0 0 auto;
            border-color: var(--accent-dark);
            background: var(--accent-dark);
            color: white;
          }
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
            gap: .7rem;
            margin-bottom: clamp(2rem, 5vw, 4rem);
            padding: clamp(1.25rem, 3vw, 2.25rem);
            overflow: hidden;
            border: 4px solid var(--ink);
            border-inline-start: clamp(.75rem, 2vw, 1.35rem) solid var(--accent);
            border-radius: 1.1rem;
            background: #ffea00;
            color: #000000;
            box-shadow: 0 0 0 4px #ffffff, 0 0 0 8px #000000, 0 18px 38px rgb(0 0 0 / 32%);
          }
          .beacon-label {
            width: fit-content;
            padding: .35rem .75rem;
            border-radius: 999px;
            background: var(--ink);
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
            padding: .8rem;
            overflow-wrap: anywhere;
            border: 1px solid #a8977d;
            border-radius: .7rem;
            background: white;
            font-size: clamp(1rem, 2vw, 1.35rem);
            font-weight: 650;
            line-height: 1.35;
          }
          .beacon-context {
            margin: 0;
            color: var(--muted);
            font-weight: 700;
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
            display: flex;
            flex-wrap: wrap;
            gap: .55rem;
            justify-content: end;
          }
          .today-button {
            border-color: var(--accent-dark);
            background: var(--accent-dark);
            color: white;
          }

          .viewport {
            position: relative;
            max-height: var(--pastafari-calendar-height, 46rem);
            overflow: auto;
            padding: 0;
            overscroll-behavior: contain;
            scrollbar-gutter: stable;
          }
          .edge-loader {
            min-height: 1.8rem;
            display: grid;
            place-items: center;
            color: var(--muted);
            font-size: .78rem;
          }
          .cutlet {
            margin: 0 0 2.25rem;
            scroll-margin-block: .75rem;
          }
          .cutlet:last-of-type { margin-bottom: 0; }
          .cutlet-heading {
            position: sticky;
            top: 0;
            z-index: 5;
            margin: 0 0 1rem;
            padding: .9rem 1rem;
            overflow-wrap: anywhere;
            border: 1px solid var(--line);
            border-inline-start: .45rem solid var(--accent);
            border-radius: .85rem;
            background: rgb(255 253 248 / 96%);
            box-shadow: 0 6px 18px rgb(54 36 20 / 10%);
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: clamp(1.5rem, 4vw, 2.6rem);
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
            min-height: 10.5rem;
            padding: .85rem;
            grid-template-rows: auto auto auto;
            align-content: stretch;
            gap: .48rem;
            overflow: hidden;
            border: 2px solid var(--month-edge, var(--line));
            border-radius: .85rem;
            background-color: var(--month-bg, var(--panel));
            background-image: var(--month-pattern-image, none);
            background-size: var(--month-pattern-size, auto);
            background-repeat: repeat;
            color: var(--month-ink, var(--ink));
            box-shadow: inset 0 1px rgb(255 255 255 / 14%);
          }
          .day[aria-current="date"] {
            z-index: 4;
            grid-template-rows: auto auto auto auto;
            border: 8px solid #ffffff;
            outline: 6px solid #000000;
            outline-offset: -2px;
            transform: scale(1.035);
            box-shadow:
              0 0 0 8px #ffea00,
              0 0 0 12px #000000,
              0 18px 38px rgb(0 0 0 / 55%);
          }
          .day[aria-current="date"]::after {
            content: "";
            position: absolute;
            inset: .34rem;
            pointer-events: none;
            border: 4px dashed #ffea00;
            border-radius: .48rem;
            box-shadow: inset 0 0 0 2px #000000;
          }
          .target-badge {
            position: relative;
            z-index: 2;
            display: block;
            width: fit-content;
            max-width: 100%;
            margin-bottom: .1rem;
            padding: .38rem .7rem;
            overflow-wrap: anywhere;
            border: 4px solid #ffea00;
            border-radius: 999px;
            background: #000000;
            color: #ffea00;
            box-shadow: 0 0 0 3px #ffffff, 0 0 0 5px #000000;
            font-size: .82rem;
            font-weight: 950;
            line-height: 1.25;
          }
          .day-line {
            display: block;
            min-width: 0;
            margin: 0;
            padding: .42rem .55rem;
            overflow-wrap: anywhere;
            border: 2px solid color-mix(in srgb, var(--month-ink, var(--ink)) 82%, transparent);
            border-radius: .52rem;
            background-color: var(--month-text-bg, var(--month-bg));
            color: var(--month-ink, var(--ink));
            box-shadow: 0 2px 7px rgb(0 0 0 / 22%);
            font-size: clamp(.8rem, 1.25vw, .96rem);
            font-weight: 600;
            line-height: 1.35;
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
            justify-items: center;
            text-align: center;
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
          .field input {
            width: 100%;
            min-height: 46px;
            direction: ltr;
            border: 1px solid #8e8272;
            border-radius: .7rem;
            padding: .58rem .68rem;
            background: white;
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
            .app-title { font-size: clamp(2.7rem, 16vw, 5.4rem); }
            .language-control { width: 100%; }
            .search-panel {
              display: grid;
              align-items: stretch;
            }
            .editor-link { width: 100%; }
            .beacon-date { grid-template-columns: 1fr; }
            .toolbar { align-items: stretch; flex-direction: column; }
            .toolbar-actions { justify-content: stretch; }
            .toolbar-actions button { flex: 1 1 9rem; }
            .cutlet-grid {
              grid-template-columns: repeat(auto-fit, minmax(min(100%, 13rem), 1fr));
              min-width: 0;
            }
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
            .language-control, .search-panel, .toolbar-actions { display: none; }
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
          <button class="editor-link" type="button"></button>
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
          </section>

          <header class="toolbar" part="toolbar">
            <div class="toolbar-copy">
              <p class="eyebrow cutlet-kicker"></p>
              <p class="selected-summary" aria-live="polite"></p>
            </div>
            <div class="toolbar-actions">
              <button class="nav-button previous" type="button"></button>
              <button class="today-button" type="button"></button>
              <button class="nav-button next" type="button"></button>
            </div>
          </header>

          <div class="viewport" part="viewport" tabindex="0">
            <div class="edge-loader before" aria-hidden="true"></div>
            <div class="cutlet-list"></div>
            <div class="edge-loader after" aria-hidden="true"></div>
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
      `;

      this._els = {
        calendar: this.shadowRoot.querySelector('.calendar'),
        toolbar: this.shadowRoot.querySelector('.toolbar'),
        appTitle: this.shadowRoot.querySelector('.app-title'),
        previous: this.shadowRoot.querySelector('.previous'),
        today: this.shadowRoot.querySelector('.today-button'),
        next: this.shadowRoot.querySelector('.next'),
        cutletKicker: this.shadowRoot.querySelector('.cutlet-kicker'),
        summary: this.shadowRoot.querySelector('.selected-summary'),
        beaconLabel: this.shadowRoot.querySelector('.beacon-label'),
        beaconYear: this.shadowRoot.querySelector('.beacon-line.year-line'),
        beaconCutlet: this.shadowRoot.querySelector('.beacon-line.cutlet-line'),
        beaconMonth: this.shadowRoot.querySelector('.beacon-line.month-line'),
        beaconContext: this.shadowRoot.querySelector('.beacon-context'),
        viewport: this.shadowRoot.querySelector('.viewport'),
        list: this.shadowRoot.querySelector('.cutlet-list'),
        beforeLoader: this.shadowRoot.querySelector('.edge-loader.before'),
        afterLoader: this.shadowRoot.querySelector('.edge-loader.after'),
        searchKicker: this.shadowRoot.querySelector('.search-kicker'),
        searchHeading: this.shadowRoot.querySelector('.search-heading'),
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
      this._els.today.addEventListener('click', () => this._goToday());
      this._els.next.addEventListener('click', () => this._scrollAdjacent(1));
      this._els.editorLink.addEventListener('click', () => this._openDialog());
      this._els.retryButton.addEventListener('click', () => this._retry());
      this._els.cancelButton.addEventListener('click', () => this._closeDialog());
      this._els.form.addEventListener('submit', (event) => this._applyDialog(event));
      this._els.viewport.addEventListener('scroll', () => this._onScroll(), { passive: true });
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
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === newValue || !this._connected) return;
      if (name === 'no-editor') {
        if (newValue !== null) this._closeDialog();
        return;
      }
      if (name === 'headless' && newValue !== null) this._closeDialog();
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
      this._els.today.textContent = this._t('calendar.today');
      this._els.next.textContent = this._t('calendar.next');
      this._els.previous.setAttribute('aria-label', this._t('calendar.previous'));
      this._els.today.setAttribute('aria-label', this._t('calendar.today'));
      this._els.next.setAttribute('aria-label', this._t('calendar.next'));
      this._els.cutletKicker.textContent = this._t('calendar.toolbarAria');
      this._els.searchKicker.textContent = this._t('search.kicker');
      this._els.searchHeading.textContent = this._t('search.heading');
      this._els.editorLink.textContent = this._t('search.submit');
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

        // The direct five-field result chooses the cutlet. dayInCutlet fixes its
        // exact start JDN; getCutletView() no longer gets to choose a containing
        // cutlet merely from the target JDN.
        const targetStartJdn = targetCutletStartJdn(targetJdn, this._value);
        const currentView = await service.getCutletView(targetStartJdn, calculationJdn);
        if (generation !== this._generation) return null;
        assertTargetCutletView(currentView, targetJdn, this._value, targetStartJdn);

        this._storeCutlet(currentView);
        this._activeStartJdn = targetStartJdn;
        this._renderSummary();
        this._renderCutlets();
        this._hideOverlays();
        this._els.calendar.setAttribute('aria-busy', 'false');
        const scrollTarget = this._value;
        enqueueMicrotask(() => {
          if (generation !== this._generation || !this._connected) return;
          try {
            this._scrollSelectedIntoView(
              scrollTarget.year,
              scrollTarget.cutletName,
              scrollTarget.dayInCutlet,
              scrollTarget.monthName,
              scrollTarget.dayInMonth,
            );
          } catch (error) {
            this._showError(error, 'error.engineFailed');
          }
        });
        this._publishValue();
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
      } catch (error) {
        if (generation === this._generation && error && error.code === RENDER_CONSISTENCY_CODE) {
          this._showError(error, 'error.engineFailed');
        }
        throw error;
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

      this._els.summary.textContent = cutletLine + ' · ' + monthLine;
      this._els.beaconLabel.textContent = this._t('target.searched');
      this._els.beaconYear.textContent = yearLine;
      this._els.beaconCutlet.textContent = cutletLine;
      this._els.beaconMonth.textContent = monthLine;
      this._els.beaconContext.textContent = this._t('target.context', {
        targetDate,
        actionDate,
      });
    }

    _prepareRenderableCutlets() {
      const seen = new Map();
      const prepared = [];
      for (const startJdn of this._orderedStarts) {
        const view = this._cutlets.get(startJdn);
        if (!view) continue;
        const days = [];
        for (const day of view.days) {
          const jdn = String(BigInt(day.jdn));
          if (this._value && this._targetJdn != null
              && BigInt(day.jdn) === this._targetJdn
              && !sameDaySemantics(day, this._value)) {
            throw new CalendarRenderConsistencyError(
              jdn,
              semanticDaySnapshot(this._value),
              semanticDaySnapshot(day),
            );
          }
          const previous = seen.get(jdn);
          if (!previous) {
            seen.set(jdn, day);
            days.push(day);
            continue;
          }
          if (!sameDaySemantics(previous, day)) {
            throw new CalendarRenderConsistencyError(
              jdn,
              semanticDaySnapshot(previous),
              semanticDaySnapshot(day),
            );
          }
          // Exact duplicate: one semantic date card is sufficient.
        }
        if (days.length > 0) prepared.push({ view, days });
      }
      return prepared;
    }

    _renderCutlets() {
      const prepared = this._prepareRenderableCutlets();
      const fragment = doc.createDocumentFragment();
      for (const item of prepared) {
        fragment.append(this._renderCutlet(item.view, item.days));
      }
      this._els.list.replaceChildren(fragment);
      const selected = this._els.list.querySelectorAll('[aria-current="date"]');
      if (selected.length > 1) {
        throw new CalendarRenderConsistencyError(
          this._targetJdn == null ? 'unknown' : this._targetJdn,
          Object.freeze({ ariaCurrentCount: selected.length }),
          Object.freeze({ ariaCurrentCount: selected.length }),
        );
      }
    }

    _renderCutlet(view, preparedDays) {
      const section = doc.createElement('section');
      const localCutlet = this._localCalendarName('cutlet', view.cutletName);
      section.className = 'cutlet';
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
        const isTarget = this._value != null && this._targetJdn != null
          && BigInt(day.jdn) === this._targetJdn && sameDaySemantics(day, this._value);
        if (isTarget) card.setAttribute('aria-current', 'date');

        if (isTarget) {
          const targetBadge = doc.createElement('span');
          targetBadge.className = 'target-badge';
          targetBadge.setAttribute('aria-hidden', 'true');
          targetBadge.textContent = this._t('target.searched');
          card.append(targetBadge);
        }

        const yearLine = doc.createElement('span');
        yearLine.className = 'day-line year';
        yearLine.textContent = this._t('date.yearLine', { year: day.year });

        const cutletLine = doc.createElement('span');
        cutletLine.className = 'day-line cutlet';
        cutletLine.textContent = this._t('date.cutletLine', {
          dayInCutlet: day.dayInCutlet,
          cutletName: localDayCutlet,
        });

        const monthLine = doc.createElement('span');
        monthLine.className = 'day-line month';
        monthLine.textContent = this._t('date.monthLine', {
          dayInMonth: day.dayInMonth,
          monthName: localDayMonth,
        });

        card.append(yearLine, cutletLine, monthLine);
        grid.append(card);
      }
      group.append(heading, grid);
      return group;
    }

    _scrollSelectedIntoView(year, cutletName, dayInCutlet, monthName, dayInMonth) {
      if (arguments.length !== 5 || year == null || cutletName == null || dayInCutlet == null
          || monthName == null || dayInMonth == null) {
        throw new TypeError('Li target de scrolling deve contener omni quin semantic partes del date.');
      }

      const target = Object.freeze({
        year: String(year),
        cutletName: String(cutletName),
        dayInCutlet: Number(dayInCutlet),
        monthName: String(monthName),
        dayInMonth: Number(dayInMonth),
      });
      const cards = Array.from(this._els.list.querySelectorAll('.day'));
      const matches = cards.filter((card) => {
        if (this._targetJdn != null && BigInt(card.dataset.jdn) !== this._targetJdn) return false;
        return sameDaySemantics({
          year: card.dataset.year,
          cutletName: card.dataset.cutletName,
          dayInCutlet: card.dataset.dayInCutlet,
          monthName: card.dataset.monthName,
          dayInMonth: card.dataset.dayInMonth,
        }, target);
      });

      if (matches.length !== 1) {
        throw new CalendarRenderConsistencyError(
          this._targetJdn == null ? 'unknown' : this._targetJdn,
          target,
          Object.freeze({ exactTargetMatchCount: matches.length }),
        );
      }

      const selected = matches[0];
      const section = selected.closest('.cutlet');
      const expectedStartJdn = this._targetJdn == null
        ? null : targetCutletStartJdn(this._targetJdn, target);
      if (!section || expectedStartJdn == null
          || BigInt(section.dataset.startJdn) !== expectedStartJdn
          || String(section.dataset.year) !== target.year
          || String(section.dataset.cutletName) !== target.cutletName) {
        throw new CalendarTargetCutletError(
          this._targetJdn == null ? 'unknown' : this._targetJdn,
          target,
          section ? Object.freeze({
            startJdn: String(section.dataset.startJdn),
            year: String(section.dataset.year),
            cutletName: String(section.dataset.cutletName),
          }) : Object.freeze({ missingSection: true }),
          'scroll-section-mismatch',
        );
      }

      for (const card of cards) {
        if (card === selected) card.setAttribute('aria-current', 'date');
        else card.removeAttribute('aria-current');
      }
      selected.scrollIntoView({ block: 'center', inline: 'nearest' });
      this._activeStartJdn = expectedStartJdn;
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
    PastafariDateElement,
    installSharedCalendarService: serviceApi.installSharedCalendarService,
    installSharedCalendarMemory: serviceApi.installSharedCalendarMemory,
  });

  root.PastafariCalendarBrowser = api;
  if (root.customElements && !root.customElements.get('pastafari-date')) {
    root.customElements.define('pastafari-date', PastafariDateElement);
  }
})(typeof globalThis === 'object' ? globalThis : this);
