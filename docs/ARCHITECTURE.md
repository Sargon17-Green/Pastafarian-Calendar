# Arkitektura hanggang Stage 4

Ang Stage 1 ay neutral na shell. Ang Stage 2 ay nagdagdag ng unang historical defect. Ang Stage 3 ay nagdagdag ng unang correction layer. Ang Stage 4 ay nagdaragdag ng ikalawang defect habang pinananatiling GREEN ang Patch 01.

## Mga hangganan

`oracle/NormativeScroll.ps1` ang test-only reference at hindi maaaring tawagin ng production path.

`src/Discovery01.ps1` ang historical legacy remainder.

`src/Patch01.ps1` ang save correction layer.

`src/Discovery02.ps1` ang historical legacy day-tag implementation.

`src/MonsterSkeleton.ps1` ang dispatcher host at kasalukuyang production route.

## Stage 4 route

```text
Invoke-CalendarDateSpaghetti
-> PATCH01 adapter
-> DISCOVERY02 adapter
-> oldDayTag(calculationDay)
-> oldDayTag(targetDay)
```

Ang `oldDayTag` ay eksaktong `2 * abs(day - FOUNDATION)` at sadyang walang Patch 02 correction.

## State ownership

Ang Patch 01 state at Discovery 02 state ay parehong nakaimbak sa sariling invocation context. Ang Discovery 02 transaction ay nagdadagdag ng:

- `legacyActionDayTag`
- `legacyTargetDayTag`

nang hindi binabago ang committed Patch 01 fields.

## Expected-red contract

Dapat manatiling GREEN ang Patch 01 regression habang ang bagong day-tag regression ay eksaktong may tatlong divergence: Foundation, Foundation+1, at Foundation+2.

Walang `dayTagWithFoundationScar` sa Stage 4.
