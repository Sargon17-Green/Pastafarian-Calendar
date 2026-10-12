# Sejarah Pembangunan Spaghetti

## Stage 1 — Bootstrap

### Apa yang dibina

Garis pelaksanaan baru diwujudkan daripada kosong untuk PHP dan Bahasa Melayu. Sokongan integer ketepatan sewenang-wenangnya ditulis dalam PHP tulen. Katalog bahasa sumber dibina dan dibekukan. Oracle normatif khusus ujian, fixture tempatan, harness ujian serta rangka production neutral turut diwujudkan.

### Lapisan raksasa yang ditambah

Hanya lapisan neutral yang dibenarkan pada bootstrap ditambah: `BootstrapContext`, `BootstrapDispatcher`, `BootstrapValidator`, `BootstrapErrorBoundary` dan `MetricsShell`.

### Mengapa lapisan ini tidak mengubah semantik

Lapisan bootstrap tidak mempunyai formula kalendar dan tidak mempunyai laluan legacy. Ia hanya mengurus lifecycle probe, validasi saiz katalog, sempadan ralat dan metrik pemerhatian. Tiada nilai metrik atau log dibaca semula sebagai input semantik.

### Sejarah tampalan

Belum ada kecacatan legacy yang diperkenalkan dan belum ada tampalan 01–26. Bahagian sejarah bagi setiap tampalan akan ditulis hanya apabila tahap `DISCOVERY` atau `PATCH` yang sepadan benar-benar dilaksanakan.

## Audit asas sebelum Stage 2 — pembahagian tepat

Pemeriksaan semantik menemui dua kekurangan Stage 1 yang tidak diuji oleh 15 ujian asal: `divMod` dan `mod` bercanggah untuk pembahagi negatif; `modSmall` berpotensi melakukan pendaraban yang melimpahi integer mesin apabila pembahagi terlalu besar. Pembetulan mengekalkan `a = b*q + r` dengan hasil bahagi lantai dan baki bertanda seperti pembahagi, serta melencongkan pembahagi besar kepada pembahagian `BigInt` penuh. Regresi terasing dan CI untuk cabang ini ditambah. Status Stage 1 tidak dinaikkan kepada Stage 2 kerana pelaksanaan kecacatan legacy belum bermula.

### Bukti audit CI pada 11 Oktober 2026

Aliran kerja `Canonical Names Lock` yang sedia aktif kini mengandungi kerja `audit_php_bahasa_melayu` yang dijalankan hanya pada `refs/heads/PHP+Bahasa-Melayu`. Run `38151727484` berjaya untuk kedua-dua kerja `verify` dan `audit_php_bahasa_melayu`: sintaks PHP, semua 15 ujian Stage 1, 1,014 kes pembahagian bersama lapan kes sempadan, serta penjanaan semula fixture tanpa perubahan. Fail aliran kerja baharu yang tidak dipicu telah dibuang untuk mengelakkan dua konfigurasi CI yang bersaing.

## Stage 2 — DISCOVERY 01: SAVE berbanding baki modulo

### Apa yang disangka

Pengiraan lama menganggap baki modulo biasa bagi pembahagi `M = 2^127 - 1` sudah memadai untuk mentakrifkan `SAVE`. Pelaksanaan `oldRemainder` mengekalkan baki sifar bagi gandaan M.

### Apa yang ditemui

Ujian perbandingan setempat dengan `NormativeMath::save` menunjukkan penyimpangan yang tepat bagi `M`, `2M` dan `3M`: hasil pengeluaran ialah `0`, tetapi hasil normatif ialah `M`. Pada `M+1`, kedua-duanya mengembalikan `1`. Tiga kegagalan baharu itu disengajakan dan tidak boleh dibaiki sebelum Stage 3.

### Lapisan raksasa yang ditambah

`BootstrapKernel::save` kini memasuki `BootstrapContext`, sempadan ralat dan dispatcher `SAVE_LEGACY`, lalu menghubungi `LegacyRemainder::calculateWithoutPatch` dan `oldRemainder`. Pemilik keadaan semantik ialah konteks setiap panggilan; objek legacy memegang modulus tetap sahaja. Metrik dan status tidak dibaca bagi keputusan matematik. Tiada cache rentas panggilan, tiada oracle dalam pengeluaran dan tiada penapisan pembetulan.

### Bukti ujian yang dirancang

