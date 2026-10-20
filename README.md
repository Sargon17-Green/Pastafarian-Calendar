# Pelaksanaan PHP + Bahasa Melayu — Stage 16 (DISCOVERY 08)

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


## Stage 10 — DISCOVERY 05: Stor titisan tersembunyi disongsangkan

`LegacyHiddenBackward::buildStoredBackward` mengira tujuh titisan tersembunyi melalui rumus PHP tulen, tetapi menyimpan `hidden7` pada slot 1 hingga `hidden1` pada slot 7. Pembaca sejarah `wrongNearness` salah menganggap slot `k` menyimpan titisan `k` yang terdekat. Ini menghasilkan perbezaan terancang dalam `BootstrapKernel::hiddenDrops(c,t)` melalui penghala `HIDDEN_BACKWARD_LEGACY`.

```text
php -d memory_limit=512M tests/stage10_discovery05_tests.php
php -d memory_limit=512M tests/verify_stage10_discovery05.php
```

Ujian pertama sengaja merah: 12 pasangan hari dengan 72 penyimpangan dan 12 padanan pada slot 4. Pengesah kedua hijau hanya apabila setiap penyimpangan sepadan dengan stor songsang dan tiada ralat lain. Ujian Stage 1–9 kekal hijau. **Jangan balikkan stor dan jangan tambahkan `hiddenByNearness` sehingga Stage 11.**


## Stage 11 — PATCH 05: Akses titisan menurut jarak

`HiddenNearnessPatch05::hiddenByNearness` mengubah indeks bacaan kepada `8-k` lalu memanggil pembaca sejarah `LegacyHiddenBackward::wrongNearness` **tanpa menyusun semula tatasusunan**. Penghala produksi `HIDDEN_PATCH_05` masih membina stor terbalik dan mengekalkan penghala `HIDDEN_BACKWARD_LEGACY` untuk bukti sejarah.

```text
php -d memory_limit=512M tests/verify_stage10_discovery05.php
php -d memory_limit=512M tests/stage11_patch05_tests.php
```

Ujian penemuan Stage 10 dijalankan terus terhadap legacy dan kekal merah dengan 72 perbezaan, 12 padanan, manakala pembalut pengesahnya hijau. Ujian Stage 11 memeriksa kesetaraan 37 pasangan × tujuh titisan, 128 set slot sintetik, hasil berulang/per-instance, ralat indeks dan regresi penuh Stage 1–9. Tiada tampalan 06 atau perubahan oracle.


## Stage 12 — DISCOVERY 06: Sejarah prior buta terhadap titisan tersembunyi

Fungsi `LegacyVisiblePrior::legacyPrior(dropStore,i,back)` menggunakan `dropStore[i-back]` secara langsung. Ia berjaya membaca titisan terlihat apabila `i-back >= 1`, tetapi bagi slot sifar atau negatif ia memulangkan `null` dan gagal menjangkau hidden1 hingga hidden7. Kecacatan sejarah ini mesti dikekalkan untuk dibetulkan oleh PATCH 06 pada Stage 13.

`BootstrapKernel::priorLegacy` menyediakan penghala `VISIBLE_PRIOR_LEGACY` dan konteks milik setiap panggilan. Bukti Stage 12 menggunakan stor terlihat sintetik yang deterministik kerana penjanaan 46 titisan terlihat yang sebenar belum bermula, sambil menguji hidden sebenar daripada PATCH 05 menggunakan oracle PHP tempatan.

```text
php -d memory_limit=512M tests/stage12_discovery06_tests.php
php -d memory_limit=512M tests/verify_stage12_discovery06.php
```

Ujian pertama dijangka keluar kod 1 dengan tepat 44 kehilangan slot hidden, 508 bacaan terlihat yang betul, 28 nilai hidden yang sepadan dan sifar ralat tidak dijangka. Pembalut kedua menerima RED yang tepat dengan kod 0. GitHub Actions run `38894141862` bagi commit `255fc02e37a8071bc7ab98948a91df4abcef1c34` telah **lulus kedua-dua kerja**, termasuk pembalut baharu dan semua ujian Stage 1–11. Stage 13 belum bermula.


## Stage 13 — PATCH 06: Akses prior dari sejarah dan hidden

`PriorAccessPatch06::priorPatch(dropStore,legacyHidden,i,back)` mengira `slot=i-back`. Untuk `slot>=1`, ia **mesti** memanggil `LegacyVisiblePrior::legacyPrior` yang wujud sejak Stage 12. Apabila `slot<=0`, `k=1-slot` dipetakan melalui `HiddenNearnessPatch05::hiddenByNearness(legacyHidden,k)`, tanpa menyusun semula stor hidden7..hidden1. Ini memulihkan akses hidden1..hidden7 tanpa menghapus fungsi legacy yang salah.

`BootstrapKernel::prior` menghala ke `PRIOR_PATCH_06` melalui konteks setiap panggilan, manakala `priorLegacy` dan `VISIBLE_PRIOR_LEGACY` kekal untuk bukti sejarah. Panggilan produksi menerima stor visible dan hidden yang disediakan pemanggil, kerana penjanaan 46 titisan visible hanya bermula pada tahap seterusnya.

```text
php -d memory_limit=512M tests/verify_stage12_discovery06.php
php -d memory_limit=512M tests/stage13_patch06_tests.php
```

Ujian Stage 13 meliputi 6 pasangan hari, 762 akses visible, 66 akses hidden dan 42 nilai hidden yang dibandingkan dengan oracle PHP, disertai 2,688 kes stor sintetik, 7 penolakan input serta regresi lama. Bukti sejarah Stage 12 masih merah secara langsung (44 missing/508 found/28 hidden pada 4 pasangan), tetapi pembalutnya hijau. Pengesahan CI hanya diiktiraf selepas hasil run sebenar diperiksa. Stage 14 tidak dimulakan.


