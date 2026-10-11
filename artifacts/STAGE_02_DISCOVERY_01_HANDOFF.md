# Serahan Stage 2 — DISCOVERY 01

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas yang disahkan sebelum perubahan:** `0e6ec66232cd1fb70364ae1255e3217b1b747f61`  
**Jenis:** Penemuan 01, tiada tampalan  
**Keadaan dijangka:** `EXPECTED_RED`

## Fail yang diubah

- `src/Legacy/LegacyRemainder.php` — baharu, `oldRemainder = regularMod(x,M)`, sengaja memulangkan sifar.
- `src/BootstrapKernel.php` — dispatcher `SAVE_LEGACY` dan laluan awam `save()`.
- `tests/bootstrap.php` — memuatkan kelas legacy.
- `tests/stage02_discovery01_tests.php` — regresi sengaja merah.
- `tests/verify_stage02_discovery01.php` — pengesahan bahawa hanya merah yang ditetapkan wujud.
- `.github/workflows/canonical-names-lock.yml` — menambah pengesah regresi ini.
- `DEVELOPMENT_STAGE.md`, `README.md`, `SPAGHETTI_DEVELOPMENT_HISTORY.md` — status dan sejarah.

## Tajuk commit yang dicadangkan

`stage02(php-ms): dedahkan baki modulo lama dan rekodkan penemuan SAVE pertama`

## Badan commit yang dicadangkan

`Aktifkan laluan SAVE_LEGACY melalui konteks, dispatcher dan sempadan ralat yang sedia ada. Kekalkan oldRemainder sebagai kesilapan sejarah yang menghasilkan sifar pada gandaan M. Tambah regresi perbandingan dengan oracle PHP tempatan untuk M, 2M, 3M dan M+1; pastikan tiga kegagalan dijangka, semua ujian terdahulu kekal lulus, dan jangan masukkan savePatch sebelum Stage 3.`

## Batasan

Ini ialah satu peringkat sahaja. Tidak boleh memperkenalkan `savePatch` atau sebarang pembetulan masa hadapan. Pemeriksaan CI perlu merekod kegagalan regresi terus sebagai dijangka dan pengesah kontrak sebagai lulus.
