# Arkitektura hanggang Stage 16

Ang Stage 16 ay Discovery 08 para sa zero-based permutation helper na tinatawag gamit ang one-based ordinal.

## Raw helper

```text
oldPermutationUnrank0(rank0)
```

ay valid sa `0..719`.

## Historical caller

```text
oneBasedOrdinal = regularMod(dropValue - 1, 720) + 1
legacyRank0Input = oneBasedOrdinal
order = oldPermutationUnrank0(legacyRank0Input)
```

Ang equality ng `legacyRank0Input` at `oneBasedOrdinal` ang scar.

## Production route

Pagkatapos ng Patch 07 probe, ang real route ay nagpapatakbo ng `LegacyPermutationRankAdapter(dropValue=1)`. Ito ay nagbabalik ng `1,2,3,4,6,5` sa halip na normative `1,2,3,4,5,6`.

## EXPECTED_RED contract

```text
EXPECTED_RED = 720
MATCH = 0
```

Wala pang Patch 08 bridge at wala pang bowl aliases ng susunod na patch family.
