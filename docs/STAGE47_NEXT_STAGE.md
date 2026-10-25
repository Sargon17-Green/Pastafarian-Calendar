# Stage47 PATCH23 Native GREEN — Stage48 DISCOVERY24 साठी अटी

कार्यशाखा: `TypeScript+मराठी`. प्रामाणिक Stage47 Native पुरावा [CI 40180985206](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40180985206) मध्ये `verify` आणि `stage27-typescript-marathi` दोन्ही SUCCESS. `DEVELOPMENT_STAGE.md` मध्ये Stage47 बंद नोंदल्यावर अंतिम प्रशासकीय closure commit चा स्वतःचा CI **दोन्ही SUCCESS** झाल्यावरच Stage48 प्रत्यक्ष सुरू करा. `main`, इतर शाखा, `SourceLanguageCatalog`, मागील २३ intentionally-red पुरावे बदलू नका.

## Stage48 — DISCOVERY24: महिना रोज स्वतंत्र निवडण्याचा ऐतिहासिक दोष

`06-implementation-prompt.md` करारातील टप्पा २४: ऐतिहासिक `legacyChooseEachDaySeparately` पूर्णपणे जतन करून **प्रत्यक्ष चालवायचा**, प्रत्येक दिनासाठी स्वतंत्र month-ID निवड करून ghost weaving तयार करायची. त्या इतिहासात योग्य aggregate month-length counts, पहिल्या व शेवटच्या दिसण्यांचा अचूक क्रम आणि एखाद्या महिन्याचे required multiplicity यांची हमी नसते. स्वतःहून `DPUnrankLegalWeaving` (Stage49 PATCH24) आधी आणायचा नाही; Stage48 मध्ये मुद्दाम चुकीचा `ghost` व स्वतंत्र test-only normative योग्य weaving मधील खरा फरक Native साक्षीने दाखवावा.

Year5000 वास्तविक वर्ष, Stage47 मधील पूर्ण जुना Stage46 व Stage45 predecessor, अचूक month-length family व त्याची Bowl3 Seal31 निवड आधी प्रत्यक्ष चालली पाहिजे. Month weaving च्या योग्य नियमांचे स्वतंत्र oracle पुरावे: प्रत्येक महिना (j) त्याच्या लांबीइतकाच दिसतो, पहिला (1,2,...,m) क्रमात, शेवटचा (1,2,...,m) क्रमात; पूर्ण day-by-day sequence वर lexicographic ascending. खरा historical month weaving प्रश्न कोणत्या bowl/seal वर होतो ते frozen normative source मध्ये तपासून मग Stage48 legacy caller द्या; काल्पनिक trace, extrapolated calls वा fake year-gate मान्य नाही.

Native छोट्या weaving कुटुंबांच्या अनेक exhaustive तुलना, मोठी उदाहरणे, 720 DROP46 स्रोतांवर नियंत्रित tests (हे 720 स्वतंत्र नैसर्गिक वर्षे नाहीत), deterministic memory bound, fault/rollback/retry आणि २४वा नवा **EXPECTED_RED** witness; मागील २३ archival intentionally-red unchanged. Stage49 सुधार आधी नाही, Stage54 full calendar route बंद. प्रत्येक कार्यप्रगतीनंतर canonical `/Pastafarian_Calendar_Project/BRANCH_REGISTRY.xlsx` ची live आवृत्ती तपासा व optimistic conflict नियंत्रणासह नोंद करा.

Stage48 DISCOVERY24 बंद करण्याआधी `npm run typecheck`, पूर्ण Stage1–48 regression, २४ अपेक्षित RED, frozen names verify आणि GitHub Actions 2/2 SUCCESS आवश्यक. Stage49 PATCH24 घाईने सुरू करायचा नाही.
