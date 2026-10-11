# स्पॅगेटी विकास इतिहास

## टप्पा 1 — प्रारंभिक पाया

या मार्गाची सुरुवात शून्यापासून केली. दुसऱ्या अंमलबजावणीतून स्रोत-संहिता, चाचणी, अपेक्षित नमुना, निष्पन्न, हॅश, नोंद किंवा निर्मित माहिती घेतलेली नाही.

स्रोत-भाषा मराठी निश्चित केली आणि 17 कटलेट व 47 महिना नावांचा `SourceLanguageCatalog` स्थिर `canonicalIndex` सह गोठवला. अर्थपूर्ण नावांचे अर्थानुवाद आणि अर्थ नसलेल्या किंवा स्थळनाम असलेल्या नावांचे निर्धारक देवनागरी लिप्यंतर नोंदवले.

Appendix A वरून TypeScript मध्ये स्वतंत्र चाचणी-मात्र स्वच्छ संदर्भ तयार केला. मुख्य अंमलबजावणीत फक्त तटस्थ, प्रत्येक आवाहनासाठी स्वतंत्र संदर्भ-अवस्था, मूलभूत वितरक, पडताळणी, त्रुटी-आवरण आणि निरीक्षणीय मापन/नोंद पाया तयार केला.

या टप्प्यात कोणताही ऐतिहासिक दोष अजून निर्माण झालेला नाही आणि कोणतीही दुरुस्ती आधीच लिहिलेली नाही. त्यामुळे पुढील इतिहास या दस्तऐवजात आगाऊ लिहिलेला नाही.

## टप्पा 2 — DISCOVERY 01: ऐतिहासिक शेष-दोष

उत्पादन-मार्गात `LegacyRemainderAdapter` जोडला. तो `M = 2^127 - 1` ने नेहमीची 0..M-1 शेष-गणना करतो; `SAVE` ची 1..M जतन-गणना यात मुद्दाम वापरलेली नाही. `Discovery01RemainderHandler` मूलभूत वितरकानंतर चालतो; प्रत्येक आवाहनाची शाखा-नोंद आणि मापन स्वतंत्र असते.

नियमाधारित चाचणी-मात्र संदर्भाच्या `SAVE` विरुद्ध साक्षी `M`, `2M`, `3M`, `M+1` तपासल्या जातात. पहिल्या तीन साक्षींमध्ये अपेक्षित फरक आहे; चौथी समान आहे. `test/discovery01Red.ts` जाणूनबुजून अयशस्वी होते आणि बाकी पडताळण्या यशस्वी होणे अपेक्षित आहे.

PATCH 01 ची 0→M दुरुस्ती, नंतरचे ऐतिहासिक दोष, स्वच्छ उत्पादन-अल्गोरिदम किंवा अंतिम monster integration अजून घातलेले नाही.

GitHub Actions run 38150967363 (commit 61c345fb17b29a2113dab495928a0bc1570a077c) मध्ये TypeScript typecheck, संपूर्ण टप्पा 1 चाचण्या (`STAGE_01_PASS`), टप्पा 2 guard चाचण्या (`STAGE_02_DISCOVERY_01_GUARDS_PASS`) आणि नेमक्या तीन अपेक्षित फरकांची स्वतंत्र लाल चाचणी या सर्व पडताळण्या यशस्वी झाल्या. पुढील टप्पा 3 — PATCH 01; तो अजून सुरू केलेला नाही.

## टप्पा 3 — PATCH 01: शून्य-अवशेषाची एकमेव दुरुस्ती

`src/patch01Save.ts` मध्ये स्वतंत्र `Patch01SaveHandler` तयार केला. तो `LegacyRemainderAdapter` मधून नेहमीचा शेष घेतो; `legacyValue === 0n` हाच एकमेव सुधारणा-नियम आहे: `savedValue = M`. उर्वरित शेष, काल-दिवसांचे इनपुट आणि इतर सर्व व्यवहार तसेच ठेवले. वैध `bigint` शिवाय इतर अंक नाकारले जातात; एका context वर handler दुसऱ्यांदा चालत नाही. दुरुस्तीचे निरीक्षण `patch01.zero_repaired`, `patch01.calls` आणि `branchTrace` मधून नियमाधारित उत्तरापासून वेगळे होते.

