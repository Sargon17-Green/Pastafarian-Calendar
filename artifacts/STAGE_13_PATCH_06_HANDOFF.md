# Serahan Stage 13 — PATCH 06

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `924f3db8ed139dcb8aad05c86920def78a98339c`  
**Tahap:** 13/55, PATCH 06, keadaan `GREEN` tertakluk kepada CI.

## Mekanisme yang diwajibkan

Pembetul `PriorAccessPatch06::priorPatch` menilai slot `i-back`. Jika slot positif, panggilan benar-benar melalui `LegacyVisiblePrior::legacyPrior` yang tidak diubah. Jika slot tidak positif, `k=1-slot` dibaca dengan `HiddenNearnessPatch05::hiddenByNearness`, yang sendiri membungkus pembaca stor backward asal.

Penyimpan hidden7..hidden1 kekal songsang, tanpa `array_reverse`; pengeluaran melalui penghala baharu `PRIOR_PATCH_06`, pemilikan konteks per panggilan. `priorLegacy` tetap disediakan dan salah secara sengaja untuk bukti Stage 12.

## Bukti yang mesti diuji

```text
php -d memory_limit=512M tests/verify_stage12_discovery06.php
php -d memory_limit=512M tests/stage13_patch06_tests.php
```

Stage 12 mesti terus pulang merah terkawal: `missing=44 found=508 hidden=28 lain=0`, pengesahnya hijau. Stage 13 mesti lulus:

```text
LULUS Stage 13 PATCH 06 positif=762 hidden=66 oracle_hidden=42 sintetik=2688 ralat=7
```

Juga wajib lulus semua ujian Stage 1–11, kunci nama kanonik, fixture deterministik dan syntax PHP. Kegagalan runtime atau RED tidak terjangka adalah halangan, bukan penerimaan.

## Sempadan

Tidak disentuh: semua legacy, `NormativeMath`, `NormativeSauce`, `CANONICAL_NAMES_LOCK.sha256`, katalog nama, fixture dan `main`. Generator titisan visible bermula Stage 14 sahaja.

**Cadangan commit:** `stage13(php-ms): betulkan akses prior hidden melalui pembalut legacy`
