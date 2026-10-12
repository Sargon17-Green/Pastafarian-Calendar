# Serahan Stage 8 — DISCOVERY 04

**Garis:** PHP + Bahasa Melayu
**Cabang:** `PHP+Bahasa-Melayu`
**Tahap:** 8/55, DISCOVERY 04
**Keadaan penerimaan:** EXPECTED_RED bagi ujian terus, GREEN bagi pengesah dan semua regresi terdahulu
**Asas:** `5743a0ffeb7ef87016f8ff2a6166460abfcaddea` (pembetulan kanonik Stage 7)

## Penemuan sejarah

Lima batu `w,b,s,m,r` disimpan dalam array yang sama lalu dikemas kini secara berurutan melalui `LegacyStoneMutation::mutateStonesWrong`. Setiap komponen selepas `w` membaca hasil baharu yang tidak sepatutnya digunakan. Ini menghasilkan jadual berbeza daripada oracle tempatan dan ialah keadaan merah yang diwajibkan bagi Stage 8; **jangan menampalnya di sini**.

Pada langkah 2, formula legacy menghasilkan (378,1434,3780,9932,25047), sedangkan formula normatif menghasilkan (378,1073,2375,6195,10493). Pembina lama mengekalkan 46 rekod dan penghala `STONE_MUTATION_LEGACY` menggunakan `BootstrapContext` baharu.

## Bukti dan cara menguji

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
```

Ujian langsung `stage08_discovery04_tests.php` harus keluar kod 1, dengan satu rekod asas sepadan, 45 rekod tersasar dan tiada ralat lain. Pengesahnya keluar kod 0 apabila tepat. Ujian regresi lain keluar kod 0. Semakan CI dilakukan selepas perubahan diterbitkan.

## Had wajib

Jangan ubah `LegacyDistance`, `DistanceCountPatch03`, oracle normatif, fixture atau katalog bahasa sumber. Jangan masukkan `stonePatch` atau snapshot pembetul sebelum Stage 9. Kekalkan semua kaedah lama dan ujian yang membuktikannya.

## Tajuk commit

`stage08(php-ms): dedahkan pencemaran mutasi batu berturutan`
