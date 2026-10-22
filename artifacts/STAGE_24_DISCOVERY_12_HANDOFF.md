# Serahan Stage 24 — DISCOVERY 12

Cabang: PHP+Bahasa-Melayu.
Asas disahkan: Stage23 GREEN; da93ec7b1dc7bae9146c4818f4182bff7cfc87e7; run 39818136362, kedua-dua kerja SUCCESS.
Status Stage24: AWAITING_CI (sasaran EXPECTED_RED); bukan PASS sebelum CI.

## Kerosakan sejarah

Permutasi titisan 46 dan enam mangkuk akhir sudah sah melalui PATCH11. Pertanyaan legacy LegacyNumericSuccessor12::askWrong tersalah memilih nextBowlId sebagai (queriedBowlId % 6)+1. Peraturan normatif memerlukan ID yang menyusul ID pertanyaan dalam permutasi orderAtDrop46, termasuk lilitan selepas posisi terakhir. Rumus first dan step selain jiran tetap benar menggunakan SAVE. BootstrapKernel::legacyAskBowl menghala ke NUMERIC_NEXT_BOWL_LEGACY dengan konteks baharu.

## Gerbang

php -d memory_limit=512M tests/stage24_discovery12_tests.php
php -d memory_limit=512M tests/verify_stage24_discovery12.php

Ujian langsung mesti keluar kod 1; daripada 720 permutasi × enam ID: 3456 jiran salah dan 864 jiran sama (setiap ID mempunyai lima kemungkinan jiran berlainan, satu padanan dalam lima). Tiga pasangan tarikh sebenar × enam ID dan tiga penolakan input juga diuji. Pengesah menerima hanya kegagalan merah terhad dengan exit 0, tanpa ralat lain. Keseluruhan Stage1–23, sintaks, fixture dan nama kanonik mesti hijau.

## Had

Jangan tambah NextBowlOrderPatch12, jangan baiki kod legacy ini pada Stage24, jangan mulakan Stage25 sebelum CI pada SHA tepat. Jangan ubah main, katalog atau fixture; jangan rujuk hasil implementasi lain. Oracle PHP tersendiri hanya dalam tests.
