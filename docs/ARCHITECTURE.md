# Stage 1 کی فنِ تعمیر

## صاف حوالہ

`PSTNormativeOracle` صرف tests کے لیے ہے۔ production monster اسے نہیں پکارتا۔ oracle میں Appendix A کی الگ الگ ذمہ داریاں صاف طریقے سے رکھی گئی ہیں: دن کے شمار، پتھر، پوشیدہ اور نمایاں قطرے، پیالے، بعد کی بارہ ہلچلیں، سوالی دھارا، مختصر اور وسیع انتخاب، دروازے، سال، کٹلیٹ، مہینے اور آخری پانچ اجزا۔

## عین عددی حساب

تمام معنوی حساب `Integer` پر ہے۔ floating point کو نرمی، rank، combinatorics یا modulo کے لیے استعمال نہیں کیا گیا۔ `M = 2^127 - 1` ہے، مگر DP counts اور ranks اس حد سے بڑے ہو سکتے ہیں۔

## virtual خاندان

بڑی combinatorial فہرستیں materialize نہیں کی جاتیں۔ محدود ترکیبات، کٹلیٹ partitions اور مہینوں کی بُنائی کے لیے exact count اور lexicographic unrank استعمال ہوتا ہے۔ چھوٹے fixture spaces پر مکمل متوقع ترتیب الگ test کی گئی ہے۔

## عمومی monster بنیاد

Stage 1 میں monster صرف اتنا بڑا ہے جتنا تاریخی ترتیب اجازت دیتی ہے:

```text
PSTMonsterManager
 -> PSTMonsterDispatcher
  -> bootstrap handler
   -> PSTMonsterValidator
    -> PSTMonsterMetrics
```

`PSTMonsterContext` ہر invocation کے لیے نئی شے ہے۔ اس میں input، lifecycle، منظور شدہ semantic state، زیر التوا state اور غیر معنوی observability رکھی جاتی ہے۔ اس مرحلے میں کسی مخصوص legacy defect یا future patch کا field نہیں ہے۔

## state ownership

منظور شدہ semantic state اور pending state کو ایک ہی mutable object ہونے کی اجازت نہیں۔ metrics اور logs معنوی input نہیں بنتے۔ ہر invocation اپنا context اور اپنی semantic state رکھتا ہے۔