## Stage 14 — DISCOVERY 07: Indeks jadual pengisaran salah

`LegacyVisibleGrind` mengandungi 11 baris pengisaran sah dengan indeks array sejarah `0..10`, tetapi `legacyRowAt(g)` membaca indeks `1..11`. Akibatnya pengisaran pertama memakai baris kedua, pengisaran kesepuluh memakai baris kesebelas, manakala pengisaran kesebelas menggunakan fallback baris sifar. Ini ialah kecacatan sejarah yang disengajakan, **bukan pembetulan**.

Pembina `buildVisibleWrong` menggunakan formula titisan lengkap dan 46 batu yang sudah dibetulkan. Setiap bacaan titisan terdahulu melalui `PriorAccessPatch06` dan setiap hidden daripada stor backward `LegacyHiddenBackward` melalui PATCH05. Penghala `VISIBLE_GRIND_LEGACY` berada dalam `BootstrapKernel::visibleDrops`, dengan konteks per panggilan dan tanpa oracle produksi.

```text
php -d memory_limit=512M tests/stage14_discovery07_tests.php
php -d memory_limit=512M tests/verify_stage14_discovery07.php
```

Ujian pertama mesti merah secara terkawal dengan tepat 138 ketakpadanan (3 pasangan hari × 46 titisan), ketiga-tiga jadual berbentuk betul dan nilai modulo dalam julat. Pengesah kedua mesti hijau hanya bagi bukti merah itu. Semua regresi Stage 1–13, termasuk bukti sejarah Stage 12, kekal diwajibkan.

Stage 15 (PATCH 07) kelak akan menambah **baris sentinel di indeks 0** dan mengalihkan 11 baris nyata ke `1..11` tanpa membuang pembaca sejarah `legacyRowAt`. Jangan tambah sentinel pada Stage 14. Jangan bina permutasi Stage 16 lebih awal.


## Stage 15 — PATCH 07: Sentinel bagi jadual pengisaran terlihat

`GrindTablePatch07` membina jadual baharu tanpa mengubah `LegacyVisibleGrind::legacyGrindRows`. Pada indeks **0** terdapat baris `[0,0,0,0,'none']` sebagai sentinel; sebelas baris sejarah asal dipetakan menurut `new[index+1]=old[index]`, tepat pada indeks **1..11**. Pengira produksi memanggil `LegacyVisibleGrind::buildVisibleWrong` melalui instance yang disuntik jadual pembetul, maka `legacyRowAt(g)` tetap dibaca secara sebenar pada semua 11 pengisaran.

`BootstrapKernel::visibleDrops` melalui `VISIBLE_GRIND_PATCH_07`, manakala `BootstrapKernel::visibleDropsLegacy` melalui `VISIBLE_GRIND_LEGACY`, dengan pembinaan konteks berasingan. Formula SAVE, batu, hidden, prior dan 46 titisan terlihat tidak ditulis semula; kelas legacy lama dan cacat indeksnya masih wujud. Tiada oracle di kod produksi.

```text
php -d memory_limit=512M tests/verify_stage14_discovery07.php
php -d memory_limit=512M tests/stage15_patch07_tests.php
```

Ujian PATCH 07 mesti memeriksa setiap 46 titisan bagi lapan pasangan tarikh, menghasilkan 368 perbandingan terhadap oracle tempatan, tiga jadual sejarah merah yang masing-masing berbeza pada 46 titisan (138 parut) dan pemilikan konteks. Ia juga menguji setiap baris sentinel dan indeks 1..11, 1,408 pemeriksaan baris, serta input indeks salah. Ujian sejarah Stage 14 tetap merah secara langsung dan pengesahnya hijau. Semua ujian Stage 1–13 masih wajib lulus.

Stage 16 — DISCOVERY 08 belum dimulakan; jangan cipta penilaian permutasi lebih awal.


## Stage 16 — DISCOVERY 08: Pangkat satu dihantar ke fungsi pangkat sifar

`LegacyPermutationUnrank0::oldPermutationUnrank0` mengira permutasi enam mangkuk secara leksikografik dengan domain tepat **0..719**. Pembaca sejarah `LegacyBowlPermutation::legacyBowlOrderFromDrop` mengira pangkat satu `1+((drop-1) mod 720)`, kemudian dengan salah terus menyerahkan pangkat **1..720** kepada fungsi pangkat sifar. Hasilnya pangkat 1..719 memilih permutasi berikutnya, sementara pangkat 720 ditolak dengan `PERMUTATION_RANK_ZERO_RANGE`. Tiada pembetulan pangkat dibuat pada Stage ini.

Penghala `BOWL_PERMUTATION_LEGACY` serta `BootstrapKernel::legacyBowlOrder` membuka laluan per-panggilan untuk memeriksa kerosakan dengan `BigInt` termasuk nilai negatif dan amat besar. Penilaian mangkuk belum dipasang dalam produksi; fasa itu datang kemudian dan tidak boleh dicipta sebelum masa.

```text
php -d memory_limit=512M tests/stage16_discovery08_tests.php
php -d memory_limit=512M tests/verify_stage16_discovery08.php
```

Ujian langsung sejarah mesti RED terkawal dengan 719 pangkat tersasar dan satu pangkat di luar julat, manakala pengesah hijau hanya bagi corak tepat itu. Fungsi sifar diuji sendiri terhadap semua 720 permutasi normatif; 46 titisan visible Stage 15 juga diuji. Semua regresi Stage 1–15 kekal hijau. **PATCH 08 Stage 17 belum diperkenalkan.**
