# Pelaksanaan PHP + Bahasa Melayu — Stage 1

Projek ini ialah bootstrap bebas untuk garis pelaksanaan PHP dengan Bahasa Melayu sebagai bahasa sumber manusia. Ia dibina daripada kosong berdasarkan rujukan normatif terbenam dalam arahan Stage 1. Tiada kod, ujian, fixture, output, hash atau artifak daripada pelaksanaan lain digunakan.

## Kandungan Stage 1

- `src/BigInt.php` menyediakan integer ketepatan sewenang-wenangnya dalam PHP tulen tanpa GMP, BCMath, FFI atau runtime bahasa lain.
- `src/SourceLanguageCatalog.php` menyimpan 17 nama potongan dan 47 nama bulan dengan `canonicalIndex` tetap.
- `src/BootstrapInfrastructure.php` menyediakan konteks asas, dispatcher asas, validator asas, sempadan ralat dan cangkerang metrik yang neutral.
- `src/BootstrapKernel.php` menyediakan probe bootstrap sahaja. Ia belum mengandungi laluan legacy atau tampalan masa hadapan.
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
