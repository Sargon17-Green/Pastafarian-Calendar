# Arkitektura hanggang Stage 3

Ang Stage 1 ay nagtatag ng neutral na per-invocation shell. Ang Stage 2 ay nagdagdag ng unang historical defect. Ang Stage 3 ay naglalagay ng unang patch layer nang hindi binubura ang defect na natuklasan sa nakaraang stage.

## Mga hangganan

`oracle/NormativeScroll.ps1` ang test-only na malinis na reference. Hindi ito maaaring tawagin ng production path.

`src/Discovery01.ps1` ang naglalaman ng historical `oldRemainder` behavior.

`src/Patch01.ps1` ang naglalaman ng `savePatch` at ng Patch 01 adapter.

`src/MonsterSkeleton.ps1` ang production dispatcher host.

`src/SourceLanguageCatalog.ps1` ang frozen na mapping mula `canonicalIndex` tungo sa Filipino source string.

## Patch 01 route

Ang kasalukuyang production route ay:

```text
Invoke-CalendarDateSpaghetti
-> New-BaseMonsterContext
-> New-BaseDispatcher
-> PATCH01 handler
-> Invoke-Patch01SaveAdapter
-> oldRemainder
-> savePatch
```

Ang `savePatch` ay hindi muling nagpapatupad ng modulo arithmetic. Tinatanggap lamang nito ang legacy remainder at minamapa ang `0` sa `M`.

## Transaksiyonal na prinsipyo

Bago mag-commit, ang Patch 01 adapter ay nagtatala sa `semanticPending` ng:

- `legacyRemainderInput`
- `legacyRemainderValue`
- `patch01PatchedValue`

Pagkatapos ng validation, ang state lamang ng kasalukuyang invocation ang kino-commit. Walang mutable semantic global state.

## Historical observability

Ang parehong legacy at patched values ay nananatiling nakikita sa context para maipakita ang eksaktong historical correction. Ang metrics at logs ay observability lamang at hindi semantic input.

## GREEN contract

Ang Stage 3 verification ay dapat magpakita na ang production patched value ay katumbas ng normative `SAVE` para sa dating divergent cases, control cases, zero, at negative inputs. Kasabay nito, dapat manatiling `0` ang direktang `oldRemainder` para sa mga multiple ng `M`.

Walang Stage 4 discovery code sa arkitekturang ito.
