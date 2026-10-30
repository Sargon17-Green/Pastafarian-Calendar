# Stage 36 — DISCOVERY 18: teka tahun menggunakan pembahagi 365 (kontrak)

Tarikh: 2026-10-30. Projek: `PC-BRANCH-PHP-MALAY`, cabang: `PHP+Bahasa-Melayu`.  
Asas HEAD disahkan: `2324dc86d5fb222c582a95bbd5984bb129867a9d`, `LAST_COMPLETED_STAGE=35`.  
**Keputusan pengguna:** pembantu diberi kuasa menentukan skop Stage36 menurut jejak kanonik; tiada kelulusan peringkat seremonial diperlukan.

## Pemilihan dan asal-usul

Skop yang dipilih ialah **nombor tahun sasaran salah kerana heuristik panjang tahun tetap 365 hari**, sama seperti Stage36 / Discovery18 dalam `TypeScript+मराठी`, `C++&Latina` dan `MATLAB+Polski`. Kesalahan alih indeks bulan dalam Scala dan penolakan arah terbalik dalam C# merupakan percabangan bahasa/implementasi lain, bukan keperluan bersama pada PHP Stage36. Perkara ini ialah keputusan reka bentuk Stage36 yang kini dimuktamadkan, bukannya dakwaan bahawa semua bahasa mempunyai ciri Stage36 yang serupa.

Rujukan silang:
- `TypeScript+मराठी/SPAGHETTI_DEVELOPMENT_HISTORY.md`, perenggan Stage36/Stage37.
- `C++&Latina/SPAGHETTI_DEVELOPMENT_HISTORY.md`, perenggan Gradus 36/37.
- `MATLAB+Polski/SPAGHETTI_DEVELOPMENT_HISTORY.md`, perenggan Etap 36/37.
- Oracle ujian milik PHP sendiri: `tests/oracle/NormativeOracle.php` — `year5000()`, `findTargetYear()`, `nextYear()` dan `previousYear()`.

## Definisi tepat yang boleh diuji

Input Stage36 ialah `calculationDay:int`, `targetDay:int` dan **rekod Year5000 yang telah diketahui secara sah** (masih disalurkan secara eksplisit buat masa ini): `{number:5000, openGateDay:int, closeGateDay:int}`; selang keahlian ialah `(openGateDay, closeGateDay]`, panjang sah `252..5778`. Endpoint baharu tidak mendakwa sendiri membina Year5000 daripada semua lapisan tahun. Penyambungan kepada penjana Year5000 yang sebenar ialah kerja tersendiri yang memerlukan bukti, bukannya pembacaan Oracle dalam produksi.

Rumus Legacy sebenar:
```text
deltaDays = targetDay − anchor.openGateDay
offset365 = floorDivSigned(deltaDays, 365)
legacyGuessedYearNumber = 5000 + offset365
```
`floorDivSigned` matematik sebenar, **bukan** pembundaran ke sifar yang berlaku dalam sebahagian operasi integer; gunakan `Pastafari\Stage01\BigInt` sedia ada dan hasilkan integer PHP hanya selepas semakan julat. Logik salah ini sengaja mengabaikan panjang sebenar tahun, sempadan, pintu dan `nextYear()/previousYear()`.

API produksi:
- `src/Legacy/LegacyYearJumpGuess18.php`: `LegacyYearJumpGuess18::guess(array $anchor,int $targetDay): array`. Mesti mengembalikan `anchorNumber`, `anchorOpenGateDay`, `anchorCloseGateDay`, `targetDay`, `deltaDays`, `offset365`, `guessedYearNumber`, `usedLegacyOutput=true`, tanpa memutasi input.
- `BootstrapKernel::legacyGuessTargetYear365(int $calculationDay,int $targetDay,array $anchor): array`: konteks panggilan baharu, pemanggilan sebenar `BootstrapDispatcher` pada `YEAR_JUMP_365_LEGACY`, status `DISCOVERY18_LEGACY_RETURNED`, telemetry milik panggilan; **mengembalikan hasil Legacy yang salah** dalam Stage36. `main` tidak disentuh dan `calendarDate` penuh tidak diubah.

## Test dan gerbang

1. Bandingkan rekod Year5000 **sebenar** yang dikira oleh Oracle ujian PHP dengan Legacy. Saksi kawalan hari `open+1` sepadan pada tahun 5000; `open+365` dan `close` patut menghasilkan **tepat dua kegagalan sejarah yang disengajakan** selagi tahun Year5000 mempunyai panjang lebih 365.
2. Periksa `targetDay` sebelum `open`, negatif, pembahagian lantai, integer hujung, input rosak, peraturan `(open,close]`, perubahan konteks antara kernel yang berlainan dan pemeliharaan input.
3. Ujian terus `tests/stage36_discovery18_tests.php` mesti `exit 1` **hanya** untuk dua salah sejarah ini (semua assertions lain PASS); pembalut `tests/verify_stage36_discovery18.php` ialah gerbang CI `exit 0` hanya apabila keluar kod 1, stderr kosong, dua label EXPECTED_RED tepat serta meter/kesimpulan tepat. Jangan sengaja menganggap sebarang fail lain sebagai expected red.
4. GitHub Actions native PHP, lint, Stage1–35 regressions, dan frozen-names/verify pada **SHA sama**. Simpan stdout, stderr, exit dan SHA. Jangan anggap lint atau test lokal semata-mata sebagai CI PASS.
5. `CURRENT_STAGE=36`, `CURRENT_KIND=DISCOVERY`, `LAST_COMPLETED_STAGE=35` sehingga Native CI Stage36 selesai SUCCESS. Stage37 / PATCH18 sahaja boleh membetulkan pencarian tahun secara berurutan; kekalkan raw Legacy dan telemetry.
6. Oracle `NormativeOracle` dan `NormativeMath` hanya boleh digunakan di `tests/`. Kod `src/` tidak boleh mengimport kedua-duanya. Perubahan skop: tiada katalog, fixture, main, hakisan fail lama, Stage37 atau penghantaran hasil kalendar lima komponen.

Jika suite CI gagal, betulkan punca secara sempit dalam cabang ini dan ulang pengesahan. **Tiada soalan kebenaran tambahan kepada pengguna.**
