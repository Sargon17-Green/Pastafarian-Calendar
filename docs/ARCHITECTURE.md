# Arkitektura hanggang Stage 12

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8/10/12 ay historical discovery layers. Ang Stage 3/5/7/9/11 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` / `src/Patch04.ps1` — stone table.
- `src/Discovery05.ps1` / `src/Patch05.ps1` — backward hidden storage at near-ness correction.
- `src/Discovery06.ps1` — visible-only prior/history access.
- `src/MonsterSkeleton.ps1` — production route at invocation-owned semantic state.

## Stage 12 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Patch 04
-> Discovery 05
-> Patch 05 (k=1)
-> Discovery 06 production probe
   -> probeStore[1] = Patch05 corrected value
   -> legacyPrior(probeStore, i=2, back=1)
   -> visible slot 1
```

Ang production probe ay hindi visible-drop calculation at hindi bagong input sa calendar semantics.

## Discovery 06 raw access

```text
legacyPrior(dropStore,i,back)
    -> dropStore[i-back]
```

Walang hidden fallback.

Ang raw adapter ay nagtatago ng `i`, `back`, computed slot, at returned value sa invocation context.

## Missing hidden-history surface

```text
slot 0  -> hidden1
slot -2 -> hidden3
slot -6 -> hidden7
```

Sa Stage 12, walang laman ang visible store sa mga slot na ito, kaya ang tatlong exact probe ay EXPECTED_RED.

## Preserved Stage 11 behavior

Ang Patch 05 ay nananatiling GREEN at ang production `k=1` corrected value ang ginagamit lamang bilang value ng valid slot-1 probe.

## Wala pang Stage 13

Walang `priorPatch`, walang `hiddenK=1-slot` translation, at walang tawag sa `hiddenByNearness` mula sa `Discovery06.ps1`.
