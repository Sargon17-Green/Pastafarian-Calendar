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
