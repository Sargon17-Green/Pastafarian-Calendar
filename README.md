# पास्ताफारी दिनदर्शिका — TypeScript आणि मराठी

हा स्वतंत्र अंमलबजावणी-मार्ग शून्यापासून तयार केला आहे. यासाठी आधीचा संग्रह, दुसऱ्या प्रोग्रामिंग भाषेतील अंमलबजावणी, दुसऱ्या स्रोत-भाषेतील अंमलबजावणी, त्यांची स्रोत-संहिता, चाचण्या, अपेक्षित नमुने, निष्पन्ने, हॅश, नोंदी किंवा निर्मित सारण्या वापरलेल्या नाहीत.

टप्पा 1/55 मधील पाया आणि टप्पा 2/55 मधील पहिल्या ऐतिहासिक दोषाचा शोध पूर्ण झाला आहे. टप्पे 1–5 पूर्ण झाले आहेत: दोन्ही ऐतिहासिक दोषांचा शोध आणि त्यांची स्वतंत्र PATCH 01/PATCH 02 दुरुस्ती. मुख्य अंमलबजावणीत पूर्ण दिनांक-अल्गोरिदम अजून जोडलेला नाही; स्वतंत्र संदर्भ-अवस्था, वितरक, पडताळणी, त्रुटी-आवरण आणि निरुपद्रवी निरीक्षणांसह पहिल्या दोन दोषांची स्वतंत्र दुरुस्ती उपलब्ध आहे. स्वच्छ नियमाधारित संदर्भ फक्त `test/` मध्ये आहे आणि मुख्य अंमलबजावणी त्याला आयात किंवा आवाहन करत नाही.

## स्थानिक तपासणी

```text
npm run typecheck
npm test
```

अपेक्षित तीन यशस्वी चाचणी-संकेत:

```text
STAGE_01_PASS
STAGE_02_DISCOVERY_01_GUARDS_PASS mismatches=3 matches=1
STAGE_03_PATCH_01_PASS cases=672 repairs=16 unchanged=656 mismatches=0
```

## स्रोत-भाषा

मानवी स्रोत-भाषा फक्त मराठी आहे. 17 कटलेट नावे आणि 47 महिना नावे `SourceLanguageCatalog` मध्ये स्थिर `canonicalIndex` सह गोठवली आहेत. अर्थ असलेली नावे अर्थानुसार मराठीत दिली आहेत; स्थळनाम किंवा जाणीवपूर्वक अर्थहीन ध्वनिसमूह निश्चित देवनागरी लिप्यंतराने दिले आहेत. क्रम, निवड, `rank`, `unrank` आणि संचय-स्मृतीच्या नियमाधारित अर्थामध्ये नावाचा मजकूर वापरला जात नाही.

## पूर्णांक नियम

सर्व नियमाधारित गणित `bigint` वर अचूक केले जाते. दशांश अंदाजाधारित गणित, wraparound overflow, saturation किंवा अंदाजाधारित संयोजन-गणना वापरलेली नाही.

## या टप्प्यात जाणीवपूर्वक नसलेले भाग

PATCH 01 आणि PATCH 02 सोडून इतर ऐतिहासिक दोष किंवा त्यावरील दुरुस्ती मुख्य अंमलबजावणीत आगाऊ घातलेली नाही. टप्पा 54 मधील अंतिम monster integration आणि टप्पा 55 मधील अंतिम लेखापरीक्षण देखील केलेले नाही.

## टप्पा 2/55 — DISCOVERY 01

स्वतंत्र उत्पादन-मार्ग `discoverLegacyRemainder(calculationDay, targetDay, value)` आधी `bootstrapMonster` ची पडताळणी करतो, नंतर जाणीवपूर्वक चुकीच्या `LegacyRemainderAdapter` मधून नेहमीची शेष-गणना करतो. प्रत्येक आवाहनाला स्वतंत्र संदर्भ, शाखा-नोंद व मापन असते. यामध्ये अद्याप नियमाधारित अंतिम दिनांक उपलब्ध नाही.

`M = 2^127 - 1` साठी ऐतिहासिक मार्ग `M`, `2M`, `3M` यांवर शून्य देतो; `SAVE` मात्र `M` देते. `M+1` वर दोन्ही 1 देतात. ही अपेक्षित लाल स्थिती केवळ ऐतिहासिक discovery मार्गात जतन केली आहे; नवीन PATCH 01 मार्गात तिची दुरुस्ती झाली आहे.

```text
npm run typecheck
npm test
npm run test:discovery01:red
```

`test:discovery01:red` ने `DISCOVERY_01_EXPECTED_RED mismatches=3 matches=1` दाखवून अयशस्वी होणे म्हणजे ऐतिहासिक दोष टिकलेला आहे, हे अपेक्षित आहे. सुरक्षित पडताळणीची `test:discovery01` चाचणी मात्र याच तीन साक्षी, शाखा-अनुक्रम आणि आवाहन-विलगीकरण तपासून यशस्वी होते.

## टप्पा 3/55 — PATCH 01

