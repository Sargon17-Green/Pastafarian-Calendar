# Arkitektura hanggang Stage 8

Ang Stage 1 ay neutral shell. Ang Stage 2/4/6/8 ay historical discovery layers. Ang Stage 3/5/7 ay correction wrappers na nagpapanatili sa raw scars.

## Mga boundary

`oracle/NormativeScroll.ps1` ay test-only at hindi bahagi ng production computation.

`src/Discovery01.ps1` / `src/Patch01.ps1` — remainder.

`src/Discovery02.ps1` / `src/Patch02.ps1` — day tags.

`src/Discovery03.ps1` / `src/Patch03.ps1` — distance.

`src/Discovery04.ps1` — legacy stone table na may sequential in-place mutation.

`src/MonsterSkeleton.ps1` — dispatcher host at production route.

## Stage 8 production route

```text
Invoke-CalendarDateSpaghetti
-> Invoke-Patch01SaveAdapter
-> Invoke-Patch02DayTagAdapter
-> Invoke-Patch03DistanceAdapter
-> Invoke-Discovery04LegacyStoneAdapter
-> Get-Discovery04LegacyStoneTable
-> mutateStonesWrong
```

## Legacy stone state

Ang row 1 ay:

```text
w=17, b=29, s=43, m=71, r=101
```

Para sa bawat `i=2..46`, ang historical routine ay nagmu-mutate sa parehong state sa pagkakasunod na `w`, `b`, `s`, `m`, `r`.

Ang table row ay kinokopya pagkatapos ng bawat mutation upang hindi mabago nang retroactive ang mga naunang row.

## Semantic state

Discovery 04 commits:

- `legacyStoneTable`
- `legacyStoneRowsBuilt`

At ang invocation context ay may:

- `discovery04Status`
- `discovery04InvocationCount`

Hindi ginagamit ang logs o metrics bilang input sa computation.

## EXPECTED_RED contract

Dapat mag-diverge sa test-only normative table ang rows 2, 3, at 46.

Sa row 2, ang `w` ay dapat tumugma pa rin sa normative value, samantalang ang `b`, `s`, `m`, at `r` ay dapat mag-diverge.

Wala pang `stonePatch` o anumang Stage 9 correction.
