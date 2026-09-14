# Arkitektura hanggang Stage 11

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8/10 ay historical discovery layers. Ang Stage 3/5/7/9/11 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` / `src/Patch04.ps1` — stone table.
- `src/Discovery05.ps1` — backward hidden storage at wrong direct accessor.
- `src/Patch05.ps1` — near-ness `8-k` translator habang pinapatakbo pa rin ang raw wrong accessor.
- `src/MonsterSkeleton.ps1` — production route at invocation-owned semantic state.

## Stage 11 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Patch 04
-> Discovery 05
   -> build hidden7..hidden1 physical storage
-> Patch 05
   -> raw legacyHidden[k] read
   -> capture raw scar
   -> hiddenByNearness(storage,k)
   -> storage[8-k]
   -> authoritative corrected value
```

## Preserved Stage 10 scars

`Discovery05.ps1` ay hindi binabago ng Stage 11.

Ang physical storage ay nananatiling reversed.

Ang `legacyHiddenDirectByAssumedNearness` ay nananatiling maling direct accessor at aktuwal na tinatawag ng Patch 05.

## Patch 05 state

Ang invocation context ay nagmamay-ari ng:

- `patch05RequestedK`
- `patch05TranslatedSlot`
- `patch05LegacyDirectValue`
- `patch05CorrectedValue`
- `patch05Applied`
- `patch05Status`
- `patch05InvocationCount`

Ang `legacyHiddenLastReturnedValue` ay authoritative corrected value na pagkatapos ng Patch 05.

## GREEN contract

Para sa lahat ng `k=1..7`, ang Patch 05 result ay dapat tumugma sa normative hidden `k`.

Para sa production `k=1`, ang raw scar ay `hidden7`, translated slot ay `7`, at corrected result ay `hidden1`.

Wala pang Stage 12 `legacyPrior` o visible-history logic.
