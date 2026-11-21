# Stage 1 — canonical Hebrew Scroll audit

**Project:** PC-BRANCH-FORTRAN-ENGLISH  
**Baseline before correction:** 6f1be87ebcf4769710bd5891086760a2e7f67cd4  
**Component correction:** a855ec194ff90eb580fcbdfd50dad915fc3b1ec5  
**Disposition:** the twelve-post-stir component is corrected and independently checked; Stage 1 remains open.

## Normative authority

The governing source is the Hebrew Scroll snapshot:

- File: `Megilat_HaItim_Yehuda_FINAL_2026-09-18.md`
- SHA-256: `7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7`
- Chapter: `לוח ארבעה עשר: לבלול שתים עשרה פעמים אחר הטיפה האחרונה`
- Snapshot lines: 831–885

The Hebrew source governs; the English translation and implementation consensus cannot override it.

## Exact twelve-post-stir rule

For stir number i=1..12, let b[1..6] be the six bowl values at the beginning of the stir.

1. Compute rawBowlSum = b[1]+...+b[6].
2. Compute savedOrderValue = SAVE(rawBowlSum + 149*i).
3. Select the lexicographic permutation of the six bowl IDs with one-based rank 1 + ((savedOrderValue - 1) mod 720).
4. For bowl o[p] at position p, with circular predecessor o[p-1] and successor o[p+1], compute:

```text
subtotal = b[o[p]]
         + 3*b[o[p-1]]
         + 5*b[o[p+1]]
         + rawBowlSum
         + i
         + p*p

newBowl[o[p]] = SAVE(subtotal*subtotal
                     + 7*b[o[p-1]]*b[o[p+1]])
```

All six updates read the same beginning-of-stir vector and are installed together. The saved value selects the order only; it does not replace rawBowlSum in the update formula.

## Defect found in the baseline

Both the Fortran routine `test/normative_oracle_core.f90::post_stir_12` and the SHA-pinned Python reference `tests/normative_reference.py` at blob `d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53` used the saved value in the update subtotal as well as in permutation selection. This contradicts the Hebrew Scroll's separate instructions.

The previous Fortran/Python differential therefore established agreement between two implementations sharing this defect. It did not establish canonical conformance.

## Correction and component evidence

- Commit `a855ec194ff90eb580fcbdfd50dad915fc3b1ec5` changes Fortran to retain both rawBowlSum and savedBowlSum.
- `test/stage01_scroll_stir_reference.py` is a standalone arbitrary-precision transcription of this rule from the Hebrew Scroll; it does not import or copy the pinned Python calendar implementation.
- `test/stage01_scroll_stir_probe.f90` invokes the actual Fortran `post_stir_12`.
- CI run `44959203482`, job `137014022296`: self-test 17/17; five vectors; 30/30 final bowl values exact.
- Artifact `14728313661`: SHA-256 `1986584cca056b0a8a922a415492a794cfe8dc521ddddcec07afef7491bce6c4`; downloaded and verified; ZIP CRC clean.

This is component-level evidence only. It does not independently prove the gate sequence, year selection, cutlet partition, month count and lengths, month weaving, name selection, or complete five-field date.

## Foundation-Day diagnostic contract

The next diagnostic captures the corrected Fortran output for calculationDay=targetDay=Foundation Day, without treating it as an expected answer.

- Input: the actual Fortran `foundation_day()` used as both calculation day and target day.
- Output: the five date fields, selected year gates, cutlet partition and names, month lengths and names, and the complete month-weaving sequence.
- Independent checks in the capture step: array dimensions, cutlet span, month bounds, exact weaving frequencies, first/last occurrence ordering, and projected date bounds.
- The artifact is explicitly candidate-only. It records no canonical expected tuple and cannot accept Stage 1.

## Remaining full-date oracle gap

The pinned Python reference is not suitable as a canonical full-date oracle until its other rules are independently checked against the Hebrew Scroll. After the correction, the legacy full-date comparisons fail against that reference; these mismatches are not canonical expected values. The legacy full-year probe also hard-codes the old 45-month/4,244-day structure and stops before reporting the corrected Fortran structure.

The next acceptance-quality step is a complete independent implementation derived from the Hebrew Scroll, with separately verified intermediate results for the sauce, gates, year selection, cutlets, month count and lengths, weaving, and names. No full-date tuple or full-year differential is promoted to canonical acceptance before that work is complete.

**Acceptance flag:** `full_stage1_accepted = false`.
