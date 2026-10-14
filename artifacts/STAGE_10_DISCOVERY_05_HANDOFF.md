# Serahan Stage 10 — DISCOVERY 05

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `36ce0839812a5b193080e7a0da896e3586f3098f`  
**Tahap:** 10 daripada 55; DISCOVERY 05  
**Keadaan dijangka:** `EXPECTED_RED`

## Cacat sejarah

`LegacyHiddenBackward` mengira titisan ke-1 hingga ke-7 dengan formula normatif yang ditulis dalam PHP produksi, tetapi menyimpannya dalam slot songsang `8-k`. Pembaca `wrongNearness` masih menggunakan `k` terus dan menghasilkan nilai yang salah. Storan sengaja tidak dibetulkan dan semua tujuh nilai terus ada.

## Laluan produksi

`BootstrapKernel::hiddenDrops(calculationDay,targetDay)` melalui `HIDDEN_BACKWARD_LEGACY`, membina kiraan action, target, distance, connection, direction menggunakan pembetulan Stage 1–9, kemudian jadual batu Stage 9. Konteks, stor dan hasil dimiliki oleh panggilan itu sahaja. Oracle tidak dibaca oleh produksi.

## Ujian penerimaan

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
```

Ujian langsung Stage 10 keluar kod 1 bagi tepat 72 perbezaan, 12 padanan pada slot tengah, tanpa ralat lain. Pengesah Stage 10 keluar kod 0 untuk merah yang tepat. Kesemua ujian terdahulu, fixture dan kunci nama kanonik mesti hijau.

## Perubahan fail

Ditambah: `src/Legacy/LegacyHiddenBackward.php`, `tests/stage10_discovery05_tests.php`, `tests/verify_stage10_discovery05.php`, dokumen serahan ini.

Diubah: penghala `BootstrapKernel`, `tests/bootstrap.php`, konfigurasi CI, `DEVELOPMENT_STAGE.md`, `README.md` dan sejarah.

Tidak diubah: `LegacyStoneMutation`, `StonePatch04`, oracle dan fixture, kod atau cabang lain.

## Tajuk commit

`stage10(php-ms): dedahkan stor titisan tersembunyi yang songsang`
