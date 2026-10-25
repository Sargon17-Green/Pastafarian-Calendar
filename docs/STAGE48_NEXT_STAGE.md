# Stage48 DISCOVERY24 Native PASS — Stage49 PATCH24 पुनःप्रारंभ

शाखा `TypeScript+मराठी`, Stage48 implementation `c5e46aea790203deb8aad88d1e272a56246f0e78`, [Native CI 40185059418](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40185059418) दोन्ही jobs SUCCESS. Stage48 च्या **अंतिम प्रशासकीय closure commit** च्या स्वतःच्या CI मध्येही दोन्ही jobs SUCCESS झाल्यानंतरच Stage49 सुरू करा.

## Stage49 PATCH24 — legal month weaving चा खरा BigInt DP

केंद्रीय `06-implementation-prompt.md` टप्पा 24: पूर्वीचा `LegacyIndependentDailyMonthChooser.legacyChooseEachDaySeparately` इतिहास म्हणून कायम ठेवून **प्रत्यक्ष चालवणे**; त्याचा ghost normative weaving म्हणून कधीही मानू नये. नवीन production `DPUnrankLegalWeaving` ने महिन्यांच्या क्रमाची अचूक संख्या व `itemAt1(rank)` lexicographic ascending legal weaving निवड द्यावी. महिन्यांचे IDs 1..m, प्रत्येक ID exactly त्याच्या month length एवढे वेळा, पहिल्या appearances 1..m क्रमात, शेवटच्या appearances 1..m क्रमात. मोठ्या Year5000 weaving family चे सर्व मार्ग enumerate करू नका; memoized state, BigInt व सुरक्षित bounded memory आवश्यक.

* Stage48 full predecessor **खरोखर चालवा**: Stage47 corrected exact month lengths, Stage46 actual oldAllWays attempt, genuine Bowl3 Seal30/31, genuine Bowl4 Seal32 first-day Sauce. Stage48 चे ghost दिवसागणिक प्रत्यक्ष तयार झालेले असावे. Stage49 corrected ranking साठी canonical Bowl4 Seal32 answer stream **कुटुंबाच्या अचूक DP count वर** स्वतंत्र पूर्ण 58-write Native call वापरा; जुन्या (N=m) selection ला योग्य weaving family rank म्हणून reuse करू नका. पुरावा context/ledger वेगळा ठेवा.
* Old ghost जर legal weaving, योग्य exact-rank result व योग्य constraints शी तंतोतंत समान असेल तरच reuse; अन्यथा योग्य DP unrank निवडा. जुने 24 intentionally-red tests, historical failures व diagnostics अपरिवर्तित. नवे reference DP उत्पादनात test-only oracle मधून import करू नका.
* लहान families ची exhaustive enumeration/independent oracle, 5349-day Year5000 large witness वर scalable DP आणि rank boundaries, 720 altered DROP46 source choices, fault rollback/retry, independent semantic owner, Stage54 पूर्ण दिनांक अजून बंद.
* Production DP complexity वर प्रामाणिक वेळ/RAM resource limits ठेवा; timeout किंवा कृत्रिम count बनवू नका. गंभीर feasibility issue आढळल्यास Stage49 अपूर्ण म्हणून प्रामाणिकपणे नोंदवा आणि खरी error evidence द्या.
* `npm run typecheck`, `npm test`, 24 historical intentional REDs, frozen Marathi SourceLanguageCatalog, GitHub Actions दोन्ही jobs SUCCESS व final administrative CI SUCCESS आधी Stage49 बंद करू नये. Stage50 DISCOVERY25 आगाऊ सुरू नको.

प्रत्येक round मध्ये Library `/Pastafarian_Calendar_Project/PROJECT_WORKFLOW.md` आणि canonical `BRANCH_REGISTRY.xlsx` चा current version व GitHub HEAD पुन्हा पडताळा; `main` किंवा इतर branch बदलू नका.
