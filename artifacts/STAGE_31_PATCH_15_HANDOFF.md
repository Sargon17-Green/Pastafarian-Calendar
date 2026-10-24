# Stage 31 — PATCH 15

**Cabang:** PHP+Bahasa-Melayu.
**Asas:** Stage30 EXPECTED_RED, SHA b1723bfc35cd6a48a9ea70cf32b5852eef8aeb0d, Native GitHub Actions 39999379403 SUCCESS 2/2.

## Pembaikan

ThirdDigitPatch15 memanggil LegacyMissingThirdDigit15 tanpa mengubah kodnya, lalu menggunakan tiga sampel SAVE pada pemberat 1, M dan M², dengan cutoff dan rejection dalam M³ bagi M²<n<=M³. Panggilan produksi menggunakan BootstrapKernel::chooseTripleRank dan dispatcher THIRD_DIGIT_PATCH_15; laluan Legacy masih menghasilkan parut sejarah.

## Syarat penerimaan

- Stage30 direct exit 1 dan wrapper exit 0 dengan tepat empat RED, matriks 40 kes (36 berbeza), tiga laluan Native dan lima invalid.
- Stage31: 400 matriks sintetik berbanding oracle, empat saksi, 18 pertanyaan kernel sebenar melalui dua instance, enam input invalid, tanpa import oracle dalam src.
- PHP lint, fixtures, Stage1–30 dan canonical names lock lulus pada HEAD tepat; jangan ubah main atau mulakan Stage32 sebelum SUCCESS 2/2.

**Status:** AWAITING_CI.
