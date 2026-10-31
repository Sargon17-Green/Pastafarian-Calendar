# Stage41 / PATCH20 — pemetaan bebas indeks gerbang kepada hari

PROJECT_ID=PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31.
Status: CODE_PREPARED; Native PHP 8.3/64-bit dan semua CI Stage1–40 menunggu keputusan SHA baharu.

## Pendahulu: bukti sebenar Stage40
GitHub run 41183979338 completed/success, 11/11 jobs pada
5980c540a7d18f837e257d554ef19979aff73fcd. Job 124486999698 (PHP 8.3.36,
64-bit) menunjukkan controls=19 candidates=2 reproduced=2 rejected=0:
next_far oracle_index=14, returned_index=15, target=-15053458;
prev_far oracle_index=-12, returned_index=-13, target=-15057703.
Exit=0, stderr kosong, lint lulus, artifact 13036560944. Kedua-duanya
membuktikan PATCH19 menerima rekod salah apabila seam masih benar.

## Kontrak input dan syarat kepercayaan
API targetYearSequentialPatch20(calculationDay:int,targetDay:int,
year5000Anchor:array,nextYearProvider:callable,previousYearProvider:callable,
gateDayByIndexProvider:callable,int maxSteps=2048).
Rekod Year5000 dan pembekal tahun berturutan mesti benar, seperti PATCH18/19.
Pemetaan gateDayByIndexProvider(int index):int MESTI berasal daripada kaedah
pengiraan gerbang bebas yang dipercayai, bukan membaca open/closeGateDay
daripada rekod tahun yang sama. Jika pembekal pemetaan tidak disediakan,
PATCH20 gagal tertutup. Integrasi pengiraan gerbang produksi yang lengkap
masih kerja lapisan berikutnya; PATCH20 tidak mendakwa membuatnya sendiri.
Oracle ujian boleh digunakan dalam tests/ SAHAJA.

## Semantik dan pengesahan
Untuk setiap rekod (anchor dan setiap candidate), validasi medan indeks dan
hari ialah int, open index < close index dan open day < close day, kemudian
bandingkan:
gateDayByIndex(openGateIndex) == openGateDay
gateDayByIndex(closeGateIndex) == closeGateDay.
Jika salah, RuntimeException; tiada silent correction. Semua sambungan indeks
seam ialah PATCH19, dan sempadan hari/tahun/bajet/legacy ialah PATCH18.
Tujuh target benar merentas 4999/5000/5001 mesti memadankan output PATCH19;
dua witness Stage40 masih diterima oleh PATCH19 sebagai bukti arkib tetapi
mesti ditolak oleh PATCH20. Sebelas kes penolakan tambahan: dua witness,
dua seam, dua anchor corrupt, mapping salah, mapping bukan integer,
tiga medan indeks hilang. Input tidak diubah.

## Penerimaan
Native PHP 8.3 (PHP_INT_SIZE=8), lint bagi kelas/kernela/bootstrap/tests,
stdout ringkasan counts, stderr kosong, exit=0, bukti SHA dan artifact.
CI Stage1–40, verify dan Stage41 mesti success pada SHA identik.
No main/merge, no test oracle imported into production.
