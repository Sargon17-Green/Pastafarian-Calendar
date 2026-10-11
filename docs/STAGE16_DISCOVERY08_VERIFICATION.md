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

स्थिती: CI पडताळणी प्रलंबित. पडताळलेल्या run व commit वरच पूर्ण घोषित करावे.
