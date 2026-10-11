# Pelaksanaan PHP + Bahasa Melayu — Stage 3 (PATCH 01)

Projek ini ialah bootstrap bebas untuk garis pelaksanaan PHP dengan Bahasa Melayu sebagai bahasa sumber manusia. Ia dibina daripada kosong berdasarkan rujukan normatif terbenam dalam arahan Stage 1. Tiada kod, ujian, fixture, output, hash atau artifak daripada pelaksanaan lain digunakan.

## Kandungan Stage 1

- `src/BigInt.php` menyediakan integer ketepatan sewenang-wenangnya dalam PHP tulen tanpa GMP, BCMath, FFI atau runtime bahasa lain.
- `src/SourceLanguageCatalog.php` menyimpan 17 nama potongan dan 47 nama bulan dengan `canonicalIndex` tetap.
- `src/BootstrapInfrastructure.php` menyediakan konteks asas, dispatcher asas, validator asas, sempadan ralat dan cangkerang metrik yang neutral.
- `src/BootstrapKernel.php` mengekalkan probe asal bersama laluan legacy sejarah dan laluan produksi bertampal.
- `tests/oracle/` mengandungi oracle normatif khusus ujian yang dibina semula dalam PHP.
- `tests/fixtures_stage01.json` mengandungi fixture yang dijana semula oleh oracle tempatan garis ini.
- `tools/generate_stage01_fixtures.php` menjana fixture menggunakan PHP sahaja.
- `tests/stage01_tests.php` menjalankan ujian exact arithmetic, katalog bahasa sumber, sauce, pemilihan, gate, Year 5000 dan semakan keluarga kombinatorik kecil terhadap enumerasi brute-force tempatan.

## Menjalankan ujian

```text
php -d memory_limit=512M tests/stage01_tests.php
```

Keadaan Stage 1 yang sah ialah semua ujian lulus dan tiada token kod tampalan masa hadapan muncul dalam `src/`.

## Menjana semula fixture

```text
php -d memory_limit=512M tools/generate_stage01_fixtures.php
```

Fixture hanya boleh dijana daripada oracle PHP dalam garis pelaksanaan ini. Ia tidak boleh diganti dengan output daripada pelaksanaan lain.

## Had Stage 1

Stage 1 sengaja tidak memasukkan kecacatan legacy atau tampalan 01–26. Laluan production pada tahap ini hanyalah rangka bootstrap neutral. Oracle ujian sudah mempunyai definisi normatif penuh yang diperlukan untuk perbandingan pada tahap-tahap berikutnya.

## Audit ketepatan integer (selepas Stage 1)

Ujian tambahan menegaskan semantik pembahagian lantai untuk pembahagi positif **dan negatif**: `a = b*q + r`, `|r| < |b|`, dan tanda baki mengikut pembahagi. Laluan `modSmall` untuk pembahagi besar tidak boleh mendarab baki dengan asas limb sehingga melimpahi integer 64-bit.

```text
php -d memory_limit=512M tests/bigint_division_regression.php
```

Aliran CI khusus cabang ini menjalankan sintaks PHP, 15 ujian Stage 1, ujian regresi pembahagian, dan penjanaan semula fixture secara deterministik. Audit ini tidak memperkenalkan tampalan legacy Stage 2.

## Stage 2 — Penemuan pertama, belum dibaiki

Laluan pengeluaran `BootstrapKernel::save(BigInt)` sengaja menggunakan baki modulo lama `LegacyRemainder::oldRemainder`. Laluan ini berbeza daripada `SAVE` normatif bagi `M`, `2M` dan `3M`. Ini bukan kegagalan yang perlu ditutup pada Stage 2: perbaikannya hanya dibenarkan dalam Stage 3 (`PATCH 01`).

```text
php -d memory_limit=512M tests/stage02_discovery01_tests.php
php -d memory_limit=512M tests/verify_stage02_discovery01.php
```

Arahan pertama mesti keluar dengan kod `1` (tiga `GAGAL_DIJANGKA`); arahan kedua mesti keluar dengan kod `0` setelah menyemak kegagalan khusus tersebut dan ketiadaan `savePatch`. Kekalkan 15 ujian Stage 1 dan ujian integer tepat.

## Stage 3 — Tampalan pertama, keadaan hijau

`LegacyRemainder::oldRemainder` sengaja dikekalkan tanpa perubahan. Adapter `SavePatch01::savePatch` mengembalikan `M` apabila baki lama sifar; jika tidak, ia mengembalikan baki asal. Dispatcher `SAVE_PATCH_01` kini menjadi laluan pengeluaran `BootstrapKernel::save`, manakala `SAVE_LEGACY` tetap wujud sebagai parut sejarah.

```text
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
```

Ujian sejarah terus membuktikan kegagalan legacy yang dijangka. Ujian Stage 3 membuktikan bahawa laluan baharu sepadan dengan `SAVE` normatif bagi integer positif, negatif, sifar, gandaan M, sempadan mesin dan integer besar. Kedua-dua perintah di atas mesti keluar dengan kod `0`. Jangan mulakan penemuan kedua sebelum tahap ini disahkan.


## Stage 4 — DISCOVERY 02: Nombor hari legacy sengaja tersilap

Laluan `BootstrapKernel::dayCount(int)` kini menggunakan `LegacyDayTag::oldDayTag` melalui dispatcher `DAY_TAG_LEGACY`. Ia mengira `2 * abs(day - FOUNDATION)` dengan integer tepat, tetapi tertinggal tambahan satu pada Hari Asas dan semua hari selepasnya. Laluan SAVE yang dibetulkan dalam Stage 3 tidak disentuh. Jangan menambah pembetulan untuk kecacatan hari sehingga Stage 5.

```text
php -d memory_limit=512M tests/stage04_discovery02_tests.php
php -d memory_limit=512M tests/verify_stage04_discovery02.php
```

Arahan pertama mesti keluar dengan kod `1`, menunjukkan 65 perbezaan dijangka dan 64 padanan normatif di sekeliling Hari Asas. Arahan kedua mesti keluar dengan kod `0`, mengesahkan corak merah khusus itu, dua semakan sempadan int dan ketiadaan tampalan Stage 5.
