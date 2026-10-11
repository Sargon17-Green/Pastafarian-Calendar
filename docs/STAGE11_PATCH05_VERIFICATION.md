# टप्पा 11/55 — PATCH 05 पडताळणी

## करार, ऐतिहासिक दोष आणि स्वतंत्र दुरुस्ती

मूळ 55-टप्प्यांच्या करारात पाचव्या दोषामुळे hidden drops `hidden7, hidden6, ..., hidden1` या उलट क्रमाने साठवले जातात. Stage 10 मधील `LegacyBackwardHiddenAdapter.storeBackward` तसेच जुना दोषयुक्त `oldHiddenAt(stored,k)=stored[k-1]` **अपरिवर्तित** आहेत.

Stage 11 मधील `src/patch05Hidden.ts` या स्वतंत्र मार्गात `Patch05HiddenHandler` / `patch05HiddenDrops` समाविष्ट आहे. क्रम पुढीलप्रमाणे:

1. सात `bigint` input स्थानांची आणि वैध संदर्भ अवस्थेची पडताळणी करा.
2. Immutable मूळ input प्रत जतन करा; प्रत्यक्ष `LegacyBackwardHiddenAdapter.storeBackward` ने उलट संग्रहण तयार करा.
3. `oldHiddenAt` सातही वेळा प्रत्यक्ष बोलावून सात जुने `legacyReads` पुरावे जतन करा.
4. उलटा संग्रहण **न बदलता**, `hidden k` साठी zero-based `stored[7-k]` / one-based `8-k` वापरून सात `correctedReads` तयार करा.
5. `correctedSlotsOneBased`, जुने/नवे फरक, immutable निरीक्षण, trace, metrics आणि `PATCH_05_APPLIED` हा status नोंदवा.

म्हणून जुन्या storage चा क्रम `hidden7,...,hidden1` राहतो; ऐतिहासिक reader अजून मुद्दाम चुकतो; नवीन reader सर्व सात थेंब योग्य क्रमाने मिळवतो. `test/normativeOracle.ts` कोणत्याही उत्पादन-कोडमध्ये आयात केला नाही. `SourceLanguageCatalog`, `CANONICAL_NAMES_LOCK.sha256` आणि `main` बदललेले नाहीत.

## चाचण्यांची मर्यादा

- `test/patch05.ts`: normative oracle ने प्रत्यक्ष गणलेल्या **105 दिवस-जोड्या**, **735 थेंब**. जुना reader **630 भिन्न / 105 समान**, corrected reader विरुद्ध **0 mismatches**.
- `test/patch05Properties.ts`: **2,062** स्वतंत्र input संच, **14,434** slots; जुने/नवे परिणामांत **12,330 भिन्न / 2,104 समान**.
- सात unique values; अगदी समान सात values; palindrome; zero/negative/`M`; जास्तीतजास्त 16,384-bit `bigint`; 2048 निश्चित-बीजाचे 512-bit यादृच्छिक संच; सात एकलस्थान प्रयोग.
- दोन कॉलमधील context व input ownership isolation, freeze, दोन्ही reader चे प्रत्यक्ष निकाल, seven-slot metrics, वापरलेल्या संदर्भाचा पुनर्वापर रोखणे, अयोग्य input आणि index.
- पहिल्या GitHub CI run `38163412867` मध्ये **sparse array validation** उघड झाला: `Array.prototype.some` रिकाम्या slots वर चालत नाही. Stage 11 च्या स्वतंत्र reader व handler मध्ये प्रत्येक स्थानाच्या `typeof` ची explicit सात-स्थान तपासणी केली. Stage 10 च्या जुन्या adapter ला स्पर्श नाही.
- Stage 1–10 regressions, `calendarDateSpaghetti` अद्याप unavailable, तसेच पाच ऐतिहासिक expected-red चाचण्या जतन.

## Native CI पुरावा

- Verified implementation commit: `4892dae7211ac4d2a70ca5aa7ab9953fe5ea1486`
- Workflow run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38163510684
- `verify` — PASS; `stage11-typescript-marathi` — PASS; TypeScript typecheck — PASS.
- `STAGE_11_PATCH_05_ORACLE_PASS cases=105 slots=735 legacyDifferences=630 legacyMatches=105 mismatches=0`
- `STAGE_11_PATCH_05_PROPERTIES_PASS cases=2062 slots=14434 legacyDifferences=12330 legacyMatches=2104`
- `DISCOVERY_01_EXPECTED_RED` ते `DISCOVERY_05_EXPECTED_RED`: पाच स्वतंत्र archival tests अपेक्षित nonzero exit सहित CI मध्ये पुष्टी.

## पुढील मर्यादा

Stage 12 — `DISCOVERY 06` मध्ये `legacyPrior(dropStore,i,back)` हे जुने history function फक्त `dropStore[i-back]` वाचते आणि hidden/negative slots ओळखत नाही, हा स्वतंत्र दोष शोधायचा. Stage 13 — PATCH 06 मध्येच history slot 1 पेक्षा कमी असल्यास hidden कडे योग्य मार्गाने वळावे. Stage 12/13 ची अंमलबजावणी या Stage 11 patch मध्ये नाही. `calendarDateSpaghetti` अंतिम Stage 54 पर्यंत चालू करू नये.
