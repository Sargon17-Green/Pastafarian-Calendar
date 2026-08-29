# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 2 de 55: DISCOVERY 01**. Li prim defect historic es nu present e activ: `oldRemainder(value)` usa regular modulo con `M_OLD = 2^127 - 1`. Un `LegacyRemainderAdapter` e un `Discovery01RemainderHandler` porta ti operation tra li manager e li context de invocation.

Ti stage es intentionalmen **EXPECTED_RED**. Li regression demonstra que multiplicas de `M` deven `0` in li legacy, ma li reference normativ `SAVE` exige `M`. Li correction `savePatch` apartene solmen a Stage 3 e ne es present.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null patch posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ usa `BigInt`. Null floating-point es usat por SAVE, rangs, counts, gates, annus, compositiones o intertexes. `M = 2^127 - 1` es representat exactmen. Counts combinatori posse crescer ultra `M` sin truncation.

## Tests

Li suites precedent resta verdes. Li commande principal fini intentionalmen con un regression red de Discovery 01:

```text
npm test
```

Por provar solmen omni regressions precedent:

```text
npm run test:previous
```

Por reproducer solmen li divergentie nov:

```text
npm run test:discovery-01
```

Li resultat expectat de Stage 2 es: regressions precedent PASS, regression de Discovery 01 FAIL exactmen pro `0` contra `M` por multiplicas de `M`.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
