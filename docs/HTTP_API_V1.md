# API HTTP v1 — Celeritas per Sepulcra

Haec cicatrix API supra monstrum historicum additur. `calendarDateSpaghetti(c,t)` non substituitur, non mundatur, non reficitur: conversiones externae ad axem dierum fiunt, deinde eadem functio Celeritas vocatur.

## Regula diei computationis

Si cliens `calculation` non dat, momentum petitionis semel capitur postquam tota petitio HTTP recepta est et ante conversionem calendarii. Dies computationis est dies Pastafarianus illius momenti apud Kisurra, non dies civilis loci ubi minister currit.

Terminus diei est transitus meridianus inferior centri Veneris. Intervalla sunt semiaperta: `[V_n, V_(n+1))`; in ipso `V_(n+1)` dies novus iam incipit.

Observator normativus:

- locus: Kisurra / Ishān Abū Ḥaṭab;
- latitudo: 31.8383° N;
- longitudo: 45.4810° E;
- modelum: `venus-lower-transit-jpl-approx-1`.

Modelum sequitur cicatricem iam definitam in repositorio referentiali: elementa JPL Table 2a, correctionem temporis lucis, precessionem IAU-1976, parallaxim topocentricam et bisectionem transitus. Extra spatium temporis modelis (circiter annos -3000..3000) nulla media nox substituitur: petitio implicita deficit (`503`).

## Axis canonicus

Conversiones calendarii primum JDN integrum gignunt. Axis Celeritas est:

```text
engineDay = JDN - 1721425
JDN       = engineDay + 1721425
```

Testimonia:

```text
Gregorian 0001-01-01 -> JDN 1721426 -> engineDay 1
Gregorian -0762-06-07 -> JDN 1442903 -> engineDay -278522
Foundation JDN -13334246 -> engineDay -15055671
```

Omnes integri arbitrarii in JSON sunt **catenae decimales canonicae** (`^-?(0|[1-9][0-9]*)$`), numquam numeri JSON.

## Viae HTTP

### `GET /v1/date`

Usus minimus:

```http
GET /v1/date?date=2026-09-02
```

Valores impliciti:

```text
calendar = gregorian (proleptic)
format = auto
language = la
calculation = momentum petitionis / Kisurra / Venus lower transit
```

Exempla explicita:

```http
GET /v1/date?date=31%2F08%2F2026
GET /v1/date?date=03%2F04%2F2026&format=dmy
GET /v1/date?date=1917-10-25&calendar=julian
GET /v1/date?date=2026-09-02&language=la
GET /v1/date?date=2026-09-02&calculation_day=42
GET /v1/date?date=2026-09-02&calculation_instant=2026-09-02T12%3A00%3A00Z
```

`calculation_day` et `calculation_instant` simul vetantur.

### `POST /v1/date`

Forma minima:

```json
{"target":"2026-09-02"}
```

Forma structurata cum lingua nominum:

```json
{
  "target": {
    "calendar": "gregorian",
    "format": "dmy",
    "value": "02/09/2026"
  },
  "language": "la"
}
```

Emendatio diei computationis:

```json
{
  "target": "2026-09-02",
  "calculation": {
    "mode": "instant",
    "value": "2026-09-02T12:00:00Z"
  }
}
```

vel, sine astronomia:

```json
{
  "target": "2026-09-02",
  "calculation": {
    "mode": "engine-day",
    "value": "42"
  }
}
```

### `POST /v1/dates`

Maximum v1: 1024 `targets`. Momentum petitionis **semel** capitur et unus idemque dies computationis omnibus elementis adhibetur. `language` est campus communis toti batch, sicut `calculation`.

```json
{
  "targets": [
    "2026-09-02",
    {"calendar":"julian","value":"2026-08-20"},
    {"calendar":"hebrew","value":"5787-07-01"}
  ],
  "language":"la"
}
```

### `GET /v1/health`

Processus HTTP vivit. Haec via calculum calendarii non cogit.

### `GET /v1/meta`

Versionem API, machinam, semantic stage, calendaria conversionis, linguas nominum, modelum Veneris et batch limit reddit. Inter alia nunc continet:

```json
{
  "defaultLanguage":"la",
  "languages":["la"]
}
```

## Conversiones in hac cicatrice

Implementatae nunc:

- `engine-day`;
- `gregorian` (proleptic);
- `julian` (proleptic);
- `hebrew` (arithmetica deterministica);
- `islamic-civil` (arithmetica deterministica).