`tests/stage02_discovery01_tests.php` mesti gagal dengan kod `1` dan tepat tiga perbezaan berlabel. `tests/verify_stage02_discovery01.php` mesti lulus hanya untuk kegagalan tepat itu, sambil mengesahkan bahawa `savePatch` belum wujud dalam `src/`. Semua ujian Stage 1 dan regresi aritmetik kekal diperlukan. Hasil sebenar CI dicatat selepas ia dijalankan.

## Stage 3 — PATCH 01: Lapisan SAVE di atas baki lama

### Apa yang dipintas

Kelas `LegacyRemainder`, termasuk `oldRemainder` dan `calculateWithoutPatch`, **tidak diubah**. Laluan `SAVE_LEGACY` juga masih berdaftar dalam dispatcher. Kesilapan pulangan sifar untuk gandaan `M` kekal sebagai parut sejarah yang boleh diuji secara terus.

### Mengapa tampalan ini setara

`SavePatch01::savePatch` terlebih dahulu memanggil `oldRemainder(x)`. Jika baki sifar, ia memulangkan `M`; selain itu ia memulangkan baki asal tanpa perubahan. Oleh sebab baki untuk modulus positif sentiasa dalam julat `[0,M-1]`, fungsi ini sama dengan `1 + ((x-1) mod M)` untuk **semua integer** termasuk sifar, nombor negatif dan bilangan yang melebihi 256 bit.

### Lapisan raksasa yang ditambah

Dispatcher menambah fasa `SAVE_PATCH_01` yang membina pengurus lama, adapter tampalan dan konteks permintaan tersendiri sebelum memulangkan keputusan. Konteks mengekalkan keadaan semantik milik panggilan itu sahaja. Status dan metrik kekal pemerhatian; tiada keputusan matematik membacanya. Tiada cache berkongsi atau pembetulan melalui oracle.

### Ujian dan sejarah kegagalan

Ujian penemuan Stage 2 kekal merah **pada laluan lama sahaja**; pemeriksa sejarah menganggap merah itu sebagai bukti yang dijangka. Ujian baharu `stage03_patch01_tests.php` menyemak perbandingan dengan oracle tempatan, semua jiran bagi gandaan negatif/positif `M`, sempadan integer mesin, angka besar, idempoten, periodik, determinisme, serta ketiadaan laluan oracle dalam pengeluaran. Laluan produksi kini dikehendaki hijau. Keputusan sebenar daripada pemeriksaan CI dicatat setelah tersedia.


## Stage 4 — DISCOVERY 02: Nombor hari kehilangan keanehan

### Apa yang disangka

Pereka dahulu menganggap kedudukan hari diukur oleh jarak mutlak daripada Hari Asas, didarab dua. Oleh itu kaedah `oldDayTag(day)` disimpan sebagai `2 * abs(day - FOUNDATION)`. Pengiraan dibuat dengan BigInt agar tiada limpahan int mesin menutupi kesilapan sejarah yang sebenar.

### Apa yang ditemui

Bagi 64 hari sebelum Asas, hasil legacy dan rujukan normatif bersetuju. Tepat pada Hari Asas, legacy memberi `0` sedangkan rujukan memberi `1`. Bagi 64 hari selepasnya, legacy memberikan nombor genap sedangkan rujukan memberikan nombor ganjil yang lebih satu. Maka ujian penemuan menghendaki 65 perbezaan dan 64 padanan, serta dua ujian ketepatan integer di had `PHP_INT_MIN` dan `PHP_INT_MAX`.

### Lapisan yang ditambah dan sempadan semantik

`LegacyDayTag` menerima hari dan mengira jarak tanpa sebarang keadaan global. `BootstrapKernel::dayCount` mencipta `BootstrapContext` tersendiri, melalui sempadan ralat dan fasa dispatcher `DAY_TAG_LEGACY`. Nilai diletakkan hanya dalam state konteks milik panggilan; metrik tidak pernah menjadi input keputusan. Laluan `SAVE_PATCH_01` dari Stage 3 dan parut `oldRemainder` tidak berubah.

### Belum ditampal

Pembetulan `dayTagWithFoundationScar` atau tambahan satu pada pihak hari lewat sama sekali tidak dilaksanakan dalam Stage 4. Kegagalan yang dikehendaki oleh `stage04_discovery02_tests.php` mesti mempunyai kod keluar `1` secara sengaja; pengesah `verify_stage04_discovery02.php` menerima hanya kegagalan tepat tersebut, tanpa sebarang kegagalan Stage 1–3. Keputusan CI direkodkan selepas disahkan.


