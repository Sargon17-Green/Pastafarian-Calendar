# Pelaksanaan PHP + Bahasa Melayu — Stage 35 (PATCH 17)

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


## Stage 17 — PATCH 08: Pembetulan pangkat satu kepada pangkat sifar

`PermutationPatch08::permutationPatch` menerima titisan BigInt, menggunakan `LegacyBowlPermutation::oneBasedRank` bagi pangkat satu 1..720, lalu **memanggil `legacyBowlOrderFromDrop` secara sebenar** untuk mengekalkan jejak kecacatan sejarah. Apabila pangkat satu 720, kelas legacy masih melemparkan `PERMUTATION_RANK_ZERO_RANGE`; pembetul memeriksa kes khusus itu sebelum mengembalikan hasil yang sah.

Untuk semua input, pangkat satu ditukar kepada pangkat sifar menggunakan `rank0=rank1-1` dan fungsi `LegacyPermutationUnrank0::oldPermutationUnrank0(rank0)` yang sah. Oleh itu rank1 720 menghasilkan permutasi terakhir dan tidak lagi gagal dalam laluan produksi.

`BootstrapKernel::bowlOrder` menggunakan `BOWL_PERMUTATION_PATCH_08` dalam konteks per panggilan. `legacyBowlOrder` dan `BOWL_PERMUTATION_LEGACY` kekal terdedah untuk menguji secara langsung 719 perbezaan dan satu pengecualian Stage 16. Tiada aplikasi campuran enam mangkuk ke 46 titisan yang sebenar lagi, kerana peringkat tersebut datang kemudian.

```text
php -d memory_limit=512M tests/verify_stage16_discovery08.php
php -d memory_limit=512M tests/stage17_patch08_tests.php
```

Ujian hijau Stage 17 membandingkan **semua 720 permutasi** dengan oracle tempatan, memastikan 720 susunan unik, 719 hasil legacy salah yang dikekalkan, satu pengecualian legacy, 14 integer besar/negatif, serta 138 permutasi daripada tiga set 46 titisan visible. Semua ujian Stage 1–16 kekal wajib dan Stage 18 belum dimulakan.


## Stage 18 — DISCOVERY 09: Tuangan membaca ID mangkuk tetap

`LegacyBowlFactory` menghitung nilai enam mangkuk asal bagi kiraan tindakan, sasaran, jarak, sambungan dan arah menggunakan `SavePatch01` serta nombor perdana 17,19,23,29,31,37. Kilang ini dibandingkan dengan oracle ujian sahaja.

`LegacyFixedPositionPours::legacyPours` menerima order enam mangkuk yang sah daripada PATCH08 Stage17, tetapi pembaca sejarah masih menganggap posisi 1,2,3 ialah **ID mangkuk 1,2,3**. Oleh itu tuangan pertama menggunakan `oldBowls[1]`, kedua `oldBowls[2]`, ketiga `oldBowls[3]` dan bukannya `oldBowls[order[position]]`. Enam posisi dikekalkan, dengan posisi 4,5,6 bernilai sifar. Kecacatan itu tidak diperbaiki pada tahap ini.

`BootstrapKernel::legacyPoursAt(c,t,i)` menggabungkan 46 titisan terlihat Stage15, susunan normatif Stage17, mangkuk asal legacy dan batu yang betul di bawah penghala `FIXED_POSITION_POURS_LEGACY`. Kaedah ini memulangkan jejak `drop`, `order`, `oldBowls` dan `pours` dalam satu konteks milik panggilan itu.

```text
php -d memory_limit=512M tests/stage18_discovery09_tests.php
php -d memory_limit=512M tests/verify_stage18_discovery09.php
```

Ujian sejarah terus keluar `EXPECTED_RED`, berdasarkan semua 720 permutasi: tepat 1,800 perbandingan salah dan 360 padanan bagi tiga posisi tuangan, ditambah empat kes keluaran sebenar dan pemeriksaan mangkuk asas. Pengesah khas hanya hijau apabila seluruh corak itu terbukti tanpa ralat tambahan. Semua regresi Stage1–17 kekal hijau.

Pemetaan `bowlAlias[position] = order[position]` ialah tugas Stage19 PATCH09; tiada alias ditambah awal atau tuangan kemas kini mangkuk dilaksanakan pada Stage18.


## Stage 19 — PATCH 09: Alias posisi bagi tiga tuangan mangkuk

`PoursAliasPatch09::installOrderAliases` menghasilkan pemetaan `bowlAlias[position]=order[position]` (posisi 1..6, senarai PHP order berindeks 0..5), tanpa menukar identiti atau nilai mangkuk yang sebenar. `bowlByLegacyPosition` membaca `oldBowls[bowlAlias[position]]`; ketiga-tiga bacaan tuangan melalui paparan posisi sementara yang dibina daripada enam identiti sebenar.