Nomen ambiguum `islamic` consulto repudiatur cum `CALENDAR_VARIANT_REQUIRED`; API non eligit silentio inter civil/tabular, Umm al-Qura aut observationem lunarem.

Gregorian `auto` nunc agnoscit:

- YMD cum `-`, `/`, `.`;
- DMY et MDY cum validatione;
- ISO week date (`2026-W36-3`);
- ordinal date (`2026-245`);
- nomina mensium Anglica (`2 September 2026`, `September 2, 2026`).

Anni duarum notarum non coniciuntur.

## Lex ambiguitatis

Parser automaticus omnes interpretationes legitimas considerat. Si omnes ad eundem `engineDay` perveniunt, datum accipitur. Si ad plus quam unum diem perveniunt, `AMBIGUOUS_DATE` redditur.

```text
31/08/2026 -> accipitur (MDY invalidum)
08/31/2026 -> accipitur (DMY invalidum)
03/04/2026 -> AMBIGUOUS_DATE
```

Nulla praelatio US/EU adhibetur.

## Lingua nominum

`language` est campus optionalis presentationis. Semantica calendarii, `engineDay`, indices canonici et cache machinae eo non mutantur.

Nunc:

```text
implicitum = la
sustentatae = la
```

Si campus deest, `la` adhibetur. `language=la` nomina canonica Latina quae machina iam reddit servat. Lingua nondum addita, exempli gratia `he`, non ad Latinam tacite recidit: `422 LANGUAGE_NOT_SUPPORTED` redditur.

Stratum `name_language` consulto post computationem machinae positum est. Linguae futurae nomina ex `cutlet.index` et `month.index` eligent; ideo translationes futuras addere licebit sine mutatione `calendarDateSpaghetti`, sine mutatione indicum canonicorum et sine pollutione `Pair Tomb`.

## Responsum

Numeri calendarii magnitudinis arbitrariae sunt catenae. Indices catalogi, quia parvi et finiti, numeri JSON manent.

```json
{
  "apiVersion": "1",
  "engine": {"id":"celeritas-per-sepulcra","semanticStage":56},
  "resolvedInput": {
    "calculation": {
      "source":"request-instant",
      "instant":"2026-09-02T12:00:00.000Z",
      "site":"kisurra",
      "dayBoundary":"venus-lower-culmination",
      "modelVersion":"venus-lower-transit-jpl-approx-1",
      "jdn":"...",
      "engineDay":"..."
    },
    "target": {
      "source":"2026-09-02",
      "calendar":"gregorian",
      "detectedFormat":"ymd",
      "normalized":"2026-09-02",
      "jdn":"2461286",
      "engineDay":"739861"
    }
  },
  "date": {
    "year":"...",
    "cutlet":{"index":7,"name":"..."},
    "dayInCutlet":"...",
    "month":{"index":28,"name":"..."},
    "dayInMonth":"...",
    "language":"la"
  }
}
```

Nomina/indices supra schematici sunt; exemplum non est testimonium calendarii Pastafariani.

## Involucrum erroris

```json
{"error":{"code":"AMBIGUOUS_DATE","message":"..."}}
```

Distributio principalis:

- 400 — JSON/query/type male formatum;
- 405 — methodus non admissa;
- 413 — corpus/batch nimis magnum;
- 415 — `Content-Type` non JSON;
- 422 — datum semanticum ambiguum, invalidum, calendarium/forma non sustentata, aut lingua nominum nondum sustentata;
- 500 — defectus internus;
- 503 — astronomia implicita praestari non potest.

Codices, exempli gratia `AMBIGUOUS_DATE` et `LANGUAGE_NOT_SUPPORTED`, sunt identificatores machinales stabiles; `message` humanum Latine redditur.

## Memoria intermedia et determinismus

Cum dies computationis implicitus est, v1 mittit `Cache-Control: no-store`, quia eadem URL post proximum transitum Veneris aliam semanticam habere potest.

Status cache internus, via sepulcralis et tempora executionis non intrant corpus semanticum. Headers semper includunt:

```text
X-Pastafari-Engine: celeritas-per-sepulcra
X-Pastafari-Semantics: stage56
```

## Ars monstri servata

API est stratum additivum. `CeleritasEnginePort` directe `calendarDateSpaghetti(c,t)` vocat. Indices catalogi post resultatum ex nominibus catalogi congelati resolvuntur. Nulla structura historica mutatur.

Optimizationes sequentes (`L0 Pair Tomb`, ossuarium diei computationis, arithmetica funebris fixed-width) cicatrices ante viam veterem esse debent; missus, defectus aut forcing diagnosticum semper viam historicam attingere potest.
