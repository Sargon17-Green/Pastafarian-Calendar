# Pelaksanaan PHP + Bahasa Melayu — Stage 9 (PATCH 04)

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


## Stage 5 — PATCH 02: Nombor hari sah tanpa menghapuskan kecacatan lama

`oldDayTag` dan laluan dispatcher `DAY_TAG_LEGACY` sengaja dikekalkan. `FoundationScarPatch02::dayTagWithFoundationScar` memanggil pengiraan lama, menambah satu pada Hari Asas serta selepasnya dan membiarkan cabang pemeriksaan sejarah tambahan pada Hari Asas. Dispatcher `DAY_TAG_PATCH_02` kini ialah laluan pengeluaran `BootstrapKernel::dayCount`. Tiada pembetulan Stage 6 dimulakan.

```text
php -d memory_limit=512M tests/verify_stage04_discovery02.php
php -d memory_limit=512M tests/stage05_patch02_tests.php
```

Pengujian sejarah yang dijalankan secara terus di `stage04_discovery02_tests.php` **masih keluar dengan kod 1 seperti yang dijangka**. Kedua-dua arahan di atas mesti keluar dengan kod 0. Ujian baharu meliputi kedua-dua sisi Hari Asas, sempadan integer mesin, perubahan ganjil/genap, dan kestabilan tampalan SAVE terdahulu.

## Stage 6 — DISCOVERY 03: Jarak hari sengaja kurang satu

Laluan `BootstrapKernel::distance(int $calculationDay, int $targetDay)` menggunakan `LegacyDistance::oldDistance` melalui dispatcher `DISTANCE_LEGACY`. Fungsi lama mengira `abs(t-c)`, tetapi bilangan jarak normatif ialah `abs(t-c)+1` kerana kedua-dua hari hujung termasuk dalam kiraan. Pengiraan jarak langkah menggunakan BigInt sepenuhnya agar pasangan ekstrem `PHP_INT_MIN/MAX` tidak melimpahi integer PHP. Penyelewengan ini sengaja tidak dibetulkan pada Stage 6; pembetulannya milik Stage 7.

```text
php -d memory_limit=512M tests/stage06_discovery03_tests.php
php -d memory_limit=512M tests/verify_stage06_discovery03.php
```

Arahan pertama **mesti** keluar dengan kod `1` dan tepat 144 perbezaan berlabel. Arahan kedua mesti keluar dengan kod `0` selepas mengesahkan corak khusus tersebut, ketiadaan tampalan jarak lebih awal, dan tiada ralat lain. Semua ujian Stage 1–5 terus perlu lulus.


## Stage 7 — PATCH 03: Jarak sebenar tanpa memadamkan sejarah

`LegacyDistance::oldDistance` terus sengaja mengira `abs(t-c)` dan dispatcher `DISTANCE_LEGACY` tidak dibuang. Adapter `DistanceCountPatch03::distanceCountPatch03` menambah satu kepada hasil lama. Laluan pengeluaran `BootstrapKernel::distance` kini menggunakan `DISTANCE_PATCH_03`, iaitu `abs(t-c)+1` untuk semua pasangan hari tanpa limpahan integer mesin.

```text
php -d memory_limit=512M tests/verify_stage06_discovery03.php
php -d memory_limit=512M tests/stage07_patch03_tests.php
```

Ujian sejarah langsung `stage06_discovery03_tests.php` masih sengaja keluar dengan kod `1` untuk 144 penyimpangan; kedua-dua arahan di atas mesti keluar dengan kod `0`. Ujian baharu merangkumi 16,668 pasangan dan 1,285 semakan anjakan, termasuk hujung `PHP_INT_MIN/MAX`. Semua ujian terdahulu, fixture dan katalog nama mesti kekal hijau. Jangan mulakan DISCOVERY 04 sebelum diminta.

## Stage 8 — DISCOVERY 04: Mutasi batu lama yang sengaja salah

`LegacyStoneMutation::mutateStonesWrong` mengemas kini lima batu secara berturutan dan membaca nilai yang sudah berubah. `buildStonesWrong()` menghasilkan 46 rekod dalam laluan `BootstrapKernel::stones()` melalui dispatcher `STONE_MUTATION_LEGACY`. Pada langkah 2 hanya batu `w` sepadan dengan oracle; empat batu lain tersasar. Pembaikan berasaskan snapshot mesti menunggu Stage 9.

```text
php -d memory_limit=512M tests/stage08_discovery04_tests.php
php -d memory_limit=512M tests/verify_stage08_discovery04.php
```

Perintah pertama mesti keluar dengan kod 1 selepas merekodkan 45 perbezaan yang dijangka dan satu baris asas yang sepadan. Pengesah kedua mesti keluar dengan kod 0. Semua ujian Stage 1–7, penjanaan fixture dan kunci nama kanonik mesti kekal hijau. Kaedah `stonePatch` tidak diwujudkan pada Stage 8.


## Stage 9 — PATCH 04: Snapshot batu dan panggilan legacy

`StonePatch04::stonePatch` menyimpan snapshot lima batu asal, memanggil `LegacyStoneMutation::mutateStonesWrong` secara sebenar pada salinan, kemudian menimpa semua lima hasil daripada **snapshot lama sahaja** menggunakan pembetul SAVE sedia ada. Legacy salah tidak diubah; laluan `STONE_MUTATION_LEGACY` kekal didaftarkan. Pengeluaran `BootstrapKernel::stones()` kini melalui `STONE_PATCH_04`.

```text
php -d memory_limit=512M tests/verify_stage08_discovery04.php
php -d memory_limit=512M tests/stage09_patch04_tests.php
```

Penemuan Stage 8 kekal merah melalui panggilan langsung ke legacy (45 rekod menyimpang, satu rekod asas sepadan); pembalut pengesah mesti hijau. Ujian Stage 9 memeriksa 46 rekod × 5 batu, sekurang-kurangnya 315 input sintetik serta had integer besar, pemilikan keadaan dan regresi Stage 1–7. Tiada kerja untuk Stage 10 dimulakan.