`patchedPours` kemudian **memanggil `LegacyFixedPositionPours::legacyPours` secara langsung** pada paparan ini. Oleh itu kaedah legacy yang masih membaca posisi tetap 1,2,3 tidak dibuang dan tidak diubah; pembetulan berlaku sepenuhnya pada alias. `BootstrapKernel::poursAt(c,t,i)` menggunakan penghala `POURS_ALIAS_PATCH_09`, sedangkan `legacyPoursAt` dan `FIXED_POSITION_POURS_LEGACY` kekal membuktikan penemuan Stage18.

```text
php -d memory_limit=512M tests/verify_stage18_discovery09.php
php -d memory_limit=512M tests/stage19_patch09_tests.php
```

Ujian Stage19 mengesahkan semua 720 permutasi dan ketiga-tiga posisi tuangan (2,160 hasil normatif), 4,320 bacaan alias, 1,800 kes legacy yang salah dan 360 padanan legacy yang dijangka. Empat tuangan produksi sebenar diperiksa terhadap oracle PHP dan determinisme instance. Enam input tidak sah ditolak. Semua regresi Stage1–18 kekal diwajibkan.

Stage20 ialah DISCOVERY10 mengenai pencemaran mangkuk akibat penulisan in-place. **Tiada vaultOld/pending atau mutasi mangkuk dilakukan pada Stage19.**


## Stage 20 — DISCOVERY 10: Pencemaran mangkuk akibat perubahan in-place

`LegacyInPlaceBowlStir::stirOneDropWrong` meniru kecacatan sejarah: bagi setiap posisi 1..6, nilai mangkuk dikira dengan rumus normatif daripada ID, jiran sebelum/selepas, tuangan, titisan dan batu; tetapi ia menulis hasilnya terus ke `bowls[id]`. Akibatnya, posisi berikutnya membaca sekurang-kurangnya satu mangkuk yang **telah berubah**. Ini bukan kesalahan rumus SAVE atau alias posisi, tetapi kesalahan sempadan snapshot.

`BootstrapKernel::legacyStirAt(c,t,i)` membuka penghala `IN_PLACE_BOWL_STIR_LEGACY`, memanggil `poursAt` daripada PATCH09, menggunakan satu titisan visible daripada PATCH07, permutasi PATCH08 dan jadual batu PATCH04, kemudian menjalankan kaedah in-place sebenar. Ia mendedahkan `oldBowls`, `pours`, `order` dan `wrongBowls` bagi pengesahan. Tiada pengubahan mangkuk jangka panjang antara titisan diperkenalkan pada Stage20.

```text
php -d memory_limit=512M tests/stage20_discovery10_tests.php
php -d memory_limit=512M tests/verify_stage20_discovery10.php
```

Penguji sejarah memeriksa semua 720 permutasi. Pada stor sintetik tetap, posisi pertama setara dengan oracle satu titisan; posisi 2..6 tersasar dengan tepat **3,600 perbezaan dan 720 padanan**. Empat jejak sebenar juga diperiksa terhadap rumus dari salinan input awal. Pembalut hijau menerima hanya kegagalan sejarah yang tepat. Semua gerbang Stage1–19 kekal hijau.

**Stage21 — PATCH10 belum bermula.** Di tahap itu sahaja `vaultOld` dan `pending` akan diperkenalkan, semua bacaan akan menggunakan salinan lama dan commit akan berlaku selepas keenam-enam posisi. Tiada kod tersebut ditambah pada Stage20.


## Stage 21 — PATCH 10: Simpan mangkuk lama, tulis keenam-enam sekali

`BowlShadowPatch10::stirOneDropViaShadow` menerima mangkuk, batu, titisan, susunan dan tuangan yang sama dengan `LegacyInPlaceBowlStir::stirOneDropWrong`. Panggilan sejarah masih benar-benar dilaksanakan pada salinan kerja tersendiri supaya parut in-place tidak dibuang, tetapi keluarannya tidak diterima sebagai jawapan.

Pembetul mencipta `vaultOld` daripada mangkuk asal, dan `pending` untuk keenam-enam hasil. **Setiap bacaan** daripada mangkuk bagi formula keenam-enam posisi datang hanya dari `vaultOld`; semua penulisan pergi ke `pending`. Selepas enam posisi, `bowls=pending` ialah satu-satunya commit kepada stor pemanggil. Dengan BigInt tidak boleh diubah serta PHP copy-on-write, snapshot kekal bersih selama satu titisan.

`BootstrapKernel::stirAt` melalui dispatcher `BOWL_SHADOW_PATCH_10`. Jalan sejarah `legacyStirAt` dan dispatcher `IN_PLACE_BOWL_STIR_LEGACY` masih mengekalkan pengiraan kotor dengan kemas kini selepas setiap posisi.

```text
php -d memory_limit=512M tests/verify_stage20_discovery10.php
php -d memory_limit=512M tests/stage21_patch10_tests.php
```

