# टप्पा 17 — PATCH 08: historical factoradic helper चे सुयोग्य caller normalization

## उत्पादन अंमलबजावणी

`src/patch08Permutation.ts` हा स्वतंत्र corrected path; Stage 16 च्या `LegacyPermutationUnrankAdapter.oldPermutationUnrank0` व raw-drop `Discovery08PermutationHandler` अपरिवर्तित. `oneBased=regularMod(drop-1,720)+1`; `legacyRank0=oneBased-1`; `order=oldPermutationUnrank0(legacyRank0)`. तीन स्पष्ट पायऱ्या आणि trace/metrics. Signed bigint regular modulo 0..719; legacyRank0 0..719. प्रत्येक क्रम frozen, per-call context स्वतंत्र.

## Verification goals

- `STAGE_17_PATCH_08_GUARDS_PASS cases=17 shifted=9 rejected=8 mismatches=0`.
- `STAGE_17_PATCH_08_PROPERTIES_PASS cases=6209 shifted=... rejected=... mismatches=0 unique=720 seeded=2048 visibleDays=12 visibleCases=552 giantCases=9`.
- 3600 wraparound, 2048 seeded signed, 552 actual 46-drop sequences, 9 huge signed numbers, all corrected 0 mismatches.
- 8 archived expected-red failures, Stage 1–16 regressions, TypeScript typecheck, frozen Marathi names lock intact.
- Stage 18 `DISCOVERY 09` bowl alias defect **अद्याप नको**.

स्थिती: **संपूर्ण पडताळणी PASS**. Implementation commit `1859d3823fcf51b80ee43a7368235271317bd722`; [GitHub Actions run 38181219879](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38181219879) येथे `verify` व `stage17-typescript-marathi` दोन्ही jobs `success`.

```text
STAGE_17_PATCH_08_GUARDS_PASS cases=17 shifted=9 rejected=8 mismatches=0
STAGE_17_PATCH_08_PROPERTIES_PASS cases=6209 shifted=720 rejected=5489 mismatches=0 unique=720 seeded=2048 visibleDays=12 visibleCases=552 giantCases=9
```

- 17 boundary probes मध्ये 9 पूर्वी चुकीचे स्वीकारलेले raw ranks व 8 पूर्वी नाकारलेले raw ranks. Corrected 0 mismatches.
- Property suite 6209 calls: 720 जुने shifted आणि 5489 जुने rejected; सर्व 6209 corrected outputs normative `bowlOrderFromDrop` शी जुळले.
- पूर्ण 720 distinct orders, 2048 signed deterministic samples, 552 normative visible drops (12 day pairs × 46), 9 huge signed bigint inputs.
- सगळ्या 8 historical intentionally-red scripts `DISCOVERY_01`.. `DISCOVERY_08` स्वतंत्र nonzero exit सह expected failure म्हणून CI मध्ये PASS.
- पहिला Stage 17 run `38181165883` मधील `test/patch08.ts` च्या 17 boundary partition मध्ये चुकीची अपेक्षित संख्या 10/7 लिहिलेली होती; खऱ्या 9/8 मोजणीवर test आणि workflow दुरुस्त केले. उत्पादन handler बदलला नाही.
- TypeScript typecheck, stages 1–17 पूर्ण tests आणि canonical name lock यशस्वी. पुढे फक्त Stage 18 DISCOVERY 09.