मूळ `Discovery01RemainderHandler` आणि `test/discovery01Red.ts` बदललेले नाहीत. त्यांची मुद्दाम लाल चाचणी historical proof म्हणून CI मध्ये राखली आहे. याउलट `test/patch01.ts` चाचणीतील सर्व गणिती साक्षींनी स्वच्छ चाचणी-मात्र oracle शी जुळले पाहिजे. पोटमोजणी/भारी संख्येच्या चाचण्या आणि context विलगीकरण यामुळे पुढील टप्प्यातील बदलांनी या दुरुस्तीत चूक येऊ नये.

Stage 54 integration अजून झालेला नाही; `calendarDateSpaghetti` आता देखील `MonsterStageError` देतो.

GitHub Actions run `38151476087` ने commit `885645e013b2a28e08cd55fcec359434cdf04fc0` साठी `STAGE_03_PATCH_01_PASS cases=672 repairs=16 unchanged=656 mismatches=0` नोंदवले. `STAGE_01_PASS`, `STAGE_02_DISCOVERY_01_GUARDS_PASS mismatches=3 matches=1`, ऐतिहासिक मुद्दाम लाल साक्षी आणि SourceLanguageCatalog चा लॉकही उत्तीर्ण झाले. त्यामुळे टप्पा 3/55 पूर्ण; टप्पा 4 (PATCH 02 DISCOVERY) अद्याप सुरू नाही.

## टप्पा 4 — DISCOVERY 02: पाया-दिवस मोजणीचा ऐतिहासिक दोष

`src/discovery02LegacyDayTag.ts` मध्ये `oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY)` हे नियमाधारित `dayCount` पेक्षा वेगळे, जाणीवपूर्वक चुकीचे गणित जोडले. वास्तविक उत्पादन-मार्गात स्वतंत्र `Discovery02DayTagHandler` दोन्ही दिवसांसाठी जुन्या मोजण्या करतो; संदर्भ, branchTrace आणि metrics प्रत्येक आवाहनाचे स्वतंत्र असतात. अपवादांपूर्वी context बदलू नये म्हणून पूर्वपडताळणी आहे.

`FOUNDATION_DAY-2,-1,0,+1,+2` या साक्षींत legacy `[4,2,0,2,4]` आणि नियमानुसार `[4,2,1,3,5]` हाच फरक अपेक्षित आहे. `test/discovery02Red.ts` मध्ये 3 expected mismatches व 2 matches मिळाल्यावरच लाल चाचणी अपेक्षित आहे. मागील stages 1–3 हिरवे राहणे आवश्यक. ऐतिहासिक PATCH 02 पुढील टप्प्यातच यावा.

GitHub Actions run 38152040485 मधील commit 24a4fe867db8fd273a9d016b6d1a9e7daa33b500 साठी canonical names lock, TypeScript typecheck, Stage 01, Stage 02 guards, Stage 03 PATCH 01 (672 साक्षी; 0 भिन्नता) आणि Stage 04 guards सर्व PASS झाले. दुसऱ्या historical comparison मध्ये अचूक `DISCOVERY_02_EXPECTED_RED mismatches=3 matches=2` मिळाले; पहिला expected-red पुरावाही टिकला. यानंतरच Stage 04 पूर्ण घोषित केला. पुढील Stage 05 मध्येच PATCH 02 करायचा.

## टप्पा 5 — PATCH 02: पाया-दिवस दुरुस्ती (पडताळलेले)

`src/patch02DayTag.ts` मधील `Patch02DayTagHandler` जुना `LegacyDayTagAdapter` वापरतो; आधी `day>=FOUNDATION_DAY` साठी `+1`, आणि त्यानंतर ऐतिहासिक निष्प्रभावी `day===FOUNDATION_DAY && n!==1` ही स्वतंत्र अट ठेवतो. दोन्ही दिवसांसाठी स्वतंत्र गणना, `bigint` अचूकता, lifecycle संरक्षण, immutable result आणि observability आहेत. `src/discovery02LegacyDayTag.ts` आणि दोन्ही लाल साक्षी यांत बदल केलेला नाही.

