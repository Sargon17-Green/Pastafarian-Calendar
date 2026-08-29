# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 12 de 55: DISCOVERY 06**. Li scars de Patch 01 til Patch 05 resta intact e testabil. Li nov legacy `legacyPrior(dropStore, i, back)` tenta resolver history exclusivmen per `dropStore[i-back]`.

Ti design functiona por un slot positiv quel refere a un visible drop ja calculat. Ma li prim visible drops necessita history de slots `0..-6`, quel semanticmen corresponde a hidden1..hidden7. Li legacy ne conosse ti mapping e ne consulta `hiddenByNearness`; ergo li nov regression es **EXPECTED RED**.

Un `LegacyPriorAdapter` e un `Discovery06PriorHandler` conecta li defect a un path real del monster. Li context conserva li index current, li retro-distance, li slot calculat, un flag indicant si li slot es visibil e li output legacy. Null `priorPatch` existe ancor.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null defect de stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions precedent, includente Patch 05, deve restar verd:

```text
npm run test:previous
```

Li regression de Discovery 06 deve esser rubi pro que `legacyPrior` ne posse resolver slots non-positiv a hidden drops:

```text
npm run test:discovery-06
```

Li commande principal deve finir rubi solmen in ti regression nov:

```text
npm test
```

Li verifier precedent confirma separatmen que `legacyPrior` continua functionar por un slot visibil positiv e que li route monster conserva exactmen li slot negativ e li output absent sin correction.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.

## Stage 11 — Patch 05

Li storage legacy del sett hidden drops resta fisicmen retrograd. `hiddenByNearness` adjunte exclusivmen li translator `8-k` por access semantic per proximity; it ne reverse, ne copie in ordine nov e ne elimina li scar de Discovery 05. `Patch05HiddenNearnessWrapper` registra li proximity demandat e li slot fisic usat durant li route historic. Li regression de Discovery 05 es nu verd.


## Stage 12 — Discovery 06

Li history legacy ne conosse li hidden drops. `legacyPrior(dropStore, i, back)` lee directmen `dropStore[i-back]`; por un slot positiv it posse trovar un visible drop precedent, ma por `0..-6` it ne traducte a hidden1..hidden7. `Discovery06PriorHandler` conserva ti failure intact in li route historic. Li correction `priorPatch` es reservat exclusivmen por Stage 13.
