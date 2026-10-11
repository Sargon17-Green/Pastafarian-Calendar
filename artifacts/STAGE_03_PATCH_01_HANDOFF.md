# Serahan Stage 3 — PATCH 01

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `67eb78c737729f5a093ca003cbcce0d375af28a0`  
**Tahap:** `3/55`  
**Jenis:** `PATCH`, nombor `01`  
**Keadaan dijangka:** `GREEN`

## Pembetulan dan sejarah

Kesilapan lama `oldRemainder(x) = x mod M` tidak disentuh. Lapisan `SavePatch01` melaksanakan `r = oldRemainder(x); if r == 0 then r = M; return r`. Dispatcher produksi melaksanakan `SAVE_PATCH_01`, bukan `SAVE_LEGACY`. Yang terakhir kekal untuk menunjukkan laluan bersejarah.

## Fail yang ditambah atau diubah

- **Baharu:** `src/Patches/SavePatch01.php`, `tests/stage03_patch01_tests.php`, `artifacts/STAGE_03_PATCH_01_HANDOFF.md`.
- **Diubah:** `src/BootstrapKernel.php`, `tests/bootstrap.php`, `tests/stage02_discovery01_tests.php`, `tests/verify_stage02_discovery01.php`, `.github/workflows/canonical-names-lock.yml`, `DEVELOPMENT_STAGE.md`, `README.md`, `SPAGHETTI_DEVELOPMENT_HISTORY.md`.
- **Tidak diubah:** `src/Legacy/LegacyRemainder.php`, katalog nama sumber dan oracle normatif.

## Perintah dan kriteria penerimaan

```text
php -d memory_limit=512M tests/stage01_tests.php
php -d memory_limit=512M tests/bigint_division_regression.php
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
php -d memory_limit=512M tools/generate_stage01_fixtures.php
```

Ujian penemuan lama terus memperlihatkan tiga perbezaan yang diharapkan melalui kaedah legacy. Ujian produksi Stage 3 mesti hijau sepenuhnya dan fixture tidak berubah.

## Tajuk commit yang dicadangkan

`stage03(php-ms): tampal SAVE tanpa membuang baki lama`

## Badan commit yang dicadangkan

`Tambahkan adapter SAVE yang menormalkan baki sifar kepada M, tanpa mengubah oldRemainder atau dispatcher warisan. Alihkan laluan pengeluaran kepada SAVE_PATCH_01, kekalkan regresi penemuan sebagai bukti sejarah pada kaedah legacy, dan uji kesetaraan dengan oracle PHP tempatan untuk integer positif, negatif dan sangat besar. Semua ujian terdahulu kekal diwajibkan dan tiada tampalan masa hadapan diperkenalkan.`

## Sempadan

Jangan melaksanakan Stage 4 atau menghapuskan kecacatan lama semasa Stage 3. Jika CI tidak hijau, baiki Stage 3 sahaja.
