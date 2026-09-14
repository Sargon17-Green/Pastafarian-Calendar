# Arkitektura hanggang Stage 6

Ang Stage 1 ay neutral na shell. Ang Stage 2 at 4 ay historical defects. Ang Stage 3 at 5 ay correction wrappers na nagpapanatili sa raw scars. Ang Stage 6 ay ikatlong discovery layer.

## Mga file boundary

`oracle/NormativeScroll.ps1` ay test-only reference.

`src/Discovery01.ps1` at `src/Patch01.ps1` ang remainder scar at correction.

`src/Discovery02.ps1` at `src/Patch02.ps1` ang day-tag scar at correction.

`src/Discovery03.ps1` ang raw legacy distance.

`src/MonsterSkeleton.ps1` ang production dispatcher host.

## Stage 6 route

```text
Invoke-CalendarDateSpaghetti
-> Invoke-Patch01SaveAdapter
-> Invoke-Patch02DayTagAdapter
-> Invoke-Discovery03LegacyDistanceAdapter
-> oldDistance
-> dayTagWithFoundationScar(calculationDay)
-> dayTagWithFoundationScar(targetDay)
```

Ang `oldDistance` ay sadyang hindi gumagamit ng chronological day difference.

## Per-invocation state

Ang Discovery 03 adapter ay nagdadagdag ng:

- `legacyDistanceCalculationDay`
- `legacyDistanceTargetDay`
- `legacyDistanceValue`
- `discovery03Status`
- `discovery03InvocationCount`

Hindi ginagamit ang logs o metrics bilang semantic input.

## Expected-red contract

Dapat manatiling GREEN ang Patch 01 at Patch 02 outputs. Ang bagong distance layer ay dapat magkaroon ng eksaktong apat na divergence at isang matching control sa limang historical probes.

Walang Patch 03 correction sa Stage 6.
