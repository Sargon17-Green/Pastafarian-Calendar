# Arkitektura sa Stage 1

Ang Stage 1 ay sadyang payak kumpara sa magiging huling monster. Ang layunin nito ay magbigay lamang ng neutral na balangkas na maaari pang lumaki sa makasaysayang pagkakasunod ng 26 patch.

## Mga hangganan

`oracle/NormativeScroll.ps1` ang test-only na malinis na reference. Hindi ito maaaring tawagin ng production path.

`src/MonsterSkeleton.ps1` ang neutral na production foundation. Wala itong legacy defect at wala itong kaalaman tungkol sa mga patch sa hinaharap.

`src/SourceLanguageCatalog.ps1` ang frozen na mapping mula `canonicalIndex` tungo sa Filipino source string. Hindi kailanman ginagamit ang string para sa rank, unrank, sort, cache key, o normative selection.

## Transaksiyonal na prinsipyo

Sa mga susunod na stage, ang mutable semantic state ay dadaan sa `snapshot -> compute -> validate -> commit`. Sa Stage 1, ang prinsipyong ito ay ipinapahayag lamang ng neutral context API; wala pang patch-specific state.

## Observability

Ang logs at metrics ay non-semantic. Walang branch sa Stage 1 na nakadepende sa kanilang laman, dami, insertion order, o estado.
