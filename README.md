# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 10 de 55: DISCOVERY 05**. Li scars de Patch 01 til Patch 04 resta intact e testabil. Li nov legacy `buildHiddenWithBackwardStorage(counts, stones)` calcula li sett hidden drops con li coefficients exact, ma conserva les fisicmen in ordine retrograd: hidden7, hidden6, ..., hidden1.

Un `LegacyHiddenStorageAdapter` e un `Discovery05HiddenStorageHandler` conecta ti storage a un path real del monster. Li context conserva li comptes, li storage legacy e du probes direct de slots 1 e 7. Li translator per proximity ne existe ancor; ergo li nov regression es **EXPECTED RED**.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null defect de stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions precedent deve restar verd:

```text
npm run test:previous
```

Li regression de Discovery 05 deve esser rubi pro que li storage legacy es retrograd e null translator de access existe ancor:

```text
npm run test:discovery-05
```

Li commande principal deve finir rubi solmen in ti regression nov:

```text
npm test
```

Li verifier precedent confirma separatmen que li sett values self es exact e que slots 1..7 es precis li serie normativ reversat.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
