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

Per default li service usa `BoundedCalendarMemory`: un local, process-only e bounded
LRU semantic memory (2048 exact conversiones + 8 cutlet-views). Null rete, storage o
persistent state es introductet. Li claves include sempre `calculationDay`, ergo semantic
state ne es compartit inter diferent calculationes.

Un memorisat cutlet-view es range-aware: un altri target intra li sam cutlet reutilisa li
immutable day-array e retargeta solmen `selectedDay`/`selectedIndex`. `convert()` posse
anc prender li exact die directmen ex ti cutlet-view, evitante un nov Worker call.
Identic concurrent conversion/cutlet demandes es coalescet a un sol in-flight operation.

`retry()` incrementa un memory-generation ante clear/restart, pro que un old asynchronous
completion ne posse repopular li cache pos un retry. `clearCalculation()` resta isolat al
selectet calculation day. Custom memory implementations posse esser installat per
`installSharedCalendarMemory(memory)`; `NullCalendarMemory` resta disponibil internmen
quam li null implementation del sam contract.

Li Web Component tene separatmen max. quin cutlet-views por scroll/DOM ergonomie.
Ti UI-cache ne es li semantic/performance memory.

## Lingues — initial scope

Ti actual browser-strate suporte exactmen du UI-lingues, complet e includet localmen:

- `ie` — Interlingue (default)
- `en` — English

Null rete, vendoring, fallback inter lingues o external i18n package es besonat.
Omni message usat de ti component existe in ambi locales; un mancant message es un
errore, ne un silenciosi fallback.

Li visibil cutlet- e mensu-nómines es traductet al selectet UI-lingue. Li translation
maps usa li exact semantic source-text retornat del actual Interlingue black-box core
quam claves; ili ne usa positional indices e ne zip li old calendar-tables. Un mancant
calendar-nómine es un explicit error.

`value`, `ready` e `pastafari-change` resta li raw semantic result del core, independent
del lingue de presentation. Ergo un change de `lang` ne muta li calculat date-object;
it muta solmen su visibil e ARIA presentation.

Additional lingues posse esser adjuntet in `browser/i18n/locales.js` solmen quande ili
have complet UI-message coverage e complet current cutlet/month coverage, sin changear
li core, `CalendarService` o public date-result contract.

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
