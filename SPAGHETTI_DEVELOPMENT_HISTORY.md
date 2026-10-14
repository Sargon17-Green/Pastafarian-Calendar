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

## टप्पा 15 — PATCH 07: grind table चा कायम sentinel समावेश

मूळ `LEGACY_GRIND_TABLE` व `LegacyGrindTableAdapter.legacyRow(g)=table[g]` दोन्ही बदललेले नाहीत. `src/patch07Grind.ts` मध्ये `GRIND_TABLE_WITH_SENTINEL` नावाची स्वतंत्र immutable 12-ओळींची table बनवली: index 0 `[0,0,0,0,NONE]` आणि index 1..11 जुन्याच 11 खऱ्या grind rows. `Patch07GrindHandler` जुनी method प्रत्यक्ष call करून archived row नोंदवतो; दुसऱ्या टेबलवर तोच `table[g]` index वापरून एकाच grind चे अचूक `patch01Save` गणित करतो. पहिले दहा shifted rows व अकराव्या missing row चा historical shadow कायम दिसतो.

`test/patch07.ts` मध्ये sentinel immutability, 11 rows, lifecycle, खरे legacy calls, invalid inputs, ownership आणि आधीचे सहा patched व्यवहार तपासले. `test/patch07Properties.ts` मध्ये नियमाधारित स्वतंत्र test-only reference विरुद्ध नियत नमुने, क्रमाने 11 grind, मोठे signed bigint व archived discovery मार्ग जतन केला. Stage 16 चा rank दोष किंवा Stage 54 चे अंतिम integration अद्याप जोडलेले नाही. पहिल्या GitHub Actions run 38171604091 मध्ये test-only निरर्थक disjoint sentinel/actual-row तुलना TypeScript `TS2367` ने नाकारली. ती तुलना वगळल्यानंतर implementation मधील गणना न बदलता run `38171643757` (commit `e408e87ef6e2b72733e0bccfef9e345d8bb940b3`) मध्ये TypeScript typecheck, Stage 1–15 regressions, सात intentionally-red historical archive tests व Canonical Names Lock सर्व PASS. Sentinel 11 rows वर शून्य दुरुस्त फरक; properties: 1280 sets/14080 rows, 12800 जुन्या shifted, 1280 जुन्या missing, शून्य दुरुस्त फरक; 64 सलग 11-step chains/704 grinds व 22 giant cases शून्य फरक. Stage 15 पूर्ण. पुढील Stage 16 फक्त DISCOVERY 08.

## टप्पा 16 — DISCOVERY 08: 0-based rank0 मध्ये थेट drop देण्याचा जुना दोष

`src/discovery08LegacyPermutation.ts` मध्ये `LegacyPermutationUnrankAdapter.oldPermutationUnrank0(rank0)` हा जुनाच स्वतंत्र factoradic unrank कर्ता आहे; तो फक्त `0..719` या zero-based व्याप्तीत योग्य काम करतो. `Discovery08PermutationHandler` मुद्दाम raw `dropValue` थेट `legacyRank0` म्हणून देते, त्यात `mod(720)`, `drop-1`, किंवा Stage 17 ची `oneBased` chain अजिबात नाही. `0..719` मध्ये चुकीची permutation; अन्य signed/मोठ्या `bigint` वर legacy rejection आहे. Frozen immutable permutations, अचूक metrics, अपवादांपूर्वी context validation आणि स्वतंत्र state समाविष्ट आहे.

