# Arkitektura hanggang Stage 9

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8 ay historical discovery layers. Ang Stage 3/5/7/9 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

- `src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.
- `src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.
- `src/Discovery03.ps1` / `src/Patch03.ps1` — distance.
- `src/Discovery04.ps1` — raw sequential in-place stone mutation.
- `src/Patch04.ps1` — snapshot/legacy-garbage/five-field overwrite correction.
- `src/MonsterSkeleton.ps1` — dispatcher host at production route.

## Stage 9 production route

```text
Invoke-CalendarDateSpaghetti
-> Invoke-Patch01SaveAdapter
-> Invoke-Patch02DayTagAdapter
-> Invoke-Patch03DistanceAdapter
-> Invoke-Patch04StoneAdapter
-> Get-Patch04StoneTableThroughLegacyBuilder
-> stonePatch (rows 2..46)
   -> old snapshot
   -> mutateStonesWrong on separate clone
   -> legacy garbage capture
   -> overwrite w,b,s,m,r from old snapshot only
```

## Preserved historical scar

`mutateStonesWrong` remains in `Discovery04.ps1` and still mutates one state in order `w,b,s,m,r`.

`Get-Discovery04LegacyStoneTable` also remains available as the raw wrong builder for direct historical testing.

## Patch 04 state

The production invocation owns:

- `legacyStoneTable`
- `legacyStoneRowsBuilt=46`
- `patch04RowsPatched=45`
- `patch04LastOldStones`
- `patch04LastLegacyGarbage`
- `patch04LastCommittedStones`
- `patch04Status`
- `patch04InvocationCount`

Logs, metrics, at diagnostics ay hindi input sa normative computation.

## GREEN contract

Lahat ng patched rows 1–46 ay dapat eksaktong tumugma sa test-only normative stone table.

Ang raw Stage 8 builder ay dapat manatiling divergent sa rows 2, 3, at 46.

Wala pang Stage 10 logic.
