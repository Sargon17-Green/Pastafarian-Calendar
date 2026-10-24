# Stage45 — PATCH22: वेगळी कटलेट नावे, खरा मूळ इतिहास

अंतिम Stage44 closure commit `3e5688367ac42222f68137a5432d0518323d3710` चा [CI 39998108185](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39998108185) 2/2 SUCCESS. Stage44 पूर्ण; Stage45 प्रथमच यानंतर सुरू.

## मूलभूत नियम

`src/discovery22LegacyCutletNames.ts` मधील मूळ 17^K lex repeated generator, `oldUnrank`, जुना Bowl5 Seal22 चा वास्तविक 58-write प्रश्न आणि सर्व 22 ऐतिहासिक RED न बदलता जतन. नवीन `Patch22DistinctNameFamily.count(K)` = 17!/(17-K)! आणि एक-आधारित `BigInt` unrank मध्ये frozen `canonicalIndex` 1..17 च्या lex क्रमावर नेमका prefix-block unrank; नावांची पुनरावृत्ती नाही. नवीन `Patch22NameSelection` हा Stage44 चा जुना प्रत्यक्ष ledger मागतो, त्याचा oldUnrank पुन्हा पडताळतो, नवीन N वर Bowl5 Seal22 चा स्वतंत्र पूर्ण प्रश्न चालवतो आणि केवळ पूर्ण जुना परिणाम == दुरुस्त परिणाम असतानाच मूळ array reuse करतो. जुना परिणाम authoritative होत नाही.

`Patch22ExactGateHandler` Stage44 चा सत्य Stage37 action-day gate provenance वापरतो. `Patch22FullHandler` Stage44 चा पूर्ण जुना Stage43 मार्ग स्वतंत्र context मध्ये चालवतो, आणि नंतर दुसरा corrected seal22; Stage17 च्या `calculationDay=openingGateDay+1` बंधामुळे हा full route exact gate नाही. बाहेरील semantic context ची सर्व प्रत्यक्ष दोष-इंजेक्शन नंतरच एकदाच commit; खोल fault वर rollback/retry.

## अपेक्षित acceptance

`test/patch22.ts` — guard, full आणि exact native मार्ग, स्वतंत्र normative Sauce oracle, जुना इतिहास, दोष-इंजेक्शन, frozen names, Stage54 barrier.
`test/patch22Properties.ts` — K=1..3 संपूर्ण स्वतंत्र 4,369 no-repeat lex रांगा; K=4..17 exact BigInt सीमा; 720 DROP46 order inputs वर प्रत्येकी मूळ आणि दुरुस्त खऱ्या Bowl5/Seal22 (एकूण 83,520 shared writes).

मूळ 22 EXPECTED_RED scripts अपरिवर्तित राहणे अनिवार्य. TypeScript native typecheck आणि पूर्ण Stage1–45 regression आणि canonical names lock या दोन्ही jobs PASS झाल्याशिवाय Stage45 बंद मानू नये. Stage54 पूर्ण calendar tuple बंद, `main` अपरिवर्तित. Stage46 सुरू करू नये.

## प्रत्यक्ष Native पडताळणी — 24 ऑक्टोबर 2026

अंमलबजावणी commit [dca84f898d](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/dca84f898d878ac9309753423c472da40b9c5f19) आणि [GitHub Actions 40011249527](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40011249527) मध्ये `verify` व `stage27-typescript-marathi` दोन्ही jobs **SUCCESS**. TypeScript typecheck, संपूर्ण Stage1–45 regression, 22 जुने intentioned RED आणि immutable source-language names lock पडताळले.

```text
STAGE_45_PATCH_22_GUARDS_PASS exactNativeGate=1 correctedRankMismatch=0 fullStage44=1 fullSeal22Calls=2 lateFaults=1 exactSauceCalls=53 fullSauceCalls=57 historicalDuplicatesPreserved=1 distinctOutput=1 archivedExpectedReds=22 stage54Blocked=1
STAGE_45_PATCH_22_PROPERTIES_PASS exhaustiveDistinctRows=4369 exhaustiveWrong=0 largeRankSamples=70 nativeOldPlusCorrectedSeal22=1440 distinctDrop46Orders=720 rankWrong=0 namesWrong=0 correctedLegacyReplaced=720 exactLegacyReused=0 realSharedWrites=83520
```

नवीन परत केलेल्या नावांमध्ये पुनरावृत्ती नाही; जुना `17^K` मार्ग प्रत्येक चाचणीत वास्तविक चालतो. `exactLegacyReused=0` हे फक्त 720 बदललेल्या DROP46 vectors मधील निरीक्षण आहे; K=1 सारखा समानतेचा स्वतंत्र guard देखील PASS झाला. `main`, SourceLanguageCatalog, Stage54 अपरिवर्तित. अंतिम प्रशासकीय commit चा CI तपासल्यावर Stage46 ची परवानगी लागू होईल.
