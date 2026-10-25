# Stage48 DISCOVERY24 — चुकीचा दिवसनिहाय month chooser

Stage47 closure [CI 40181446496](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40181446496) 2/2 SUCCESS. `TypeScript+मराठी` branch फक्त.

`legacyChooseEachDaySeparately` रोज स्वतंत्र month-ID ठरवतो, required multiplicities, प्रथम व शेवटच्या appearance चा क्रम न तपासता. तो Stage48 मध्ये जाणीवपूर्वक ऐतिहासिक चुकीचा राहतो. Corrected legal DP weaving/unrank Stage49 PATCH24 साठी राखीव. Year5000 च्या वास्तविक predecessor मध्ये Stage47 full path, Stage46 जुन्या सूचीचा खरा प्रयत्न, virtual exact month lengths व स्वतंत्र native Bowl4/Seal32 पूर्ण 58 writes यानंतरच ghost बनतो. Ghost मधील L independent day decisions या **एका** Bowl4 Seal32 पूर्ण Native query वरून तयार होतात; L स्वतंत्र Native calls असा दावा नाही.

स्वतंत्र test-only `weavingFamily([4,4,5])` च्या योग्य constraints मध्ये counts [4,4,5], पण legacy seed=1 ghost मध्ये [5,4,4]; standalone intentional EXPECTED_RED क्रमांक 24. मागील 23 ऐतिहासिक RED अपरिवर्तित. Test `discovery24.ts` मध्ये लहान सर्व legal weaving, nonzero historical mismatch, full Year5000 predecessor, native Seal32, deep fault/rollback, owner isolation व Stage54 barrier; `discovery24Properties.ts` मध्ये 720 altered DROP46 inputs वर actual Bowl3 Seal30/31 आणि Bowl4 Seal32, bounded real ghost generation. Full huge legal weaving DP production मध्ये नाही; Stage49 fix लवकर लागू नाही.

GitHub Actions Native 2/2 SUCCESS येईपर्यंत Stage48 बंद किंवा Stage49 सुरू नाही.

## Native CI ची पडताळणी — २५ ऑक्टोबर २०२६

मूळ Stage48 implementation commit [c5e46aea](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/c5e46aea790203deb8aad88d1e272a56246f0e78) व [CI 40185059418](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40185059418) मध्ये **verify** आणि **stage27-typescript-marathi** दोन्ही SUCCESS. TypeScript typecheck, Stage1–48 regression, स्वतंत्र २४वा intentional EXPECTED_RED आणि आधीचे २३ archived RED checks, frozen source names lock हे सर्व PASS.

```text
STAGE_48_DISCOVERY_24_GUARDS_PASS smallLegalRows=3101 syntheticWrong=3 realYearDays=5349 realYearMonthCount=44 realGhostWrong=1 nativeSeal32=1 realSharedWrites=3480 fullStage47=1 deepFaults=1 stage49FixApplied=0 archivedExpectedReds=23 stage54Blocked=1
STAGE_48_DISCOVERY_24_PROPERTIES_PASS distinctDrop46=720 nativeSeal30=720 nativeSeal31=720 nativeSeal32=720 historicalBlocked=720 ghostInvalid=720 ghostWrong=0 independentDailyDecisions=3851280 realSharedWrites=125280
STAGE_48_DISCOVERY_24_EXPECTED_RED_VERIFIED nonzero=1 wrongGhost=1
```

प्रत्येक बदललेल्या DROP46 संदर्भात Bowl3 Seal30, Bowl3 Seal31 आणि Bowl4 Seal32 या तीन स्वतंत्र पूर्ण native प्रश्नांमध्ये 58 shared writes आहेत; म्हणून 720×3×58 = 125280. एकूण 3851280 जुने दिवसनिहाय निर्णय हे **Native Bowl4 queries नाहीत**. छोट्या [4,4,5] family च्या 3101 वैध weaving अनुक्रमांची test-only independent normative तपासणी; वास्तविक Year5000 संदर्भात 5349-दिवसीय जुना ghost चुकीचा. Stage49 चे DPUnrankLegalWeaving लागू झाले नाही. अंतिम closure commit च्या 2/2 CI SUCCESS पूर्वी Stage49 सुरू नाही.
