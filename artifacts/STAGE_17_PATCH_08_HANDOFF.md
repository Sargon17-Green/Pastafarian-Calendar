# Serahan Stage 17 — PATCH 08

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `a9d148915dd5b6cf182c1c17bff32696923956a1`  
**Tahap:** 17 daripada 55 — PATCH 08  
**Keadaan sasaran:** `GREEN`

## Kontrak pembetulan

`PermutationPatch08` masih memanggil `LegacyBowlPermutation::legacyBowlOrderFromDrop` dalam semua keadaan. Untuk rank1 1..719, panggilan itu memulangkan permutasi yang salah dan tidak digunakan sebagai jawapan. Pada rank1 720, `PERMUTATION_RANK_ZERO_RANGE` ditangkap hanya dalam keadaan yang tepat. Selepas jejak legacy sebenar itu, pembetul mengira `rank0 = rank1 - 1` dan meminta `LegacyPermutationUnrank0` menghasilkan jawapan sah. Kedua-dua fungsi legacy tidak diubah.

Penghala `BOWL_PERMUTATION_PATCH_08` dalam `BootstrapKernel::bowlOrder` ialah pintu produksi; `BOWL_PERMUTATION_LEGACY` dan `BootstrapKernel::legacyBowlOrder` kekal bagi ujian sejarah. Perkiraan SAVE, batu, hidden, prior, visible dan katalog nama tidak disentuh.

## Gerbang ujian

```text
php -d memory_limit=512M tests/verify_stage16_discovery08.php
php -d memory_limit=512M tests/stage17_patch08_tests.php
```

Pengesah sejarah Stage16 mesti pulang 0 setelah membuktikan tepat 719 hasil tersasar, satu pengecualian rank720, 720 pembaca sifar yang sah, dan 46 visible diperiksa. Stage17 mesti membuktikan 720 jawapan sah dan unik terhadap oracle PHP tempatan, 719 parut legacy dan satu pengecualian, 14 nilai BigInt/negatif, 138 jawapan daripada tiga contoh 46 titisan visible, serta determinisme panggilan dan instance. Semua gerbang CI Stage1–17, syntax, penguncian nama dan fixture wajib lulus.

## Had dan status

Jangan ubah `main`, jangan memadam legacy, jangan menyalin oracle ke produksi, jangan memulakan Stage18. Pemilihan/perubahan mangkuk sebenar tidak termasuk Stage17. **CI sebenar mesti diperiksa sebelum penerimaan.**

**Cadangan commit:** `stage17(php-ms): betulkan ordinal permutasi tanpa memadam sejarah`
