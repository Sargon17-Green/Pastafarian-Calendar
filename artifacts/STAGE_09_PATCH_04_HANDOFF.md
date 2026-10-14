# Serahan Stage 9 — PATCH 04

**Cabang:** `PHP+Bahasa-Melayu`
**Asas:** `89ecc6fa41193cfb261d179ec0a2d953e0385ed8`
**Tahap:** 9/55 — PATCH 04
**Keadaan dijangka:** GREEN

## Kontrak mutasi dan snapshot

`src/Legacy/LegacyStoneMutation.php` tidak diubah: lima komponen masih tercemar akibat pembacaan nilai baharu secara berurutan. `StonePatch04::stonePatch` menyimpan salinan asal `old`, memanggil `mutateStonesWrong` pada salinan `garbage`, lalu menimpa kesemua lima medan `garbage` dengan rumus yang hanya merujuk `old` dan `SavePatch01`. Jangan buang panggilan legacy sebenar.

## Penghala produksi

`BootstrapKernel::stones` beralih kepada `STONE_PATCH_04`; `STONE_MUTATION_LEGACY` masih didaftarkan. Setiap permintaan mencipta objek penampal dan konteks semantik tersendiri.

## Ujian

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
```

Pemeriksaan sejarah Stage 8 secara langsung masih pulang kod 1 untuk 45 penyimpangan dan satu padanan; pemeriksa Stage 8 mesti pulang kod 0. Tampalan Stage 9 dan seluruh suite regresi mesti hijau. Kunci nama kanonik dan fixture perlu tiada diff.

## Fail

Ditambah: `src/Patches/StonePatch04.php`, `tests/stage09_patch04_tests.php`, dokumen serahan ini.

Diubah: penghala dalam `src/BootstrapKernel.php`, `tests/bootstrap.php`, ujian sejarah Stage 8 dan pengesahnya, ujian Stage 3/5/7 untuk membenarkan tampalan keempat, workflow dan dokumen tahap.

Tidak diubah: seluruh komponen legacy, sumber oracle tempatan, katalog nama, fixtures dan cabang `main`.

## Tajuk commit

`stage09(php-ms): betulkan batu melalui snapshot tanpa memadam legacy`
