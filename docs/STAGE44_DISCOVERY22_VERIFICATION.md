# Stage44 — DISCOVERY22 : जुन्या पुनरावृत्ती-नावांची Native चाचणी

## ऐतिहासिक दोष

कटलेटची सतराही कॅनॉनिकल नावे गोठवलेल्या `SourceLanguageCatalog` मधील स्थानक्रमानुसारच वापरायची. जुना नमुना एकाच नावाचा पुन्हा उपयोग करू देतो, म्हणून `LegacyRepeatingCutletNames.oldCount(K) = 17^K`. `oldUnrank(K,rank)` एकाधारित rank चे K आधार-17 अंक मोजून 1..17 स्थान निर्देशांक परत करतो. आधीचा शब्दक्रम जतन केला आहे; नवे नाव, स्थानिक भाषेचा collation किंवा नवीन distinctness नियम येथे आणला नाही.

योग्य नॉर्मेटिव्ह count हा `17!/(17-K)!` आहे. पण हा Stage45 PATCH22 मधील सुधार आहे: **Stage44 मध्ये त्याचा वापर निवडीसाठी निषिद्ध आहे.** `Discovery22RepeatedNameSelector` प्रचलित Stage29 `patch14WideChoice(c, firstDay, drops, stones, bowls, 5, 22, 17^K)` प्रत्यक्ष चालवून, त्याच जुन्या क्रमाने नावांची यादी देतो. नावे पुन्हा येत असल्यास `legacyHasRepeatedNames` फक्त स्वतंत्र diagnostic आहे; तो निकाल बदलत नाही.

## प्रत्यक्ष पूर्ववर्ती आणि मर्यादा

`Discovery22ExactGateHandler` खरे Stage43 `Patch21ExactGateHandler` पुन्हा चालवतो. Stage37 मधून signed gates, year5000(c), पहिल्या दिवसाचे खरे Sauce, Bowl2 seal20/21 आणि आवश्यक असल्यास filtered partition निर्माण होते. यानंतर स्वतंत्र Bowl5 seal22 प्रश्न विचारला जातो.

`Discovery22FullHandler` खरा पूर्ण Stage43 / Stage41 इतिहास आधी चालवतो, नंतर खऱ्या वर्षाच्या पहिल्या दिवसाच्या त्या स्रोतावर Bowl5 seal22 निवड करतो; बाहेरील semantic context सर्व पूर्ववर्ती यशस्वी झाल्यानंतरच बदलतो. Stage17 च्या नियमानुसार त्या मार्गात calculationDay = openingGateDay+1 असल्यामुळे तो exact internal gate नाही; याबाबत खोटे दावे न करता स्वतंत्र exact-gate मार्ग ठेवला आहे.

दोन्ही मार्गांत 58 वास्तविक shared-memory writes प्रत्येकी एक Seal22 प्रश्नाला आवश्यक; archive जुनी unfiltered नावांची यादी आणि सर्व 21 पूर्वीचे अपेक्षित RED पुरावे अपरिवर्तित.

## पडताळणी आणि स्वीकार निकष

`test/discovery22.ts`: 17² जुन्या lex नावांची संपूर्ण यादी आणि जुन्या K=17 अचूक मोठ्या रँकचे परीक्षण; खरा internal gate व खरा full Stage43 Route; Bowl5 seal22 चा स्वतंत्र oracle रँक; दोषाची निदर्शने; पूर्ण उशिरा fault injection, बाहेरील context rollback आणि retry, मालकी भिन्नता, Stage54 अडथळा.

`test/discovery22Properties.ts`: K=1..3 साठी संपूर्ण 17^K lex क्रम स्वतंत्र base17 unrank शी तुलना; K=4..17 प्रचंड BigInt count/rank; 720 वेगवेगळ्या DROP46 order पद्धतींमध्ये खरे Bowl5 Seal22 व 58-write chain, टेस्ट-ओरॅकलमधील post-stir व rank शी तुलना. या 720 संचांमध्ये DROP46 input बदलले जातात आणि त्यांना नैसर्गिक ऐतिहासिक source म्हणून चुकीचे संबोधलेले नाही.