`test/discovery08.ts`, `test/discovery08Properties.ts`, `test/discovery08Red.ts` मध्ये जुना helper 720 वैध rank0 वर नियमाधारित reference शी बरोबर आहे हे प्रथम तपासले; नंतर raw drop caller चा फरक, 2880 मोठ्या प्रमाणातील cases, giant signed inputs, historical expected-red व Stage 1–15 guard तपासले. Stage 17 PATCH 08 अजून लागू नाही. पहिल्या run `38180365187` मध्ये चाचणी-मात्र nullable type narrowing वर TS18047 मिळाला; दोन्ही test files मधील guards स्पष्ट करून पुनरावृत्ती केली. GitHub Actions `38180418412` (tested commit `e3a8b9307815a717001630e85dd1f3312c87c921`) मध्ये `verify` व `stage16-typescript-marathi` PASS; TypeScript typecheck, Stages 1–16, 8 historical expected-red archives आणि name lock PASS. 720 वैध independent rank0 permutations, 2880 raw-drop cases सर्व divergent: 1439 accepted-but-wrong, 1441 rejected; 10 boundary / 5 rejected / 8 giant signed bigint पुरावे. Stage 16/55 पूर्ण.

## टप्पा 17 — PATCH 08: three-step one-based permutation normalization

`src/patch08Permutation.ts` मध्ये नवीन `Patch08PermutationHandler` प्रत्येक drop साठी तीन पायऱ्या स्वतंत्रपणे चालवतो: `oneBased=regularMod(drop-1,720)+1`, `legacyRank0=oneBased-1`, आणि मूळ `LegacyPermutationUnrankAdapter.oldPermutationUnrank0(legacyRank0)` ला प्रत्यक्ष call. `src/discovery08LegacyPermutation.ts` मधील raw-drop caller व त्याचा आठवा intentionally-red पुरावा बदललेला नाही. Branch trace, metrics, immutable order आणि semantic context नोंदले. Type-only किंवा non-bigint drop नाकारले जातात. Stage 18 चा bowls alias दोष अजून न हाताळलेला आहे.

`test/patch08.ts` मध्ये 17 boundary ranks, real helper invocation instrumentation, preflight lifecycle, context ownership व आधीचे सात patched entrypoints तपासले. `test/patch08Properties.ts` मध्ये 3600 wraparound, 2048 deterministic signed values, 12 actual day-pairs मधील 552 normative visible drops व 9 giant signed values; सर्वांशी canonical order व old helper चा प्रत्यक्ष मार्ग तपासला. पहिल्या run `38181165883` मध्ये test-only boundary witness ची चुकीची 10 shifted/7 rejected विभागणी दिसली; खरी 9/8 विभागणी tests व CI expectations मध्ये सुधारली. Production गणित तसेच राहिले. GitHub Actions run `38181219879` (commit `1859d3823fcf51b80ee43a7368235271317bd722`) मध्ये `verify`, `stage17-typescript-marathi`, TypeScript typecheck, Stage 1–17 regressions, आठ archived expected-red proofs आणि canonical names lock सर्व PASS. 17 guards/0 corrected mismatches, 6209 properties/0 corrected mismatches, 720 distinct orders, 2048 deterministic signed, 552 वास्तविक visible drops, 9 giant cases. Stage 17/55 पूर्ण; Stage 18 फक्त DISCOVERY 09.

## टप्पा 18 — DISCOVERY 09: ऐतिहासिक स्थिर कערांमधून pours

`src/discovery09LegacyFixedPours.ts` मध्ये Stage17 `patch08Permutation` चा योग्य order वेगळा नोंदवूनही जुन्या `legacyFixedPours` ने positions 1,2,3 हे थेट bowls 1,2,3 मानून वाचले. `test/discovery09Reference.ts` स्वतंत्र test-only oracle मध्ये खर्‍या `order[position]`-निर्दिष्ट bowls वापरून वास्तविक अंकगणिती फरक सिद्ध झाला. 720 permutations/2160 cells मध्ये 1800 wrong व 360 coincident. 12 normative दिन-जोड्या/552 actual visible drops वर initial bowl states च्या स्वतंत्र निरीक्षणात 1383 wrong व 273 coincident; 8 विशाल bigint साक्षी; lifecycle validation व frozen state snapshots. पहिल्या दोन GitHub runs मधील test-only fixture bigint type errors सुधारले; production historical code बदलला नाही. [GitHub Actions run 38182044313](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38182044313) मध्ये TypeScript typecheck, Stage 1–18 suites, 9 archived expected-red proofs आणि names lock सर्व PASS. Stage 18 पूर्ण. Stage 19 फक्त bowl alias patch.

