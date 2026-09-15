# Arkitektura hanggang Stage 20

## Input sa Discovery 10

Ang bowl-update scar ay tumatanggap ng:

- real visible drop `i`;
- Patch 08 corrected order;
- Patch 09 corrected pours;
- patched stone row;
- current six bowl values.

## Historical update

```text
working = copy(current bowls)

for position = 1..6:
    bowlId = order[position]
    prevId = previous order position
    nextId = next order position
    s = working[bowlId]
        + 2*working[prevId]
        + 3*working[nextId]
        + pours[position]
        + drop
        + stone[position-kind]

    working[bowlId] = SAVE(
        s^2
        + 5*working[prevId]*working[nextId]
        + i*position
    )
```

Ang contamination ay dahil parehong storage ang source ng reads at destination ng bawat immediate write.

## Production route

Stage 20 keeps Stage 19 intact, then executes one real `i=1` Discovery 10 bowl update using `legacyInitialBowls` and `patch09ProductionPours`. The raw result remains observable but is not yet corrected.

## Stage boundary

Wala pang separate old snapshot, pending output table, o commit-after-all-six update. Iyon ay Patch 10 / Stage 21.
