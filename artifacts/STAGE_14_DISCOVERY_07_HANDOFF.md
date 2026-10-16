# Serahan Stage 14 — DISCOVERY 07

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `02e266ea7240f4edbf326411f7476c1eb10f1287`  
**Tahap:** `14/55` — `DISCOVERY 07`; keadaan `EXPECTED_RED`.

## Punca kerosakan sejarah

Sebelas baris pengisaran disimpan pada indeks `0..10`, tetapi pembaca `LegacyVisibleGrind::legacyRowAt(g)` digunakan bagi pengisaran `1..11`. Kerosakan bererti baris kedua digunakan untuk pengisaran pertama, baris kesebelas untuk pengisaran kesepuluh, dan fallback baris pertama untuk pengisaran terakhir. Semua rumus penyimpanan, SAVE dan akses prior lain kekal dipanggil secara sebenar.

`BootstrapKernel::visibleDrops(c,t)` kini menjanakan 46 titisan melalui penghala sejarah `VISIBLE_GRIND_LEGACY` dan satu konteks bagi setiap panggilan. Pengiraan menggunakan pembetul tersembunyi PATCH05, pembaca prior PATCH06 dan jadual batu PATCH04. Tiada oracle dalam laluan produksi.

## Gerbang ujian

```text
php -d memory_limit=512M tests/stage14_discovery07_tests.php
php -d memory_limit=512M tests/verify_stage14_discovery07.php
```

Ujian sejarah terus mesti keluar kod 1 dengan `divergence=138 kes=3 julat=138 lain=0`, tanpa ralat tidak dijangka. Pengesah mesti keluar kod 0. Semua ujian Stage01–Stage13, kunci nama, fixture dan PHP syntax mesti hijau. Run 38915860291 telah mengesahkan EXPECTED_RED yang tepat; boleh memulakan Stage15 pada pusingan seterusnya.

## Larangan tampalan awal

Jangan tambahkan baris sentinel yang membetulkan jadual pada Stage14; ia diperkenalkan hanya pada Stage15 — PATCH07. Jangan hapuskan pembaca legacy atau alihkan peraturan indeks. Jangan mulakan Stage16 atau sebarang peringkat kemudian. Jangan kemas kini `main`, oracle, nama bahasa dan fixture.

**Commit:** `stage14(php-ms): dedahkan indeks grind sejarah tersasar satu baris`


### Keputusan GitHub Actions yang disahkan

**Run:** `38915860291`  
**Commit diuji:** `324b0e90ed6e923c08ebc3b19aadf1ec1aad8d8e`  
**Kerja:** `verify=success`, `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
LULUS Stage 13 PATCH 06 positif=762 hidden=66 oracle_hidden=42 sintetik=2688 ralat=7
KEPUTUSAN MERAH_DIJANGKA divergence=138 kes=3 julat=138 lain=0
LULUS kontrak merah 07; indeks grind legacy salah, sentinel belum ditambah
```

Keadaan `EXPECTED_RED` adalah benar-benar terbukti: hanya ujian sejarah langsung keluar dengan kod 1; pembalut khas keluar dengan kod 0. Tiada ralat luar jangka dan semua ujian Stage 1–13 termasuk kunci nama serta fixture telah lulus. Stage15 — PATCH07 belum dimulakan.
