# Stage33 — PATCH16 — serahan

**Cabang:** `PHP+Bahasa-Melayu`.
**Asas:** Stage32 DISCOVERY16 EXPECTED_RED disahkan, SHA `748966fd7d2030c1199b30c1127508ee40ab10df`, Native CI `40169711719`, 3/3 SUCCESS.

## Pembaikan

`FourthDigitPatch16` memanggil `LegacyMissingFourthDigit16` sebenar tanpa mengubahnya, kemudian menghasilkan empat digit daripada SAVE(first + j*step), j=0..3 pada pemberat 1, M, M², M³. Domain `M³<n<=M⁴`, cutoff `floor(M⁴/n)*n`, rejection dalam 1..M⁴. `BootstrapKernel::chooseQuadRank` dan dispatcher `FOUR_DIGIT_PATCH_16` disediakan; laluan sejarah `MISSING_FOURTH_DIGIT_LEGACY` kekal.

## Gerbang GREEN

- `verify_stage32_discovery16.php` tetap exit 0 hanya bagi empat RED sejarah dengan 56 matriks, 52 mismatch, tiga panggilan sebenar dan lima invalid.
- `stage33_patch16_tests.php`: 400 matriks terhadap oracle, 392 mismatch sejarah, lapan match, empat saksi, 18 panggilan real dan enam input tidak sah; tiada oracle dalam `src`.
- Semua Stage1–32, PHP lint, fixture dan canonical names lock di Native CI, empat pekerjaan SUCCESS pada SHA HEAD yang sama.
- Tiada perubahan `main`, fixture, katalog, kod `LegacyMissingFourthDigit16.php` atau kod PATCH15.

**Status:** AWAITING_CI. Stage34 belum dibuka.

## Native CI VERIFIED

Stage33 PATCH16 disahkan GREEN pada SHA `6ed4efbe2e60a3d910f9e6277a4dbe7494333fa9` dalam run `40192008267`, 4/4 pekerjaan SUCCESS. Stage34 DISCOVERY17 dibenarkan, kod legacy sejarah tetap utuh.
