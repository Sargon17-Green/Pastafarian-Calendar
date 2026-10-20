# Serahan Stage 16 — DISCOVERY 08

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `1755f280041f5514d4e27aab73b3a7fa256b1c4a`  
**Tahap:** 16/55, DISCOVERY 08; sasaran `EXPECTED_RED`.

## Cacat sejarah yang diperlukan

`LegacyPermutationUnrank0::oldPermutationUnrank0` menerima pangkat sifar 0..719 dan menghasilkan salah satu daripada 720 permutasi enam mangkuk dengan tertib leksikografik yang tepat. `LegacyBowlPermutation::legacyBowlOrderFromDrop` menghantar pangkat satu 1..720 kepada fungsi itu tanpa mengurangkan satu. Ini menghasilkan 719 hasil beralih satu pangkat dan pengecualian pada pangkat ke-720. Kesilapan sejarah mesti ditunjukkan, bukan dibetulkan, sehingga Stage 17.

## Pengasingan dan sempadan

`BootstrapKernel::legacyBowlOrder` mengguna dispatcher `BOWL_PERMUTATION_LEGACY` dan konteks sendiri. Tiada fungsi yang membetulkan pangkat, menyusun mangkuk, atau membaca oracle dalam sumber produksi. Rantai perhitungan sebelum Stage 16, termasuk visible Stage 15, tidak diubah. Jangan mengubah `main` atau membuka Stage 17 sebelum bukti merah yang tepat disahkan oleh CI.

## Bukti yang mesti diperoleh

```text
php -d memory_limit=512M tests/stage16_discovery08_tests.php
php -d memory_limit=512M tests/verify_stage16_discovery08.php
```

Ujian sejarah terus mesti keluar **kod 1** dengan:

```text
KEPUTUSAN MERAH_DIJANGKA salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0
```

Pengesah `verify_stage16_discovery08.php` mesti keluar **kod 0** tanpa ralat. Semua ujian Stage 1–15, lint PHP, penguncian nama dan fixture kekal hijau. Pemeriksaan menggunakan oracle dalam `tests/oracle` sahaja.

## Keadaan bukti

CI run 39413144285 telah menerima penemuan ini sebagai EXPECTED_RED tepat; kedua-dua kerja berjaya. Stage 17 boleh dimulakan pada pusingan berikutnya. Tiada handoff untuk dijalankan pengguna selagi semua kerja dapat diselesaikan di GitHub.

**Commit dicadangkan:** `stage16(php-ms): dedahkan kekeliruan pangkat permutasi satu dan sifar`


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
