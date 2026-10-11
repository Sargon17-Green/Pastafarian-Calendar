# टप्पा 17 — PATCH 08: historical factoradic helper चे सुयोग्य caller normalization

## उत्पादन अंमलबजावणी

`src/patch08Permutation.ts` हा स्वतंत्र corrected path; Stage 16 च्या `LegacyPermutationUnrankAdapter.oldPermutationUnrank0` व raw-drop `Discovery08PermutationHandler` अपरिवर्तित. `oneBased=regularMod(drop-1,720)+1`; `legacyRank0=oneBased-1`; `order=oldPermutationUnrank0(legacyRank0)`. तीन स्पष्ट पायऱ्या आणि trace/metrics. Signed bigint regular modulo 0..719; legacyRank0 0..719. प्रत्येक क्रम frozen, per-call context स्वतंत्र.

## Verification goals

- `STAGE_17_PATCH_08_GUARDS_PASS cases=17 shifted=10 rejected=7 mismatches=0`.
- `STAGE_17_PATCH_08_PROPERTIES_PASS cases=6209 shifted=... rejected=... mismatches=0 unique=720 seeded=2048 visibleDays=12 visibleCases=552 giantCases=9`.
- 3600 wraparound, 2048 seeded signed, 552 actual 46-drop sequences, 9 huge signed numbers, all corrected 0 mismatches.
- 8 archived expected-red failures, Stage 1–16 regressions, TypeScript typecheck, frozen Marathi names lock intact.
- Stage 18 `DISCOVERY 09` bowl alias defect **अद्याप नको**.

स्थिति: GitHub Actions पडताळणी प्रलंबित; प्रमाणित run नंतरच पूर्णत्व लिहावे.
