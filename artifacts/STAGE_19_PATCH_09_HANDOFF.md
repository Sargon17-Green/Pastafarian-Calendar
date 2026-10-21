# Stage 19 — PATCH 09: Serahan kejuruteraan

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `3aaa14ea303eef94f3a397e10323152a4ae61b26`  
**Tahap:** 19/55 — PATCH 09; sasaran `GREEN`.

## Mekanisme yang diwajibkan

Pembaikan `PoursAliasPatch09` membuat `bowlAlias[position] = order[position]`, dengan penukaran indeks senarai PHP dari 0 kepada posisi 1. `bowlByLegacyPosition(oldBowls,aliases,position)` membaca mangkuk identiti sebenar. Enam posisi diberi alias, tiga yang pertama digunakan oleh fungsi `LegacyFixedPositionPours::legacyPours` yang kekal salah dan **dipanggil secara sebenar** pada paparan `oldBowls` yang teralias. Pembaca legacy, kilang mangkuk, logik permutasi dan semua matematik terdahulu tidak diubah.

`BootstrapKernel::poursAt(c,t,i)` menggunakan `POURS_ALIAS_PATCH_09`. `legacyPoursAt` masih menggunakan `FIXED_POSITION_POURS_LEGACY`, supaya 1,800 bacaan lama yang salah daripada 720 order boleh diuji semula.

## Gerbang

```text
php -d memory_limit=512M tests/verify_stage18_discovery09.php
php -d memory_limit=512M tests/stage19_patch09_tests.php
```

Semua 720 order dan 2,160 hasil tuangan diperiksa terhadap oracle PHP; 4,320 bacaan alias tepat, legacy mempunyai 1,800 kegagalan dan 360 padanan seperti dahulu. Empat kes live dengan 24 kedudukan serta enam input salah turut diperiksa. Semua gerbang Stage1–18, penguncian nama, PHP lint dan fixture tidak boleh gagal.

## Had

Tidak melakukan perubahan `vaultOld`, `pending`, `rollback` atau penulisan mangkuk in-place. Tiada pemindahan Stage20 atau Stage21 dibenarkan. Jangan sentuh `main`.

**Status selepas CI:** PATCH09 GREEN disahkan; Stage18 EXPECTED_RED kekal sah. Stage20 boleh dimulakan pada pusingan berikutnya.


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
