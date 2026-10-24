# Stage46 DISCOVERY23 — जुन्या संपूर्ण महिना-लांबीच्या यादीचे मर्यादित भौतिक प्रदर्शन

Stage45 पूर्ण आणि [final CI 40124962660](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40124962660) दोन्ही jobs SUCCESS. जुने SourceLanguageCatalog आणि Stage44/45 संपूर्ण पूर्ववर्ती संरक्षित.

## ऐतिहासिक दोष

वर्षाची खरी दिवससंख्या `L=closeGateDay-openGateDay`, महिन्यांची संख्या `m` ही वास्तविक Bowl3 seal30 वरून निवड. जुने `LegacyAllMonthLengthWays.oldAllWays(L,m)` सर्व 4..123 मर्यादित धन पूर्णांक लांबी `lex ascending` क्रमाने पूर्णपणे materialize करते. लहान यादीत मूळ API खरोखर तयार होतो आणि स्वतंत्र Bowl3 seal31 rank निवडतो. प्रचंड कुटुंबात तो OOM किंवा अंतहीन काम करण्याऐवजी आधीपासून जाहीर केलेल्या memory मर्यादेवर `LegacyMonthListLimit` नोंदवतो; चूक लपवून योग्य `rank` किंवा आभासी सूची तयार केल्याचा दावा नाही. Stage47 मध्येच `VirtualLegacyList` व exact DP count / itemAt1 परवानगी आहे.

`demonstrableLowerBound(L,m)` हा DP नाही. `q=floor(L/m)`, `r=L%m` यातील q आणि q+1 मूळ अनुक्रमांवर समान मूल्याच्या जोड्यांसाठी वैध `(v+d,v-d)` पर्याय वापरून सिद्ध किमान cardinality देतो: `∏ (2 min(v−4,123−v)+1)^floor(n_v/2)`. 47 महिन्यांवरील `L=211` साक्षीमध्ये मोठी lower bound मिळते; कृत्रिम OOM आवश्यक नाही.

## प्रत्यक्ष मार्ग आणि सावधगिरी

`Discovery23FullHandler` आधी संपूर्ण Stage45, Stage44 जुन्या repeat नावांचा मार्ग, वास्तविक वर्ष व पहिल्या दिवसाचा sauce चालवतो. तो Bowl3 seal30 ने m निवडतो आणि मूळ list API ला प्रत्यक्ष विचारतो. सुरक्षित लहान list असल्यास full Bowl3 seal31 निवडतो; लांबी मोठी असल्यास historical `blocked` मिळते; Stage47 चे virtual backend नाही. सर्व caller semantic state यशस्वी किंवा सिद्ध expected-legacy-blockage नोंदणी होईपर्यंत अपरिवर्तित.

`test/discovery23.ts`: खरे लहान lex rows, प्रचंड गणिती lower-bound, खरा full Stage45 path, स्वतंत्र test-only normative DP मोजणी, rollback/retry, Stage54 barrier.
`test/discovery23Properties.ts`: 720 बदललेले DROP46 sources (720 स्वतंत्र नैसर्गिक वर्षे असा दावा नाही), प्रत्येकाची Bowl3 seal30 पूर्ण 58 writes, सुरक्षित small-list साठी खरा seal31; `source\code` नाही.
`test/discovery23Red.ts`: स्वतंत्र 23वा हेतुपुरस्सर RED पुरावा; पहिली 22 ऐतिहासिक RED अपरिवर्तित.

CI 2/2 PASS आणि पूर्ण TypeScript typecheck / Stage1–46 regression / source names lock झाल्यावरच Stage46 बंद. Stage47 PATCH23 सुरू नाही; main अपरिवर्तित.

## Native CI निकाल — २५ ऑक्टोबर २०२६

मूळ commit [cc794630](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/cc7946306989c9f89ee5ba7bdb1b6adffa0fd7be) च्या [CI 40125753511](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125753511) मध्ये `verify` PASS पण test-only handler construction मधील एक बंद कंस नसल्याने `test/discovery23.ts:45` वर TS1005 अपयश आले. जुन्या production algorithm ला न स्पर्श करता फक्त ती चाचणी ओळ [54833c8c](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/54833c8c6e22609373d8278763e30da4c7536055) मध्ये सुधारली.

दुरुस्त [GitHub Actions 40134684657](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40134684657) मध्ये TypeScript typecheck, जुना संपूर्ण Stage1–46 regression, canonical names lock आणि 23 ऐतिहासिक अपेक्षित-RED साक्षी **दोन्ही jobs SUCCESS**.

```text
STAGE_46_DISCOVERY_23_GUARDS_PASS smallLexRows=10 syntheticHugeLowerBound=177147 preflightBlocked=1 nativeFullStage45=1 yearLength=5349 monthCount=44 oldCountFromTestOracle=956989856157389440798554542400 realOldListBlocked=1 lateFaults=1 stage47VirtualFixApplied=0
STAGE_46_DISCOVERY_23_PROPERTIES_PASS distinctDrop46=720 nativeSeal30=720 nativeSeal31=0 blockedLists=720 smallCompleteLists=0 countWrong=0 smallListSelectionWrong=0 realSharedWrites=41760
STAGE_46_DISCOVERY_23_EXPECTED_RED_VERIFIED nonzero=1 hugeFamily=1
```

पूर्ण ऐतिहासिक वर्षाच्या ५३४९ दिवसांमध्ये ४४ महिने असताना कुटुंब प्रचंड आहे. ७२० बदललेल्या DROP46 inputs वर प्रत्येक जुन्या यादीला सुरक्षित resource barrier लागू झाला; त्यामुळे `nativeSeal31=0` योग्यच आहे, काल्पनिक निवड नव्हे. वेगळ्या छोट्या उदाहरणात दहा जुन्या lex rows पूर्ण तयार होतात आणि independent reference शी तंतोतंत जुळतात. ७२० DROP46 inputs हे ७२० भिन्न नैसर्गिक वर्षे नाहीत. Stage47 मधील `VirtualLegacyList` दुरुस्ती अजून उत्पादनात नाही.

**Stage46 ची Native पडताळणी पूर्ण.** अंतिम प्रशासकीय commit च्या दोन्ही jobs PASS झाल्यावरच Stage47 उघडण्यास परवानगी.
