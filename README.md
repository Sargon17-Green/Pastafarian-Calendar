# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 3 de 55: PATCH 01**. Li defect historic de Stage 2 resta present: `oldRemainder(value)` usa regular modulo con `M_OLD = 2^127 - 1` e rende `0` por multiplicas de `M`.

Li correction ne modifica ti function legacy. `savePatch(value)` apella `oldRemainder`, e si li residu es `0` it remappa it a `M_OLD`. Un `Patch01SaveWrapper` aplica ti correction pos `Discovery01RemainderHandler`, conservante li scar, li trace e li output legacy in li context de invocation. Li repository retorna a **GREEN**.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null patch posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ usa `BigInt`. Null floating-point es usat por SAVE, rangs, counts, gates, annus, compositiones o intertexes. `M = 2^127 - 1` es representat exactmen. Counts combinatori posse crescer ultra `M` sin truncation.

## Tests

Li commande principal es nu verd:

```text
npm test
```

Por executar li suites anterior includente li regression de Discovery 01 in su form nu reparat:

```text
npm run test:previous
```

Por verificar directmen li equivalence local de Patch 01:

```text
npm run test:patch-01
```

Li tests confirma simultanmen que `oldRemainder(M) == 0` resta ver e que `savePatch(M) == M` concorda con li reference normativ.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
