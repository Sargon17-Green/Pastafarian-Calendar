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


## Stage 9 — PATCH 04: Pembalut snapshot bagi lima batu

### Sebab pembetulan diperlukan

Pengiraan `LegacyStoneMutation::mutateStonesWrong` membaca hasil terkini komponen yang sudah berubah. Ia telah terbukti berbeza daripada `NormativeSauce::buildStones` pada 45 daripada 46 baris dalam Stage 8. Punca sejarah tidak dipadam, kerana kerosakan semantik ialah bukti wajib.

### Cara pembetulan yang ditetapkan

`StonePatch04::stonePatch(i,state)` membina `old` (snapshot array dan objek BigInt tidak berubah), kemudian `garbage` daripada salinan bebas dan **benar-benar** memanggil `mutateStonesWrong(i,garbage)`. Semua lima medan `garbage` selepas itu ditulis semula dengan `savePatch` dan formula asli yang hanya membaca `old`. Hasil pengeluaran `buildStones` ialah 46 baris, setiap baris memiliki rekod tersendiri.

### Lapisan tambahan untuk pertumbuhan monster

Dispatcher lama `STONE_MUTATION_LEGACY` kekal untuk sejarah. Dispatcher produksi baharu `STONE_PATCH_04` membina penampal berserta objek legacy dan SAVE; `BootstrapKernel::stones` kini melalui laluan baharu, dalam konteks panggilan per-instance. Metrik dan status hanya pemerhatian, tidak menjadi input semantik, dan tiada oracle dalam laluan produksi.

### Bukti regresi dan pengasingan

Ujian langsung Stage 8 masih keluar kod 1 untuk 45 baris legacy yang salah. Pemeriksa Stage 8 mengesahkan merah yang tepat dan menerima pembalut Stage 9. Ujian hijau Stage 9 membandingkan semua 230 komponen jadual dengan oracle tempatan, melakukan 315 ujian terus bagi snapshot termasuk input negatif dan besar melebihi 256 bit, memeriksa panggilan lama benar-benar wujud, determinisme, pemilikan keadaan, input yang tidak diubah serta ralat. Semua regresi Stage 1–7 terus diwajibkan.

### Had tahap

Tiada penyimpanan tersembunyi terbalik atau tampalan 05 dibina dalam Stage 9. Struktur nama sumber dan fixture kanonik tidak disentuh; langkah berikut ialah Stage 10, DISCOVERY 05.


## Stage 10 — DISCOVERY 05: Titisan tersembunyi dalam stor songsang

### Andaian sejarah yang salah

Sistem mula menyimpan tujuh titisan dengan `hidden7` di slot 1 dan `hidden1` di slot 7. Pembaca lama `wrongNearness` menganggap slot `k` sendiri ialah titisan `k` dari yang terdekat. Penyimpanan dilakukan oleh `buildStoredBackward` selepas rumus untuk setiap `k` dihitung mengikut rujukan normatif; hanya susunannya songsang.

### Pendedahan sebenar

Penghala `HIDDEN_BACKWARD_LEGACY` membina kiraan menggunakan tampalan hari dan jarak sedia ada, jadual batu yang sudah dibetulkan oleh Stage 9, lalu memanggil penyimpan legacy. Hasil produksi masih dibaca melalui indeks salah. Ujian membandingkan keluaran dengan `NormativeSauce::buildHiddenDrops` dalam direktori oracle PHP tempatan sahaja. Untuk 12 pasangan hari, enam daripada tujuh slot dijangka berbeza dan slot tengah, 4, tetap sepadan. Keseluruhan 72 perbezaan keluar merah dengan kod 1, dan pemeriksa khusus menerima hanya corak tepat itu.

### Pertambahan sistem

Penyimpan legacy, pendedah salah, dispatcher serta konteks per-panggilan menjadikan sejarah stor kelihatan jelas. Tiada input matematik diambil daripada metrik atau log. Katalog nama, fixture, fungsi SAVE, jarak dan batu tidak diubah.

### Had yang sengaja dikekalkan

Tiada pembetulan peta `8-k` diwujudkan lagi. Jangan menterbalikkan susunan stor untuk membetulkan gejala; perkara ini ialah tugas Stage 11 (PATCH 05).


## Stage 11 — PATCH 05: Pembetulan kedekatan melalui indeks 8-k

### Apa yang dielakkan

Stage 10 memperkenalkan `LegacyHiddenBackward` dengan susunan `hidden7,hidden6,...,hidden1` di dalam stor dan pembaca `wrongNearness` yang salah menganggap slot 1 paling dekat. Pemindahan atau penyongsangan stor akan memusnahkan bukti asal. Oleh itu stor, fungsi pembaca salah dan dispatcher sejarah kekal utuh.

### Mengapa patch setara

`HiddenNearnessPatch05` menerima `k` dengan had 1..7, menterjemah hanya akses kepada slot `8-k`, dan memanggil `wrongNearness` pada stor yang sama. Ini memulihkan nilai titisan yang betul tanpa mengubah rumus atau urutan penyimpanan. Setiap pembinaan melalui `BootstrapKernel::hiddenDrops(c,t)` mempunyai konteks semantik dan objek patch sendiri.

### Bukti ujian

