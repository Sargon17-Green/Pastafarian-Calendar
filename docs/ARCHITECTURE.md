# Arkitektura hanggang Stage 10

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8/10 ay historical discovery layers. Ang Stage 3/5/7/9 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` / `src/Patch04.ps1` — stone table.
- `src/Discovery05.ps1` — backward hidden storage at wrong direct near-ness access.
- `src/MonsterSkeleton.ps1` — production route at invocation-owned semantic state.

## Stage 10 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Patch 04
-> Discovery 05
   -> exact hidden values from patched counts + patched stones
   -> physical storage hidden7..hidden1
   -> wrong direct read storage[1] for requested k=1
```

## Hidden computation

Para sa bawat `k=1..7`, kinukuha ang coefficient tuple, exact counts, patched stone row `k`, at seven-grind recurrence. Ang lahat ng modular saving ay dumadaan sa kasalukuyang SAVE patch semantics.

Ang coefficient storage ay historical reversed layout:

```text
slot 1 = coeff(k=7)
...
slot 7 = coeff(k=1)
```

`Get-Discovery05CoeffForHidden(k)` ay kumukuha ng `slot 8-k`, kaya tama ang value generation bago pa lumitaw ang access defect.

## Historical scar

Ang backward physical storage ay nananatiling totoong reversed array.

Ang maling accessor ay nananatiling:

```text
legacyHiddenDirectByAssumedNearness(storage,k) = storage[k]
```

## Invocation-owned state

- `legacyHiddenStorage`
- `legacyHiddenCount`
- `legacyHiddenLastRequestedK`
- `legacyHiddenLastReturnedValue`
- `discovery05Status`
- `discovery05InvocationCount`

## EXPECTED_RED contract

`k=1,2,6,7` — divergent.

`k=4` — MATCH dahil midpoint.

Wala pang `hiddenByNearness` translator at walang Stage 11 correction.