## टप्पा 19 — PATCH 09: fixed bowl pour position साठी alias virtual view

Stage 18 चा `LegacyFixedBowlPoursAdapter` अजिबात न बदलता `src/patch09BowlAlias.ts` मध्ये immutable सहा-position `bowlAlias[1..6]` आणि zero sentinel तयार केले. `LegacyBowlAliasAdapter.bowlByLegacyPosition` प्रत्येक position चा actual `order[position]` bowl ID शोधतो. `Patch09BowlAliasHandler` मूळ oldBowls सह historical fixed-pour helper ला प्रत्यक्ष call करून 1,800 historical wrong / 360 coincidence आणि 552 actual drops वरील 1,383 wrong / 273 coincidences तसेच ठेवतो. त्याच जुन्या helper ला पूर्ण सहा-position alias virtual view दिल्यास तीनही corrected pours स्वतंत्र reference `normativeThreePours` शी अचूक जुळतात.

GitHub Actions [38212645315](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212645315), commit `616df1cad4f24a4bd596955759dc1a488cdd1a3d`: `verify` व `stage19-typescript-marathi` PASS; 8 ×3 boundary cells व 3,328 property cases/9,984 corrected cells, 0 corrected differences. सर्व पूर्वीचे Stage 1–18 regressions, 9 deliberately-red archived proofs व frozen Marathi names lock यशस्वी. या stage मध्ये bowl state mutation नाही. पुढे Stage 20 = DISCOVERY 10; in-place old-stir contamination स्वतंत्र निदान करायचा आहे; vaultOld/pending writes Stage 21 च्या patch आधी वापरू नयेत.

## टप्पा 20 — DISCOVERY 10: in-place mutation मध्ये नंतरच्या reads चे दूषण

Stage 19 `patch09Pours` ने pours योग्य घेतल्यावर जुना `LegacyInPlaceBowlStirAdapter.stirInPlace` सर्व सहा bowl positions वर `B[id]` तात्काळ overwrite करतो. दुसरी ते सहावी position यांमधील `B[prev]` आधी लिहिलेल्या value ला वाचते; सहाव्या position ला `B[next]` देखील आधी लिहिलेली value दिसते. त्यामुळे प्रत्येक drop वर 5 दूषित positions आणि 6 overwritten-read slots असा प्रत्यक्ष read/write trace दिसतो. `src/discovery10LegacyInPlaceStir.ts` मध्ये नेमका हाच ऐतिहासिक दोष कायम असून स्वतंत्र clone फक्त caller input ownership साठी आहे, गणनेच्या reads साठी नाही. शेजारी bowls एकाच जुन्या snapshot वरून वाचणे व `pending` लिहून commit करणे हे पुढच्या Stage 21 साठी राखले आहे.

`test/discovery10Reference.ts` मध्ये फक्त चाचणी-पुरता independent normal-form stir आहे. आठ witnesses मध्ये 40 mismatches/8 matches; सर्व 720 permutations मध्ये 3600 mismatches/720 matches; 12 canonical day-pairs ×46 visible drops वर 2760 historical single-drop wrong values. 12 संपूर्ण 46-drop histories मध्ये reference final states `applyVisibleDropsToBowls` शी जुळले आणि प्रत्येक जुन्या in-place output च्या सहा bowls वेगळ्या, एकूण 72 final differences. 1024 seeded signed cases, 8 giant signed samples; एकूण 2304 cases×6 positions = 13824, historical mismatches 11520 व matches 2304.

GitHub Actions [38214265315](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38214265315), implementation commit `57deea966018d29384ea2ad954e100f7d66a0fb5`: `verify` व `stage20-typescript-marathi` दोन्ही SUCCESS, TypeScript, stages 1–20, दहा archival intentionally-red scripts व frozen canonical names lock PASS. सुरुवातीची CI problems फक्त test-only TypeScript typing आणि instrumentation argument index मध्ये होती; old production helper बदलला नाही. Stage 20 पूर्ण; Stage 21 PATCH 10 पुढे.