Regresi Stage 10 kekal merah secara langsung pada legacy, dengan 72 ketakpadanan dan 12 padanan bagi 12 pasangan. Penerimaan Stage 11 wajib membandingkan pengeluaran dengan `NormativeSauce` dalam skop ujian sahaja, meliputi 37 pasangan, 259 nilai titisan, 128 stor sintetik × tujuh slot, setiap penanda legacy, ralat input dan kesetaraan semantik Stage 1–9. Pemuat ujian lama masih hijau.

### Had

Stage 12 (DISCOVERY 06 — penggunaan sejarah yang tidak mengenali slot hidden bagi indeks tidak positif) belum ditambah. Tidak berlaku bacaan oracle dalam kod produksi.


## Stage 12 — DISCOVERY 06: Pembaca prior sejarah tiada laluan ke hidden

### Kecacatan asal yang dibuktikan

Pembaca `LegacyVisiblePrior::legacyPrior` mencari `dropStore[i-back]` sahaja. Bagi slot 0 hingga -6, tujuh titisan hidden yang sudah dikira oleh PATCH 05 tidak disentuh. Pembaca memulangkan `null` apabila nilai tidak ditemui; laluan sejarah ini tidak diubah dan tidak diisi fallback palsu.

### Pertambahan seni bina

`VISIBLE_PRIOR_LEGACY` didaftarkan dalam `BootstrapDispatcher`. `BootstrapKernel::priorLegacy` menyerahkan stor, indeks dan jarak-undur dalam konteks semantik baharu bagi setiap panggilan; status pemerhatian membezakan `VISIBLE_PRIOR_RETURNED` daripada `VISIBLE_PRIOR_MISSING`. Semua akses positif masih menghala melalui legacy, bukan oracle.

### Bukti yang dikunci dan had tahap

Empat pasangan tarikh × 46 indeks terlihat × tiga jarak-undur (1,3,7) menghasilkan tepat 44 kekosongan hidden yang dijangka, 508 bacaan terlihat yang betul, dan 28 nilai hidden setara oracle. Pembalut menerima hanya RED terkawal, tanpa ralat tambahan. Run GitHub Actions `38894141862` pada SHA `255fc02e37a8071bc7ab98948a91df4abcef1c34` menghasilkan `KEPUTUSAN MERAH_DIJANGKA missing=44 found=508 hidden=28 lain=0` dan `LULUS kontrak merah 06; prior legacy buta terhadap hidden`. Kedua-dua kerja CI hijau. Kunci nama, fixture dan regresi Stage 1–11 kekal lulus.

`priorPatch` dan pembacaan slot tidak positif melalui `hiddenByNearness` tidak ditambah pada Stage 12. Tugasnya ialah Stage 13 — PATCH 06. Fungsi penjanaan titisan terlihat dan oracle tidak disentuh.


## Stage 13 — PATCH 06: Pembaikan bacaan prior dengan slot hidden

### Mengapa pembaca sejarah tidak diubah

Pembaca `LegacyVisiblePrior::legacyPrior` hanya mengakses `dropStore[i-back]`. Bagi slot 0..-6, ia memulangkan `null` walaupun hidden sedia dihitung. Penemuan ini disimpan sepenuhnya; ia masih boleh diuji melalui `priorLegacy`. Tiada fallback sifar palsu.

### Penghala dan pembaikan

`PriorAccessPatch06` menerima pembaca legacy dan adapter `HiddenNearnessPatch05`. `slot=i-back` diputuskan pada satu titik: jika positif, pembaca legacy **benar-benar** dipanggil. Jika sifar atau negatif, `k=1-slot` diserahkan kepada `hiddenByNearness`, yang sudah memetakan hidden dengan indeks `8-k` melalui pembaca backward legacy. Penghala produksi `PRIOR_PATCH_06` menggunakan konteks dan metrik setiap panggilan tanpa berkongsi cache boleh ubah.

### Skop ujian

Penguji membaca enam pasangan tarikh daripada oracle PHP tempatan untuk nilai hidden sebenar; semua 46 slot visible × tiga lookback (1,3,7) diliputi pada setiap pasangan. Sebanyak 762 bacaan visible mengekalkan warisan tepat dan 66 bacaan hidden mengikut oracle tanpa null. Selainnya, 128 stor sintetik × 21 akses menguji peta slot dan neutraliti input; tujuh kes tidak sah menguji sempadan. Ujian Stage 12 diubah pada pengesahnya sahaja agar menerima pembetul baharu tanpa melemahkan bukti legacy. Semuanya tertakluk kepada pengesahan CI penuh.

### Perkara yang belum dibina

Tahap ini tidak membina 46 titisan visible, kerana kerja itu bermula pada Stage 14. Tiada oracle dalam kod produksi, tiada pembetulan sejarah terus, tiada perubahan nama kanonik, fixture atau main.


## Stage 14 — DISCOVERY 07: Baris pengisaran bergeser satu slot

### Kecacatan sejarah yang aktif

`LegacyVisibleGrind::legacyGrindRows` menyimpan 11 baris normatif pada indeks 0..10. Fungsi sejarah `legacyRowAt(g)` terus membaca `rows[g]` bagi `g=1..11`; apabila tiada baris ke-11, ia menggunakan fallback salah ke baris 0. Oleh itu ia menggunakan baris ke-2 hingga ke-11 sebelum mengulangi baris pertama. Kerosakan berlaku dalam pilihan baris, bukan dalam pengiraan integer, SAVE, akses hidden atau formula asas titisan.

