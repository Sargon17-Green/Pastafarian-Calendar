# Interfacie de navigator

Ti directorie adjunte li extern browser-interfacie del anterior projecte al branche
JavaScript + Interlingue, sin copiar li old du-engine verification router.

## Extern contract

Li custom element es:

```html
<pastafari-date></pastafari-date>
```

Con li original attributes:

- `date`
- `calculation-date`
- `no-editor`
- `headless`

E li additive lingue-attribute:

- `lang`

Li public element contract conserva:

- `value`
- `ready`
- `refresh()`
- `pastafari-change`

Li classic bundle expone `globalThis.PastafariCalendarBrowser`.
Li Standalone bundle expone anc li compatibility alias
`globalThis.PastafariCalendarStandalone`.

Li Standard ESM facade es `browser/dist/pastafari-date.mjs`.

## Semantic limite

Li browser-strate ne lege context, structure, Stage scars o intern managers.
Li Worker usa solmen:

```text
calendarDateSpaghetti(calculationDay, targetDay)
```

Li cutlet-view es derivat per black-box scanning: li selectet `dayInCutlet`
determina li cutlet-comense, e li Worker continua die per die til li sequent
`dayInCutlet == 1`. Li dur securitá-limite es 6000 dies.

## Memorisation

`CalendarService` es li sol punctu usat del Web Component por semantic demandes.
`CalendarMemory` es un explicit contract sub ti service.

Per default li implementation es `NullCalendarMemory`: null nov semantic cache es
introducet per ti initial browser-version. Un futur memorisation implementation posse
esser installat per `installSharedCalendarMemory(memory)` sin mutation del Web
Component.

Li Web Component tene separatmen max. quin cutlet-views por scroll/DOM ergonomie.
Ti UI-cache ne es li semantic/performance memory.

## Lingues — initial scope

Ti prim correct upload suporte exactmen du UI-lingues, complet e includet localmen:

- `ie` — Interlingue (default)
- `en` — English

Null rete, vendoring, fallback inter lingues o external i18n package es besonat.
Omni message usat de ti component existe in ambi locales; un mancant message es un
errore, ne un silenciosi fallback.

Li cutlet- e mensu-nómines ne es traductet per ti strate. Lor semantic identificatores
in li old projecte ne es identic al congelat catalog de ti branche. Li presentation
usa exactmen li Interlingue nómines retornat del nov black-box core. `value`, `ready`
e `pastafari-change` resta ergo semanticmen identic quande `lang` change.

Additional lingues posse esser adjuntet plu tard in `browser/i18n/locales.js` sin
changear li core, `CalendarService` o public date-result contract.

## Construction

```text
node scripts/build-browser.js
```

Null npm dependentie es besonat.

## Provas

```text
node tests/verify-stage-01.js
node tests/browser-interface-all.js
node scripts/build-browser.js
node tests/browser-built-artifacts.js
```

Li historic branch-test resta autoritativ por li original Stage 01–58 state.
