# Arkitektura hanggang Stage 19

## Preserved raw pour layer

```text
legacyFixedBowlPours
    position 1 -> fixed old bowl ID 1
    position 2 -> fixed old bowl ID 2
    position 3 -> fixed old bowl ID 3
```

Ang raw layer ay nananatiling pisikal at talagang pinapatakbo muna.

## Patch 09

```text
Invoke-Patch09BowlAliasRepair
-> legacyFixedBowlPours
-> installOrderAliases(order)
-> aliasedPositionPours
   -> bowlByLegacyPosition(..., position=1)
   -> bowlByLegacyPosition(..., position=2)
   -> bowlByLegacyPosition(..., position=3)
-> corrected pours
```

Ang alias table ay 1-based:

```text
alias[1] = order[0]
...
alias[6] = order[5]
```

at slot 0 ay sentinel `0`.

## Production route

Ang Stage 19 production route ay gumagamit ng real 46-drop table at Patch 08 corrected order table. Sa production probe `i=1`, kino-capture nang hiwalay ang raw Discovery 09 pours at ang corrected Patch 09 pours; ang corrected tuple ang authoritative result.

## Invocation-owned Patch 09 state

- `patch09DropIndex`
- `patch09BowlAlias`
- `patch09LegacyFixedPours`
- `patch09CorrectedPours`
- `patch09Applied`
- `patch09Status`
- `patch09InvocationCount`

## Stage boundary

Wala pang Stage 20 / Patch 10 `vaultOld`, pending bowl-update table, o in-place bowl-update repair.
