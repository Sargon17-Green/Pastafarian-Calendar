# Serahan Stage 26 — DISCOVERY 13

**Cabang:** PHP+Bahasa-Melayu.
**Asas:** fd2f82a965d5f4c42e513409e1e8c7e656f39647.
**Stage25 PATCH12:** Native CI 39915193046 kedua-dua pekerjaan SUCCESS.
**Stage26:** AWAITING_CI; sasaran EXPECTED_RED sahaja.

## Punca sejarah

LegacyNoRejection13 memilih dengan (first-1) mod n + 1 tanpa ujian had L=floor(M/n)*n, sedangkan oracle rejection sampling menolak first>L, membaca sampel berikut dalam aliran bertanda ±1 sehingga sah. Domain Stage26 ialah 1<=n<=M. Tidak ada PATCH13 lagi.

## Bukti terhad yang diwajibkan

- Ujian langsung stage26_discovery13_tests.php: exit 1, tepat empat kes salah pada n=3,10,97,720, semuanya first=L+1 dengan step=-1. Legacy rank 1, oracle rank n.
- 13 kawalan yang mesti benar, 3 laluan Native sebenar dari PATCH12, 4 input tidak sah yang ditolak.
- verify_stage26_discovery13.php: exit 0 hanya bila RED tepat, tanpa warning/ralat yang tidak dirancang.
- Semua Stage1–25 termasuk parut lama, lint, fixture dan kunci nama mesti lulus dalam GitHub Actions pada HEAD tepat.

**Sempadan:** tiada PATCH13, tiada Stage27, tiada perubahan main, tiada oracle produksi, tiada kod dari pelaksanaan lain.
