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