`patch01Save(calculationDay, targetDay, value)` हा नवीन, स्वतंत्र सार्वजनिक मार्ग आहे. `LegacyRemainderAdapter` चा मूळ `0..M-1` परिणाम गणला जातो आणि फक्त शून्याचा अवशेष `M` मध्ये बदलला जातो. इतर अवशेष जसाचे तसे ठेवले जातात. यामुळे `SAVE(x) = 1 + ((x-1) mod M)` हे सर्व धन, ऋण व शून्य पूर्णांकांसाठी प्राप्त होते. मुख्य अंमलबजावणी चाचणी-मात्र oracle आयात करत नाही.

`discoverLegacyRemainder` मधील मूळ चुकीचे वर्तन आणि त्याची लाल चाचणी इतिहासासाठी अपरिवर्तित आहेत. PATCH 01 च्या चाचणी-मांडणीत शून्य, ऋण-पूर्णांक, `M` च्या आसपासची अचूक सीमास्थाने, विशाल `bigint`, नियत-बीजाचे गणिती नमुने, `M`-कालिकता, स्वतंत्र context, आवाहन-क्रम, निगराणी-मोजणी आणि चुकीच्या इनपुटचा अपवाद यांचा समावेश आहे.

```text
npm run typecheck
npm test
npm run test:patch01
npm run test:discovery01:red
```

पहिले तीन आदेश यशस्वी झाले पाहिजेत; चौथा आदेश वेगळा चालविल्यास केवळ ऐतिहासिक दोषाच्या पुष्टीसाठी मुद्दाम exit 1 असतो. GitHub Actions मध्ये चौथ्या आदेशाची अपेक्षित अपयशी अवस्था स्पष्टपणे तपासली जाते. अंतिम दिनांक-मूल्य `calendarDateSpaghetti` पुढील टप्प्यांसाठी अद्याप अनुपलब्ध आहे.

**पडताळणी:** GitHub Actions run `38151476087` (commit `885645e013b2a28e08cd55fcec359434cdf04fc0`) मधील TypeScript typecheck, stage 1, stage 2, stage 3, अपेक्षित historical red आणि canonical names lock सर्व job निष्पन्ने `success` आहेत. पुढील कार्य टप्पा 4/55 — PATCH 02 DISCOVERY, त्याआधी इतर दोषाची दुरुस्ती घालू नये.

## टप्पा 4/55 — DISCOVERY 02

ऐतिहासिक `oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY)` हा सदोष दिवस-मोजणी मार्ग आता उत्पादन स्रोत-कोडमध्ये आहे. `discoverLegacyDayTags(calculationDay, targetDay)` वास्तविक dispatcher आणि handler वापरतो. दोन पाया-दिवसापूर्वीच्या साक्षी जुळतात; पाया-दिवशी आणि त्यापुढील तीन साक्षी `test/normativeOracle.ts` मधील `dayCount` पेक्षा 1 ने कमी येतात. PATCH 02 ची सुधारणा Stage 5 मधील स्वतंत्र API मध्ये उपलब्ध आहे; जुना Stage 4 discovery मार्ग अजून सदोष ठेवला आहे.

```text
npm run typecheck
npm test
npm run test:discovery02:red
```

पहिले दोन आदेश यशस्वी, तिसऱ्यात `DISCOVERY_02_EXPECTED_RED mismatches=3 matches=2` व मुद्दाम exit 1 अपेक्षित आहे. पहिल्या PATCH 01 ला आणि मूळ historical red पुराव्यांना स्पर्श केलेला नाही. दुरुस्ती Stage 5 मधील `patch02DayTags` मध्ये पूर्ण झाली आहे.

## टप्पा 5/55 — PATCH 02 (पूर्ण)

`patch02DayTags(calculationDay, targetDay)` Stage 4 च्या जुना `LegacyDayTagAdapter` ला न बदलता दोन्ही स्वतंत्र दिवसांवर अचूक `bigint` दुरुस्ती करतो. `day >= FOUNDATION_DAY` असेल तेव्हा `n += 1`; त्यानंतर `day === FOUNDATION_DAY && n !== 1` हा ऐतिहासिक निरुपद्रवी scar म्हणून स्वतंत्र `if` कायम आहे. प्रत्येक संदर्भाची branchTrace आणि metrics स्वतंत्र ठेवली आहेत; oracle फक्त `test/` मध्ये आहे.

GitHub Actions run `38153654056`: TypeScript typecheck, Stages 01–05, canonical names lock आणि दोन्ही archival expected-red चाचण्या उत्तीर्ण. `STAGE_05_PATCH_02_PASS pairs=1099 days=2198 plusOne=1079 scarChecks=18 scarForces=0 mismatches=0`.

```text
npm run typecheck
npm test
npm run test:discovery01:red
npm run test:discovery02:red
```

पहिले दोन आदेश PASS; शेवटचे दोन historical proof म्हणून मुद्दाम exit 1 देतात. CI त्यांच्या अचूक failure markers तपासतो. पूर्ण दिनांक-अंमलबजावणी अजून लागू नाही. पुढील Stage 6 मध्ये फक्त **DISCOVERY 03**, मूळ करार तपासल्यावरच करायचा; PATCH 03 Stage 7 मध्येच.

## टप्पे 6–7/55 — अंतराची तिसरी ऐतिहासिक चूक आणि PATCH 03

