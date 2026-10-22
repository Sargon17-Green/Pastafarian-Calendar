# Serahan Stage 21 — PATCH 10

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `f447f0c2f3f58495e5fd9cd2b45b69b42779983d`  
**Tahap:** 21/55; PATCH 10; sasaran `GREEN`.

## Pembaikan semantik

`BowlShadowPatch10::stirOneDropViaShadow` mesti memanggil `LegacyInPlaceBowlStir::stirOneDropWrong` secara benar pada salinan, kemudian melaksanakan snapshot `vaultOld` daripada input lama dan penulisan semua enam hasil kepada `pending`, sebelum satu commit akhir kepada `bowls`. Semua bacaan mangkuk semasa enam posisi datang daripada `vaultOld`, tidak pernah daripada `pending`. Input salah dilemparkan oleh validasi legacy tanpa mengubah mangkuk asal.

`BootstrapKernel::stirAt` dan dispatcher `BOWL_SHADOW_PATCH_10` menjadi pintu masuk baru. `legacyStirAt` dan `IN_PLACE_BOWL_STIR_LEGACY` kekal untuk kegagalan sejarah Stage20.

## Penerimaan

```text
php -d memory_limit=512M tests/verify_stage20_discovery10.php
php -d memory_limit=512M tests/stage21_patch10_tests.php
```

Pengesah sejarah Stage20 mesti kekal hijau dengan RED langsung 3,600 perbezaan, 720 padanan dan empat jejak sebenar. Ujian Stage21 mesti membuktikan 720 permutasi, 4,320 komponen yang sah, 3,600 hasil legacy tersasar, 720 padanan pertama, empat tarikh sebenar × enam mangkuk, 20 parut sebenar, empat padanan pertama dan lima penolakan input.

Seluruh Stage1–20, fixture, syntax dan kunci nama kanonik mesti hijau. CI yang dijalankan atas SHA tepat ialah gerbang penerimaan; sebelum itu pembetulan tidak boleh ditandakan selesai.

## Sempadan

Jangan ubah `main`, fungsi legacy lama, oracle, katalog, fixture atau cabang lain. Jangan mula Stage22 sebelum semua CI hijau. Tiada `orderAt46Latch` atau keseluruhan 46 stirs di sini.

**Commit:** `stage21(php-ms): vault dan pending enam mangkuk tanpa memadam legacy`


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
