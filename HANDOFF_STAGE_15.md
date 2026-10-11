# टप्पा 15 पूर्ण — टप्पा 16 साठी हस्तांतरण

## प्रमाणित अवस्था

- **फक्त** `TypeScript+मराठी` शाखेत काम करा. `main` बदलू नका.
- एकूण 55 टप्पे; शेवटचा पूर्ण टप्पा **15 — PATCH 07**; पुढचा **16 — DISCOVERY 08**.
- मुख्य TypeScript उत्पादन-अंमलबजावणी, चाचणी-मात्र normative oracle व मराठी frozen SourceLanguageCatalog वेगळेच ठेवावेत.
- Stage 15 सत्यापित commit: `e408e87ef6e2b72733e0bccfef9e345d8bb940b3`.
- Stage 15 GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38171643757 ; jobs `verify` आणि `stage15-typescript-marathi` दोन्ही PASS.

## Stage 15 मधील विशिष्ट सुधारणा

- `src/discovery07LegacyGrind.ts` व `test/discovery07Red.ts` **बदललेले नाहीत**: sentinel-विरहित 11-row `LEGACY_GRIND_TABLE` व चुकीचे `legacyRow(g)=table[g]` मूळच आहेत.
- `src/patch07Grind.ts` मध्ये `GRIND_SENTINEL=[0n,0n,0n,0n,"NONE"]` आणि `GRIND_TABLE_WITH_SENTINEL=[GRIND_SENTINEL,...LEGACY_GRIND_TABLE]`; frozen 12 rows.
- `Patch07GrindHandler.oneBasedRow(g)` मध्ये जुनेच `table[g]` indexing; आता g=1..11 वर 11 वास्तविक rows. `Patch07GrindHandler.run` मूळ `LegacyGrindTableAdapter.legacyRow(g)` ला **खरी** call करून shifted/missing historical shadow राखतो; उत्तरासाठी बरोबर sentinel-table row वापरतो; `patch01Save` मधून अचूक `SAVE`.
- Per-call `MonsterContext`, frozen stone snapshots, metrics, trace, preflight input validation आणि reused-context rejection.
- आधीच्या Stages 1–14 च्या हिरव्या regression आणि सात historical deliberately red पुरावे जतन.

## पडताळणी

```text
STAGE_15_PATCH_07_GUARDS_PASS rows=11 shifted=10 missing=1 mismatches=0
STAGE_15_PATCH_07_PROPERTIES_PASS runs=1280 cases=14080 shifted=12800 missing=1280 mismatches=0 chains=64 chainedGrinds=704 chainMismatches=0 giantCases=22 giantMismatches=0
```

- 11 मूलभूत grind row साक्षी; 10 जुने shifted व एक जुनी missing row.
- 1280 संच × 11 = 14080 corrected table/semantic checks; सर्व 0 फरक.
- 64 सलग 11-grind साखळ्या = 704 steps; 0 फरक; 22 giant signed bigint cases; 0 फरक.
- `DISCOVERY_01_EXPECTED_RED` ते `DISCOVERY_07_EXPECTED_RED` या सात archival expected-red checks workflow ने independent nonzero exit सह PASS केल्या.
- पहिले CI run `38171604091` मध्ये test-only `TS2367` आले; redundant literal-comparison काढल्यावर run `38171643757` पूर्ण हिरवा. Production patch च्या गणनेत बदल नव्हता.

## टप्पा 16 — पुढील एकमेव काम

1. GitHub branch ची **ताजी HEAD** आणि `DEVELOPMENT_STAGE.md` पहा; समांतर संभाषणामुळे शाखा पुढे गेली असू शकते.
2. मूळ 55-stage/26-patch project contract तपासा. Stage 16 = **DISCOVERY 08**, ऐतिहासिक permutation rank चा 0-based दोष.
3. फक्त जुन्या `oldPermutationUnrank0(rank0)` व त्याच्या expected-red divergence चे स्वतंत्र production diagnosis आणि regression यांचे काम करा. Stage 17 चा repair chain लागू करू नका: `oneBased=regularMod(drop-1,720)+1`; `legacyRank0=oneBased-1`; `oldPermutationUnrank0(legacyRank0)` हा भविष्यातील Stage 17 साठी.
4. Stage 1–15 सर्व green regression व सात जुने intentional-red archives अबाधित. Stage 16 मध्ये आठवा expected-red जोडा.
5. SourceLanguageCatalog frozen नावांचा lock, `calendarDateSpaghetti` चे Stage 54 पूर्वीचे `MonsterStageError`, code ownership आणि Marathi टिप्पण्या जतन.
6. एका प्रतिसादात **एकच टप्पा**; Stage 16 चा CI expected-red पुरावा तपासल्यानंतरच stage पूर्ण घोषित करा.

वापरकर्त्याने सध्या काहीही स्थानिक कृती करायची नाही.