टप्पा 6 मध्ये `oldDistance(c,t)=abs(patchedDayTag(c)-patchedDayTag(t))` हा सदोष मार्ग, त्याचे `4 mismatches / 1 match` साक्षी आणि अपेक्षित लाल चाचणी जतन केली. टप्पा 7 मधील स्वतंत्र `patch03Distance(c,t)` आता जुना परिणाम खऱ्या `abs(t-c)` शी तुलना करतो; फरक असल्यासच दुरुस्ती करतो आणि शेवटी `+1` लावतो. जुना दोष जतन केला आहे; `calendarDateSpaghetti` अजून पुढील Stage 54 पर्यंत अनुपलब्ध आहे.

Stage 7 GitHub Actions run `38156511209`: `STAGE_07_PATCH_03_PASS pairs=1243 overridden=1214 preserved=29 mismatches=0`. TypeScript typecheck, Stage 1–6 चाचण्या, Stage 6 lifecycle QA, तीन historical expected-red आणि Canonical Names Lock सर्व PASS. तांत्रिक तपशील `docs/STAGE07_PATCH03_VERIFICATION.md` मध्ये.

पुढील टप्पा 8 — `DISCOVERY 04`: दगडांची sequential in-place legacy mutation शोधायची. PATCH 04 किंवा अंतिम integration अजून करू नये.

## टप्पा 8/55 — DISCOVERY 04 (पूर्ण)

मूळ `mutateStonesWrong` ही पाच दगडांची in-place, अनुक्रमिक mutation आता स्वतंत्र उत्पादन-मार्गात जतन आहे. `w` अद्ययावत केल्यावर लगेच `b` च्या गणनेत नवे `w` जाते; उरलेली मूल्येही अशाच क्रमाने बदलतात. नियमाधारित `test/normativeOracle.ts` मधील snapshot-आधारित परिणामापेक्षा यामुळे `i=2` येथे चार फरक दिसतात: `DISCOVERY_04_EXPECTED_RED mismatches=4 matches=1`.

`discoverLegacyStoneMutation` प्रत्येक आवाहनाची स्वतंत्र context, immutable observation, trace आणि metrics जतन करते. 45 ऐतिहासिक पायऱ्या आणि 516 स्वतंत्र properties test cases प्रमाणित. Stage 1–7 आणि चार historical expected-red पुरावे GitHub Actions run `38157981487` मध्ये PASS आहेत.

```text
npm run typecheck
npm test
npm run test:discovery04:red
```

तिसरी चाचणी हेतुपुरस्सर exit 1 देते आणि CI तिचा अचूक पुरावा तपासते. Stage 9 मध्येच old snapshot घेऊन legacy call clone वर चालवून नवी पाच मूल्ये फक्त old पासून स्वतंत्र मोजावीत. येथे ती दुरुस्ती लागू केलेली नाही. तपशील `docs/STAGE08_DISCOVERY04_VERIFICATION.md` मध्ये.

## टप्पा 9/55 — PATCH 04 (पूर्ण)

`patch04Stones(calculationDay,targetDay,index,inputStone)` ही स्वतंत्र TypeScript उत्पादन-क्रिया जुनी `mutateStonesWrong` काढून टाकत नाही. ती प्रथम `old` snapshot जतन करते, `clone` वर प्रत्यक्ष जुनी क्रमिक mutation चालवते, `legacyGarbage` जतन करते आणि मग `old` मधील पाच मूल्यांवरून पाच स्वतंत्र नियमाधारित `correctedStone` परिणाम तयार करते. मूलभूत `SAVE` Stage 3 च्याच `patch01Save` वरून येते; test-only oracle उत्पादन-कोडमध्ये नाही.

GitHub Actions run `38159106148` मध्ये Node 22 TypeScript typecheck, संपूर्ण Stage 01–09 regressions आणि चार ऐतिहासिक expected-red चाचण्या उत्तीर्ण झाल्या. `STAGE_09_PATCH_04_PASS cases=1076 cells=5380 legacyCalls=1076 overwritten=4304 mismatches=0`. स्वतंत्र 301 metamorphic तुलना देखील PASS.

```text
npm run typecheck
npm test
npm run test:discovery04:red
```

शेवटची ऐतिहासिक चाचणी हेतुपुरस्सर exit 1 देते आणि CI त्याच अपेक्षित fail marker ला स्वीकारतो. तांत्रिक पुरावा `docs/STAGE09_PATCH04_VERIFICATION.md`, पुढील हस्तांतरण `HANDOFF_STAGE_09.md` मध्ये आहे. Stage 10 मध्ये फक्त उलट क्रमाने साठवलेल्या hidden drops चा DISCOVERY 05 करावा; त्याची PATCH 05 दुरुस्ती Stage 11 पर्यंत करू नये.

## टप्पा 10/55 — DISCOVERY 05 (पूर्ण)

`src/discovery05LegacyHidden.ts` मध्ये `hidden7..hidden1` या जुन्या उलट hidden storage आणि न दुरुस्त केलेला `LegacyBackwardHiddenAdapter.oldHiddenAt` reader असलेला स्वतंत्र उत्पादन-मार्ग जोडला. `discoverLegacyHiddenStorage` प्रत्येक आवाहनासाठी स्वतंत्र context, immutable input/storage/readings, trace आणि metrics तयार करते. अजून `8-k` slot सुधारणे लागू नाही; ते Stage 11 मध्येच होईल.

Normative oracle मधील 9 दिवस-जोड्यांवर `54 mismatches / 9 matches` दिसले. इतर 1,030 property cases, 7,210 slots मध्ये `6,168 mismatches / 1,042 matches`. `DISCOVERY_05_EXPECTED_RED mismatches=6 matches=1` हा नवीन हेतुपुरस्सर लाल पुरावा इतर चार पुराव्यांबरोबर जतन झाला.

