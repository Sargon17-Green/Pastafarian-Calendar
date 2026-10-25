# Stage 32 — DISCOVERY 16

**Cabang:** PHP+Bahasa-Melayu.
**Asas:** Stage31 PATCH15 GREEN pada SHA `405c4f94eb7a774c9a1fd757b2045624920bffe9`; Native CI `40125767529`, dua pekerjaan SUCCESS.

## Parut sejarah

`LegacyMissingFourthDigit16` menerima pilihan `M³<n<=M⁴` dan memproses tiga digit SAVE pada berat 1, M dan M². Digit keempat yang sepatutnya mempunyai berat M³ ditinggalkan. Cutoff serta domain rejection tetap dihitung dengan M⁴. `BootstrapKernel::legacyChooseQuadRank` memanggil Legacy melalui `MISSING_FOURTH_DIGIT_LEGACY`, `askBowl` PATCH12 dan konteks tersendiri.

## Kriteria EXPECTED_RED

- Empat saksi tanpa rejection: `n=M⁴`, beza tepat `(digit4-1)*M³`.
- 56 kes matriks, tepat 52 mismatch, empat yang sepadan; empat nilai ruang dan dua arah, tiada penolakan astronomi.
- Tiga pertanyaan Native dan lima input tidak sah.
- Skrip `tests/stage32_discovery16_tests.php`: exit 1 disengajakan. Pembalut `tests/verify_stage32_discovery16.php`: exit 0 jika dan hanya jika RED tepat.
- Stage1–31, lint, fixture deterministik dan canonical names lock semua PASS pada HEAD baharu.

**Status:** AWAITING_CI. Jangan mulakan PATCH16 / Stage33, jangan ubah main.

## Native CI VERIFIED

Stage32 EXPECTED_RED disahkan pada SHA `748966fd7d2030c1199b30c1127508ee40ab10df` (run `40169711719`, 3/3 pekerjaan SUCCESS); Stage33 PATCH16 dibenarkan dan parut Stage32 kekal wajib.