GitHub Actions run `38153654056` (commit `7ff46fb0de35e1bf5aa837d56a3cde0d692630ca`) मधील TypeScript typecheck, Stages 01–04 regression, PATCH 01 साठी 672 साक्षी/0 फरक आणि PATCH 02 साठी **1099** दिवस-जोड्या/**2198** दिवस/0 फरक उत्तीर्ण झाले. `plusOne=1079`, `scarChecks=18`, `scarForces=0`. Canonical Names Lock व दोन्ही expected-red ऐतिहासिक चाचण्या PASS. टप्पा 5/55 पूर्ण. पुढे Stage 6 — DISCOVERY 03; Stage 7 ची PATCH 03 दुरुस्ती अद्याप नाही.

## टप्पा 7 — PATCH 03: खरे कालक्रम अंतर (प्रमाणित)

`src/patch03Distance.ts` मध्ये `Patch03DistanceHandler` आणि `patch03Distance` समाविष्ट केले. Stage 6 मधील `oldDistance` कायम ठेवून त्याची `abs(t-c)` शी तुलना केली जाते; फरक असल्यास कालक्रम मूल्य वापरले जाते; नंतर नेहमी `+1`. दोन शाखांचे स्पष्ट trace/metrics आणि प्रत्येक आवाहनाची स्वतंत्र context स्थिती जतन केली. मूळ `DISCOVERY_03_EXPECTED_RED mismatches=4 matches=1` प्रमाणित पुरावा बदललेला नाही.

QA मध्ये `Discovery03DistanceHandler` ला explicit status, invalid-context rejection आणि पुनर्वापर प्रतिबंध दिला; ऐतिहासिक गणित जसेच्या तसे राहिले. `test/discovery03Lifecycle.ts` ने हा गुण तपासला.

GitHub Actions run `38156511209` (commit `27f3d682b1ea40a5751af1fabefc092ab03f1b68`) मध्ये Stage 01–06, historical red #1–#3, TypeScript typecheck आणि canonical names lock PASS. PATCH 03 साठी **1243** जोड्या, **1214** replacements, **29** preserved, **0** mismatches मिळाले. त्यामुळे Stage 7/55 पूर्ण. पुढील Stage 8 = DISCOVERY 04; Stage 9 ची दुरुस्ती आताच केलेली नाही.

## टप्पा 8 — DISCOVERY 04: अनुक्रमिक in-place दगडांचा ऐतिहासिक दोष

`src/discovery04LegacyStones.ts` मध्ये `LegacySequentialStoneAdapter.mutateStonesWrong` ही पाच दगडांची जुनी in-place क्रिया प्रत्यक्ष लिहिली. क्रम `w,b,s,m,r`; प्रत्येक पुढील गणना चालू आवाहनात आधीच बदललेल्या दगडांवर अवलंबते. `SAVE` साठी आधीची `patch01Save` उत्पादन अंमलबजावणी वापरली, test-only oracle आयात केला नाही. `Discovery04StoneHandler` मध्ये स्वतंत्र input clone, status, trace, metrics व अपवादांसाठी पूर्वपडताळणी जोडली.

प्रारंभ `[17,29,43,71,101]` पासून `i=2` येथे जुना परिणाम `[378,1434,3780,9932,25047]`; नियमाधारित परिणाम `[378,1073,2375,6195,10493]`. यामुळे नेमक्या चार expected mismatches आणि एक match सिद्ध झाले. संपूर्ण 45-टप्प्यांच्या ऐतिहासिक श्रृंखलेतील प्रत्येक पायरी वेगळी आहे.

GitHub Actions run `38157981487` (commit `0d765f251e1ecf976d461e1180d7dc54f9361b05`) ने TypeScript typecheck, Stages 1–8 guards, 516 properties cases व 2580 values, चार historical expected-red पुरावे आणि canonical names lock सर्व PASS पुष्टी केले. Stage 8/55 पूर्ण. पुढे Stage 9 = PATCH 04; legacy call clone वर ठेवत old snapshot मधून पाच दुरुस्त मूल्ये मोजायची, परंतु हे आज केलेले नाही.

## टप्पा 9 — PATCH 04: snapshot आणि ऐतिहासिक clone mutation (प्रमाणित)

`src/patch04Stones.ts` मध्ये `Patch04StoneHandler` जोडला. `old` snapshot व mutable clone वेगळे आहेत. `LegacySequentialStoneAdapter.mutateStonesWrong` ची प्रत्यक्ष in-place call **clone वर** होते, परिणाम `legacyGarbage` म्हणून जतन होतो, आणि नंतर सर्व पाच योग्य नवे मूल्य फक्त `old` वरून मोजले जाते. जुन्या Stage 8 च्या कार्यपद्धतीत बदल नाही. Immutable result, status `PATCH_04_APPLIED`, trace, metrics, invalid input व lifecycle guards समाविष्ट केले.

Commit `e4581720a00c09ec1f7a16ff1fb70d0c05879a6e` वरील GitHub Actions run `38159106148` मध्ये सर्व jobs PASS. `test/patch04.ts` मधून 1076 cases, 5380 cells, 1076 खऱ्या legacy calls, 4304 garbage/योग्य फरक आणि oracle विरुद्ध 0 mismatches. `test/patch04Metamorphic.ts`: 301 तुलना, 1505 cells, 1204 इतिहासातील दोषांची साक्ष. आधीच्या 1–8 stages, चार historical expected-red पुरावे व canonical names lock सर्व कायम आणि पडताळलेले. म्हणून Stage 9/55 पूर्ण.

पुढे Stage 10 — DISCOVERY 05: hidden7..hidden1 या उलट साठवण क्रमाचा जुना दोष. Stage 11 मधील `hidden k` साठी `8-k` हा दुरुस्ती नियम Stage 10 मध्ये अकाली लागू करू नये.

## टप्पा 10 — DISCOVERY 05: उलट hidden storage चा ऐतिहासिक दोष

`LegacyBackwardHiddenAdapter.storeBackward` सात hidden drops `hidden7,hidden6,...,hidden1` मध्ये ठेवतो; `oldHiddenAt(stored,k)` अजून सदोष सामान्य `k-1` slot वाचतो. यात Stage 11 ची `8-k` दुरुस्ती मिसळलेली नाही. `Discovery05HiddenHandler` मध्ये स्वतंत्र validation, lifecycle, immutable observation आणि context metrics जोडले.

`test/discovery05.ts` ने test-only oracle चे 9 दिवस-जोड खरे hidden drops वापरून `54 mismatches / 9 matches` सिद्ध केले. `test/discovery05Properties.ts` ने 1,030 cases / 7,210 slots (`6,168 mismatches / 1,042 matches`), reverse-array semantics, giant BigInt, palindrome, malformed input आणि instance isolation तपासले. `test/discovery05Red.ts` हा पाचवा archive expected-red पुरावा (`6 mismatches / 1 match`) आहे.

GitHub Actions run `38160880004` (commit `1fa1054a2ba4dbd3106baf9458657614c26419ca`) मध्ये stages 1–10, TypeScript typecheck, पाच archive reds आणि canonical names lock सर्व PASS. Stage 10/55 पूर्ण. पुढील Stage 11 = PATCH 05, storage न बदलता reader मध्ये योग्य `8-k` slot वापरायचा.

## टप्पा 11 — PATCH 05: उलट hidden storage वर योग्य वाचन

`Patch05HiddenHandler` आणि `patch05HiddenDrops` उत्पादनात जोडले. सात थेंबांचा जुना `hidden7..hidden1` storage आणि `oldHiddenAt` या दोन्ही जुन्या पद्धती अविकृत आहेत. जुन्या सात reads खऱ्या legacy adapter मधून जतन होतात. सुधारित वाचन `stored[7-k]`, म्हणजे one-based `8-k`, सातही वेळा करते; `correctedSlotsOneBased`, `mismatchesRepaired`, frozen values, वैध lifecycle आणि metrics बाहेर उपलब्ध आहेत.

पहिल्या CI run `38163412867` मध्ये sparse array वर `Array.some` holes skip करत असल्याचा QA निष्कर्ष मिळाला. केवळ नवीन reader आणि handler मध्ये सातही index तपासल्यामुळे तो दोष दुरुस्त झाला; Stage 10 च्या ऐतिहासिक adapter ला स्पर्श नाही. Commit `4892dae7211ac4d2a70ca5aa7ab9953fe5ea1486` आणि run `38163510684` वर दोन्ही GitHub Actions jobs PASS.

Oracle साठी 105 जोड्या / 735 slots: जुने 630 फरक, corrected 0 mismatches; properties साठी 2,062 cases / 14,434 slots, जुने 12,330 फरक / 2,104 accidental matches. Stage 1–10 आणि 5 ऐतिहासिक expected-red पुरावे हिरवे. Stage 11/55 पूर्ण. Stage 12 = फक्त DISCOVERY 06 (`legacyPrior` hidden-history slot); Stage 13 पूर्वी patch करू नये.

## टप्पा 12 — DISCOVERY 06: hidden इतिहास न ओळखणारा visible reader

`LegacyVisiblePriorAdapter.legacyPrior(dropStore,i,back)` मध्ये मूळ `dropStore[i-back]` हाच दोषयुक्त history expression ठेवला. `Discovery06PriorHandler` ने 1-based visible `1..46`, मागील अंतर `1,3,7`, visible store snapshot, स्वतंत्र संदर्भ, metrics आणि 0/ऋण slot वर hidden history न शोधणारी branch स्पष्ट केली. `Patch06` अजून लागू नाही.

नियमाधारित `test/normativeOracle.ts` मधील `buildHiddenDrops` व `buildVisibleDrops` च्या साहाय्याने 15 boundary cases: 11 hidden mismatches, 4 visible matches. 16 दिवस-जोड्या × 46 visible × 3 history = 2,208 calls: 176 missing hidden आणि 2,032 योग्य visible. आवाहनांचे ownership, invalid input, sparse visible slots, मोठे `bigint`, Stage 1–11 regressions आणि `calendarDateSpaghetti` ची Stage 54 सीमा तपासली.

GitHub Actions run `38165814846` (commit `a727c9af88a3d576653d8db104c2a69fdb5c04eb`) मध्ये TypeScript typecheck, `verify`, `stage12-typescript-marathi`, तसेच सर्व सहा historical expected-red साक्षी PASS. Stage 12/55 पूर्ण. पुढील Stage 13 — PATCH 06: positive slot साठी legacy call आणि nonpositive slot साठी Stage 11 corrected hidden mapping; Stage 14 अजून सुरू नाही.

## टप्पा 13 — PATCH 06: दिसणाऱ्या थेंबांपासून मागे जाऊन लपवलेला इतिहास वाचणे

`LegacyVisiblePriorAdapter.legacyPrior(dropStore,i,back)` आणि `DISCOVERY_06_EXPECTED_RED` काहीही बदललेले नाहीत. `Patch06PriorHandler` मध्ये `slot>=1` असेल तेव्हा थेट खऱ्या legacy helper ची call होते; अन्यथा `hiddenK=1-slot` काढून Stage 11 च्या `correctedHiddenAt(backwardStored,hiddenK)` मधून वाचतो. `hidden7..hidden1` backward storage कायम आहे. स्वतंत्र frozen visible व hidden snapshots, semantic status, branchTrace, metrics, lifecycle व malformed input guards जोडले.

हे केवळ सहाव्या दोषासाठी आहे; पुढील grind indexing, अंतिम दिनांक किंवा Stage 54 बदललेले नाहीत. GitHub Actions run `38167061333` (commit `f4e4d260135c9bec75af5ebdcdc48b5d0da2704b`) मध्ये `verify` आणि `stage13-typescript-marathi` jobs PASS. `test/patch06.ts`: 15 boundary cases, 11 hidden व 4 legacy visible, 0 mismatches. `test/patch06Properties.ts`: 16 दिवस-जोड्या, 2208 सर्व इतिहास offsets, 176 hidden, 2032 visible, 0 mismatches; 138 giant signed bigint cases, 0 mismatches. Typecheck, 1–12 regression व सहाही ऐतिहासिक expected-red tests PASS. टप्पा 13/55 पूर्ण.

## टप्पा 14 — DISCOVERY 07: grind table चा एक-आधारित index चुकीचा वापरणे

`src/discovery07LegacyGrind.ts` मध्ये 11 वास्तविक टेबल-ओळी 0..10 या क्रमाने आहेत. `LegacyGrindTableAdapter.legacyRow(g)` मात्र (g=1..11) वापरून `table[g]` ही चुकीची पद्धत जशीच्या तशी घेतो. त्यामुळे गाळलेल्या पहिल्या ओळीऐवजी (g+1) ग्राइंडचे गुणांक वापरले जातात; (g=11) ला अजिबात ओळ नसते. जुन्या गलथान indexing ला दुरुस्त केलेले नाही; Stage 15 मध्येच index 0 ला sentinel row जोडावी.

`Discovery07GrindHandler` चा स्वतंत्र संदर्भ, फक्त valid bigint व पाच दगड असलेले input, frozen snapshots, branchTrace, metrics व missing row ची स्पष्ट नोंद समाविष्ट आहे. पहिल्या 10 चुकीच्या numeric परिणामांबरोबर शेवटचा undefined witness आणि चाचणी-मात्र नियमाधारित 11-row table विरुद्ध अपेक्षित लाल regression नोंदवला. Stage 1–13 चा कोणताही patch किंवा सहा archive red बदललेले नाहीत. GitHub Actions run `38170583590` (commit `e5a6dd6db96f24a2282c40bfd3a61bfe2c15cfc0`) मध्ये TypeScript typecheck, Stage 1–14 सर्व चाचण्या, सात intentionally-red archives आणि Canonical Names Lock PASS. 11 boundary पैकी 11 चुकीचे, शेवटची एक row गहाळ; 256×11=2816 property cases मध्ये 2816 फरक, 256 missing, 2560 shifted. 22 विशाल signed bigint calls/20 वास्तविक numeric checks उत्तीर्ण. Stage 14/55 पूर्ण; पुढील एकटाच Stage 15 — PATCH 07.
