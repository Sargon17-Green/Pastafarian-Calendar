# Stage46 DISCOVERY23 नंतर — Stage47 PATCH23 साठी पुनर्प्रारंभ

कार्यशाखा `TypeScript+मराठी` एकटी बदलावी, `main` नव्हे. 55 कठोर विकास टप्पे आहेत. Stage46 चा सुधारलेला Native implementation commit `54833c8c6e22609373d8278763e30da4c7536055`, [CI 40134684657](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40134684657) दोन्ही jobs SUCCESS, २३ हेतुपुरस्सर जुने RED जतन. अंतिम Stage46 प्रशासकीय commit च्या स्वतःच्या CI मध्ये **दोन्ही SUCCESS** होईपर्यंत Stage47 सुरू करू नये.

## पुढील टप्पा: Stage47 PATCH23

अधिकृत `06-implementation-prompt.md` टप्पा २३: जुना `LegacyAllMonthLengthWays.oldAllWays(L,m)` आणि त्याच्या 4..123 bounded lex सूचीची भौतिक पुनर्रचना प्रत्यक्ष जुना मार्ग म्हणून ठेवावी; कमी आकारांची यादी तशीच तयार होते, मोठ्या आकारासाठी `LegacyMonthListLimit` स्पष्ट दिसतो. **जुना helper हटवू किंवा नव्या DP कडे वळवू नये.**

स्वतंत्र `VirtualLegacyList` backend जोडावा: `count()` हे अचूक non-negative arbitrary-precision DP, `itemAt1(rank)` हा जुन्याच कडक lex ascending क्रमाचा अचूक 1-based unrank. `L=year.closeGateDay-year.openGateDay`, प्रत्यक्ष Bowl3/seal30 चा `m`, `lo=4`, `hi=123`. नव्या normative `N=count()` वर स्वतंत्र पूर्ण Bowl3/**seal31** प्रश्न आणि ५८ shared writes वापरून दुरुस्त रचना मिळवावी. जुन्या यादीत historical result मिळाल्यास त्याच्याशी अचूक तुलना करावी; तोच परिणाम असल्यास reuse, नाहीतर correct; ऐतिहासिक resource block किंवा जुना चुकीचा rank authoritative करायचा नाही.

सर्व Stage45 full historical predecessor आणि Stage46 जुना Bowl3 seal30, oldAllWays physically चालवावा. खर्‍या first-day Sauce आणि Stage17 gate+1 मर्यादेचा आदर राखावा. test-only normative oracle production मध्ये import नको. (L=5349,m=44) या वास्तविक साक्षीवर `count=956989856157389440798554542400` ची स्वतंत्र चाचणी आणि पहिल्या/मध्य/शेवटच्या lex ranks करावेत. ७२० भिन्न DROP46 orders, मोठ्या `BigInt` संख्या, K छोटे exhaustive rows, fault rollback/retry, distinct semantic context owner, २३ जुने intentionally-red scripts, names lock व Stage54 barrier पडताळावेत.

`npm run typecheck`, संपूर्ण `npm test`, दोन GitHub Actions jobs SUCCESS, आणि अंतिम प्रशासकीय commit चे CI SUCCESS झाल्याशिवाय Stage47 बंद करू नये. Stage48 DISCOVERY24 ची कामे लवकर सुरू करू नयेत. `/Pastafarian_Calendar_Project/PROJECT_WORKFLOW.md` आणि एकमेव `BRANCH_REGISTRY.xlsx` प्रत्येक round मध्ये live version तपासून अद्यतन करावेत; समांतर branch rows जतन कराव्यात.
