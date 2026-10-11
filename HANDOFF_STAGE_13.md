# टप्पा 13 पूर्ण — टप्पा 14 साठी हस्तांतरण

## अद्ययावत स्थिति

- शाखा: `TypeScript+मराठी` — `main` किंवा दुसरी भाषिक शाखा बदलू नका.
- एकूण 55 टप्पे; शेवटचा पूर्ण टप्पा **13 (PATCH 06)**.
- पुढे **14 (DISCOVERY 07)**, केवळ ऐतिहासिक सातव्या दोषाचा शोध. Stage 15 PATCH 07 अकाली नको.
- (Stage 54) पूर्वी अंतिम `calendarDateSpaghetti` कार्यान्वित नाही.
- Stage 13 implementation tested commit: `f4e4d260135c9bec75af5ebdcdc48b5d0da2704b`.
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38167061333 — `verify` आणि `stage13-typescript-marathi` **PASS**.

## Stage 13 मधील ठोस काम

- `src/patch06Prior.ts`: `Patch06PriorHandler`, `patch06Prior`.
- `slot=i-back>=1`: `LegacyVisiblePriorAdapter.legacyPrior` प्रत्यक्ष कॉल करून positive visible history `bigint` परत.
- `slot<=0`: `hiddenK=1-slot`; मागे संग्रहित hidden7..hidden1 मध्ये Stage 11 चा `Patch05HiddenHandler.correctedHiddenAt` व `7-hiddenK` mapping वापरून योग्य hidden थेंब वाचा.
- जुना `LegacyVisiblePriorAdapter.legacyPrior(dropStore,i,back)=dropStore[i-back]` बदलला नाही. `src/discovery06LegacyPrior.ts` व `test/discovery06Red.ts` जसेच्या तसे.
- स्वतंत्र visible/hidden frozen snapshots, per-call context, branch trace, metrics आणि invalid-state पूर्वपडताळणी.

## CI-प्रमाणित चाचण्या

```text
STAGE_13_PATCH_06_GUARDS_PASS cases=15 hidden=11 visible=4 mismatches=0
STAGE_13_PATCH_06_PROPERTIES_PASS days=16 cases=2208 hidden=176 visible=2032 mismatches=0 giantCases=138 giantMismatches=0
```

- 16 वास्तविक दिवस-जोड्यांतील 46 visible drops × 3 इतिहास-अंतरे, 2208 सत्यापित परिणाम.
- 11 hidden + 4 visible अशा 15 सीमा-साक्षी; सर्व शून्य फरक.
- 138 स्वतंत्र 16,384-bit मूल्यांचे प्रयोग; शून्य फरक.
- सहा जुन्या `DISCOVERY_01_EXPECTED_RED` ते `DISCOVERY_06_EXPECTED_RED` हेतुपुरस्सर गैरशून्य exit चे CI validation पास.
- `CANONICAL_NAMES_LOCK.sha256` अपरिवर्तित, मराठी नावांचा कॅटलॉग गोठवलेला.
- Stage 1–12 सर्व regressions हिरवे.

## पुढील एकमेव काम

1. live branch HEAD व `DEVELOPMENT_STAGE.md` पहा; अन्य समांतर काम नवीन असू शकते.
2. मूळ 55-टप्प्यांच्या contract मधील सातवा ऐतिहासिक दोष **grind table indexing** अचूक वाचा.
3. Stage 14 मध्ये फक्त चुकीची legacy indexing आणि नियमाधारित oracle विरुद्ध प्रत्यक्ष divergence सिद्ध करणारा expected-red regression जोडा.
4. Stage 15 चा patch लावू नका. Stage 1–13 चाचण्या आणि सहाही जुन्या archive reds चालू ठेवा.
5. स्वतःची TypeScript implementation व Marathi comments वापरा; अन्य भाषिक शाखांमधील implementation, tests, fixtures, hashes किंवा derived artifacts आयात करू नका.
6. GitHub Actions पडताळणी झाली कीच Stage 14 पूर्ण घोषित करा.

या हस्तांतरणातील सर्व Stage 13 पुरावे repository मध्ये कायम साठवलेले आहेत. स्वतंत्र स्थानिक वापरकर्ता-कृती आवश्यक नाही.
