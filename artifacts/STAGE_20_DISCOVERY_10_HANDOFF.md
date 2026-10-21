# Serahan Stage 20 — DISCOVERY 10

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas tepat:** `da13a43e874ae186639dd4e4612ffcb6072fb471`  
**Sasaran tahap:** 20/55, DISCOVERY 10, `EXPECTED_RED`  
**Tanggungjawab:** pengguna tidak perlu menjalankan sebarang pakej tempatan jika CI berjaya.

## Keadaan sejarah yang sengaja rosak

`LegacyInPlaceBowlStir::stirOneDropWrong` mengambil enam nilai mangkuk daripada keadaan semasa; bagi posisi 1..6, ia mengira formula satu titisan, kemudian **segera** menulis nilai ke `bowls[id]`. Bacaan posisi kemudian menjadi tercemar. Jangan membetulkannya dalam Stage20.

`BootstrapKernel::legacyStirAt(c,t,i)` mencipta konteks panggilan sendiri, memperoleh jejak `POURS_ALIAS_PATCH_09` dan kemudian memanggil kod legacy sebenar. Ia memulangkan `drop`, `order`, `oldBowls`, `pours` dan `wrongBowls`. Parameter `$bowls` dalam legacy ditulis dengan reference PHP; panggilan tunggal tidak boleh mencemarkan panggilan lain.

## Gerbang bukti

```text
php -d memory_limit=512M tests/stage20_discovery10_tests.php
php -d memory_limit=512M tests/verify_stage20_discovery10.php
```

Ujian langsung mesti mengembalikan **exit 1** dengan `salah=3600 sepadan=720 pangkat=720 real=4` serta `real_salah>0`, `ralat=4 lain=0`. Pembalut mesti menerima pola merah ini dan keluar **0**. Perbandingan oracle bagi satu titisan berada di `tests` sahaja. Semua ujian Stage1–19, kanon nama, fixture dan sintaks PHP mesti lulus.

## Had tahap

Tiada `vaultOld`, `pending` atau commit pasca-enam-mangkuk dibina pada tahap ini. Semua itu tergolong dalam Stage21 — PATCH10 sahaja. Fungsi `LegacyInPlaceBowlStir` mesti terus wujud, boleh dipanggil dan menghasilkan parut sejarah selepas tampalan berikutnya. Jangan sentuh `main`, jangan membuka Stage21 dan jangan membuat sumber silang daripada cabang lain.

## Status

Diterima: run 39622805001 mengesahkan seluruh pola merah serta kedua-dua pekerjaan CI berjaya. Stage21 boleh dimulakan pada pusingan berikutnya.

**Commit dirancang:** `stage20(php-ms): dedahkan pencemaran mangkuk in-place sebelum snapshot`


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
