# Arkitektura hanggang Stage 13

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8/10/12 ay historical discovery layers. Ang Stage 3/5/7/9/11/13 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` / `src/Patch04.ps1` — stone table.
- `src/Discovery05.ps1` / `src/Patch05.ps1` — backward hidden storage at near-ness correction.
- `src/Discovery06.ps1` — raw visible-only `legacyPrior`.
- `src/Patch06.ps1` — visible/hidden branch correction.
- `src/MonsterSkeleton.ps1` — production route at invocation-owned semantic state.

## Raw Stage 12 scar

```text
legacyPrior(dropStore,i,back)
    -> dropStore[i-back]
```

`Discovery06.ps1` ay hindi binago ng Stage 13.

## Patch 06

```text
slot = i - back

slot >= 1
    -> legacyPrior(dropStore,i,back)

slot <= 0
    -> hiddenK = 1-slot
    -> hiddenByNearness(legacyHidden,hiddenK)
```

Ang positive branch ay hindi nangangailangan ng hidden storage.

Ang nonpositive branch ay nangangailangan ng hidden storage at gumagamit ng Stage 11 near-ness translator.

## Stage 13 production route

```text
Invoke-CalendarDateSpaghetti
-> Patch 01
-> Patch 02
-> Patch 03
-> Patch 04
-> Discovery 05
-> Patch 05
-> Patch 06 production probe
   -> i=2
   -> back=1
   -> slot=1
   -> raw legacyPrior
```

Ang probe ay hindi visible-drop computation at hindi pa sinisimulan ang Stage 14 builder.

## Patch 06 state

Invocation-owned:

- `patch06Slot`
- `patch06UsedHidden`
- `patch06HiddenK`
- `patch06Value`
- `patch06Applied`
- `patch06Status`
- `patch06InvocationCount`

Patuloy ding naka-record ang Stage 12 coordinates at authoritative `legacyPriorValue`.

## GREEN contract

Ang dating Stage 12 cases na slot `0,-2,-6` ay tumutugma na sa `hidden1,hidden3,hidden7`.

Ang visible branch ay nagpapatunay ng tunay na raw legacy call at gumagana kahit walang hidden storage.

Ang hidden branch ay hindi tumatawag sa raw helper at tumatawag nang eksaktong isang beses sa `hiddenByNearness`.

## Wala pang Stage 14

Walang `legacyGrindRow`, `LEGACY_VISIBLE_GRIND_TABLE`, `SENTINEL_GRIND_ROW`, `GRIND_TABLE_WITH_SENTINEL`, o `LegacyVisibleDropBuilder`.