### Rantaian pengiraan yang ditambah

`BootstrapKernel::visibleDrops(c,t)` membuka konteks dan penghala `VISIBLE_GRIND_LEGACY`, memperoleh kiraan PATCH01–03, batu PATCH04, stor hidden backward daripada legacy yang dikekalkan, serta prior PATCH06. `LegacyVisibleGrind::buildVisibleWrong` menghasilkan 46 titisan satu demi satu dengan 11 pengisaran untuk setiap titisan, memanggil `legacyRowAt` yang salah tanpa normalisasi tersembunyi. Keadaan titisan tidak dikongsi antara panggilan. Semua matematik menggunakan `BigInt`, tiada oracle dalam sumber produksi.

### Bukti merah

Ujian khas membandingkan 3 pasangan hari dan seluruh 46 titisan terhadap `NormativeSauce::buildVisibleDrops` daripada direktori ujian. Dijangka 138 penyimpangan, sifar padanan luar jangka dan semua 138 nilai dalam julat SAVE. Jadual indeks lama 0..10, keluaran `legacyRowAt(1), (10), (11)` dan dua indeks tidak sah diperiksa sendiri. Laluan produksi dan panggilan langsung kepada kelas legacy dibandingkan, sambil mengekalkan ujian prior, hidden, batu, jarak dan SAVE terdahulu. Pembalut mengiktiraf hanya merah yang tepat.

### Had PATCH07

Penyelesaian yang dibenarkan pada Stage 15 sahaja: masukkan sentinel di indeks 0 dan jadikan sebelas baris pengisaran nyata tersedia pada indeks 1..11, tanpa membuang `legacyRowAt`, tanpa mengubah rumus dan tanpa memadam sejarah yang salah. Tiada permutasi mangkuk atau pemindahan lain dicipta.


### Keputusan GitHub Actions yang disahkan

**Run:** `38915860291`  
**Commit diuji:** `324b0e90ed6e923c08ebc3b19aadf1ec1aad8d8e`  
**Kerja:** `verify=success`, `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
LULUS Stage 13 PATCH 06 positif=762 hidden=66 oracle_hidden=42 sintetik=2688 ralat=7
KEPUTUSAN MERAH_DIJANGKA divergence=138 kes=3 julat=138 lain=0
LULUS kontrak merah 07; indeks grind legacy salah, sentinel belum ditambah
```

Keadaan `EXPECTED_RED` adalah benar-benar terbukti: hanya ujian sejarah langsung keluar dengan kod 1; pembalut khas keluar dengan kod 0. Tiada ralat luar jangka dan semua ujian Stage 1–13 termasuk kunci nama serta fixture telah lulus. Stage15 — PATCH07 belum dimulakan.


## Stage 15 — PATCH 07: Pemetaan baris dengan sentinel tanpa kehilangan legacy

### Asal kecacatan dan cara rawatan

`LegacyVisibleGrind::legacyGrindRows` kekal dengan sebelas baris pada indeks 0..10, dan `legacyRowAt(g)` tetap membaca `rows[g] ?? rows[0]` bagi `g=1..11`. Untuk mengekalkan parut sejarah, kod lama tidak diubah. `GrindTablePatch07::rowsWithSentinel` menghasilkan satu jadual baharu, menambah `[0,0,0,0,'none']` pada slot 0 dan mengalihkan setiap baris sejarah kepada slot `index+1`. Nilai sentinel tidak pernah dikira sebagai pengisaran sebenar kerana pembaca lama bermula pada 1.

### Integrasi monsternya

`GrindTablePatch07` membalut satu `LegacyVisibleGrind` yang dibina dengan suntikan jadual sentinel. `grindPatch(g)` memanggil `legacyRowAt(g)` untuk membuktikan akses lama hidup; `buildVisible` memanggil `buildVisibleWrong` yang sama, tetapi dengan jadual baharu. Penghala `VISIBLE_GRIND_LEGACY` tidak dibuang; `visibleDropsLegacy` memperlihatkan kegagalan lampau. Penghala baharu `VISIBLE_GRIND_PATCH_07` menjadi laluan keluaran `visibleDrops`. Metrik dan keadaan semantik dimiliki konteks setiap panggilan, bukan input matematik.

### Bukti wajib

Ujian Stage 14 masih mesti mengembalikan kod 1 dengan 138 perbezaan berbanding oracle, sementara pembalut pengesah keluar 0. Ujian Stage 15 membandingkan 46 titisan × 8 pasangan hari = 368 komponen normatif, tiga pasangan sejarah yang terus berbeza pada 138 komponen, kesetaraan jadual sentinel, pembaca legacy sebenar, pemilikan state, sempadan indeks dan semua regresi Stage 1–13. Keputusan CI sebenar dan SHA akan direkodkan selepas sah.

### Had tahap

Tampalan ini tidak mengubah fungsi SAVE, susunan batu, rumus visible, keturunan hidden, atau pemilihan permutasi. Stage 16 (DISCOVERY 08) ditangguhkan sehingga PATCH 07 hijau di GitHub Actions.