## Stage 5 — PATCH 02: Parut Hari Asas di atas kiraan hari lama

### Apa yang dipintas

Kod `LegacyDayTag::oldDayTag` dan `calculateWithoutPatch` tidak dipinda dan masih memulangkan sifar pada Hari Asas serta nombor genap selepasnya. Dispatcher `DAY_TAG_LEGACY` kekal didaftarkan bagi mengekalkan parut sejarah. `FoundationScarPatch02` memanggil kaedah lama dahulu, kemudian menambah satu tepat apabila `day >= FOUNDATION`, dan mengekalkan semakan sejarah yang memaksa `1` sekiranya hasil pada Hari Asas masih tidak sama dengan `1`.

### Mengapa tampalan ini tepat

Sebelum Hari Asas, nilai legacy `2*abs(day-FOUNDATION)` sudah sama dengan oracle. Pada dan selepas Hari Asas, menambah satu menghasilkan nombor ganjil `2*abs(day-FOUNDATION)+1`. Syarat parut tambahan selepas langkah itu ialah pengesahan sejarah yang tidak mengubah hasil. Semua pengiraan beza hari menggunakan BigInt dalam kelas lama, jadi sempadan `PHP_INT_MIN/MAX` tidak melimpahi integer mesin.

### Lapisan raksasa dan pemilik keadaan

Laluan awam `BootstrapKernel::dayCount` menubuhkan konteks baharu dan memilih dispatcher `DAY_TAG_PATCH_02`; dispatcher membina komponen legacy serta adapter dan menyimpan satu hasil ke dalam keadaan semantik konteks setempat. Metrik pemerhatian dan status tidak menjadi input matematik. Fasa `SAVE_PATCH_01` dan semua peraturan Stage 1–3 masih wujud.

### Bukti regresi

`stage04_discovery02_tests.php` tetap keluar dengan kod `1` untuk 65 perbezaan bersejarah pada legacy sahaja; pembalut Stage 4 mengesahkan corak tersebut dan kewujudan tampalan dalam kelas yang berasingan. `stage05_patch02_tests.php` membandingkan nilai pengeluaran dengan oracle PHP bagi ribuan hari sekitar Asas, menguji integer ekstrem melalui formula BigInt tepat, perubahan ganjil/genap, determinisme, panggilan berulang, SAVE, probe, ketiadaan oracle di pengeluaran dan ketiadaan kecacatan Stage 6. Hasil CI sebenar perlu disahkan sebelum peringkat ini dinyatakan lulus.

### Bukti CI sebenar selepas pelaksanaan Stage 5

Pada 11 Oktober 2026, aliran kerja `Canonical Names Lock` run `38155098345` lulus kedua-dua kerja: `verify` dan `audit_php_bahasa_melayu`. Log menunjukkan 15 daripada 15 ujian asas lulus, 1,014 kes pembahagian dan lapan kes sempadan lulus, fixture dijana semula tanpa perubahan, kegagalan sejarah SAVE kekal tiga kes yang dijangka, 94 ujian Stage 3 lulus, serta ujian penemuan hari lama menunjukkan 65 perbezaan dan 64 padanan yang dijangka. Ujian Stage 5 berjaya dalam 4,618 kes, termasuk 2,305 kes sebelum Hari Asas, 2,311 kes pada atau selepasnya, satu pemeriksaan Hari Asas dan dua kes had integer. Laporan ini dicatat pada akhir Stage 5, bukan permulaan tahap baharu.

## Stage 6 — DISCOVERY 03: Jarak langkah bukan bilangan hari

### Andaian yang gagal

Pereka pengiraan lama menyangka bilangan jarak antara hari pengiraan dan hari sasaran ialah jarak langkah mutlak sahaja: `oldDistance(c,t) = abs(t-c)`. Ini mengabaikan aturan normatif bahawa hari di kedua-dua hujung diambil kira: `distance(c,t) = abs(t-c)+1`. Hari yang sama mesti mempunyai jarak `1`, bukannya `0`.

### Bagaimana penyelewengan dibuktikan