## टप्पा 21 — PATCH 10: vaultOld / pending shadow आणि सहा-write commit

Stage20 `LegacyInPlaceBowlStirAdapter.stirInPlace` ची तात्काळ overwrite विधी इतिहासासाठी जतन केली. `src/patch10SnapshotStir.ts` मधील `Patch10ShadowBowlAdapter` स्वतंत्र `vaultOld`/ `pending` clones तयार करतो; सहाही bowl outputs साठी current, previous, next reads सर्व जुन्या vault वरून करतो. सहा independent pending writes नंतरच सहा-writes commit होते. Stage 19 patched pours आणि Stage 17 permutation order reused. Corrected results कोणत्याही जुन्या in-place results वर आधारित नाहीत; Stage20 चे in-place source/test archive अप्रभावित.

Verified implementation commit `5010a3c4af0d875e4195e1c8176557943531743f`, [GitHub Actions 38228198853](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228198853): `verify`, `stage21-typescript-marathi`, TypeScript, Stage1–21 green tests, दहा historical expected-red scripts व catalog lock PASS. 8 boundary witnesses (40 old wrong, 8 coincident, 0 corrected errors); 2304 property calls ×6 positions =13824 corrected comparisons, 0 mismatches, historic 11520 wrong/2304 same; 12 complete 46-step day-pair histories independent full normative oracle शी पूर्ण जुळल्या. सहाही fail-after-pending-write injected errors वेळी no partial commit/context mutation; retry exact. प्रारंभी Stage20 source tree चे integration omission आणि Node22 strip-only constructor parameter property या दोन CI अडचणी दुरुस्त केल्या. पुढचा Stage22 फक्त DISCOVERY 11 — old general order memory वर होणाऱ्या 12 post-stir overwrites चे निदान, Stage23 चे orderAt46 latch अजून नाही.

## टप्पा 22 — DISCOVERY 11: 46 व्या drop च्या क्रमाला 12 post-stirs overwrite करतात

`LegacySharedOrderMemoryAdapter` मध्ये एकाच six-cell order buffer वर 46 real corrected Stage21 bowl rounds आणि 12 normative post-stir rounds या 58 प्रत्यक्ष writes होतात. `queryLegacyOrder()` फक्त latest shared buffer वाचतो, म्हणून `STIR_12` order मिळतो; canonical `DROP_46` order मिळत नाही. Per-write immutable forensic ledger diagnostic आहे, semantic latch नाही; source मध्ये `orderAt46Latch` stage23 पूर्वी अस्तित्वात नाही. Stage21 corrected snapshot bowls जतन; STONES, Stage19 patched pours, Stage17 correct permutation वापरला. Stage 1–21 इतिहास व दहा deliberate reds सुरक्षित.

Verified [GitHub Actions 38233277622](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38233277622), commit `94f3ca8f5ab7ac440f03122889dc95ae32e87f2f`: complete TypeScript typecheck, two jobs PASS, eleven intentionally-red archives SUCCESS. 12 real canonical daypairs, positional 1/2/6 मध्ये 32 differences/4 accidental matches. 12 real + 64 modified drop1/drop46 + 8 huge signed cases = 84 पूर्ण histories, 4872 real memory writes, 29232 forensic ID cells, 206 historical mismatches/46 accidental matches, 48 पूर्ण तीन-position expected-red witnesses. Five injected mid-history failures नंतर no context/input mutation, retry deterministic. स्वतंत्र oracle ने 46-drop bowls, 12 post-stir intermediate orders आणि final bowls अचूक सिद्ध केले.

पहिल्या CI `38233130886` मधील test-only getter, static narrowing, Stone tuple typing त्रुटी `94f3ca8...` मध्ये दुरुस्त केल्या; source old-memory arithmetic तसाच. Stage 22 COMPLETE / EXPECTED_RED; पुढे Stage23 PATCH11 मध्येच once-after-drop46 latch व query reroute.

