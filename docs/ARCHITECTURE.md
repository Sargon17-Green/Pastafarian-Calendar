# Arkitektura hanggang Stage 17

Ang Stage 17 ay Patch 08 para sa permutation-rank off-by-one scar ng Discovery 08.

## Preserved raw layer

```text
oldPermutationUnrank0(rank0)
legacy caller:
    oneBased = regularMod(drop-1,720)+1
    raw = oldPermutationUnrank0(oneBased)
```

Ang layer na ito ay nananatiling pisikal at talagang tinatawag.

## Patch 08

```text
Invoke-Patch08PermutationRankRepair
-> LegacyPermutationRankAdapter         # raw scar first
-> oneBased = regularMod(drop-1,720)+1
-> legacyRank0 = oneBased-1
-> oldPermutationUnrank0(legacyRank0)
-> corrected order
```

Sa raw ordinal 720, kino-capture ang undefined/range scar at nagpapatuloy ang corrected chain sa rank0 719.

## Production route

Pagkatapos ng Patch 07 probe:

```text
Invoke-Patch08PermutationRankRepair(dropIndex=1, dropValue=1)
    raw Discovery 08 -> 1,2,3,4,6,5
    corrected rank0=0 -> 1,2,3,4,5,6
```

Ang raw order ay nananatiling observable sa `legacyPermutationProbeOrder`; ang authoritative probe value ay `patch08ProductionOrder`.

## Patch 08 state

Invocation-owned:

- `patch08DropIndex`
- `patch08DropValue`
- `patch08OneBasedOrdinal`
- `patch08LegacyRank0`
- `patch08LegacyWrongOrder`
- `patch08LegacyWrongUndefined`
- `patch08LegacyWrongError`
- `patch08CorrectedOrder`
- `patch08Applied`
- `patch08Status`
- `patch08InvocationCount`

## GREEN contract

- raw Discovery 08 RED count = 720;
- corrected translator GREEN count = 720;
- supplied visible-drop order table = 46/46 GREEN;
- raw scar executes before correction;
- drop 720 raw undefined, corrected final permutation.

## Wala pang Stage 18

Walang fixed-bowl pour defect, `LegacyPourAdapter`, `bowlAlias`, `patchedPours`, o Patch 09.
