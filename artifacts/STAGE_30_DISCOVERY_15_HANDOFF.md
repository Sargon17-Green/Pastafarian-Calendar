# Stage 30 — DISCOVERY 15: Native handoff

Cabang: \`PHP+Bahasa-Melayu\`.
Baseline: Stage29 PATCH14 GREEN pada \`aae1c106706bf571adbb94282f8a96e80698df91\`, run \`39985192899\`, kedua-dua job SUCCESS.

## Masalah yang sengaja dikekalkan

\`LegacyMissingThirdDigit15\` membaca dua digit \`first\`, \`SAVE(first+step)\` tetapi mengabaikan digit ketiga \`SAVE(first+2*step)\` di ruang pilihan \`M²<n<=M³\`. Cutoff tetap daripada M³. Kelas legacy sebelum ini dan PATCH14 tidak diubah. Dispatcher \`MISSING_THIRD_DIGIT_LEGACY\` memanggil PATCH12 sebenar, tanpa state semantik silang panggilan.

## Kriteria EXPECTED_RED

- Empat saksi \`n=M³\` dengan perbezaan tepat \`(digit3-1)*M²\` di mana tiada rejection.
- Matriks 40 pertanyaan untuk \`M²+1, M²+2, M³-1, M³\`: tepat 36 mismatch (selebihnya padan).
- Tiga laluan tarikh sebenar, lima penolakan input.
- \`stage30_discovery15_tests.php\` exit 1 sengaja, \`verify_stage30_discovery15.php\` exit 0 untuk bukti RED sahaja; tiada warning/ralat tidak dijangka.
- Semua Stage1–29, native PHP lint, fixture dan lock SHA256 mesti lulus pada SHA baharu.

**Status:** AWAITING_CI. Jangan tambah PATCH15, jangan buka Stage31, jangan ubah main.