## टप्पा 23 — PATCH 11: shared order memory वरुन independent DROP46 latch

Stage22 मधील जुना `LegacySharedOrderMemoryAdapter` अजून एकच six-cell general order buffer 58 वेळा overwrite करतो: 46 drop rounds, 12 post-stirs. शेवटचा historical query `STIR_12` order वाचून चुकीचाच राहतो; 11 intentional red archives कायम. नवीन `Patch11Drop46LatchAdapter` मध्ये 46 व्या **real old memory write नंतर** Stage17 production permutation मधून मिळालेला computed `DROP_46` क्रम एकदाच private frozen detached clone मध्ये साठवला जातो. `Patch11OrderLatchHandler` आधीचा untouched Stage22 workflow child context वर पूर्ण चालवतो आणि semantic query फक्त स्वतंत्र saved snapshot मधून करतो. Ledger फक्त audit evidence, source of truth नाही. `orderAt46Latch` आणि corrected query या दोन स्वतंत्र frozen arrays आहेत.

Verified implementation `4caf392c5991d397364708adc107c936a6946eb6`, [GitHub Actions 38235335198](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235335198): `verify` आणि `stage23-typescript-marathi` SUCCESS; Stages1–23 TypeScript native QA, 11 independently expected-red archives PASS. Twelve canonical date-pairs ×3 positions: 36 corrected exact, old wrong 32/4 coincident; 84 original complete sequences historical 206 wrong/46 matches कायम. त्याव्यतिरिक्त सर्व 720 DROP46 permutation ranks tested; **804 sequences, 46632 real shared-memory writes, 804 one-time order captures, 4824 corrected six-position comparisons, zero differences**. Historical latest-memory 2020 wrong/392 accidental matches. Six deterministic pre/post-latch failure boundaries verified, no partial input/context state leaked. Next Stage24 DISCOVERY12 only; Stage25 premature patch नाही.

## टप्पा 24 — DISCOVERY 12: numerical fixed-ID successor विरुद्ध saved DROP46 permutation

Stage23 `orderAt46Latch` योग्य असतानाही `LegacyNextBowlFixedNameAdapter.oldNextBowlFixedName` हा original numeric ID increment (6→1 wrap) वापरतो; यामुळे next bowl च्या त्या permutation मधील circular position ऐवजी fixed name परिणाम मिळतो. `src/discovery12LegacyFixedNextBowl.ts` स्वतंत्र wrong production path म्हणून, Stage23 पूर्ण 58-write order-memory/latch आणि corrected bowl-history reusable; successors patch नाही. Old Stage22/Stage23 sources आणि आधीचे 11 deliberately-red tests unchanged.

Exact rank2 order `[1,2,3,4,6,5]` चे IDs 4,5,6 तीन independent historical expected-red witnesses. 720 permutation orders × six queried IDs = 4320 independent canonical successor comparisons: **3456 legacy wrong / 864 accidental same**. 720 ID6 numerical wraps and 720 permutation last-position wraps checked, last-position legacy wrong 576. Twelve normative real-day pairs ×6 =72 complete full-run queries: 60 wrong/12 same. 12 original +64 modified +8 signed huge +720 exhaustive ranks =804 full 46-drop+12-stir histories, **46632** original shared-order writes, 629 old wrong/175 same numeric results (one queried ID per full-run).

[Verified CI 38239449544](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239449544) implementation `e5c03c15c7fb6b99126b2290dfa8e90ede457b4d`: two PASS jobs, full TypeScript Stage1–24 suite and **all twelve** archival deliberately-red scripts success as expected nonzero failures, frozen canonical names lock PASS. Negative/malformed IDs and arrays, observed old function calls, injected failure and owner isolation verified. Stage24 COMPLETE/EXPECTED_RED; Stage25 PATCH12 alone shall fix permutation-position successor.

## Stage 25 PATCH 12 — verified and closed

