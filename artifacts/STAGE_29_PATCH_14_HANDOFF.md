# Serahan Stage 29 — PATCH 14

Cabang: `PHP+Bahasa-Melayu`.
Asas: Stage28 EXPECTED_RED disahkan, `7814d28ca9f9f489aa6ce3210a955e48a0c52477`; Native run `39981352293` SUCCESS 2/2.

## Pembaikan tepat

`BigEndianDigitsPatch14::choosePatched` memanggil legacy sebenar untuk bukti sejarah dan pengesahan, lalu membentuk bilangan dua digit dengan nilai sampel pertama berat 1 dan kedua berat M. Kedua-dua digit berasal daripada SAVE yang sah. Had penerimaan dan rank menggunakan domain `M*M`, tepat seperti oracle. Skop `M<n<=M*M` sahaja.

## Syarat GREEN

- Semua empat saksi sejarah Stage28 (n=M+1), serta ujian RED langsung Stage28, kekal tepat.
- `tests/stage29_patch14_tests.php`: 4 saksi, 720 perbandingan matriks terhadap oracle, 18 panggilan produksi daripada tiga pasangan hari, enam input salah, bukti laluan legacy tidak diubah dan tiada oracle produksi.
- Semua ujian Stage1–28, PHP lint, fixture deterministik dan canonical names lock lulus di Native CI terhadap SHA tepat.
- Tiada perubahan `main`, katalog, fixture, fail `LegacyBigEndianDigits14.php` atau algoritma normatif. Stage30 belum dimulakan.

**Status:** AWAITING_CI, bukan GREEN sehingga Native CI lengkap.
