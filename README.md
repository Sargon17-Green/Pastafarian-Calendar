# پاستافاری کیلنڈر — Smalltalk + اردو

یہ شاخ ایک بالکل نیا اور خود مختار نفاذی سلسلہ ہے۔ اس کا پہلا مرحلہ صرف **Bootstrap** ہے۔ اس مرحلے میں کسی دوسرے نفاذ، کسی دوسری پروگرامنگ زبان کے oracle، کسی بیرونی fixture، کسی hash، کسی snapshot اور کسی differential output کو ماخذِ حقیقت نہیں بنایا گیا۔

## زبانیں

- پروگرامنگ زبان: `Smalltalk`
- انسانی ماخذ زبان: `اردو`
- کینونیکل ناموں کی ترتیب: صرف `canonicalIndex`

اردو متن صرف presentation کی سطح پر حل کیا جاتا ہے۔ انتخاب، rank، unrank، cache key یا کسی دوسرے معنوی فیصلے میں مقامی متن استعمال نہیں ہوتا۔

## Stage 1 میں موجود حصے

- `PSTSourceLanguageCatalog` — سترہ کٹلیٹ اور سینتالیس مہینوں کا منجمد اردو کیٹلاگ۔
- `PSTNormativeOracle` — Appendix A کا صاف، test-only، arbitrary-precision حوالہ۔
- `PSTBoundedCompositionCounter` — محدود ترکیبات کی عین گنتی اور لغوی unrank۔
- `PSTCutletPartitionCounter` — داخلی دروازے کی شرط سمیت عین کٹلیٹ تقسیم۔
- `PSTWeavingCounter` — مہینوں کی مکمل قانونی بُنائی کی DP گنتی اور لغوی unrank۔
- `PSTMonsterContext`، `PSTMonsterDispatcher`، `PSTMonsterValidator`، `PSTMonsterErrorWrapper`، `PSTMonsterMetrics` اور `PSTMonsterManager` — صرف عمومی اور غیر مخصوص monster بنیاد۔
- مقامی fixtures اور test harness، دونوں Smalltalk میں۔

## اس مرحلے میں جان بوجھ کر موجود نہیں

Stage 2 سے Stage 53 تک کے کسی legacy defect، patch، scar، alias، latch، ghost path، bad cache key، year filter یا دوسرے تاریخی detour کا production code Stage 1 میں شامل نہیں ہے۔ یہ چیزیں اپنے مقررہ تاریخی مرحلے سے پہلے داخل نہیں کی جائیں گی۔

## آزمائش چلانے کا طریقہ

Pharo 13 یا ایسا Smalltalk ماحول درکار ہے جو روایتی chunk file-in، arbitrary-precision `Integer` اور استعمال شدہ بنیادی collections کو سپورٹ کرے۔ پروجیکٹ کی جڑ سے:

```text
pharo Pharo.image st run-stage01.st
```

کامیاب run پر `STAGE_01_EXECUTION_LOG.txt` بنایا جاتا ہے۔ ناکامی پر test harness error اٹھاتا ہے اور Stage 1 مکمل نہیں سمجھا جاتا۔

## اگلا مرحلہ

صرف Stage 1 کے مکمل اور سبز ہونے کے بعد اگلا مرحلہ `DISCOVERY 01` ہوگا۔ اس repository state میں اس کا code موجود نہیں ہونا چاہیے۔
