# Stage 25 — PATCH 12: अधिकृत CI पडताळणी (PASS)

Repository: `Sargon17-Green/Pastafarian-Calendar`, फक्त `TypeScript+मराठी`.
Implementation commit: [392f13a3016d3bbd3296ff6c7ab43638902dc4e7](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/392f13a3016d3bbd3296ff6c7ab43638902dc4e7).
Verification: [GitHub Actions 38242303724](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38242303724), 2026-10-12. Jobs `verify` आणि `stage25-typescript-marathi`: **SUCCESS**.

## Production correction

`src/patch12NextBowl.ts` मधील `Patch12PermutationSuccessorAdapter.nextFromLatchedPermutation` हा frozen Stage23 `orderAt46Latch` मधील queried ID चे **स्थान** शोधून पुढील cyclic स्थानावरील bowl ID परत करतो. numeric ID increment हा corrected answer काढण्यासाठी वापरत नाही. जुन्या `LegacyNextBowlFixedNameAdapter.oldNextBowlFixedName` चा स्वतंत्र वास्तविक call होतो व `legacyNextBowlId` म्हणून इतिहास राखला जातो; जुनी `src/discovery12LegacyFixedNextBowl.ts` बदललेली नाही.

`Patch12NextBowlHandler` पूर्ण `patch11OrderLatch` ची 46 real drops +12 post-stirs +58 historical shared writes चालवतो; Stage23 independent immutable latch, STIR_12 provenance, final bowl values आणि caller-state isolation कायम आहेत. `test/discovery12Reference.ts` हा test-only oracle production मध्ये import होत नाही.

## GitHub Actions मधील actual test results

```text
STAGE_25_PATCH_12_GUARDS_PASS dayPairs=12 cells=72 mismatches=0 oldWrong=60 oldMatches=12 rank2Fixed=3 legacyCalls=2 positionalCalls=2 injectedFailures=2
STAGE_25_PATCH_12_PROPERTIES_PASS orders=720 cells=4320 mismatches=0 oldWrong=3456 oldMatches=864 numericWrap=720 positionWrap=720 positionWrapOldWrong=576 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 fullMismatches=0 fullOldWrong=629 fullOldMatches=175
```

- 720 lexicographic permutations × सहा queried bowl IDs = **4320 corrected**, शून्य चुकीचे. जुन्या numeric successor मध्ये **3456 चुकीचे, 864 योगायोगाने बरोबर**; numeric ID6 wrap 720 आणि permutation-position6 wrap 720 (576 old wrong).
- 12 canonical day-pairs × सहा IDs = 72 real executions; जुन्या पद्धतीचे 60 wrong /12 same, corrected zero wrong.
- Independent full historical route: 12 canonical +64 varied +8 enormous signed bigints +720 distinct real DROP46 ranks = 804 complete histories ×58 = **46632 वास्तविक memory writes**, corrected zero mismatch; sampled old 629 wrong/175 same.
- rank2 `[1,2,3,4,6,5]`: queried IDs 4,5,6 चे सर्व तीन successors corrected. Actual methods independently spy-verified 2 old +2 corrected calls.
- Invalid IDs, sparse data/stone/bowl shapes, injected fault at legacy and corrected helper after 58 writes, retry, ownership/reentrancy आणि `calendarDateSpaghetti` Stage54 guard PASS.
- Native TypeScript `npm run typecheck`, Stage1–25 `npm test`, all 12 independently expected-nonzero intentionally red scripts, and frozen canonical names lock PASS.

## सीमारेषा

`LAST_COMPLETED_STAGE=25`. पुढचे **Stage26 DISCOVERY13** अजून सुरू नाही. काम फक्त त्याच branch मध्ये; इतर branches, `main`, frozen names किंवा आधीची intentional-red scripts बदलू नयेत.
