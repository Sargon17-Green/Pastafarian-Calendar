# Arkitektura hanggang Stage 18

## Stage 18 support plumbing

Ang real production route ay ngayon nagtatayo ng:

```text
patched stone table
-> hidden storage
-> patched prior reads
-> sentinel-corrected visible grinds
-> 46 visible drops
-> Patch 08 corrected 46-order table
-> Discovery 09 fixed-bowl pour probe
```

Ang visible-drop builder ay gumagamit ng existing Patch 06 history semantics at Patch 07 grind rows; wala itong bagong scar.

## Discovery 09 scar

Ang exact old initial bowls ay:

```text
temp = action + target*bowlId + distance + connection + direction + prime^2
oldBowls[bowlId] = SAVE(temp^2 + bowlId)
```

na may primes `17,19,23,29,31,37`.

Ang raw pour helper:

```text
pour1 = SAVE(drop^2 + wheat * oldBowls[1] + 3*i)
pour2 = SAVE(drop^2 + barley * oldBowls[2] + 5*i)
pour3 = SAVE(drop^2 + salt * oldBowls[3] + 7*i)
```

ay sadyang hindi tumitingin sa permutation order.

## Production probe

Sa Foundation fixture, `i=1`:

```text
drop ordinal = 570
order = 5,4,3,6,2,1
raw reads = bowl IDs 1,2,3
```

kaya red ang positions 1 at 2; position 3 ay coincidentally pareho sa bowl 3 ngunit buong tuple ay divergent.

## Stage boundary

Wala pang `installOrderAliases`, `bowlByLegacyPosition`, `aliasedPositionPours`, `bowlAlias`, `patchedPours`, `vaultOld`, o in-place bowl update patch.