### Bukti GitHub Actions Stage 15 — disahkan

**Run:** `38923823861`  
**SHA diperiksa:** `8fc05d7687acf128026dfdc3a61bb851f9b32adf`  
**Pekerjaan:** `verify=success`; `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
LULUS Stage 13 PATCH 06 positif=762 hidden=66 oracle_hidden=42 sintetik=2688 ralat=7
KEPUTUSAN MERAH_DIJANGKA divergence=138 kes=3 julat=138 lain=0
LULUS kontrak merah 07; legacy kekal salah dan sentinel hanya dalam tampalan
LULUS Stage 15 PATCH 07 kes=8 komponen=368 parut=138 ulang=46 baris_sintetik=1408
```

Semua ujian Stage 1–14, pemeriksaan nama kanonik dan fixture turut lulus. Stage 15 ialah PATCH GREEN yang diterima; Stage 16 belum bermula. Tidak terdapat handoff PHP aktif dalam `Pending_User_Execution`.


## Stage 16 — DISCOVERY 08: Keliru ordinal bagi permutasi mangkuk

### Bukti punca sejarah

`LegacyPermutationUnrank0` melaksanakan penyahpangkat leksikografik enam elemen mengikut baki faktorial dengan pangkat sifar 0..719. Setiap hasil itu sendiri sah, lengkap dan dibandingkan dengan oracle ujian `NormativeSauce::permutationUnrank1(rank0+1)`. Kesalahan berlaku di pembaca `LegacyBowlPermutation` yang mendapat pangkat satu daripada titisan dan menghantarnya tanpa menolak satu. Panggilan sejarah ini wajib kekal dapat dicapai.

### Lapisan tambahan

Penghala `BOWL_PERMUTATION_LEGACY` dalam `BootstrapKernel` membina objek pembaca setiap panggilan, menyimpan nilai pemerhatian dalam `BootstrapContext`, merekod metrik, kemudian benar-benar memanggil pembaca legacy yang salah. Tiada oracle ujian atau jadual permutasi salinan dalam produksi. Rangka kerja SAVE, 46 titisan visible, prior, hidden dan batu tidak diubah.

### Penemuan merah yang diminta

Bagi input rank1 1..719, keluaran pangkat sifar salah satu langkah berbanding hasil normatif. Pada rank1 720, pengecualian julat sengaja berlaku. Ujian mengesahkan semua 720 pangkat sifar tulen benar, kemudian menilai 720 input pangkat satu, nilai negatif, `BigInt` lebih daripada 256 bit dan 46 titisan visible sebenar. Pengesah menerima hanya corak `salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0` dan keluar 0, walaupun ujian langsung keluar 1.

### Batas Stage 16

Tiada `permutationPatch` atau pengurangan pangkat satu kepada sifar dalam pembaca sejarah. Pembaikan ini ialah Stage 17 — PATCH 08. Belum dibuat tuangan mangkuk, pemilihan selepas 46 titisan, atau perubahan katalog, fixture ataupun `main`.


### Bukti penerimaan GitHub Actions

**Run:** `39413144285`  
**SHA yang diuji:** `afd8456b0914e88c5ee5240880cc40db9e914a78`  
**Kerja:** `verify=success`; `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
LULUS Stage 15 PATCH 07 kes=8 komponen=368 parut=138 ulang=46 baris_sintetik=1408
ORDINAL1_MISALIGNED rank=1
RANK720_REJECTED rank=720
KEPUTUSAN MERAH_DIJANGKA salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0
LULUS kontrak merah 08; pangkat satu dihantar ke fungsi pangkat sifar
```

Oleh itu Stage 16 ialah `EXPECTED_RED` yang benar-benar diperakui, bukan kegagalan CI. Semua ujian sebelumnya lulus. Stage 17 — PATCH 08 belum dimulakan.


## Stage 17 — PATCH 08: Susunan mangkuk sah daripada pembaca sifar lama

### Pembaikan yang tidak memadam sejarah

`LegacyBowlPermutation` dan `LegacyPermutationUnrank0` langsung tidak disentuh. Kerosakan ordinal Stage 16 masih dapat diperhatikan melalui `legacyBowlOrder`: 719 pangkat beralih kepada susunan lain dan satu pangkat melemparkan pengecualian pada 720. `PermutationPatch08` menerima dependency legacy yang sama, melaksanakan panggilan sejarah yang sebenar, menerima hanya pengecualian `PERMUTATION_RANK_ZERO_RANGE` pada rank1=720, kemudian meminta pembaca sifar yang betul dengan rank1-1.

### Pertumbuhan lapisan monsternya

Penghala produksi `BOWL_PERMUTATION_PATCH_08` mencipta pembaca sifar, pembaca legacy, dan adapter Stage 17 pada konteks permintaan itu sahaja. Laluan `BOWL_PERMUTATION_LEGACY` masih wujud dengan kontrak lama. Metrik dan keadaan semantik tidak mengawal keputusan matematik. Tiada oracle atau jadual 720 permutasi disalin ke sumber produksi.

### Pemeriksaan normatif dan regresi

