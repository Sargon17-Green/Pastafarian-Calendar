# Serahan Stage 11 — PATCH 05

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `c8addff183ac9c44a8b2394e82e0f871f6686045`  
**Tahap:** 11/55, PATCH 05  
**Keadaan dijangka:** GREEN

## Cara pembetulan

`HiddenNearnessPatch05::hiddenByNearness` menyelesaikan `k` kepada slot `8-k` dan memanggil `LegacyHiddenBackward::wrongNearness` pada tatasusunan songsang yang asal. Keputusan pembangunan Stage 10 dikekalkan sebagai bukti merah melalui `stage10_discovery05_tests.php`, yang sekarang memeriksa legacy secara terus agar laluan pengeluaran baharu tidak memadamkan sejarah.

`BootstrapKernel::hiddenDrops` kini menggunakan `HIDDEN_PATCH_05`, dan handler `HIDDEN_BACKWARD_LEGACY` kekal didaftarkan. Tiada pemindahan elemen stor; tiada rumus baharu; tiada oracle di produksi.

## Ujian wajib

```text
php -d memory_limit=512M tests/stage01_tests.php
php -d memory_limit=512M tests/bigint_division_regression.php
php -d memory_limit=512M tools/generate_stage01_fixtures.php
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
php -d memory_limit=512M tests/verify_stage04_discovery02.php
php -d memory_limit=512M tests/stage05_patch02_tests.php
php -d memory_limit=512M tests/verify_stage06_discovery03.php
php -d memory_limit=512M tests/stage07_patch03_tests.php
php -d memory_limit=512M tests/verify_stage08_discovery04.php
php -d memory_limit=512M tests/stage09_patch04_tests.php
php -d memory_limit=512M tests/verify_stage10_discovery05.php
php -d memory_limit=512M tests/stage11_patch05_tests.php
```

Ujian Stage 10 terus mendapat `EXPECTED_RED` (72 berbeza, 12 sepadan) dan penyemaknya mendapat PASS. Stage 11 membandingkan 37 pasangan hari dan 259 hasil dengan oracle tempatan, serta 896 slot sintetik. Ujian Stage 1–9 dan kunci katalog mesti tetap hijau.

**Tajuk commit:** `stage11(php-ms): betulkan kedekatan titisan tanpa menyongsang stor`
