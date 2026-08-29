# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 8 de 55: DISCOVERY 04**. Li scars de Patch 01, Patch 02 e Patch 03 resta intact e testabil. Li nov defect historic es `mutateStonesWrong(index, state)`: it muta li quin stones sequentialmen in-place e li passus posterior usa immediatmen valores ja mutat.

Li path real passa per `LegacyStoneMutationAdapter` e `Discovery04StoneMutationHandler`. Li handler conserva li valores de intrada por diagnostics, crea un statu de labor proprietari al invocation e passa ti object al legacy. Li legacy rende li sam object quel it mutat. Null `stonePatch`, null snapshot normativ e null code de Patch 04 es present. Li repository es intentionalmen **EXPECTED_RED** solmen por li nov regression de Discovery 04.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null defect de stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions precedent, includente Patch 03, deve restar verd:

```text
npm run test:previous
```

Li commande principal es intentionalmen rubi in Discovery 04:

```text
npm test
```

Por executar solmen li regression nov:

```text
npm run test:discovery-04
```

Por li prim transition de stones, li legacy rende `[378,1434,3780,9932,25047]`, durante que li transition simultan normativ rende `[378,1073,2375,6195,10493]`. Li prim stone coincide pro que it es calculat ante quelcunc contamination; li altri quar demonstra li dependentie sequential intra li sam passu.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