Ujian Stage 17 melintasi semua pangkat 1..720: hasil susunan produksi mesti setara tepat dengan `NormativeSauce::permutationUnrank1`, semua susunan unik, dan setiap hasil daripada enam nombor 1..6 sekali sahaja. Penguji membuktikan pangkat1=1/720, determinisme antara panggilan dan instance, 719 hasil legacy tersasar, pengecualian legacy pada 720, 14 input negatif/BigInt melebihi 256 bit dan 138 hasil susunan daripada tiga pasangan tarikh menggunakan 46 titisan visible Stage15. Pengesah sejarah Stage16 mesti kekal `EXPECTED_RED` yang terkawal dan CI meluluskan seluruh Stage1–17. Keputusan runner dicatat selepas pengesahan sebenar.

### Sempadan peringkat

Stage17 membetulkan pemilihan permutasi sahaja; tidak melaksanakan aplikasi tempias/tuangan mangkuk, pemilihan mangkuk terakhir, atau perubahan kepada katalog sumber, fixture, struktur tahun, ataupun `main`. Stage18 — DISCOVERY09 hanya selepas CI hijau.


### Keputusan GitHub Actions Stage 17 — disahkan

**Run:** `39495731241`  
**SHA diperiksa:** `59583089c1ad2a843935d4753689001c2d1f60d7`  
**Pekerjaan:** `verify=success` dan `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
LULUS Stage 15 PATCH 07 kes=8 komponen=368 parut=138 ulang=46 baris_sintetik=1408
KEPUTUSAN MERAH_DIJANGKA salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0
LULUS kontrak merah 08; pangkat satu dihantar ke fungsi pangkat sifar
LULUS Stage 17 PATCH 08 pangkat=720 unik=720 parut=719 pengecualian=1 integer_besar=14 visible=138 legacy_visible=138 legacy_exception=0
```

Kesimpulan: PATCH 08 GREEN sebenar; bukti sejarah DISCOVERY 08 kekal merah yang disengajakan dan penerimaannya hijau. Semua gerbang CI Stage 1–17 lulus dan tiada kod Stage 18 diperkenalkan.


## Stage 18 — DISCOVERY 09: Pembaca tuangan mengelirukan posisi dengan identiti

### Punca sejarah dan kebolehcerapan

`LegacyBowlFactory` menyediakan enam nilai mangkuk asas sah melalui formula asal dan SAVE. Pembaca `LegacyFixedPositionPours` menerima susunan leksikografik yang telah dibetulkan oleh PATCH08. Namun pembaca lama masih menganggap posisi pertama bermaksud mangkuk ID1, posisi kedua ID2 dan posisi ketiga ID3, walaupun susunan boleh menjadi mana-mana permutasi. Nilai tuangan yang dikira adalah konsisten dengan kecacatan itu dan tidak membaca oracle.

### Pemasangan seni bina tambahan

`BootstrapKernel::legacyPoursAt` membuka `BootstrapContext` sendiri lalu mendaftar dengan `FIXED_POSITION_POURS_LEGACY`. Aliran mengira 46 titisan daripada PATCH07, susunan daripada PATCH08, batu PATCH04 dan mangkuk asas daripada kilang legacy. Pada akhirnya, pembaca legacy memulangkan jejak empat komponen supaya perbezaan posisi/ID disahkan daripada nilai sebenar. Tiada hasil dituangkan semula ke dalam mangkuk kerana pembetulan snapshot dan pending ialah peringkat lain.

### Ujian merah yang terhad dan tepat

Bagi enam mangkuk sintetik berbeza dan semua 720 susunan, setiap posisi 1,2,3 berada pada ID sendiri bagi 120 permutasi sahaja. Oleh itu terdapat 360 padanan dan 1,800 bacaan salah daripada 2,160 pemeriksaan kedudukan. Ujian membandingkan pengiraan sejarah langsung dan rumus normatif melalui oracle PHP ujian, memastikan posisi 4..6 kekal sifar, memeriksa input tidak sah, serta menjalankan `legacyPoursAt` pada empat keadaan titisan sebenar daripada dua pasangan hari. Pembalut pengesah menerima hanya merah tepat; ujian Stage1–17 kekal wajib.

### Batas tahap

Jangan menambah alias posisi pada Stage18, jangan mengubah legacy fixed IDs, jangan menjalankan update mangkuk in-place atau pending shadow, jangan mewujudkan oracle dalam `src`. Stage19 memperkenalkan alias sambil mengekalkan semua fungsi sejarah.


### Bukti penerimaan GitHub Actions Stage 18

**Run:** `39610007279`  
**Commit sumber:** `5e58dd85f32ef76e969b157201f74b5b0da6d0a8`  
**Pekerjaan:** `verify=success` dan `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
KEPUTUSAN MERAH_DIJANGKA salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0
LULUS Stage 17 PATCH 08 pangkat=720 unik=720 parut=719 pengecualian=1 integer_besar=14 visible=138 legacy_visible=138 legacy_exception=0
KEPUTUSAN MERAH_DIJANGKA salah=1800 sepadan=360 pangkat=720 real=4 lain=0
LULUS kontrak merah 09; tuangan menggunakan identiti tetap bukan posisi
```

Tahap ini diterima sebagai `EXPECTED_RED` yang disahkan, bukan kegagalan CI; seluruh ujian Stage1–17 dan ujian nama, sintaks, serta fixture lulus. Stage19 belum dimulakan.


