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
