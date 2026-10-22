# Serahan Stage 22 — DISCOVERY 11

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `223ac21ea1c5a32a4e1d111f025638553727dfc5`  
**Tahap:** 22/55 — DISCOVERY 11; `EXPECTED_RED` tertakluk kepada CI.

## Punca sejarah

`LegacyOverwrittenOrder11::sauceWrong` mengira 46 titisan, 46 kali pengadunan mangkuk dengan snapshot, dan 12 kacauan akhir. Sementara nilai enam mangkuk tetap tepat, `order` pada titisan ke-46 tidak disalin ke latch; setiap post-stir menimpa `order` yang sama. Hasil `orderAtDrop46` menjadi susunan post-stir ke-12.

## Laluan produksi dan sempadan

`BootstrapKernel::legacySauceOrder` membuka konteks dan menghala kepada `OVERWRITTEN_ORDER_46_LEGACY`. Kod masih bergantung pada pembetul sah Stage 1–21 untuk kiraan, SAVE, batu, hidden, visible, permutasi, tuangan dan shadow. Hanya pengendalian order terminal mengandungi cacat sejarah ini. Tiada oracle di direktori `src`.

**Jangan masukkan latch Stage23, jangan memulakan Stage24, jangan ubah `main`, jangan sentuh kata nama atau fixture.**

## Ujian penerimaan

```text
php -d memory_limit=512M tests/stage22_discovery11_tests.php
php -d memory_limit=512M tests/verify_stage22_discovery11.php
```

Ujian langsung mesti keluar 1 dengan tepat:

```text
KEPUTUSAN MERAH_DIJANGKA kes=3 susunan_salah=3 mangkuk_betul=18 kacau=36 lain=0
```

Pengesah mesti keluar 0 dan mencetak `LULUS kontrak merah 11`. Semua regresi Stage 1–21 serta keseluruhan CI yang tepat kepada HEAD baharu mesti lulus. Penemuan tidak boleh ditandatangani berdasarkan sintaks sahaja.

## Bukti

Belum tersedia sebelum GitHub Actions menjalankan SHA tahap ini.
