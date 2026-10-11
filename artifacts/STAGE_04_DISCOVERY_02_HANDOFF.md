# Serahan Stage 4 — DISCOVERY 02

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `28d8d7facea2e334e5403d7a6457f9123e801f06`  
**Peringkat:** 4/55 — DISCOVERY 02  
**Status yang dijangka:** EXPECTED_RED

## Perubahan yang dibuat

- Baharu: `src/Legacy/LegacyDayTag.php` — `oldDayTag(day) = 2 * abs(day - FOUNDATION)`, menggunakan BigInt untuk ketepatan di semua sempadan integer mesin.
- Diubah: `src/BootstrapKernel.php` — penghala `DAY_TAG_LEGACY` dan kaedah `dayCount(int)` yang memilih jalan sejarah tanpa pembetulan.
- Diubah: `tests/bootstrap.php` — memuatkan kelas lama yang baharu.
- Diubah: `tests/stage03_patch01_tests.php` — membenarkan parut Stage 4 sambil terus melarang tampalan Stage 5 dan penggunaan oracle dalam pengeluaran.
- Baharu: `tests/stage04_discovery02_tests.php` — bukti 65 ketakpadanan yang dijangka, 64 padanan, dan dua kes had integer.
- Baharu: `tests/verify_stage04_discovery02.php` — membezakan merah yang sah daripada kegagalan lain, dan melarang pembetulan awal.
- Diubah: `.github/workflows/canonical-names-lock.yml` — menjalankan pemeriksa penemuan selepas semua ujian terdahulu.
- Diubah: `DEVELOPMENT_STAGE.md`, `README.md`, `SPAGHETTI_DEVELOPMENT_HISTORY.md`.
- Baharu: `artifacts/STAGE_04_DISCOVERY_02_HANDOFF.md`.

**Tidak diubah:** `oldRemainder`, `SavePatch01`, katalog Bahasa Melayu, dan oracle normatif PHP.

## Tajuk commit yang dicadangkan

`stage04(php-ms): dedahkan tag hari lama dan bukti beza ganjil`

## Badan commit yang dicadangkan

`Perkenalkan oldDayTag sebagai laluan produksi nombor hari yang sengaja kekurangan pembetulan hari Asas dan hari kemudian. Kekalkan penghala serta tampalan SAVE Stage 3, tambah regresi 65 perbezaan dan 64 padanan bersama ujian had integer, dan sahkan bahawa tiada pembetulan hari diperkenalkan sebelum Stage 5. Kekalkan semua ujian tahap terdahulu hijau.`

## Bukti penerimaan

```text
php -d memory_limit=512M tests/stage01_tests.php
php -d memory_limit=512M tests/bigint_division_regression.php
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
php -d memory_limit=512M tests/verify_stage04_discovery02.php
```

Ujian terus `stage04_discovery02_tests.php` dijangka gagal dengan kod `1` semata-mata kerana divergence yang diperincikan. Pemeriksa pembalut dijangka lulus. Penjanaan semula fixture Stage 1 mestilah tidak menghasilkan diff. Tahap seterusnya ialah PATCH 02 (Stage 5), dan **tidak dimulakan dalam serahan ini**.
