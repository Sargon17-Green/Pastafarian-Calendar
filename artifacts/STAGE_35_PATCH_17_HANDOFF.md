# Stage 35 — PATCH17 — Serahan

**Cabang:** `PHP+Bahasa-Melayu`.
**Asas:** Stage34 DISCOVERY17 `EXPECTED_RED` pada SHA `c9ff4ec6ecdf73b5a11fcc38060fbd84f32ab9f2`, run `40234787662`, 5/5 Native SUCCESS.

## Pembaikan dan penghala

`FifthDigitPatch17` memanggil `LegacyMissingFifthDigit17` sebenar dan membina lima digit SAVE dengan pemberat 1, M, M², M³, M⁴ dalam domain M⁵. Cutoff dan rejection pada `M⁵` untuk ruang `M⁴<n<=M⁵`. `BootstrapKernel::chooseQuintRank` memanggil `FIFTH_DIGIT_PATCH_17` dengan konteks sendiri; laluan Legacy salah tidak diubah.

## Gerbang GREEN

- Stage34 wrapper tetap exit 0 hanya jika empat RED sejarah (saksi menurun first=6), 56 matriks dengan 52 salah, tiga real dan lima invalid.
- Stage35: 400 kes sintetik terhadap oracle, 392 parut Legacy dan lapan padanan, empat saksi Stage34, 18 real melalui dua kernel, enam invalid, pemeriksaan tiada oracle produksi.
- Semua ujian Stage1–34, fixture, syntax PHP dan Canonical Names Lock PASS.
- Enam pekerjaan Native CI SUCCESS pada SHA tepat: `verify`, audit awal, audit 24–32, Stage33, Stage34 dan Stage35.

**Status:** GREEN disahkan selepas Native CI run `40404749682` selesai `SUCCESS` dengan 6/6 pekerjaan pada HEAD `0d16b132015b04406792964e7bab68ab179b38c9` (2026-10-26). Wrapper Stage34 tetap `EXPECTED_RED` dan tidak bermakna Legacy dibaiki. Stage36 belum dimulakan kerana kontrak/pelan Stage36 yang sah belum disahkan; `main` tidak diubah.

## Bukti regresi tambahan — 2026-10-27

Nota ini menambah sejarah di atas, **bukan** menggantikan pengesahan pada SHA lama `0d16b132015b04406792964e7bab68ab179b38c9`.

- Commit `751eaf47d1099a4fc465cad0d5142d72661c02da` menambah perlindungan regresi terhadap **dua langkah penolakan berturut-turut** dalam `tests/stage35_patch17_tests.php`: `REJECTION_TWO_STEP_CUTOFF` dan `REJECTION_TWO_STEP`.
- Native CI run [40494774367](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40494774367) disahkan `completed/success` untuk **6/6** jobs pada commit tersebut. Job [122157329954](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40494774367/job/122157329954) menjalankan `php -d memory_limit=512M tests/stage35_patch17_tests.php` dan melaporkan `LULUS Stage35 PATCH17 matrix=400 parut=392 sepadan=8 saksi=4 real=18 invalid=6`.
- Fail sumber bukti: [stage35_patch17_tests.php pada commit 751eaf47](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/751eaf47d1099a4fc465cad0d5142d72661c02da/tests/stage35_patch17_tests.php).
- Skop pengesahan ialah **Stage35 PATCH17 pada SHA 751eaf47**, bukan keseluruhan projek atau commit dokumentasi kemudian. Laluan Legacy dan `main` tidak diubah oleh pembaikan regresi ini.
- **Stage36 tidak dibenarkan** sehingga kebenaran pengguna yang jelas serta pelan Stage36 yang disahkan tersedia. Jangan jalankan semula CI sejarah hanya untuk menyemak bukti yang telah selesai.
