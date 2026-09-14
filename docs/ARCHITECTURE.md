# Arkitektura hanggang Stage 5

Ang Stage 1 ay neutral na shell. Stage 2 at 4 ay historical discoveries. Stage 3 at 5 ay hiwalay na patch layers na hindi binubura ang raw scars.

## Mga file boundary

`oracle/NormativeScroll.ps1` ay test-only reference.

`src/Discovery01.ps1` ay raw legacy remainder.

`src/Patch01.ps1` ay save patch.

`src/Discovery02.ps1` ay raw legacy day tag.

`src/Patch02.ps1` ay `dayTagWithFoundationScar`, ang pisikal na Foundation guard, at Patch 02 adapter.

`src/MonsterSkeleton.ps1` ang production dispatcher host.

## Stage 5 route

```text
Invoke-CalendarDateSpaghetti
-> Invoke-Patch01SaveAdapter
-> Invoke-Patch02DayTagAdapter
-> dayTagWithFoundationScar(action)
-> oldDayTag(action)
-> dayTagWithFoundationScar(target)
-> oldDayTag(target)
```

## Raw at patched state

Ang Patch 02 adapter ay nagko-commit ng parehong raw at patched values:

- `legacyActionDayTag`
- `legacyTargetDayTag`
- `patch02ActionDayTag`
- `patch02TargetDayTag`

Ang `patch02FoundationGuardSeen` ay observability ng historical guard at hindi normative input.

## GREEN contract

Ang patched action at target day tags ay dapat tumugma sa normative `day_count` para sa mga araw bago, sa, at pagkatapos ng Foundation. Ang direct `oldDayTag` ay dapat manatiling mali sa historical surface.

Walang `oldDistance` sa Stage 5.
