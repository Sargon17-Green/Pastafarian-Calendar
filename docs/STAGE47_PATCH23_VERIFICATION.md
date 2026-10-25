# Stage47 PATCH23 — आभासी महिन्यांच्या लांबी, ऐतिहासिक यादी कायम

## नियम

Stage46 मधील `LegacyAllMonthLengthWays.oldAllWays`, वास्तविक Bowl3 Seal30, सुरक्षित मर्यादेतील प्रत्यक्ष जुन्या यादींचे materialization, `LegacyMonthListLimit` आणि 23 आधीचे intentionally-red पुरावे जतन. नवीन `VirtualLegacyList(L,m)` च्या `count()` मध्ये 4..123 मधील bounded compositions ची अचूक BigInt DP sliding-window recurrence आहे; `itemAt1(rank)` मूळ ascending lex order चा 1-based suffix-block unrank आहे. प्रचंड family RAM मध्ये enumeration नाही. Test-only normative oracle उत्पादनात import होत नाही.

`Patch23FullHandler` पूर्ण Stage46 historical predecessor स्वतंत्र owner मध्ये प्रत्यक्ष चालवतो. Stage17 `calculationDay=openingGateDay+1` अट कायम. Stage41 true first-day Sauce वर नवीन Bowl3 Seal31 चा पूर्ण 58-write native प्रश्न normative DP family count ने चालतो. जुनी पूर्ण materialized रचना उपलब्ध असल्यास ती फक्त पूर्ण बरोबरीवर reuse; historical blocked किंवा चुकीची निवड authoritative नाही. Fault नंतर caller च्या semantic state मध्ये बदल नाही.

## स्वीकार निकष

`test/patch23.ts` मध्ये लहान lex families exhaustive old-vs-virtual-vs-independent oracle, 5349 दिवसांच्या 44 महिन्यांच्या प्रत्यक्ष family ची 956989856157389440798554542400 exact count आणि first/middle/last rank, full Stage46 chain, fault, retry, owner isolation, Stage54 barrier. `test/patch23Properties.ts` मध्ये 720 DROP46 input changes, Bowl3 Seal30 जुना व स्वतंत्र corrected Seal31 दोन्ही 58 writes, rank व रचना स्वतंत्र oracle शी तुलना. 23 जुने EXPECTED_RED अपरिवर्तित.

हे implementation documentation आहे; GitHub Actions 2/2 SUCCESS मिळेपर्यंत Stage47 GREEN किंवा बंद घोषित करायचा नाही. Stage48 उघडू नये; main, इतर शाखा आणि frozen SourceLanguageCatalog अपरिवर्तित.

## प्रत्यक्ष Native स्वीकार — २५ ऑक्टोबर २०२६

प्राथमिक [CI 40170233328](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40170233328) मध्ये `verify` SUCCESS पण `MonsterStatus` union मध्ये `PATCH_23_APPLIED` नसल्यामुळे TypeScript मधील TS2820 व TS2367 झाले. `src/monsterBase.ts` मध्ये फक्त हे नवीन status जोडणारा commit `159b9b075c274763a1c2b022cb3a9cecf32a26d3` लावला; मागील legacy वा DP algorithm बदललेला नाही.

दुरुस्त [GitHub Actions 40180985206](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40180985206): `verify` SUCCESS आणि `stage27-typescript-marathi` SUCCESS. TypeScript typecheck व संपूर्ण Stage1–47 regression पास. वास्तविक log पुरावे:

```text
STAGE_47_PATCH_23_GUARDS_PASS exhaustiveLexRows=6097 hugeRankSamples=5 actualYearLength=5349 monthCount=44 exactCount=956989856157389440798554542400 fullStage46=1 oldBlocked=1 correctedSeal31=1 rankWrong=0 chosenWrong=0 faultRecovery=1 predecessorCalls=59 sharedWrites=3422 stage54Blocked=1 archivedExpectedReds=23
STAGE_47_PATCH_23_PROPERTIES_PASS distinctDrop46=720 correctedNativeSeal31=720 blockedHistoricalLists=720 lexWrong=0 exactLegacyReused=0 realSharedWrites=83520
```

मागील Stage46 `EXPECTED_RED` क्रमांक २३ आणि आधीच्या २२ intentionally red साक्षी विसरलेल्या नाहीत. ७२० बदललेले DROP46 inputs स्वतंत्र Sauce परिस्थिती आहेत; ती ७२० नैसर्गिक वर्षे असल्याचा दावा नाही. या ७२० प्रकरणांत जुन्या भौतिक सूची संसाधन-बाधित असतानाही स्वतंत्र अचूक correction ने ५८ shared writes चा खरा नवीन seal31 वापरला. एकच खरा उपलब्ध रकाना असलेल्या जुन्या family वर समानतेने reuse करण्याचा स्वतंत्र guard देखील Native PASS.

Stage47 कोड Native पडताळला. अंतिम प्रशासकीय closure commit च्याही दोन्ही jobs SUCCESS झाल्याशिवाय पुढील Stage48 सुरू करू नये.