GitHub Actions run `38160880004`: TypeScript typecheck, सर्व Stage 1–10 guards, पाच ऐतिहासिक expected-red आणि canonical name lock PASS. तपशील `docs/STAGE10_DISCOVERY05_VERIFICATION.md`; पुढील मार्ग `HANDOFF_STAGE_10.md` मध्ये.

## टप्पा 11/55 — PATCH 05 (पूर्ण)

`src/patch05Hidden.ts` मधील `patch05HiddenDrops` जुने `hidden7..hidden1` storage आणि `oldHiddenAt(stored,k)=stored[k-1]` ही ऐतिहासिक चूक बदलत नाही. प्रत्यक्ष जुन्या calls चा `legacyReads` पुरावा जतन करतो आणि वेगळ्या corrected reader ने **zero-based `7-k`** अर्थात one-based `8-k` slot वरून योग्य सात `correctedReads` काढतो. Frozen input/result, context ownership, trace, metrics, अवैध index आणि sparse सात-स्थान arrays यांची खात्री केली.

GitHub Actions run `38163510684` ने Stage 01–11 regressions, TypeScript typecheck, पाच historical expected-red चाचण्या आणि canonical names lock सर्व PASS केले. 105 oracle cases / 735 slots: `630` old differences पण `0` corrected mismatches. 2,062 इतर property cases / 14,434 slots: `12,330` old differences आणि `2,104` coincidental matches.

तपशील `docs/STAGE11_PATCH05_VERIFICATION.md`; पुढील काम `HANDOFF_STAGE_11.md` मध्ये आहे. Stage 12 मध्ये hidden history slots न ओळखणारा `legacyPrior` याचा फक्त DISCOVERY 06 करावा; त्याचा PATCH 06 Stage 13 पर्यंत करू नये.

## टप्पा 12/55 — DISCOVERY 06 (पूर्ण)

`src/discovery06LegacyPrior.ts` मध्ये जुना visible-history reader `legacyPrior(dropStore,i,back)` प्रत्यक्ष `dropStore[i-back]` एवढाच वाचतो. शून्य/ऋण history slot वर hidden थेंब पाहण्याची त्याला क्षमता नाही; `discoverLegacyPrior` स्वतंत्र context, immutable visible snapshot, branchTrace, metrics आणि `undefined` legacy result जतन करतो. पुढील PATCH 06 चा hidden fallback या टप्प्यात **नाही**.

`test/discovery06.ts` ने प्रत्यक्ष normative hidden/visible oracle मधून 15 boundary witnesses तपासून `11 mismatches / 4 matches` सिद्ध केले. `test/discovery06Properties.ts` ने 16 स्वतंत्र दिवस-जोड्यांवर 46 थेंब × तीन history distances = 2,208 calls तपासल्या; `176` hidden history misses आणि `2,032` visible history matches. Stage 1–11 regressions आणि सहा archive expected-red proofs अखंड.

GitHub Actions run `38165814846`: TypeScript typecheck, `stage12-typescript-marathi`, `verify` दोन्ही PASS. पुरावा `docs/STAGE12_DISCOVERY06_VERIFICATION.md` आणि पुढील `HANDOFF_STAGE_12.md` मध्ये. Stage 13 = PATCH 06; त्यापूर्वी जुन्या reader मध्ये दुरुस्ती करू नये.

## टप्पा 13/55 — PATCH 06

`src/patch06Prior.ts` मध्ये नवीन `patch06Prior(c,t,visibleStore,backwardHidden,i,back)` प्रत्यक्ष दोन स्वतंत्र मार्गांवर काम करते. `slot=i-back` सकारात्मक असेल तर `LegacyVisiblePriorAdapter.legacyPrior` खऱ्या call ने वाचतो. `slot<=0` असेल तर `hiddenK=1-slot` साठी Stage 11 चा `Patch05HiddenHandler.correctedHiddenAt` वापरून `backwardStored[7-hiddenK]` मिळते. जुना visible reader, उलट hidden storage, सहा archived red आणि अजून न आलेले Stage 14 बदललेले नाहीत.

`npm run test:patch06` ने 15 मूलभूत साक्षी, 16 वास्तविक दिवस-जोड्या × 46 visible drops × 3 history offsets, 16,384-bit signed इनपुट, शाखेचा प्रत्यक्ष legacy call, sparse storage व lifecycle तपासावेत. `npm test` सर्व जुन्या हिरव्या चाचण्या व PATCH 06 तपासते. अंतिम कालदिनांक API Stage 54 पूर्वी अनुपलब्ध.

Stage 13 यशस्वी पडताळणी: [GitHub Actions 38167061333](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38167061333) वर `STAGE_13_PATCH_06_GUARDS_PASS` व `STAGE_13_PATCH_06_PROPERTIES_PASS`, सर्व जुन्या चाचण्या आणि सहा historical expected-red पुरावे PASS. पुढील टप्पा 14/55 — DISCOVERY 07; पुढील grind table indexing दोषाचा शोध; दुरुस्ती stage 15 पर्यंत नाही.

## टप्पा 14/55 — DISCOVERY 07

