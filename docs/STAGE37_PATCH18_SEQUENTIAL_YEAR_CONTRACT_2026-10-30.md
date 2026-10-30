# Stage 37 — PATCH 18: perjalanan tahun berurutan

Projek: PC-BRANCH-PHP-MALAY. Tarikh: 2026-10-30.
Asas yang disahkan: HEAD 7031763e0e60f355a41ff579fece70fb4512ca42,
Stage36 DISCOVERY18 selesai: Native 7/7 success pada SHA kod 4ff5c5d4
dan Native 7/7 success pada HEAD dokumentasi 7031763e.

## Kontrak semantik dan sempadan
- Kekalkan LegacyYearJumpGuess18 dan YEAR_JUMP_365_LEGACY tanpa sebarang perubahan. Jalur PATCH18 mesti benar-benar memanggil laluan Legacy Stage36 dahulu, menyimpan laporan asal, tetapi tidak menggunakan nombor tekaan /365 untuk mencari tahun.
- Input: calculationDay:int, targetDay:int, rekod Year5000 yang sah (number=5000; open/close serta indeks gerbang jika diberikan), dua operasi adjacent-year yang sebenar nextYear/previousYear, dan had langkah. Pembina Year5000 / gerbang sepenuhnya **belum** diimplementasi dalam produksi; adapter ini memerlukan pembekal tahun sah daripada pemanggil dan tidak boleh mendakwa mengeluarkan tarikh lima komponen secara lengkap.
- Selang tahun (openGateDay, closeGateDay], panjang 252..5778 hari. Jika target > close, minta tepat satu tahun berikutnya (number + 1; next.open=old.close). Jika target <= open, minta tepat satu tahun terdahulu (number - 1; previous.close=old.open). Tidak lompat menggunakan /365. Ulang sehingga target berada dalam selang; tiap langkah memerlukan semakan.
- Fail dengan jelas pada rekod/callback tidak sah, sela tidak bersambung, nombor tahun salah, overflows atau langkah melebihi bajet. Tidak bergantung pada metrik, cache merentas panggilan atau Oracle test di src/.
- Output: targetYearCandidate yang dipilih, raw legacyReport yang tidak berubah, bilangan langkah, arah, usedLegacyOutput=false. Konteks BootstrapKernel milik satu panggilan melalui TARGET_YEAR_PATCH_18.
- Kekalkan Stage36 deliberate historical EXPECTED_RED pada old route, Stage35 PATCH17, katalog, fixture, main dan semua regresi. Ujian Stage37 mestilah GREEN dengan anchor/year-sequences yang dikira oleh Oracle test-only, termasuk dua sejarah RED /365, target sempadan, satu langkah ke depan dan belakang, validasi input, ketidakmutasian, tanpa import Oracle ke production.
- Gerbang penerimaan: PHP lint, unit Stage37, all previous Stage1–36 verifier, frozen source-names verify, Native PHP 8.3 Actions pada SHA yang sama dan log/artifact. Jangan tanda Stage37 PASS sehingga semua selesai. Tindakan ini tidak merge ke main.
