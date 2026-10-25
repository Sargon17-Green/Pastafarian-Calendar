# Stage47 PATCH23 — आभासी महिन्यांच्या लांबी, ऐतिहासिक यादी कायम

## नियम

Stage46 मधील `LegacyAllMonthLengthWays.oldAllWays`, वास्तविक Bowl3 Seal30, सुरक्षित मर्यादेतील प्रत्यक्ष जुन्या यादींचे materialization, `LegacyMonthListLimit` आणि 23 आधीचे intentionally-red पुरावे जतन. नवीन `VirtualLegacyList(L,m)` च्या `count()` मध्ये 4..123 मधील bounded compositions ची अचूक BigInt DP sliding-window recurrence आहे; `itemAt1(rank)` मूळ ascending lex order चा 1-based suffix-block unrank आहे. प्रचंड family RAM मध्ये enumeration नाही. Test-only normative oracle उत्पादनात import होत नाही.

`Patch23FullHandler` पूर्ण Stage46 historical predecessor स्वतंत्र owner मध्ये प्रत्यक्ष चालवतो. Stage17 `calculationDay=openingGateDay+1` अट कायम. Stage41 true first-day Sauce वर नवीन Bowl3 Seal31 चा पूर्ण 58-write native प्रश्न normative DP family count ने चालतो. जुनी पूर्ण materialized रचना उपलब्ध असल्यास ती फक्त पूर्ण बरोबरीवर reuse; historical blocked किंवा चुकीची निवड authoritative नाही. Fault नंतर caller च्या semantic state मध्ये बदल नाही.

## स्वीकार निकष

`test/patch23.ts` मध्ये लहान lex families exhaustive old-vs-virtual-vs-independent oracle, 5349 दिवसांच्या 44 महिन्यांच्या प्रत्यक्ष family ची 956989856157389440798554542400 exact count आणि first/middle/last rank, full Stage46 chain, fault, retry, owner isolation, Stage54 barrier. `test/patch23Properties.ts` मध्ये 720 DROP46 input changes, Bowl3 Seal30 जुना व स्वतंत्र corrected Seal31 दोन्ही 58 writes, rank व रचना स्वतंत्र oracle शी तुलना. 23 जुने EXPECTED_RED अपरिवर्तित.

हे implementation documentation आहे; GitHub Actions 2/2 SUCCESS मिळेपर्यंत Stage47 GREEN किंवा बंद घोषित करायचा नाही. Stage48 उघडू नये; main, इतर शाखा आणि frozen SourceLanguageCatalog अपरिवर्तित.