स्थिर numeric bowl-ID successor हा जुन्या दोषाचा अंश आहे. नवीन `Patch12PermutationSuccessorAdapter` हा immutable Stage23 DROP46 latch च्या permutation position मध्ये पुढचा ID निवडतो; जुन्या `LegacyNextBowlFixedNameAdapter` चा खरा call स्वतंत्र राखला. Full 58 shared writes आणि test-only reference मधील स्वतंत्रता राखली. GitHub Actions run 38242303724 दोन्ही jobs SUCCESS. 720×6 सर्व दुरुस्त, 804 पूर्ण histories मधील शून्य corrected mismatches, 12 ऐतिहासिक intentional reds अजूनही expected nonzero; LAST_COMPLETED_STAGE=25.

## Stage 26 DISCOVERY 13 — verified and closed

मूळ biased first-answer modulo selection हा नियमाधारित rejection/wide `chooseRank` चा पर्याय नाही. नवीन historical old adapter प्रत्यक्ष चालतो; Stage25 chain आणि प्रश्न-उत्तर SAVE सूत्र जसेच्या तसे राखलेले. स्वतंत्र test-only oracle, top-of-M rejection witnesses, wide-family under-coverage, 804 genuine precursor histories व तेरावा intentional expected-red regressions जोडल्यानंतर CI verification बाकी आहे. GitHub Actions run 38246972763: दोन्ही jobs SUCCESS. 256 पैकी 255 family sizes मध्ये modulo bias; 804 full histories मध्ये canonical stream error शून्य, historical rank differences 177. 13 archived intentionally-red tests expected-nonzero. Stage26 बंद.

## Stage 27 PATCH 13 — verified and closed

Corrected rejection-sampling rank selection short/wide दोन्ही domain मध्ये स्वतंत्र production implementation; Stage26 real old modulo method unchanged and invoked, corrected full Stage25 chain reused. O(1) exact skip of +1/-1 cyclic rejected suffix avoids worst-case M iterations. Independent finite-base exhaustive brute oracle, canonical TypeScript test oracle bounded witnesses, 12 day pairs, 64 varied, eight signed-bigint, 720 rank paths. GitHub Actions run 38253073014: both CI jobs PASS, 2560 canonical short comparisons and 13926 finite-base brute-force proofs, 804 real histories with zero corrected mismatches, 13 old expected-red scripts unchanged. LAST_COMPLETED_STAGE=27.

## Stage 28 DISCOVERY 14 — verified and closed

Historical short-only choice assumes N<=M. The actual old method handles N<=M by invoking Stage27 short rejection, but for N>M it records blocked/invalid rank zero instead of hanging at zero acceptance bound. Full Stage27 production chain and old Stage26 modulo scar remain real and unchanged. Tests cover short and wide boundary discrepancies and preserve prior 13 historical reds; new 14th expected-red runs through a standalone verifier in npm test. GitHub Actions 38256920590 दोन्ही jobs SUCCESS. 2560 short cases all correct; 30 wide direct cases all blocked; 804 full runtime sequences with 238 wide blocked, 46,632 genuine shared writes. Fourteenth intentional-red verified via npm test. LAST_COMPLETED_STAGE=28; Stage29 not started.

## Stage 29 PATCH 14 — verified and closed

Stage28 short-only historical zero rank for N>M remains unchanged and actually invoked. Production dispatcher reuses the real old short result when N<=M, and for N>M physically calls the already verified Stage27 M-adic Wide Choice on the saved answer ring. It does not recompute answer digits while rejecting full composite values. Canonical independent oracle, 2560 direct short, 30 wide boundary, 804 full historical 58-write traces, fault-injected rollback and 14 archived intentional-red tests. Stage30 not started. CI run 38260956581 SUCCESS; 2560 short, 30 wide and 804 full histories, 46632 shared writes, zero corrected mismatches. Fourteen historical expected-red checks retained.

## Stage 30 DISCOVERY 15 — verified and closed

