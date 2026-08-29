# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 9 de 55: PATCH 04**. Li scars de Patch 01, Patch 02 e Patch 03 resta intact e testabil. `mutateStonesWrong(index, state)` anc resta intact quam li mutation sequential in-place decovrit in Stage 8.

Li correction historic nov es `stonePatch(index, state)`: it prende un snapshot `old`, voca realmen `mutateStonesWrong` sur un clone e conserva ti call legacy, ma poy superscri omni quin outputs con formules quel lege exclusivmen `old`. `getStoneTableThroughLegacyBuilder()` usa ti route por construir li 46 stones. Un `Patch04StoneWrapper` es insertet pos `Discovery04StoneMutationHandler`, e li context conserva li garbage legacy ante overwrite e li resultate reparat separatmen. Li repository es **GREEN**.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null defect de stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions precedent, includente li scar de Discovery 04, deve restar verd:

```text
npm run test:previous
```

Li commande principal deve esser verd in Patch 04:

```text
npm test
```

Por executar solmen li patch nov:

```text
npm run test:patch-04
```

Por li prim transition, li legacy continua rendre `[378,1434,3780,9932,25047]`, ma `stonePatch` rende `[378,1073,2375,6195,10493]`. Li builder reparat concorda row-per-row con omni 46 stones del reference local test-only.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
