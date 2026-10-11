# Audit pembahagian tepat — garis PHP + Bahasa Melayu

Tarikh: 2026-10-11. Cabang: `PHP+Bahasa-Melayu`.

## Asal dan skop

Asas yang diperiksa: `5fc6bd76ba7823986a9876ea70a59710067ead2f`. Stage 1 sudah lengkap sebelum audit ini; pembetulan tidak memulakan Stage 2 dan tidak memasukkan mana-mana tampalan kecacatan legacy.

## Penemuan yang disahkan dalam sumber

1. Sebelum pembetulan, `divMod(-5, -3)` memberi pasangan (2, 1), tetapi `mod(-5, -3)` memberi -1 kerana penukaran tanda tambahan; pasangan akhir tidak memenuhi identiti pembahagian yang sama.
2. Sebelum pembetulan, `floorDiv(5, -3)` memberi -1 walaupun nilai lantai matematik ialah -2.
3. `modSmall` membenarkan pembahagi sehingga `PHP_INT_MAX`; pengiraan `remainder * 1000000000` boleh melimpahi integer asli sebelum modulo dilakukan.

## Pembaikan

- `divMod` menggunakan kuotien lantai dan baki dengan tanda pembahagi untuk semua kombinasi tanda.
- `mod` menggunakan terus baki daripada `divMod`.
- `modSmall` mengalihkan pembahagi `>= 1000000000` kepada pembahagian `BigInt` penuh.
- Regresi menyemak `a=b*q+r`, `|r|<|b|`, tanda baki, `floorDiv`, `mod`, nilai diketahui untuk integer kecil, pembahagian lebih 256-bit, dan sempadan 64-bit.

## Bukti pemeriksaan GitHub Actions

- Workflow: `Canonical Names Lock` (kerja `verify` dan `audit_php_bahasa_melayu`).
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151727484
- Hasil: kedua-dua kerja **success**.
- Sintaks PHP: **success**.
- Ujian Stage 1 asal (15 ujian): **success**.
- Regresi pembahagian (1,014 kes serta lapan semakan tambahan): **success**.
- Penjanaan semula fixture dan `git diff --exit-code`: **success**.
- Tiada fail dalam `main` dikemaskini.

## Sempadan langkah berikut

`LAST_COMPLETED_STAGE=1` masih tepat. Sebelum mengisytiharkan Stage 2 lengkap, ikuti kontrak kecacatan legacy bagi Stage 2 dan jalankan ujian khusus Stage 2; jangan menganggap penambahbaikan aritmetik ini sebagai pengganti kepada Stage 2.
