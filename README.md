# Kalendaryong Pastafarian — PowerShell + Filipino

## Stage 18 — Discovery 09

Ang old initial-bowl factory ay tama. Mula sa patched counts, eksaktong binubuo nito ang anim na initial bowls gamit ang primes `17,19,23,29,31,37`.

Ang bagong historical scar ay nasa pours:

```text
pour position 1 -> fixed old bowl ID 1
pour position 2 -> fixed old bowl ID 2
pour position 3 -> fixed old bowl ID 3
```

Sa normatibong position semantics, dapat gamitin ang bowl IDs mula sa corrected permutation order positions 1,2,3.

Ang Stage 18 production route ay lumalawak sa full 46 visible drops at corrected 46-order table upang ang pour defect ay talagang nasa real path. Pagkatapos nito ay isang raw fixed-bowl pour lamang sa `i=1` ang ginagawa; wala pang bowl stir/update.

Sa exact Foundation fixture:

```text
i=1  order = 5,4,3,6,2,1  -> EXPECTED_RED
i=2  order = 1,6,2,4,3,5  -> EXPECTED_RED
i=3  order = 1,3,5,6,2,4  -> EXPECTED_RED
i=46 order = 1,2,3,4,6,5  -> incidental MATCH
```

Wala pang Patch 09 `bowlAlias` correction at wala pang Patch 10 in-place bowl update logic.
