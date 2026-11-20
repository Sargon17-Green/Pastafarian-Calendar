# FALSE+العربية — Stage 16 independent offline evidence audit (2026-11-20)

**PROJECT_ID:** `PC-BRANCH-FALSE-ARABIC`  
**Scope:** stage-16 exact-source Native evidence + independent, artifact-only audit; no production code change.  
**Verdict:** `NATIVE_VERIFIED_WITH_CONTRACT_GAP`; **Stage16 NOT_ACCEPTED**.

## Verified run and provenance

- GitHub run [44634528237](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44634528237) completed/success; job `135949507620` completed/success on branch `FALSE+العربية` at `3737bfc2f24ac31011f825554be0f9568ca0d77f`.
- Original-source pin: `6f28e9400f5c6e867fbe998629a02f739f91a4a9`.
- Original interpreter pin: `eb3135565a8670cced3f6bbca4dbf7b014c45634`; compiler exit 0; Unicode preflight output 4.
- Artifact [14584972442](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44634528237/artifacts/14584972442), byte length 59,645; SHA-256 `06f1fb5a7770c45b65e8cbff74e8dd8a9a3291be4a930337735df1aaed581fbe`; ZIP CRC PASS (46 files).
- Source reconstructed *from the exact `native.false` input bytes* by SHA-256 partitioning, not by assuming the receipt is truthful. Each recovered segment's Git blob SHA-1 was compared with a separately fetched file from the pinned source commit:

| Source | SHA-256 | Git blob SHA-1 | Bytes |
| --- | --- | --- | ---: |
| `src/bigint.false` | `2a67528b19ea8cb1f8db907f8c13fabf95480bed2b4c88c1e8c82e49c3d084d0` | `1e8de1147ba46cd0eb75a47f24673bbd9783946f` | 14,682 |
| `src/monster_bootstrap.false` | `9ce4a772092f8a6ccf4e2af243451d427861e1324af1e5b12737d81d26102653` | `923b07573789e80efc6c4c12e9e03accc462f3a5` | 14,053 |
| `test/stage16_sequence_remove_14.false` | `6ffa6b59a6c6f0004e1a630dd4afe94e7d664fc767c37c9256a7228cea0490ad` | `bdc95f06e5ccfaaf1e5e81c26b059261d2f8bf7a` | 9,559 |

Combined runtime input SHA-256: `ff57b38255e7b1cb4d56a4036c09708831d3297fb55a535d5cad5162b9237e74`. All three source pieces, separators and end-of-input matched.

## Independent checks performed

1. Parsed `evidence.json` and `oracle.json` *without importing* the Stage16 production or CI oracle Python modules.
2. Checked 14 ordered Native success labels, including 12 distinct anchors and 2 exact replays; Native exit 0, empty stderr, exactly one terminal marker.
3. Independently recomputed each `chosen=sequence[position-1]` and `remaining=[x for index,x in enumerate(sequence,1) if index!=position]`. All 14 anchor/replay expectations passed, including duplicates.
4. Independently enumerated `sum(n*n! for n in range(1,7)) = 5039` permutation-position domain cases; matched the independent design count.
5. Counted 160 embedded FALSE comparisons in the exact `native.false` source. Verified six invalid-case exits (`1`) and their exact error markers, plus one deliberately corrupted expected-result mutant (`exit=1`, `STAGE16_REMOVE_00_RESULT_FAIL`).
6. Created an additional corrupted-oracle negative control by increasing the expected `chosen` in case 0 by one. The standalone mathematical verifier **rejected** it; negative-control PASS.

This proves that original-source Native execution passed the tested domain, not that every possible input or memory-layout variant is covered.

## Contract gap — deliberately NOT accepted

The two “missing field” negatives use explicit `-1` sentinel values. They **do not** encode a physically truncated two-cell tuple. The interface stores `[sequence,position]` in untagged adjacent cells and has no allocation length metadata, so reading a purportedly absent second cell is not inherently distinguishable from a valid, zero-initialized or neighboring cell. Both the source comment and receipt acknowledge this. Artifact field `truncated_tuple_rejection_verified=false`, `stage16_full_acceptance=false`.

**NEXT (engineering, no user decision required):** write and verify an explicit safe layout contract for absent fields, either a length-tagged tuple with checked accessor or an explicit sentinel-only domain with a separately stated exclusion of physically truncated tuples. Preserve compatibility with existing valid `op33` calls; add focused negative Native checks for the chosen representable layout; perform a new source-pinned CI run only if code/contract materially changes; then update the independent audit and decide Stage16 acceptance. Do not move to Stage17 before this gap is resolved. No main/merge.

**Local audit tool:** `stage16_offline_audit.py` (artifact-only independent verifier; passed locally on the above ZIP; corrupt-oracle negative rejected). Its persistent copy should be attached to the next QA package; no claim of GitHub upload of this script in this commit.