## Stage 19 — PATCH 09: Alias posisi bagi mangkuk yang diterima oleh legacy

### Rawatan tanpa memadam fungsi salah

Pada Stage18, `LegacyFixedPositionPours::legacyPours` membaca `oldBowls[1]`, `oldBowls[2]`, `oldBowls[3]` untuk tiga tuangan pertama, walaupun permutasi `order` mungkin meletakkan identiti berbeza di ketiga-tiga posisi. Stage19 tidak mengubah fungsi salah itu. `PoursAliasPatch09` membina enam alias 1..6 daripada `order[position-1]`, menyediakan paparan `view[position]=oldBowls[bowlAlias[position]]` dengan `bowlByLegacyPosition`, dan menyerahkan paparan itu kepada fungsi legacy asal.

### Pertumbuhan penghala dan konteks

`BootstrapKernel::poursAt` mendaftarkan `POURS_ALIAS_PATCH_09` yang membina titisan visible, permutasi PATCH08, mangkuk asal `LegacyBowlFactory` dan batu PATCH04 dalam satu konteks. `legacyPoursAt` masih menghala ke `FIXED_POSITION_POURS_LEGACY`, dan keputusan itu kekal salah apabila posisi berbeza daripada ID. Tiada oracle dalam produksi, tiada penulisan semula nilai mangkuk, tiada cache berkongsi.

### Gerbang pengesahan Stage19

Untuk semua 720 order leksikografik, ketiga-tiga tuangan mesti mematuhi rumus normatif tepat; alias dikira juga bagi posisi ke-4 hingga ke-6 tetapi tuangan pada posisi tersebut kekal sifar. Oleh itu pemeriksaan menghasilkan 2,160 tuangan dan 4,320 lookup alias, sambil membuktikan 1,800 kes legacy salah dan 360 padanan apabila ID sama dengan posisi. Empat kes produksi sebenar disemak, dengan 24 nilai tuangan dan kesetaraan oracle, 6 input tidak sah ditolak. Pengesah `EXPECTED_RED` Stage18 masih mesti hijau, setelah membuktikan kegagalan sejarah langsung. Seluruh regresi Stage1–18 masih diwajibkan.

### Sempadan tahap

Tiada in-place bowl mutation atau snapshot pending dilakukan di sini. Stage20 — DISCOVERY10 akan memperkenalkan masalah itu, dan Stage21 — PATCH10 akan memperkenalkan vaultOld dan pending. Tiada perubahan pada main, nilai rujukan, katalog nama atau fixture.


### Bukti GitHub Actions Stage 19 — hijau disahkan

**Run penerimaan:** `39612888306`  
**SHA diuji:** `1e6d29a094c35c779d16770192f74fada3c14450`  
**Kerja:** `verify=success`, `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
KEPUTUSAN MERAH_DIJANGKA salah=1800 sepadan=360 pangkat=720 real=4 lain=0
LULUS kontrak merah 09; tuangan menggunakan identiti tetap bukan posisi
LULUS Stage 19 PATCH 09 pangkat=720 tuangan=2160 legacy_salah=1800 legacy_sepadan=360 alias=4320 real=4 real_tuangan=24 ralat=6
```

Run calon awal `39612576553` gagal pada ujian Stage01 `FUTURE_TOKEN_bowlAlias`, kerana nama medan pemerhatian dalam `BootstrapKernel`. Ia dibaiki di commit `1e6d29a0` dengan menamakan medan itu `positionAliases`, tanpa mengubah sebarang formula atau melonggarkan ujian. Run kedua menerima semua gerbang termasuk Stage01 dan Stage19. Stage20 belum bermula.


## Stage 20 — DISCOVERY 10: Pencemaran nilai mangkuk di tengah satu titisan

### Cacat asal: penulisan terlalu awal

Fungsi sejarah `LegacyInPlaceBowlStir::stirOneDropWrong` mengekalkan pengiraan enam mangkuk mengikut `order` yang sah. Setiap posisi menggunakan formula tepat bagi ID dan kedua-dua jiran lingkaran, tiga tuangan atau sifar, titisan, jenis batu dan nilai SAVE. Masalahnya ialah hasilnya segera disimpan dalam `bowls[id]` sebelum posisi seterusnya bermula. Oleh itu bacaan `bowls[prev]` atau `bowls[next]` boleh merujuk nilai selepas mutasi, bukannya keadaan pada permulaan titisan.

### Lapisan observable yang ditambah

`IN_PLACE_BOWL_STIR_LEGACY` menjemput penghala `POURS_ALIAS_PATCH_09` untuk jejak tuangan sah, kemudian menyerahkan salinan stor mangkuk kepada `LegacyInPlaceBowlStir` yang mutasinya sebenar. `BootstrapKernel::legacyStirAt` memulangkan mangkuk asal dan mangkuk salah bersama input lain. Metrik serta konteks semantik milik panggilan tidak menjadi input formula. Tiada oracle normatif digunakan dalam sumber `src`.

### Kaedah pembuktian

