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

**Status sebelum CI:** bukti akan direkod selepas commit dan tindakan GitHub selesai.
