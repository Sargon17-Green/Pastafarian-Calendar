# Stage50 DISCOVERY25 — महिना सलग असल्याचा चुकीचा अंदाज (work in progress)

Stage49 PATCH24 final [CI 40243065329](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40243065329) दोन्ही jobs SUCCESS. Only `TypeScript+मराठी`. Previous 24 intentional RED histories and `main` unchanged.

`OldContiguousMonthDayGuess.oldContiguousMonthDayGuess` वास्तविक ranked legal weaving मध्ये target year-day चा month-ID घेतो आणि त्या महिन्याच्या **पहिल्या** day index पासून target पर्यंतची संपूर्ण span मोजतो. मध्ये इतर महिन्यांचे दिवस पडले तरी ते count मध्ये चुकीने समाविष्ट होतात. Stage51 PATCH25 मधील योग्य prefix-occurrence count उत्पादनात आणलेला नाही. Stage50 मध्ये फक्त historical guess उपलब्ध; correct actual counts स्वतंत्र **test-only** oracle नेच काढतात.

`Discovery25FullHandler` पूर्वीचे सर्व पूर्ण `Patch24ScalableFullHandler` (Stage49), Stage48 legacy independent daily ghost, Stage47 exact virtual month lengths, real Bowl3 Seal30/31 व दोन स्वतंत्र Bowl4 Seal32 Native प्रश्न प्रत्यक्ष चालवतो; यानंतर `oldContiguousMonthDayGuess` चालतो, कोणतेही अतिरिक्त Sauce प्रश्न नाहीत. Target day वास्तविक Year5000 कालखंडात नसल्यास reject; caller semantic owner वर सर्व परिणाम successful predecessor पूर्ण झाल्यावरच commit.

Concrete legal witness `[1,2,1,2,1,2,1,3,2,3,3,3,3]`: final month 3 old guess=6, actual occurrences=5, hence independent 25th standalone EXPECTED_RED. Day9 in month2 old guess=8, actual=4. Test-only independent exhaustive/sample oracle compares multiple families and true Year5000 5,349 days/44 months. Still preserves Stage54 full-date integration blocker. No premature Stage51 fix.

**This is implementation evidence only, not Stage50 closure.** `npm run typecheck`, full regression, 25 EXPECTED_RED archives, frozen SourceLanguageCatalog, two GitHub Actions SUCCESS and administrative closure CI required.
