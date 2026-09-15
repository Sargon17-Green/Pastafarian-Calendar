# Kalendaryong Pastafarian — PowerShell + Filipino

## Stage 20 — Discovery 10

Ang bagong historical scar ay nasa six-position bowl update loop.

Sa bawat position, kinukuha ang `bowlId`, `prevId`, at `nextId` mula sa corrected permutation order. Ngunit ang legacy helper ay nagbabasa at agad nagsusulat sa **iisang working bowl storage**:

```text
working[bowlId] = SAVE(
    s^2 + 5*working[prevId]*working[nextId] + i*position
)
```

Dahil dito, ang mga position na susunod ay maaaring makabasa ng values na naisulat na ng naunang position sa parehong drop.

Ang tamang snapshot semantics ay dapat magbasa lamang mula sa lumang bowl snapshot at magsulat sa hiwalay na output storage, ngunit **hindi pa iyon ipinapatupad sa Stage 20**.

Sa historical required fixture:

```text
position 1 -> snapshot MATCH
positions 2,3,6 -> EXPECTED_RED
```

Ang raw helper ay nasa tunay na production path sa `i=1`, gamit ang corrected Patch 09 pours.

Wala pang Patch 10 snapshot/write-buffer/commit-after-six repair.
