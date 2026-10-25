# Serahan Stage34 — DISCOVERY 17

**Cabang:** PHP+Bahasa-Melayu.
**Asas:** Stage33 PATCH16 GREEN, SHA `6ed4efbe2e60a3d910f9e6277a4dbe7494333fa9`, Native CI `40192008267`, 4/4 SUCCESS.

## Parut sejarah

`LegacyMissingFifthDigit17` memproses empat sampel SAVE, dengan berat 1,M,M²,M³; digit kelima yang sepatutnya berat M⁴ tidak dibaca untuk ruang `M⁴<n<=M⁵`. Domain dan cutoff masih M⁵. `BootstrapKernel::legacyChooseQuintRank` menggunakan dispatcher `MISSING_FIFTH_DIGIT_LEGACY`, `askBowl` PATCH12 dan konteks yang dimiliki panggilan itu sahaja. Semua kelas Legacy dan Patch lebih awal dikekalkan.

## Gerbang EXPECTED_RED

- Empat saksi `n=M⁵` tanpa rejection dengan perbezaan `(digit5-1)*M⁴`.
- 56 kes matriks, tepat 52 mismatch sejarah dan empat padanan; sifar rejection dalam semakan sempadan.
- Tiga jejak tarikh melalui penghala Native, lima input tidak sah.
- Ujian terus `tests/stage34_discovery17_tests.php` exit 1 yang disengajakan; pembalut `tests/verify_stage34_discovery17.php` exit 0 hanya apabila empat RED tepat dan tiada masalah lain.
- Semua Stage1–33, PHP lint, fixture, canonical names lock. Ujian Stage34 dalam pekerjaan CI khusus. Lima pekerjaan mesti SUCCESS terhadap HEAD yang sama.

**Status:** AWAITING_CI. Jangan buka Stage35/PATCH17 atau ubah `main`.
