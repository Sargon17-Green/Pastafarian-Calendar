# Stage 1 — canonical Hebrew Scroll audit: twelve post-stirs

**Project:** PC-BRANCH-FORTRAN-ENGLISH  
**Baseline branch HEAD:** 6f1be87ebcf4769710bd5891086760a2e7f67cd4  
**Disposition:** component correction only; Stage 1 remains open.

## Normative authority

The governing source is the Hebrew Scroll snapshot:

- File: `Megilat_HaItim_Yehuda_FINAL_2026-09-18.md`
- SHA-256: `7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b`
- Chapter: `לוח ארבעה עשר: לבלול שתים עשרה פעמים אחר הטיפה האחרונה`
- Snapshot lines: 831–885

The English translation and implementation consensus are not allowed to override the Hebrew source.

## Exact rule

For stir number (i=1,ldots,12), let the six values at the **beginning** of the stir be (b_1,ldots,b_6), and let

[
B_i=sum_{j=1}^{6}b_j
]

The Scroll first defines (B_i) as the number of the six bowls, adds (149i), and applies SAVE. That saved value is reduced modulo 720 to select the bowl permutation. It is not the value used in the bowl-update subtotal.

For bowl (o_p) at position (p) in that permutation, with circular predecessor (o_{p-1}) and successor (o_{p+1}), the subtotal is

[
x_p=b_{o_p}+3b_{o_{p-1}}+5b_{o_{p+1}}+B_i+i+p^2
]

and the new value is

[
b'_{o_p}=operatorname{SAVE}left(x_p^2+7b_{o_{p-1}}b_{o_{p+1}}ight).
]

All six new values are installed together after the six calculations. Thus every update reads the same pre-stir state.

## Defect found in the baseline

Both the Fortran routine `test/normative_oracle_core.f90::post_stir_12` and the SHA-pinned Python reference `tests/normative_reference.py` at blob `d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53` used the saved value in the update subtotal as well as in permutation selection. That contradicts the Hebrew Scroll's separate instructions:

1. SAVE the sum plus (149i), then use that saved value to select the order.
2. Later, add the number of the six bowls (the unsaved (B_i)) to each bowl's subtotal.

The previous Fortran/Python differential therefore established agreement between two implementations sharing this defect. It did not establish canonical conformance.

## Change and test contract

- The Fortran implementation now retains both values: `rawBowlSum` for each bowl update and `savedBowlSum` only for order selection.
- `test/stage01_scroll_stir_reference.py` is a standalone, arbitrary-precision Python transcription of this specific rule from the Hebrew Scroll. It does not import or copy the pinned Python calendar implementation.
- `test/stage01_scroll_stir_probe.f90` invokes the actual Fortran `post_stir_12` routine.
- Five deterministic six-bowl vectors are compared; all 30 final bowl values must match exactly.
- The self-test checks SAVE boundaries, permutation endpoints, all 720 permutations, range invariants, and that the old saved-sum update mutant is detected by every vector.

This is a component-level oracle for the twelve post-stirs only. It does not independently prove the gate sequence, year selection, cutlet partitioning, month lengths, month weaving, or the complete five-field date.

## Remaining Stage 1 gap

The pinned Python reference is not suitable as a canonical full-date oracle until its other rules are independently checked against the Hebrew Scroll. The conflicting Foundation-Day five-field tuples remain unresolved. No full-date tuple, 45-month result, or prior differential PASS is promoted to canonical acceptance by this change.

**Acceptance flag:** `full_stage1_accepted = false`.
