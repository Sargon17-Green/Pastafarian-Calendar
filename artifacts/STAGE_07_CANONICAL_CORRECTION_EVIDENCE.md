# Pembetulan kontrak sejarah Stage 6–7 — PHP + Bahasa Melayu

**Jenis:** finding konkrit dan pembetulan pada peringkat sedia ada; **bukan Stage 8 atau Stage 9**.
**Cabang sasaran:** `PHP+Bahasa-Melayu` sahaja.
**Titik asas yang perlu diperiksa:** `7ad85d922f3af053a43fa413fa1a63a4e0422165` (Stage 7, CI asal hijau, tetapi bukan bukti kesetiaan bentuk sejarah).
**Keadaan yang dikehendaki selepas pembetulan:** Stage 7, `GREEN` — jangan menaikkan `LAST_COMPLETED_STAGE`.

## Penemuan kontrak

Rujukan terbenam yang mengikat menyatakan bagi PATCH 03:

```
oldDistance(c,t) = abs(dayTag(c) - dayTag(t))
chronological = abs(t - c)
if legacy != chronological:
    legacy = chronological
distance = legacy + 1
```

Namun kod Stage 6 yang pernah disimpan mengira `oldDistance(c,t) = abs(t-c)`; adapter Stage 7 menambah satu terus tanpa syarat perbandingan. Oleh itu **hasil pengeluaran betul tetapi parut sejarah salah**. Ini ialah finding konkrit untuk membuka kembali bahagian terhad yang terjejas, bukan alasan menulis semula sejarah Git.

## Kandungan pembetulan

| Laluan | Tindakan |
|---|---|
| `src/Legacy/LegacyDistance.php` | Ganti dengan legacy jarak antara hasil `dayTagWithFoundationScar` bagi kedua-dua hari. Ia tetap sengaja tidak normatif. |
| `src/Patches/DistanceCountPatch03.php` | Baca legacy, banding dengan jarak kronologi menggunakan BigInt, gantikan nilai legacy hanya jika berbeza, kemudian tambah satu. |
| `tests/stage06_discovery03_tests.php` | Buktikan penyimpangan dan padanan sejarah secara tepat, termasuk kes ekstrem. |
| `tests/verify_stage06_discovery03.php` | Kunci corak bukti merah yang betul serta syarat cabang pembetulan pengeluaran. |
| `tests/stage07_patch03_tests.php` | Buktikan kesetaraan 16,668 pasangan, pemanggilan adapter, parut tag, kedua-dua cabang, simetri, anjakan dan sempadan int. |
| `artifacts/STAGE_07_CANONICAL_CORRECTION_EVIDENCE.md` | Catatan finding, bukti, dan penerimaan. |

Semua fail di atas adalah fail sumber penuh di laluan repo mereka yang tepat. Tidak ada fail `HANDOFF_*` peribadi atau skrip memuat naik secara automatik. Tidak ada perubahan pada `main`, `SourceLanguageCatalog`, oracle, atau `LegacyDayTag`.

## Bukti PHP terasing, bukan bukti CI sebenar

Pemeriksaan sintaks PHP terhadap lima fail kelas/ujian baharu: `PASS`.
Pemeriksaan aritmetik kes 136 selamat dengan PHP sahaja: 126 penyimpangan sejarah dan 10 padanan; bagi lapan kes ekstrem: empat penyimpangan dan empat padanan. Jumlah kes Stage 6:

```
KEPUTUSAN MERAH_DIJANGKA perbezaan=130 sepadan=14 lencongan=124 tepi=8 lain=0
LULUS bukti sejarah tag dan lencongan PATCH 03, 130 merah dijangka
```

Ujian Stage 7 telah dilaksanakan dalam persekitaran QA **terasing** menggunakan salinan kelas pembetulan, pembungkus konteks dan BigInt PHP ketepatan sewenang-wenangnya yang disusun semula untuk audit ini. Hasil:

```
LULUS Stage 7 PATCH 03 kes=16668 oracle=16656 tepi=12 simetri=16668 anjakan=1285 lencongan=16450 sepadan_legacy=218
```

Ini tidak membuktikan ujian checkout sebenar, fixture penuh atau CI GitHub. Bukti penuh masih memerlukan ujian terhadap cabang pengguna selepas pemasangan oleh pengguna.

## Urutan sah bagi pengguna

1. Jangan muat naik atau pasang pakej Stage 8 `v001` yang terdahulu; ia diasaskan pada hash fail ujian Stage 7 sebelum pembetulan dan dengan betul dijangka menolak versi baharu.
2. Pastikan checkout cabang `PHP+Bahasa-Melayu` berpunca daripada commit Stage 7 yang dinyatakan dan belum diselitkan Stage 8. Jika Stage 8 sudah dipasang, jangan tindih secara membuta tuli: perlu menyelaraskan delta Stage 8 dahulu.
3. Gantikan hanya lima fail `.php` yang disenaraikan serta tambah dokumen bukti ini. Simpan fail lain tanpa perubahan.
4. Jalankan semua ujian CI sedia ada, khususnya:

```
php -d memory_limit=512M tests/verify_stage02_discovery01.php
php -d memory_limit=512M tests/stage03_patch01_tests.php
php -d memory_limit=512M tests/verify_stage04_discovery02.php
php -d memory_limit=512M tests/stage05_patch02_tests.php
php -d memory_limit=512M tests/verify_stage06_discovery03.php
php -d memory_limit=512M tests/stage07_patch03_tests.php
```

Jalankan juga Stage 1, regresi BigInt, semakan sintaks seluruh `src/` dan `tests/`, serta penjanaan fixture tanpa diff. Hanya selepas semua PASS boleh menandai titik Stage 7 diperbetulkan sebagai disahkan dan menyusun semula pakej Stage 8 berasaskan fail baharu.

## Tajuk commit disyorkan

`audit(php-ms): pulihkan parut jarak tag dan lencongan bersyarat PATCH 03`

## Badan commit disyorkan

`Betulkan ketidakpatuhan bentuk sejarah yang ditemui terhadap kontrak terbenam. LegacyDistance kini mengekalkan jarak antara tag hari yang salah, bukan jarak kronologi. Adapter PATCH 03 menguji ketakpadanan, melencong ke jarak kronologi yang tepat jika perlu, dan menambah satu. Kemas kini ujian Stage 6 kepada 130 penyimpangan dan 14 padanan yang dijangka, serta ujian Stage 7 bagi kedua-dua cabang dan had integer. Tiada langkah baharu, tiada ubah oracle, dan tiada kod Stage 8/9 dimasukkan.`