सातव्या ऐतिहासिक दोषासाठी `LegacyGrindTableAdapter` मध्ये 11 वास्तविक grind rows, पण मुद्दाम चुकीचे `legacyRow(g) = table[g]` ठेवले. (g=1..10) येथे पुढची ओळ वाचली जाते आणि (g=11) येथे `undefined` येते. `discoverLegacyGrind` हा स्वतंत्र production observation मार्ग प्रत्येक चुकीच्या index चा आणि प्रत्यक्ष गणिती परिणामाचा पुरावा ठेवतो. नियमाधारित 11-row संदर्भ फक्त `test/discovery07Fixtures.ts` मध्ये आहे; production त्याला आयात करत नाही.

`npm run test:discovery07` हा guard/property चाचण्यांचा यशस्वी आदेश आहे. `npm run test:discovery07:red` हा स्वतंत्र historical expected-red साठी मुद्दाम nonzero exit देतो. Stage 15 ची index 0 sentinel row दुरुस्ती अजून **नाही**. आधीचे सर्व टप्पे आणि Stage 54 चे अद्याप unavailable अंतिम दिनांक मार्ग अबाधित.

**टप्पा 14 पडताळणी:** [GitHub Actions 38170583590](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38170583590) वर typecheck, Stage 1–14 tests, सात archival intentional expected-red regressions आणि canonical names lock सर्व PASS. `STAGE_14_DISCOVERY_07_GUARDS_PASS mismatches=11 matches=0 missing=1 shifted=10`; `STAGE_14_DISCOVERY_07_PROPERTIES_PASS cases=2816 shifted=2560 missing=256 differences=2816 giantCases=22 giantValues=20`. Stage 15 च्या sentinel index दुरुस्तीसाठी `HANDOFF_STAGE_14.md` पहा.

## टप्पा 15/55 — PATCH 07

नवीन `patch07Grind(calculationDay,targetDay,grind,x,p1,p3,p7,stone)` हा सातव्या historical indexing दोषाचा दुरुस्त केलेला मार्ग आहे. `GRIND_TABLE_WITH_SENTINEL` मध्ये पहिली immutable `[0,0,0,0,NONE]` नोंद आहे; `g=1..11` याच **जुन्या one-based indexing** सूत्राने आता अचूक row मिळते. मूळ sentinel-विरहित `LEGACY_GRIND_TABLE` व `discoverLegacyGrind` अजिबात बदललेले नाहीत; त्यांचे ऐतिहासिक intentionally-red regression अजून चालते.

```text
npm run typecheck
npm test
npm run test:patch07
```

नव्या property चाचणीमध्ये सर्व 11 rows, deterministic signed bigint, मोठे पूर्णांक, ग्राइंडची 11-पदरी सलग साखळी, स्वतंत्र context, frozen snapshots, जुना shadow call व सर्व आधीचे patches राखले जातील. सातवे archival `test:discovery07:red` वेगळे चालविल्यास जाणीवपूर्वक nonzero exit देणे हाच अपेक्षित इतिहास-पुरावा आहे.

**Stage 15 प्रमाणित:** [GitHub Actions 38171643757](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38171643757), implementation commit `e408e87ef6e2b72733e0bccfef9e345d8bb940b3`. `STAGE_15_PATCH_07_GUARDS_PASS rows=11 shifted=10 missing=1 mismatches=0` आणि `STAGE_15_PATCH_07_PROPERTIES_PASS runs=1280 cases=14080 shifted=12800 missing=1280 mismatches=0 chains=64 chainedGrinds=704 chainMismatches=0 giantCases=22 giantMismatches=0`; आधीचे सर्व 14 टप्पे, सात archival expected-red पुरावे, frozen names lock यशस्वी. पुढे Stage 16 — फक्त DISCOVERY 08, permutation rank चा जुना दोष.

## टप्पा 16/55 — DISCOVERY 08

`oldPermutationUnrank0(rank0)` ही स्वतंत्र factoradic जुनी पद्धत फक्त `0..719` वर बरोबर आहे. `discoverLegacyPermutation(c,t,drop)` च्या historical caller मध्ये मात्र `drop` थेट `rank0` मानल्याने (1..719) मध्ये one-off permutation आणि इतर अनेक मूल्यांवर rejection होतो. `test/discovery08Red.ts` हा आठवा मुद्दाम expected-red archive पुरावा आहे. `npm run test:discovery08` मधील guards/property चाचण्या हरित असल्या पाहिजेत; archival `npm run test:discovery08:red` मुद्दाम nonzero exit देतो.

Stage 17 ची `oneBased=regularMod(drop-1,720)+1`, `legacyRank0=oneBased-1`, `oldPermutationUnrank0(legacyRank0)` ही ऐतिहासिक दुरुस्ती आज लागू केलेली नाही.

**Stage 16 पडताळणी पूर्ण:** [GitHub Actions 38180418412](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38180418412), implementation commit `e3a8b9307815a717001630e85dd1f3312c87c921`, दोन्ही jobs PASS. `STAGE_16_DISCOVERY_08_GUARDS_PASS mismatches=10 matches=0 accepted=5 rejected=5 witnesses=10`; `STAGE_16_DISCOVERY_08_PROPERTIES_PASS direct=720 unique=720 cases=2880 mismatches=2880 accepted=1439 rejected=1441 giant=8`. आठ ऐतिहासिक expected-red पुरावे राखले, जुन्या 1–15 सर्व हरित tests व Canonical Names Lock PASS. पुढील एकमेव काम Stage 17 — PATCH 08; `HANDOFF_STAGE_16.md` पहा.

