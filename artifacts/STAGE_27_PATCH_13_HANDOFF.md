# Serahan Stage 27 — PATCH 13

**Cabang**: PHP+Bahasa-Melayu.
**SHA asas**: 3a51e44e35f9692884d0a5050884b53d336d7aad.
**Stage26**: EXPECTED_RED disahkan oleh run 39931454215, kedua-dua kerja CI SUCCESS.

## Pembaikan

\`RejectionSamplingPatch13::choosePatched\` mesti memanggil \`LegacyNoRejection13::chooseWrong\` secara nyata untuk mengekalkan jejak serta semakan input. Selepas itu cutoff \`floor(M/n)*n\` memisahkan sampel sah daripada yang ditolak. Sampel melebihi cutoff melangkah ±1 dalam domain \`1..M\` melalui \`SavePatch01\` sehingga diterima. Nilai sah ditukar ke rank \`1..n\`. Domain stage ini ialah \`1<=n<=M\`; \`n>M\` tidak disokong dan tidak diubah secara senyap.

## Penerimaan

- \`verify_stage26_discovery13.php\` masih exit 0 hanya bagi empat parut RED tepat; legacy dan arkib sejarah tidak diubah.
- \`stage27_patch13_tests.php\` membandingkan >=1500 pertanyaan sintetik dengan oracle PHP setempat, menguji semua empat parut, sempadan L, M, 1, step ±1, kitaran, 18 pertanyaan Native sebenar, penolakan input dan pemilikan konteks.
- Semua Stage1–26, PHP lint, fixture deterministik, dan kunci nama kanonik mesti lulus Native GitHub Actions pada SHA tepat.
- Main, katalog, fixture dan \`LegacyNoRejection13.php\` tidak diubah; jangan mulakan Stage28 sehingga CI penuh GREEN.

**Status**: AWAITING_CI — bukan GREEN sebelum hasil Native disahkan.
