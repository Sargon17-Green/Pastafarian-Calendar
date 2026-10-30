# Stage38 / DISCOVERY19 — penyiasatan kesinambungan indeks gerbang

Projek: PC-BRANCH-PHP-MALAY
Cabang: PHP+Bahasa-Melayu
Asas semasa penyediaan: 6bab4ce8fb077768c6b987aa933086f8f42a85c5
Tarikh: 2026-10-31
Status: HIPOTESIS YANG WAJIB DIUJI; BUKAN EXPECTED_RED ATAU PASS SEBELUM LOG NATIVE DISAHKAN.
Pendahulu: Stage37/PATCH18 lengkap, run #41108531274 8/8 SUCCESS; run dokumentasi #41117526278 completed/success 8/8.

## Asal masalah dan pemisahan skop
Stage36/DISCOVERY18 mengesan tekaan tempoh tahun /365 yang salah; ini BUKAN pengulangan kes itu.
Stage37/PATCH18 menyemak sambungan hari (next.openGateDay = current.closeGateDay,
previous.closeGateDay = current.openGateDay) tetapi tidak menyemak indeks
openGateIndex/closeGateIndex apabila penyedia tahun membekalkannya.
Hipotesis: sebuah hasil penyedia yang salah indeks tetapi betul sempadan hari
boleh diterima dan dihantar semula, lalu merosakkan jejak kanonik bagi tahun selepasnya.
Ini ialah pemerhatian statik terhadap PATCH18 yang diwarisi, bukan bukti runtime lagi.
Tidak boleh mendakwa semua year-provider palsu sebagai tahun sah.

## Input, output dan oracle bebas
Input: calculationDay = NormativeMath::FOUNDATION_DAY; Oracle ujian PHP
menghasilkan Year5000 dan tahun sebenar bersebelahan (nextYear, previousYear);
target forward = anchor.closeGateDay+1, backward = anchor.openGateDay.
Dua rekod calon diuji: next.openGateIndex ditambah 1; previous.closeGateIndex
ditolak 1, tanpa mengubah openGateDay/closeGateDay, bilangan tahun atau panjangnya.
Kedua-duanya rosak secara sengaja — ia bukannya keluaran Oracle.
Oracle bebas: indeks pintu sambungan mesti sama tepat,
next.openGateIndex === anchor.closeGateIndex dan
previous.closeGateIndex === anchor.openGateIndex.
Pilihan tahun betul disahkan melalui hasil Oracle asli, bukan jangkaan hard-coded.

Output ujian: dua kawalan tahun benar, dua laporan calon, indeks sebenar dan
indeks rosak, rekod legacyReport yang masih dipelihara, bilangan witness yang
diterima/direjek, exit code, stderr, GITHUB_SHA. Tiada bacaan tests/oracle di src.

## Kriteria keputusan
1. Kawalan next dan previous mesti sepadan tahun sebenar daripada Oracle.
2. Dua calon rosak hanya menjadi witness selepas laluan produksi PHP sebenar
   mengembalikannya tanpa reject pada SHA yang sama, disahkan log completed.
3. Probe mencetak CANDIDATE_REPRODUCED jika diterima, CANDIDATE_REJECTED jika
   ditolak. Nama EXPECTED_RED hanya boleh diputuskan selepas baca bukti penuh.
4. Jika tiada dua witness, hipotesis tidak diterima; kaji sebab tanpa mencipta
   nilai expected-red. Jika berjaya, kekalkan reproducer dan buka hanya
   PATCH19 sempadan indeks pada Stage39 selepas penutupan Discovery19.
5. Semua ujian Stage1–37 mesti kekal. Bagi Stage38, tiada edit source,
   tiada merge ke main, tiada dakwaan algoritma lima komponen lengkap.
6. CI: PHP 8.3 64-bit, lint, probe bounded, stdout/stderr/exit/SHA artifact,
   beserta semua 8 jobs sedia ada dalam satu run. queued/in_progress
   bukan PASS atau halangan.

## Had penyiasatan
Tidak mengubah semantik pemilihan Oracle, generator Year5000, bilangan tahun,
susunan cutlet/bulan, atau cara tahun dinombor. Ia semakan integriti callback
Year5000 yang spesifik. Ini ialah kecacatan baharu yang disyaki pada laluan
PATCH18 yang sedia ada; status sebagai kecacatan sejarah memerlukan bukti,
bukannya tekaan bahawa laluan legacy sengaja menghasilkan indeks salah.
