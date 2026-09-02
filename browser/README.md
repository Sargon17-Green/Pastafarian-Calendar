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

## Lingues

Li actual browser-strate suporte deci complet UI-lingues, includet localmen:

- `ie` — Interlingue (default, LTR)
- `en` — English (LTR)
- `he` — עברית (RTL)
- `ar` — العربية (RTL)
- `ru` — Русский (LTR)
- `fr` — Français (LTR)
- `de` — Deutsch (LTR)
- `es` — Español (LTR)
- `it` — Italiano (LTR)
- `cs` — Čeština (LTR)

Null rete, vendoring, fallback inter lingues o external i18n package es besonat.
Omni message usat de ti component existe in omni activ locale; un mancant message es un
errore, ne un silenciosi fallback.

Li visibil e ARIA cutlet- e mensu-nómines es traductet al selectet UI-lingue. Li
translation maps usa li exact semantic source-text retornat del actual Interlingue
black-box core quam claves; ili ne usa positional indices e ne zip li old
calendar-tables. Omni activ locale have complet coverage de 17 cutlets e 47 mensus.
Un mancant calendar-nómine es un explicit error.

`value`, `ready` e `pastafari-change` resta li raw semantic result del core, independent
del lingue de presentation. Ergo un change de `lang` ne muta li calculat date-object;
it muta solmen su visibil e ARIA presentation.

Additional lingues posse esser adjuntet in `browser/i18n/locales.js` solmen quande ili
have complet UI-message coverage e complet current cutlet/month coverage, sin changear
li core, `CalendarService` o public date-result contract.

## Public presentation e lifecycle

Li visible shell resta inspirat del original public site: editorial `PASTAFARI` masthead,
paper/panel palette, prominent date-search panel, target beacon, explicit cutlet toolbar
e grand tri-line day cards. Li actual cards usa li original public-site structure: tri
boxed lines, semantic month-colores e un fort target badge/outline. Li day cards es
display units, ne implicit buttons. Month-runs resta semantic gruppes in li DOM ma ne
frange li visible cutlet in separat panels. Li desktop seven-column layout es visual
arrangement, ne un week-semantic; narrow screens reflow responsivmen.

Mensu-colores es derivat deterministicmen del exact semantic source-name, ne del lingue
o del position del month in un actual cutlet. Ergo un mensu conserva su visual identitá
quande li locale cambia o quande un altri cutlet es apert.

Li component usa generation e connection-epoch guards. Rapid attribute changes,
disconnect/reconnect e old asynchronous completions ne posse publicar stale `value` o
`pastafari-change`. `headless` executa solmen li data conversion. Si `headless` o
`no-editor` es activat durante que li editor-dialog es apert, li dialog es cludet.
`Retro al hodie` reinicialisa tant `date` quam `calculation-date`.

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
