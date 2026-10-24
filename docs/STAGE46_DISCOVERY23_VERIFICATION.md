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
