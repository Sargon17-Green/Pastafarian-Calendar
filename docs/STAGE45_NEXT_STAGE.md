# Stage45 Native PASS — पुढील Stage46 DISCOVERY23

शाखा: `TypeScript+मराठी`. [Stage45 CI 40011249527](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40011249527) मधील दोन्ही jobs SUCCESS. Stage45 अंतिम closure HEAD च्या दोन्ही jobs SUCCESS झाल्यानंतरच Stage46 सुरू करा. Stage46 हा DISCOVERY23; Stage47 PATCH23 लवकर लागू करू नका.

## ऐतिहासिक दोष व अचूक करार

`06-implementation-prompt.md` मधील टप्पा 23: month-length materialization legacy API “सर्व मार्गांची यादी” तयार करण्याचा प्रयत्न करतो. तो वास्तविक `L=year.closeGateDay-year.openGateDay`, `m=chooseMonthCount` आणि `lo=4, hi=123` यांच्या lexicographic ascending bounded compositions साठी कार्य करणे आवश्यक आहे. Normative family size म्हणजे `Count(L,m)`; योग्य ranking ही Bowl3 / `SEAL_MONTH_LENGTHS` वरून, पूर्ण first-day `structureSauce` वापरून. Discovery23 मध्ये संपूर्ण list थेट अमर्याद तयार करू नका; प्रचंड count आणि memory आवश्यकतेचा गणिती पुरावा द्या, आणि मर्यादित साक्षींसाठी खऱ्या old materialization API चा प्रयोग करा.

ऐतिहासिक wrong API व त्याचे materialization barrier जपणे, प्रचंड रांगांसाठी OOM किंवा hung job टाळणे, आणि Stage47 च्या `VirtualLegacyList(count, itemAt1)` दुरुस्तीला आधी न जोडणे अत्यावश्यक. Correction चे exact DP count/unrank stage47 साठीच राखावे. जुना historical caller लहान family वर खरा सूची परिणाम आणि मोठ्या family वर स्पष्ट bounded-failure पुरावा देतो; fabricated list किंवा fake success नको.

## वैधानिक व चाचणी अटी

पूर्ण Stage45 predecessor (समेत प्रत्यक्ष Stage44 जुना repeating-name मार्ग, corrected Bowl5 Seal22, वर्षाच्या पहिल्या दिवसाचा Sauce) चालवावा; Stage17 `calculationDay=openingGateDay+1` अट न मोडावी. MonthCount ची नवीन Bowl3 / `SEAL_MONTH_COUNT` आणि monthLengths साठी जुनी प्रत्यक्ष Bowl3 / `SEAL_MONTH_LENGTHS` chain आवश्यक. गणिती मोजणी संदर्भ स्वतंत्र test-only oracle मधून काढावी. प्रचंड `L,m` साठी संपूर्ण कुटुंब RAM मध्ये न बनवता अचूक संख्या / memory lower bound दाखवावा. 720 DROP46 order variations, BigInt checks, failure injection, rollback/retry, 22 archived expected RED, आणि स्वतंत्र 23वा EXPECTED_RED; frozen names lock, Stage54 barrier, main व इतर शाखा अपरिवर्तित.

पूर्ण `npm run typecheck`, `npm test`, जुनी सर्व RED proofs आणि GitHub Actions दोन jobs PASS झाल्यावरच Stage46 ची बंदी मानावी; Stage47 सुरू करू नका. केंद्रीय `PROJECT_WORKFLOW.md` आणि `BRANCH_REGISTRY.xlsx` चे वर्तमान version रिफ्रेश करूनच बदल करावे.