Untuk semua 720 susunan leksikografik pada stor mangkuk berbeza yang tetap, bandingkan penulisan in-place dengan pengiraan rujukan dalam `tests` yang membaca hanya stor asal. Tepat satu padanan bagi setiap susunan, pada posisi pertama (720 keseluruhan), dan lima perbezaan pada posisi seterusnya (3,600 keseluruhan). Bagi empat set tarikh/indeks visible sebenar, jejak produksi dibandingkan dengan pembinaan langsung legacy dan perbandingan snapshot. Kes tidak sah dan bentuk stor diuji; ujian sejarah keluar 1 untuk penemuan terkawal, manakala pembalut pengesah keluar 0 jika tiada ralat lain.

### Had tahap yang wajib

Pembaikan `vaultOld=clone(B)`, penulisan ke `pending`, dan commit enam mangkuk sekaligus tidak diwujudkan sebelum PATCH10 Stage21. Keseluruhan rantaian SAVE, hidden, visible, permutasi, alias, oracle dan fixture tidak diubah; jangan buka Stage21 selagi penemuan merah ini belum disahkan.


### Bukti GitHub Actions — Stage 20

**Run penerimaan:** `39622805001`  
**HEAD diuji:** `27f7a87cc88159df4ad45d281313e9c06def1d9b`  
**Keputusan:** kedua-dua pekerjaan `verify` dan `audit_php_bahasa_melayu` berjaya.

```text
LULUS Stage 19 PATCH 09 pangkat=720 tuangan=2160 legacy_salah=1800 legacy_sepadan=360 alias=4320 real=4 real_tuangan=24 ralat=6
POSISI_PERTAMA_SEPADAN pangkat=720
POSISI_BERIKUT_TERCEMAR pangkat=720 kedudukan=2..6
KEPUTUSAN MERAH_DIJANGKA salah=3600 sepadan=720 pangkat=720 real=4 real_salah=20 ralat=4 lain=0
LULUS kontrak merah 10; mangkuk legacy tercemar tanpa snapshot
```

Ini ialah `EXPECTED_RED` yang disahkan, bukan kegagalan CI. Semua regresi Stage 1–19, kunci nama kanonik dan sintaks PHP telah lulus. Stage 21 — PATCH10 belum dimulakan.


## Stage 21 — PATCH 10: Vault lama dan pending enam mangkuk

### Kesilapan lama tetap hidup

`LegacyInPlaceBowlStir::stirOneDropWrong` kekal tidak diubah: ia membaca mangkuk terkini dan segera menulis setiap hasil. Ini mengubah bacaan jiran bagi posisi 2..6. Ujian Stage 20 masih melihat tepat 3,600 perbezaan dan 720 padanan daripada 720 permutasi, serta empat jejak sejarah sebenar.

### Pembaikan yang menjaga jejak asal

`BowlShadowPatch10::stirOneDropViaShadow` memanggil fungsi legacy secara sebenar pada `garbage` yang merupakan salinan mangkuk. Ini juga mengesahkan input sebelum pembetul menyentuh stor pemanggil. Kemudian `vaultOld` dibina daripada keadaan asal dan `pending` daripada salinan berasingan. Keenam-enam rumus menggunakan mangkuk `vaultOld[id]`, `vaultOld[prev]` dan `vaultOld[next]` semata-mata, dengan tuangan, batu dan tetapan SAVE yang sama. Hasil disimpan dalam `pending[id]`, tanpa membacanya sehingga semua enam siap, kemudian satu commit `bowls=pending`.

### Penghala dan bukti ujian

`BOWL_SHADOW_PATCH_10` dalam `BootstrapKernel` menerima jejak `poursAt` yang sudah dibetulkan pada Stage19, lalu membuat pembaca legacy dan pembetul bagi konteks itu sahaja. `stirAt(c,t,i)` memulangkan jejak sah; `legacyStirAt(c,t,i)` terus memulangkan jejak salah secara berasingan. Ujian Stage 21 meliputi 720 susunan, 4,320 hasil, 3,600 perbezaan legacy, 720 padanan, empat tarikh/indeks sebenar, 24 hasil serta lima kegagalan input tanpa commit. Formula rujukan dibina secara bebas dalam direktori `tests`. Tiada oracle dimasukkan ke `src`.

### Had perkembangan

Stage21 hanya membaiki satu titisan. Ia tidak menjalankan 46 titisan sebagai state machine, tidak menghasilkan `orderAt46Latch` sebelum Stage23, dan tidak mencipta sebarang peraturan bowl-next. Stage22 ialah DISCOVERY11 yang berikutnya. Terima hanya apabila CI sebenar hijau dan `EXPECTED_RED` Stage20 terpelihara.


### Bukti GitHub Actions bagi Stage 21 — diterima

**Run:** `39732200876`  
**SHA diuji:** `1929bb3ba57d3371f4b927d552e71930e5f7ad8a`  
**Pekerjaan:** `verify=success`; `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
KEPUTUSAN MERAH_DIJANGKA salah=3600 sepadan=720 pangkat=720 real=4 real_salah=20 ralat=4 lain=0
LULUS kontrak merah 10; mangkuk legacy tercemar tanpa snapshot
LULUS Stage 21 PATCH 10 pangkat=720 komponen=4320 parut=3600 sepadan_legacy=720 real=4 real_komponen=24 real_parut=20 real_sepadan=4 ralat=5
```

CI lengkap sah dan semua gerbang Stage1–20 lulus. Stage21 diterima sebagai `GREEN` dengan pembetul snapshot sah, sejarah salah masih terbukti. Stage22 belum dimulakan.


