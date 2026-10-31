# Stage40/DISCOVERY20 — calon herotan indeks hujung jauh

PROJECT_ID=PC-BRANCH-PHP-MALAY | 2026-10-31 | Status: HYPOTHESIS_AWAITING_NATIVE.

Asas: Stage39/PATCH19 lulus 10/10 jobs pada 747430578e99c13a7984f5b2cebf275a553d9828. Ia
memeriksa next.openGateIndex === old.closeGateIndex dan
previous.closeGateIndex === old.openGateIndex. Hipotesis berbeza
daripada Stage38: rekod jiran boleh mempunyai indeks hujung jauh
yang salah walaupun seam, hari gerbang dan nombor tahun benar.

Input: c=NormativeMath::FOUNDATION_DAY, anchor verified Year5000
daripada test-only NormativeOracle; next/previous tahun benar 5001/4999,
target next=anchor.closeGateDay+1, previous=anchor.openGateDay, budget=4.
Oracle bebas: NormativeOracle::year5000/nextYear/previousYear di tests/
sahaja; tiada salinan kod PATCH19. Saksi pertama: ubah HANYA
next.closeGateIndex sebanyak +1; saksi kedua: ubah HANYA
previous.openGateIndex sebanyak -1. Anchor tidak disentuh.
Semua hari, nombor dan indeks sambungan dikekalkan; rekod benar
daripada Oracle disimpan berasingan sebagai pembanding.

Output: CANDIDATE_REPRODUCED/NOT_REPRODUCED/REJECTED setiap saksi,
ringkasan controls=N candidates=2 reproduced=N rejected=N.
Expected-red hanya sah selepas PHP Native 8.3/64-bit membuktikan
kedua-dua saksi diterima oleh TARGET_YEAR_PATCH_19 sebagai
targetYearCandidate dan indeks itu berbeza daripada Oracle, rejected=0.
Jika tidak, penyiasatan berterusan dan hipotesis ditolak/disemak.
Kawalan: 4999/5000/5001, seam sebenar, hari sebenar, 2 target
benar, steps=1, legacy output bukan keputusan, input immutable,
tiada Oracle dalam production patch, lint PHP.
Native timeout 900s, memory 512M, stdout/stderr/exit/SHA/artifact;
semua regresi Stage1–39 dan verify success pada SHA sama.
Jangan gunakan bukti statik sebagai Native PASS. Tiada merge/main.
Jika terbukti, Stage41 memerlukan pemetaan indeks-hari independen
yang sah dan tersedia untuk produksi, bukan import Oracle tests/.
