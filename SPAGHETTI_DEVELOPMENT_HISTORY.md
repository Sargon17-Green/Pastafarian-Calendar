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
