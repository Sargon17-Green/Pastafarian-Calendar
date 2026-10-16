# Serahan Stage 12 — DISCOVERY 06

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `3f2a29cbacba42042ea867c4a8cc1cf939c86476`  
**Sasaran:** `EXPECTED_RED`

## Cacat sejarah

`LegacyVisiblePrior::legacyPrior(dropStore,i,back)` hanya membaca slot `i-back` daripada stor titisan terlihat. Apabila `i-back <= 0`, slot tersembunyi tidak boleh dicapai dan bacaan memulangkan `null`. Fungsi legacy tidak diubah menjadi pembetul; penyelesaian `priorPatch` dikhaskan untuk Stage 13.

## Penghala

`BootstrapKernel::priorLegacy` meneruskan stor salinan dan indeks melalui `VISIBLE_PRIOR_LEGACY`. Status dan metrik tidak mengubah keputusan. Ujian menggunakan fixture terlihat sintetik kerana penjanaan 46 titisan terlihat belum dibuat; nilai hidden sebenar disemak secara bebas dengan oracle PHP tempatan.

## Ujian yang perlu diluluskan

```text
php -d memory_limit=512M tests/stage12_discovery06_tests.php
php -d memory_limit=512M tests/verify_stage12_discovery06.php
```

Ujian langsung patut keluar kod 1 dengan 44 slot negatif atau sifar, 508 slot terlihat yang betul, 28 padanan hidden dan tiada ralat lain. Pengesah patut keluar kod 0. Semua regresi Stage 1–11 mesti kekal hijau.

**Status sebelum CI:** kod disediakan, pengesahan penuh belum dilakukan. Jangan mulakan Stage 13 sebelum bukti penerimaan Stage12 tersedia.