Ujian baru menguji 720 susunan × enam posisi = 4,320 komponen, kesetaraan dengan oracle snapshot yang berdikari, 3,600 parut yang dijangka, 720 padanan posisi pertama, empat jejak tarikh sebenar × enam mangkuk, determinisme, pemilikan state serta lima input salah. Stage 20 mesti terus merah secara langsung dan lulus dalam pembalut pengesahan. Semua regresi 1–20 diwajibkan hijau dalam CI.

Stage 22 — DISCOVERY 11 tidak diperkenalkan sehingga SHA Stage 21 disahkan.


## Stage 22 — DISCOVERY 11: Susunan titisan 46 ditindih

`LegacyOverwrittenOrder11::sauceWrong` menggabungkan secara sebenar pembetul terdahulu: 46 titisan visible, kilang enam mangkuk, `PermutationPatch08`, `PoursAliasPatch09` dan `BowlShadowPatch10`. Setiap titisan mengemas kini mangkuk melalui snapshot dan pending yang sah. Selepas titisan 46, laluan sejarah menjalankan dua belas kacauan akhir dengan snapshot dan pending, namun menggunakan semula pemboleh ubah `order` yang menyimpan permutasi titisan ke-46. Setiap post-stir menimpanya, sehingga hasil yang salah memegang susunan post-stir ke-12.

Kesilapan ini **hanya** menjejaskan `orderAtDrop46`, bukan nilai enam mangkuk. Tiada latch atau snapshot susunan khusus diperkenalkan pada Stage 22. Penghala `OVERWRITTEN_ORDER_46_LEGACY` dalam `BootstrapKernel::legacySauceOrder` menyediakan laluan boleh diuji tanpa berkongsi state semantik antara panggilan.

```text
php -d memory_limit=512M tests/stage22_discovery11_tests.php
php -d memory_limit=512M tests/verify_stage22_discovery11.php
```

Ujian langsung sejarah sengaja keluar dengan kod 1: tiga pasangan hari, tiga susunan terpadam yang dijangka, 18 nilai mangkuk akhir yang tepat, dan 36 kacauan pasca-titisan, tanpa ralat lain. Pengesah keluar 0 hanya jika RED ini terasing dan tepat. Semua ujian Stage 1–21 mesti kekal hijau. **Stage 23 — PATCH 11 tidak dimulakan.**


## Stage 23 — PATCH 11: Kunci susunan titisan 46

OrderLatchPatch11 menyimpan permutasi titisan ke-46, memanggil LegacyOverwrittenOrder11::sauceWrong secara sebenar dan menukar hanya medan orderAtDrop46. Enam mangkuk dan 12 kacauan tetap diperoleh daripada pengiraan sejarah. Legacy, oracle, katalog dan fixture tidak diubah.

Ujian: php -d memory_limit=512M tests/verify_stage22_discovery11.php dan php -d memory_limit=512M tests/stage23_patch11_tests.php. Enam pasangan hari dibandingkan dengan oracle PHP tempatan, 36 komponen mangkuk dan 72 kacauan, serta dua input tidak lengkap. Jangan mulakan Stage24 sebelum CI Native untuk HEAD tepat Stage23 hijau.

## Stage 24 — DISCOVERY 12: Jiran susunan bukan jiran nombor

Selepas Stage23 PATCH11, susunan orderAtDrop46 disimpan dengan betul. LegacyNumericSuccessor12 masih menganggap jiran setiap mangkuk ialah (id % 6)+1; ini boleh berbeza daripada ID mangkuk berikutnya dalam permutasi titisan 46. Formula SAVE first dan step kekal, tetapi input mangkuk jiran tersalah pilih. Kod legacy belum dibaiki.

Ujian: php -d memory_limit=512M tests/stage24_discovery12_tests.php (exit 1 dijangka), dan php -d memory_limit=512M tests/verify_stage24_discovery12.php (exit 0 jika merah tepat). Pemeriksaan menyeluruh 720 permutasi × 6 pertanyaan: 3456 jiran berbeza, 864 sepadan; tiga pasangan tarikh sebenar, tiga input tidak sah, dan penghala produksi berasingan. Stage23 disahkan oleh run 39818136362. Jangan tambah PATCH12 atau Stage25 sebelum CI Stage24 disahkan.


## Stage 25 — PATCH 12: Jiran mengikut susunan titisan 46

Selepas Stage24 membuktikan jiran angka salah bagi 3,456 daripada 4,320 pertanyaan enam ID pada semua 720 permutasi, `NextBowlOrderPatch12::askPatched` memanggil `LegacyNumericSuccessor12::askWrong` secara sebenar sebagai parut sejarah dan validasi, kemudian membaca `orderAtDrop46` untuk menentukan jiran yang mengikuti ID pertanyaan (termasuk lilitan). Formula `first`, `step` dan SAVE tidak berubah. Tidak ada import oracle dalam `src`.

`BootstrapKernel::askBowl` membuka konteks baharu dan menghala ke `ORDER_NEIGHBOR_PATCH_12`. `legacyAskBowl` serta `NUMERIC_NEXT_BOWL_LEGACY` tidak diubah. Pengesah Stage24 masih memerlukan kegagalan sejarah yang tepat dan ujian langsung masih mengembalikan exit 1. Semua ujian Stage1–24, fixture, sintaks dan kunci nama mesti lulus.

