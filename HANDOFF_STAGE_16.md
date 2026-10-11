# टप्पा 16 पूर्ण — टप्पा 17 साठी प्रमाणित हस्तांतरण

## वर्तमान स्थिती

- शाखा: **फक्त `TypeScript+मराठी`**; `main` आणि इतर भाषांच्या branches बदलू नका.
- एकूण टप्पे: 55; **शेवटचा पूर्ण टप्पा 16 (DISCOVERY 08)**.
- पुढील टप्पा: **17 (PATCH 08)**; एक प्रतिसाद = एकच टप्पा. Stage 18 DISCOVERY 09 आगाऊ नाही.
- Tested implementation commit: `e3a8b9307815a717001630e85dd1f3312c87c921`.
- GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38180418412 — `verify` आणि `stage16-typescript-marathi` दोन्ही PASS.
- `SourceLanguageCatalog` व `CANONICAL_NAMES_LOCK.sha256` गोठवलेले; Stage 54 पूर्वी `calendarDateSpaghetti` अंतिम दिनांक परत करत नाही.
- उत्पादन TypeScript; वापरकर्त्याशी संवाद हिब्रूमध्ये; comments, README, tests व docs मराठीत; अन्य भाषेचे artifacts/fixtures वापरू नका.

## Stage 16 मध्ये काय केले

`src/discovery08LegacyPermutation.ts`:
- `LegacyPermutationUnrankAdapter.oldPermutationUnrank0(rank0)` हा स्वतंत्र factorial/factoradic unrank helper; त्याचा **स्वतःचा** valid domain शून्याधारित `0..719`, ज्यात lexicographic `[1,2,3,4,5,6]` च्या 720 permutations अचूक मिळतात.
- ऐतिहासिक दोष फक्त caller मध्ये: `Discovery08PermutationHandler` `legacyRank0 = dropValue` असे थेट वापरतो, normalization नाही.
- `dropValue` बाहेर असल्यास helper चा `MonsterValidationError` निदानाच्या `legacyRejection="OUT_OF_RANGE"` मध्ये रूपांतरित होतो; चुकीचे उत्तर बनावट दिले जात नाही.
- स्वतंत्र per-call context/trace/metrics, frozen order, lifecycle guards, invalid input rejection.
- `test/discovery08Red.ts`: आठवा archived expected-red regression; मागचे `DISCOVERY_01_EXPECTED_RED` ते `07` अपरिवर्तित.

## GitHub Actions मधून मिळालेले पुरावे

```text
STAGE_16_DISCOVERY_08_GUARDS_PASS mismatches=10 matches=0 accepted=5 rejected=5 witnesses=10
STAGE_16_DISCOVERY_08_PROPERTIES_PASS direct=720 unique=720 cases=2880 mismatches=2880 accepted=1439 rejected=1441 giant=8
DISCOVERY_08_EXPECTED_RED mismatches=10 matches=0 rejected=5
```

- Helper च्या 720 वैध rank0 outputs सर्व unique व test-only normative `permutationUnrank1` शी अचूक.
- जुना caller 2880 candidate drops मध्ये 1439 accepted-but-wrong व 1441 rejected, zero matches.
- आठ अतिमोठ्या signed bigint values; प्रत्येकावर canonical क्रम उपलब्ध पण raw legacy rank invalid.
- TypeScript `tsc --noEmit`, Stage 1–16 guard/property suites, all eight isolated intentionally-red scripts, name lock PASS.
- आधीचा run `38180365187` test-only `TS18047` मुळे fail; explicit null guards नंतर run `38180418412` पूर्ण यशस्वी. Production behavior न बदलता फक्त tests दुरुस्त.

## पुढे Stage 17 — PATCH 08

मूळ project contract मधील **न कापता ठेवण्याची ऐतिहासिक chain**:

```text
oneBased   = regularMod(drop - 1, 720) + 1
legacyRank0 = oneBased - 1
order      = oldPermutationUnrank0(legacyRank0)
```

- वरच्या तीन स्वतंत्र टप्प्यांची अंमलबजावणी व trace/metrics ने साक्ष द्या. `regularMod(drop-1,720)` या एकाच शॉर्टकटने त्यांना पर्याय देऊ नका.
- नवे production `Patch08PermutationHandler` किंवा समतुल्य, पण **मूळ `oldPermutationUnrank0` आणि stage 16 चा चुकीचा raw-drop caller बदलू नका**. जुन्या helper ला प्रत्यक्ष call करावी.
- सर्व 720 boundaries, मोठे सकारात्मक/ऋण signed bigint, wraparound, full 720 permutations, many deterministic cases, context isolation, frozen outputs, invalid drop आणि reused state यांचे स्वतःचे tests करा.
- स्वतंत्र archival red `DISCOVERY_08_EXPECTED_RED mismatches=10 matches=0 rejected=5` व आधीचे सात archive red tests जतन करा; Stage 1–16 हिरवे राहावेत.
- फक्त Stage 17 च्या CI यशानंतर Stage 17 पूर्णत्व नोंदवा. Stage 18 च्या bowls/alias दोषाचा code या टप्प्यात नको.

पुढील प्रतिसादाच्या सुरुवातीला live GitHub branch HEAD, `DEVELOPMENT_STAGE.md`, canonical 55-stage contract, हा handoff व वर्तमान CI तपासून घ्या. अन्य संभाषण शाखा बदलत असल्यास जुनी HEAD गृहीत धरू नका.
