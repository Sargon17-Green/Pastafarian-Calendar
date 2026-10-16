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

**Status selepas CI:** penemuan Stage 12 diterima sebagai EXPECTED_RED yang terkawal. Stage 13 boleh dimulakan pada pusingan berikutnya.

## Penerimaan CI sebenar

**Run:** `38894141862`; **SHA:** `255fc02e37a8071bc7ab98948a91df4abcef1c34`.

**Keputusan:** `verify=success`, `audit_php_bahasa_melayu=success`. Log PHP membuktikan:

```text
KEPUTUSAN MERAH_DIJANGKA missing=44 found=508 hidden=28 lain=0
LULUS kontrak merah 06; prior legacy buta terhadap hidden
```

Semua langkah Stage 1–11 lulus, termasuk `LULUS Stage 11 PATCH 05 pasangan=37 komponen=259 parut=222 sepadan_legacy=37 slot_sintetik=896 ralat=5`. Oleh itu `EXPECTED_RED` adalah merah yang disengajakan dan disahkan, bukannya kegagalan CI. Stage 13 belum dimulakan.
