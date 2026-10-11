# Serahan Stage 7 — PATCH 03

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `16add94b9e673e43e0116ffb1789103e590f962d`  
**Tahap:** 7/55 — PATCH 03  
**Keadaan dijangka:** GREEN

## Formula serta parut sejarah

`LegacyDistance::oldDistance(c,t)` sengaja tidak diubah dan memulangkan `abs(t-c)`. Adapter baharu `DistanceCountPatch03::distanceCountPatch03(c,t)` memanggilnya dan kemudian menambah `1`. Pengeluaran `BootstrapKernel::distance(c,t)` menggunakan `DISTANCE_PATCH_03`; dispatcher `DISTANCE_LEGACY` kekal untuk bukti sejarah. Semua pengiraan jarak dibuat dalam PHP tulen menggunakan BigInt, termasuk `PHP_INT_MIN/MAX`.

## Fail yang ditambah

- `src/Patches/DistanceCountPatch03.php` — pembalut pembetul yang tidak mengubah legacy.
- `tests/stage07_patch03_tests.php` — 16,668 kes normatif termasuk 12 ujian sempadan, 1,285 kes anjakan dan 200 sifat additiviti.
- `artifacts/STAGE_07_PATCH_03_HANDOFF.md` — rekod serahan.

## Fail yang diubah

- `src/BootstrapKernel.php`, `tests/bootstrap.php` — penghala dan muatan kelas.
- `tests/stage06_discovery03_tests.php`, `tests/verify_stage06_discovery03.php` — kekalkan bukti merah pada legacy secara langsung, tetapi semak patch kini hadir dan digunakan oleh pengeluaran.
- `tests/stage03_patch01_tests.php`, `tests/stage05_patch02_tests.php` — benarkan PATCH 03 sambil menghalang DISCOVERY 04.
- `.github/workflows/canonical-names-lock.yml` — uji peringkat baharu bersama semua ujian terdahulu.
- `DEVELOPMENT_STAGE.md`, `README.md`, `SPAGHETTI_DEVELOPMENT_HISTORY.md` — status dan sejarah Bahasa Melayu.

## Fail yang mesti kekal tanpa perubahan

`src/Legacy/LegacyDistance.php`, semua fungsi legacy terdahulu, tampalan 01–02, oracle normatif, fixtures dan katalog nama sumber. Tiada perubahan kepada `main`.

## Arahan ujian penerimaan

```text
php -d memory_limit=512M tests/stage01_tests.php
php -d memory_limit=512M tests/bigint_division_regression.php
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
php -d memory_limit=512M tests/verify_stage04_discovery02.php
php -d memory_limit=512M tests/stage05_patch02_tests.php
php -d memory_limit=512M tests/verify_stage06_discovery03.php
php -d memory_limit=512M tests/stage07_patch03_tests.php
```

Pemeriksaan sintaks semua PHP, regenerasi fixture tanpa diff dan kunci nama kanonik turut diperlukan. Regresi Stage 6 secara langsung masih keluar kod 1 untuk 144 kes; pembalut pemeriksa mesti hijau. Stage 7 mesti hijau sepenuhnya.

**Sempadan:** Stage 8 (DISCOVERY 04) belum dibenarkan, dan tiada kod `mutateStonesWrong` boleh dimasukkan.

## Tajuk commit dicadangkan

`stage07(php-ms): betulkan jarak inklusif melalui pembalut warisan`

## Bukti pemeriksaan CI yang benar-benar dijalankan

Aliran `Canonical Names Lock` run `38157374399` untuk commit `3b2984b29f2881a960e2df4b643f2726f7521c25` telah **lulus sepenuhnya**: kedua-dua kerja `verify` dan `audit_php_bahasa_melayu` berstatus `success`. Bukti utama:

```text
RINGKASAN lulus=15 gagal=0
LULUS bigint_division_regression kes=1014 tambahan=8
KEPUTUSAN MERAH_DIJANGKA perbezaan=3 sepadan=1 lain=0
LULUS Stage 3 PATCH 01 kes=94 baki_sifar=21 warisan=3
KEPUTUSAN MERAH_DIJANGKA perbezaan=65 sepadan=64 tepi=2 lain=0
LULUS Stage 5 PATCH 02 kes=4618 sebelum=2305 pada_atau_selepas=2311 asas=1 tepi=2
KEPUTUSAN MERAH_DIJANGKA perbezaan=144 jumlah=144 tepi=8 lain=0
LULUS kontrak merah khusus 03; legacy kekal salah dan produksi ditampal
LULUS Stage 7 PATCH 03 kes=16668 oracle=16656 tepi=12 simetri=16668 anjakan=1285
```

Kemas kini ini hanya menambah bukti ke dokumen serahan. Kod produksi dan semua ujian tidak diubah. Peringkat berikutnya ialah Stage 8 — DISCOVERY 04 dan belum dimulakan.
