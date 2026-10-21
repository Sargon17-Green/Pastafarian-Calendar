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

Gagal jika ada ralat selain RED yang dijangka. Pengesah keluar kod 0 bagi corak tepat sahaja. Semua gerbang Stage1–17, nama kanonik, fixture dan lint PHP harus kekal hijau. Run CI 39610007279 telah mengesahkan Stage18 EXPECTED_RED dengan dua kerja SUCCESS. Stage19 boleh dimulakan pada pusingan berikutnya.

## Had

Jangan sentuh `main`, jangan hapus fungsi legacy, jangan ubah Oracle, jangan melaksanakan alias Stage19 atau snapshot Stage20, jangan menjalankan Stage19 sebelum CI sah.

**Cadangan commit:** `stage18(php-ms): dedahkan tuangan yang menyalahbaca posisi mangkuk`


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