Historical gate question always selects FOUNDATION+abs(index), including negative -1,-2, instead of normative FOUNDATION-index magnitude. Every queried positive-side gap uses the real Stage29 full pipeline (58 shared-memory writes per query), and the old gate day is accumulated with signed direction. Native test-only normative GateEngine independently evaluates correct negative-side Sauce. The fifteenth historical expected-red is independently verified. Stage31 correction not yet implemented. GitHub Actions run 38265673925 both jobs SUCCESS, all 12 signed real gates and 834 authentic production predecessor runs, 48,372 writes, zero upstream disagreements, 15th historic expected red verified.

## Stage 31 PATCH15 — verified and closed

Full historical Stage30 legacy gate (F+abs(n)) is actually executed and retained. Correct signed questions use F+n or F-n with true Stage29 producer and 58 writes. On positive indices the prior correct predecessor result is reused, while negative indices add an actual separate Sauce run. Independent reference signed GateEngine, 720 permutation sequences, giant signed data, failure rollback and 15 archived RED proofs. Stage32 not started. GitHub Actions run 38270609582 both jobs SUCCESS; 12 correct signed gates, six historical negative wrong gates preserved, 1,647 full Stage29 calls, 95,526 shared writes, fifteen archived expected reds unchanged.

## Stage 32 DISCOVERY16 — verified and closed

Exact historical year maximum 5781 in an invoked old predicate, allowing 5779..5781 before the historic length-only sort and true Stage29 year seal10 selector. Actual Stage31 full signed-gate predecessor produces the gate anchor, with explicitly synthetic close-gate candidate boundaries to avoid false provenance. Fifteen prior red tests remain unchanged, sixteenth standalone expected-red full-route witness added. Stage33 correction not started. CI run 38274577638 SUCCESS on both jobs, 255 direct boundaries with 12 historical false accepts, 12 genuinely computed signed gate anchors, 792 injected selector histories, 1,659 full predecessors and 96,222 writes. Sixteenth intentional red verified.

## Stage 33 PATCH16 — verified and closed

Preserve and physically execute the original old 5781 year-bound predicate on every candidate and preserve its old sorted ledger. New real 5778 guard separately filters original-position entries BEFORE the corrected stable length-only sort and genuine seal10 year selector, with N equal to the corrected family's size. A 5781-only legacy family cannot enter the corrected selector. Full Stage31 signed opening-gate predecessor, all 16 archived intentional reds, 255 direct range cells, signed ±1..±6, 792 injected stress cases and deep rollback checks. Stage34 not started. GitHub Actions 38280247898 both jobs SUCCESS; corrected year selection excludes all >5778, with no changes to original 5781 historical helper or sixteen expected-red scripts.

## Stage 34 DISCOVERY17 — verified and closed

The original stable year-length-only comparator is actually invoked after the full Stage33 signed-gate/year selection predecessor. Equal-length candidates supplied in reverse opening-gate-day order stay reversed in old production, contradicting the independent Year5000 two-key normative ordering. All alternate candidate gate boundaries are explicitly synthetic provenance; real signed anchor and Sauce sampling are authentic. Original Stage32 5781 predicate and Stage33 corrected 5778 filter remain physical. Sixteenth prior intentionally-red tests unchanged, seventeenth expected-red full chain added. Stage35 correction not implemented. GitHub Actions 38283939340: verify and full TypeScript regression jobs SUCCESS, 256 direct wrong tie families, 12 real anchored tie witnesses, 2,463 full 58-write predecessors and 17 archival expected-red tests.

## Stage 35 PATCH17 — verified and closed

Historical Stage34 stable sort by length only is physically invoked again after the complete actual Stage34 predecessor and remains unchanged. Only maximal equal-length runs are independently reordered by earlier opening-gate day, preserving all other original ordering, stable equal opening days and the archived wrong history. A second genuine seal10 year selector runs on corrected ordering; rank is unchanged but selected candidate is corrected. Tests separately verify injected year candidate provenance versus genuinely generated signed opening gate and full preceding Sauce streams. All 17 deliberate expected-red historical proofs remain untouched. Stage36 not started. GitHub Actions 38288810264 SUCCESS on both jobs; 256 disjoint equal-length families, 12 genuine signed gates, 3,267 full predecessor calls with 189,486 writes; 17 historical expected-red scripts untouched.

