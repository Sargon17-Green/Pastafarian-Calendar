# Interfacie web del calendarium pastafarian

Ti directorium adjunte al branche `JavaScript+Interlingue` li contract extern del interfacie web del anterior projecte, sin copiar su mecanisme de verification inter du motores.

## Contract extern

Li custom element es `<pastafari-date>`. It conserva li attributes `date`, `calculation-date`, `no-editor`, `headless`; li proprietá `value`; li Promise `ready`; li metode `refresh()`; e li event `pastafari-change` (`bubbles: true`, `composed: true`).

`getPastafariDateAsync(targetDate, calculationDate)` e su compatibil alias `getPastafariDate(...)` retorna un Promise con un object gelat:

```js
{
  year: "5000",
  cutletName: "...",
  dayInCutlet: 306,
  monthName: "...",
  dayInMonth: 23
}
```

Li inputs posse esser ISO-strings, `Date`, `{ year, month, day }`, o `null`/vacui por li hodial local date. Negativ annus e annus con plu quam quar cifres es supportat.

## Architectura e limite de cassa nigri

Li component parla solmen con `CalendarService`. `CalendarService` parla con `PastafariEngineClient`, quel usa un Worker. Li Worker importa li existent core e invoca solmen:

```js
calendarDateSpaghetti(calculationDay, targetDay)
```

Li cod del navigator ne lege `context`, `structure`, managers, internales de Stage 58 o altri semantic structures. Un complet cutlet es derivat quam cassa nigri: li selectet resultat da `dayInCutlet`, li die inicial es calculat, e li Worker avansa die-pos-die til `dayInCutlet` recomensa a 1. Un dur limite de 6000 dies impedi un scan sin termination.

## Punctu preparat por futur memorisation

`CalendarService` accepta un object `memory` con ti contract:

```js
getConversion(calculationDay, targetDay)
setConversion(calculationDay, targetDay, value)
getCutletView(calculationDay, targetDay)
setCutletView(calculationDay, targetDay, value)
clearCalculation(calculationDay)
clear()
```

Un manca es representat per `undefined`. Li predefinit `NullCalendarMemory` conserva necos. Ergo li extern component e su DOM-cache de quin cutlets ne deve esser changeat por adjunter futur memorisation semantic o de performance.

## Compilation

Installar li dependenties e executer:

```text
npm run build:browser
```

Li compilation crea `dist/browser/pastafari-date.js`, `dist/browser/pastafari-worker.js`, e li autonom classic-script variantes sub `dist/browser/standalone/`.

Usation normal per HTTP/HTTPS:

```html
<script type="module" src="./pastafari-date.js"></script>
<pastafari-date></pastafari-date>
```

Usation autonom, includente `file://`:

```html
<pastafari-date></pastafari-date>
<script src="./pastafari-date.js"></script>
```

Li autonom variante usa un classic Blob Worker e ne have fallback al principal thread. Su asincron API es anc disponibil quam `PastafariCalendarStandalone.getPastafariDateAsync(...)`.

## Important separation

Li cache intern del component es solmen un limitat cache de presentation e scroll (maxim quin cutlets). It ne es li futur semantic memorisation. Tal memorisation deve esser injectet sub `CalendarService`, preferibilmen sin changear li public contract del navigator.
