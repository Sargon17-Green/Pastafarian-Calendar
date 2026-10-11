# टप्पा 18 — DISCOVERY 09: fixed-ID bowl pours

## ऐतिहासिक दोष व प्रत्यक्ष अंमलबजावणी

`src/discovery09LegacyFixedPours.ts` मधील `LegacyFixedBowlPoursAdapter.legacyFixedPours` ने position 1,2,3 साठी **नेहमीच bowl ID 1,2,3** वाचले. त्याला `Patch08Permutation` मधून मिळालेला योग्य order उपलब्ध असूनही fixed `oldBowls[position-1]` हीच चूक चालू आहे. तोच ऐतिहासिक method प्रत्यक्ष call केला जातो; aliases अजून लावलेले नाहीत.

Independent test-only `test/discovery09Reference.ts` मध्ये प्रत्येक position साठी `oldBowls[order[position]-1]` व `SAVE` वापरले आहेत; production मध्ये normative oracle आयात केलेले नाही. `src` मध्ये preflight validation, immutable input snapshots, legacy pours, metrics, branch trace आणि per-call context ठेवले आहेत.

## प्रमाणित पुरावे

Implementation commit `6519984eeeb2a255cdb02c0a0ccacbf35d2e4b76`. [GitHub Actions 38182044313](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38182044313): `verify` व `stage18-typescript-marathi` दोन्ही jobs PASS. TypeScript typecheck, Stages 1–18 tests, canonical lock व सर्व नऊ archived expected-red proofs यशस्वी.

```text
STAGE_18_DISCOVERY_09_GUARDS_PASS witnesses=8 cells=24 mismatches=16 matches=8
STAGE_18_DISCOVERY_09_PROPERTIES_PASS rankOrders=720 rankCells=2160 rankMatches=360 rankMismatches=1800 realPairs=12 realDrops=552 realCells=1656 realMismatches=1383 realMatches=273 giantCases=8 giantCells=24
DISCOVERY_09_EXPECTED_RED mismatches=16 matches=8 witnesses=8 cells=24
```

- सर्व 720 permutations मध्ये तीन-तीन pours = 2160 comparisons; 1800 फरक आणि 360 योगायोगाने जुळलेली positions.
- 12 normative दिन-जोड्या × 46 visible drops = 552 वास्तविक थेंब; प्रत्येक स्वतंत्र निरीक्षणात त्या दिन-जोडीच्या **initial bowls** व त्याच्या `stones[i]` वापरले. हे संपूर्ण 46-drop bowl-state evolution चे integration test नाही. 1656 cell comparisons मध्ये 1383 फरक व 273 matches.
- आठ विशाल signed bigint साक्षी/24 pour positions; exact arithmetic.
- आठ पूर्वीचे intentionally red regression proofs बदललेले नाहीत; नववा expected-red CI मध्ये जाणीवपूर्वक nonzero exit देतो.
- सुरुवातीचे दोन CI runs मध्ये test-only fixture मधील TypeScript bigint/number typing त्रुटी होत्या; त्या fixture मध्ये दुरुस्त केल्यानंतर run 38182044313 पूर्ण PASS. Historical production algorithm अपरिवर्तित.

## स्पष्ट मर्यादा

Stage 19 मध्येच `bowlAlias[position]=order[position]` द्वारे reads दुरुस्त करावेत. Stage 20 च्या in-place mutation दोषाचा शोध, Stage 21 pending/vault patch आणि Stage 54 एकत्रीकरण Stage 18 मध्ये केलेले नाही.
