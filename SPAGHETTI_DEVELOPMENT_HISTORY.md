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
