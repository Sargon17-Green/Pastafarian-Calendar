# Serahan Stage 28 — DISCOVERY 14

Cabang: `PHP+Bahasa-Melayu`.
Asas disahkan: Stage27 GREEN, `21288f66b97a713ed99b5513f0017c20f1ef82cf`; run `39945378948`, kedua-dua tugas SUCCESS.
Status: `AWAITING_CI`, sasaran `EXPECTED_RED` selepas Native CI sahaja.

## Parut

Untuk `M<n<=M*M`, dua sampel SAVE membentuk bilangan lebar. Kedudukan yang benar ialah digit awal di berat 1 dan digit kedua berat M. `LegacyBigEndianDigits14` salah membalikkan kedua-dua berat tetapi mengekalkan cara pengiraan cutoff dan rejection bagi nilai lebar. Ia menggunakan `SavePatch01` sebenar; penghala `BIG_ENDIAN_DIGITS_LEGACY` memanggil `BootstrapKernel::askBowl` PATCH12 dalam konteks per-panggilan.

## Bukti dan gerbang

- `tests/stage28_discovery14_tests.php`: exit 1 kerana tepat empat saksi salah pada n=M+1, termasuk lilitan M-ke-1; matriks 48 permulaan/arah/ruang, sekurang-kurangnya 40 penyimpangan, tiga pasangan hari sebenar dan lima kes input salah.
- `tests/verify_stage28_discovery14.php`: exit 0 hanya jika salah tepat dan tiada ralat tidak diduga.
- Semua Stage1–27 lulus, lint PHP, fixture tidak berubah, kunci nama kanonik tetap utuh. Tiada oracle dalam src.
- Jangan tambah PATCH14, jangan mulakan Stage29, jangan ubah main, katalog, fixture atau kod legacy sedia ada.

**Status**: AWAITING_CI sehingga Native GitHub Actions pada HEAD tepat diterima.
