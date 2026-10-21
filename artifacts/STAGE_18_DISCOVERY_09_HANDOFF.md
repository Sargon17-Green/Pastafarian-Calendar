# Serahan Stage 18 — DISCOVERY 09

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `ef1b4e62f5a66a1e62b325ff6d115a818cd73843`  
**Tahap:** 18/55 — DISCOVERY 09  
**Keadaan sasaran:** `EXPECTED_RED`.

## Jejak kecacatan yang mesti kekal

`LegacyBowlFactory` mengira enam mangkuk asas secara sah daripada kiraan calendar, primes [17,19,23,29,31,37] dan SAVE. `LegacyFixedPositionPours::legacyPours` menggunakan ID mangkuk 1,2,3 yang tetap untuk posisi tuangan 1,2,3 walaupun susunan enam mangkuk daripada Stage17 mungkin berlainan. Pembetulan alias `bowlAlias[position] = order[position]` **tidak boleh** ditambah pada Stage18.

`BootstrapKernel::legacyPoursAt(c,t,i)` ialah titik kemasukan per-panggilan. Ia menggunakan 46 titisan visible PATCH07, order PATCH08, stones PATCH04, kilang mangkuk dan fungsi tuangan sejarah sebenar. Hasil menunjukkan drop/order/oldBowls/pours secara berasingan. Tiada kaedah pengiraan normatif digunakan dalam produksi.

## Bukti ujian diperlukan

```text
php -d memory_limit=512M tests/stage18_discovery09_tests.php
php -d memory_limit=512M tests/verify_stage18_discovery09.php
```

Ujian langsung harus keluar **kod 1** dengan mesej:

```text
KEPUTUSAN MERAH_DIJANGKA salah=1800 sepadan=360 pangkat=720 real=4 lain=0
```

Gagal jika ada ralat selain RED yang dijangka. Pengesah keluar kod 0 bagi corak tepat sahaja. Semua gerbang Stage1–17, nama kanonik, fixture dan lint PHP harus kekal hijau. Bukti CI pada HEAD tertentu wajib sebelum menandakan Stage18 selesai.

## Had

Jangan sentuh `main`, jangan hapus fungsi legacy, jangan ubah Oracle, jangan melaksanakan alias Stage19 atau snapshot Stage20, jangan menjalankan Stage19 sebelum CI sah.

**Cadangan commit:** `stage18(php-ms): dedahkan tuangan yang menyalahbaca posisi mangkuk`
