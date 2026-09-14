# Arkitektura hanggang Stage 2

Ang Stage 1 ay nagtatag ng neutral na per-invocation shell. Sa Stage 2, lumalaki ang monster sa unang makasaysayang DISCOVERY nang hindi pa nagdaragdag ng correction.

## Mga hangganan

`oracle/NormativeScroll.ps1` ang test-only na malinis na reference. Hindi ito maaaring tawagin ng production path.

`src/MonsterSkeleton.ps1` ang production foundation at dispatcher host.

`src/Discovery01.ps1` ang naglalaman ng unang legacy arithmetic behavior at adapter. Ito lamang ang production file na may `oldRemainder`.

`src/SourceLanguageCatalog.ps1` ang frozen na mapping mula `canonicalIndex` tungo sa Filipino source string. Hindi kailanman ginagamit ang string para sa rank, unrank, sort, cache key, o normative selection.

## Discovery 01 route

Ang kasalukuyang production route ay:

```text
Invoke-CalendarDateSpaghetti
-> New-BaseMonsterContext
-> New-BaseDispatcher
-> DISCOVERY01 handler
-> Invoke-Discovery01LegacyAdapter
-> oldRemainder
```

Ang `oldRemainder` ay regular modulo sa `M` at sadyang hindi gumagawa ng `0 -> M` correction.

## Transaksiyonal na prinsipyo

Ang Discovery 01 adapter ay nagsusulat ng `legacyRemainderInput` at `legacyRemainderValue` sa `semanticPending`, vina-validate ang pending state, at saka lamang nagko-commit. Pagkatapos ng commit, ang public discovery fields sa context ay ina-update para sa kasalukuyang invocation.

Walang mutable semantic global state. Ang constant na `M` ay immutable configuration lamang.

## Observability

Ang logs at metrics ay non-semantic. Ang log code na `monster.discovery01.legacy.adapter` ay naglalarawan ng dinaanang route ngunit hindi ginagamit upang magpasya ng arithmetic result.

## Expected-red contract

Ang Stage 2 test suite ay matagumpay lamang kapag napatunayan nito ang eksaktong tatlong expected divergences sa `M`, `2M`, at `3M`, kasama ang tugmang `M+1`. Ang repository state ay samakatuwid `RED` sa makasaysayang kahulugan ngunit ang Discovery verification mismo ay `PASS`.

Walang `savePatch` sa arkitekturang ito; ang correction ay hindi maaaring lumitaw bago ang Stage 3.
