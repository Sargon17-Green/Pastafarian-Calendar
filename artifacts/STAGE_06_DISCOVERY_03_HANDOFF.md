# Serahan Stage 6 — DISCOVERY 03

**Cabang:** `PHP+Bahasa-Melayu`  
**Commit asas sebelum perubahan:** `176d01d81393db9de68d6dfd4b1ea433dcfceed3`  
**Tahap:** 6/55 — DISCOVERY 03  
**Keadaan kontrak:** `EXPECTED_RED`

## Definisi semantik

Nilai sah `distance(c,t) = abs(t-c)+1`, manakala laluan lama baharu `oldDistance(c,t) = abs(t-c)`. Kedua-duanya dikira sebagai BigInt apabila melibatkan julat integer yang luas. Hari sama: `1` lawan `0`; hari berturutan: `2` lawan `1`; pasangan ekstrem ditangani tanpa limpahan integer mesin.

## Fail yang ditambah

- `src/Legacy/LegacyDistance.php` — pengiraan sejarah yang sengaja salah; tiada tampalan.
- `tests/stage06_discovery03_tests.php` — bukti 144 perbezaan semantik yang tepat.
- `tests/verify_stage06_discovery03.php` — pengesah subprocess yang mesti hijau untuk kegagalan dijangka sahaja.
- `artifacts/STAGE_06_DISCOVERY_03_HANDOFF.md` — serahan keadaan kerja.

## Fail yang diubah

- `src/BootstrapKernel.php` — laluan `DISTANCE_LEGACY` dan API `distance()`.
- `tests/bootstrap.php` — pendaftaran kelas legacy baharu.
- `tests/stage03_patch01_tests.php` dan `tests/stage05_patch02_tests.php` — benarkan penemuan ketiga, terus melarang tampalan ketiga.
- `.github/workflows/canonical-names-lock.yml` — aktifkan pemeriksa penemuan dalam CI.
- `DEVELOPMENT_STAGE.md`, `README.md`, `SPAGHETTI_DEVELOPMENT_HISTORY.md` — kemas kini status dan sejarah Bahasa Melayu.

## Yang tidak diubah

Semua kelas dan tampalan Stage 1–5, oracle PHP, fail fixture dan katalog bahasa sumber. `main` tidak disentuh.

## Perintah penerimaan

```text
php -d memory_limit=512M tests/stage01_tests.php
php -d memory_limit=512M tests/bigint_division_regression.php
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
php -d memory_limit=512M tests/verify_stage04_discovery02.php
php -d memory_limit=512M tests/stage05_patch02_tests.php
php -d memory_limit=512M tests/verify_stage06_discovery03.php
```

Jalankan juga penjanaan semula fixture dan sahkan tiada `git diff`. Pengesah akhir mesti melaporkan `perbezaan=144 jumlah=144 tepi=8 lain=0`, sambil semua ujian terdahulu lulus. Ujian merah langsung sengaja keluar dengan kod `1`.

## Henti kerja dan langkah seterusnya

Jangan mula Stage 7 tanpa arahan baharu. PATCH 03 yang akan datang perlu membalut operasi lama dengan pembetulan bilangan hujung, tanpa memadamkan `oldDistance`. Catat hasil CI yang sebenar setelah tersedia.