## Stage 22 — DISCOVERY 11: Pemboleh ubah order titisan 46 ditindih

### Apa yang dipercayai oleh kod lama

Selepas titisan visible ke-46, pemboleh ubah `order` memang mengandungi permutasi mangkuk untuk titisan itu. Pelaksana lama menganggap nilai ini akan terus tersedia setelah dua belas kacauan terakhir. Sebenarnya setiap kacauan pasca-titisan menggunakan nama `order` yang sama bagi permutasinya sendiri; susunan titisan 46 hilang dan bacaan akhir menerima permutasi kacauan terakhir.

### Kod baharu yang tidak membaiki kecacatan

`LegacyOverwrittenOrder11` memanggil kilang mangkuk, pembetul pangkat, alias tuangan, dan shadow snapshot Stage21 bagi 46 titisan sebenar dalam urutan. Selepas itu ia melaksanakan 12 post-stir dengan bacaan hanya daripada snapshot `old` dan semua tulisan kepada `pending`. Rumus mangkuk masih tepat. Hanya `orderAtDrop46` terakhir salah kerana 12 kali ditulis semula. Tiada latch berasingan disediakan.

Penghala `OVERWRITTEN_ORDER_46_LEGACY` menghasilkan konteks baharu bagi setiap permintaan, merekod metrik dan status, tanpa menjadikan metrik sebahagian daripada formula. Oracle normatif hanya digunakan dalam ujian. Katalog nama, fixture dan formula Stage 1–21 kekal tanpa perubahan.

### Bukti dan had peringkat

Ujian Stage22 membandingkan tiga tarikh meliputi 46 titisan dan 12 post-stir setiap satu terhadap oracle tempatan yang dibina dalam PHP. Keenam-enam mangkuk terakhir mesti tepat bagi setiap tarikh (18 komponen); sebaliknya susunan yang terdedah berbeza daripada `orderAtDrop46` normatif kerana ia sama dengan permutasi post-stir terakhir. Tiga RED yang terkawal dan sifar ralat tidak dijangka diperlukan. Pemeriksa memperakui kod keluar 1 hanya untuk corak ini dan keluar 0 apabila berjaya.

Penyelesaian Stage23 mesti menyimpan salinan susunan tepat selepas titisan 46 dan sebelum post-stirs, tidak menulis latch itu lagi, sambil meninggalkan pemboleh ubah legacy salah sebagai bukti. Tidak diperkenalkan pada Stage22.

## Stage 23 — PATCH 11: Bukti Native

Run GitHub Actions 39818136362 pada commit da93ec7b1dc7bae9146c4818f4182bff7cfc87e7 selesai SUCCESS. Kedua-dua pekerjaan verify serta audit_php_bahasa_melayu hijau, termasuk ujian Stage23, sejarah Stage22, semua regresi lebih awal, sintaks PHP, nama dan fixture. Stage23 diterima GREEN dengan latch susunan titisan 46 tanpa memadam parut sejarah. Main tidak diubah.

## Stage 24 — DISCOVERY 12: Andaian jiran nombor

LegacyNumericSuccessor12::askWrong menerima mangkuk akhir dan orderAtDrop46 yang telah dibetulkan melalui Stage23. Namun kaedah sejarah menggunakan nextBowlId=(queriedBowlId % 6)+1, bukannya jiran daripada susunan tersebut. BootstrapKernel menyediakan NUMERIC_NEXT_BOWL_LEGACY serta konteks milik panggilan. 720 permutasi × enam pertanyaan mesti mendedahkan 3456 penyimpangan jiran dan 864 padanan; tiga pasangan tarikh sebenar dan penolakan input juga diuji. Oracle hanya dalam direktori tests. Status Stage24 ialah AWAITING_CI hingga bukti Native SHA baharu diperiksa; tiada PATCH12 atau perubahan main.

## Stage 25 — PATCH 12: Jiran bukan nombor berturutan

Stage24 membuktikan 3,456 jiran legacy yang salah dan 864 yang sepadan dalam seluruh 720 susunan enam mangkuk. Penampal `NextBowlOrderPatch12` mengekalkan panggilan sebenar kepada `LegacyNumericSuccessor12::askWrong` lalu memilih ID jiran berdasarkan posisi dalam orderAtDrop46, bukan pada nilai angka ID. Formula first/step dan SAVE kekal, nombor asal tidak diubah. Dispatcher `ORDER_NEIGHBOR_PATCH_12` menjadi laluan produksi di samping `NUMERIC_NEXT_BOWL_LEGACY`; konteks baharu setiap panggilan. Ujian 720×6, meterai tambahan, tiga pasangan sebenar, penolakan input, ujian legacy dan keseluruhan CI diperlukan sebelum GREEN. Stage26 belum dimulakan.


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

Semua Stage1–34, fixture, lint PHP dan kunci nama kanonik mesti lulus Native CI. Stage35 mempunyai pekerjaan khusus `audit_php_bahasa_melayu_stage35`; semua **enam pekerjaan** pada SHA HEAD yang sama wajib SUCCESS. **Status: AWAITING_CI** sehingga pengesahan Native penuh. Jangan mulakan Stage36, ubah `main`, fixture atau katalog.