## टप्पा 17/55 — PATCH 08

`patch08Permutation(calculationDay,targetDay,dropValue)` हा आठव्या historical permutation-rank दोषासाठी स्वतंत्र corrected entrypoint आहे. मूळ `oldPermutationUnrank0(rank0)` आणि चुकीचा `discoverLegacyPermutation` यांना स्पर्श नाही. तीन चरण जाणीवपूर्वक स्वतंत्र आहेत: `oneBased=regularMod(drop-1,720)+1` → `legacyRank0=oneBased-1` → `oldPermutationUnrank0(legacyRank0)`. त्यांची branch trace, metrics, frozen order व per-call state स्वतंत्र साठवली जाते.

`npm run test:patch08` मध्ये 17 canonical boundaries, पूर्ण 720 permutations, 3600 wraparound, 2048 seeded signed drops, 12 day-pairs मधील 552 नियमाधारित वास्तविक visible drops व विशाल bigint आहेत. आठही historical deliberately-red regressions अजून जपलेल्या आहेत. Stage 18 ची bowl alias दुरुस्ती **नाही**.

**टप्पा 17 प्रमाणित:** [GitHub Actions 38181219879](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38181219879) या implementation commit `1859d3823fcf51b80ee43a7368235271317bd722` साठी दोन्ही jobs PASS. `STAGE_17_PATCH_08_GUARDS_PASS cases=17 shifted=9 rejected=8 mismatches=0`; `STAGE_17_PATCH_08_PROPERTIES_PASS cases=6209 shifted=720 rejected=5489 mismatches=0 unique=720 seeded=2048 visibleDays=12 visibleCases=552 giantCases=9`. Stage 1–16 tests, आठ archival intentional-red proofs आणि Canonical Names Lock PASS. पुढील काम `HANDOFF_STAGE_17.md` मध्ये — Stage 18 फक्त DISCOVERY 09.

## टप्पा 18/55 — DISCOVERY 09 प्रमाणित

`LegacyFixedBowlPoursAdapter.legacyFixedPours` मध्ये जुन्या तीन pours साठी fixed bowls 1,2,3 वाचले जातात, जरी Stage 17 चा योग्य क्रम वेगळा असेल. सुधारित bowl alias अजून लावलेले नाही. `discoverLegacyFixedPours` मध्ये per-call frozen snapshots, trace/metrics व हा ऐतिहासिक दोष जतन केला. `test/discovery09Red.ts` हा नववा archived intentional expected-red आहे.

[GitHub Actions 38182044313](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38182044313): दोन्ही jobs PASS; पूर्ण 720 orders ×3 = 2160 comparisons, 1800 जुने mismatches/360 accidental matches; 12 day-pairs ×46 actual drops वर 1383 mismatches/273 matches; 8 giant bigint साक्षी. Stage 1–17 regressions, 9 historical expected-red आणि names lock PASS. तपशील `docs/STAGE18_DISCOVERY09_VERIFICATION.md`, पुढील `HANDOFF_STAGE_18.md`. Stage 19 च्या `bowlAlias[position]=order[position]` दुरुस्तीला आगाऊ हात घातला नाही.

## टप्पा 19/55 — PATCH 09: six-position bowl alias

नवीन `patch09Pours(c,t,i,drop,oldBowls,stone)` हा स्वतंत्र corrected मार्ग `bowlAlias[position]=order[position]` या नियमानुसार सहा स्थानांची immutable alias table तयार करतो. प्रत्यक्ष जुना `LegacyFixedBowlPoursAdapter.legacyFixedPours` method **बदललेला नाही**. Handler मूळ bowls वर त्याची ऐतिहासिक call करून जुन्या चुकीच्या तीन pours नोंदवतो, मग `oldBowls[alias[position]-1]` ने तयार केलेल्या virtual six-bowl view वर त्याच helper ला दुसरी call करून normative corrected pours मिळवतो.

`npm run test:patch09` मध्ये 8 सीमा witnesses, पूर्ण 720 permutations, 12 वास्तविक day-pairs × 46 visible drops, 2048 seeded signed values, 8 विशाल signed inputs, immutable input snapshots, real legacy invocation आणि state isolation यांची पडताळणी आहे. `npm test` सर्व Stage 1–19 green tests चालवते; सर्व नऊ `test:discoveryXX:red` हे CI मध्ये intentional nonzero exit पुरावे म्हणून जपलेले आहेत.

**Stage 19 verified:** [GitHub Actions 38212645315](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212645315), commit `616df1cad4f24a4bd596955759dc1a488cdd1a3d`, दोन्ही jobs PASS. `STAGE_19_PATCH_09_GUARDS_PASS witnesses=8 cells=24 mismatches=0 historicalWrong=16 historicalMatches=8 aliases=6 originalCalls=2`; `STAGE_19_PATCH_09_PROPERTIES_PASS cases=3328 cells=9984 mismatches=0 rankOrders=720 rankWrong=1800 rankMatches=360 realPairs=12 realDrops=552 realWrong=1383 realMatches=273 seeded=2048 giant=8`.