`stage06_discovery03_tests.php` menggunakan `NormativeMath::workCounts` sebagai oracle tempatan untuk 136 pasangan selamat, termasuk matriks hari sekitar Hari Asas, hari sama, jarak negatif/positif pada paksi, Hari Loh, dan pasangan yang diterbalikkan. Untuk lapan pasangan di sempadan `PHP_INT_MIN/MAX`, pengiraan normatif `abs(t-c)+1` dilakukan dengan BigInt tepat bagi mengelakkan limpahan yang boleh berlaku dalam oracle Stage 1 apabila ia menolak int asli. Semua 144 pasangan mesti mendedahkan penyelewengan tepat satu. Ujian terus keluar dengan kod `1` secara sengaja, dan pemeriksa `verify_stage06_discovery03.php` menerima hanya 144 kegagalan itu dan tiada ralat sampingan.

### Lapisan raksasa yang ditambah

`LegacyDistance` memegang pengiraan yang salah sebagai kaedah tersendiri. Panggilan `BootstrapKernel::distance` mewujudkan `BootstrapContext` khusus, melalui dispatcher `DISTANCE_LEGACY` dan sempadan ralat, mengembalikan keputusan lama tanpa mengubahnya. Pemilik keadaan semantik ialah konteks panggilan; status dan metrik kekal pemerhatian sahaja. Kiraan hari dari PATCH 02 dan pembetulan SAVE dari PATCH 01 tidak berubah.

### Batasan penemuan

Tiada `distanceCountPatch03`, tiada penghala `DISTANCE_PATCH_03`, dan tiada tambahan satu dalam pengeluaran pada Stage 6. Hanya Stage 7 boleh melaksanakan PATCH 03 sambil mengekalkan `LegacyDistance::oldDistance` seperti dahulu. Keputusan CI akan direkodkan selepas ia diuji.

### Bukti CI sebenar — 11 Oktober 2026

Aliran kerja `Canonical Names Lock`, run `38156102411`, tamat dengan **success** bagi kedua-dua kerja `verify` dan `audit_php_bahasa_melayu`. Log menunjukkan 15/15 ujian Stage 1 lulus, 1,014 ujian pembahagian bersama lapan ujian tambahan lulus, fixture dijana semula tanpa perubahan, penemuan 01 kekal tiga penyimpangan dijangka, 94 kes PATCH 01 lulus, penemuan 02 kekal 65 penyimpangan dan 64 padanan, serta 4,618 kes PATCH 02 lulus. Penemuan 03 menunjukkan `KEPUTUSAN MERAH_DIJANGKA perbezaan=144 jumlah=144 tepi=8 lain=0` dan pembalut `LULUS kontrak merah khusus 03; laluan legacy kekal tidak ditampal`. Pada pasangan `PHP_INT_MIN` dan `PHP_INT_MAX`, bilangan normatif ialah `18446744073709551616` dan nilai legacy ialah `18446744073709551615`. Ini bukan pelaksanaan PATCH 03; status akhir Stage 6 kekal `EXPECTED_RED` dengan pengesah CI hijau.


## Stage 7 — PATCH 03: Jarak inklusif di atas kesilapan warisan

### Kesilapan sejarah yang terus dikekalkan

`LegacyDistance::oldDistance(c,t)` **tidak diubah** dan terus memulangkan `abs(t-c)`. Kaedah `calculateWithoutPatch` serta pendaftaran dispatcher `DISTANCE_LEGACY` juga kekal. Penemuan Stage 6 boleh menunjukkan semula 144 penyimpangan yang sama dengan memanggil kaedah legacy secara langsung, bukannya memalsukan hasil pengeluaran.

### Pembetulan normatif dan mengapa ia sah

`DistanceCountPatch03::distanceCountPatch03(c,t)` memanggil `oldDistance(c,t)` terlebih dahulu, kemudian menambah `BigInt::one()`. Untuk setiap pasangan hari bertanda dalam julat integer PHP, ini sama dengan bilangan normatif `abs(t-c)+1`, termasuk dua hujung ekstrem, hari sama, gerak ke hadapan dan gerak ke belakang. Tiada operasi pengiraan jarak menggunakan penolakan int mesin; bezanya dibina melalui BigInt dalam kaedah sejarah yang tidak diubah.

### Pertambahan lapisan raksasa yang neutral

`BootstrapKernel::distance` mengarahkan permintaan kepada dispatcher `DISTANCE_PATCH_03` yang membina adapter tampalan di atas objek `LegacyDistance`. Hasil dan status disimpan dalam `BootstrapContext` khusus bagi panggilan. Statistik hanya diubah selepas pengiraan dan tidak pernah dibaca sebagai input matematik. Tiada cache merentas panggilan atau oracle dalam pengeluaran.