```text
php -d memory_limit=512M tests/verify_stage24_discovery12.php
php -d memory_limit=512M tests/stage25_patch12_tests.php
```

Stage25 menguji 720 × 6 = 4,320 pertanyaan terhadap oracle tempatan, termasuk 3,456 parut berbeza dan 864 padanan; 72 ujian meterai tambahan; 18 pertanyaan sebenar daripada tiga pasangan hari; kesetaraan panggilan langsung/per-instance; dan empat penolakan input. **Stage26 belum dimulakan.** Stage25 ditanda AWAITING_CI sehingga GitHub Actions Native lulus pada SHA tepat.


## Stage 26 — DISCOVERY 13: Pemilihan modulo tanpa rejection sampling

Stage25 PATCH12 disahkan GREEN pada SHA \`fd2f82a965d5f4c42e513409e1e8c7e656f39647\`, GitHub Actions run \`39915193046\`, kedua-dua pekerjaan SUCCESS. Laluan pertanyaan mangkuk sudah betul.

\`LegacyNoRejection13::chooseWrong\` menerima strim \`first,step\` sah (nilai dalam \`1..M\` dan langkah ±1), serta saiz ruang \`n\` dari 1 hingga \`M=2^127-1\`. Kecacatan yang sengaja dicipta: ia memulangkan \`1+((first-1) mod n)\` segera, tanpa menolak sampel yang melebihi \`L=floor(M/n)*n\`. Oracle PHP tempatan sebaliknya menolak semua \`x>L\`, bergerak dalam strim dengan SAVE dan hanya kemudian mengira modulo. Kes \`n>M\` **bukan** dalam skop penemuan ini.

Untuk \`n=3,10,97,720\`, saksi \`first=L+1, step=-1\` menghasilkan legacy rank 1 dan oracle rank \`n\`; empat penyimpangan RED. Tambahan 13 padanan kawalan di bawah had, tiga jejak strim tarikh sebenar melalui \`BootstrapKernel::legacyChooseRank\` dan empat penolakan input. Penghala \`NO_REJECTION_CHOICE_LEGACY\` memanggil \`BootstrapKernel::askBowl\` (PATCH12) yang sah; kecacatan hanya pada pemilihan rank.

\`\`\`text
php -d memory_limit=512M tests/stage26_discovery13_tests.php  # keluar 1, empat RED sahaja
php -d memory_limit=512M tests/verify_stage26_discovery13.php # keluar 0 jika RED tepat
\`\`\`

Semua regresi Stage1–25, fixture deterministik, lint dan kunci nama mesti kekal hijau. Tiada oracle dalam \`src\`; kod legacy lama tidak diubah; main, nama dan fixture tidak diubah. **Jangan tambah RejectionSamplingPatch13 atau mulakan Stage27 sebelum Native CI Stage26 disahkan.**


## Stage 27 — PATCH 13: Penolakan sampel supaya pemilihan pangkat tidak berat sebelah

Stage26 \`DISCOVERY13\` disahkan \`EXPECTED_RED\` oleh Native GitHub Actions run \`39931454215\` pada SHA \`3a51e44e35f9692884d0a5050884b53d336d7aad\`; \`verify\` dan \`audit_php_bahasa_melayu\` kedua-duanya SUCCESS.

\`RejectionSamplingPatch13::choosePatched\` memanggil \`LegacyNoRejection13::chooseWrong\` secara sebenar sebelum membetulkan ralat. Bagi \`1<=n<=M\`, ia mengira \`cutoff=floor(M/n)*n\`; jika first berada di bawah atau sama cutoff, jawapan legacy sudah benar dan dipulangkan. Jika first melepasi cutoff, tampalan berjalan mengikut step ±1, menggunakan \`SavePatch01\` bagi mengitar nilai antara 1 dan M, sehingga menemui sampel pertama yang tidak melepasi cutoff. Pangkat ialah \`1+((accepted-1) mod n)\`.

\`BootstrapKernel::chooseRank\` membuka konteks panggilan baharu melalui dispatcher \`REJECTION_SAMPLING_PATCH_13\`; \`legacyChooseRank\` kekal mempamerkan kegagalan lama. Ujian Stage27 membandingkan sekurang-kurangnya 1,500 kes sintetik pada pelbagai \`n\`, sempadan, arah aliran, pelbagai penolakan dan kitaran M-ke-1 terhadap oracle PHP bebas. Empat parut Stage26 dipastikan diperbetulkan, 18 pertanyaan produksi daripada tiga pasangan tarikh, serta enam input salah. Semua ujian Stage1–26 dan pengesah RED sejarah mesti kekal lulus.

\`\`\`text
php -d memory_limit=512M tests/verify_stage26_discovery13.php
php -d memory_limit=512M tests/stage27_patch13_tests.php
\`\`\`

**Status: AWAITING_CI.** Stage28 belum dimulakan; tiada oracle dalam kod produksi, tiada perubahan pada \`main\`, katalog atau fixture.


## Stage 28 — DISCOVERY 14: Berat digit pilihan besar diterbalikkan

Stage27 PATCH13 disahkan GREEN pada SHA `21288f66b97a713ed99b5513f0017c20f1ef82cf`, Native GitHub Actions run `39945378948`, kedua-dua pekerjaan SUCCESS. Stage28 meninjau ruang pilihan lebih besar daripada `M = 2^127-1` tetapi tidak melebihi `M*M`: tepat dua digit SAVE diperlukan.

`LegacyBigEndianDigits14::chooseWrong` menganggap sampel pertama sebagai digit **paling penting** (`M`) dan sampel kedua sebagai digit **kurang penting** (1). Oracle PHP tempatan menafsir sampel pertama sebagai digit kurang penting, lalu digit kedua pada pemberat `M`. Kecacatan ini tidak mengubah formula SAVE atau had penerimaan `floor(M*M/n)*n`; hanya pemberat kedudukan digit tersalah. `BootstrapKernel::legacyChooseWideRank` mendedahkan penghala `BIG_ENDIAN_DIGITS_LEGACY`, menggunakan strim asal daripada PATCH12, dengan konteks sendiri.

Empat saksi tetap diuji pada `n=M+1`: sampel pertama 1 dan langkah +1, sampel pertama 2 langkah +1, sampel pertama 2 langkah -1, sampel pertama M langkah +1 yang juga menguji lilitan. Empat keputusan salah ialah `EXPECTED_RED`, di samping matriks 48 kes (empat ruang, enam titik mula dan dua arah), tiga jejak tarikh sebenar dan lima penolakan input.

```text
php -d memory_limit=512M tests/stage28_discovery14_tests.php  # exit 1 tepat
php -d memory_limit=512M tests/verify_stage28_discovery14.php # exit 0 jika RED terkawal
```

Semua Stage1–27, pemeriksaan sintaks, fixture dan kunci nama kanonik wajib kekal hijau. **Jangan tambah `BigEndianDigitsPatch14` atau Stage29 sebelum Native CI Stage28 pada SHA tepat disahkan.** Tiada perubahan `main`, oracle produksi, katalog atau fixture.


## Stage 29 — PATCH 14: Dua digit dengan pemberat benar

Stage28 `DISCOVERY14` disahkan `EXPECTED_RED` di HEAD `7814d28ca9f9f489aa6ce3210a955e48a0c52477` oleh Native GitHub Actions run `39981352293`, kedua-dua pekerjaan SUCCESS.

`BigEndianDigitsPatch14::choosePatched` memanggil `LegacyBigEndianDigits14::chooseWrong` secara sebenar dan mengekalkan kelas sejarah tanpa sebarang perubahan. Pembaikan hanya berat kedudukan digit dalam bilangan 1..M² bagi ruang pilihan `M<n<=M²`: sampel pertama berat **1**, sampel kedua berat **M**. Kedua-dua sampel dijana melalui SAVE yang sama, disusuli rejection sampling pada cutoff `floor(M²/n)*n` dan pengeluaran rank `1+((wide-1) mod n)`.

`BootstrapKernel::chooseWideRank` menggunakan penghala `TWO_DIGIT_WEIGHTS_PATCH_14` dengan konteks sendiri. `legacyChooseWideRank` dan `BIG_ENDIAN_DIGITS_LEGACY` terus mempamerkan susunan salah yang boleh diuji. Domain untuk `n<=M` kekal ditangani oleh `chooseRank` daripada Stage27.

Ujian Stage29 membandingkan empat saksi matematik Stage28, 720 pertanyaan sintetik (90 nilai permulaan × dua arah × empat saiz ruang), 18 pertanyaan produksi dari tiga pasangan tarikh, enam input salah dan pemilikan state terhadap oracle PHP setempat. Pengesah Stage28 mesti terus memerlukan empat parut RED tepat; semua regresi Stage1–28, lint, fixture dan nama kanonik mesti lulus.

```text
php -d memory_limit=512M tests/verify_stage28_discovery14.php
php -d memory_limit=512M tests/stage29_patch14_tests.php
```

**Status:** `AWAITING_CI`. Tidak memulakan Stage30, tidak mengubah `main`, kod legacy, katalog atau fixture.


## Stage 30 — DISCOVERY 15: Digit ketiga tidak dibaca

Stage29 PATCH14 disahkan GREEN pada commit \`aae1c106706bf571adbb94282f8a96e80698df91\`, Native CI run \`39985192899\` (verify dan audit_php_bahasa_melayu SUCCESS).

Stage30 menguji ruang \`M²<n<=M³\`. Formula normatif membaca tiga sampel SAVE dari strim PATCH12, dengan pemberat 1, M dan M². \`LegacyMissingThirdDigit15::chooseWrong\` sengaja mengira dua digit yang pertama sahaja, menolak digit ketiga pada pemberat M². Ia tetap memakai cutoff \`floor(M³/n)*n\` serta domain sampel penuh M³ supaya ketidaksetaraan tertumpu pada digit yang tertinggal. Kod legasi sedia ada tidak diubah; \`BootstrapKernel::legacyChooseTripleRank\` memilih laluan \`MISSING_THIRD_DIGIT_LEGACY\` dalam konteks baharu.

Empat saksi matematik menggunakan n=M³: tiada rejection, jadi beza yang dijangka tepat \`(digit3-1)*M²\`; 40 sampel matriks pada n=M²+1, M²+2, M³-1, M³ memberi 36 perbezaan; tiga jejak hari sebenar dan lima kes input tidak sah. Ujian langsung \`stage30_discovery15_tests.php\` sengaja exit 1, manakala pembalut \`verify_stage30_discovery15.php\` exit 0 **hanya** jika empat RED tepat, 36/40 matriks dan tiada kegagalan lain.

\`\`\`text
php -d memory_limit=512M tests/stage30_discovery15_tests.php  # exit 1 yang disengajakan
php -d memory_limit=512M tests/verify_stage30_discovery15.php # exit 0 jika merah tepat
\`\`\`

Semua regresi Stage1–29, lint PHP, fixture deterministik, dan Canonical Names Lock mesti kekal hijau. **Status: AWAITING_CI. Jangan tambah ThirdDigitPatch15 atau mulakan Stage31 sebelum GitHub Actions Native disahkan pada SHA tepat.** Tiada perubahan main, katalog, fixture atau import oracle ke dalam \`src\`.


## Stage 31 — PATCH 15: Pulihkan digit ketiga pilihan luas

Stage30 DISCOVERY15 menerima EXPECTED_RED melalui Native CI `39999379403` pada SHA `b1723bfc35cd6a48a9ea70cf32b5852eef8aeb0d` (verify dan audit kedua-duanya SUCCESS). Kecacatan bersejarah `LegacyMissingThirdDigit15` dibiarkan utuh.

`ThirdDigitPatch15::choosePatched` memanggil `LegacyMissingThirdDigit15::chooseWrong` secara sebenar untuk mengekalkan laluan sejarah dan validasi, kemudian membaca tiga sampel SAVE pada pemberat `1`, `M`, dan `M²`. Nilai ruang ialah `M²<n<=M³`, cutoff ialah `floor(M³/n)*n`; sampel melebihi cutoff ditolak dengan langkah ±1 dalam domain `1..M³`. Penghala produksi baharu `THIRD_DIGIT_PATCH_15` dan API `BootstrapKernel::chooseTripleRank` mempunyai konteks per-panggilan tersendiri; `legacyChooseTripleRank` kekal salah.

Ujian `stage31_patch15_tests.php` membandingkan 400 input sintetik dengan oracle PHP tempatan yang bebas, termasuk keempat-empat saksi Stage30, 18 pertanyaan sebenar melalui dua instance kernel, enam input salah, serta semakan tanpa oracle di `src`. Pembalut `verify_stage30_discovery15.php` terus mesti menerima tepat empat kegagalan RED lama (exit 0), sementara ujian terus Stage30 kekal exit 1.

```text
php -d memory_limit=512M tests/verify_stage30_discovery15.php
php -d memory_limit=512M tests/stage31_patch15_tests.php
```

Semua regresi Stage1–30, lint PHP, fixture dan kunci nama kanonik mesti lulus Native GitHub Actions pada SHA tepat. **Status: AWAITING_CI. Stage32 tidak boleh dimulakan sebelum SUCCESS kedua-dua pekerjaan pada HEAD baharu.** Tiada perubahan pada `main`.


## Stage 32 — DISCOVERY 16: Digit keempat hilang daripada pilihan luas

Stage31 PATCH15 disahkan GREEN pada SHA `405c4f94eb7a774c9a1fd757b2045624920bffe9`, Native GitHub Actions run `40125767529`, kedua-dua tugas SUCCESS.

Bagi ruang `M³<n<=M⁴`, oracle PHP normatif membaca empat sampel daripada strim `askBowl` PATCH12, dengan berat `1`, `M`, `M²`, `M³`. `LegacyMissingFourthDigit16` dengan sengaja membaca hanya tiga sampel pertama, tidak membaca digit keempat pada berat `M³`. Cutoff dikira dalam ruang `M⁴` yang sebenar; kecacatan terkawal hanya pada ketiadaan digit. `BootstrapKernel::legacyChooseQuadRank` melalui penghala `MISSING_FOURTH_DIGIT_LEGACY` dengan konteks per panggilan; kod legacy Stage1–30 dan PATCH15 tidak diubah.

Empat saksi tetap pada `n=M⁴`, tanpa rejection, menunjukkan beza tepat `(digit4-1)*M³`; 56 kes sempadan daripada empat ruang, tujuh titik mula, dua arah menghasilkan tepat 52 mismatch, empat kebetulan, tanpa penolakan astronomi. Tiga pertanyaan sebenar melalui dispatcher, lima input tidak sah. Ujian terus `stage32_discovery16_tests.php` keluar dengan kod 1 **yang disengajakan**; pembalut `verify_stage32_discovery16.php` keluar kod 0 hanya jika tepat empat RED dan tiada kegagalan lain.

```text
php -d memory_limit=512M tests/stage32_discovery16_tests.php # keluar 1, empat RED disengajakan
php -d memory_limit=512M tests/verify_stage32_discovery16.php # keluar 0 apabila RED tepat
```

Semua ujian Stage1–31, PHP lint, fixture dan kunci nama kanonik wajib lulus Native GitHub Actions pada SHA tepat. **Status: AWAITING_CI. Jangan tambah FourthDigitPatch16, jangan mulakan Stage33, jangan ubah main.**


## Stage 33 — PATCH 16: Pulihkan digit keempat pada berat M³

Stage32 DISCOVERY16 telah disahkan EXPECTED_RED oleh Native GitHub Actions `40169711719` pada SHA `748966fd7d2030c1199b30c1127508ee40ab10df`: tiga pekerjaan SUCCESS, termasuk kedua-dua kumpulan regresi PHP.

`FourthDigitPatch16::choosePatched` menjalankan `LegacyMissingFourthDigit16::chooseWrong` secara sebenar untuk semakan domain dan pemeliharaan parut; kelas lama itu **tidak diubah**. Jawapan normatif membaca empat sampel SAVE daripada strim PATCH12 dengan pemberat `1`, `M`, `M²` dan `M³`. Had penerimaan `floor(M⁴/n)*n`, pergerakan rejection ±1 dan lilitan pada domain `M⁴` digunakan untuk ruang `M³<n<=M⁴`. Laluan produksi `BootstrapKernel::chooseQuadRank` memakai dispatcher `FOUR_DIGIT_PATCH_16` dalam konteks tersendiri; `legacyChooseQuadRank` kekal membuang digit keempat.

Ujian Stage33 merangkumi 400 perbandingan matriks dengan oracle PHP bebas (empat ruang, 50 nilai awal, dua arah), 392 mismatch sejarah dan lapan persamaan sejarah, empat saksi Stage32 dengan beza tepat `(digit4−1)*M³`, 18 panggilan produksi merentas dua kernel, enam penolakan input dan imbasan tanpa oracle dalam kod produksi. Titik mula kritikal telah diselaraskan agar penolakan tidak mengambil tempoh astronomi; semakan aritmetik persendirian mendapati paling banyak empat langkah rejection pada 400 kes ini. Saksi dan verifier Stage32 terus menuntut empat kegagalan `EXPECTED_RED` yang sama.

Semua ujian Stage1–32, PHP lint, fixture dan canonical names lock perlu lulus. Suite dipecahkan kepada tiga pekerjaan PHP bagi mengelakkan timeout: regresi awal Stage1–23, regresi Stage24–32, dan Stage33 sendiri. Pekerjaan `verify` juga wajib SUCCESS, semuanya terhadap SHA HEAD yang tepat.

```text
php -d memory_limit=512M tests/verify_stage32_discovery16.php
php -d memory_limit=512M tests/stage33_patch16_tests.php
```

**Status:** `AWAITING_CI`. Jangan mulakan Stage34 sehingga empat pekerjaan Native CI berjaya. Jangan ubah `main`, katalog atau fixture.


## Stage 34 — DISCOVERY 17: Digit kelima dibuang daripada pilihan lima digit

Stage33 PATCH16 telah disahkan GREEN oleh Native GitHub Actions `40192008267` pada SHA `6ed4efbe2e60a3d910f9e6277a4dbe7494333fa9`: empat pekerjaan SUCCESS. Fail legacy `LegacyMissingFourthDigit16.php` telah dipulihkan dalam commit asas itu dan mesti kekal tidak diubah.

Untuk `M⁴<n<=M⁵`, pemilih normatif membaca lima sampel SAVE daripada `askBowl` PATCH12 dengan pemberat `1`, `M`, `M²`, `M³` dan `M⁴`. `LegacyMissingFifthDigit17::chooseWrong` sengaja membaca empat digit pertama sahaja, tidak membaca sampel kelima pada pemberat M⁴. Had rejection `floor(M⁵/n)*n` dan domain M⁵ yang sebenar **tetap digunakan**, supaya kesalahan tunggal ialah digit terakhir yang hilang. Laluan `BootstrapKernel::legacyChooseQuintRank` memanggil kod Legacy sebenar melalui dispatcher `MISSING_FIFTH_DIGIT_LEGACY` dan konteks per panggilan.

Empat saksi tetap pada `n=M⁵` menunjukkan perbezaan tepat `(digit5−1)*M⁴`; 56 ujian sempadan (empat ruang, tujuh nilai first, dua arah) menunjukkan tepat 52 mismatch sejarah dan empat padanan. Semakan aritmetik bebas sebelum implementasi mendapati **sifar langkah rejection** bagi matriks ini, jadi ia tidak mewujudkan gelung yang tidak terhad. Tambahan: tiga pertanyaan Native sebenar melalui PATCH12, lima input tidak sah, larangan import oracle ke `src` dan larangan munculnya `FifthDigitPatch17` sebelum Stage35.

```text
php -d memory_limit=512M tests/stage34_discovery17_tests.php   # keluar 1: RED sengaja
php -d memory_limit=512M tests/verify_stage34_discovery17.php  # keluar 0: empat RED terkawal
```

Kerja `audit_php_bahasa_melayu_stage34` mengasingkan ujian baharu. Semua empat pekerjaan terdahulu (`verify`, regresi awal, regresi 24–32, Stage33), beserta pekerjaan Stage34 yang kelima, mesti lulus Native GitHub Actions pada SHA tepat. **Status: AWAITING_CI**; jangan mulakan Stage35 atau mengubah `main`, fixture, katalog atau kod sejarah.


## Stage 35 — PATCH 17: Pulihkan digit kelima pada pemberat M⁴

Stage34 DISCOVERY17 telah disahkan `EXPECTED_RED` oleh Native GitHub Actions run `40234787662`, HEAD `c9ff4ec6ecdf73b5a11fcc38060fbd84f32ab9f2`, lima pekerjaan SUCCESS. Saksi `menurun` kini bermula pada 6, arah -1, sehingga digit kelima bernilai 2 dan benar-benar mendedahkan kecacatan.

`FifthDigitPatch17::choosePatched` memanggil kelas Legacy `LegacyMissingFifthDigit17::chooseWrong` secara sebenar, tanpa mengubah kodnya, bagi mengekalkan semakan input dan parut sejarah. Formula pengganti membaca lima digit SAVE daripada strim `askBowl` PATCH12, dengan pemberat `1, M, M², M³, M⁴`. Domain `M⁴<n<=M⁵`; cutoff `floor(M⁵/n)*n`, rejection ±1 dan lilitan dalam `1..M⁵`. Penghala produksi `BootstrapKernel::chooseQuintRank` melalui dispatcher `FIFTH_DIGIT_PATCH_17` dan konteks milik panggilan; `legacyChooseQuintRank` serta `MISSING_FIFTH_DIGIT_LEGACY` terus menunjukkan cacat sejarah.

Ujian `tests/stage35_patch17_tests.php` membandingkan 400 kes sintetik (empat saiz, 50 nilai first, dua arah) terhadap oracle PHP tempatan yang bebas. Terdapat **392 mismatch Legacy dan lapan padanan**, dengan sifar langkah rejection pada matriks ini menurut semakan integer tepat bebas; dua titik mula berbahaya diganti dengan jiran selamat, jumlah dan liputan sempadan dikekalkan. Empat saksi Stage34 menguji beza tepat `(digit5-1)*M⁴`; 18 pertanyaan Native (tiga pasangan hari × enam mangkuk), enam input invalid, tiada oracle dalam produksi, dan kelas Legacy asal kekal.

```text
php -d memory_limit=512M tests/verify_stage34_discovery17.php
php -d memory_limit=512M tests/stage35_patch17_tests.php
```

Semua Stage1–34, fixture, lint PHP dan kunci nama kanonik mesti lulus Native CI. Stage35 mempunyai pekerjaan khusus `audit_php_bahasa_melayu_stage35`; semua **enam pekerjaan** pada SHA HEAD yang sama wajib SUCCESS. **Status: GREEN** selepas Native GitHub Actions run `40404749682` pada HEAD `0d16b132015b04406792964e7bab68ab179b38c9`: keenam-enam pekerjaan (`verify`, audit asas, Stage24–32, Stage33, Stage34 EXPECTED_RED wrapper, Stage35 PATCH17) tamat `SUCCESS`. Stage34 kekal dengan kegagalan sejarah yang disengajakan; jangan mulakan Stage36 tanpa kontrak dan pelan yang disahkan. Jangan ubah `main`, fixture atau katalog.


## Pengesahan regresi Stage35 terkini (2026-10-27)

Perlindungan dua penolakan berturut-turut (`REJECTION_TWO_STEP_CUTOFF`, `REJECTION_TWO_STEP`) ditambah dalam [`stage35_patch17_tests.php`](tests/stage35_patch17_tests.php) pada commit `751eaf47d1099a4fc465cad0d5142d72661c02da`. Native GitHub Actions [`40554857029`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40554857029) pada commit `e958da7c01fc2e1bad9e13cfacf720cf699a8b32` selesai `success` dengan keenam-enam pekerjaan berjaya, termasuk audit Stage35. Bukti terperinci berada dalam [`STAGE_35_PATCH_17_HANDOFF.md`](artifacts/STAGE_35_PATCH_17_HANDOFF.md). Ini tidak membenarkan Stage36; kontrak/pelan yang disahkan dan kebenaran pengguna yang jelas masih diperlukan.
