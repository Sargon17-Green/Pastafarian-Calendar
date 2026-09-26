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
      return ['date', 'calculation-date', 'lang', 'open', 'live'];
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
      this._gateDetailError = null;
      this._liveEntries = [];
      this._liveState = 'idle';
      this._liveRenderedCount = 0;
      this._liveGroupNodes = new Map();
      this._liveSauceNodes = new Map();
      this._liveRenderQueued = false;
      this._liveLastGroupKey = null;
      this._livePhaseKey = null;
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
            display: none;
            color: var(--pastafari-color, var(--ink));
            font-family: Arial, "Noto Sans Hebrew", "Segoe UI", sans-serif;
            line-height: 1.5;
          }
          :host([open]) {
            position: fixed;
            inset: 0;
            z-index: 1000;
            display: block;
            width: 0;
            height: 0;
            margin: 0;
          }
          :host([live]) {
            position: relative;
            z-index: 25;
            display: block;
            width: min(100%, 72rem);
            height: auto;
            margin: clamp(1rem, 3vw, 2rem) auto;
          }
          *, *::before, *::after { box-sizing: border-box; }
          [hidden] { display: none !important; }
          button { font: inherit; min-height: 44px; }
          button:focus-visible,
          [tabindex]:focus-visible {
            outline: 4px solid var(--focus);
            outline-offset: 3px;
          }
          .shell {
            width: min(72rem, calc(100vw - 2rem));
            height: min(52rem, calc(100dvh - 2rem));
            max-width: none;
            max-height: calc(100dvh - 2rem);
            margin: auto;
            padding: 0;
            overflow: hidden;
            border: 2px solid var(--ink);
            border-radius: 1.2rem;
            background: var(--panel);
            color: var(--ink);
            box-shadow: 0 24px 70px rgb(0 0 0 / 28%);
          }
          .shell[open] {
            display: grid;
            grid-template-rows: auto auto auto minmax(0, 1fr);
          }
          :host([live]) .shell {
            position: relative;
            width: 100%;
            height: min(42rem, 72dvh);
            max-height: min(42rem, 72dvh);
            margin: 0;
            border-color: #a75a42;
            box-shadow: 0 18px 50px rgb(54 36 20 / 16%);
          }
          :host([live]) .shell::backdrop { display: none; }
          :host([live]) .close,
          :host([live]) .nav { display: none !important; }
          .shell::backdrop {
            background: rgb(23 19 14 / 48%);
            backdrop-filter: blur(2px);
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
            flex-wrap: wrap;
            gap: .45rem;
            padding: .75rem clamp(1rem, 3vw, 2rem);
            overflow: visible;
            border-bottom: 1px solid var(--line);
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
          .live-hero {
            display: none;
            grid-template-columns: minmax(9rem, 12rem) minmax(0, 1fr);
            gap: 1rem;
            align-items: center;
            min-height: 8rem;
            padding: .8rem clamp(1rem, 3vw, 2rem);
            overflow: hidden;
            border-bottom: 1px solid var(--line);
            background:
              radial-gradient(circle at 15% 20%, rgb(255 224 183 / 55%), transparent 30%),
              linear-gradient(90deg, #fff8eb, #fffdf8);
          }
          :host([live]) .live-hero { display: grid; }
          .monster-stage {
            position: relative;
            height: 6.5rem;
            min-width: 9rem;
          }
          .monster {
            position: absolute;
            inset: .2rem .5rem auto;
            height: 5.6rem;
            animation: monster-float 2.2s ease-in-out infinite;
            filter: drop-shadow(0 .5rem .35rem rgb(70 36 18 / 16%));
          }
          .monster-noodle {
            position: absolute;
            width: 4.4rem;
            height: 2.1rem;
            border: .34rem solid #d6a83a;
            border-inline-start-color: transparent;
            border-inline-end-color: transparent;
            border-radius: 50%;
          }
          .monster-noodle.n1 { inset: 1.3rem auto auto .2rem; transform: rotate(-16deg); }
          .monster-noodle.n2 { inset: 2.3rem .1rem auto auto; transform: rotate(19deg); }
          .monster-noodle.n3 { inset: 3rem auto auto 2.7rem; transform: rotate(5deg); width: 5.2rem; }
          .monster-meatball {
            position: absolute;
            top: 1.55rem;
            width: 2.45rem;
            height: 2.45rem;
            border: .18rem solid #6f281b;
            border-radius: 48% 52% 46% 54%;
            background:
              radial-gradient(circle at 32% 28%, #d77755 0 12%, transparent 13%),
              radial-gradient(circle at 68% 62%, #7f2f20 0 11%, transparent 12%),
              #a8442c;
          }
          .monster-meatball.m1 { left: 2.25rem; transform: rotate(-8deg); }
          .monster-meatball.m2 { right: 2.25rem; transform: rotate(7deg); }
          .monster-eye {
            position: absolute;
            top: -1.35rem;
            left: .78rem;
            width: .72rem;
            height: .72rem;
            border: .14rem solid #17130e;
            border-radius: 50%;
            background: #fffdf8;
            box-shadow: 0 1rem 0 -.27rem #d6a83a;
          }
          .monster-eye::after {
            content: "";
            position: absolute;
            inset: .18rem;
            border-radius: 50%;
            background: #17130e;
          }
          .sauce-drip {
            position: absolute;
            top: 3.55rem;
            width: .58rem;
            height: 1.2rem;
            border-radius: 50% 50% 65% 65%;
            background: #9d3825;
            transform-origin: top center;
            animation: sauce-drip 1.8s ease-in infinite;
          }
          .sauce-drip.d1 { left: 4.25rem; }
          .sauce-drip.d2 { right: 3.3rem; animation-delay: .75s; }
          .live-current-wrap { min-width: 0; }
          .live-current-kicker {
            margin: 0 0 .25rem;
            color: var(--accent-dark);
            font-size: .72rem;
            font-weight: 900;
            letter-spacing: .08em;
            text-transform: uppercase;
          }
          .live-current {
            margin: 0;
            overflow-wrap: anywhere;
            font-family: Georgia, "Times New Roman", "Noto Serif Hebrew", serif;
            font-size: clamp(1rem, 2vw, 1.35rem);
            font-weight: 800;
          }
          @keyframes monster-float {
            0%, 100% { transform: translateY(.15rem) rotate(-1deg); }
            50% { transform: translateY(-.35rem) rotate(1deg); }
          }
          @keyframes sauce-drip {
            0% { transform: translateY(0) scaleY(.45); opacity: .9; }
            72% { transform: translateY(1.1rem) scaleY(1); opacity: .8; }
            100% { transform: translateY(1.75rem) scale(.4); opacity: 0; }
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
            min-height: 0;
            overflow: auto;
            overscroll-behavior: contain;
            scrollbar-gutter: stable;
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
            grid-template-columns: minmax(12rem, 22rem) minmax(0, 1fr);
            gap: .45rem 1rem;
            margin: 0;
          }
          .kv dt {
            min-width: 0;
            color: var(--muted);
            font-family: ui-monospace, "SFMono-Regular", Consolas, monospace;
            font-size: .86em;
            font-weight: 800;
            overflow-wrap: anywhere;
            word-break: break-word;
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
          .exact-number[data-expanded="true"] {
            cursor: zoom-out;
            white-space: normal;
            word-break: break-all;
          }
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
            flex-wrap: wrap;
            gap: .4rem;
            overflow: visible;
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
          .inline-error {
            margin: .65rem 0 0;
            padding: .6rem .7rem;
            border-inline-start: .3rem solid #9b1c1c;
            background: #fff1f1;
            color: #651010;
            font-weight: 700;
          }
          .archaeology-note { color: var(--muted); font-style: italic; }
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

          .live-log {
            display: grid;
            gap: .7rem;
          }
          .live-group,
          .live-sauce {
            min-width: 0;
            border: 1px solid var(--line);
            border-radius: .85rem;
            background: #fff;
            overflow: clip;
          }
          .live-group > summary,
          .live-sauce > summary {
            display: flex;
            gap: .65rem;
            align-items: center;
            min-height: 46px;
            padding: .7rem .85rem;
            cursor: pointer;
            font-weight: 900;
            list-style-position: inside;
          }
          .live-group > summary { background: #fff7e8; }
          .live-sauce {
            margin: .55rem;
            border-color: #dfc9b9;
            background: #fffdfa;
          }
          .live-sauce > summary { background: #fff4ee; font-size: .92rem; }
          .live-group-count {
            margin-inline-start: auto;
            min-width: 2.1rem;
            padding: .12rem .45rem;
            border-radius: 999px;
            background: #efe5d8;
            color: #4a382d;
            font-size: .78rem;
            font-variant-numeric: tabular-nums;
            text-align: center;
          }
          .live-list {
            display: grid;
            gap: .35rem;
            margin: 0;
            padding: .5rem;
            list-style: none;
          }
          .live-row {
            display: grid;
            grid-template-columns: 2.7rem minmax(0, 1fr) auto;
            gap: .65rem;
            align-items: center;
            min-width: 0;
            padding: .5rem .6rem;
            border: 1px solid #ebe3d8;
            border-radius: .65rem;
            background: #fcfaf6;
          }
          .live-row-copy { min-width: 0; }
          .live-row-label {
            display: block;
            overflow-wrap: anywhere;
            font-weight: 850;
            line-height: 1.25;
          }
          .live-row-value {
            display: block;
            margin-top: .13rem;
            overflow-wrap: anywhere;
            color: var(--muted);
            font-family: ui-monospace, "SFMono-Regular", Consolas, monospace;
            font-size: .76rem;
            line-height: 1.3;
          }
          .live-time {
            align-self: start;
            padding-top: .15rem;
            color: var(--muted);
            font-size: .72rem;
            font-variant-numeric: tabular-nums;
            white-space: nowrap;
          }
          .live-icon {
            position: relative;
            display: grid;
            place-items: center;
            width: 2.25rem;
            height: 2.25rem;
            color: #26150f;
            font-family: ui-monospace, "SFMono-Regular", Consolas, monospace;
            font-size: .66rem;
            font-weight: 950;
            line-height: 1;
          }
          .live-icon--drop {
            width: 1.9rem;
            height: 1.9rem;
            margin: .18rem;
            border: 2px solid #672013;
            border-radius: 58% 44% 62% 35%;
            background: #d86d4c;
            transform: rotate(45deg);
          }
          .live-icon--drop > span { transform: rotate(-45deg); }
          .live-icon--bowl {
            height: 1.65rem;
            margin-top: .45rem;
            border: 3px solid #7d5a33;
            border-top: 1px solid #7d5a33;
            border-radius: 15% 15% 52% 52%;
            background: linear-gradient(#fffdf8 0 30%, #e6c77d 31%);
          }
          .live-icon--gate {
            height: 2.1rem;
            border: 3px solid #6f5138;
            border-bottom-width: 1px;
            border-radius: 1.05rem 1.05rem .15rem .15rem;
            background: #f5e8d5;
          }
          .live-icon--stone {
            width: 2rem;
            height: 1.75rem;
            margin: .25rem;
            border: 2px solid #6c665e;
            border-radius: 48% 56% 42% 58%;
            background: #d7d1c8;
          }
          .live-icon--year,
          .live-icon--selection,
          .live-icon--result,
          .live-icon--view {
            border: 2px solid #672013;
            border-radius: 50%;
            background: #fff1e8;
          }
          .live-icon--selection {
            box-shadow: inset 0 0 0 .28rem #fffdf8, inset 0 0 0 .4rem #9d3825;
          }
          .live-icon--weave {
            border: 2px solid #85662f;
            border-radius: .35rem;
            background:
              repeating-linear-gradient(45deg, #e7c86d 0 .2rem, transparent .2rem .4rem),
              repeating-linear-gradient(-45deg, #d78b45 0 .2rem, #fff4da .2rem .4rem);
          }
          .live-icon--sauce {
            border: 2px solid #9d3825;
            border-radius: 50% 45% 55% 42%;
            background: radial-gradient(circle at 40% 35%, #eeaa75, #b94e32 65%, #8d2f20);
            color: white;
          }
          .live-complete-note {
            margin: 0 0 .8rem;
            padding: .65rem .8rem;
            border-inline-start: .35rem solid #4f713d;
            background: #f0f6e9;
            font-weight: 800;
          }
          @media (max-width: 700px) {
            .shell {
              width: 100vw;
              height: 100dvh;
              max-height: 100dvh;
              border: 0;
              border-radius: 0;
            }
            :host([live]) {
              width: 100%;
              margin: .75rem auto;
            }
            :host([live]) .shell {
              width: 100%;
              height: min(38rem, 76dvh);
              max-height: min(38rem, 76dvh);
              border: 1px solid var(--line);
              border-radius: .85rem;
            }
            .live-hero {
              grid-template-columns: 7.5rem minmax(0, 1fr);
              min-height: 7rem;
              padding: .65rem .75rem;
            }
            .monster-stage { transform: scale(.82); transform-origin: center; }
            .live-row { grid-template-columns: 2.4rem minmax(0, 1fr); }
            .live-time { grid-column: 2; padding: 0; }
            .head {
              grid-template-columns: minmax(0, 1fr) auto;
              gap: .65rem;
              padding: .8rem 1rem;
            }
            .head h2 { font-size: clamp(1.55rem, 8vw, 2.35rem); }
            .subtitle { margin-top: .4rem; font-size: .86rem; }
            .close { align-self: start; justify-self: end; }
            .nav {
              display: grid;
              grid-template-columns: repeat(2, minmax(0, 1fr));
              gap: .35rem;
              padding: .55rem .75rem;
            }
            .nav button {
              min-width: 0;
              min-height: 44px;
              white-space: normal;
              line-height: 1.2;
            }
            .pane { padding: 1rem; }
            .kv { grid-template-columns: 1fr; gap: .15rem; }
            .kv dd { margin-bottom: .55rem; }
            .result-five { grid-template-columns: 1fr 1fr; }
          }
          @media (max-width: 420px) {
            .result-five { grid-template-columns: 1fr; }
          }
          @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after {
              scroll-behavior: auto !important;
              transition: none !important;
              animation: none !important;
            }
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
        <dialog class="shell" part="shell" aria-modal="true" aria-labelledby="pastafari-cooking-title" aria-busy="false">
          <header class="head">
            <div>
              <p class="kicker">PASTAFARI · TRACE</p>
              <h2 class="title" id="pastafari-cooking-title"></h2>
              <p class="subtitle"></p>
            </div>
            <button class="close" type="button"></button>
          </header>
          <nav class="nav" aria-label="Trace chapters"></nav>
          <section class="live-hero">
            <div class="monster-stage" aria-hidden="true">
              <div class="monster">
                <i class="monster-noodle n1"></i>
                <i class="monster-noodle n2"></i>
                <i class="monster-noodle n3"></i>
                <span class="monster-meatball m1"><i class="monster-eye"></i></span>
                <span class="monster-meatball m2"><i class="monster-eye"></i></span>
                <i class="sauce-drip d1"></i>
                <i class="sauce-drip d2"></i>
              </div>
            </div>
            <div class="live-current-wrap">
              <p class="live-current-kicker"><span>PASTAFARI</span> · <span class="live-kicker"></span></p>
              <p class="live-current" role="status" aria-live="polite"></p>
            </div>
          </section>
          <div class="status loading" hidden role="status" aria-live="polite">
            <p class="loading-text"></p>
          </div>
          <div class="status error" hidden role="alert">
            <p class="error-text"></p>
            <button class="retry" type="button"></button>
          </div>
          <section class="pane" tabindex="-1"></section>
        </dialog>
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
        liveKicker: this.shadowRoot.querySelector('.live-kicker'),
        liveCurrent: this.shadowRoot.querySelector('.live-current'),
        pane: this.shadowRoot.querySelector('.pane'),
      };
      this._els.close.addEventListener('click', () => this.close());
      this._els.shell.addEventListener('cancel', (event) => {
        if (typeof event.preventDefault === 'function') event.preventDefault();
        this.close();
      });
      this.shadowRoot.addEventListener('keydown', (event) => {
        if (!event || event.key !== 'Escape' || !this.hasAttribute('open')) return;
        // Native modal dialogs own Escape through the cancel event. Keep this
        // path only as a fallback for environments without showModal().
        if (typeof this._els.shell.showModal === 'function') return;
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
      this._syncDialogOpen();
      if (this.hasAttribute('open')) this._queueLoad();
    }

    disconnectedCallback() {
      if (!this._connected) return;
      this._connected = false;
      if (this._els && this._els.shell && this._els.shell.hasAttribute('open')) {
        if (typeof this._els.shell.close === 'function') this._els.shell.close();
        else this._els.shell.removeAttribute('open');
      }
      this._generation += 1;
      this._queuedEpoch = null;
      this._gateDetailLoading = null;
      this._gateDetailError = null;
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === newValue) return;
      if (name === 'lang') {
        this._applyLocale();
        this._renderState();
        return;
      }
      if (name === 'open') {
        this._syncDialogOpen();
        if (newValue !== null && this._connected) this._queueLoad();
        else {
          this._generation += 1;
          this._queuedEpoch = null;
          this._gateDetailLoading = null;
          this._gateDetailError = null;
        }
        return;
      }
      if (name === 'live') {
        this._syncDialogOpen();
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

    _currentInputKey() {
      try {
        const targetDate = axis.normalizeDateInput(this.getAttribute('date'), 'Li date a examinar');
        const calculationDate = axis.normalizeDateInput(this.getAttribute('calculation-date'), 'Li die de calculation');
        return String(axis.gregorianToJdn(calculationDate)) + ':' + String(axis.gregorianToJdn(targetDate));
      } catch (_) {
        return null;
      }
    }

    _resetLiveLog(state = 'running') {
      this._liveEntries = [];
      this._liveState = state;
      this._liveRenderedCount = 0;
      this._liveGroupNodes = new Map();
      this._liveSauceNodes = new Map();
      this._liveRenderQueued = false;
      this._liveLastGroupKey = null;
      this._livePhaseKey = null;
      if (this._els && this._els.pane) this._els.pane.replaceChildren();
      if (this._els && this._els.nav) this._els.nav.replaceChildren();
    }

    beginLiveTrace() {
      this._generation += 1;
      this._queuedEpoch = null;
      this._trace = null;
      this._traceInputKey = null;
      this._gateDetails.clear();
      this._gateDetailLoading = null;
      this._gateDetailError = null;
      this._resetLiveLog('running');
      this.setAttribute('live', '');
      this._syncDialogOpen();
      this._hideStatus();
      if (this._els && this._els.liveCurrent) {
        this._els.liveCurrent.textContent = this._t('cooking.loading');
      }
      return this;
    }

    appendLiveProgress(event) {
      if (!event || typeof event !== 'object') return;
      const copy = plainClone(event);
      copy.kind = String(copy.kind || 'progress');
      copy.payload = copy.payload && typeof copy.payload === 'object' ? copy.payload : {};
      this._liveEntries.push(copy);
      if (this._liveState === 'idle' || this._liveState === 'complete') this._liveState = 'running';
      if (this._els && this._els.liveCurrent) {
        this._els.liveCurrent.textContent = this._liveEventLabel(copy);
      }
      this._scheduleLiveDrain();
    }

    finishLiveTrace(trace = null) {
      if (trace && typeof trace === 'object') {
        this._trace = trace;
        this._traceInputKey = this._currentInputKey();
      }
      this._liveState = 'complete';
      this._drainLiveRows();
      if (this.hasAttribute('live')) this.removeAttribute('live');
      this._syncDialogOpen();
      if (this.hasAttribute('open')) {
        this._hideStatus();
        this._renderState();
      }
      return trace;
    }

    failLiveTrace(error) {
      this._liveState = 'error';
      this._drainLiveRows();
      if (this.hasAttribute('live')) this.removeAttribute('live');
      this._syncDialogOpen();
      if (root.console && typeof root.console.error === 'function') root.console.error(error);
    }

    _syncDialogOpen() {
      if (!this._els || !this._els.shell) return;
      const shell = this._els.shell;
      const live = this.hasAttribute('live');
      const modal = this.hasAttribute('open');
      const shouldOpen = (live || modal) && this._connected;
      shell.setAttribute('aria-modal', modal && !live ? 'true' : 'false');
      const isOpen = shell.hasAttribute('open');
      if (shouldOpen && !isOpen) {
        try {
          if (modal && !live && typeof shell.showModal === 'function') shell.showModal();
          else shell.setAttribute('open', '');
        } catch (_) {
          shell.setAttribute('open', '');
        }
        if (modal && !live) enqueueMicrotask(() => {
          if (!this._connected || !this.hasAttribute('open') || this.hasAttribute('live')) return;
          if (this._els && this._els.close && typeof this._els.close.focus === 'function') {
            try { this._els.close.focus({ preventScroll: true }); }
            catch (_) { this._els.close.focus(); }
          }
        });
      } else if (!shouldOpen && isOpen) {
        if (typeof shell.close === 'function') shell.close();
        else shell.removeAttribute('open');
      }
    }

    _queueLoad() {
      if (!this._connected || !this.hasAttribute('open')) return;
      this._gateDetailLoading = null;
      this._gateDetailError = null;
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
      if (this._els.liveKicker) this._els.liveKicker.textContent = this._t('cooking.live.kicker');
      this._els.nav.setAttribute('aria-label', this._t('cooking.title'));
    }

    _t(key, values) { return i18n.translate(this._locale, key, values); }
    _term(key) { return this._t('cooking.term.' + key); }

    _liveGroupKey(event) {
      const kind = String(event && event.kind || '');
      if (kind === 'run-start' || kind === 'conversion-cache-hit') this._livePhaseKey = 'inputs';
      else if (kind === 'year-resolution-start') this._livePhaseKey = 'year-walk';
      else if (kind === 'structure-start') this._livePhaseKey = 'structure-sauce';
      else if (kind === 'final-result-ready' || kind === 'semantic-execution-finished' || kind === 'trace-ready') {
        this._livePhaseKey = 'result';
      } else if (kind === 'view-start' || kind.startsWith('view-')) {
        this._livePhaseKey = 'position';
      }
      if (!this._livePhaseKey) {
        if (kind.startsWith('year-') || kind.startsWith('gate-')) this._livePhaseKey = 'year-walk';
        else this._livePhaseKey = 'inputs';
      }
      return this._livePhaseKey;
    }

    _liveGroupTitle(key) {
      if (CHAPTER_KEYS[key]) return this._t(CHAPTER_KEYS[key]);
      return String(key);
    }

    _liveIconKind(event) {
      const kind = String(event && event.kind || '');
      if (kind.includes('drop') || kind.includes('grind')) return 'drop';
      if (kind.includes('bowl') || kind === 'post-stir') return 'bowl';
      if (kind.startsWith('gate-')) return 'gate';
      if (kind.startsWith('stone-')) return 'stone';
      if (kind.startsWith('year-')) return 'year';
      if (kind === 'selection-result') return 'selection';
      if (kind.includes('weaving') || kind.includes('month')) return 'weave';
      if (kind.startsWith('view-')) return 'view';
      if (kind.startsWith('sauce-')) return 'sauce';
      return 'result';
    }

    _liveEventNumber(event) {
      const p = event && event.payload || {};
      const kind = String(event && event.kind || '');
      const compact = (value) => {
        const text = String(value == null ? '' : value);
        return text.length <= 5 ? text : text.slice(0, 4) + '…';
      };
      if (kind === 'hidden-grind' || kind === 'visible-grind') {
        return compact(String(p.ordinal || '') + '.' + String(p.grind || ''));
      }
      if (p.ordinal != null) return compact(p.ordinal);
      if (p.bowlId != null) return compact(p.bowlId);
      if (p.stirIndex != null) return compact(p.stirIndex);
      if (p.signedIndex != null) return compact(p.signedIndex);
      if (p.index != null) return compact(p.index);
      if (kind === 'year-transition' && p.toYear && p.toYear.number != null) return compact(p.toYear.number);
      if (p.number != null) return compact(p.number);
      if (p.count != null) return compact(p.count);
      if (kind === 'selection-result' && p.output != null) return compact(p.output);
      if (p.sauceId) return compact(String(p.sauceId).replace(/^sauce-/, ''));
      if (kind === 'final-result-ready' || kind === 'trace-ready') return '✓';
      return '·';
    }

    _liveSelectionLabel(label) {
      switch (String(label || '')) {
        case 'gate-gap': return this._term('gateGap');
        case 'YEAR_5000-semantic': return this._chapterTitle('year-5000');
        case 'cutlet-count': return this._chapterTitle('cutlets');
        case 'cutlet-partition-semantic': return this._chapterTitle('cutlets') + ' · ' + this._term('selection');
        case 'cutlet-names-distinct-rank': return this._chapterTitle('cutlets') + ' · ' + this._t('cooking.live.names');
        case 'month-count': return this._chapterTitle('months');
        case 'month-lengths': return this._chapterTitle('months') + ' · ' + this._t('cooking.live.lengths');
        case 'month-weaving': return this._term('weaving');
        case 'month-names-distinct-rank': return this._chapterTitle('months') + ' · ' + this._t('cooking.live.names');
        default: return '';
      }
    }

    _liveEventLabel(event) {
      const p = event && event.payload || {};
      switch (String(event && event.kind || '')) {
        case 'run-start': return this._chapterTitle('inputs');
        case 'conversion-cache-hit': return this._term('checkpoints') + ' · ' + this._t('cooking.live.cache');
        case 'gate-gap-start': return this._term('gateGap') + ' ' + String(p.signedIndex);
        case 'gate-gap-finished': return this._term('gateGap') + ' ' + String(p.signedIndex);
        case 'gate-ready': return this._term('gate') + ' ' + String(p.index);
        case 'year-resolution-start': return this._chapterTitle('year-walk');
        case 'year-5000-ready':
        case 'year-5000-memory': return this._chapterTitle('year-5000');
        case 'year-walk-anchor': return this._term('year') + ' ' + String(p.number);
        case 'year-walk-step': return this._term('year') + ' ' + String(p.fromNumber) + ' → ' + String(p.toNumber);
        case 'year-transition': {
          const from = p.fromYear && p.fromYear.number != null ? p.fromYear.number : '?';
          const to = p.toYear && p.toYear.number != null ? p.toYear.number : '?';
          return this._term('year') + ' ' + String(from) + ' → ' + String(to);
        }
        case 'year-authoritative': return this._term('year') + ' ' + String(p.year && p.year.number != null ? p.year.number : '');
        case 'year-walk-finished':
        case 'year-resolution-finished': return this._chapterTitle('year-walk') + ' ✓';
        case 'sauce-start': return this._term('sauce') + ' ' + String(p.sauceId || '');
        case 'sauce-finished': return this._term('sauce') + ' ' + String(p.sauceId || '') + ' ✓';
        case 'stone-seed': return this._term('stone') + ' 1';
        case 'stone-transition': return this._term('stone') + ' ' + String(p.ordinal);
        case 'hidden-start': return this._term('hiddenDrop') + ' ' + String(p.ordinal);
        case 'hidden-grind': return this._term('hiddenDrop') + ' ' + String(p.ordinal) + ' · ' + this._term('grind') + ' ' + String(p.grind);
        case 'visible-start': return this._term('visibleDrop') + ' ' + String(p.ordinal);
        case 'visible-grind': return this._term('visibleDrop') + ' ' + String(p.ordinal) + ' · ' + this._term('grind') + ' ' + String(p.grind);
        case 'initial-bowl': return this._term('initialBowls') + ' · ' + this._term('bowl') + ' ' + String(p.bowlId);
        case 'bowl-round': return this._term('bowlRound') + ' ' + String(p.ordinal);
        case 'post-stir': return this._term('postStir') + ' ' + String(p.stirIndex);
        case 'selection-result': {
          const label = this._liveSelectionLabel(p.label);
          return this._term('selection') + (label ? ' · ' + label : '');
        }
        case 'structure-start': return this._chapterTitle('structure-sauce');
        case 'structure-finished': return this._chapterTitle('structure-sauce') + ' ✓';
        case 'cutlet-count-ready': return this._term('cutlet') + ' × ' + String(p.count);
        case 'cutlet-partition-ready': return this._chapterTitle('cutlets') + ' · ' + this._term('selection');
        case 'cutlet-names-ready': return this._chapterTitle('cutlets') + ' · ' + this._t('cooking.live.names');
        case 'cutlets-materialized': return this._chapterTitle('cutlets') + ' ✓';
        case 'month-count-ready': return this._chapterTitle('months') + ' × ' + String(p.count);
        case 'month-lengths-ready': return this._chapterTitle('months') + ' · ' + this._t('cooking.live.lengths');
        case 'month-weaving-ready': return this._term('weaving') + ' ✓';
        case 'month-names-ready': return this._chapterTitle('months') + ' · ' + this._t('cooking.live.names');
        case 'final-result-ready': return this._chapterTitle('result') + ' ✓';
        case 'semantic-execution-finished': return this._t('cooking.sameExecution');
        case 'view-day-ready': return this._chapterTitle('position') + ' · ' + this._t('field.day') + ' ' + String(p.ordinal);
        case 'view-start': return this._chapterTitle('position');
        case 'view-finished': return this._chapterTitle('position') + ' ✓';
        case 'trace-ready': return this._chapterTitle('result') + ' · ' + this._t('cooking.live.trace') + ' ✓';
        default: return String(event && event.kind || 'progress');
      }
    }

    _livePayloadSummary(event) {
      const p = event && event.payload || {};
      const kind = String(event && event.kind || '');
      const short = (value) => value == null ? '' : exactDisplay(value);
      if (kind === 'stone-seed' && p.values) {
        return Object.entries(p.values).map(([key, value]) => key + '=' + short(value)).join(' · ');
      }
      if (kind === 'stone-transition' && p.after) {
        return Object.entries(p.after).map(([key, value]) => key + '=' + short(value)).join(' · ');
      }
      if (kind.endsWith('-grind')) return (p.stoneKind ? String(p.stoneKind) + ' → ' : '') + short(p.after);
      if (kind.endsWith('-start')) return p.initial != null ? short(p.initial) : '';
      if (kind === 'initial-bowl') return short(p.value);
      if (kind === 'bowl-round') {
        return (p.drop != null ? this._term('visibleDrop') + '=' + short(p.drop) + ' · ' : '')
          + safeArray(p.afterBowls).map(short).join(' / ');
      }
      if (kind === 'post-stir') return safeArray(p.afterBowls).map(short).join(' / ');
      if (kind === 'selection-result') {
        return (p.familySize != null ? 'N=' + short(p.familySize) + ' · ' : '')
          + (p.rejectionSteps != null ? '↻' + short(p.rejectionSteps) + ' · ' : '')
          + '→ ' + short(p.output);
      }
      if (kind === 'gate-gap-finished') return 'Δ=' + short(p.gap);
      if (kind === 'gate-ready') return short(p.day);
      if (kind === 'year-transition') {
        const from = p.fromYear && p.fromYear.number != null ? p.fromYear.number : '?';
        const to = p.toYear && p.toYear.number != null ? p.toYear.number : '?';
        return String(from) + ' → ' + String(to);
      }
      if (kind === 'year-walk-step') return short(p.fromNumber) + ' → ' + short(p.toNumber);
      if (kind === 'year-walk-finished') {
        const arrow = p.direction === 'previous' ? '←' : (p.direction === 'next' ? '→' : '↔');
        return arrow + ' × ' + short(p.stepCount) + ' · ' + short(p.number);
      }
      if (kind === 'year-authoritative' && p.year) {
        return [p.year.number, p.year.openDay, p.year.closeDay].filter((x) => x != null).map(short).join(' · ');
      }
      if (kind === 'sauce-finished') return safeArray(p.finalBowls).map(short).join(' / ');
      if (kind === 'cutlet-partition-ready') return safeArray(p.partition).join(' · ');
      if (kind === 'cutlet-names-ready' || kind === 'month-names-ready') return safeArray(p.indices).join(' · ');
      if (kind === 'month-lengths-ready') return safeArray(p.lengths).join(' · ');
      if (kind === 'final-result-ready') {
        return [p.year, p.cutletName, p.dayInCutlet, p.monthName, p.dayInMonth].filter((x) => x != null).join(' · ');
      }
      if (kind === 'view-day-ready' && p.targetDay != null) return String(p.targetDay);
      const scalars = Object.entries(p).filter(([, value]) =>
        value === null || ['string', 'number', 'boolean'].includes(typeof value)
      ).slice(0, 3);
      return scalars.map(([, value]) => short(value)).join(' · ');
    }

    _liveDurationText(value, withPlus = false) {
      const ms = Number(value);
      if (!Number.isFinite(ms) || ms < 0) return '';
      const prefix = withPlus ? '+' : '';
      if (ms < 1 && ms > 0) return prefix + ms.toFixed(2) + ' ms';
      if (ms < 10) return prefix + ms.toFixed(1) + ' ms';
      if (ms < 1000) return prefix + String(Math.round(ms)) + ' ms';
      if (ms < 10000) return prefix + (ms / 1000).toFixed(2) + ' s';
      return prefix + (ms / 1000).toFixed(1) + ' s';
    }

    _liveTimeText(event) {
      return this._liveDurationText(event && event.durationMs, true);
    }

    _liveBadgeText(node) {
      const duration = this._liveDurationText(node && node.totalMs, false);
      return String(node && node.value || 0) + (duration ? ' · ' + duration : '');
    }

    _liveIcon(event) {
      const icon = doc.createElement('span');
      const kind = this._liveIconKind(event);
      icon.className = 'live-icon live-icon--' + kind;
      icon.setAttribute('aria-hidden', 'true');
      const value = doc.createElement('span');
      value.textContent = this._liveEventNumber(event);
      icon.append(value);
      return icon;
    }

    _ensureLiveGroup(key) {
      if (this._liveGroupNodes.has(key)) {
        const existing = this._liveGroupNodes.get(key);
        if (this._liveState === 'running' && this._liveLastGroupKey !== key) {
          const previous = this._liveGroupNodes.get(this._liveLastGroupKey);
          if (previous) previous.details.open = false;
          existing.details.open = true;
          this._liveLastGroupKey = key;
        }
        return existing;
      }
      const details = doc.createElement('details');
      details.className = 'live-group';
      details.dataset.group = key;
      details.open = this._liveState === 'running';
      const summary = doc.createElement('summary');
      const title = doc.createElement('span');
      title.textContent = this._liveGroupTitle(key);
      const count = doc.createElement('span');
      count.className = 'live-group-count';
      count.textContent = '0';
      summary.append(title, count);
      const list = doc.createElement('ol');
      list.className = 'live-list';
      details.append(summary, list);
      this._els.pane.append(details);
      const node = { details, list, count, value: 0, totalMs: 0 };
      this._liveGroupNodes.set(key, node);
      if (this._liveState === 'running' && this._liveLastGroupKey && this._liveLastGroupKey !== key) {
        const previous = this._liveGroupNodes.get(this._liveLastGroupKey);
        if (previous) previous.details.open = false;
      }
      this._liveLastGroupKey = key;
      return node;
    }

    _ensureLiveSauce(group, event) {
      const p = event && event.payload || {};
      const sauceId = p.sauceId == null ? null : String(p.sauceId);
      if (!sauceId) return group;
      if (this._liveSauceNodes.has(sauceId)) return this._liveSauceNodes.get(sauceId);
      if (event.kind === 'sauce-start') {
        for (const prior of this._liveSauceNodes.values()) prior.details.open = false;
      }
      const details = doc.createElement('details');
      details.className = 'live-sauce';
      details.open = this._liveState === 'running';
      const summary = doc.createElement('summary');
      const title = doc.createElement('span');
      title.textContent = this._term('sauce') + ' ' + sauceId.replace(/^sauce-/, '')
        + (p.gateIndex != null ? ' · ' + this._term('gate') + ' ' + String(p.gateIndex) : '');
      const count = doc.createElement('span');
      count.className = 'live-group-count';
      count.textContent = '0';
      summary.append(title, count);
      const list = doc.createElement('ol');
      list.className = 'live-list';
      details.append(summary, list);
      const wrapper = doc.createElement('li');
      wrapper.className = 'live-sauce-item';
      wrapper.append(details);
      group.list.append(wrapper);
      const node = { details, list, count, value: 0, totalMs: 0 };
      this._liveSauceNodes.set(sauceId, node);
      return node;
    }

    _appendLiveRow(event) {
      const key = this._liveGroupKey(event);
      const group = this._ensureLiveGroup(key);
      const kind = String(event && event.kind || '');
      const markerOnly = kind === 'run-start'
        || kind === 'year-resolution-start'
        || kind === 'structure-start'
        || kind === 'view-start'
        || kind === 'gate-gap-start'
        || kind === 'sauce-start';
      if (kind === 'sauce-start') this._ensureLiveSauce(group, event);
      if (markerOnly) return false;
      const durationMs = Math.max(0, Number(event && event.durationMs) || 0);
      group.value += 1;
      group.totalMs += durationMs;
      group.count.textContent = this._liveBadgeText(group);
      const target = this._ensureLiveSauce(group, event);
      if (target !== group) {
        target.value += 1;
        target.totalMs += durationMs;
        target.count.textContent = this._liveBadgeText(target);
      }
      const li = doc.createElement('li');
      li.className = 'live-row';
      li.dataset.kind = String(event.kind);
      li.append(this._liveIcon(event));
      const copy = doc.createElement('span');
      copy.className = 'live-row-copy';
      const label = doc.createElement('span');
      label.className = 'live-row-label';
      label.textContent = this._liveEventLabel(event);
      const value = doc.createElement('span');
      value.className = 'live-row-value';
      value.textContent = this._livePayloadSummary(event);
      if (!value.textContent) value.hidden = true;
      copy.append(label, value);
      const time = doc.createElement('small');
      time.className = 'live-time';
      time.textContent = this._liveTimeText(event);
      li.append(copy, time);
      target.list.append(li);
      return true;
    }

    _prepareLiveLog(reset = false) {
      if (!this._els) return;
      if (reset) {
        this._els.pane.replaceChildren();
        this._liveRenderedCount = 0;
        this._liveGroupNodes = new Map();
        this._liveSauceNodes = new Map();
        this._liveLastGroupKey = null;
        this._livePhaseKey = null;
      }
      this._els.nav.replaceChildren();
      this._els.pane.hidden = false;
      this._els.loading.hidden = true;
      this._els.error.hidden = true;
      this._els.shell.setAttribute('aria-busy', this._liveState === 'running' ? 'true' : 'false');
    }

    _drainLiveRows(reset = false) {
      if (!this._els || !this._liveEntries.length) return;
      const pane = this._els.pane;
      const scrollHeight = Number(pane.scrollHeight) || 0;
      const scrollTop = Number(pane.scrollTop) || 0;
      const clientHeight = Number(pane.clientHeight) || 0;
      const follow = this.hasAttribute('live')
        && (scrollHeight === 0 || clientHeight === 0 || scrollHeight - scrollTop - clientHeight < 96);
      if (reset) this._prepareLiveLog(true);
      else if (this._liveRenderedCount === 0) this._prepareLiveLog(false);
      while (this._liveRenderedCount < this._liveEntries.length) {
        this._appendLiveRow(this._liveEntries[this._liveRenderedCount]);
        this._liveRenderedCount += 1;
      }
      if (this._liveState === 'complete' && this._liveLastGroupKey) {
        const last = this._liveGroupNodes.get(this._liveLastGroupKey);
        if (last) last.details.open = true;
      }
      if (follow) {
        try { pane.scrollTop = pane.scrollHeight; } catch (_) { /* best effort */ }
      }
    }

    _scheduleLiveDrain() {
      if (this._liveRenderQueued) return;
      this._liveRenderQueued = true;
      const flush = () => {
        this._liveRenderQueued = false;
        this._drainLiveRows();
      };
      if (typeof root.requestAnimationFrame === 'function') root.requestAnimationFrame(flush);
      else enqueueMicrotask(flush);
    }

    async load(expectedGeneration) {
      if (!this.hasAttribute('open')) return null;
      const generation = expectedGeneration === undefined ? ++this._generation : expectedGeneration;
      try {
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
        this._trace = null;
        this._traceInputKey = null;
        this._resetLiveLog('running');
        this._hideStatus();
        if (this._els && this._els.liveCurrent) this._els.liveCurrent.textContent = this._t('cooking.loading');
        const trace = await service.getCookingTrace(targetJdn, calculationJdn, {
          onProgress: (event) => {
            if (generation !== this._generation || !this._connected || !this.hasAttribute('open')) return;
            this.appendLiveProgress(event);
          },
        });
        if (generation !== this._generation || !this._connected || !this.hasAttribute('open')) return null;
        this._trace = trace;
        this._traceInputKey = inputKey;
        this._liveState = 'complete';
        this._drainLiveRows();
        this._gateDetails.clear();
        this._gateDetailLoading = null;
        this._gateDetailError = null;
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
        this._liveState = 'error';
        if (this._liveEntries.length) {
          this._hideStatus();
          this._renderState();
        } else {
          this._showError(error);
        }
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
      if (this._liveEntries.length) {
        this._prepareLiveLog(true);
        this._drainLiveRows();
        return;
      }
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
      if (this._els.liveKicker) this._els.liveKicker.textContent = this._t('cooking.live.kicker');
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
        if (!row || ((row.value === undefined || row.value === null) && !row.node)) continue;
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
      pane.scrollTop = 0;
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
      const coverage = this._trace.coverage;
      if (coverage) {
        const card = doc.createElement('section');
        card.className = 'step-card';
        this._heading(card, 'coverage', 4);
        const scalar = Object.entries(coverage).filter(([, value]) => value === null || typeof value !== 'object');
        this._kv(card, scalar.map(([key, value]) => ({ label: key, value })));
        for (const [key, value] of Object.entries(coverage)) {
          if (Array.isArray(value)) this._kv(card, [{ label: key, node: this._arrayValue(value), value: key }]);
        }
        pane.append(card);
      }
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

    _selectionEvent(sourceLabel, gateIndex = null) {
      const selections = safeArray(this._trace && this._trace.artifacts && this._trace.artifacts.selections);
      return selections.find((row) => row
        && row.sourceLabel === sourceLabel
        && (gateIndex === null || String(row.gateIndex) === String(gateIndex))) || null;
    }

    _exactish(value) {
      return typeof value === 'bigint' || /^-?\d+$/.test(String(value));
    }

    _renderMiniObject(container, title, value) {
      if (!value || typeof value !== 'object' || Array.isArray(value)) return;
      const mini = doc.createElement('section');
      mini.className = 'mini';
      const strong = doc.createElement('strong');
      strong.textContent = title;
      mini.append(strong);
      this._kv(mini, Object.entries(value).map(([key, item]) => ({
        label: key,
        value: item,
        exact: this._exactish(item),
      })));
      container.append(mini);
    }

    _renderSelectionCard(container, title, stream = null, summary = null, event = null) {
      if (!stream && !summary && !event) return;
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, this._term('selection') + ' · ' + String(title), 4);

      const actualStream = stream || (event && event.stream) || null;
      if (actualStream) {
        this._heading(card, this._term('stream'), 4);
        this._kv(card, [
          { label: 'first', value: actualStream.first, exact: true },
          { label: 'directionStep', value: actualStream.directionStep, exact: true },
        ]);
      }

      if (summary && typeof summary === 'object') {
        this._kv(card, Object.entries(summary).map(([key, value]) => ({
          label: key,
          value,
          exact: this._exactish(value),
        })));
      }

      if (event) {
        const rows = [
          ['sourceLabel', event.sourceLabel, false],
          ['mode', event.mode, false],
          ['familySize', event.familySize, true],
          ['places', event.places, true],
          ['space', event.space, true],
          ['acceptanceLimit', event.acceptanceLimit, true],
          ['firstCandidate', event.firstCandidate, true],
          ['initialWide', event.initialWide, true],
          ['rejectionSteps', event.rejectionSteps, true],
          ['acceptedCandidate', event.acceptedCandidate, true],
          ['output', event.output, true],
        ].map(([label, value, exact]) => ({ label, value, exact }));
        this._kv(card, rows);
        if (safeArray(event.digits).length) {
          this._kv(card, [{ label: 'digits', node: this._arrayValue(event.digits, true), value: 'digits' }]);
        }
        if (event.rejectionEncoding) {
          const grid = doc.createElement('div');
          grid.className = 'mini-grid';
          this._renderMiniObject(grid, 'rejectionEncoding', event.rejectionEncoding);
          card.append(grid);
        }
      }
      container.append(card);
    }

    _renderGates(pane) {
      const network = this._trace.artifacts && this._trace.artifacts.gateNetwork;
      const gates = safeArray(network && network.gates);
      const gaps = safeArray(network && network.gaps);
      if (!gates.length && !gaps.length) return this._empty(pane);

      if (gates.length) {
        const gateKey = 'gatePoints';
        const gateIndex = this._cursor(gateKey, gates.length);
        this._stepControls(pane, gateKey, gates.length, () => this._renderChapter());
        const gate = gates[gateIndex];
        const gateCard = doc.createElement('section');
        gateCard.className = 'step-card';
        this._heading(gateCard, this._term('gate') + ' ' + String(gate.index), 4);
        this._kv(gateCard, [
          { label: 'index', value: gate.index, exact: true },
          { label: 'day', value: gate.day, exact: true },
        ]);
        pane.append(gateCard);
      }

      if (!gaps.length) return;
      const key = 'gateGaps';
      const index = this._cursor(key, gaps.length);
      this._stepControls(pane, key, gaps.length, () => this._renderChapter());
      const gap = gaps[index];
      const card = doc.createElement('section');
      card.className = 'step-card';
      this._heading(card, this._term('gateGap') + ' ' + String(gap.signedIndex), 4);
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
          { label: 'orderAtDrop46', node: this._arrayValue(gap.sauceSummary.orderAtDrop46), value: 'orderAtDrop46' },
          { label: 'finalBowls', node: this._arrayValue(gap.sauceSummary.finalBowls, true), value: 'finalBowls' },
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
        if (this._gateDetailError && this._gateDetailError.signedIndex === String(gap.signedIndex)) {
          const error = doc.createElement('p');
          error.className = 'inline-error';
          error.setAttribute('role', 'alert');
          error.textContent = this._t('cooking.error');
          card.append(error);
        }
      }
      pane.append(card);

      const selection = this._selectionEvent('gate-gap', gap.signedIndex);
      this._renderSelectionCard(pane, 'gate-gap', selection && selection.stream, null, selection);
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
      this._gateDetailError = null;
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
        this._gateDetailError = null;
        this._renderNav();
        this._renderChapter();
        return chunk;
      } catch (error) {
        if (generation === this._generation && this._connected && this.hasAttribute('open')) {
          this._gateDetailLoading = null;
          this._gateDetailError = { signedIndex: String(signedIndex) };
          this._renderChapter();
          if (root.console && typeof root.console.error === 'function') root.console.error(error);
        }
        throw error;
      }
    }

    _renderYear5000(pane) {
      const yearWalk = this._trace.artifacts && this._trace.artifacts.yearWalk;
      const year = yearWalk ? yearWalk.year5000 : null;
      if (!year) return this._empty(pane);
      if (yearWalk.interval) this._kv(pane, [{ label: 'interval', value: yearWalk.interval }]);
      this._renderYearCard(pane, year, this._t('cooking.chapter.year5000'));
      const selection = this._selectionEvent('YEAR_5000-semantic');
      this._renderSelectionCard(pane, 'YEAR_5000-semantic', selection && selection.stream, null, selection);
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
      const yearWalk = this._trace.artifacts && this._trace.artifacts.yearWalk;
      const transitions = safeArray(yearWalk && yearWalk.transitions);
      if (yearWalk && yearWalk.interval) this._kv(pane, [{ label: 'interval', value: yearWalk.interval }]);
      const authoritativeYears = safeArray(yearWalk && yearWalk.authoritativeYears);
      if (authoritativeYears.length) {
        const authKey = 'authoritativeYears';
        const authIndex = this._cursor(authKey, authoritativeYears.length);
        this._stepControls(pane, authKey, authoritativeYears.length, () => this._renderChapter());
        const authoritative = authoritativeYears[authIndex];
        const card = doc.createElement('section');
        card.className = 'step-card';
        this._heading(card, this._term('year'), 4);
        this._kv(card, [{ label: 'lineage', value: authoritative.lineage }]);
        pane.append(card);
        if (authoritative.year) this._renderYearCard(pane, authoritative.year, this._term('year'));
      }
      if (!transitions.length) {
        const finalYear = yearWalk ? yearWalk.finalYear : null;
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
        { label: 'direction', value: transition.direction },
        { label: 'sharedDay', value: transition.sharedDay, exact: true },
        { label: 'sauceRunId', value: transition.sauceRunId || '—' },
      ]);
      pane.append(card);
      this._renderYearCard(pane, transition.fromYear, this._term('fromYear'));
      this._renderYearCard(pane, transition.toYear, this._term('toYear'));
      if (yearWalk && yearWalk.finalYear && index === transitions.length - 1) {
        this._renderYearCard(pane, yearWalk.finalYear, this._term('finalYear'));
      }
      const run = findSauce(this._trace, transition.sauceRunId);
      if (run) this._renderSauceInspector(pane, run, run.id);
    }

    _renderStructureSauce(pane) {
      const structure = this._trace.artifacts && this._trace.artifacts.structure;
      const run = safeArray(this._trace.artifacts && this._trace.artifacts.sauceRuns)
        .find((item) => item.role && item.role.kind === 'year-structure');
      if (structure && structure.year) this._renderYearCard(pane, structure.year, this._term('year'));
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

    _renderInitialBowls(container, run) {
      const rows = safeArray(run && run.initialBowls);
      if (!rows.length) return;
      this._heading(container, this._term('initialBowls'), 4);
      const grid = doc.createElement('div');
      grid.className = 'mini-grid';
      for (const row of rows) {
        const mini = doc.createElement('section');
        mini.className = 'mini';
        const strong = doc.createElement('strong');
        strong.textContent = this._term('bowl') + ' ' + String(row.bowlId);
        mini.append(strong);
        this._kv(mini, [
          { label: 'prime', value: row.prime, exact: true },
          { label: 'seed', value: row.seed, exact: true },
          { label: 'rawBeforeSave', value: row.rawBeforeSave, exact: true },
          { label: 'output', value: row.output, exact: true },
        ]);
        grid.append(mini);
      }
      container.append(grid);
    }

    _renderSauceCheckpoints(container, run) {
      this._heading(container, this._term('checkpoints'), 4);
      this._kv(container, [
        { label: 'orderAtDrop46', node: this._arrayValue(run.orderAtDrop46), value: 'orderAtDrop46' },
        { label: 'bowlsAfterDrops', node: this._arrayValue(run.bowlsAfterDrops, true), value: 'bowlsAfterDrops' },
        { label: 'finalBowls', node: this._arrayValue(run.finalBowls, true), value: 'finalBowls' },
      ]);
    }

    _renderSauceInspector(container, run, scope) {
      const sauce = doc.createElement('section');
      sauce.className = 'sauce';
      const role = run.role && run.role.kind ? String(run.role.kind) : 'Sauce';
      this._heading(sauce, this._term('sauce') + ' · ' + role, 4);
      if (run.inputs) {
        this._kv(sauce, [
          { label: 'calculationDay', value: run.inputs.calculationDay, exact: true },
          { label: 'targetDay', value: run.inputs.targetDay, exact: true },
          { label: 'stoneTableRef', value: run.stoneTableRef },
        ]);
      }
      this._renderCounters(sauce, run.counters);
      this._renderInitialBowls(sauce, run);
      this._renderSauceCheckpoints(sauce, run);

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
          ['rawBeforeSave', row.transition.rawBeforeSave],
          ['after', row.transition.after],
        ]) this._renderMiniObject(grid, label, values);
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
      const grid = doc.createElement('div');
      grid.className = 'mini-grid';
      this._renderMiniObject(grid, 'coefficients', row.coefficients);
      this._renderMiniObject(grid, 'stoneRow', row.stoneRow);
      if (grid.children.length) container.append(grid);
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
      const grid = doc.createElement('div');
      grid.className = 'mini-grid';
      this._renderMiniObject(grid, 'stoneRow', row.stoneRow);
      if (grid.children.length) container.append(grid);
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
          { label: 'stoneKind', value: grind.stoneKind },
          { label: 'stoneValue', value: grind.stoneValue, exact: true },
          { label: 'after', value: grind.after, exact: true },
        ]);
        if (grind.rule) {
          const grid = doc.createElement('div');
          grid.className = 'mini-grid';
          this._renderMiniObject(grid, 'rule', grind.rule);
          li.append(grid);
        }
        list.append(li);
      }
      container.append(list);
    }

    _renderBowlRound(container, row) {
      this._heading(container, this._term('bowlRound') + ' ' + String(row.ordinal), 4);
      this._kv(container, [
        { label: 'drop', value: row.drop, exact: true },
        { label: 'order', node: this._arrayValue(row.order), value: 'order' },
        { label: 'poursByPosition', node: this._arrayValue(row.poursByPosition, true), value: 'poursByPosition' },
        { label: 'beforeBowls', node: this._arrayValue(row.beforeBowls, true), value: 'beforeBowls' },
        { label: 'afterBowls', node: this._arrayValue(row.afterBowls, true), value: 'afterBowls' },
      ]);
      const stoneGrid = doc.createElement('div');
      stoneGrid.className = 'mini-grid';
      this._renderMiniObject(stoneGrid, 'stoneRow', row.stoneRow);
      if (stoneGrid.children.length) container.append(stoneGrid);
      const list = doc.createElement('ol');
      list.className = 'sequence';
      for (const position of safeArray(row.positions)) {
        const li = doc.createElement('li');
        const strong = doc.createElement('strong');
        strong.textContent = this._term('position') + ' ' + String(position.position) + ' · ' + this._term('bowl') + ' ' + String(position.bowlId);
        li.append(strong);
        this._kv(li, [
          { label: 'prevId', value: position.prevId },
          { label: 'nextId', value: position.nextId },
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
        { label: 'order', node: this._arrayValue(row.order), value: 'order' },
        { label: 'beforeBowls', node: this._arrayValue(row.beforeBowls, true), value: 'beforeBowls' },
        { label: 'afterBowls', node: this._arrayValue(row.afterBowls, true), value: 'afterBowls' },
      ]);
      const list = doc.createElement('ol');
      list.className = 'sequence';
      for (const position of safeArray(row.positions)) {
        const li = doc.createElement('li');
        const strong = doc.createElement('strong');
        strong.textContent = this._term('position') + ' ' + String(position.position) + ' · ' + this._term('bowl') + ' ' + String(position.bowlId);
        li.append(strong);
        this._kv(li, [
          { label: 'prevId', value: position.prevId },
          { label: 'nextId', value: position.nextId },
          { label: 'oldBowl', value: position.oldBowl, exact: true },
          { label: 'oldPrev', value: position.oldPrev, exact: true },
          { label: 'oldNext', value: position.oldNext, exact: true },
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
        { label: 'partition', node: this._arrayValue(cutlets.partition), value: 'partition' },
        { label: 'nameCanonicalIndices', node: this._arrayValue(cutlets.nameCanonicalIndices), value: 'nameCanonicalIndices' },
      ]);
      this._renderSelectionCard(pane, 'cutlet-count', cutlets.countStream, null, this._selectionEvent('cutlet-count'));
      this._renderSelectionCard(pane, 'cutlet-partition-semantic', cutlets.partitionStream, cutlets.partitionSelection, this._selectionEvent('cutlet-partition-semantic'));
      this._renderSelectionCard(pane, 'cutlet-names-distinct-rank', cutlets.nameStream, cutlets.nameSelection, this._selectionEvent('cutlet-names-distinct-rank'));

      const items = safeArray(cutlets.items);
      if (!items.length) return;
      const key = 'cutlets';
      const index = this._cursor(key, items.length);
      this._stepControls(pane, key, items.length, () => this._renderChapter());
      const item = items[index];
      const card = doc.createElement('section');
      card.className = 'step-card';
      const name = item.sourceName ? i18n.calendarName(this._locale, 'cutlet', item.sourceName) : null;
      this._heading(card, this._term('cutlet') + ' ' + String(index + 1) + (name ? ' · ' + name : ''), 4);
      this._kv(card, [
        { label: 'sourceName', value: item.sourceName },
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
        { label: 'nameCanonicalIndices', node: this._arrayValue(months.nameCanonicalIndices), value: 'nameCanonicalIndices' },
      ]);
      this._renderSelectionCard(pane, 'month-count', months.countStream, null, this._selectionEvent('month-count'));
      this._renderSelectionCard(pane, 'month-lengths', months.lengthStream, months.lengthSelection, this._selectionEvent('month-lengths'));
      this._renderSelectionCard(pane, 'month-weaving', months.weavingStream, months.weavingSelection, this._selectionEvent('month-weaving'));
      this._renderSelectionCard(pane, 'month-names-distinct-rank', months.nameStream, months.nameSelection, this._selectionEvent('month-names-distinct-rank'));

      const items = safeArray(months.items);
      const count = items.length || safeArray(months.lengths).length;
      if (count) {
        const key = 'months';
        const index = this._cursor(key, count);
        this._stepControls(pane, key, count, () => this._renderChapter());
        const item = items[index] || {
          slot: index + 1,
          length: months.lengths[index],
          nameCanonicalIndex: months.nameCanonicalIndices[index],
        };
        const card = doc.createElement('section');
        card.className = 'step-card';
        const name = item.sourceName ? i18n.calendarName(this._locale, 'month', item.sourceName) : null;
        this._heading(card, this._term('monthSlot') + ' ' + String(item.slot || index + 1) + (name ? ' · ' + name : ''), 4);
        this._kv(card, [
          { label: 'sourceName', value: item.sourceName },
          { label: 'length', value: item.length },
          { label: 'nameCanonicalIndex', value: item.nameCanonicalIndex },
        ]);
        pane.append(card);
      }

      const weaving = safeArray(months.weaving);
      if (weaving.length) {
        const weavingKey = 'monthWeaving';
        const weavingIndex = this._cursor(weavingKey, weaving.length);
        this._stepControls(pane, weavingKey, weaving.length, () => this._renderChapter());
        const card = doc.createElement('section');
        card.className = 'step-card';
        this._heading(card, this._term('weaving') + ' · ' + String(weavingIndex + 1), 4);
        this._kv(card, [
          { label: 'positionInYear', value: weavingIndex + 1 },
          { label: 'monthId', value: weaving[weavingIndex] },
        ]);
        pane.append(card);
      }
    }

    _renderPosition(pane) {
      const position = this._trace.artifacts && this._trace.artifacts.positioning;
      if (!position) return this._empty(pane);
      if (position.year) this._renderYearCard(pane, position.year, this._term('finalYear'));
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

    _renderArchaeology(container) {
      const rows = safeArray(this._trace && this._trace.archaeology);
      if (!rows.length) return;
      const section = doc.createElement('section');
      section.className = 'step-card';
      this._heading(section, this._term('archaeology'), 4);
      const note = doc.createElement('p');
      note.className = 'archaeology-note';
      note.textContent = this._t('cooking.archaeology.note');
      section.append(note);
      for (const row of rows) {
        const item = doc.createElement('section');
        item.className = 'mini';
        const strong = doc.createElement('strong');
        strong.textContent = String(row.kind || 'historical-scar');
        item.append(strong);
        const scalarEntries = Object.entries(row).filter(([key, value]) => key !== 'kind'
          && value !== null && value !== undefined && (typeof value !== 'object'));
        this._kv(item, scalarEntries.map(([key, value]) => ({
          label: key,
          value,
          exact: this._exactish(value),
        })));
        if (row.semanticYear) this._renderYearCard(item, row.semanticYear, 'semanticYear');
        if (row.ghostYear) this._renderYearCard(item, row.ghostYear, 'ghostYear');
        section.append(item);
      }
      container.append(section);
    }

    _renderResult(pane) {
      const result = this._trace.finalResult;
      if (!result) return this._empty(pane);
      const cutletName = i18n.calendarName(this._locale, 'cutlet', result.cutlet.sourceName);
      const monthName = i18n.calendarName(this._locale, 'month', result.month.sourceName);
      const grid = doc.createElement('div');
      grid.className = 'result-five';
      const values = [
        [this._t('cooking.result.year'), result.year],
        [this._t('cooking.result.cutlet'), cutletName],
        [this._t('cooking.result.dayInCutlet'), result.dayInCutlet],
        [this._t('cooking.result.month'), monthName],
        [this._t('cooking.result.dayInMonth'), result.dayInMonth],
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
      this._renderArchaeology(pane);
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
