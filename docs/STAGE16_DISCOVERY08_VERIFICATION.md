# टप्पा 16/55 — DISCOVERY 08: जुना zero-based permutation rank

## प्रत्यक्ष इतिहास

मूळ `oldPermutationUnrank0(rank0)` हा `0..719` मधील 6! क्रमचय lexicographic factoradic पद्धतीने योग्य उघडणारा कर्ता आहे. त्याचा जुना caller हा एक स्वतंत्र दोष: `dropValue` हेच थेट zero-based `rank0`. नियमानुसार `bowlOrderFromDrop(drop)` ही `1..720` normalized निवड असते; Stage 17 मध्येच हे normalization करायचे. Stage 16 मध्ये **नाही**.

## चाचणी निकष

- 720 direct legacy ranks `0..719` test-only normative `permutationUnrank1(rank0+1)` शी बरोबर, सर्व 720 unique lexicographic permutations.
- 10 boundary witness drops `-1,0,1,2,6,719,720,721,1440,M`: 10 wrong results, 0 matches, 5 rank rejections.
- `0..719`, `1..1440`, `-720..-1`: 2880 raw-drop diagnosis calls, सर्व 2880 divergent; 1439 accepted पण चुकीचा order, 1441 rejected.
- आणखी 8 अत्यंत मोठे signed bigint drops, canonical reference ordinal valid पण legacy rejection.
- योग्य legacy helper ची प्रत्यक्ष call, rejection record, context trace/metrics, frozen order, invalid inputs व repeated-use guard.
- `DISCOVERY_08_EXPECTED_RED mismatches=10 matches=0 rejected=5` हे स्वतंत्र test मुद्दाम nonzero exit देते; CI ला ते अपेक्षित आहे.
- Stages 1–15 tests आणि आधीचे 7 historical expected-red proofs अखंड.

## पुढे

Stage 17 = PATCH 08. ठरलेली chain `oneBased=regularMod(drop-1,720)+1`; `legacyRank0=oneBased-1`; `oldPermutationUnrank0(legacyRank0)`; ती कधीही थेट `regularMod(drop-1,720)` या शॉर्टकटने बदलू नये. Stage 16 मध्ये हा सुधारित production API **नाही**. Stage 54 पूर्वी `calendarDateSpaghetti` अद्याप unavailable.

स्थिती: **प्रमाणित PASS, ऐतिहासिक expected-red जाणूनबुजून कायम.** Tested implementation commit `e3a8b9307815a717001630e85dd1f3312c87c921`, [GitHub Actions run 38180418412](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38180418412). दोन्ही jobs — `verify` आणि `stage16-typescript-marathi` — PASS. TypeScript typecheck, Stage 1–16 regression, आठ archived intentional expected-red tests, canonical names lock सर्व प्रमाणित.

```text
STAGE_16_DISCOVERY_08_GUARDS_PASS mismatches=10 matches=0 accepted=5 rejected=5 witnesses=10
STAGE_16_DISCOVERY_08_PROPERTIES_PASS direct=720 unique=720 cases=2880 mismatches=2880 accepted=1439 rejected=1441 giant=8
DISCOVERY_08_EXPECTED_RED mismatches=10 matches=0 rejected=5
```

पहिला run `38180365187` मध्ये `test/discovery08.ts` आणि `test/discovery08Properties.ts` या test-only फाइलमध्ये nullable `legacyOrder` साठी `TS18047` preflight त्रुटी आल्या. त्या दोन चाचण्यांतील explicit null narrowing बदलल्यानंतर सर्व चाचण्या यशस्वी झाल्या; `src/discovery08LegacyPermutation.ts` मधील historical production arithmetic किंवा rank semantics बदलले नाहीत.

Stage 17 च्या `oneBased`/normalization chain साठी नवीन patched production route अजून लिहिलेला नाही; हा केवळ DISCOVERY 08 चा मान्यताप्राप्त checkpoint.
