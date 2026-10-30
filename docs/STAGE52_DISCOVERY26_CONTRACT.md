# Stage52 — DISCOVERY26: विणलेल्या महिन्याची अखेरची उपस्थिती

**स्थिती:** संशोधनावर आधारित स्टेज करार; Native अंमलबजावणी किंवा PASS अद्याप नाही. आधार SHA: `f346cb5329459ab7078af237b4750a4b98e7865d`; Stage51/PATCH25 चाचण्या आधीच पूर्ण. 2026-10-30 रोजी करार स्वतंत्रपणे ठरविण्याची परवानगी मिळाली. `main` बदलू नये.

## नियम आणि मांडणी
Stage51 मध्ये दिवसाचा क्रमांक पूर्ण वर्षातील निवडलेल्या महिन्याच्या **prefix occurrences** मोजून ठरतो. महिने सलग असतीलच असे नाही. या आधारावर, विणकाम `w[1..N]` आणि दिनांक `d` साठी:
`isLastMonthOccurrence(d) = NOT EXISTS j (d < j <= N AND w[j] = w[d])`.
हे स्वतंत्र तपासणीचे गुणधर्म आहे; **सहावा दिनांक-घटक नाही**. Stage51 चा मुख्य परिणाम बदलू नये.

फक्त जुन्या मार्गाच्या तपासणीसाठी मुद्दाम चुकीचा `oldContiguousMonthEndGuess(d) = (d=N) OR (w[d+1] != w[d])` तयार करावा. हा **नवीन चाचणीसाठी बनवलेला legacy model** आहे; आधीपासून production bug सापडल्याचा दावा नाही.

## स्वतंत्र उदाहरण
विणकाम: `[1,2,1,2,1,2,1,3,2,3,3,3,3]`.
दिनांक 1, 2, 8: legacy=true, अचूक suffix-सदस्यत्व=false — **तीन EXPECTED_RED**.
दिनांक 7, 13: legacy=true, अचूक=true — **दोन हिरवे controls**.
ही पाच गणिती प्रकरणे स्वतंत्रपणे तपासली; TypeScript Native चाचणी अजून झालेली नाही.

## अंमलबजावणी व स्वीकृती
1. `src/discovery26LegacyMonthEnd.ts` मध्ये मागील Stage51 च्या संपूर्ण साखळीवरून (नवीन स्वतंत्र owner) निवडलेल्या `legalWeaving` वर काम करणारा diagnostic adapter; `Patch25MonthDayResult` आणि आधीचे trace, sealed native query-count व historical scars अपरिवर्तित.
2. Test-only independent oracle: `w.slice(d).includes(w[d-1])` च्या नकारातून निर्णय; production adapter सोबत implementation शेअर करू नये.
3. पाच निश्चित प्रकरणे, वर्षाच्या शेवटची सीमा, एका महिन्याची विण, अनियमित विण, तसेच seeded random families; नकार/rollback/retry व पूर्वीच्या Stage51, Stage50 archive tests राखणे.
4. `npm run typecheck`, `npm test`, verify + TypeScript Native, names lock, सर्वांचे commit SHA एकच असणे आवश्यक. EXPECTED_RED फक्त 3 घोषित normative mismatches असतील तरच Stage52 साठी अपेक्षित; इतर failure असल्यास दुरुस्ती.
5. Stage52 पूर्ण झाल्याचा दावा फक्त Native पुराव्यानंतर; Stage53/PATCH26 किंवा अंतिम स्पॅगेटी दिनांक अजून उघडू नये.

**काळजी:** हा स्वतंत्रपणे व्युत्पन्न करता येणारा शोध-करार आहे. आधीपासूनची production त्रुटी असल्याचा पुरावा नाही. दावे व test totals प्रत्यक्ष CI वर अवलंबून आहेत.