पुढील एकमेव टप्पा **20 — DISCOVERY 10**, जुन्या in-place bowl stir contamination चा स्वतंत्र historical error demonstration. Stage 21 मध्येच vaultOld/pending clone fix लावावा. `HANDOFF_STAGE_19.md` पहा.

## टप्पा 20/55 — DISCOVERY 10: जुनी in-place bowl contamination

`src/discovery10LegacyInPlaceStir.ts` मध्ये `LegacyInPlaceBowlStirAdapter.stirInPlace` हा जुनाच दोष दाखवणारा source मार्ग आहे: सहा positions मधून गणना करताना तो `workingBowls[id-1]` लगेच overwrite करतो आणि पुढचे `prev`/`next` reads आधीच्या writes चे बदललेले values पाहतात. त्याआधीची Stage 19 corrected pours वापरल्यामुळे या stage मध्ये मूळ in-place दोष स्वतंत्रपणे तपासता येतो. Source मध्ये Stage 21 `vaultOld`/`pending` patch अजून **नाही**.

`npm run test:discovery10` मध्ये 8 boundary witnesses, 720 permutation orders, 12 canonical day-pairs × 46 drops, अतिरिक्त 12 पूर्ण evolving 46-drop histories, 1024 seeded signed cases व 8 giant signed bigint cases आहेत. Test-only `normativeSingleStir` सर्व positions एकाच जुन्या bowl state वरून reference म्हणून मोजतो. `npm run test:discovery10:red` हे दहावे deliberately-red history script असून CI त्याचा nonzero exit अपेक्षित मानते.

**Verified:** [GitHub Actions 38214265315](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38214265315), implementation commit `57deea966018d29384ea2ad954e100f7d66a0fb5`, दोन्ही jobs PASS. 720 permutations ×6 = 4320 rows मधून 3600 historical mismatches आणि 720 योगायोगचे matches; 2304 calls ×6 = 13824 positions मध्ये 11520 mismatches, 2304 matches; 12 पूर्ण evolving sequences मध्ये 72 final bowl mismatches. दहा archived expected-red पुरावे कायम. पुढे Stage 21 PATCH 10; `HANDOFF_STAGE_20.md` वाचा.

## टप्पा 21/55 — PATCH 10: snapshot reads आणि pending commit

`patch10Stir(c,t,i,drop,bowls,stone)` हा स्वतंत्र दहावा corrected मार्ग आहे. `Patch10ShadowBowlAdapter.stage` मध्ये सहाही reads मूळ `vaultOld` snapshot वरून होतात; सहा outputs `pending` वर लिहिले जातात, आणि `commit` मधील सहा assignments हे सर्व गणित पूर्ण झाल्यावरच handler-owned destination मध्ये होतात. Input bowls किंवा इतर callers च्या state मध्ये partial write नाही. Historical `LegacyInPlaceBowlStirAdapter.stirInPlace` जुन्याप्रमाणेच चालतो; वेगळ्या private clone वर त्याची वास्तविक call करून जुनी चुकीची गणना साक्षी म्हणून साठवली जाते.

`npm run test:patch10` मध्ये सहा स्वतंत्र injected mid-stage errors, all 720 ranks, 12 actual date-pairs ×46, 12 evolving 46-step sequences, 1024 seeded signed आणि 8 giant values तपासले जातात. **[Verified run 38228198853](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228198853)**, implementation commit `5010a3c4af0d875e4195e1c8176557943531743f`: दोन्ही GitHub Actions jobs PASS, 2304 corrected calls ×6=13824 bowl checks, **0** corrected mismatches, 552 evolving steps ×6 आणि 12 final states independent normative reference शी exact; दहा archival intentionally-red tests PASS. पुढे Stage22 = DISCOVERY 11; `HANDOFF_STAGE_21.md` पहा.

## टप्पा 22/55 — DISCOVERY 11: shared permutation memory overwrites

`src/discovery11LegacyOrderMemory.ts` मध्ये `LegacySharedOrderMemoryAdapter` ची **एकच सहा-cell overwritable क्रम-स्मृती** आहे. `Discovery11OverwrittenOrderHandler` stage21 `patch10Stir` चे 46 real drop-rounds पूर्ण करतो; नंतर canonical 12 post-stirs करतो. या प्रत्येक 58 rounds मध्ये original order buffer overwrite होतो; चुकीचा `queryLegacyOrder()` अंतिम `STIR_12` order परत करतो — अपेक्षित `DROP_46` order नाही. Debug forensic ledger हा फक्त सत्यापनासाठी, query त्यातून वाचत नाही. **Stage23 latch नाही**.

`npm run test:discovery11` मध्ये 12 real date-pairs, 64 बदललेले drop1/drop46 datasets आणि 8 signed giant datasets अशा 84 पूर्ण 58-write histories, 4872 actual writes, 12 स्वतंत्र post-stir oracle traces, 29232 forensic cells, 5 injected rollback boundaries तपासले. `npm run test:discovery11:red` अकरावा historical expected-red (positions 1,2,6) nonzero exit देतो. आधीचे सर्व 10 intentionally-red scripts CI मध्ये राखले आहेत.