### Bukti regresi baharu

Ujian `stage07_patch03_tests.php` diwajibkan hijau dan merangkumi 16,668 pasangan teras: matriks 127×127 sekitar Hari Asas, 15 pasangan khas, 512 pasangan terserak, dan 12 kes sempadan integer mesin. Setiap pasangan menegaskan ketepatan, pembalut langsung, parut sejarah, simetri, ulangan, serta kebebasan instance. Tambahan 1,285 semakan anjakan dan 200 semakan additiviti jarak dilakukan. Oracle PHP Stage 1 digunakan hanya bagi julat selamat; nilai ekstrem dibandingkan dengan formula BigInt bebas daripada overflow.

### Had peringkat dan penerimaan

Pengujian sejarah Stage 6 masih mesti keluar dengan kod 1 untuk tepat 144 penyimpangan lama; pemeriksa sejarah mesti keluar dengan kod 0. Pengeluaran Stage 7 kini mesti hijau sepenuhnya. Penemuan keempat atau `mutateStonesWrong` tidak dilaksanakan sebelum Stage 8. Keputusan CI sebenar dicatat setelah diperiksa.

### Bukti CI sebenar pada 11 Oktober 2026

Run `38157374399` bagi commit `3b2984b29f2881a960e2df4b643f2726f7521c25` selesai dengan **success** dalam kedua-dua kerja `verify` dan `audit_php_bahasa_melayu`. Ujian sintaks dan kunci nama kanonik lulus; 15/15 ujian Stage 1 lulus; regresi pembahagian `kes=1014 tambahan=8` lulus dan fixture dijana tanpa diff. Pengesah sejarah masih melaporkan tiga penyimpangan SAVE, 65 penyimpangan bagi nombor hari, dan 144 penyimpangan legacy jarak yang dijangka; pengesah bagi setiap peringkat menerima corak itu. Ujian Stage 3 mencatat 94 kes lulus, Stage 5 mencatat 4,618 kes lulus, dan Stage 7 menghasilkan `LULUS Stage 7 PATCH 03 kes=16668 oracle=16656 tepi=12 simetri=16668 anjakan=1285`. Oleh itu tahap ini GREEN, tetapi kesilapan `oldDistance` masih wujud sebagai bukti sejarah.


## Stage 8 — DISCOVERY 04: Mutasi berturutan mencemarkan batu

### Andaian sejarah

Pembina lama menyangka lima batu boleh diubah secara berurutan dalam satu keadaan yang sama. Semasa mengira `b`, ia membaca `w` baharu; bagi `s`, ia membaca `b` baharu; bagi `m`, ia membaca `s` baharu; bagi `r`, ia membaca `w` dan `m` baharu. Formula normatif sebaliknya memerlukan setiap komponen membaca rekod lama bagi langkah yang sama.

### Bukti perbezaan

Pada langkah 2, nilai legacy ialah `(w=378,b=1434,s=3780,m=9932,r=25047)`, manakala oracle PHP garis ini ialah `(w=378,b=1073,s=2375,m=6195,r=10493)`. Pengesahan membandingkan 46 rekod menggunakan oracle PHP tempatan; rekod pertama sepadan dan baki 45 dijangka menyimpang. Perbezaan ini bukan kegagalan tidak terkawal: pembalut memeriksa output merah dan keluar dengan kod 0 hanya jika corak bukti tepat.

### Lapisan tambahan

`LegacyStoneMutation` menerima pembetul SAVE yang sudah wujud dari Stage 3. Dispatcher `STONE_MUTATION_LEGACY` membuat instance dan konteks baharu bagi setiap panggilan. Jadual asal diwariskan dengan semantik copy-on-write PHP; tiada keadaan boleh ubah yang dikongsi antara panggilan. Metrik direkodkan selepas pembinaan dan tidak menjadi input keputusan. Oracle hanya wujud dalam direktori `tests/oracle`.

### Had tahap

`mutateStonesWrong` belum dibetulkan. Tiada `stonePatch`, snapshot `old` atau penindihan semua lima hasil sehingga Stage 9. Semua regresi terdahulu kekal wajib lulus.

### Titik asas

Penemuan ini dibina selepas pembetulan kanonik Stage 7 pada commit `5743a0ffeb7ef87016f8ff2a6166460abfcaddea`, yang telah lulus GitHub Actions sebelum perubahan Stage 8.
