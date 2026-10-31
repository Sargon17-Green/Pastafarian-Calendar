# Stage39 / PATCH19 — kesinambungan indeks gerbang tahun

Projek PC-BRANCH-PHP-MALAY | Cabang PHP+Bahasa-Melayu | 2026-10-31.
Status kod awal: menunggu pengesahan Native PHP 8.3 dan CI pada SHA commit baru.

## Bukti dan keperluan
Stage38 DISCOVERY19 di SHA 6a8090d9092adc88a075ace4620f4dba03cc5fe6
telah dibuktikan melalui run #41136362315: 9/9 SUCCESS, job
stage38-discovery19-probe #124339690590 (PHP 8.3.36 64-bit), 18 kawalan,
2/2 witness benar dan rejected=0, stderr kosong dan exit=0.
Witnes forward: oracle=4, callback=5. Witnes backward:
oracle=-4, callback=-5. Dua calon dijana dengan Oracle ujian yang sah
lalu indeks dikorupsi secara sengaja; bukan data Oracle palsu.

## Input/output
Input: calculationDay:int, targetDay:int, verified Year5000 anchor
(number=5000, open/close days dan open/close gate indices:int),
real next/previous year callbacks, maxSteps 0..100000.
Output sama dengan PATCH18: targetYearCandidate yang sah;
legacyReport daripada YEAR_JUMP_365_LEGACY, steps, direction,
usedLegacyOutput=false. Pintu tahun (openDay,closeDay].
Pembekal mesti pulangkan tahun sebenar; aplikasi tidak membina
Year5000 di sini. Jangan menyifatkan patch ini sebagai pengiraan
lima komponen yang lengkap.

## Invarian dan algoritma
Sebelum delegasi kepada PATCH18, validasi kedua-dua indeks anchor.
Bungkus pembekal next: mesti ada old.closeGateIndex:int,
candidate.openGateIndex:int, candidate.closeGateIndex:int dan
candidate.openGateIndex === old.closeGateIndex. Bagi previous:
mesti ada old.openGateIndex:int, candidate.openGateIndex:int,
candidate.closeGateIndex:int dan
candidate.closeGateIndex === old.openGateIndex. Reject tanpa
mengubah input, tanpa membetulkan senyap, tanpa mengguna Oracle
di src/. Semua pemeriksaan nombor tahun, had panjang tahun,
kebersambungan hari, overflow dan bajet kekal dalam PATCH18 yang
didelegasikan. Jika tiada langkah, anchor masih mesti berindeks.
Ini hanya mengesahkan *sambungan* indeks, bukan identiti dalaman
setiap rekod terhadap Oracle yang tidak wujud di sisi produksi.

## Oracle dan matriks penerimaan
Oracle test-only: NormativeOracle::year5000/nextYear/previousYear
untuk tiga tahun sebenar; tujuh hari sasaran meliputi stay,
forward dan backward, dua witness Stage38 lama mesti kekal
diterima oleh laluan PATCH18 tetapi ditolak oleh PATCH19.
Tambah ujian medan hilang, string index, bajet 0/-1, gate day gap,
serialization input immutable, kesetaraan laporan Legacy dan
laluan dispatcher sebenar. Sembilan expected rejection.
Gate: PHP lint, Stage39 unit Native PHP8.3 64-bit, stderr kosong,
exit 0, bilangan check/invalid/targets dan bukti SHA dalam artifact;
Stage1-38 termasuk probe Stage38 dan verify mesti lulus pada SHA
yang sama. Run queued/in_progress bukan PASS. Tiada merge/main,
tiada ubah legacy/PATCH18/fixtures/katalog.