**Stage22 verified:** [GitHub Actions 38233277622](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38233277622), implementation commit `94f3ca8f5ab7ac440f03122889dc95ae32e87f2f`. `verify` व `stage22-typescript-marathi` SUCCESS, TypeScript native `tsc`, Stage1–22 regressions आणि 11 expected-red historical tests PASS. 84 histories च्या 252 position checks मध्ये 206 old differences/46 accidental matches, 48 all-three-position RED witnesses; 12 real day-pairs च्या 36 checks मध्ये 32 differences/4 matches. पुढे Stage23 PATCH11 फक्त drop46 order latch. `HANDOFF_STAGE_22.md` पहा.

## टप्पा 23/55 — PATCH 11: immutable DROP46 order latch

`src/patch11OrderLatch.ts` हे independent corrected production route. जुना Stage22 `Discovery11OverwrittenOrderHandler` अपरिवर्तित ठेवून त्याला पुन्हा 46 real patched bowl rounds व 12 canonical post-stirs चालवतो. Original one-buffer shared memory वर **58 actual overwrites** होतातच. `DROP_46` ची 46 वी write झाल्यावर callback मध्ये `patch08Permutation` production path कडून नेमका क्रम घेत एकदाच `Patch11Drop46LatchAdapter.captureAfterWrite` मध्ये frozen detached clone बनवतो. Corrected `queryOrder` latch वाचतो, original `queryLegacyOrder` अजून `STIR_12` order वाचतो. Diagnostic ledger semantic latch म्हणून कधीच वापरलेला नाही.

`npm run test:patch11` मध्ये 12 canonical day pairs, 64 deterministic varied drop values, 8 signed giant values आणि पूर्ण **720 unique DROP46 permutations** वापरून 804 पूर्ण sequences/46632 actual shared writes/804 latch writes तपासले जातात. **4824 corrected order comparisons, zero mismatches**; historical old-memory 2020 differences/392 accidental same जतन. Six fault-injection boundaries validate no context/input leaks.

**[GitHub Actions run 38235335198](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235335198)** `4caf392c5991d397364708adc107c936a6946eb6`: both jobs PASS, native TypeScript, full Stage1–23 regression suite, all 11 archived intentional expected-red tests and canonical name locks verified. पुढील एकमेव Stage24 `DISCOVERY 12` — numerical next-bowl successor मधील ऐतिहासिक दोष; त्याची दुरुस्ती Stage25 पर्यंत नको. `HANDOFF_STAGE_23.md` पहा.

## टप्पा 24/55 — DISCOVERY 12: स्थिर numeric नावाने next bowl निवडण्याचा जुना दोष

`src/discovery12LegacyFixedNextBowl.ts` मधील `LegacyNextBowlFixedNameAdapter.oldNextBowlFixedName(id)` हा जुना `id==6?1:id+1` नियम मुद्दाम तसाच ठेवतो. Real `patch11OrderLatch` आधीच योग्य `DROP_46` permutation स्वतंत्र clone मध्ये आणत असला, तरी ही जुनी पद्धत queried bowl ची **permutation position शोधत नाही**. नियमाधारित next bowl हा `orderAt46Latch` मध्ये queried ID नंतरचा circular ID असतो; `test/discovery12Reference.ts` स्वतंत्र test-only reference.

`npm run test:discovery12` ने 12 canonical daypairs × all six bowl IDs, 720 permutations ×6 complete successor comparisons, 804 full 46-drop+12-stir histories (46632 actual shared-memory writes), 64 deterministic variants, 8 enormous signed cases, invalid inputs, physical legacy method call आणि injected failures तपासले. `npm run test:discovery12:red` हा 12 वा deliberately-red historical script आहे: permutation `1,2,3,4,6,5` मध्ये IDs 4/5/6 सर्व three fixed-name next results चुकीचे.

**Verified [GitHub Actions 38239449544](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239449544)**, implementation `e5c03c15c7fb6b99126b2290dfa8e90ede457b4d`, दोन्ही jobs PASS: 720 orders ×6=4320 checks, old numeric wrong 3456, accidental matches 864; 12 real×6=72 full queries, 60 wrong/12 same; 804 full-run sampled queries, 629 wrong/175 same. All previous 11 archival intentionally-red tests व नवीन 12 वा independent expected-red proof retained. **Stage25 PATCH12** मध्येच correct permutation-position successor लागू करावा. `HANDOFF_STAGE_24.md` पहा.

## Stage 25 — PATCH 12 (CI पडताळणीची प्रतीक्षा)

DROP_46 च्या frozen six-bowl क्रमात विचारलेल्या ID चे स्थान शोधून त्याच्या पुढचे cyclic स्थान निवडणारा स्वतंत्र `patch12NextBowl` production मार्ग जोडला. जुना `oldNextBowlFixedName` helper बदललेला नाही: तो स्वतंत्रपणे प्रत्यक्ष invoke होतो आणि `legacyNextBowlId` म्हणून नोंदला जातो; `correctedNextBowlId` फक्त जतन केलेल्या permutation च्या स्थानावरून ठरतो. जुने 46 drops व 12 post-stirs, एकूण 58 shared writes आणि Stage23 latch पूर्ववत आहेत. 720×6 rank/ID permutations, 12 वास्तविक day-pairs, 64 बदललेले इनपुट, 8 फार मोठे integers आणि 720 rank-driven पूर्ण traces यासाठी नवीन tests/CI जोडले. GitHub Actions पूर्ण होईपर्यंत Stage24 हा शेवटचा बंद टप्पा राहील. पुढील Stage26 सुरू नाही.
