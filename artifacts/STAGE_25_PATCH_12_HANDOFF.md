# Serahan Stage 25 — PATCH 12

Cabang: `PHP+Bahasa-Melayu`. Asas: `13bd8c0cfc0fee4975dbefcf353ca4162c5b341a`.
Stage24 disahkan EXPECTED_RED oleh run 39840971619: verify dan audit_php_bahasa_melayu kedua-duanya SUCCESS.

## Pembaikan

`NextBowlOrderPatch12::askPatched` memanggil secara benar `LegacyNumericSuccessor12::askWrong`, mengekalkan kecacatan asal tanpa mengubahnya. Ia mencari ID yang ditanya dalam `orderAtDrop46` dan memilih ID seterusnya, termasuk lilitan. First dan step dihitung dengan formula SAVE yang sama menggunakan jiran sebenar. Dispatcher `ORDER_NEIGHBOR_PATCH_12` digunakan oleh `BootstrapKernel::askBowl`. Laluan `legacyAskBowl` kekal.

## Kriteria penerimaan

- `php -d memory_limit=512M tests/verify_stage24_discovery12.php`: exit 0, menerima RED sejarah tepat.
- `php -d memory_limit=512M tests/stage25_patch12_tests.php`: exit 0 dan perbandingan kesetaraan dengan oracle PHP bebas.
- 720 permutasi, 4,320 pertanyaan, 3,456 jiran legacy tersasar, 864 sepadan, 72 meterai tambahan, 18 pertanyaan sebenar, 4 input ditolak.
- Semua regresi Stage1–24, lint, penjanaan fixture tanpa diff, kunci nama 17+47 dan GitHub Actions terhadap SHA baharu mesti hijau.
- Tiada perubahan kepada `main`, legacy asal, katalog, fixture atau formula normatif. Tiada Stage26 sebelum CI Native PASS.

**Status:** AWAITING_CI — jangan laporkan GREEN sebelum menjalankan CI pada SHA tepat.
