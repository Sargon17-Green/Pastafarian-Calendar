# Serahan Stage 5 — PATCH 02

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas awal:** `725aa36b67a32dc22bdcb13b7884b59c3bcf1d08`  
**Peringkat:** 5/55, PATCH 02  
**Keadaan dijangka:** GREEN

## Semantik dan bentuk sejarah

Kekalkan pengiraan lama `oldDayTag(day) = 2 * abs(day - FOUNDATION)` dalam `LegacyDayTag`, bersama dispatcher `DAY_TAG_LEGACY`. Tambah `FoundationScarPatch02::dayTagWithFoundationScar` yang mengambil hasil lama; tambah satu untuk `day >= FOUNDATION`; selepas itu kekalkan syarat sejarah `if day == FOUNDATION and n != 1 then n = 1`. Jangan baiki sumber lama, jangan panggil oracle dalam pengeluaran dan jangan melaksanakan Stage 6.

## Fail serahan

- Baharu: `src/Patches/FoundationScarPatch02.php`, `tests/stage05_patch02_tests.php`, `artifacts/STAGE_05_PATCH_02_HANDOFF.md`.
- Diubah: `src/BootstrapKernel.php`, `tests/bootstrap.php`, `tests/stage03_patch01_tests.php`, `tests/stage04_discovery02_tests.php`, `tests/verify_stage04_discovery02.php`, `.github/workflows/canonical-names-lock.yml`, `DEVELOPMENT_STAGE.md`, `README.md`, `SPAGHETTI_DEVELOPMENT_HISTORY.md`.
- Kekal tanpa perubahan: `src/Legacy/LegacyDayTag.php`, `src/Legacy/LegacyRemainder.php`, `src/Patches/SavePatch01.php`, oracle PHP dan katalog bahasa Melayu.

## Tajuk commit dicadangkan

`stage05(php-ms): balut tag hari lama dengan parut Hari Asas`

## Badan commit dicadangkan

`Tambahkan FoundationScarPatch02 di atas oldDayTag tanpa mengubah kesilapan sejarahnya. Alihkan dayCount pengeluaran kepada DAY_TAG_PATCH_02 sambil mengekalkan DAY_TAG_LEGACY dan bukti merah Stage 4. Jalankan ujian normatif meliputi ribuan hari, had integer mesin, determinisme, kestabilan SAVE Stage 3 dan ketidakhadiran kod tahap seterusnya.`

## Penerimaan CI

Semua ujian sebelum ini perlu lulus, bukti merah legacy kekal disahkan oleh pembalut hijau, dan `tests/stage05_patch02_tests.php` mesti hijau. Penjanaan fixture mestilah tidak mengubah fail. Tiada kod pembetulan Stage 6 dibenarkan.

**Tahap seterusnya:** DISCOVERY 03, Stage 6 — belum dimulakan.

## Bukti daripada larian CI pertama

Run `38155098345` berjaya bagi `verify` dan `audit_php_bahasa_melayu`. Ringkasan sebenar ujian `Stage 5 PATCH 02`: `kes=4618 sebelum=2305 pada_atau_selepas=2311 asas=1 tepi=2`. Semua 15 ujian Stage 1 dan 1,014+8 ujian pembahagian lulus, dan bukti kegagalan legacy kedua-dua tampalan kekal menurut kontrak. Pembetulan selepas larian ini hanya menambah rekod audit dan membetulkan satu perkataan komen kepada Bahasa Melayu; semantik pengeluaran, oracle dan ujian kes tidak berubah.
