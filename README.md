# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 5 de 55: PATCH 02**. Li defect `oldDayTag(day)` de Discovery 02 resta intact e directmen testabil: it rende `0` al Foundation e valores par pos it. Li nov `dayTagWithFoundationScar(day)` circumit ti defect sin modificar li legacy: it adjunte un unit por dies al o pos li Foundation e conserva un guard redundant separat por li Foundation quam scar historic.

Li path real passa per `LegacyDayTagAdapter`, `Discovery02DayTagHandler` e `Patch02DayTagWrapper`. Li context conserva input, output legacy, decisiones local del patch, output reparat, handlers, trace e metrics non-semantic. Li regression de Discovery 02 es nu verd, e li repository es **GREEN**.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null defect de Patch 03 o stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ usa `BigInt`. Null floating-point es usat por SAVE, rangs, counts, gates, annus, compositiones o intertexes. `M = 2^127 - 1` es representat exactmen. Counts combinatori posse crescer ultra `M` sin truncation.

## Tests

Li commande principal deve esser verd in ti patch:

```text
npm test
```

Por executar li regression historic de Discovery 02, nu reparat per Patch 02:

```text
npm run test:discovery-02
```

Por executar solmen li prova supplementari de Patch 02:

```text
npm run test:patch-02
```

Li tests confirma simultanmen que `oldDayTag` resta defectiv, que `dayTagWithFoundationScar` es equivalent a `dayCount` sur un gril larg circum li Foundation, e que li guard redundant del Foundation resta fisicmen present.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
