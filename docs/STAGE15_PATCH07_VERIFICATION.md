# टप्पा 15/55 — PATCH 07 दुरुस्ती-वस्तुस्थिती व चाचण्या

## ठरलेला ऐतिहासिक उपाय

मूळ 11-row `LEGACY_GRIND_TABLE` आणि त्याचा `legacyRow(g) = table[g]` हा चुकीचा adapter बदललेला नाही. नवी `GRIND_TABLE_WITH_SENTINEL` 12 rows ची immutable यादी आहे: index 0 = `[0n,0n,0n,0n,"NONE"]`, index 1..11 = पूर्वीच्या 11 वास्तविक rows. पूर्वीसारख्याच `table[g]` index ने योग्य row व `patch01Save` मधून normative 1..M उत्तर मिळते.

`Patch07GrindHandler` खऱ्या `LegacyGrindTableAdapter.legacyRow` च्या call मधून पूर्वीची सदोष row नोंदवतो, त्या row वर उत्तराचा अर्थ अवलंबून ठेवत नाही. Frozen input snapshot, प्रत्येक आवाहनाची metrics/branchTrace, validation before mutation, वापरलेला context पुन्हा न चालवणे हे अपेक्षित.

## स्वतंत्र तपासणीचे निकष

- `test/patch07.ts`: 11 sentinel row witnesses / 11 corrected values; 10 shifted historical rows व शेवटची एक absent historical row. 0 corrected mismatches. `STAGE_15_PATCH_07_GUARDS_PASS rows=11 shifted=10 missing=1 mismatches=0`.
- `test/patch07Properties.ts`: 1280 deterministic datasets × 11 rows = 14080 cases; जुन्या 12800 shifted व 1280 missing rows कायम, 0 corrected mismatches; 64 सलग 11-grind chains = 704 steps, 0 mismatches; 22 giant 8192-bit signed cases, 0 mismatches.
- `test/discovery07Red.ts` व मागचे सातही ऐतिहासिक expected-red पुरावे अपरिवर्तित; `DISCOVERY_07_EXPECTED_RED mismatches=11 matches=0 missing=1` जाणीवपूर्वक nonzero exit.
- Stage 1–14 regression, TypeScript typecheck, CANONICAL_NAMES_LOCK PASS.

## पुढे

Stage 16 = **DISCOVERY 08**: ऐतिहासिक 0-based permutation rank; त्या दोषाचे समाधान Stage 17 आधी करायचे नाही. Stage 54 पर्यंत संपूर्ण calendar API unavailable.

स्थिती: **PASS**. Implementation commit `e408e87ef6e2b72733e0bccfef9e345d8bb940b3` साठी [GitHub Actions run 38171643757](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38171643757) मध्ये `verify` आणि `stage15-typescript-marathi` दोन्ही jobs यशस्वी; TypeScript typecheck आणि सर्व Stage 1–15 tests PASS.

```text
STAGE_15_PATCH_07_GUARDS_PASS rows=11 shifted=10 missing=1 mismatches=0
STAGE_15_PATCH_07_PROPERTIES_PASS runs=1280 cases=14080 shifted=12800 missing=1280 mismatches=0 chains=64 chainedGrinds=704 chainMismatches=0 giantCases=22 giantMismatches=0
```

सातही `DISCOVERY_01_EXPECTED_RED` ते `DISCOVERY_07_EXPECTED_RED` हे स्वतंत्र nonzero exit tests workflow मध्ये अपेक्षित लाल इतिहास-पूरावा म्हणून PASS. Source-language catalog lock PASS.

पूर्वीच्या run 38171604091 मध्ये केवळ `test/patch07.ts` मधील type-level disjoint `actualRow !== GRIND_SENTINEL` तुलना `TS2367` मुळे typecheck अपयशी झाले; redundant तुलना काढली, मूळ logic न बदलता संपूर्ण CI पुन्हा चालवून यशस्वी झाले. पुढचा Stage 16 = DISCOVERY 08.
