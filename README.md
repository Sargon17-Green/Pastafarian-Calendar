# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 4 de 55: DISCOVERY 02**. Li scar de Patch 01 resta intact e verd. Un nov defect historic es nu conectet a production: `oldDayTag(day)` calcula duplic li distance absolut al Foundation. Ti design rende `0` al Foundation e rende valores par anc pos li Foundation, contradient li numeration normativ quel exige `1` al Foundation e valores impar pos it.

Li legacy passa tra `LegacyDayTagAdapter` e `Discovery02DayTagHandler`, con input, output, handler, trace e metric conservat in li context de invocation. Null correction es present: Patch 02 es reservat por Stage 5. Li statu del repository es dunc intentionalmen **EXPECTED_RED**.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null patch posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ usa `BigInt`. Null floating-point es usat por SAVE, rangs, counts, gates, annus, compositiones o intertexes. `M = 2^127 - 1` es representat exactmen. Counts combinatori posse crescer ultra `M` sin truncation.

## Tests

Li commande principal es intentionalmen rubi in ti discovery:

```text
npm test
```

Por confirmar que omni regressions anterior resta verd:

```text
npm run test:previous
```

Por executar solmen li regression nov de Discovery 02:

```text
npm run test:discovery-02
```

Ti regression compara `oldDayTag` con `dayCount` del reference local. Li failure es expectat exactmen al Foundation e al dies posterior. Ne changear li expected values e ne adjunter li correction ante Stage 5.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