## Stage 36 DISCOVERY18 — verified and closed

Historically the monster guessed a year by dividing days from the 5000-anchor first day by 365, ignoring variable year lengths. The exact old signed floorDiv method is now genuinely invoked after the entire Stage35 selection chain, and remains a ghost diagnostic without controlling a returned authoritative target year. Corrected authoritative sequential nextYear/previousYear traversal belongs strictly to Stage37, not added early. The test-only normative oracle independently checks one true gate-pair forward SEAL11 and backward SEAL12 year and exposes both wrong jump guesses. Prior 17 expected-red test scripts remain intact; 18th expected-red failure witness added. Stage37 not started. GitHub Actions 38376499660 both jobs SUCCESS; 801 floor cells, 24 authentic anchored query chains, independent test-only one-step Year5000 seed successor and predecessor reference, 3,366 full 58-write paths; 18 RED proofs preserved.

## Stage 37 PATCH18 — verified and closed

Preserves actual old /365 ghost telemetry by physically executing the complete Stage36 predecessor; does not use it for year navigation. The authoritative pathway separately reconstructs a contiguous signed-gate window by real Patch14/Stage29 Sauce questions, generates all legal Year5000 pairs, calls genuine unchanged Stage32 5781 and Stage33 5778 filters plus Stage35's real historical length-only/equal-run sort, then physically invokes seal10 for authentic Year5000. True nextYear/previousYear follow only one adjacent year at a time, sampling at the true transition gate day with seal11/12 and rejecting insufficient gate window/step budget. Previous synthetic alternative-year candidates are never treated as authentic. Stage38 not started. GitHub Actions run 38431563771 both jobs SUCCESS: physically reconstructed 68 signed gate questions, 36 full walks across four calculation days, 52 correct consecutive year transitions using SEAL11/12, 2,536 real Sauce predecessors with 147,088 writes, both old ghost calls and all 18 historic expected-red scripts retained.

## Stage 38 DISCOVERY19 — verified and closed

Historical `LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER` is represented as a genuine owned Map keyed only by BigInt `year.number`. Actual `oldGet` and `oldPut` methods use no action-day or year-open/year-close guards, exactly preserving the historical bad cache hit. Each request physically runs the entire Stage37 reconstructed-gates/Seal10/Seal11/Seal12 true-year path before asking the old Map, retaining the freshly computed record and the stale served record separately as proof. A cross-action-day same-Year5000-number HIT returns the earlier year despite genuine different bounds. Stage39 cache guards are not implemented, while prior eighteen historical expected-red witnesses remain unchanged; nineteenth expected-red verified by native CI. Stage39 not started. Both jobs of GitHub Actions 38585298407 SUCCESS; 512 signed/giant key collisions, 3 authentic Stage37 full walks with 100 real predecessors and 5800 shared writes, 19 historical expected-red witnesses preserved.

## Stage 39 PATCH19 — implementation submitted for CI

A truly executed Stage38 historical wrong year-number cache persists unmodified on the full physical Stage37 year path. New Patch19 corrected cache still uses the original `LegacyYearNumberOnlyCache.oldGet(number)` and `oldPut(number,value)`, never a compound Map key. Its sidecar record owns `calculationDayFingerprint` (exact collision-free signed BigInt hexadecimal), `openGate`, `closeGate`, and an immutable year `value`; only all-three-valid and old-slot-coherent HIT may be served. All misses physically overwrite the original number-only slot using oldPut. Original Stage38 wrong hit is preserved as historical evidence and still actually returns the old stale `served`, while the independently corrected `correctedServed` is the real Stage37 year. Tests include isolated single-guard faults, external cache tampering, preexisting unguarded slots, 512 giant signed inputs, real independent Year5000 days and old get/put/Stage37 method spies. Stage40 not begun; CI pending.