`test/discovery22Red.ts` आणि `test/verifyDiscovery22ExpectedRed.mjs`: 22वा जाणीवपूर्वक अयशस्वी होणारा मूळ दोषाचा पुरावा; यशस्वी पडताळणीसाठी फक्त अपेक्षित विशिष्ट nonzero अपयश स्वीकारले जाते. सर्व 21 आधीच्या RED चाचण्या राखल्या आहेत.

केवळ दोन GitHub Actions कामे PASS झाल्यावर Stage44 पूर्ण म्हणून नोंदवायचा. Stage45 PATCH22 लवकर उघडायचा नाही. `main`, इतर भाषा-शाखा, frozen names lock आणि खासगी `HANDOFF_*` मध्ये बदल नाही. केंद्रीय `PROJECT_WORKFLOW.md` नुसार `BRANCH_REGISTRY.xlsx` ची संबंधित पंक्ती व जर्नल इतर पंक्तींना न छेडता अद्ययावत करायची.

## Native GitHub Actions पुरावे — 23 ऑक्टोबर 2026

मूळ implementation commit [908b9674](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/908b96743ebee502aaddfed4e8ba2bf813e53edd) च्या [रन 39987043398](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39987043398) मध्ये frozen names lock PASS होता, पण स्वतंत्र test-only normative reference मधील `source.stones` चा सामान्य `readonly bigint[]` प्रकार `Stone` च्या नेमक्या पाच घटकांशी जुळला नाही (TS2345, `test/discovery22Properties.ts:54`). Source fixture मध्ये असलेलाच स्वतंत्र मानक `STONES` tuple वापरणारा केवळ त्या test expression चा बदल [b7a7d302](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/b7a7d302026693d0afa01eb85c7bd4b784d4b5c0) मध्ये केला. उत्पादन स्रोत किंवा मूळ इतिहास बदलला नाही.

सुधारित commit चा [Native CI 39996594404](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39996594404) — `verify` आणि `stage27-typescript-marathi` **दोन्ही SUCCESS**. TypeScript typecheck, Stage1–44 पूर्ण regression, frozen name lock, पहिल्या 21 ऐतिहासिक अपेक्षित RED आणि 22वा स्वतंत्र अपेक्षित RED सर्व पडताळले.

```text
STAGE_44_DISCOVERY_22_GUARDS_PASS oldLexRows=289 oldRepeatedRows=1 genuineExactGate=1 nativeSeal22=1 actualRepeated=1 independentReferenceDistinct=1 fullStage43=1 fullSelectorSpy=1 exactNativeCalls=52 exactNativeWrites=3016 fullPredecessors=56 fullWrites=3248 faultCases=1 earlyPatchApplied=0
STAGE_44_DISCOVERY_22_PROPERTIES_PASS exhaustiveRows=5219 lexWrong=0 duplicateRows=850 giantRankSamples=98 giantDigits=1029 canonicalNamesDistinct=1 nativeSeal22Variations=720 distinctDrop46Orders=720 rankWrong=0 namesWrong=0 repeatedOutputs=449 uniqueOutputs=271 realSharedWrites=41760
STAGE_44_DISCOVERY_22_EXPECTED_RED_VERIFIED nonzero=1 naturalNativeWitness=1 duplicateNames=1
```

720 DROP46 vectors हे नियंत्रित बदललेले test inputs आहेत, 720 स्वतंत्र ऐतिहासिक वर्ष-प्रश्न नाहीत. जुन्या `17^K` generator ने प्रत्यक्ष 449 repeated-name outputs दिले; normative `17!/(17-K)!` family चा Stage45 उपाय Stage44 मध्ये अजिबात लावलेला नाही. Stage54 पूर्ण calendar tuple अजून बंद आहे.

ही नोंद implementation CI स्वीकारते; प्रशासकीय final commit व त्याचा स्वतंत्र CI यशस्वी झाल्यावरच `LAST_COMPLETED_STAGE=44` नोंदवायचा.
